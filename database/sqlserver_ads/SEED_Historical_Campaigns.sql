USE PromptAds
GO

/* ===========================================================
   SCRIPT: Generar Campañas Históricas
   -----------------------------------------------------------
   Autor: Equipo PromptSales
   Fecha: 2025-11-11
   
   Propósito:
   ==========
   Generar 1000 campañas históricas con distribución:
   - 70% culminadas (ya terminadas)
   - 30% activas (en curso)
   - Picos en diciembre, enero y julio
   - Periodo: Julio 2024 - Enero 2026
   
   Este script está SEPARADO del SP principal siguiendo
   las mejores prácticas vistas en clase.
   =========================================================== */

PRINT '========================================';
PRINT 'GENERACIÓN DE CAMPAÑAS HISTÓRICAS';
PRINT '========================================';

-- Parámetros de configuración
DECLARE @TotalCampaigns INT = 1000;
DECLARE @StartDate DATE = '2024-07-01';
DECLARE @EndDate DATE = '2026-01-31';
DECLARE @ActivePercentage FLOAT = 0.30; -- 30% activas

-- Variables de trabajo
DECLARE @i INT = 1;
DECLARE @CampaignName VARCHAR(150);
DECLARE @CampaignStart DATETIME2;
DECLARE @CampaignEnd DATETIME2;
DECLARE @IsActive BIT;
DECLARE @BusinessId INT;
DECLARE @UserId INT;
DECLARE @DayRange INT = DATEDIFF(DAY, @StartDate, @EndDate);

-- Obtener IDs existentes
DECLARE @BusinessIds TABLE (rowNum INT IDENTITY(1,1), businessId INT);
INSERT INTO @BusinessIds (businessId)
SELECT TOP 20 businessId FROM PABusinesses ORDER BY businessId;

DECLARE @UserIds TABLE (rowNum INT IDENTITY(1,1), userId INT);
INSERT INTO @UserIds (userId)
SELECT TOP 10 userId FROM PAUsers ORDER BY userId;

-- Validación de datos existentes
DECLARE @BusinessCount INT = (SELECT COUNT(*) FROM @BusinessIds);
DECLARE @UserCount INT = (SELECT COUNT(*) FROM @UserIds);

IF @BusinessCount = 0 OR @UserCount = 0
BEGIN
    RAISERROR('Error: Se requieren al menos 1 negocio y 1 usuario en las tablas PABusinesses y PAUsers', 16, 1);
    RETURN;
END

PRINT 'Negocios disponibles: ' + CAST(@BusinessCount AS VARCHAR);
PRINT 'Usuarios disponibles: ' + CAST(@UserCount AS VARCHAR);
PRINT 'Iniciando generación de ' + CAST(@TotalCampaigns AS VARCHAR) + ' campañas...';
PRINT '';

-- Iniciar transacción para mejor rendimiento
BEGIN TRANSACTION;

BEGIN TRY
    WHILE @i <= @TotalCampaigns
    BEGIN
        -- Determinar si será activa o culminada
        SET @IsActive = CASE 
            WHEN @i <= (@TotalCampaigns * @ActivePercentage) THEN 1 
            ELSE 0 
        END;
        
        -- Seleccionar business y user aleatorios
        SET @BusinessId = (
            SELECT businessId 
            FROM @BusinessIds 
            WHERE rowNum = (1 + ABS(CHECKSUM(NEWID())) % @BusinessCount)
        );
        
        SET @UserId = (
            SELECT userId 
            FROM @UserIds 
            WHERE rowNum = (1 + ABS(CHECKSUM(NEWID())) % @UserCount)
        );
        
        -- Generar fecha de inicio base
        DECLARE @RandomDays INT = ABS(CHECKSUM(NEWID())) % @DayRange;
        SET @CampaignStart = DATEADD(DAY, @RandomDays, @StartDate);
        
        -- Aplicar picos estacionales (diciembre, enero, julio)
        DECLARE @Month INT = MONTH(@CampaignStart);
        DECLARE @RandomChance INT = ABS(CHECKSUM(NEWID())) % 100;
        
        -- 60% de probabilidad de crear más campañas en meses pico
        IF @Month = 12 -- Diciembre
        BEGIN
            IF @RandomChance < 60
                SET @CampaignStart = DATEFROMPARTS(YEAR(@CampaignStart), 12, 1 + (ABS(CHECKSUM(NEWID())) % 30));
        END
        ELSE IF @Month = 1 -- Enero
        BEGIN
            IF @RandomChance < 60
                SET @CampaignStart = DATEFROMPARTS(YEAR(@CampaignStart), 1, 1 + (ABS(CHECKSUM(NEWID())) % 30));
        END
        ELSE IF @Month = 7 -- Julio (mes adicional de pico)
        BEGIN
            IF @RandomChance < 60
                SET @CampaignStart = DATEFROMPARTS(YEAR(@CampaignStart), 7, 1 + (ABS(CHECKSUM(NEWID())) % 30));
        END
        
        -- Duración de campaña (entre 7 y 90 días)
        DECLARE @Duration INT = 7 + (ABS(CHECKSUM(NEWID())) % 84);
        SET @CampaignEnd = DATEADD(DAY, @Duration, @CampaignStart);
        
        -- Para campañas culminadas, asegurar que ya terminaron
        IF @IsActive = 0
        BEGIN
            IF @CampaignEnd > GETDATE()
            BEGIN
                -- Ajustar para que termine antes de hoy
                SET @CampaignEnd = DATEADD(DAY, -1 - (ABS(CHECKSUM(NEWID())) % 30), GETDATE());
                SET @CampaignStart = DATEADD(DAY, -@Duration, @CampaignEnd);
            END
        END
        ELSE -- Para campañas activas
        BEGIN
            -- Asegurar que estén en curso
            IF @CampaignStart > GETDATE()
            BEGIN
                SET @CampaignStart = DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 30), GETDATE());
                SET @CampaignEnd = DATEADD(DAY, @Duration, @CampaignStart);
            END
        END
        
        -- Generar nombre único de campaña
        SET @CampaignName = CONCAT(
            CASE @Month
                WHEN 12 THEN 'Black Friday '
                WHEN 1 THEN 'Año Nuevo '
                WHEN 7 THEN 'Verano '
                WHEN 2 THEN 'San Valentín '
                WHEN 5 THEN 'Día Madres '
                WHEN 11 THEN 'Cyber Monday '
                ELSE 'Promoción '
            END,
            YEAR(@CampaignStart),
            ' - Campaign #',
            @i
        );
        
        -- Insertar campaña
        INSERT INTO PACampaigns (
            name, 
            description, 
            objectives,
            campaignTypeId,
            targetMetrics,
            strategyNotes,
            startsAt, 
            endsAt, 
            enabled, 
            deleted, 
            businessId, 
            createdAt, 
            createdBy_userId
        )
        VALUES (
            @CampaignName,
            'Campaña histórica generada para análisis y reportes',
            CASE 
                WHEN @Month = 12 THEN 'Maximizar ventas de temporada navideña'
                WHEN @Month = 1 THEN 'Capturar nuevos clientes con ofertas de año nuevo'
                WHEN @Month = 7 THEN 'Impulsar ventas de verano'
                ELSE 'Incrementar awareness y conversiones'
            END,
            1 + (ABS(CHECKSUM(NEWID())) % 3), -- Tipo aleatorio 1-3
            '{"impressions": ' + CAST(10000 + ABS(CHECKSUM(NEWID())) % 90000 AS VARCHAR) + 
            ', "clicks": ' + CAST(100 + ABS(CHECKSUM(NEWID())) % 900 AS VARCHAR) + 
            ', "conversions": ' + CAST(10 + ABS(CHECKSUM(NEWID())) % 90 AS VARCHAR) + '}',
            'Estrategia multicanal con segmentación demográfica',
            @CampaignStart,
            @CampaignEnd,
            @IsActive,
            0,
            @BusinessId,
            DATEADD(DAY, -1, @CampaignStart), -- createdAt un día antes del inicio
            @UserId
        );
        
        -- Agregar algunos anuncios básicos para cada campaña
        DECLARE @NewCampaignId INT = SCOPE_IDENTITY();
        DECLARE @NumAds INT = 2 + (ABS(CHECKSUM(NEWID())) % 4); -- Entre 2 y 5 anuncios
        DECLARE @j INT = 1;
        
        WHILE @j <= @NumAds
        BEGIN
            INSERT INTO PAAds (
                campaignId, headline, bodyText, format, 
                dimensions, adType, enabled, createdAt
            )
            VALUES (
                @NewCampaignId,
                @CampaignName + ' - Ad ' + CAST(@j AS VARCHAR),
                'Contenido promocional para ' + @CampaignName,
                CASE (ABS(CHECKSUM(NEWID())) % 3)
                    WHEN 0 THEN 'image'
                    WHEN 1 THEN 'video'
                    ELSE 'carousel'
                END,
                '1080x1080',
                CASE (ABS(CHECKSUM(NEWID())) % 2)
                    WHEN 0 THEN 'display'
                    ELSE 'native'
                END,
                @IsActive,
                @CampaignStart
            );
            
            SET @j = @j + 1;
        END
        
        -- Progreso cada 100 campañas
        IF @i % 100 = 0
            PRINT 'Progreso: ' + CAST(@i AS VARCHAR) + ' / ' + CAST(@TotalCampaigns AS VARCHAR) + ' campañas creadas...';
        
        SET @i = @i + 1;
    END
    
    COMMIT TRANSACTION;
    
    PRINT '';
    PRINT '✓ Generación completada exitosamente';
    PRINT '========================================';
    
    -- Estadísticas finales
    PRINT 'ESTADÍSTICAS DE CAMPAÑAS GENERADAS:';
    PRINT '------------------------------------';
    
    SELECT 
        'Total Campañas' AS [Métrica],
        COUNT(*) AS [Valor]
    FROM PACampaigns
    WHERE description = 'Campaña histórica generada para análisis y reportes'
    
    UNION ALL
    
    SELECT 
        'Campañas Activas',
        COUNT(*)
    FROM PACampaigns
    WHERE enabled = 1 
      AND description = 'Campaña histórica generada para análisis y reportes'
    
    UNION ALL
    
    SELECT 
        'Campañas Culminadas',
        COUNT(*)
    FROM PACampaigns
    WHERE enabled = 0 
      AND description = 'Campaña histórica generada para análisis y reportes';
    
    -- Distribución por mes
    PRINT '';
    PRINT 'DISTRIBUCIÓN POR MES DE INICIO:';
    SELECT 
        MONTH(startsAt) AS [Mes],
        DATENAME(MONTH, startsAt) AS [Nombre Mes],
        COUNT(*) AS [Cantidad Campañas],
        CAST(COUNT(*) * 100.0 / @TotalCampaigns AS DECIMAL(5,2)) AS [Porcentaje]
    FROM PACampaigns
    WHERE description = 'Campaña histórica generada para análisis y reportes'
    GROUP BY MONTH(startsAt), DATENAME(MONTH, startsAt)
    ORDER BY MONTH(startsAt);
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    PRINT 'ERROR en generación de campañas históricas:';
    PRINT ERROR_MESSAGE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH

PRINT '';
PRINT '========================================';
PRINT 'FIN DEL SCRIPT';
PRINT '========================================';
GO