/* ===========================================================
   SCRIPT 1: Creación de Types (Table-Valued Parameters)
   -----------------------------------------------------------
   Autor: Equipo PromptAds
   Fecha: 2025-11-08
   
   IMPORTANTE: Ejecutar este script ANTES del stored procedure
   Los TYPE deben existir en la BD antes de crear el SP
   =========================================================== */

USE PromptAds;
GO

-- TYPE para PAAds
IF TYPE_ID('dbo.TVP_PAAds') IS NULL
    CREATE TYPE dbo.TVP_PAAds AS TABLE(
        headline VARCHAR(200) NOT NULL,
        bodyText NVARCHAR(3000) NULL,
        adDescription NVARCHAR(1000) NULL,
        format VARCHAR(50) NOT NULL,
        dimensions VARCHAR(50) NULL,
        adType VARCHAR(50) NULL,
        duration INT NULL,
        mediaURL VARCHAR(1000) NULL
    );
GO

-- TYPE para PACallToActions
IF TYPE_ID('dbo.TVP_PACallToActions') IS NULL
    CREATE TYPE dbo.TVP_PACallToActions AS TABLE(
        adIndex INT NOT NULL,
        label VARCHAR(100) NOT NULL,
        orderInAd INT NOT NULL,
        targetURL VARCHAR(1000) NOT NULL,
        ctaTypeId INT NOT NULL
    );
GO

-- TYPE para PAAdXChannel
IF TYPE_ID('dbo.TVP_PAAdXChannel') IS NULL
    CREATE TYPE dbo.TVP_PAAdXChannel AS TABLE(
        adIndex INT NOT NULL,
        channelId INT NOT NULL,
        customURL VARCHAR(1000) NULL,
        adXchannelStatusId INT NOT NULL
    );
GO

-- TYPE para PACampaignBudgetAllocations
IF TYPE_ID('dbo.TVP_PACampaignBudgetAlloc') IS NULL
    CREATE TYPE dbo.TVP_PACampaignBudgetAlloc AS TABLE(
        channelId INT NOT NULL,
        budgetAssigned DECIMAL(12,2) NOT NULL
    );
GO

-- TYPE para PATargetIds
IF TYPE_ID('dbo.TVP_PATargetIds') IS NULL
    CREATE TYPE dbo.TVP_PATargetIds AS TABLE(
        targetId INT NOT NULL
    );
GO

-- Verificar que todos los TYPE se crearon correctamente
SELECT 
    name AS TypeName,
    type_table_object_id,
    is_table_type
FROM sys.types
WHERE is_table_type = 1
ORDER BY name;

PRINT 'Todos los Table-Valued Parameters han sido creados exitosamente';
GO
