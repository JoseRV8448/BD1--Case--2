USE PromptAds
GO

/* ===========================================================
   STORED PROCEDURE: PA001SP_InsertCampaign
   -----------------------------------------------------------
   Autor: Equipo PromptSales
   Fecha: 2025-11-11
   
   Propósito:
   ==========
   Crea una nueva campaña publicitaria con todos sus elementos
   asociados (anuncios, CTAs, canales, presupuestos y targets).

   Códigos de Error Personalizados:
   --------------------------------
   50001 - Parámetros básicos inválidos
   50002 - Fecha de fin anterior a inicio
   50003 - Nombre de campaña vacío
   50004 - Error al insertar campaña
   50005 - Error al insertar anuncios
   50006 - Error al insertar CTAs
   50007 - Error al asignar canales
   50008 - Error al asignar presupuesto
   50009 - Error al asignar targets
   =========================================================== */

-- Registrar errores personalizados en sys.messages
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50001)
    EXEC sp_addmessage @msgnum = 50001, @severity = 16, 
         @msgtext = N'Parámetros básicos de campaña inválidos';
         
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50002)
    EXEC sp_addmessage @msgnum = 50002, @severity = 16,
         @msgtext = N'La fecha de fin debe ser posterior a la de inicio';
         
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50003)
    EXEC sp_addmessage @msgnum = 50003, @severity = 16,
         @msgtext = N'El nombre de la campaña no puede estar vacío';
GO

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
    @Ads                     dbo.TVP_PAAds READONLY,              
    @AdsCTAs                 dbo.TVP_PACallToActions READONLY,    
    @AdChannels              dbo.TVP_PAAdXChannel READONLY,       
    @BudgetAllocations       dbo.TVP_PACampaignBudgetAlloc READONLY,
    @TargetIds               dbo.TVP_PATargetIds READONLY         
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT;
    DECLARE @Message VARCHAR(200);
    DECLARE @InicieTransaccion BIT;

    /* ===========================================================
       VALIDACIONES INICIALES (fuera de transacción)
       =========================================================== */
    -- Limpieza de strings
    SET @Name = LTRIM(RTRIM(@Name));
    IF @Description IS NOT NULL
        SET @Description = LTRIM(RTRIM(@Description));
    
    -- Validaciones básicas
    IF @BusinessId IS NULL OR @CreatedBy_UserId IS NULL OR 
       @StartsAt IS NULL OR @EndsAt IS NULL
    BEGIN
        THROW 50001, 'Parámetros básicos de campaña inválidos', 1;
    END
    
    IF @EndsAt <= @StartsAt
    BEGIN
        THROW 50002, 'La fecha de fin debe ser posterior a la de inicio', 1;
    END
    
    IF LEN(@Name) = 0
    BEGIN
        THROW 50003, 'El nombre de la campaña no puede estar vacío', 1;
    END

    -- Preparar tabla de canales habilitados (fuera de transacción)
    DECLARE @EnabledChannels TABLE (channelId INT);
    INSERT INTO @EnabledChannels
    SELECT channelId FROM PAChannels WHERE enabled = 1
    INTERSECT
    SELECT DISTINCT channelId FROM @AdChannels;

    /* ===========================================================
       INICIO DE TRANSACCIÓN
       =========================================================== */
    SET @InicieTransaccion = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        SET @InicieTransaccion = 1;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION;
    END
    
    BEGIN TRY
        DECLARE @NewCampaignId INT;

        -- 1. Insertar campaña principal
        INSERT INTO PACampaigns
            (name, description, objectives, campaignTypeId, targetMetrics, 
             strategyNotes, startsAt, endsAt, enabled, deleted, 
             businessId, createdAt, createdBy_userId)
        VALUES
            (@Name, @Description, @Objectives, @CampaignTypeId, @TargetMetrics, 
             @StrategyNotes, @StartsAt, @EndsAt, 1, 0, 
             @BusinessId, GETDATE(), @CreatedBy_UserId);

        SET @NewCampaignId = SCOPE_IDENTITY();
        
        IF @NewCampaignId IS NULL
            THROW 50004, 'Error al insertar campaña', 1;

        -- 2. Insertar anuncios directamente sin tabla temporal
        -- Usando CTE con nombre significativo
        ;WITH AdsWithRowNumber AS (
            SELECT 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS adRowNumber,
                headline, bodyText, adDescription, format, 
                dimensions, adType, duration, mediaURL
            FROM @Ads
        )
        INSERT INTO PAAds 
            (campaignId, headline, bodyText, adDescription, format, 
             dimensions, adType, duration, mediaURL, 
             createdAt, updatedAt, enabled)
        SELECT 
            @NewCampaignId, 
            headline, bodyText, adDescription, format, 
            dimensions, adType, duration, mediaURL, 
            GETDATE(), NULL, 1
        FROM AdsWithRowNumber;

        -- 3. Insertar CTAs usando JOIN directo con los anuncios insertados
        ;WITH AdsOrdered AS (
            SELECT 
                adId,
                ROW_NUMBER() OVER (ORDER BY adId) AS adOrder
            FROM PAAds
            WHERE campaignId = @NewCampaignId
        ),
        CTAsWithOrder AS (
            SELECT 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS adOrder,
                label, orderInAd, targetURL, ctaTypeId
            FROM @AdsCTAs
        )
        INSERT INTO PACallToActions 
            (adId, label, orderInAd, targetURL, enabled, ctaTypeId)
        SELECT 
            AO.adId, 
            CTA.label, 
            CTA.orderInAd, 
            CTA.targetURL, 
            1, 
            CTA.ctaTypeId
        FROM CTAsWithOrder CTA
        INNER JOIN AdsOrdered AO ON AO.adOrder = CTA.adOrder;

        -- 4. Asignar canales a anuncios (solo canales habilitados)
        ;WITH AdsOrdered AS (
            SELECT 
                adId,
                ROW_NUMBER() OVER (ORDER BY adId) AS adOrder
            FROM PAAds
            WHERE campaignId = @NewCampaignId
        ),
        ChannelsWithOrder AS (
            SELECT 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS adOrder,
                channelId, customURL, adXchannelStatusId
            FROM @AdChannels
        )
        INSERT INTO PAAdXChannel 
            (adId, channelId, customURL, createdAt, adXchannelStatusId)
        SELECT 
            AO.adId, 
            CH.channelId, 
            CH.customURL, 
            GETDATE(), 
            CH.adXchannelStatusId
        FROM ChannelsWithOrder CH
        INNER JOIN AdsOrdered AO ON AO.adOrder = CH.adOrder
        WHERE CH.channelId IN (SELECT channelId FROM @EnabledChannels);

        -- 5. Insertar presupuesto por canal usando MERGE (sin DELETE)
        MERGE PACampaignBudgetAllocations AS Target
        USING @BudgetAllocations AS Source
          ON Target.campaignId = @NewCampaignId 
         AND Target.channelId = Source.channelId
        WHEN MATCHED THEN
            UPDATE SET 
                Target.budgetAssigned = Source.budgetAssigned, 
                Target.updatedAt = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (campaignId, channelId, budgetAssigned, budgetUsed, createdAt)
            VALUES (@NewCampaignId, Source.channelId, Source.budgetAssigned, 0, GETDATE());

        -- 6. Asociar targets a anuncios
        INSERT INTO PAAdsXTarget (adId, targetId)
        SELECT DISTINCT
            AD.adId, 
            TG.targetId
        FROM @TargetIds TG
        CROSS JOIN PAAds AD
        WHERE AD.campaignId = @NewCampaignId
          AND NOT EXISTS (
              SELECT 1 FROM PAAdsXTarget PAT
              WHERE PAT.adId = AD.adId 
                AND PAT.targetId = TG.targetId
          );

        -- 7. Crear métricas iniciales
        INSERT INTO PARectrem 
            (adXchannelId, recordedAt, cost, revenue, clicks, 
             impressions, reach, conversions, score)
        SELECT 
            AXC.adXchannelId, 
            GETDATE(), 
            0, 0, 0, 0, 0, 0, NULL
        FROM PAAdXChannel AXC
        INNER JOIN PAAds AD ON AD.adId = AXC.adId
        WHERE AD.campaignId = @NewCampaignId;

        INSERT INTO PAAdEngagementMetrics 
            (adXchannelId, recordedAt, likes, shares, comments, saves, 
             videoViews, videoCompletionRate, clickThroughRate, engagementRate)
        SELECT 
            AXC.adXchannelId, 
            GETDATE(), 
            0, 0, 0, 0, 0, NULL, NULL, NULL
        FROM PAAdXChannel AXC
        INNER JOIN PAAds AD ON AD.adId = AXC.adId
        WHERE AD.campaignId = @NewCampaignId;

        -- 8. Actualizar budget usado basado en costos reales
        UPDATE PACampaignBudgetAllocations
        SET budgetUsed = ISNULL(CostSummary.totalCost, 0)
        FROM PACampaignBudgetAllocations
        INNER JOIN (
            SELECT 
                AXC.channelId, 
                SUM(REC.cost) AS totalCost
            FROM PARectrem REC
            INNER JOIN PAAdXChannel AXC ON AXC.adXchannelId = REC.adXchannelId
            INNER JOIN PAAds AD ON AD.adId = AXC.adId
            WHERE AD.campaignId = @NewCampaignId
            GROUP BY AXC.channelId
        ) AS CostSummary ON CostSummary.channelId = PACampaignBudgetAllocations.channelId
        WHERE PACampaignBudgetAllocations.campaignId = @NewCampaignId;

        -- Confirmar transacción
        IF @InicieTransaccion = 1
        BEGIN
            COMMIT TRANSACTION;
        END
        
        -- Retornar ID de la nueva campaña
        SELECT @NewCampaignId AS NewCampaignId;
        
    END TRY
    BEGIN CATCH
        IF @InicieTransaccion = 1
            ROLLBACK TRANSACTION;

        -- Re-lanzar el error
        THROW;
    END CATCH    
END
GO

PRINT 'Stored Procedure PA001SP_InsertCampaign creado exitosamente';
GO