-- ============================================================================
-- VISTAS ETL FALTANTES - CRÍTICAS PARA N8N
-- ============================================================================

-- ============================================================================
-- PARTE 1: PROMPTCRM - Vista ETL
-- ============================================================================

USE PromptCRM;
GO

-- Eliminar vista si existe
IF OBJECT_ID('vw_CRM_Campaign_Sales_ETL', 'V') IS NOT NULL
    DROP VIEW vw_CRM_Campaign_Sales_ETL;
GO

-- VISTA ETL para PromptCRM -> PromptSales
CREATE VIEW vw_CRM_Campaign_Sales_ETL AS
SELECT 
    rc.utmCampaign AS campaign_id,
    COUNT(DISTINCT cc.clienteId) AS customers_reached,
    COUNT(DISTINCT conv.conversionId) AS orders,
    SUM(ISNULL(conv.valorConversion, 0)) AS net_revenue_usd,
    MAX(COALESCE(conv.updatedAt, conv.createdAt, GETDATE())) AS updatedAt
FROM 
    referencias_campanas rc
    LEFT JOIN campanas_cliente cc ON rc.referenciaId = cc.referenciaId
    LEFT JOIN conversiones_lead conv ON cc.clienteId = conv.clienteId
WHERE 
    rc.deleted = 0 
    AND (cc.deleted = 0 OR cc.deleted IS NULL)
    AND (conv.deleted = 0 OR conv.deleted IS NULL)
GROUP BY 
    rc.utmCampaign;
GO

PRINT 'Vista vw_CRM_Campaign_Sales_ETL creada exitosamente'
GO

-- ============================================================================
-- PARTE 2: PROMPTADS - Vista ETL
-- ============================================================================

USE PromptAds;
GO

-- Eliminar vista si existe
IF OBJECT_ID('vw_ADS_Campaign_Summary_ETL', 'V') IS NOT NULL
    DROP VIEW vw_ADS_Campaign_Summary_ETL;
GO

-- VISTA ETL para PromptAds -> PromptSales
CREATE VIEW vw_ADS_Campaign_Summary_ETL AS
SELECT 
    c.campaignID AS campaign_id,
    c.businessId AS business_id,
    c.name,
    c.startDate AS starts_at,
    c.endDate AS ends_at,
    COUNT(DISTINCT ch.channelId) AS channels_cnt,
    COUNT(DISTINCT a.adId) AS placements_cnt,
    SUM(ISNULL(ar.impressions, 0)) AS impressions,
    SUM(ISNULL(ar.reach, 0)) AS reach,
    SUM(ISNULL(ar.clicks, 0)) AS clicks,
    SUM(ISNULL(ar.conversions, 0)) AS conversions,
    SUM(ISNULL(ar.likes, 0)) AS likes,
    SUM(ISNULL(ar.comments, 0)) AS comments,
    SUM(ISNULL(ar.shares, 0)) AS shares,
    SUM(ISNULL(ar.saves, 0)) AS saves,
    SUM(ISNULL(ar.revenue, 0)) AS revenue_usd,
    SUM(ISNULL(ar.cost, 0)) AS cost_usd,
    CASE 
        WHEN SUM(ISNULL(ar.cost, 0)) > 0 
        THEN (SUM(ISNULL(ar.revenue, 0)) - SUM(ISNULL(ar.cost, 0))) / SUM(ar.cost)
        ELSE 0
    END AS roi_ads_only,
    CASE 
        WHEN SUM(ISNULL(ar.impressions, 0)) > 0
        THEN CAST(SUM(ISNULL(ar.clicks, 0)) AS FLOAT) / SUM(ar.impressions)
        ELSE 0
    END AS ctr,
    CASE 
        WHEN SUM(ISNULL(ar.clicks, 0)) > 0
        THEN CAST(SUM(ISNULL(ar.conversions, 0)) AS FLOAT) / SUM(ar.clicks)
        ELSE 0
    END AS cvr,
    MAX(COALESCE(ar.updatedAt, ar.createdAt, GETDATE())) AS updatedAt
FROM 
    PACampaigns c
    LEFT JOIN PACampaignChannels cc ON c.campaignID = cc.campaignID
    LEFT JOIN PAChannels ch ON cc.channelId = ch.channelId
    LEFT JOIN PAAds a ON c.campaignID = a.campaignId
    LEFT JOIN PAAdResults ar ON a.adId = ar.adId
WHERE 
    c.deleted = 0
    AND (cc.deleted = 0 OR cc.deleted IS NULL)
    AND (a.deleted = 0 OR a.deleted IS NULL)
    AND (ar.deleted = 0 OR ar.deleted IS NULL)
GROUP BY 
    c.campaignID,
    c.businessId,
    c.name,
    c.startDate,
    c.endDate;
GO

PRINT 'Vista vw_ADS_Campaign_Summary_ETL creada exitosamente'
GO

-- ============================================================================
-- VERIFICACIÓN DE VISTAS
-- ============================================================================

-- Verificar PromptCRM
USE PromptCRM;
SELECT TOP 5 * FROM vw_CRM_Campaign_Sales_ETL;
GO

-- Verificar PromptAds  
USE PromptAds;
SELECT TOP 5 * FROM vw_ADS_Campaign_Summary_ETL;
GO

PRINT ''
PRINT '============================================'
PRINT 'VISTAS ETL CREADAS EXITOSAMENTE'
PRINT '============================================'
PRINT '- vw_CRM_Campaign_Sales_ETL (PromptCRM)'
PRINT '- vw_ADS_Campaign_Summary_ETL (PromptAds)'
PRINT ''
PRINT 'Ahora N8N puede usar estas vistas para el ETL'
PRINT '============================================'
