-- ============================================================================
-- ETL CON SQL SERVER AGENT - REEMPLAZA N8N
-- Archivo: ETL_SQLServerAgent_Complete.sql
-- ============================================================================

-- ============================================================================
-- PARTE 1: CREAR DATA WAREHOUSE
-- ============================================================================

CREATE DATABASE PromptSales_DW;
GO

USE PromptSales_DW;
GO

-- Crear esquemas
CREATE SCHEMA staging;
CREATE SCHEMA dw;
CREATE SCHEMA etl;
GO

-- ============================================================================
-- PARTE 2: TABLAS DE STAGING
-- ============================================================================

CREATE TABLE staging.campaigns_ads (
    campaignId INT,
    businessId INT,
    name NVARCHAR(200),
    startsAt DATETIME2,
    endsAt DATETIME2,
    impressions BIGINT,
    clicks BIGINT,
    conversions BIGINT,
    revenue DECIMAL(18,2),
    cost DECIMAL(18,2),
    row_hash VARBINARY(32),
    updatedAt DATETIME2
);

CREATE TABLE staging.campaigns_crm (
    campaign_id INT,
    customers_reached INT,
    orders INT,
    net_revenue_usd DECIMAL(18,2),
    row_hash VARBINARY(32),
    updatedAt DATETIME2
);
GO

-- ============================================================================
-- PARTE 3: FACT TABLE
-- ============================================================================

CREATE TABLE dw.fact_campaigns (
    campaign_id INT PRIMARY KEY,
    business_id INT,
    name NVARCHAR(200),
    starts_at DATETIME2,
    ends_at DATETIME2,
    impressions BIGINT,
    clicks BIGINT,
    conversions BIGINT,
    revenue_ads DECIMAL(18,2),
    cost_ads DECIMAL(18,2),
    customers_reached INT,
    orders INT,
    revenue_crm DECIMAL(18,2),
    row_hash VARBINARY(32),
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================================
-- PARTE 4: TABLAS DE CONTROL ETL
-- ============================================================================

CREATE TABLE etl.watermarks (
    source_system VARCHAR(50) PRIMARY KEY,
    last_extracted_at DATETIME2,
    records_processed INT,
    etl_status VARCHAR(20)
);

CREATE TABLE etl.execution_log (
    log_id INT IDENTITY PRIMARY KEY,
    execution_time DATETIME2,
    records_processed INT,
    status VARCHAR(20),
    message NVARCHAR(MAX),
    duration_seconds INT
);

-- Inicializar watermarks
INSERT INTO etl.watermarks VALUES 
    ('PromptAds', '2024-07-01', 0, 'ready'),
    ('PromptCRM', '2024-07-01', 0, 'ready'),
    ('MongoDB', '2024-07-01', 0, 'ready');
GO

-- ============================================================================
-- PARTE 5: STORED PROCEDURE PRINCIPAL DE ETL
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_ETL_Run_Every_11_Minutes
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @LastETL_Ads DATETIME2;
    DECLARE @LastETL_CRM DATETIME2;
    DECLARE @RecordsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Obtener watermarks
        SELECT @LastETL_Ads = last_extracted_at 
        FROM etl.watermarks 
        WHERE source_system = 'PromptAds';
        
        SELECT @LastETL_CRM = last_extracted_at 
        FROM etl.watermarks 
        WHERE source_system = 'PromptCRM';
        
        -- Limpiar staging
        TRUNCATE TABLE staging.campaigns_ads;
        TRUNCATE TABLE staging.campaigns_crm;
        
        -- Extraer de PromptAds (usando vista ETL)
        INSERT INTO staging.campaigns_ads
        SELECT 
            campaign_id,
            business_id,
            name,
            starts_at,
            ends_at,
            impressions,
            clicks,
            conversions,
            revenue_usd,
            cost_usd,
            HASHBYTES('SHA2_256', 
                CONCAT(campaign_id,'|',business_id,'|',ISNULL(impressions,0),'|',ISNULL(clicks,0))
            ) as row_hash,
            updatedAt
        FROM PROMPTADS_LINK.PromptAds.dbo.vw_ADS_Campaign_Summary_ETL
        WHERE updatedAt > @LastETL_Ads;
        
        -- Extraer de PromptCRM (usando vista ETL)
        INSERT INTO staging.campaigns_crm
        SELECT 
            campaign_id,
            customers_reached,
            orders,
            net_revenue_usd,
            HASHBYTES('SHA2_256', 
                CONCAT(campaign_id,'|',customers_reached,'|',orders)
            ) as row_hash,
            updatedAt
        FROM PROMPTCRM_LINK.PromptCRM.dbo.vw_CRM_Campaign_Sales_ETL
        WHERE updatedAt > @LastETL_CRM;
        
        -- MERGE con detección de cambios
        MERGE dw.fact_campaigns AS Target
        USING (
            SELECT 
                a.campaignId,
                a.businessId,
                a.name,
                a.startsAt,
                a.endsAt,
                a.impressions,
                a.clicks,
                a.conversions,
                a.revenue,
                a.cost,
                c.customers_reached,
                c.orders,
                c.net_revenue_usd,
                a.row_hash
            FROM staging.campaigns_ads a
            LEFT JOIN staging.campaigns_crm c ON a.campaignId = c.campaign_id
        ) AS Source
        ON Target.campaign_id = Source.campaignId
        
        WHEN MATCHED AND Target.row_hash != Source.row_hash THEN
            UPDATE SET
                impressions = Source.impressions,
                clicks = Source.clicks,
                conversions = Source.conversions,
                revenue_ads = Source.revenue,
                cost_ads = Source.cost,
                customers_reached = ISNULL(Source.customers_reached, Target.customers_reached),
                orders = ISNULL(Source.orders, Target.orders),
                revenue_crm = ISNULL(Source.net_revenue_usd, Target.revenue_crm),
                row_hash = Source.row_hash,
                last_updated = GETDATE()
                
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (campaign_id, business_id, name, starts_at, ends_at,
                   impressions, clicks, conversions, revenue_ads, cost_ads,
                   customers_reached, orders, revenue_crm, row_hash)
            VALUES (Source.campaignId, Source.businessId, Source.name,
                   Source.startsAt, Source.endsAt, Source.impressions,
                   Source.clicks, Source.conversions, Source.revenue, Source.cost,
                   ISNULL(Source.customers_reached, 0), 
                   ISNULL(Source.orders, 0),
                   ISNULL(Source.net_revenue_usd, 0), 
                   Source.row_hash);
        
        SET @RecordsProcessed = @@ROWCOUNT;
        
        -- Actualizar watermarks
        UPDATE etl.watermarks
        SET last_extracted_at = GETDATE(),
            records_processed = @RecordsProcessed,
            etl_status = 'success'
        WHERE source_system IN ('PromptAds', 'PromptCRM');
        
        -- Log de éxito
        INSERT INTO etl.execution_log 
            (execution_time, records_processed, status, message, duration_seconds)
        VALUES 
            (@StartTime, @RecordsProcessed, 'SUCCESS', 
             'ETL completado exitosamente', 
             DATEDIFF(SECOND, @StartTime, GETDATE()));
        
        COMMIT TRANSACTION;
        
        PRINT 'ETL completado: ' + CAST(@RecordsProcessed AS VARCHAR) + ' registros procesados';
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log de error
        INSERT INTO etl.execution_log 
            (execution_time, records_processed, status, message, duration_seconds)
        VALUES 
            (GETDATE(), 0, 'ERROR', @ErrorMessage, 
             DATEDIFF(SECOND, @StartTime, GETDATE()));
        
        -- Actualizar status de error
        UPDATE etl.watermarks
        SET etl_status = 'error'
        WHERE source_system IN ('PromptAds', 'PromptCRM');
        
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- PARTE 6: CONFIGURAR SQL SERVER AGENT JOB
-- ============================================================================

USE msdb;
GO

-- Eliminar job si existe
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'ETL_PromptSales_11min')
BEGIN
    EXEC sp_delete_job @job_name = N'ETL_PromptSales_11min';
END
GO

-- Crear Job
EXEC dbo.sp_add_job
    @job_name = N'ETL_PromptSales_11min',
    @enabled = 1,
    @description = N'ETL cada 11 minutos - Reemplaza N8N';

-- Agregar Step
EXEC dbo.sp_add_jobstep
    @job_name = N'ETL_PromptSales_11min',
    @step_name = N'Ejecutar ETL',
    @subsystem = N'TSQL',
    @command = N'EXEC sp_ETL_Run_Every_11_Minutes;',
    @database_name = N'PromptSales_DW';

-- Crear Schedule (cada 11 minutos)
EXEC dbo.sp_add_schedule
    @schedule_name = N'Cada_11_Minutos',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 11,
    @active_start_time = 0,
    @active_end_time = 235959;

-- Asociar schedule al job
EXEC dbo.sp_attach_schedule
    @job_name = N'ETL_PromptSales_11min',
    @schedule_name = N'Cada_11_Minutos';

-- Agregar job al servidor
EXEC dbo.sp_add_jobserver
    @job_name = N'ETL_PromptSales_11min';
GO

PRINT '========================================';
PRINT 'ETL CON SQL SERVER AGENT CONFIGURADO';
PRINT '========================================';
PRINT 'Job Name: ETL_PromptSales_11min';
PRINT 'Frecuencia: Cada 11 minutos';
PRINT 'Status: Activo';
PRINT '';
PRINT 'Para iniciar manualmente:';
PRINT 'EXEC msdb.dbo.sp_start_job @job_name = ''ETL_PromptSales_11min''';
PRINT '';
PRINT 'Para ver logs:';
PRINT 'SELECT * FROM PromptSales_DW.etl.execution_log ORDER BY log_id DESC';
GO

-- ============================================================================
-- PARTE 7: QUERIES DE MONITOREO
-- ============================================================================

USE PromptSales_DW;
GO

-- Crear vista de monitoreo
CREATE OR ALTER VIEW vw_ETL_Monitor AS
SELECT TOP 100
    l.log_id,
    l.execution_time,
    l.records_processed,
    l.status,
    l.duration_seconds,
    w.source_system,
    w.last_extracted_at,
    w.etl_status as watermark_status
FROM etl.execution_log l
CROSS JOIN etl.watermarks w
ORDER BY l.log_id DESC;
GO

-- Procedimiento para verificar salud del ETL
CREATE OR ALTER PROCEDURE sp_ETL_HealthCheck
AS
BEGIN
    -- Última ejecución
    SELECT TOP 1 
        'Última Ejecución' as Metric,
        CAST(execution_time AS VARCHAR) as Value,
        CASE 
            WHEN status = 'SUCCESS' THEN 'OK'
            ELSE 'ERROR'
        END as Status
    FROM etl.execution_log
    ORDER BY log_id DESC
    
    UNION ALL
    
    -- Promedio de registros
    SELECT 
        'Promedio Registros/Ejecución',
        CAST(AVG(records_processed) AS VARCHAR),
        'INFO'
    FROM etl.execution_log
    WHERE status = 'SUCCESS'
    AND execution_time > DATEADD(DAY, -1, GETDATE())
    
    UNION ALL
    
    -- Estado watermarks
    SELECT 
        'Watermark ' + source_system,
        CAST(last_extracted_at AS VARCHAR),
        etl_status
    FROM etl.watermarks;
END
GO

PRINT 'ETL configurado completamente. Ejecutar sp_ETL_HealthCheck para verificar estado.';
GO