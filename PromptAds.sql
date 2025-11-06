/* 
PromptAds - Base de datos encargada de generación y manejo de campañas de digital marketing.
*/
DROP TABLE IF EXISTS PACampaignBudgetTxns
DROP TABLE IF EXISTS PACampaignBudgetAllocations
DROP TABLE IF EXISTS PAPayments
DROP TABLE IF EXISTS PAInfluencerXAd
DROP TABLE IF EXISTS PAInfluencerXSocials
DROP TABLE IF EXISTS PAInfluencerSocials
DROP TABLE IF EXISTS PAInfluencers
DROP TABLE IF EXISTS PARectrem
DROP TABLE IF EXISTS PAAdEvents
DROP TABLE IF EXISTS PAAdsXTarget
DROP TABLE IF EXISTS PATargetXValue
DROP TABLE IF EXISTS PATarget
DROP TABLE IF EXISTS PAScheduleEventXChannel
DROP TABLE IF EXISTS PAScheduleEvents
DROP TABLE IF EXISTS PAAdXChannel
DROP TABLE IF EXISTS PAChannels
DROP TABLE IF EXISTS PACallToActions
DROP TABLE IF EXISTS PAAds
DROP TABLE IF EXISTS PACampaigns
DROP TABLE IF EXISTS PABusinesses
DROP TABLE IF EXISTS PASubXUser
DROP TABLE IF EXISTS PAFeatureXSubscription
DROP TABLE IF EXISTS PASubscriptions
DROP TABLE IF EXISTS PASubFeatures
DROP TABLE IF EXISTS PAUserXRole
DROP TABLE IF EXISTS PAPermissionxRole
DROP TABLE IF EXISTS PAUsers
DROP TABLE IF EXISTS PAPopulationFeatureValues
DROP TABLE IF EXISTS PAPopulationFeatures
DROP TABLE IF EXISTS PAPaymentTypes
DROP TABLE IF EXISTS PAPaymentStatuses
DROP TABLE IF EXISTS PAPaymentMethods
DROP TABLE IF EXISTS PAAddressLines
DROP TABLE IF EXISTS PAAddresses
DROP TABLE IF EXISTS PACities
DROP TABLE IF EXISTS PAStates
DROP TABLE IF EXISTS PACountries
DROP TABLE IF EXISTS PAScheduleEventStatuses
DROP TABLE IF EXISTS PAScheduleEventTypes
DROP TABLE IF EXISTS PAAdXChannelStatus
DROP TABLE IF EXISTS PAChannelTypes
DROP TABLE IF EXISTS PABusinessStatuses
DROP TABLE IF EXISTS PAPermissions
DROP TABLE IF EXISTS PARoles
DROP TABLE IF EXISTS PAUserStatuses
DROP TABLE IF EXISTS PAUserTypes
DROP TABLE IF EXISTS PALogLevels
DROP TABLE IF EXISTS PALogSources
DROP TABLE IF EXISTS PALogTypes
DROP TABLE IF EXISTS PAMediaSources
DROP TABLE IF EXISTS PAMediaPlatforms
DROP TABLE IF EXISTS PAEventTypes
DROP TABLE IF EXISTS PACallToActionTypes
DROP TABLE IF EXISTS PATxnTypes

-- -----------------------------------------------------------------------
CREATE DATABASE PromptAds
USE PromptAds

CREATE TABLE PATxnTypes (
	txnTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL
)
CREATE TABLE PACallToActionTypes (
	ctaTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL
)
CREATE TABLE PAEventTypes (
	eventTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL
)
CREATE TABLE PAMediaPlatforms (
	platformId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL,
	enabled BIT NOT NULL,
	registeredAt DATETIME2 DEFAULT GETDATE(),
	deleted BIT DEFAULT 0
)
CREATE TABLE PAMediaSources (
	mediaSourceId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL,
	enabled BIT NOT NULL,
	platformId INT,

	CONSTRAINT FK_MediaSources_Platforms FOREIGN KEY (platformId) REFERENCES PAMediaPlatforms (platformId)
)
CREATE TABLE PALogTypes (
	logTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PALogSources (
	logSourceId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PALogLevels (
	logLevelId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (20) NOT NULL
)
CREATE TABLE PAUserTypes (
	userTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL
)
CREATE TABLE PAUserStatuses (
	userStatusId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (20) NOT NULL
)
CREATE TABLE PARoles (
	roleId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
	enabled BIT DEFAULT 1,
	createdAt DATETIME2 DEFAULT GETDATE()
)
CREATE TABLE PAPermissions (
	permissionId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL, -- Texto visible para usuarios; puede cambiar sin afectar la lógica interna, a diferencia de code que está pensado más en backend.
	enabled BIT DEFAULT 1,
	description VARCHAR(100) NOT NULL,
	code VARCHAR(50) --El propósito de este code es tener un identificador más legible q id, nada más. (tipo "EDIT_USERS" o "VIEW_CAMPAIGNS")
)
CREATE TABLE PABusinessStatuses (
	businessStatusId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PAChannelTypes (
	channelTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL,
	enabled BIT DEFAULT 1
)
CREATE TABLE PAAdXChannelStatus (
	adXchannelStatusId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PAScheduleEventTypes (
	scheduleEventTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PAScheduleEventStatuses (
	scheduleEventStatusId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL
)
CREATE TABLE PACountries (
	countryId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL
)
CREATE TABLE PAStates (
	stateId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL,
	countryId INT,
	CONSTRAINT FK_States_Countries FOREIGN KEY (countryId) REFERENCES PACountries (countryId)
)
CREATE TABLE PACities (
	cityId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL,
	stateId INT,
	CONSTRAINT FK_Cities_States FOREIGN KEY (stateId) REFERENCES PAStates (stateId)
)
CREATE TABLE PAAddresses (
	addressId INT PRIMARY KEY IDENTITY(1,1),
	zipCode INT NOT NULL,
	cityId INT,
	CONSTRAINT FK_Addresses_Cities FOREIGN KEY (cityId) REFERENCES PACities (cityId)
)
CREATE TABLE PAAddressLines (
	addressLineId INT PRIMARY KEY IDENTITY(1,1),
	line1 NVARCHAR (100) NOT NULL,
	line2 NVARCHAR (100),
	addressId INT,
	CONSTRAINT FK_AddressLines_Addresses FOREIGN KEY (addressId) REFERENCES PAAddresses (addressId)
)
CREATE TABLE PAPaymentMethods (
	paymentMethodId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
	enabled BIT DEFAULT 1
)
CREATE TABLE PAPaymentStatuses (
	paymentStatusId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
)
CREATE TABLE PAPaymentTypes (
	paymentTypeId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
	description VARCHAR (70)
)
CREATE TABLE PAPopulationFeatures (
	popFeatId INT PRIMARY KEY IDENTITY(1,1),
	label VARCHAR (30) NOT NULL
)
CREATE TABLE PAPopulationFeatureValues (
	popFeatValId INT PRIMARY KEY IDENTITY(1,1),
	popFeatId INT NOT NULL,
	maxValue INT,
	minValue INT,
	textValue VARCHAR (20),

	CONSTRAINT FK_PopFeatVals_PopFeatures FOREIGN KEY (popFeatId) REFERENCES PAPopulationFeatures (popFeatId)
)
CREATE TABLE PAUsers (
	userId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL,
	email VARCHAR (50) UNIQUE NOT NULL,
	phone VARCHAR (50) UNIQUE NOT NULL,
	createdAt DATETIME2 DEFAULT GETDATE(),
	lastLogin DATETIME2 NULL,
	userStatusId INT NOT NULL,
	userTypeId INT NOT NULL,

	CONSTRAINT FK_Users_UserStatus FOREIGN KEY (userStatusId) REFERENCES PAUserStatuses (userStatusId),
	CONSTRAINT FK_Users_UserTypes FOREIGN KEY (userTypeId) REFERENCES PAUserTypes (userTypeId)
)
CREATE TABLE PAPermissionxRole (
	permissionXroleId INT PRIMARY KEY IDENTITY(1,1),
	permissionId INT NOT NULL,
	roleId INT NOT NULL,
	enabled BIT DEFAULT 1,

	CONSTRAINT FK_PermXRoles_Permissions FOREIGN KEY (permissionId) REFERENCES PAPermissions (permissionId),
	CONSTRAINT FK_PermXRoles_Roles FOREIGN KEY (roleId) REFERENCES PARoles (roleId)
)
CREATE TABLE PAUserXRole (
	userXroleId INT PRIMARY KEY IDENTITY(1,1),
	userId INT NOT NULL,
	roleId INT NOT NULL,
	enabled BIT DEFAULT 1,

	CONSTRAINT FK_UserXRole_Users FOREIGN KEY (userId) REFERENCES PAUsers (userId),
	CONSTRAINT FK_UserXRole_Roles FOREIGN KEY (roleId) REFERENCES PARoles (roleId),
)

/*
	Sistema de suscripciones:
	- PASubscriptions: Los planes de suscripción que se pueden comprar. (starter, premium, etc)
	- PASubFeatures: Capacidades que puede tener un plan, los features como tal pues. (acceso a IA, campañas activas máximas, etc)
	- PAFeatureXSubscription: Qué features se incluyen en qué plan. Tabla intermedia
*/

CREATE TABLE PASubFeatures (
	subFeatureId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (40) NOT NULL, -- Texto visible para usuarios; puede cambiar sin afectar la lógica interna, a diferencia de code que está pensado más en backend.
	description NVARCHAR (150) NOT NULL,
	code VARCHAR (20) NOT NULL, --El propósito de este code es tener un identificador más legible q id, nada más.
	dataType VARCHAR (20) NOT NULL -- Qué tipo de dato debe tener el valor asociado al feature (ej: si el feature es Acceso a IA --> dataType = BIT)
)
CREATE TABLE PASubscriptions (
	subscriptionId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (25) NOT NULL,
	description NVARCHAR (200) NOT NULL,
	price DECIMAL(10,2) NOT NULL,
	enabled BIT DEFAULT 1
)
CREATE TABLE PAFeatureXSubscription (
	featXsubId INT PRIMARY KEY IDENTITY(1,1),
	subscriptionId INT,
	subFeatureId INT,
	enabled BIT DEFAULT 1,
	value VARCHAR (45)

	CONSTRAINT FK_FeatXSub_Subscriptions FOREIGN KEY (subscriptionId) REFERENCES PASubscriptions (subscriptionId),
	CONSTRAINT FK_FeatXSub_SubFeatures FOREIGN KEY (subFeatureId) REFERENCES PASubFeatures (subFeatureId)
)
CREATE TABLE PASubXUser (
	subXuserId INT PRIMARY KEY IDENTITY(1,1),
	userId INT,
	subscriptionId INT,

	CONSTRAINT FK_SubXUser_Subscriptions FOREIGN KEY (subscriptionId) REFERENCES PASubscriptions (subscriptionId),
	CONSTRAINT FK_SubXUser_Users FOREIGN KEY (userId) REFERENCES PAUsers (userId)
)
CREATE TABLE PABusinesses (
	businessId INT PRIMARY KEY IDENTITY(1,1),
	marketName VARCHAR (50) NOT NULL,
	legalName VARCHAR (50) NOT NULL,
	email VARCHAR (60) UNIQUE NOT NULL,
	phone VARCHAR (20) NOT NULL,
	registeredAt DATETIME2 NULL,
	businessStatusId INT,
	addressId INT,
	createdBy_userId INT,

	CONSTRAINT FK_Businesses_Users FOREIGN KEY (createdBy_userId) REFERENCES PAUsers (userId),
	CONSTRAINT FK_Businesses_Addresses FOREIGN KEY (addressId) REFERENCES PAAddresses (addressId),
	CONSTRAINT FK_Businesses_BusinessStatuses FOREIGN KEY (addressId) REFERENCES PABusinessStatuses (businessStatusId),
)
CREATE TABLE PACampaigns (
	campaignId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (90) NOT NULL,
	budgetTotal DECIMAL (10,2) NOT NULL,
	startsAt DATETIME2 NOT NULL,
	endsAt DATETIME2 NOT NULL,
	enabled BIT DEFAULT 1,
	deleted BIT DEFAULT 0,
	businessId INT,

	CONSTRAINT FK_Campaigns_Businesses FOREIGN KEY (businessId) REFERENCES PABusinesses (businessId)
)
CREATE TABLE PAAds (
	adId INT PRIMARY KEY IDENTITY(1,1),
	campaignId INT,
	headline VARCHAR (100) NOT NULL,
	format VARCHAR (30) NOT NULL,
	mediaURL VARCHAR (500) NOT NULL,
	createdAt DATETIME2 DEFAULT GETDATE(),
	updatedAt DATETIME2 NULL,
	enabled BIT DEFAULT 1

	CONSTRAINT FK_Ads_Campaigns FOREIGN KEY (campaignId) REFERENCES PACampaigns (campaignId)
)
CREATE TABLE PACallToActions (
	ctaId INT PRIMARY KEY IDENTITY(1,1),
	adId INT,
	label VARCHAR (60) NOT NULL,
	orderInAd INT NOT NULL,
	targetURL VARCHAR (500) NOT NULL,
	enabled BIT DEFAULT 1,
	ctaTypeId INT,

	CONSTRAINT FK_CallToActions_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId),
	CONSTRAINT FK_CallToActions_CtaTypes FOREIGN KEY (ctaTypeId) REFERENCES PACallToActionTypes (ctaTypeId)
)
CREATE TABLE PAChannels (
	channelId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (50) NOT NULL,
	enabled BIT DEFAULT 1,
	channelTypeId INT,
	integrationURL VARCHAR (500) NOT NULL,
	requiresAuth BIT NOT NULL,
	supportsScheduling BIT NOT NULL,
	supportsAnalytics BIT NOT NULL,
	apiVersion VARCHAR (20) NOT NULL,
	documentationURL VARCHAR (500) NOT NULL,

	CONSTRAINT FK_Channels_ChannelTypes FOREIGN KEY (channelTypeId) REFERENCES PAChannelTypes (channelTypeId)
)
CREATE TABLE PAAdXChannel (
	adXchannelId INT PRIMARY KEY IDENTITY(1,1),
	adId INT,
	channelId INT,
	customURL VARCHAR (500) NOT NULL,
	createdAt DATETIME DEFAULT GETDATE(),
	adXchannelStatusId INT,

	CONSTRAINT FK_AdXChannel_AdXChannelStatus FOREIGN KEY (adXchannelStatusId) REFERENCES PAAdXChannelStatus (adXchannelStatusId),
	CONSTRAINT FK_AdXChannel_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId),
	CONSTRAINT FK_AdXChannel_Channels FOREIGN KEY (channelId) REFERENCES PAChannels (channelId)
)
CREATE TABLE PAScheduleEvents (
	scheduleEventId INT PRIMARY KEY IDENTITY(1,1),
	adId INT,
	campaignId INT,
	scheduleEventTypeId INT,
	scheduleEventStatus INT,
	scheduledFor DATETIME2 NOT NULL,
	executedAt DATETIME2 NULL,
	detail VARCHAR (80) NOT NULL,
	recurrenceRule NVARCHAR(MAX) NULL, -- Sustituye el datatype JSON
	triggeredBy_userId INT,

	CONSTRAINT FK_ScheduleEvents_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId),
	CONSTRAINT FK_ScheduleEvents_Campaigns FOREIGN KEY (campaignId) REFERENCES PACampaigns (campaignId),
	CONSTRAINT FK_ScheduleEvents_ScheduleEventStatuses FOREIGN KEY (scheduleEventStatus) REFERENCES PAScheduleEventStatuses (scheduleEventStatusId),
	CONSTRAINT FK_ScheduleEvents_ScheduleEventTypes FOREIGN KEY (scheduleEventTypeId) REFERENCES PAScheduleEventTypes (scheduleEventTypeId),
	CONSTRAINT FK_ScheduleEvents_Users FOREIGN KEY (triggeredBy_userId) REFERENCES PAUsers (userId)
)
CREATE TABLE PAScheduleEventXChannel (
	eventXchannelId INT PRIMARY KEY IDENTITY(1,1),
	scheduleEventId INT,
	channelId INT,
	customStartDate DATETIME2 NOT NULL,
	executedAt DATETIME2,
	enabled BIT DEFAULT 1,

	CONSTRAINT FK_ScheduleEventXChannel_ScheduleEvents FOREIGN KEY (scheduleEventId) REFERENCES PAScheduleEvents (scheduleEventId),
	CONSTRAINT FK_ScheduleEventXChannel_Channels FOREIGN KEY (channelId) REFERENCES PAChannels (channelId)
)
CREATE TABLE PATargets (
	targetId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
	enabled BIT DEFAULT 1,
	createdBy_userId INT,

	CONSTRAINT FK_Targets_Users FOREIGN KEY (createdBy_userId) REFERENCES PAUsers (userId)
)
CREATE TABLE PATargetXValue (
	targetXvalId INT PRIMARY KEY IDENTITY(1,1),
	targetId INT,
	popFeatValId INT,
	included BIT NOT NULL,

	CONSTRAINT FK_TargetXValue_Targets FOREIGN KEY (targetId) REFERENCES PATargets (targetId),
	CONSTRAINT FK_TargetXValue_PopFeatVal FOREIGN KEY (popFeatValId) REFERENCES PAPopulationFeatureValues (popFeatValId)
)
CREATE TABLE PAAdsXTarget (
	adXtargetId INT PRIMARY KEY IDENTITY(1,1),
	adId INT,
	targetId INT,

	CONSTRAINT FK_AdXTarget_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId),
	CONSTRAINT FK_AdXTarget_Targets FOREIGN KEY (targetId) REFERENCES PATargets (targetId)
)
CREATE TABLE PAAdEvents (
	eventId INT PRIMARY KEY IDENTITY(1,1),
	adId INT,
	eventTypeId INT,
	mediaSourceId INT,
	ocurredAt DATETIME2 DEFAULT GETDATE(),
	extraData NVARCHAR(MAX) NULL, -- Sustituye el datatype JSON

	CONSTRAINT FK_AdEvents_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId),
	CONSTRAINT FK_AdEvents_EventTypes FOREIGN KEY (eventTypeId) REFERENCES PAEventTypes (eventTypeId),
	CONSTRAINT FK_AdEvents_MediaSource FOREIGN KEY (mediaSourceId) REFERENCES PAMediaSources (mediaSourceId),
)
CREATE TABLE PARectrem (
	rectremId INT PRIMARY KEY IDENTITY(1,1),
	adXchannelId INT,
	recordedAt DATETIME2 DEFAULT GETDATE(),
	cost DECIMAL (10,2) NOT NULL,
	revenue DECIMAL (10,2) NOT NULL,
	clicks INT NOT NULL,
	impressions INT NOT NULL,
	reach INT NOT NULL,
	score DECIMAL (10,2) NOT NULL, -- Estos son los números q se tienen q ver como en los stocks

	CONSTRAINT FK_Rectrem_AdXChannel FOREIGN KEY (adXchannelId) REFERENCES PAAdXChannel (adXchannelId)
)
CREATE TABLE PAInfluencers (
	influencerId INT PRIMARY KEY IDENTITY(1,1),
	username VARCHAR (20) NOT NULL,
	realName VARCHAR (50) NOT NULL,
	followers INT NOT NULL,
	email VARCHAR (50) UNIQUE NOT NULL,
	enabled BIT DEFAULT 1
)
CREATE TABLE PAInfluencerSocials (
	influencerSocialsId INT PRIMARY KEY IDENTITY(1,1),
	name VARCHAR (30) NOT NULL,
	enabled BIT DEFAULT 1
)
CREATE TABLE PAInfluencerXSocials (
	influencerXsocialsId INT PRIMARY KEY IDENTITY(1,1),
	influencerId INT,
	influencerSocialsId INT,
	followers INT,
	enabled BIT DEFAULT 1

	CONSTRAINT FK_InfluencerXSocials_Influencers FOREIGN KEY (influencerId) REFERENCES PAInfluencers (influencerId),
	CONSTRAINT FK_InfluencerXSocials_InfluencerSocials FOREIGN KEY (influencerSocialsId) REFERENCES PAInfluencerSocials (influencerSocialsId)
)
CREATE TABLE PAInfluencerXAd (
	influencerXadId INT PRIMARY KEY IDENTITY(1,1),
	influencerId INT,
	adId INT,
	roleInAd VARCHAR (50) NOT NULL,
	performanceScore DECIMAL (10,2) NULL,
	impactNotes NVARCHAR (100) NULL,
	createdAt DATETIME2 DEFAULT GETDATE(),
	enabled BIT DEFAULT 1

	CONSTRAINT FK_InfluencerXAd_Influencers FOREIGN KEY (influencerId) REFERENCES PAInfluencers (influencerId),
	CONSTRAINT FK_InfluencerXAd_Ads FOREIGN KEY (adId) REFERENCES PAAds (adId)
)
CREATE TABLE PAPayments (
	paymentId INT PRIMARY KEY IDENTITY(1,1),
	txnAmount DECIMAL (10,2) NOT NULL,
	detail VARCHAR (100) NOT NULL,
	paidAtDate DATETIME2 DEFAULT GETDATE(),
	checksum VARCHAR (45) NOT NULL,
	paymentStatusId INT,
	paymentMethodId INT,
	paymentTypeId INT,

	CONSTRAINT FK_Payments_PaymentMethods FOREIGN KEY (paymentMethodId) REFERENCES PAPaymentMethods (paymentMethodId),
	CONSTRAINT FK_Payments_PaymentTypes FOREIGN KEY (paymentTypeId) REFERENCES PAPaymentTypes (paymentTypeId),
	CONSTRAINT FK_Payments_PaymentStatuses FOREIGN KEY (paymentStatusId) REFERENCES PAPaymentStatuses (paymentStatusId),
)
CREATE TABLE PACampaignBudgetAllocations (
	allocationId INT PRIMARY KEY IDENTITY(1,1),
	campaignId INT,
	channelId INT,
	budgetAssigned DECIMAL (10,2) NOT NULL,
	budgetUsed DECIMAL (10,2) NOT NULL,
	budgetAvailable AS (budgetAssigned - budgetUsed) PERSISTED, -- PERSISTED guarda el dato en disco, es más rápido de leer y se podría indexar si es necesario

	CONSTRAINT FK_BudgetAllocations_Campaigns FOREIGN KEY (campaignId) REFERENCES PACampaigns (campaignId),
	CONSTRAINT FK_BudgetAllocations_Channels FOREIGN KEY (channelId) REFERENCES PAChannels (channelId)
)
CREATE TABLE PACampaignBudgetTxns (
	txnId INT PRIMARY KEY IDENTITY(1,1),
	allocationId INT,
	txnTypeId INT,
	amount DECIMAL (10,2) NOT NULL,
	reason VARCHAR (100) NOT NULL,
	performedAt DATETIME2 DEFAULT GETDATE(),
	performedBy_userId INT,

	CONSTRAINT FK_CampaignBudgetTxns_CampBudgAllo FOREIGN KEY (allocationId) REFERENCES PACampaignBudgetAllocations (allocationId),
	CONSTRAINT FK_CampaignBudgetTxns_TxnTypes FOREIGN KEY (txnTypeId) REFERENCES PATxnTypes (txnTypeId),
	CONSTRAINT FK_CampaignBudgetTxns_Users FOREIGN KEY (performedBy_userId) REFERENCES PAUsers (userId)
)