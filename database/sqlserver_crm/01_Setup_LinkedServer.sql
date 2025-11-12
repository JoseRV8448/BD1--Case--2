-- ============================================================================
-- CONFIGURACIÓN LINKED SERVER: PromptCRM <-> PromptAds
-- Autor: Equipo PromptSales
-- ============================================================================

-- Configurar desde PromptCRM hacia PromptAds
USE PromptCRM
GO

EXEC sp_addlinkedserver 
    @server = 'PROMPTADS_LINK',
    @srvproduct = '',
    @provider = 'SQLNCLI',
    @datasrc = 'localhost'
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'PROMPTADS_LINK',
    @useself = 'TRUE'
GO

-- Configurar desde PromptAds hacia PromptCRM  
USE PromptAds
GO

EXEC sp_addlinkedserver 
    @server = 'PROMPTCRM_LINK',
    @srvproduct = '',
    @provider = 'SQLNCLI', 
    @datasrc = 'localhost'
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'PROMPTCRM_LINK',
    @useself = 'TRUE'
GO

-- Queries de prueba básicos
SELECT TOP 5 * FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns;
SELECT TOP 5 * FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes;