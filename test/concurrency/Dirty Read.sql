USE PromptCRM
GO

-- Habilitar IDENTITY_INSERT para cada tabla y luego insertar datos

SET IDENTITY_INSERT nv_tipos_cliente ON
INSERT INTO nv_tipos_cliente (tipoId, nombreTipo, descripcion)
VALUES 
    (1, 'Prospecto', 'Cliente potencial'),
    (2, 'Activo', 'Cliente con compras activas'),
    (3, 'Inactivo', 'Cliente sin actividad reciente')
SET IDENTITY_INSERT nv_tipos_cliente OFF

SET IDENTITY_INSERT nv_estados_cliente ON
INSERT INTO nv_estados_cliente (estadoId, nombreEstado)
VALUES 
    (1, 'Nuevo'),
    (2, 'En Proceso'),
    (3, 'Activo')
SET IDENTITY_INSERT nv_estados_cliente OFF

SET IDENTITY_INSERT nv_estados_lead ON
INSERT INTO nv_estados_lead (estadoId, nombreEstado, ordenFlujo)
VALUES 
    (1, 'Nuevo', 1),
    (2, 'Contactado', 2),
    (3, 'Calificado', 3)
SET IDENTITY_INSERT nv_estados_lead OFF

SET IDENTITY_INSERT nv_tipos_fuente_lead ON
INSERT INTO nv_tipos_fuente_lead (tipoId, nombreTipo)
VALUES 
    (1, 'Web'),
    (2, 'Referido'),
    (3, 'Campaña Ads')
SET IDENTITY_INSERT nv_tipos_fuente_lead OFF

SET IDENTITY_INSERT fuentes_lead ON
INSERT INTO fuentes_lead (fuenteId, tipoFuenteId, nombreFuente, descripcion)
VALUES 
    (1, 1, 'Sitio Web Corporativo', 'Leads desde formulario web'),
    (2, 3, 'Google Ads', 'Campañas de Google Ads')
SET IDENTITY_INSERT fuentes_lead OFF

SET IDENTITY_INSERT nv_tipos_interaccion ON
INSERT INTO nv_tipos_interaccion (tipoId, nombreTipo, descripcion)
VALUES 
    (1, 'Llamada', 'Llamada telefónica'),
    (2, 'Email', 'Correo electrónico'),
    (3, 'Reunión', 'Reunión presencial o virtual')
SET IDENTITY_INSERT nv_tipos_interaccion OFF

SET IDENTITY_INSERT nv_canales ON
INSERT INTO nv_canales (canalId, nombreCanal, descripcion, esDigital, permiteAutomatizacion)
VALUES 
    (1, 'Teléfono', 'Llamadas telefónicas', 0, 0),
    (2, 'Email', 'Correo electrónico', 1, 1),
    (3, 'WhatsApp', 'Mensajería WhatsApp', 1, 1)
SET IDENTITY_INSERT nv_canales OFF

SET IDENTITY_INSERT nv_estados_usuario ON
INSERT INTO nv_estados_usuario (estadoId, nombreEstado)
VALUES 
    (1, 'Activo'),
    (2, 'Inactivo')
SET IDENTITY_INSERT nv_estados_usuario OFF

SET IDENTITY_INSERT cuentas_usuario ON
INSERT INTO cuentas_usuario (usuarioId, nombreUsuario, passwordHash, nombre, apellido, estadoUsuarioId)
VALUES (1, 'admin.test', 0x00, 'Admin', 'Sistema', 1)
SET IDENTITY_INSERT cuentas_usuario OFF

SET IDENTITY_INSERT nv_paises ON
INSERT INTO nv_paises (paisId, nombrePais, codigoPais)
VALUES (1, 'Costa Rica', 'CRI')
SET IDENTITY_INSERT nv_paises OFF

SET IDENTITY_INSERT nv_estados ON
INSERT INTO nv_estados (estadoId, paisId, nombreEstado)
VALUES (1, 1, 'San José')
SET IDENTITY_INSERT nv_estados OFF

SET IDENTITY_INSERT nv_ciudades ON
INSERT INTO nv_ciudades (ciudadId, estadoId, nombreCiudad, coordenadas)
VALUES (1, 1, 'San José Centro', geography::Point(9.9281, -84.0907, 4326))
SET IDENTITY_INSERT nv_ciudades OFF

SET IDENTITY_INSERT clientes ON
INSERT INTO clientes (clienteId, tipoClienteId, estadoClienteId, nombreEmpresa, nombreContacto, apellidoContacto, creadoPor)
VALUES (1, 1, 1, 'TechCorp SA', 'María', 'González', 1)
SET IDENTITY_INSERT clientes OFF

-- Interacciones (no necesita leadId para este demo)
INSERT INTO interacciones (clienteId, tipoInteraccionId, canalId, usuarioId, fechaInteraccion, duracionMinutos, puntajeSentimiento, estaCompletada)
VALUES 
    (1, 1, 1, 1, DATEADD(DAY, -30, GETDATE()), 15, 0.8, 1),
    (1, 2, 2, 1, DATEADD(DAY, -25, GETDATE()), 20, 0.7, 1),
    (1, 1, 1, 1, DATEADD(DAY, -20, GETDATE()), 10, 0.9, 0)

-- Crear leads asociados al cliente
DECLARE @leadId1 INT, @leadId2 INT

INSERT INTO leads (clienteId, fuenteLeadId, estadoLeadId, puntajeLead, utmCampaign, creadoPor)
VALUES (1, 1, 1, 75, 'campaign_test_2024', 1)
SET @leadId1 = SCOPE_IDENTITY()

INSERT INTO leads (clienteId, fuenteLeadId, estadoLeadId, puntajeLead, utmCampaign, creadoPor)
VALUES (1, 1, 2, 65, 'campaign_test_2024', 1)
SET @leadId2 = SCOPE_IDENTITY()

-- Insertar conversiones para cálculo de valor total
INSERT INTO conversiones_lead (clienteId, leadId, valorConversion, fechaConversion, tipoConversion, creadoPor)
VALUES 
    (1, @leadId1, 1500.00, DATEADD(DAY, -15, GETDATE()), 'Venta Directa', 1),
    (1, @leadId2, 2300.00, DATEADD(DAY, -10, GETDATE()), 'Venta Directa', 1)

GO


----------- ESCENARIO CON PROBLEMA - DIRTY READ -------------
-- Actualización de métricas de cliente con nivel de aislamiento bajo

CREATE OR ALTER PROCEDURE sp_RecalcularMetricasCliente_ConProblema
    @clienteId INT
AS
BEGIN
    -- READ UNCOMMITTED permite leer datos no confirmados (dirty reads)
    -- Esto significa que otras sesiones pueden ver cambios antes del COMMIT
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    
    BEGIN TRANSACTION
    
    BEGIN TRY
        -- Variables para almacenar las métricas calculadas
        DECLARE @totalInteracciones INT
        DECLARE @interacciones7Dias INT
        DECLARE @interacciones30Dias INT
        DECLARE @totalConversiones INT
        DECLARE @valorTotalConversiones DECIMAL(18,2)
        DECLARE @valorPromedioConversion DECIMAL(18,2)
        DECLARE @tasaRespuesta DECIMAL(5,2)
        DECLARE @puntajeEngagement INT
       
        -- Calcular estadísticas de interacciones del cliente
        SELECT 
            @totalInteracciones = COUNT(*),
            @interacciones7Dias = SUM(CASE WHEN fechaInteraccion >= DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END),
            @interacciones30Dias = SUM(CASE WHEN fechaInteraccion >= DATEADD(DAY, -30, GETDATE()) THEN 1 ELSE 0 END),
            @tasaRespuesta = AVG(CASE WHEN estaCompletada = 1 THEN 100.0 ELSE 0.0 END)
        FROM interacciones
        WHERE clienteId = @clienteId AND deleted = 0
        
        -- Calcular estadísticas de conversiones
        SELECT 
            @totalConversiones = COUNT(*),
            @valorTotalConversiones = SUM(valorConversion),
            @valorPromedioConversion = AVG(valorConversion)
        FROM conversiones_lead
        WHERE clienteId = @clienteId AND deleted = 0
        
        -- Calcular puntaje de engagement basado en actividad reciente y conversiones
        SET @puntajeEngagement = (
            (@interacciones7Dias * 10) + 
            (@totalConversiones * 20) + 
            (CAST(@tasaRespuesta AS INT) / 2)
        )
        
        -- Limitar el puntaje al máximo permitido
        IF @puntajeEngagement > 100 SET @puntajeEngagement = 100
        
        -- SIMULACIÓN DE ERROR: Insertar snapshot con valores incorrectos (multiplicados x10)
        -- Este error será detectado después y se hará rollback
        -- Con READ UNCOMMITTED, otras sesiones pueden leer estos valores erróneos
        INSERT INTO snapshots_metricas_cliente (
            clienteId,
            totalInteracciones,
            interaccionesUltimos7Dias,
            interaccionesUltimos30Dias,
            totalConversiones,
            valorTotalConversiones,
            valorPromedioConversion,
            tasaRespuesta,
            puntajeEngagement,
            fechaSnapshot
        )
        VALUES (
            @clienteId,
            @totalInteracciones * 10,      -- ERROR: valor inflado
            @interacciones7Dias * 10,       -- ERROR: valor inflado
            @interacciones30Dias * 10,      -- ERROR: valor inflado
            @totalConversiones * 10,        -- ERROR: valor inflado
            @valorTotalConversiones * 10,   -- ERROR: valor inflado
            @valorPromedioConversion,
            @tasaRespuesta,
            @puntajeEngagement,
            GETDATE()
        )
        
        -- Simular tiempo de procesamiento/validación (10 segundos)
        -- Durante este tiempo, otras sesiones con READ UNCOMMITTED verán los datos incorrectos
        WAITFOR DELAY '00:00:10'
        
        -- Detectar el error y revertir los cambios
        -- PROBLEMA: Las sesiones que leyeron durante el WAITFOR obtuvieron datos incorrectos
        ROLLBACK TRANSACTION
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
            
        THROW
    END CATCH
END
GO

-- Procedimiento que genera reportes leyendo datos potencialmente no confirmados
CREATE OR ALTER PROCEDURE sp_GenerarReporteCliente_ConProblema
    @clienteId INT
AS
BEGIN
    -- READ UNCOMMITTED permite dirty reads: puede leer datos que luego serán revertidos
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    
    -- Este SELECT puede leer el snapshot con valores incorrectos (x10)
    -- si se ejecuta mientras sp_RecalcularMetricasCliente_ConProblema está en el WAITFOR
    SELECT TOP 1
        clienteId,
        totalInteracciones,
        interaccionesUltimos7Dias,
        totalConversiones,
        valorTotalConversiones,
        puntajeEngagement,
        fechaSnapshot,
        'DIRTY READ - Puede contener datos NO CONFIRMADOS' AS advertencia
    FROM snapshots_metricas_cliente
    WHERE clienteId = @clienteId
    ORDER BY fechaSnapshot DESC
END
GO

----------- VERSIÓN CORREGIDA - SIN DIRTY READ ----------------
-- Implementación con nivel de aislamiento seguro

CREATE OR ALTER PROCEDURE sp_RecalcularMetricasCliente_Corregido
    @clienteId INT
AS
BEGIN
    -- READ COMMITTED previene dirty reads: solo permite leer datos confirmados
    -- Otras sesiones NO verán estos cambios hasta que se haga COMMIT
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT ON
    
    BEGIN TRANSACTION
    
    BEGIN TRY
        -- Variables para métricas
        DECLARE @totalInteracciones INT
        DECLARE @interacciones7Dias INT
        DECLARE @interacciones30Dias INT
        DECLARE @totalConversiones INT
        DECLARE @valorTotalConversiones DECIMAL(18,2)
        DECLARE @valorPromedioConversion DECIMAL(18,2)
        DECLARE @tasaRespuesta DECIMAL(5,2)
        DECLARE @puntajeEngagement INT
        
        -- Calcular interacciones con hint READCOMMITTED explícito
        SELECT 
            @totalInteracciones = COUNT(*),
            @interacciones7Dias = SUM(CASE WHEN fechaInteraccion >= DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END),
            @interacciones30Dias = SUM(CASE WHEN fechaInteraccion >= DATEADD(DAY, -30, GETDATE()) THEN 1 ELSE 0 END),
            @tasaRespuesta = AVG(CASE WHEN estaCompletada = 1 THEN 100.0 ELSE 0.0 END)
        FROM interacciones WITH (READCOMMITTED)
        WHERE clienteId = @clienteId AND deleted = 0
        
        -- Calcular conversiones
        SELECT 
            @totalConversiones = COUNT(*),
            @valorTotalConversiones = SUM(valorConversion),
            @valorPromedioConversion = AVG(valorConversion)
        FROM conversiones_lead WITH (READCOMMITTED)
        WHERE clienteId = @clienteId AND deleted = 0
        
        -- Calcular puntaje de engagement
        SET @puntajeEngagement = (
            (@interacciones7Dias * 10) + 
            (@totalConversiones * 20) + 
            (CAST(@tasaRespuesta AS INT) / 2)
        )
        
        IF @puntajeEngagement > 100 SET @puntajeEngagement = 100
        
        -- Insertar snapshot con valores incorrectos (simulación de error)
        INSERT INTO snapshots_metricas_cliente (
            clienteId,
            totalInteracciones,
            interaccionesUltimos7Dias,
            interaccionesUltimos30Dias,
            totalConversiones,
            valorTotalConversiones,
            valorPromedioConversion,
            tasaRespuesta,
            puntajeEngagement,
            fechaSnapshot
        )
        VALUES (
            @clienteId,
            @totalInteracciones * 10,      -- ERROR intencional para demostración
            @interacciones7Dias * 10,
            @interacciones30Dias * 10,
            @totalConversiones * 10,
            @valorTotalConversiones * 10,
            @valorPromedioConversion,
            @tasaRespuesta,
            @puntajeEngagement,
            GETDATE()
        )
        
        -- Tiempo de procesamiento (10 segundos)
        -- IMPORTANTE: Durante este tiempo, otras sesiones NO verán estos datos incorrectos
        -- gracias a READ COMMITTED
        WAITFOR DELAY '00:00:10'
        
        -- Detectar error y revertir
        -- A diferencia de la versión con problema, ninguna sesión habrá leído datos incorrectos
        ROLLBACK TRANSACTION
       
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
            
        THROW
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_GenerarReporteCliente_Corregido
    @clienteId INT
AS
BEGIN
    -- READ COMMITTED garantiza que solo se lean datos confirmados
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT ON
    
    -- Este SELECT se BLOQUEARÁ si hay una transacción activa modificando los datos
    -- Solo continuará cuando la transacción haga COMMIT o ROLLBACK
    -- VENTAJA: Nunca leerá datos incorrectos que luego serán revertidos
    SELECT TOP 1
        clienteId,
        totalInteracciones,
        interaccionesUltimos7Dias,
        totalConversiones,
        valorTotalConversiones,
        puntajeEngagement,
        fechaSnapshot,
        'LECTURA SEGURA - Solo datos CONFIRMADOS' AS estado
    FROM snapshots_metricas_cliente WITH (READCOMMITTED)
    WHERE clienteId = @clienteId
    ORDER BY fechaSnapshot DESC
    
    IF @@ROWCOUNT = 0

END



/*

--------------------------- INSTRUCCIONES PARA DEMOSTRAR DIRTY READ ---------------------------

-------------- PROBLEMA - DIRTY READ --------------

DELETE FROM snapshots_metricas_cliente WHERE clienteId = 1
GO

Abrir DOS Ventanas de Query en SSMS

VENTANA 1 (Sesión que modifica datos)
EXEC sp_RecalcularMetricasCliente_ConProblema @clienteId = 1

VENTANA 2 (Sesión que lee datos)
INMEDIATAMENTE después de ejecutar Ventana 1 mientras espera
EXEC sp_GenerarReporteCliente_ConProblema @clienteId = 1


-------------- SIN DIRTY READ --------------

DELETE FROM snapshots_metricas_cliente WHERE clienteId = 1
GO

Abrir DOS Ventanas de Query en SSMS

VENTANA 1 (Sesión que modifica datos)
EXEC sp_RecalcularMetricasCliente_Corregido @clienteId = 1


VENTANA 2 (Sesión que lee datos)
INMEDIATAMENTE después de ejecutar Ventana 1 mientras espera
EXEC sp_GenerarReporteCliente_Corregido @clienteId = 1


*/

DROP PROCEDURE IF EXISTS sp_RecalcularMetricasCliente_ConProblema
DROP PROCEDURE IF EXISTS sp_GenerarReporteCliente_ConProblema
DROP PROCEDURE IF EXISTS sp_RecalcularMetricasCliente_Corregido
DROP PROCEDURE IF EXISTS sp_GenerarReporteCliente_Corregido

DELETE FROM snapshots_metricas_cliente WHERE clienteId = 1
DELETE FROM conversiones_lead WHERE clienteId = 1
DELETE FROM leads WHERE clienteId = 1
DELETE FROM interacciones WHERE clienteId = 1
DELETE FROM clientes WHERE clienteId = 1

