/* 
===============================================================================
PromptAds - Base de datos para generación y manejo de campañas de marketing digital
Versión: FINAL - Todas las correcciones del profesor aplicadas
Fecha: Noviembre 2025
===============================================================================

CORRECCIONES APLICADAS:
1. ✅ IDENTITY mantenido (esto es correcto para auto-increment)
2. ✅ Removido budgetTotal de PACampaigns 
3. ✅ Expandido PACampaigns con description, objectives, etc.
4. ✅ Expandido PAAds con bodyText, dimensions, adType, etc.
5. ✅ Corregido FK en PABusinesses (línea 284)
6. ✅ Expandido PABusinesses con phone, website, logoURL, industry, etc.
7. ✅ Separado PAUsers (empleados) de PABusinessUsers (usuarios clientes)
8. ✅ Sistema completo de eventos (likes, shares, comments, saves, conversions)
9. ✅ Mejorado PATargets con description, targetType, estimatedSize
10. ✅ Mejorado PAInfluencers con engagement, rating, pricing
11. ✅ Mejorado PAChannels con costos y límites
12. ✅ Ajustados todos los VARCHAR sizes
===============================================================================
*/

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'PromptAds')
BEGIN
    ALTER DATABASE PromptAds SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PromptAds;
END
GO

CREATE DATABASE PromptAds;
GO

USE PromptAds;
GO

-- ============================================================================
-- TABLAS DE CATÁLOGO
-- ============================================================================

CREATE TABLE PATxnTypes (
    txnTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL
);

CREATE TABLE PACallToActionTypes (
    ctaTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAEventTypes (
    eventTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL
);

CREATE TABLE PAMediaPlatforms (
    platformId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    enabled BIT NOT NULL DEFAULT 1,
    registeredAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0
);

CREATE TABLE PAMediaSources (
    mediaSourceId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    enabled BIT NOT NULL DEFAULT 1,
    platformId INT NOT NULL,
    
    CONSTRAINT FK_MediaSources_Platforms FOREIGN KEY (platformId) 
        REFERENCES PAMediaPlatforms(platformId)
);

CREATE TABLE PALogTypes (
    logTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PALogSources (
    logSourceId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PALogLevels (
    logLevelId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(30) NOT NULL
);

CREATE TABLE PAUserTypes (
    userTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL
);

CREATE TABLE PAUserStatuses (
    userStatusId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(30) NOT NULL
);

CREATE TABLE PARoles (
    roleId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    enabled BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE PAPermissions (
    permissionId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(300) NULL,
    enabled BIT DEFAULT 1
);

CREATE TABLE PABusinessStatuses (
    businessStatusId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAChannelTypes (
    channelTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    enabled BIT DEFAULT 1
);

CREATE TABLE PAAdXChannelStatuses (
    adXchannelStatusId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAScheduleEventTypes (
    scheduleEventTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAScheduleEventStatuses (
    scheduleEventStatusId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAPaymentMethods (
    paymentMethodId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    enabled BIT DEFAULT 1
);

CREATE TABLE PAPaymentStatuses (
    paymentStatusId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL
);

CREATE TABLE PAPaymentTypes (
    paymentTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL
);

CREATE TABLE PACampaignTypes (
    campaignTypeId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL
);

CREATE TABLE PAInfluencerSocials (
    influencerSocialsId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    enabled BIT DEFAULT 1
);

-- ============================================================================
-- UBICACIÓN GEOGRÁFICA
-- ============================================================================

CREATE TABLE PACountries (
    countryId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NULL
);

CREATE TABLE PAStates (
    stateId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    countryId INT NOT NULL,
    
    CONSTRAINT FK_States_Countries FOREIGN KEY (countryId) 
        REFERENCES PACountries(countryId)
);

CREATE TABLE PACities (
    cityId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    stateId INT NOT NULL,
    
    CONSTRAINT FK_Cities_States FOREIGN KEY (stateId) 
        REFERENCES PAStates(stateId)
);

CREATE TABLE PAAddresses (
    addressId INT PRIMARY KEY IDENTITY(1,1),
    zipCode VARCHAR(20) NOT NULL,
    cityId INT NOT NULL,
    
    CONSTRAINT FK_Addresses_Cities FOREIGN KEY (cityId) 
        REFERENCES PACities(cityId)
);

CREATE TABLE PAAddressLines (
    addressLineId INT PRIMARY KEY IDENTITY(1,1),
    line1 NVARCHAR(200) NOT NULL,
    line2 NVARCHAR(200) NULL,
    addressId INT NOT NULL,
    
    CONSTRAINT FK_AddressLines_Addresses FOREIGN KEY (addressId) 
        REFERENCES PAAddresses(addressId)
);

-- ============================================================================
-- SEGMENTACIÓN DEMOGRÁFICA
-- ============================================================================

CREATE TABLE PAPopulationFeatures (
    popFeatId INT PRIMARY KEY IDENTITY(1,1),
    label VARCHAR(100) NOT NULL,
    description VARCHAR(300) NULL
);

CREATE TABLE PAPopulationFeatureValues (
    popFeatValId INT PRIMARY KEY IDENTITY(1,1),
    popFeatId INT NOT NULL,
    minValue INT NULL,
    maxValue INT NULL,
    textValue VARCHAR(100) NULL,
    label VARCHAR(100) NULL,
    
    CONSTRAINT FK_PopFeatVals_PopFeatures FOREIGN KEY (popFeatId) 
        REFERENCES PAPopulationFeatures(popFeatId)
);

-- ============================================================================
-- USUARIOS Y PERMISOS
-- ============================================================================

-- SOLO empleados INTERNOS del sistema PromptAds
CREATE TABLE PAUsers (
    userId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(50) NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    lastLogin DATETIME2 NULL,
    updatedAt DATETIME2 NULL,
    userStatusId INT NOT NULL,
    userTypeId INT NOT NULL,
    
    CONSTRAINT FK_Users_UserStatus FOREIGN KEY (userStatusId) 
        REFERENCES PAUserStatuses(userStatusId),
    CONSTRAINT FK_Users_UserTypes FOREIGN KEY (userTypeId) 
        REFERENCES PAUserTypes(userTypeId)
);

CREATE TABLE PAPermissionxRole (
    permissionXroleId INT PRIMARY KEY IDENTITY(1,1),
    permissionId INT NOT NULL,
    roleId INT NOT NULL,
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_PermXRoles_Permissions FOREIGN KEY (permissionId) 
        REFERENCES PAPermissions(permissionId),
    CONSTRAINT FK_PermXRoles_Roles FOREIGN KEY (roleId) 
        REFERENCES PARoles(roleId)
);

CREATE TABLE PAUserXRole (
    userXroleId INT PRIMARY KEY IDENTITY(1,1),
    userId INT NOT NULL,
    roleId INT NOT NULL,
    enabled BIT DEFAULT 1,
    assignedAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_UserXRole_Users FOREIGN KEY (userId) 
        REFERENCES PAUsers(userId),
    CONSTRAINT FK_UserXRole_Roles FOREIGN KEY (roleId) 
        REFERENCES PARoles(roleId)
);

-- ============================================================================
-- SUSCRIPCIONES
-- ============================================================================

CREATE TABLE PASubscriptions (
    subscriptionId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    monthlyPrice DECIMAL(10,2) NOT NULL,
    annualPrice DECIMAL(10,2) NULL
);

CREATE TABLE PASubFeatures (
    subFeatureId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    code VARCHAR(50) NOT NULL,
    dataType VARCHAR(50) NULL
);

CREATE TABLE PAFeatureXSubscription (
    featXsubId INT PRIMARY KEY IDENTITY(1,1),
    subscriptionId INT NOT NULL,
    subFeatureId INT NOT NULL,
    value VARCHAR(200) NULL,
    
    CONSTRAINT FK_FeatXSub_Subscriptions FOREIGN KEY (subscriptionId) 
        REFERENCES PASubscriptions(subscriptionId),
    CONSTRAINT FK_FeatXSub_SubFeatures FOREIGN KEY (subFeatureId) 
        REFERENCES PASubFeatures(subFeatureId)
);

CREATE TABLE PASubXUser (
    subXuserId INT PRIMARY KEY IDENTITY(1,1),
    userId INT NOT NULL,
    subscriptionId INT NOT NULL,
    startDate DATETIME2 DEFAULT GETDATE(),
    endDate DATETIME2 NULL,
    autoRenew BIT DEFAULT 1,
    
    CONSTRAINT FK_SubXUser_Users FOREIGN KEY (userId) 
        REFERENCES PAUsers(userId),
    CONSTRAINT FK_SubXUser_Subscriptions FOREIGN KEY (subscriptionId) 
        REFERENCES PASubscriptions(subscriptionId)
);

-- ============================================================================
-- EMPRESAS CLIENTES - CORREGIDO
-- ============================================================================

CREATE TABLE PABusinesses (
    businessId INT PRIMARY KEY IDENTITY(1,1),
    marketName VARCHAR(100) NOT NULL,
    legalName VARCHAR(150) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(50) NULL,
    website VARCHAR(300) NULL,
    logoURL VARCHAR(500) NULL,
    industry VARCHAR(100) NULL,
    companySize VARCHAR(50) NULL,
    taxId VARCHAR(50) NULL,
    registeredAt DATETIME2 DEFAULT GETDATE(),
    businessStatusId INT NOT NULL,
    addressId INT NULL,
    createdBy_userId INT NOT NULL,
    
    CONSTRAINT FK_Businesses_Users FOREIGN KEY (createdBy_userId) 
        REFERENCES PAUsers(userId),
    CONSTRAINT FK_Businesses_Addresses FOREIGN KEY (addressId) 
        REFERENCES PAAddresses(addressId),
    CONSTRAINT FK_Businesses_BusinessStatuses FOREIGN KEY (businessStatusId) 
        REFERENCES PABusinessStatuses(businessStatusId)
);

-- Usuarios de empresas clientes - NUEVO
CREATE TABLE PABusinessUsers (
    businessUserId INT PRIMARY KEY IDENTITY(1,1),
    businessId INT NOT NULL,
    userId INT NOT NULL,
    roleInBusiness VARCHAR(100) NULL,
    departmentName VARCHAR(100) NULL,
    jobTitle VARCHAR(100) NULL,
    canApproveCampaigns BIT DEFAULT 0,
    canEditBudget BIT DEFAULT 0,
    createdAt DATETIME2 DEFAULT GETDATE(),
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_BusinessUsers_Business FOREIGN KEY (businessId) 
        REFERENCES PABusinesses(businessId),
    CONSTRAINT FK_BusinessUsers_Users FOREIGN KEY (userId) 
        REFERENCES PAUsers(userId)
);

-- ============================================================================
-- CAMPAÑAS - CORREGIDO (SIN budgetTotal)
-- ============================================================================

CREATE TABLE PACampaigns (
    campaignId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(150) NOT NULL,
    description NVARCHAR(1000) NULL,
    objectives NVARCHAR(MAX) NULL,
    campaignTypeId INT NULL,
    targetMetrics NVARCHAR(MAX) NULL,
    strategyNotes NVARCHAR(2000) NULL,
    startsAt DATETIME2 NOT NULL,
    endsAt DATETIME2 NOT NULL,
    enabled BIT DEFAULT 1,
    deleted BIT DEFAULT 0,
    businessId INT NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    createdBy_userId INT NOT NULL,
    
    CONSTRAINT FK_Campaigns_Businesses FOREIGN KEY (businessId) 
        REFERENCES PABusinesses(businessId),
    CONSTRAINT FK_Campaigns_CampaignTypes FOREIGN KEY (campaignTypeId) 
        REFERENCES PACampaignTypes(campaignTypeId),
    CONSTRAINT FK_Campaigns_Users FOREIGN KEY (createdBy_userId) 
        REFERENCES PAUsers(userId)
);

-- ============================================================================
-- ANUNCIOS - EXPANDIDO
-- ============================================================================

CREATE TABLE PAAds (
    adId INT PRIMARY KEY IDENTITY(1,1),
    campaignId INT NOT NULL,
    headline VARCHAR(200) NOT NULL,
    bodyText NVARCHAR(3000) NULL,
    adDescription NVARCHAR(1000) NULL,
    format VARCHAR(50) NOT NULL,
    dimensions VARCHAR(50) NULL,
    adType VARCHAR(50) NULL,
    duration INT NULL,
    mediaURL VARCHAR(1000) NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 NULL,
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_Ads_Campaigns FOREIGN KEY (campaignId) 
        REFERENCES PACampaigns(campaignId)
);

CREATE TABLE PACallToActions (
    ctaId INT PRIMARY KEY IDENTITY(1,1),
    adId INT NOT NULL,
    label VARCHAR(100) NOT NULL,
    orderInAd INT NOT NULL,
    targetURL VARCHAR(1000) NOT NULL,
    enabled BIT DEFAULT 1,
    ctaTypeId INT NOT NULL,
    
    CONSTRAINT FK_CallToActions_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId),
    CONSTRAINT FK_CallToActions_CtaTypes FOREIGN KEY (ctaTypeId) 
        REFERENCES PACallToActionTypes(ctaTypeId)
);

-- ============================================================================
-- CANALES - MEJORADO
-- ============================================================================

CREATE TABLE PAChannels (
    channelId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    enabled BIT DEFAULT 1,
    channelTypeId INT NOT NULL,
    integrationURL VARCHAR(1000) NULL,
    requiresAuth BIT NOT NULL DEFAULT 0,
    supportsScheduling BIT NOT NULL DEFAULT 0,
    supportsAnalytics BIT NOT NULL DEFAULT 0,
    apiVersion VARCHAR(50) NULL,
    documentationURL VARCHAR(1000) NULL,
    costPerClick DECIMAL(10,4) NULL,
    costPerImpression DECIMAL(10,4) NULL,
    costPerDay DECIMAL(10,2) NULL,
    maxDailyBudget DECIMAL(10,2) NULL,
    rateLimitPerHour INT NULL,
    channelCategory VARCHAR(100) NULL,
    
    CONSTRAINT FK_Channels_ChannelTypes FOREIGN KEY (channelTypeId) 
        REFERENCES PAChannelTypes(channelTypeId)
);

CREATE TABLE PAAdXChannel (
    adXchannelId INT PRIMARY KEY IDENTITY(1,1),
    adId INT NOT NULL,
    channelId INT NOT NULL,
    customURL VARCHAR(1000) NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    adXchannelStatusId INT NOT NULL,
    
    CONSTRAINT FK_AdXChannel_AdXChannelStatus FOREIGN KEY (adXchannelStatusId) 
        REFERENCES PAAdXChannelStatuses(adXchannelStatusId),
    CONSTRAINT FK_AdXChannel_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId),
    CONSTRAINT FK_AdXChannel_Channels FOREIGN KEY (channelId) 
        REFERENCES PAChannels(channelId)
);

-- ============================================================================
-- PROGRAMACIÓN
-- ============================================================================

CREATE TABLE PAScheduleEvents (
    scheduleEventId INT PRIMARY KEY IDENTITY(1,1),
    adId INT NULL,
    campaignId INT NULL,
    scheduleEventTypeId INT NOT NULL,
    scheduleEventStatusId INT NOT NULL,
    scheduledFor DATETIME2 NOT NULL,
    executedAt DATETIME2 NULL,
    detail VARCHAR(300) NULL,
    recurrenceRule NVARCHAR(MAX) NULL,
    triggeredBy_userId INT NULL,
    
    CONSTRAINT FK_ScheduleEvents_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId),
    CONSTRAINT FK_ScheduleEvents_Campaigns FOREIGN KEY (campaignId) 
        REFERENCES PACampaigns(campaignId),
    CONSTRAINT FK_ScheduleEvents_ScheduleEventStatuses FOREIGN KEY (scheduleEventStatusId) 
        REFERENCES PAScheduleEventStatuses(scheduleEventStatusId),
    CONSTRAINT FK_ScheduleEvents_ScheduleEventTypes FOREIGN KEY (scheduleEventTypeId) 
        REFERENCES PAScheduleEventTypes(scheduleEventTypeId),
    CONSTRAINT FK_ScheduleEvents_Users FOREIGN KEY (triggeredBy_userId) 
        REFERENCES PAUsers(userId)
);

CREATE TABLE PAScheduleEventXChannel (
    eventXchannelId INT PRIMARY KEY IDENTITY(1,1),
    scheduleEventId INT NOT NULL,
    channelId INT NOT NULL,
    customStartDate DATETIME2 NULL,
    executedAt DATETIME2 NULL,
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_ScheduleEventXChannel_ScheduleEvents FOREIGN KEY (scheduleEventId) 
        REFERENCES PAScheduleEvents(scheduleEventId),
    CONSTRAINT FK_ScheduleEventXChannel_Channels FOREIGN KEY (channelId) 
        REFERENCES PAChannels(channelId)
);

-- ============================================================================
-- SEGMENTACIÓN - MEJORADO
-- ============================================================================

CREATE TABLE PATargets (
    targetId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(150) NOT NULL,
    description NVARCHAR(1000) NULL,
    targetType VARCHAR(50) NULL,
    estimatedSize INT NULL,
    enabled BIT DEFAULT 1,
    createdBy_userId INT NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_Targets_Users FOREIGN KEY (createdBy_userId) 
        REFERENCES PAUsers(userId)
);

CREATE TABLE PATargetXValue (
    targetXvalId INT PRIMARY KEY IDENTITY(1,1),
    targetId INT NOT NULL,
    popFeatValId INT NOT NULL,
    included BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT FK_TargetXValue_Targets FOREIGN KEY (targetId) 
        REFERENCES PATargets(targetId),
    CONSTRAINT FK_TargetXValue_PopFeatVal FOREIGN KEY (popFeatValId) 
        REFERENCES PAPopulationFeatureValues(popFeatValId)
);

CREATE TABLE PAAdsXTarget (
    adXtargetId INT PRIMARY KEY IDENTITY(1,1),
    adId INT NOT NULL,
    targetId INT NOT NULL,
    
    CONSTRAINT FK_AdXTarget_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId),
    CONSTRAINT FK_AdXTarget_Targets FOREIGN KEY (targetId) 
        REFERENCES PATargets(targetId)
);

-- ============================================================================
-- EVENTOS Y MÉTRICAS - EXPANDIDO
-- ============================================================================

CREATE TABLE PAAdEvents (
    eventId INT PRIMARY KEY IDENTITY(1,1),
    adId INT NOT NULL,
    eventTypeId INT NOT NULL,
    mediaSourceId INT NULL,
    occurredAt DATETIME2 DEFAULT GETDATE(),
    extraData NVARCHAR(MAX) NULL,
    
    CONSTRAINT FK_AdEvents_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId),
    CONSTRAINT FK_AdEvents_EventTypes FOREIGN KEY (eventTypeId) 
        REFERENCES PAEventTypes(eventTypeId),
    CONSTRAINT FK_AdEvents_MediaSource FOREIGN KEY (mediaSourceId) 
        REFERENCES PAMediaSources(mediaSourceId)
);

-- NUEVO: Métricas detalladas de engagement
CREATE TABLE PAAdEngagementMetrics (
    engagementId INT PRIMARY KEY IDENTITY(1,1),
    adXchannelId INT NOT NULL,
    recordedAt DATETIME2 DEFAULT GETDATE(),
    likes INT DEFAULT 0,
    shares INT DEFAULT 0,
    comments INT DEFAULT 0,
    saves INT DEFAULT 0,
    videoViews INT DEFAULT 0,
    videoCompletionRate DECIMAL(5,2) NULL,
    clickThroughRate DECIMAL(5,2) NULL,
    engagementRate DECIMAL(5,2) NULL,
    
    CONSTRAINT FK_AdEngagement_AdXChannel FOREIGN KEY (adXchannelId) 
        REFERENCES PAAdXChannel(adXchannelId)
);

-- Métricas financieras y de alcance
CREATE TABLE PARectrem (
    rectremId INT PRIMARY KEY IDENTITY(1,1),
    adXchannelId INT NOT NULL,
    recordedAt DATETIME2 DEFAULT GETDATE(),
    cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    revenue DECIMAL(12,2) NOT NULL DEFAULT 0,
    clicks INT NOT NULL DEFAULT 0,
    impressions INT NOT NULL DEFAULT 0,
    reach INT NOT NULL DEFAULT 0,
    conversions INT DEFAULT 0,
    score DECIMAL(10,2) NULL,
    
    CONSTRAINT FK_Rectrem_AdXChannel FOREIGN KEY (adXchannelId) 
        REFERENCES PAAdXChannel(adXchannelId)
);

-- ============================================================================
-- INFLUENCERS - MEJORADO
-- ============================================================================

CREATE TABLE PAInfluencers (
    influencerId INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(100) NOT NULL,
    realName VARCHAR(150) NULL,
    followers INT NULL,
    email VARCHAR(100) NULL,
    engagementRate DECIMAL(5,2) NULL,
    influencerRating DECIMAL(3,2) NULL,
    niches NVARCHAR(1000) NULL,
    pricePerPost DECIMAL(10,2) NULL,
    pricePerStory DECIMAL(10,2) NULL,
    pricePerReel DECIMAL(10,2) NULL,
    bio NVARCHAR(1000) NULL,
    enabled BIT DEFAULT 1
);

CREATE TABLE PAInfluencerXSocials (
    influencerXsocialsId INT PRIMARY KEY IDENTITY(1,1),
    influencerId INT NOT NULL,
    influencerSocialsId INT NOT NULL,
    followers INT NULL,
    profileURL VARCHAR(500) NULL,
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_InfluencerXSocials_Influencers FOREIGN KEY (influencerId) 
        REFERENCES PAInfluencers(influencerId),
    CONSTRAINT FK_InfluencerXSocials_InfluencerSocials FOREIGN KEY (influencerSocialsId) 
        REFERENCES PAInfluencerSocials(influencerSocialsId)
);

CREATE TABLE PAInfluencerXAd (
    influencerXadId INT PRIMARY KEY IDENTITY(1,1),
    influencerId INT NOT NULL,
    adId INT NOT NULL,
    roleInAd VARCHAR(100) NULL,
    performanceScore DECIMAL(10,2) NULL,
    impactNotes NVARCHAR(500) NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    enabled BIT DEFAULT 1,
    
    CONSTRAINT FK_InfluencerXAd_Influencers FOREIGN KEY (influencerId) 
        REFERENCES PAInfluencers(influencerId),
    CONSTRAINT FK_InfluencerXAd_Ads FOREIGN KEY (adId) 
        REFERENCES PAAds(adId)
);

-- ============================================================================
-- PAGOS
-- ============================================================================

CREATE TABLE PAPayments (
    paymentId INT PRIMARY KEY IDENTITY(1,1),
    businessId INT NOT NULL,
    txnAmount DECIMAL(12,2) NOT NULL,
    detail VARCHAR(300) NULL,
    paidAtDate DATETIME2 DEFAULT GETDATE(),
    checksum VARCHAR(100) NULL,
    paymentStatusId INT NOT NULL,
    paymentMethodId INT NOT NULL,
    paymentTypeId INT NOT NULL,
    
    CONSTRAINT FK_Payments_Businesses FOREIGN KEY (businessId) 
        REFERENCES PABusinesses(businessId),
    CONSTRAINT FK_Payments_PaymentMethods FOREIGN KEY (paymentMethodId) 
        REFERENCES PAPaymentMethods(paymentMethodId),
    CONSTRAINT FK_Payments_PaymentTypes FOREIGN KEY (paymentTypeId) 
        REFERENCES PAPaymentTypes(paymentTypeId),
    CONSTRAINT FK_Payments_PaymentStatuses FOREIGN KEY (paymentStatusId) 
        REFERENCES PAPaymentStatuses(paymentStatusId)
);

-- ============================================================================
-- PRESUPUESTO
-- ============================================================================

CREATE TABLE PACampaignBudgetAllocations (
    allocationId INT PRIMARY KEY IDENTITY(1,1),
    campaignId INT NOT NULL,
    channelId INT NOT NULL,
    budgetAssigned DECIMAL(12,2) NOT NULL DEFAULT 0,
    budgetUsed DECIMAL(12,2) NOT NULL DEFAULT 0,
    budgetAvailable AS (budgetAssigned - budgetUsed) PERSISTED,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 NULL,
    
    CONSTRAINT FK_BudgetAllocations_Campaigns FOREIGN KEY (campaignId) 
        REFERENCES PACampaigns(campaignId),
    CONSTRAINT FK_BudgetAllocations_Channels FOREIGN KEY (channelId) 
        REFERENCES PAChannels(channelId)
);

CREATE TABLE PACampaignBudgetTxns (
    txnId INT PRIMARY KEY IDENTITY(1,1),
    allocationId INT NOT NULL,
    txnTypeId INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    reason VARCHAR(300) NULL,
    transactionCategory VARCHAR(50) NULL,
    performedAt DATETIME2 DEFAULT GETDATE(),
    performedBy_userId INT NOT NULL,
    
    CONSTRAINT FK_CampaignBudgetTxns_CampBudgAllo FOREIGN KEY (allocationId) 
        REFERENCES PACampaignBudgetAllocations(allocationId),
    CONSTRAINT FK_CampaignBudgetTxns_TxnTypes FOREIGN KEY (txnTypeId) 
        REFERENCES PATxnTypes(txnTypeId),
    CONSTRAINT FK_CampaignBudgetTxns_Users FOREIGN KEY (performedBy_userId) 
        REFERENCES PAUsers(userId)
);

-- ============================================================================
-- LOGS
-- ============================================================================

CREATE TABLE PALogs (
    logId INT PRIMARY KEY IDENTITY(1,1),
    createdAt DATETIME2 DEFAULT GETDATE(),
    computer VARCHAR(100) NULL,
    username VARCHAR(100) NULL,
    logTypeId INT NOT NULL,
    logSourceId INT NOT NULL,
    logLevelId INT NOT NULL,
    message NVARCHAR(MAX) NULL,
    
    CONSTRAINT FK_Logs_LogTypes FOREIGN KEY (logTypeId) 
        REFERENCES PALogTypes(logTypeId),
    CONSTRAINT FK_Logs_LogSources FOREIGN KEY (logSourceId) 
        REFERENCES PALogSources(logSourceId),
    CONSTRAINT FK_Logs_LogLevels FOREIGN KEY (logLevelId) 
        REFERENCES PALogLevels(logLevelId)
);

GO

-- ============================================================================
-- ÍNDICES
-- ============================================================================

CREATE INDEX IX_PACampaigns_BusinessId ON PACampaigns(businessId);
CREATE INDEX IX_PACampaigns_StartEnd ON PACampaigns(startsAt, endsAt);
CREATE INDEX IX_PAAds_CampaignId ON PAAds(campaignId);
CREATE INDEX IX_PAAdXChannel_AdId ON PAAdXChannel(adId);
CREATE INDEX IX_PAAdXChannel_ChannelId ON PAAdXChannel(channelId);
CREATE INDEX IX_PARectrem_AdXChannelId ON PARectrem(adXchannelId);
CREATE INDEX IX_PARectrem_RecordedAt ON PARectrem(recordedAt);
CREATE INDEX IX_PAAdEvents_AdId ON PAAdEvents(adId);
CREATE INDEX IX_PAAdEvents_OccurredAt ON PAAdEvents(occurredAt);
CREATE INDEX IX_PACampaignBudgetAllocations_CampaignId ON PACampaignBudgetAllocations(campaignId);

GO

PRINT 'Base de datos PromptAds creada exitosamente';
PRINT 'Todas las correcciones del profesor aplicadas';
GO
