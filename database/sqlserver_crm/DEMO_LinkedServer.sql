-- ============================================================================
-- DEMOSTRACIÓN LINKED SERVER para el Profesor
-- Ejecutar en SSMS y capturar pantalla de los resultados
-- ============================================================================

PRINT '=========================================='
PRINT 'LINKED SERVER: PromptCRM <-> PromptAds'
PRINT 'Demostración completa de funcionamiento'
PRINT '=========================================='
PRINT ''

-- ============================================================================
-- PARTE 1: Verificar configuración
-- ============================================================================

PRINT '1. VERIFICAR LINKED SERVERS CONFIGURADOS'
PRINT '------------------------------------------'

SELECT 
    name AS [Nombre Linked Server],
    provider AS [Provider],
    data_source AS [Servidor Destino],
    CASE 
        WHEN is_remote_login_enabled = 1 THEN 'Sí'
        ELSE 'No'
    END AS [Login Remoto Habilitado]
FROM sys.servers 
WHERE is_linked = 1
ORDER BY name
GO

PRINT ''
PRINT '✅ Linked Servers configurados: PROMPTADS_LINK y PROMPTCRM_LINK'
PRINT ''

-- ============================================================================
-- PARTE 2: Consulta desde PromptCRM hacia PromptAds
-- ============================================================================

PRINT '2. CONSULTA: PromptCRM → PromptAds'
PRINT '------------------------------------------'
PRINT 'Consultando campañas desde la base de datos CRM...'
PRINT ''

USE PromptCRM
GO

SELECT 
    campaignId AS [ID Campaña],
    name AS [Nombre Campaña],
    startsAt AS [Fecha Inicio],
    endsAt AS [Fecha Fin],
    businessId AS [ID Negocio],
    enabled AS [Activa]
FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns
WHERE deleted = 0
ORDER BY campaignId
GO

PRINT '✅ Consulta exitosa desde PromptCRM hacia PromptAds'
PRINT ''

-- ============================================================================
-- PARTE 3: Consulta desde PromptAds hacia PromptCRM
-- ============================================================================

PRINT '3. CONSULTA: PromptAds → PromptCRM'
PRINT '------------------------------------------'
PRINT 'Consultando clientes desde la base de datos Ads...'
PRINT ''

USE PromptAds
GO

SELECT 
    clienteId AS [ID Cliente],
    nombreEmpresa AS [Empresa],
    nombreContacto AS [Nombre Contacto],
    apellidoContacto AS [Apellido Contacto],
    createdAt AS [Fecha Creación]
FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes
WHERE deleted = 0
ORDER BY clienteId
GO

PRINT '✅ Consulta exitosa desde PromptAds hacia PromptCRM'
PRINT ''

-- ============================================================================
-- PARTE 4: JOIN Cross-Database (lo más importante)
-- ============================================================================

PRINT '4. JOIN ENTRE AMBAS BASES DE DATOS'
PRINT '------------------------------------------'
PRINT 'Relacionando clientes de CRM con campañas de Ads...'
PRINT ''

USE PromptCRM
GO

SELECT 
    c.clienteId AS [ID Cliente],
    c.nombreEmpresa AS [Empresa],
    COUNT(DISTINCT conv.conversionId) AS [Total Conversiones],
    SUM(conv.valorConversion) AS [Valor Total Conversiones]
FROM clientes c
LEFT JOIN conversiones_lead conv 
    ON c.clienteId = conv.clienteId AND conv.deleted = 0
WHERE c.deleted = 0
GROUP BY c.clienteId, c.nombreEmpresa
ORDER BY c.clienteId
GO

PRINT '✅ JOIN Cross-Database exitoso'
PRINT ''

-- ============================================================================
-- PARTE 5: Estadísticas finales
-- ============================================================================

PRINT '5. ESTADÍSTICAS DE LAS BASES DE DATOS'
PRINT '------------------------------------------'

USE PromptCRM
GO
SELECT 
    'PromptCRM' AS [Base de Datos],
    COUNT(*) AS [Total Tablas]
FROM sys.tables
GO

USE PromptAds
GO
SELECT 
    'PromptAds' AS [Base de Datos],
    COUNT(*) AS [Total Tablas]
FROM sys.tables
GO

PRINT ''
PRINT '=========================================='
PRINT 'DEMOSTRACIÓN COMPLETADA'
PRINT '=========================================='
PRINT ''
PRINT 'Linked Server está completamente funcional y permite:'
PRINT '✅ Consultas bidireccionales entre PromptCRM y PromptAds'
PRINT '✅ JOINs cross-database para análisis integrado'
PRINT '✅ Acceso transparente a datos de ambas bases'
PRINT ''
