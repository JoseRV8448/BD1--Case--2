USE PromptAds
GO

/* ===========================================================
   SCRIPT DE PRUEBA: PA001SP_InsertCampaign
   -----------------------------------------------------------
   Autor: Equipo PromptSales
   Fecha: 2025-11-11
   
   Propósito:
   ==========
   Probar la inserción de una campaña completa con todos sus
   componentes usando Table-Valued Parameters (TVPs).
   =========================================================== */

-- Limpiar variables de tabla anteriores
DECLARE @TestAds dbo.TVP_PAAds;
DECLARE @TestCTAs dbo.TVP_PACallToActions;
DECLARE @TestChannels dbo.TVP_PAAdXChannel;
DECLARE @TestBudgets dbo.TVP_PACampaignBudgetAlloc;
DECLARE @TestTargets dbo.TVP_PATargetIds;

-- Verificar que existan datos básicos necesarios
IF NOT EXISTS (SELECT 1 FROM PABusinesses)
BEGIN
    PRINT 'ERROR: No hay negocios en PABusinesses. Ejecute el script de llenado primero.';
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM PAUsers)
BEGIN
    PRINT 'ERROR: No hay usuarios en PAUsers. Ejecute el script de llenado primero.';
    RETURN;
END

-- Obtener IDs válidos para la prueba
DECLARE @TestBusinessId INT = (SELECT TOP 1 businessId FROM PABusinesses);
DECLARE @TestUserId INT = (SELECT TOP 1 userId FROM PAUsers);

PRINT '========================================';
PRINT 'INICIANDO PRUEBA DE PA001SP_InsertCampaign';
PRINT '========================================';
PRINT 'BusinessId de prueba: ' + CAST(@TestBusinessId AS VARCHAR);
PRINT 'UserId de prueba: ' + CAST(@TestUserId AS VARCHAR);

-- 1. Preparar datos de anuncios (3 anuncios de prueba)
INSERT INTO @TestAds (headline, bodyText, adDescription, format, dimensions, adType, duration, mediaURL)
VALUES 
    ('¡Ofertas Black Friday!', 'Descuentos hasta 70% en toda la tienda', 'Promoción especial de temporada', 'image', '1080x1920', 'display', NULL, 'https://cdn.example.com/bf1.jpg'),
    ('Nuevo iPhone disponible', 'Reserva el tuyo ahora con envío gratis', 'Lanzamiento de producto', 'video', '1920x1080', 'video', 30, 'https://cdn.example.com/iphone.mp4'),
    ('Suscríbete y ahorra', 'Planes desde $9.99/mes', 'Campaña de suscripciones', 'carousel', '1080x1080', 'display', NULL, 'https://cdn.example.com/plans.jpg');

-- 2. Preparar CTAs (2 CTAs por anuncio)
INSERT INTO @TestCTAs (adIndex, label, orderInAd, targetURL, ctaTypeId)
VALUES 
    (1, 'Comprar Ahora', 1, 'https://shop.example.com/blackfriday', 1),
    (1, 'Ver Ofertas', 2, 'https://shop.example.com/deals', 2),
    (2, 'Reservar', 1, 'https://shop.example.com/iphone', 1),
    (2, 'Más Info', 2, 'https://shop.example.com/iphone/specs', 3),
    (3, 'Suscribirse', 1, 'https://shop.example.com/subscribe', 4),
    (3, 'Comparar Planes', 2, 'https://shop.example.com/plans', 2);

-- 3. Asignar canales (Facebook, Instagram, Google Ads)
-- Verificar que existan estos canales
IF NOT EXISTS (SELECT 1 FROM PAChannels WHERE channelId IN (1,2,3))
BEGIN
    PRINT 'Creando canales de prueba...';
    SET IDENTITY_INSERT PAChannels ON;
    INSERT INTO PAChannels (channelId, name, platformType, apiEndpoint, enabled, createdAt)
    VALUES 
        (1, 'Facebook', 'social', 'https://graph.facebook.com/v18.0/', 1, GETDATE()),
        (2, 'Instagram', 'social', 'https://graph.instagram.com/v18.0/', 1, GETDATE()),
        (3, 'Google Ads', 'search', 'https://googleads.googleapis.com/v14/', 1, GETDATE());
    SET IDENTITY_INSERT PAChannels OFF;
END

INSERT INTO @TestChannels (adIndex, channelId, customURL, adXchannelStatusId)
VALUES 
    (1, 1, NULL, 1), -- Anuncio 1 en Facebook
    (1, 2, NULL, 1), -- Anuncio 1 en Instagram
    (2, 1, NULL, 1), -- Anuncio 2 en Facebook
    (2, 3, NULL, 1), -- Anuncio 2 en Google Ads
    (3, 2, NULL, 1), -- Anuncio 3 en Instagram
    (3, 3, NULL, 1); -- Anuncio 3 en Google Ads

-- 4. Definir presupuesto por canal
INSERT INTO @TestBudgets (channelId, budgetAssigned)
VALUES 
    (1, 5000.00),  -- Facebook: $5000
    (2, 3500.00),  -- Instagram: $3500
    (3, 7500.00);  -- Google Ads: $7500

-- 5. Definir targets (audiencias)
-- Verificar que existan targets
IF NOT EXISTS (SELECT 1 FROM PATargets)
BEGIN
    PRINT 'Creando targets de prueba...';
    INSERT INTO PATargets (name, minAge, maxAge, gender, interests, behaviors, customAudience)
    VALUES 
        ('Millennials Tech', 25, 40, 'all', 'technology,gadgets', 'online_shopping', NULL),
        ('Gen Z Fashion', 18, 24, 'all', 'fashion,trends', 'social_media_active', NULL),
        ('Profesionales', 30, 55, 'all', 'business,finance', 'high_income', NULL);
END

INSERT INTO @TestTargets (targetId)
SELECT TOP 3 targetId FROM PATargets;

-- 6. Ejecutar el stored procedure
PRINT '';
PRINT 'Ejecutando PA001SP_InsertCampaign...';
PRINT '----------------------------------------';

BEGIN TRY
    EXEC dbo.PA001SP_InsertCampaign
        @BusinessId = @TestBusinessId,
        @Name = 'Campaña de Prueba - Black Friday 2025',
        @Description = 'Campaña multi-canal para Black Friday con promociones especiales',
        @Objectives = 'Incrementar ventas 40%, Conseguir 1000 nuevos suscriptores, ROI 3:1',
        @CampaignTypeId = 1,
        @TargetMetrics = '{"conversions": 5000, "ctr": 3.5, "roas": 3.0}',
        @StrategyNotes = 'Enfoque en remarketing y lookalike audiences',
        @StartsAt = '2025-11-20',
        @EndsAt = '2025-11-30',
        @CreatedBy_UserId = @TestUserId,
        @Ads = @TestAds,
        @AdsCTAs = @TestCTAs,
        @AdChannels = @TestChannels,
        @BudgetAllocations = @TestBudgets,
        @TargetIds = @TestTargets;
    
    PRINT 'ÉXITO: Campaña creada correctamente';
    
    -- Verificar los datos insertados
    PRINT '';
    PRINT 'VERIFICACIÓN DE DATOS INSERTADOS:';
    PRINT '==================================';
    
    DECLARE @CampaignId INT = (SELECT TOP 1 campaignId FROM PACampaigns ORDER BY campaignId DESC);
    
    -- Verificar campaña
    SELECT 'Campaña creada:' AS [Resultado], 
           campaignId, name, startsAt, endsAt 
    FROM PACampaigns 
    WHERE campaignId = @CampaignId;
    
    -- Contar anuncios
    SELECT 'Total anuncios:' AS [Resultado], 
           COUNT(*) AS [Cantidad] 
    FROM PAAds 
    WHERE campaignId = @CampaignId;
    
    -- Contar CTAs
    SELECT 'Total CTAs:' AS [Resultado], 
           COUNT(*) AS [Cantidad]
    FROM PACallToActions CTA
    INNER JOIN PAAds AD ON AD.adId = CTA.adId
    WHERE AD.campaignId = @CampaignId;
    
    -- Verificar canales asignados
    SELECT 'Canales asignados:' AS [Resultado],
           CH.name AS [Canal],
           COUNT(DISTINCT AXC.adId) AS [Anuncios]
    FROM PAAdXChannel AXC
    INNER JOIN PAChannels CH ON CH.channelId = AXC.channelId
    INNER JOIN PAAds AD ON AD.adId = AXC.adId
    WHERE AD.campaignId = @CampaignId
    GROUP BY CH.name;
    
    -- Verificar presupuesto
    SELECT 'Presupuesto total:' AS [Resultado],
           SUM(budgetAssigned) AS [Total],
           COUNT(*) AS [Canales]
    FROM PACampaignBudgetAllocations
    WHERE campaignId = @CampaignId;
    
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Severidad: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT 'Estado: ' + CAST(ERROR_STATE() AS VARCHAR);
END CATCH

PRINT '';
PRINT '========================================';
PRINT 'FIN DE PRUEBA';
PRINT '========================================';
GO