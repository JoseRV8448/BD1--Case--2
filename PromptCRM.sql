------------ TABLAS DE CATÁLOGOS --------------

-- Catálogo de países
CREATE TABLE nv_paises (
    paisId INT IDENTITY(1,1) PRIMARY KEY,
    nombrePais NVARCHAR(100) NOT NULL,
    codigoPais CHAR(3) NOT NULL UNIQUE,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0
)

-- Estados o provincias por país
CREATE TABLE nv_estados (
    estadoId INT IDENTITY(1,1) PRIMARY KEY,
    paisId INT NOT NULL,
    nombreEstado NVARCHAR(100) NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_estados_pais FOREIGN KEY (paisId) REFERENCES nv_paises(paisId)
)

-- Ciudades con coordenadas geográficas
-- TODO: Verificar performance de índice espacial con volumen alto
CREATE TABLE nv_ciudades (
    ciudadId INT IDENTITY(1,1) PRIMARY KEY,
    estadoId INT NOT NULL,
    nombreCiudad NVARCHAR(100) NOT NULL,
    coordenadas GEOGRAPHY NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_ciudades_estado FOREIGN KEY (estadoId) REFERENCES nv_estados(estadoId)
)
CREATE SPATIAL INDEX idx_coordenadas ON nv_ciudades(coordenadas)

-- Clasificación de industrias
CREATE TABLE nv_industrias (
    industriaId INT IDENTITY(1,1) PRIMARY KEY,
    nombreIndustria NVARCHAR(100) NOT NULL,
    codigoIndustria NVARCHAR(30) UNIQUE,
    deleted BIT DEFAULT 0
)

-- Tipos de cliente: Prospecto, Activo, Inactivo, etc
CREATE TABLE nv_tipos_cliente (
    tipoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(50) NOT NULL,
    descripcion NVARCHAR(200),
    deleted BIT DEFAULT 0
)

CREATE TABLE nv_estados_cliente (
    estadoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreEstado NVARCHAR(50) NOT NULL
)

-- Estados del flujo de leads
CREATE TABLE nv_estados_lead (
    estadoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreEstado NVARCHAR(50) NOT NULL,
    ordenFlujo INT
)

CREATE TABLE nv_estados_usuario (
    estadoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreEstado NVARCHAR(50) NOT NULL
)

-- Fuentes de donde vienen los leads
CREATE TABLE nv_tipos_fuente_lead (
    tipoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(30) NOT NULL
)

-- Tipos de interacción: llamada, email, reunión, etc
CREATE TABLE nv_tipos_interaccion (
    tipoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(50) NOT NULL,
    descripcion NVARCHAR(200)
)

-- Canales de comunicación con métricas
-- Incluye email, WhatsApp, SMS, llamadas, etc
CREATE TABLE nv_canales (
    canalId INT IDENTITY(1,1) PRIMARY KEY,
    nombreCanal NVARCHAR(50) NOT NULL,
    descripcion NVARCHAR(200),
    esDigital BIT DEFAULT 1,
    permiteAutomatizacion BIT DEFAULT 0,
    soportaBot BIT DEFAULT 0,
    requiereConsentimiento BIT DEFAULT 0,
    costoPromedioPorContacto DECIMAL(10,2),
    tasaEntregaPromedio DECIMAL(5,2),
    tasaAperturaPromedio DECIMAL(5,2),
    tiempoRespuestaPromedioMin INT,
    soportaArchivos BIT DEFAULT 0,
    limiteMensajeCaracteres INT,
    activo BIT DEFAULT 1
)

CREATE TABLE nv_tipos_contacto (
    tipoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(30) NOT NULL,
    categoria NVARCHAR(20) NOT NULL CHECK (categoria IN ('email', 'telefono', 'red_social', 'mensajeria')),
    requiereVerificacion BIT DEFAULT 0,
    formatoRegex NVARCHAR(500)
)

CREATE TABLE nv_dias_semana (
    diaId INT PRIMARY KEY,
    nombreDia NVARCHAR(20) NOT NULL,
    nombreCorto CHAR(3) NOT NULL
)

-- Para el sistema de logging
CREATE TABLE nv_niveles_log (
    nivelId INT IDENTITY(1,1) PRIMARY KEY,
    nombreNivel NVARCHAR(20) NOT NULL,
    severidad INT NOT NULL
)

CREATE TABLE nv_tipos_log (
    tipoId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(50) NOT NULL
)


------------- TABLAS PRINCIPALES ----------------


-- Direcciones físicas con geolocalización
CREATE TABLE direcciones (
    direccionId INT IDENTITY(1,1) PRIMARY KEY,
    direccionLinea1 NVARCHAR(150) NOT NULL,
    direccionLinea2 NVARCHAR(150),
    codigoPostal NVARCHAR(20),
    ciudadId INT NOT NULL,
    coordenadas GEOGRAPHY NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_direcciones_ciudad FOREIGN KEY (ciudadId) REFERENCES nv_ciudades(ciudadId)
)
CREATE SPATIAL INDEX idx_direcciones_coordenadas ON direcciones(coordenadas)

-- Usuarios del sistema CRM
CREATE TABLE cuentas_usuario (
    usuarioId INT IDENTITY(1,1) PRIMARY KEY,
    nombreUsuario NVARCHAR(100) NOT NULL UNIQUE,
    passwordHash VARBINARY(255) NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    apellido NVARCHAR(100) NOT NULL,
    estadoUsuarioId INT NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_usuarios_estado FOREIGN KEY (estadoUsuarioId) REFERENCES nv_estados_usuario(estadoId)
)
CREATE INDEX idx_usuarios_nombre ON cuentas_usuario(nombreUsuario)

-- Emails y teléfonos de usuarios
CREATE TABLE contactos_usuario (
    contactoId INT IDENTITY(1,1) PRIMARY KEY,
    usuarioId INT NOT NULL,
    tipoContactoId INT NOT NULL,
    valorContacto NVARCHAR(255) NOT NULL,
    esPrincipal BIT DEFAULT 0,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_contactos_usuario_usuario FOREIGN KEY (usuarioId) REFERENCES cuentas_usuario(usuarioId) ON DELETE CASCADE,
    CONSTRAINT fk_contactos_usuario_tipo FOREIGN KEY (tipoContactoId) REFERENCES nv_tipos_contacto(tipoId)
)
CREATE INDEX idx_contactos_usuario ON contactos_usuario(usuarioId)

-- Fuentes de leads configurables
CREATE TABLE fuentes_lead (
    fuenteId INT IDENTITY(1,1) PRIMARY KEY,
    tipoFuenteId INT NOT NULL,
    nombreFuente NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(200),
    costoPorLead DECIMAL(18,2),
    activo BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_fuentes_tipo FOREIGN KEY (tipoFuenteId) REFERENCES nv_tipos_fuente_lead(tipoId)
)

-- Referencias de campañas sincronizadas desde PromptAds
-- Se actualiza vía ETL programado
CREATE TABLE referencias_campanas (
    referenciaId INT IDENTITY(1,1) PRIMARY KEY,
    utmCampaign NVARCHAR(100) NOT NULL UNIQUE,
    nombreCampana NVARCHAR(200),
    fechaInicio DATE,
    fechaFin DATE,
    ultimaSincronizacionETL DATETIME2 DEFAULT GETDATE(),
    activa BIT DEFAULT 1
)
CREATE INDEX idx_ref_campanas_utm ON referencias_campanas(utmCampaign)
CREATE INDEX idx_ref_campanas_fechas ON referencias_campanas(fechaInicio, fechaFin)
CREATE INDEX idx_ref_campanas_activa ON referencias_campanas(activa, ultimaSincronizacionETL)

-- Tabla principal de clientes
-- Soporta tanto B2B como B2C
CREATE TABLE clientes (
    clienteId INT IDENTITY(1,1) PRIMARY KEY,
    tipoClienteId INT NOT NULL,
    fuenteLeadId INT,
    estadoClienteId INT NOT NULL,
    industriaId INT,
    direccionId INT,
    nombreEmpresa NVARCHAR(200),
    sitioWeb NVARCHAR(255),
    notas NVARCHAR(MAX),
    nombreContacto NVARCHAR(100),
    apellidoContacto NVARCHAR(100),
    cargoContacto NVARCHAR(100),
    identificacionEncrypted VARBINARY(256),  -- Encriptado por cumplimiento GDPR
    creadoPor INT,
    modificadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_clientes_tipo FOREIGN KEY (tipoClienteId) REFERENCES nv_tipos_cliente(tipoId),
    CONSTRAINT fk_clientes_fuente FOREIGN KEY (fuenteLeadId) REFERENCES fuentes_lead(fuenteId),
    CONSTRAINT fk_clientes_estado FOREIGN KEY (estadoClienteId) REFERENCES nv_estados_cliente(estadoId),
    CONSTRAINT fk_clientes_industria FOREIGN KEY (industriaId) REFERENCES nv_industrias(industriaId),
    CONSTRAINT fk_clientes_direccion FOREIGN KEY (direccionId) REFERENCES direcciones(direccionId),
    CONSTRAINT fk_clientes_creado_por FOREIGN KEY (creadoPor) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT fk_clientes_modificado_por FOREIGN KEY (modificadoPor) REFERENCES cuentas_usuario(usuarioId)
)
CREATE INDEX idx_clientes_empresa ON clientes(nombreEmpresa)
CREATE INDEX idx_clientes_contacto ON clientes(nombreContacto, apellidoContacto)

-- Emails, teléfonos y redes sociales de clientes
CREATE TABLE contactos_cliente (
    contactoId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    tipoContactoId INT NOT NULL,
    valorContacto NVARCHAR(255) NOT NULL,
    extension NVARCHAR(10),
    esPrincipal BIT DEFAULT 0,
    esVerificado BIT DEFAULT 0,
    fechaVerificacion DATETIME2 NULL,
    aceptaMarketing BIT DEFAULT 0,  -- Consentimiento GDPR
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_contactos_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_contactos_tipo FOREIGN KEY (tipoContactoId) REFERENCES nv_tipos_contacto(tipoId)
)
CREATE INDEX idx_contactos_cliente ON contactos_cliente(clienteId)
CREATE INDEX idx_contactos_valor ON contactos_cliente(valorContacto)

-- Preferencias de contacto por cliente
-- Define cómo y cuándo contactar a cada cliente
CREATE TABLE preferencias_contacto_cliente (
    preferenciaId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    canalId INT NOT NULL,
    esCanalPreferido BIT DEFAULT 0,
    diasSemana NVARCHAR(50) DEFAULT 'lun,mar,mie,jue,vie',
    horaInicio TIME DEFAULT '09:00:00',
    horaFin TIME DEFAULT '18:00:00',
    frecuenciaMaximaSemanal INT DEFAULT 3,
    activa BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_preferencias_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_preferencias_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId),
    CONSTRAINT chk_pref_horario CHECK (horaInicio < horaFin),
    CONSTRAINT chk_pref_frecuencia CHECK (frecuenciaMaximaSemanal > 0)
)
CREATE INDEX idx_preferencias_cliente ON preferencias_contacto_cliente(clienteId)
CREATE INDEX idx_preferencias_canal ON preferencias_contacto_cliente(canalId)

-- Bloqueos de contacto
-- Para manejar opt-outs y restricciones legales
CREATE TABLE bloqueos_contacto_cliente (
    bloqueoId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    canalId INT,
    noContactar BIT DEFAULT 0,
    razonBloqueo NVARCHAR(500),
    fechaInicio DATETIME2 DEFAULT GETDATE(),
    fechaFin DATETIME2 NULL,
    activo BIT DEFAULT 1,
    CONSTRAINT fk_bloqueos_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_bloqueos_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId)
)
CREATE INDEX idx_bloqueos_cliente ON bloqueos_contacto_cliente(clienteId)
CREATE INDEX idx_bloqueos_activos ON bloqueos_contacto_cliente(activo, fechaFin)

-- Ventanas horarias específicas por día
CREATE TABLE ventanas_contacto_cliente (
    ventanaId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    diaId INT NOT NULL,
    horaInicio TIME NOT NULL,
    horaFin TIME NOT NULL,
    activa BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_ventanas_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_ventanas_dia FOREIGN KEY (diaId) REFERENCES nv_dias_semana(diaId),
    CONSTRAINT chk_ventanas_horario CHECK (horaInicio < horaFin)
)
CREATE INDEX idx_ventanas_cliente_dia ON ventanas_contacto_cliente(clienteId, diaId)


------------ MÉTRICAS DE COMPORTAMIENTO --------------
-- insert-only

CREATE TABLE snapshots_metricas_cliente (
    snapshotId BIGINT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    fechaSnapshot DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- Métricas de interacción
    totalInteracciones INT NOT NULL DEFAULT 0,
    interaccionesUltimos7Dias INT NOT NULL DEFAULT 0,
    interaccionesUltimos30Dias INT NOT NULL DEFAULT 0,
    ultimaInteraccion DATETIME2 NULL,
    diasDesdeUltimaInteraccion INT,
    canalMasEfectivoId INT,
    tasaRespuesta DECIMAL(5,2),
    tiempoPromedioRespuestaHoras DECIMAL(10,2),
    
    -- Métricas de conversión
    totalConversiones INT NOT NULL DEFAULT 0,
    conversionesUltimos30Dias INT NOT NULL DEFAULT 0,
    ultimaConversion DATETIME2 NULL,
    valorTotalConversiones DECIMAL(18,2) NOT NULL DEFAULT 0,
    valorPromedioConversion DECIMAL(18,2) NOT NULL DEFAULT 0,
    diasDesdeUltimaConversion INT,
    
    -- Métricas de engagement y ML
    puntajeEngagement INT NOT NULL DEFAULT 0,
    tendenciaEngagement NVARCHAR(20) DEFAULT 'estable' CHECK (tendenciaEngagement IN ('ascendente', 'estable', 'descendente')),
    diasDesdeRegistro INT,
    ltvEstimado DECIMAL(18,2),
    probabilidadChurn DECIMAL(5,2),
    probabilidadRecompra DECIMAL(5,2),
    modeloIA NVARCHAR(100),
    confianzaModelo DECIMAL(5,2),
    
    CONSTRAINT fk_snapshots_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_snapshots_canal FOREIGN KEY (canalMasEfectivoId) REFERENCES nv_canales(canalId),
    CONSTRAINT chk_snapshots_engagement CHECK (puntajeEngagement BETWEEN 0 AND 100),
    CONSTRAINT chk_snapshots_tasa_respuesta CHECK (tasaRespuesta IS NULL OR (tasaRespuesta BETWEEN 0 AND 100)),
    CONSTRAINT chk_snapshots_churn CHECK (probabilidadChurn IS NULL OR (probabilidadChurn BETWEEN 0 AND 100))
)
CREATE INDEX idx_snapshots_cliente_fecha ON snapshots_metricas_cliente(clienteId, fechaSnapshot DESC)
CREATE INDEX idx_snapshots_engagement ON snapshots_metricas_cliente(puntajeEngagement DESC)
CREATE INDEX idx_snapshots_churn ON snapshots_metricas_cliente(probabilidadChurn DESC)

-- Distribución de interacciones por canal
CREATE TABLE snapshots_interacciones_por_canal (
    snapshotId BIGINT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    canalId INT NOT NULL,
    fechaSnapshot DATETIME2 NOT NULL DEFAULT GETDATE(),
    cantidadInteracciones INT NOT NULL DEFAULT 0,
    tasaConversion DECIMAL(5,2),
    valorGenerado DECIMAL(18,2) DEFAULT 0,
    CONSTRAINT fk_snapshots_canal_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId) ON DELETE CASCADE,
    CONSTRAINT fk_snapshots_canal_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId)
)
CREATE INDEX idx_snapshots_canal_cliente_fecha ON snapshots_interacciones_por_canal(clienteId, fechaSnapshot DESC)
CREATE INDEX idx_snapshots_canal_id ON snapshots_interacciones_por_canal(canalId)


----------------- LEADS Y TRACKING -------------------


CREATE TABLE leads (
    leadId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    fuenteLeadId INT NOT NULL,
    estadoLeadId INT NOT NULL,
    puntajeLead INT DEFAULT 0,
    
    -- Parámetros UTM para tracking de campañas
    utmSource NVARCHAR(100),
    utmMedium NVARCHAR(100),
    utmCampaign NVARCHAR(100),
    utmTerm NVARCHAR(100),
    utmContent NVARCHAR(100),
    
    -- Click IDs de diferentes plataformas
    gclid NVARCHAR(255),  -- Google Ads
    fbclid NVARCHAR(255), -- Facebook
    msclkid NVARCHAR(255), -- Microsoft Ads
    liClickId NVARCHAR(255), -- LinkedIn
    ttclid NVARCHAR(255), -- TikTok
    
    -- Datos de navegación
    primeraPaginaVista NVARCHAR(500),
    paginaConversion NVARCHAR(500),
    referrerUrl NVARCHAR(500),
    userAgent NVARCHAR(MAX),
    ipAddress NVARCHAR(45),
    dispositivo NVARCHAR(50),
    sistemaOperativo NVARCHAR(50),
    navegador NVARCHAR(50),
    resolucionPantalla NVARCHAR(20),
    
    asignadoAUsuarioId INT,
    creadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_leads_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_leads_fuente FOREIGN KEY (fuenteLeadId) REFERENCES fuentes_lead(fuenteId),
    CONSTRAINT fk_leads_estado FOREIGN KEY (estadoLeadId) REFERENCES nv_estados_lead(estadoId),
    CONSTRAINT fk_leads_asignado FOREIGN KEY (asignadoAUsuarioId) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT fk_leads_creado_por FOREIGN KEY (creadoPor) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT chk_leads_puntaje CHECK (puntajeLead BETWEEN 0 AND 100)
)
CREATE INDEX idx_leads_cliente ON leads(clienteId)
CREATE INDEX idx_leads_utm_campaign ON leads(utmCampaign)
CREATE INDEX idx_leads_utm_source ON leads(utmSource)
CREATE INDEX idx_leads_utm_medium ON leads(utmMedium)
CREATE INDEX idx_leads_estado ON leads(estadoLeadId)
CREATE INDEX idx_leads_puntaje ON leads(puntajeLead DESC)
CREATE INDEX idx_leads_gclid ON leads(gclid)
CREATE INDEX idx_leads_fbclid ON leads(fbclid)

GO


-- Notas adicionales sobre leads
CREATE TABLE notas_lead (
    notaId INT IDENTITY(1,1) PRIMARY KEY,
    leadId INT NOT NULL,
    nota NVARCHAR(MAX) NOT NULL,
    creadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_notas_lead FOREIGN KEY (leadId) REFERENCES leads(leadId) ON DELETE CASCADE,
    CONSTRAINT fk_notas_usuario FOREIGN KEY (creadoPor) REFERENCES cuentas_usuario(usuarioId)
)
CREATE INDEX idx_notas_lead ON notas_lead(leadId)

-- Sistema de etiquetas flexible
CREATE TABLE tags_lead (
    tagId INT IDENTITY(1,1) PRIMARY KEY,
    leadId INT NOT NULL,
    nombreTag NVARCHAR(50) NOT NULL,
    valorTag NVARCHAR(200),
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_tags_lead FOREIGN KEY (leadId) REFERENCES leads(leadId) ON DELETE CASCADE
)
CREATE INDEX idx_tags_lead ON tags_lead(leadId)
CREATE INDEX idx_tags_nombre ON tags_lead(nombreTag)

-- Scores de intención de compra calculados por ML
CREATE TABLE scores_intencion_compra (
    scoreId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    leadId INT,
    puntajeIntencion DECIMAL(5,2) NOT NULL,
    confianzaModelo DECIMAL(5,2),
    modeloIA NVARCHAR(100),
    factoresClaves NVARCHAR(MAX),
    fechaCalculo DATETIME2 DEFAULT GETDATE(),
    validoHasta DATETIME2,
    CONSTRAINT fk_scores_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_scores_lead FOREIGN KEY (leadId) REFERENCES leads(leadId),
    CONSTRAINT chk_scores_puntaje CHECK (puntajeIntencion BETWEEN 0 AND 100)
)
CREATE INDEX idx_scores_cliente_valido ON scores_intencion_compra(clienteId, validoHasta)
CREATE INDEX idx_scores_puntaje ON scores_intencion_compra(puntajeIntencion DESC)


-------------- BOTS DE INTERACCIÓN ------------------

-- Sesiones de chatbot o voicebot
CREATE TABLE sesiones_bot_cliente (
    sesionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    tipoBot NVARCHAR(20) NOT NULL CHECK (tipoBot IN ('chatbot', 'voicebot')),
    canalId INT NOT NULL,
    inicioSesion DATETIME2 DEFAULT GETDATE(),
    finSesion DATETIME2 NULL,
    duracionSegundos INT,
    cantidadMensajes INT DEFAULT 0,
    sentimientoPromedio DECIMAL(5,2),
    intencionPrincipal NVARCHAR(100),
    objetivoCumplido BIT DEFAULT 0,
    seEscalo BIT DEFAULT 0,
    usuarioEscaladoId INT,
    CONSTRAINT fk_sesiones_bot_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_sesiones_bot_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId),
    CONSTRAINT fk_sesiones_bot_usuario FOREIGN KEY (usuarioEscaladoId) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT chk_sesiones_sentimiento CHECK (sentimientoPromedio IS NULL OR (sentimientoPromedio BETWEEN -1 AND 1))
)
CREATE INDEX idx_sesiones_cliente_fecha ON sesiones_bot_cliente(clienteId, inicioSesion)

-- Mensajes individuales dentro de una sesión
CREATE TABLE mensajes_bot (
    mensajeId INT IDENTITY(1,1) PRIMARY KEY,
    sesionId INT NOT NULL,
    esDelBot BIT NOT NULL,
    contenido NVARCHAR(MAX) NOT NULL,
    intencionDetectada NVARCHAR(100),
    confianzaIA DECIMAL(5,2),
    fechaMensaje DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_mensajes_sesion FOREIGN KEY (sesionId) REFERENCES sesiones_bot_cliente(sesionId) ON DELETE CASCADE
)
CREATE INDEX idx_mensajes_sesion ON mensajes_bot(sesionId)

-------------- - INTERACCIONES -----------------

CREATE TABLE interacciones (
    interaccionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    tipoInteraccionId INT NOT NULL,
    canalId INT NOT NULL,
    usuarioId INT,
    leadId INT,
    sesionBotId INT,
    asunto NVARCHAR(200),
    contenido NVARCHAR(MAX),
    notas NVARCHAR(MAX),
    fechaInteraccion DATETIME2 DEFAULT GETDATE(),
    duracionMinutos INT,
    esAutomatizada BIT DEFAULT 0,
    puntajeSentimiento DECIMAL(5,2),
    requiereSeguimiento BIT DEFAULT 0,
    fechaSeguimientoSugerida DATETIME2 NULL,
    estaCompletada BIT DEFAULT 0,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_interacciones_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_interacciones_tipo FOREIGN KEY (tipoInteraccionId) REFERENCES nv_tipos_interaccion(tipoId),
    CONSTRAINT fk_interacciones_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId),
    CONSTRAINT fk_interacciones_usuario FOREIGN KEY (usuarioId) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT fk_interacciones_lead FOREIGN KEY (leadId) REFERENCES leads(leadId),
    CONSTRAINT fk_interacciones_sesion_bot FOREIGN KEY (sesionBotId) REFERENCES sesiones_bot_cliente(sesionId),
    CONSTRAINT chk_interacciones_sentimiento CHECK (puntajeSentimiento IS NULL OR (puntajeSentimiento BETWEEN -1 AND 1))
)
CREATE INDEX idx_interacciones_cliente_fecha ON interacciones(clienteId, fechaInteraccion)
CREATE INDEX idx_interacciones_usuario_fecha ON interacciones(usuarioId, fechaInteraccion)
CREATE INDEX idx_interacciones_seguimiento ON interacciones(requiereSeguimiento, fechaSeguimientoSugerida)

-- Metadata extensible para interacciones
CREATE TABLE metadata_interaccion (
    metadataId INT IDENTITY(1,1) PRIMARY KEY,
    interaccionId INT NOT NULL,
    claveMetadata NVARCHAR(100) NOT NULL,
    valorMetadata NVARCHAR(MAX),
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_metadata_interaccion FOREIGN KEY (interaccionId) REFERENCES interacciones(interaccionId) ON DELETE CASCADE
)
CREATE INDEX idx_metadata_interaccion ON metadata_interaccion(interaccionId)

------------------ CONVERSIONES --------------------

CREATE TABLE conversiones_lead (
    conversionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    leadId INT NOT NULL,
    valorConversion DECIMAL(18,2) NOT NULL,
    tipoConversion NVARCHAR(50),
    descripcion NVARCHAR(500),
    
    -- UTMs para atribución
    utmSource NVARCHAR(100),
    utmMedium NVARCHAR(100),
    utmCampaign NVARCHAR(100),
    utmTerm NVARCHAR(100),
    utmContent NVARCHAR(100),
    
    modeloAtribucion NVARCHAR(50),
    fechaConversion DATETIME2 NOT NULL,
    referenciaExterna NVARCHAR(100),
    sistemaOrigen NVARCHAR(50),
    creadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_conversiones_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_conversiones_lead FOREIGN KEY (leadId) REFERENCES leads(leadId),
    CONSTRAINT fk_conversiones_creado_por FOREIGN KEY (creadoPor) REFERENCES cuentas_usuario(usuarioId),
    CONSTRAINT chk_conversiones_valor CHECK (valorConversion >= 0)
)
CREATE INDEX idx_conversiones_cliente ON conversiones_lead(clienteId)
CREATE INDEX idx_conversiones_lead ON conversiones_lead(leadId)
CREATE INDEX idx_conversiones_fecha ON conversiones_lead(fechaConversion)
CREATE INDEX idx_conversiones_utm_campaign ON conversiones_lead(utmCampaign)

-- Touchpoints del customer journey
-- Para análisis de atribución multi-touch
CREATE TABLE touchpoints_conversion (
    touchpointId INT IDENTITY(1,1) PRIMARY KEY,
    conversionId INT NOT NULL,
    interaccionId INT NOT NULL,
    ordenTouchpoint INT NOT NULL,
    porcentajeAtribucion DECIMAL(5,2),
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_touchpoints_conversion FOREIGN KEY (conversionId) REFERENCES conversiones_lead(conversionId) ON DELETE CASCADE,
    CONSTRAINT fk_touchpoints_interaccion FOREIGN KEY (interaccionId) REFERENCES interacciones(interaccionId)
)
CREATE INDEX idx_touchpoints_conversion ON touchpoints_conversion(conversionId)

------------------ SISTEMA DE LOGS ---------------------

CREATE TABLE operation_logs (
    logId INT IDENTITY(1,1) PRIMARY KEY,
    nivelLogId INT NOT NULL,
    tipoLogId INT NOT NULL,
    usuarioId INT,
    nombreOperacion NVARCHAR(120) NOT NULL,
    descripcion NVARCHAR(500),
    direccionIp NVARCHAR(45),
    nombreComputadora NVARCHAR(100),
    tiempoEjecucionMs INT,
    detallesError NVARCHAR(MAX),
    payload NVARCHAR(MAX),
    createdAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_logs_nivel FOREIGN KEY (nivelLogId) REFERENCES nv_niveles_log(nivelId),
    CONSTRAINT fk_logs_tipo FOREIGN KEY (tipoLogId) REFERENCES nv_tipos_log(tipoId),
    CONSTRAINT fk_logs_usuario FOREIGN KEY (usuarioId) REFERENCES cuentas_usuario(usuarioId)
)
CREATE INDEX idx_logs_created ON operation_logs(createdAt)
CREATE INDEX idx_logs_usuario ON operation_logs(usuarioId)
CREATE INDEX idx_logs_nivel ON operation_logs(nivelLogId)

GO







