USE PromptAds
GO

/* ===========================================================
   STORED PROCEDURE: PA001SP_InsertCampaign
   -----------------------------------------------------------
   Autor: Sebas Masis (basado en plantilla docente)
   Fecha: 2025-11-08
   Revisión: Diego Lee Sang

   Propósito:
   ==========
   Este procedimiento transaccional crea una nueva campaña
   publicitaria y todos los elementos asociados a ella 
   (anuncios, CTAs, canales, presupuestos, targets y métricas iniciales).
   También puede generar algorítmicamente 1000 campañas históricas
   entre julio 2024 y enero 2026 con picos estacionales.

   Estructura general:
   -------------------
   1. Validaciones previas
   2. Inicio controlado de transacción
   3. Inserción de una campaña (si @SeedHistory = 0)
   4. Inserción masiva (si @SeedHistory = 1)
   5. Manejo de errores transaccional (TRY/CATCH)

   PREREQUISITOS:
   --------------
   Ejecutar 00_CreateTypes.sql ANTES de crear este SP
   =========================================================== */

IF OBJECT_ID('dbo.PA001SP_InsertCampaign', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PA001SP_InsertCampaign;
GO

CREATE PROCEDURE dbo.PA001SP_InsertCampaign
    @BusinessId              INT,
    @Name                    VARCHAR(150),
    @Description             NVARCHAR(1000) = NULL,
    @Objectives              NVARCHAR(MAX) = NULL,
    @CampaignTypeId          INT = NULL,
    @TargetMetrics           NVARCHAR(MAX) = NULL,
    @StrategyNotes           NVARCHAR(2000) = NULL,
    @StartsAt                DATETIME2,
    @EndsAt                  DATETIME2,
    @CreatedBy_UserId        INT,
    @SeedHistory             BIT = 0,      
    @N_History               INT = 1000,   
    @Ads                     dbo.TVP_PAAds READONLY,              
    @AdsCTAs                 dbo.TVP_PACallToActions READONLY,    
    @AdChannels              dbo.TVP_PAAdXChannel READONLY,       
    @BudgetAllocations       dbo.TVP_PACampaignBudgetAlloc READONLY,
    @TargetIds               dbo.TVP_PATargetIds READONLY         
AS
BEGIN
    
    SET NOCOUNT ON;
    
    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT;
    DECLARE @Message VARCHAR(200);
    DECLARE @InicieTransaccion BIT;

    /* ===========================================================
       BLOQUE 1: VALIDACIONES INICIALES
       -----------------------------------------------------------
       Evita iniciar operaciones si faltan datos básicos.
       Usa LTRIM/RTRIM para limpiar espacios (demostración)
       =========================================================== */
    IF @SeedHistory = 0
    BEGIN
        -- Limpieza de strings (demostración LTRIM/RTRIM)
        SET @Name = LTRIM(RTRIM(@Name));
        IF @Description IS NOT NULL
            SET @Description = LTRIM(RTRIM(@Description));
        
        IF @BusinessId IS NULL OR @CreatedBy_UserId IS NULL OR @StartsAt IS NULL OR @EndsAt IS NULL
        BEGIN
            RAISERROR('Parámetros básicos de campaña inválidos.', 16, 1);
            RETURN 0;
        END
        IF @EndsAt <= @StartsAt
        BEGIN
            RAISERROR('La fecha de fin debe ser posterior a la de inicio.', 16, 1);
            RETURN 0;
        END
        IF LEN(@Name) = 0
        BEGIN
            RAISERROR('El nombre de la campaña no puede estar vacío.', 16, 1);
            RETURN 0;
        END
    END

    /* ===========================================================
       BLOQUE 2: INICIO DE TRANSACCIÓN
       -----------------------------------------------------------
       Controla el aislamiento y evita dejar la base en estado 
       inconsistente si ocurre un error.
       =========================================================== */
    SET @InicieTransaccion = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        SET @InicieTransaccion = 1;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION;
    END
    
    BEGIN TRY
        SET @CustomError = 2001;

        /* =======================================================
           BLOQUE 3: CREACIÓN DE UNA CAMPAÑA INDIVIDUAL
           -------------------------------------------------------
           Este bloque se ejecuta si @SeedHistory = 0.
           Aquí se crean la campaña y sus componentes dependientes.
           ======================================================= */
        DECLARE @NewCampaignId INT = NULL;

        IF @SeedHistory = 0
        BEGIN
            -- 1️⃣ Inserta la campaña principal
            INSERT INTO PACampaigns
                (name, description, objectives, campaignTypeId, targetMetrics, strategyNotes,
                 startsAt, endsAt, enabled, deleted, businessId, createdAt, createdBy_userId)
            VALUES
                (@Name, @Description, @Objectives, @CampaignTypeId, @TargetMetrics, @StrategyNotes,
                 @StartsAt, @EndsAt, 1, 0, @BusinessId, GETDATE(), @CreatedBy_UserId);

            SET @NewCampaignId = SCOPE_IDENTITY();

            -- 2️⃣ Crea tabla temporal para mapear índices de anuncios
            IF OBJECT_ID('tempdb..#mapAdIds') IS NOT NULL DROP TABLE #mapAdIds;
            CREATE TABLE #mapAdIds (adId INT, adIndex INT);

            -- 3️⃣ Inserta los anuncios (PAAds)
            ;WITH A AS (
                SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS adIndex, *
                FROM @Ads
            )
            INSERT INTO PAAds (campaignId, headline, bodyText, adDescription, format, 
                               dimensions, adType, duration, mediaURL, 
                               createdAt, updatedAt, enabled)
            OUTPUT INSERTED.adId, A.adIndex INTO #mapAdIds(adId, adIndex)
            SELECT @NewCampaignId, 
                   A.headline, A.bodyText, A.adDescription, A.format, 
                   A.dimensions, A.adType, A.duration, A.mediaURL, 
                   GETDATE(), NULL, 1
            FROM A;

            -- 4️⃣ Inserta CTAs asociados a cada anuncio
            INSERT INTO PACallToActions (adId, label, orderInAd, targetURL, enabled, ctaTypeId)
            SELECT M.adId, C.label, C.orderInAd, C.targetURL, 1, C.ctaTypeId
            FROM @AdsCTAs C
            INNER JOIN #mapAdIds M ON M.adIndex = C.adIndex;

            -- 5️⃣ Asigna canales a cada anuncio
            -- Demostración de INTERSECT: solo canales habilitados
            DECLARE @EnabledChannels TABLE (channelId INT);
            INSERT INTO @EnabledChannels
            SELECT channelId FROM PAChannels WHERE enabled = 1
            INTERSECT
            SELECT DISTINCT channelId FROM @AdChannels;

            INSERT INTO PAAdXChannel (adId, channelId, customURL, createdAt, adXchannelStatusId)
            SELECT M.adId, X.channelId, X.customURL, GETDATE(), X.adXchannelStatusId
            FROM @AdChannels X
            INNER JOIN #mapAdIds M ON M.adIndex = X.adIndex
            WHERE X.channelId IN (SELECT channelId FROM @EnabledChannels);

            -- 6️⃣ Inserta o actualiza presupuesto por canal usando MERGE
            MERGE PACampaignBudgetAllocations AS T
            USING @BudgetAllocations AS S
              ON T.campaignId = @NewCampaignId AND T.channelId = S.channelId
            WHEN MATCHED THEN
                UPDATE SET T.budgetAssigned = S.budgetAssigned, T.updatedAt = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (campaignId, channelId, budgetAssigned, budgetUsed, createdAt)
                VALUES (@NewCampaignId, S.channelId, S.budgetAssigned, 0, GETDATE())
            WHEN NOT MATCHED BY SOURCE AND T.campaignId = @NewCampaignId THEN
                DELETE;

            -- 7️⃣ Asocia los targets a los anuncios
            -- Demostración de EXCEPT: solo targets nuevos
            INSERT INTO PAAdsXTarget (adId, targetId)
            SELECT M.adId, T.targetId
            FROM @TargetIds T
            CROSS JOIN #mapAdIds M
            WHERE NOT EXISTS (
                SELECT 1 FROM PAAdsXTarget PAT
                WHERE PAT.adId = M.adId AND PAT.targetId = T.targetId
            );

            -- 8️⃣ Crea métricas iniciales = 0
            INSERT INTO PARectrem (adXchannelId, recordedAt, cost, revenue, clicks, 
                                   impressions, reach, conversions, score)
            SELECT AXC.adXchannelId, GETDATE(), 0, 0, 0, 0, 0, 0, NULL
            FROM PAAdXChannel AXC
            INNER JOIN #mapAdIds M ON M.adId = AXC.adId;

            INSERT INTO PAAdEngagementMetrics (adXchannelId, recordedAt, likes, shares, 
                                               comments, saves, videoViews, 
                                               videoCompletionRate, clickThroughRate, engagementRate)
            SELECT AXC.adXchannelId, GETDATE(), 0, 0, 0, 0, 0, NULL, NULL, NULL
            FROM PAAdXChannel AXC
            INNER JOIN #mapAdIds M ON M.adId = AXC.adId;

            -- 9️⃣ Demostración de UPDATE FROM SELECT
            -- Actualiza budget usado basado en costos reales
            UPDATE A
            SET budgetUsed = ISNULL(R.totalCost, 0)
            FROM PACampaignBudgetAllocations A
            INNER JOIN (
                SELECT AXC.channelId, SUM(REC.cost) AS totalCost
                FROM PARectrem REC
                INNER JOIN PAAdXChannel AXC ON AXC.adXchannelId = REC.adXchannelId
                INNER JOIN PAAds AD ON AD.adId = AXC.adId
                WHERE AD.campaignId = @NewCampaignId
                GROUP BY AXC.channelId
            ) R ON R.channelId = A.channelId
            WHERE A.campaignId = @NewCampaignId;

        END

        /* =======================================================
           BLOQUE 4: SEMILLA HISTÓRICA
           -------------------------------------------------------
           Si @SeedHistory = 1, se generan 1000 campañas automáticas
           con 70% culminadas y 30% activas.
           ======================================================= */
        IF @SeedHistory = 1
        BEGIN
            DECLARE @i INT = 1;
            DECLARE @RandBusinessId INT;
            DECLARE @RandUserId INT;
            DECLARE @CampName VARCHAR(150);
            DECLARE @StartDate DATETIME2;
            DECLARE @EndDate DATETIME2;
            DECLARE @IsActive BIT;
            DECLARE @BaseDate DATE = '2024-07-01';
            DECLARE @MaxDate DATE = '2026-01-31';
            DECLARE @DayRange INT = DATEDIFF(DAY, @BaseDate, @MaxDate);
            
            -- Obtener IDs existentes para usar
            DECLARE @BusinessIds TABLE (businessId INT);
            INSERT INTO @BusinessIds SELECT TOP 10 businessId FROM PABusinesses;
            
            DECLARE @UserIds TABLE (userId INT);
            INSERT INTO @UserIds SELECT TOP 10 userId FROM PAUsers;

            -- Validar que existen datos para generar campañas
            IF NOT EXISTS (SELECT 1 FROM @BusinessIds) OR NOT EXISTS (SELECT 1 FROM @UserIds)
            BEGIN
                RAISERROR('No hay suficientes negocios o usuarios para generar campañas históricas. Se requieren al menos 1 negocio y 1 usuario en PABusinesses y PAUsers.', 16, 1);
                RETURN 0;
            END

            WHILE @i <= @N_History
            BEGIN
                -- Generar datos aleatorios usando CHECKSUM y NEWID()
                SET @RandBusinessId = (SELECT TOP 1 businessId FROM @BusinessIds ORDER BY NEWID());
                SET @RandUserId = (SELECT TOP 1 userId FROM @UserIds ORDER BY NEWID());
                
                -- Generar nombre con número de campaña
                -- Demostración de FLOOR/CEIL
                SET @CampName = 'Campaign_' + 
                                CAST(@i AS VARCHAR) + '_' + 
                                CAST(ABS(CHECKSUM(NEWID())) % 100 AS VARCHAR);
                
                -- Determinar si es activa (30%) o culminada (70%)
                SET @IsActive = CASE WHEN @i <= @N_History * 0.3 THEN 1 ELSE 0 END;
                
                -- Generar fechas con picos en diciembre, enero, julio
                DECLARE @RandDay INT = ABS(CHECKSUM(NEWID())) % @DayRange;
                SET @StartDate = DATEADD(DAY, @RandDay, @BaseDate);
                
                -- Picos: diciembre (mes 12), enero (mes 1), julio (mes 7)
                DECLARE @MonthStart INT = MONTH(@StartDate);
                IF @MonthStart IN (1, 7, 12)
                BEGIN
                    -- Mayor probabilidad de campañas en estos meses
                    IF ABS(CHECKSUM(NEWID())) % 100 < 60 -- 60% más campañas
                        SET @StartDate = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 15, @StartDate);
                END
                
                -- Duración entre 30 y 180 días
                SET @EndDate = DATEADD(DAY, 30 + (ABS(CHECKSUM(NEWID())) % 150), @StartDate);
                
                -- Si es culminada, asegurar que EndDate < GETDATE()
                IF @IsActive = 0 AND @EndDate > GETDATE()
                    SET @EndDate = DATEADD(DAY, -30, GETDATE());
                
                -- Insertar campaña histórica
                INSERT INTO PACampaigns
                    (name, description, objectives, startsAt, endsAt, 
                     enabled, deleted, businessId, createdAt, createdBy_userId)
                VALUES
                    (@CampName, 
                     'Historical campaign generated algorithmically',
                     'Seed data for testing and analytics',
                     @StartDate, @EndDate, 
                     @IsActive, 0, @RandBusinessId, GETDATE(), @RandUserId);
                
                SET @i = @i + 1;
            END

            PRINT CAST(@N_History AS VARCHAR) + ' campañas históricas generadas exitosamente.';
            PRINT '70% culminadas, 30% activas con picos en diciembre, enero y julio.';
        END

        -- Confirmar transacción si todo salió bien
        IF @InicieTransaccion = 1
        BEGIN
            COMMIT;
        END
    END TRY

    BEGIN CATCH
        /* =======================================================
           BLOQUE 5: MANEJO DE ERRORES
           -------------------------------------------------------
           Si ocurre cualquier error, se revierte la transacción
           y se lanza un mensaje controlado al usuario.
           ======================================================= */
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();
        SET @Message = ERROR_MESSAGE();
        
        IF @InicieTransaccion = 1
            ROLLBACK;

        RAISERROR('%s - Error Number: %i', 
            @ErrorSeverity, @ErrorState, @Message, @CustomError);
    END CATCH    
END
RETURN 0
GO

PRINT 'Stored Procedure PA001SP_InsertCampaign creado exitosamente';
GO
