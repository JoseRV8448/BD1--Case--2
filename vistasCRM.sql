USE PromptCRM;
GO

-------------------- CREACIÓN DE NUEVAS VISTAS --------------------


-- VISTA 1: Interacciones Mensuales
CREATE VIEW vw_interacciones_mensuales
WITH SCHEMABINDING
AS
SELECT 
    c.clienteId,
    c.nombreEmpresa,
    YEAR(i.fechaInteraccion) AS anio,
    MONTH(i.fechaInteraccion) AS mes,
    i.canalId,
    COUNT_BIG(*) AS cantidadInteracciones,
    SUM(ISNULL(i.duracionMinutos, 0)) AS tiempoTotal
FROM dbo.clientes c
INNER JOIN dbo.interacciones i 
    ON c.clienteId = i.clienteId 
    AND c.deleted = 0 
    AND i.deleted = 0
GROUP BY 
    c.clienteId, 
    c.nombreEmpresa, 
    YEAR(i.fechaInteraccion), 
    MONTH(i.fechaInteraccion), 
    i.canalId;
GO

-- VISTA 2: Conversiones Mensuales
CREATE VIEW vw_conversiones_mensuales
WITH SCHEMABINDING
AS
SELECT 
    c.clienteId,
    YEAR(conv.fechaConversion) AS anio,
    MONTH(conv.fechaConversion) AS mes,
    COUNT_BIG(*) AS cantidadConversiones,
    SUM(conv.valorConversion) AS valorTotal
FROM dbo.clientes c
INNER JOIN dbo.conversiones_lead conv 
    ON c.clienteId = conv.clienteId
    AND c.deleted = 0 
    AND conv.deleted = 0
GROUP BY 
    c.clienteId, 
    YEAR(conv.fechaConversion), 
    MONTH(conv.fechaConversion);
GO

-- VISTA 3: Efectividad por Canal
CREATE VIEW vw_efectividad_canales
WITH SCHEMABINDING
AS
SELECT 
    i.canalId,
    YEAR(i.fechaInteraccion) AS anio,
    MONTH(i.fechaInteraccion) AS mes,
    COUNT_BIG(*) AS totalInteracciones,
    SUM(ISNULL(i.duracionMinutos, 0)) AS tiempoTotal
FROM dbo.interacciones i
WHERE i.deleted = 0
GROUP BY 
    i.canalId, 
    YEAR(i.fechaInteraccion), 
    MONTH(i.fechaInteraccion);
GO

-- VISTA 4: Leads por Fuente
CREATE VIEW vw_leads_por_fuente
WITH SCHEMABINDING
AS
SELECT 
    l.fuenteLeadId,
    l.estadoLeadId,
    YEAR(l.createdAt) AS anio,
    MONTH(l.createdAt) AS mes,
    COUNT_BIG(*) AS cantidadLeads,
    SUM(ISNULL(l.puntajeLead, 0)) AS sumaPuntajes
FROM dbo.leads l
WHERE l.deleted = 0
GROUP BY 
    l.fuenteLeadId, 
    l.estadoLeadId, 
    YEAR(l.createdAt), 
    MONTH(l.createdAt);
GO

-- VISTA 5: Performance de Bots
CREATE VIEW vw_performance_bots
WITH SCHEMABINDING
AS
SELECT 
    sb.tipoBot,
    sb.canalId,
    CAST(sb.inicioSesion AS DATE) AS fecha,
    COUNT_BIG(*) AS totalSesiones,
    SUM(ISNULL(sb.duracionSegundos, 0)) AS sumaDuracion
FROM dbo.sesiones_bot_cliente sb
GROUP BY 
    sb.tipoBot, 
    sb.canalId, 
    CAST(sb.inicioSesion AS DATE);
GO

-- VISTA 6: Campañas por Cliente
CREATE VIEW vw_campanas_por_cliente
WITH SCHEMABINDING
AS
SELECT 
    cc.clienteId,
    rc.utmCampaign,
    rc.nombreCampana,
    COUNT_BIG(*) AS totalAsociaciones
FROM dbo.campanas_cliente cc
INNER JOIN dbo.referencias_campanas rc 
    ON cc.referenciaId = rc.referenciaId
GROUP BY 
    cc.clienteId, 
    rc.utmCampaign, 
    rc.nombreCampana;
GO

-------------------- CREAR TODOS LOS ÍNDICES --------------------


CREATE UNIQUE CLUSTERED INDEX idx_vw_interacciones_pk
ON vw_interacciones_mensuales(clienteId, anio, mes, canalId);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vw_conversiones_pk
ON vw_conversiones_mensuales(clienteId, anio, mes);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vw_efectividad_canales_pk
ON vw_efectividad_canales(canalId, anio, mes);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vw_leads_fuente_pk
ON vw_leads_por_fuente(fuenteLeadId, estadoLeadId, anio, mes);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vw_performance_bots_pk
ON vw_performance_bots(tipoBot, canalId, fecha);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vw_campanas_cliente_pk
ON vw_campanas_por_cliente(clienteId, utmCampaign);
GO



--------------- MOSTRAR Y PROBAR LAS VISTAS --------------------

-- Ver algunos datos de ejemplo (solo las primeras filas)
SELECT TOP 10 * FROM vw_interacciones_mensuales;
SELECT TOP 10 * FROM vw_conversiones_mensuales;
SELECT TOP 10 * FROM vw_efectividad_canales;
SELECT TOP 10 * FROM vw_leads_por_fuente;
SELECT TOP 10 * FROM vw_performance_bots;
SELECT TOP 10 * FROM vw_campanas_por_cliente;
GO
