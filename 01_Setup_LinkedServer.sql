-- ============================================================================
-- CONFIGURACIÓN LINKED SERVER: PromptCRM <-> PromptAds
-- ============================================================================

-- PARTE 1: Desde PromptCRM conectar a PromptAds
-- ============================================================================
USE PromptCRM
GO

-- Eliminar conexión existente si existe
IF EXISTS (SELECT * FROM sys.servers WHERE name = 'PROMPTADS_LINK')
BEGIN
    EXEC sp_dropserver 'PROMPTADS_LINK', 'droplogins'
    PRINT 'PROMPTADS_LINK existente eliminado'
END
GO

-- Crear Linked Server
EXEC sp_addlinkedserver 
    @server = 'PROMPTADS_LINK',
    @srvproduct = '',
    @provider = 'SQLNCLI',
    @datasrc = '(local)'  -- o 'localhost' o el nombre real del servidor
GO

-- Configuración de seguridad (Windows Authentication)
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'PROMPTADS_LINK',
    @useself = 'TRUE',
    @locallogin = NULL,
    @rmtuser = NULL,
    @rmtpassword = NULL
GO

-- Activar RPC (mejora de rendimiento)
EXEC sp_serveroption 'PROMPTADS_LINK', 'rpc out', 'true'
GO

-- Compatibilidad de collation
EXEC sp_serveroption 'PROMPTADS_LINK', 'collation compatible', 'true'
GO

PRINT '✅ PROMPTADS_LINK creado en PromptCRM'
GO


-- PARTE 2: Desde PromptAds conectar a PromptCRM
-- ============================================================================
USE PromptAds
GO

-- Eliminar conexión existente si existe
IF EXISTS (SELECT * FROM sys.servers WHERE name = 'PROMPTCRM_LINK')
BEGIN
    EXEC sp_dropserver 'PROMPTCRM_LINK', 'droplogins'
    PRINT 'PROMPTCRM_LINK existente eliminado'
END
GO

-- Crear Linked Server
EXEC sp_addlinkedserver 
    @server = 'PROMPTCRM_LINK',
    @srvproduct = '',
    @provider = 'SQLNCLI',
    @datasrc = '(local)'
GO

-- Configuración de seguridad (Windows Authentication)
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'PROMPTCRM_LINK',
    @useself = 'TRUE',
    @locallogin = NULL,
    @rmtuser = NULL,
    @rmtpassword = NULL
GO

-- Activar RPC
EXEC sp_serveroption 'PROMPTCRM_LINK', 'rpc out', 'true'
GO

-- Compatibilidad de collation
EXEC sp_serveroption 'PROMPTCRM_LINK', 'collation compatible', 'true'
GO

PRINT '✅ PROMPTCRM_LINK creado en PromptAds'
GO


-- ============================================================================
-- PRUEBAS: Verificar conexiones
-- ============================================================================

PRINT ''
PRINT '========== PROBANDO LINKED SERVERS =========='
PRINT ''

-- Prueba 1: PromptCRM → PromptAds
USE PromptCRM
GO

PRINT 'Prueba 1: Consultando PromptAds desde PromptCRM...'
BEGIN TRY
    SELECT TOP 3 
        name AS nombre_campana,
        startDate AS fecha_inicio,
        budgetAllocated AS presupuesto
    FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns
    PRINT '✅ PromptCRM → PromptAds: ÉXITO'
END TRY
BEGIN CATCH
    PRINT '❌ PromptCRM → PromptAds: FALLÓ'
    PRINT ERROR_MESSAGE()
END CATCH
GO

-- Prueba 2: PromptAds → PromptCRM
USE PromptAds
GO

PRINT 'Prueba 2: Consultando PromptCRM desde PromptAds...'
BEGIN TRY
    SELECT TOP 3 
        nombreEmpresa,
        nombreContacto,
        createdAt AS fecha_creacion
    FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes
    PRINT '✅ PromptAds → PromptCRM: ÉXITO'
END TRY
BEGIN CATCH
    PRINT '❌ PromptAds → PromptCRM: FALLÓ'
    PRINT ERROR_MESSAGE()
END CATCH
GO

PRINT ''
PRINT '========== CONFIGURACIÓN LINKED SERVER COMPLETADA =========='
PRINT ''
PRINT 'Ahora puedes usar:'
PRINT '  - PROMPTADS_LINK.PromptAds.dbo.[tabla] desde PromptCRM'
PRINT '  - PROMPTCRM_LINK.PromptCRM.dbo.[tabla] desde PromptAds'
PRINT ''
PRINT '========== EJEMPLOS DE USO =========='
PRINT ''
PRINT '-- Desde PromptCRM:'
PRINT 'SELECT * FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns'
PRINT ''
PRINT '-- Desde PromptAds:'
PRINT 'SELECT * FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes'
PRINT ''
