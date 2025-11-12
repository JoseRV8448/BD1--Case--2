-- ============================================================================
-- PROMPTCRM - VERSIÓN SIMPLIFICADA
-- Base de datos de gestión de clientes
-- ============================================================================

USE PromptCRM;
GO

-- ============================================================================
-- TABLAS DE CATÁLOGOS (Simplificadas)
-- ============================================================================

-- Estados del cliente
CREATE TABLE nv_estados_cliente (
    estadoClienteId INT IDENTITY(1,1) PRIMARY KEY,
    nombreEstado NVARCHAR(50) NOT NULL
);

-- Tipos de cliente
CREATE TABLE nv_tipos_cliente (
    tipoClienteId INT IDENTITY(1,1) PRIMARY KEY,
    nombreTipo NVARCHAR(50) NOT NULL
);

-- Estados del lead
CREATE TABLE nv_estados_lead (
    estadoLeadId INT IDENTITY(1,1) PRIMARY KEY,
    nombreEstado NVARCHAR(50) NOT NULL,
    ordenFlujo INT
);

-- Canales de comunicación
CREATE TABLE nv_canales (
    canalId INT IDENTITY(1,1) PRIMARY KEY,
    nombreCanal NVARCHAR(50) NOT NULL,
    esDigital BIT DEFAULT 1,
    activo BIT DEFAULT 1
);

-- ============================================================================
-- TABLAS PRINCIPALES
-- ============================================================================

-- Usuarios del sistema
CREATE TABLE usuarios (
    usuarioId INT IDENTITY(1,1) PRIMARY KEY,
    nombreUsuario NVARCHAR(100) NOT NULL UNIQUE,
    nombre NVARCHAR(100) NOT NULL,
    apellido NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    activo BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0
);

-- Tabla principal de clientes
CREATE TABLE clientes (
    clienteId INT IDENTITY(1,1) PRIMARY KEY,
    tipoClienteId INT NOT NULL,
    estadoClienteId INT NOT NULL,
    identificacionEncrypted VARBINARY(256), -- Cifrado X.509
    nombreEmpresa NVARCHAR(200),
    nombreContacto NVARCHAR(100),
    apellidoContacto NVARCHAR(100),
    email NVARCHAR(255),
    telefono NVARCHAR(50),
    direccion NVARCHAR(500),
    ciudad NVARCHAR(100),
    pais NVARCHAR(100),
    sitioWeb NVARCHAR(255),
    notas NVARCHAR(MAX),
    creadoPor INT,
    modificadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    CONSTRAINT fk_clientes_tipo FOREIGN KEY (tipoClienteId) REFERENCES nv_tipos_cliente(tipoClienteId),
    CONSTRAINT fk_clientes_estado FOREIGN KEY (estadoClienteId) REFERENCES nv_estados_cliente(estadoClienteId),
    CONSTRAINT fk_clientes_creado FOREIGN KEY (creadoPor) REFERENCES usuarios(usuarioId),
    CONSTRAINT fk_clientes_modificado FOREIGN KEY (modificadoPor) REFERENCES usuarios(usuarioId)
);

CREATE INDEX idx_clientes_empresa ON clientes(nombreEmpresa);
CREATE INDEX idx_clientes_estado ON clientes(estadoClienteId);
CREATE INDEX idx_clientes_deleted ON clientes(deleted);

-- Referencias de campañas (para sincronizar con PromptAds)
CREATE TABLE referencias_campanas (
    referenciaId INT IDENTITY(1,1) PRIMARY KEY,
    utmCampaign NVARCHAR(100) NOT NULL UNIQUE,
    nombreCampana NVARCHAR(200),
    fechaInicio DATE,
    fechaFin DATE,
    activa BIT DEFAULT 1,
    deleted BIT DEFAULT 0
);

CREATE INDEX idx_ref_campanas_utm ON referencias_campanas(utmCampaign);

-- Leads
CREATE TABLE leads (
    leadId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    estadoLeadId INT NOT NULL,
    puntajeLead INT DEFAULT 0 CHECK (puntajeLead BETWEEN 0 AND 100),
    
    -- Parámetros UTM básicos
    utmSource NVARCHAR(100),
    utmMedium NVARCHAR(100),
    utmCampaign NVARCHAR(100),
    
    -- Información básica
    paginaOrigen NVARCHAR(500),
    fechaContacto DATETIME2 DEFAULT GETDATE(),
    
    asignadoAUsuarioId INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_leads_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_leads_estado FOREIGN KEY (estadoLeadId) REFERENCES nv_estados_lead(estadoLeadId),
    CONSTRAINT fk_leads_asignado FOREIGN KEY (asignadoAUsuarioId) REFERENCES usuarios(usuarioId)
);

CREATE INDEX idx_leads_cliente ON leads(clienteId);
CREATE INDEX idx_leads_utm_campaign ON leads(utmCampaign);
CREATE INDEX idx_leads_estado ON leads(estadoLeadId);

-- Interacciones con clientes
CREATE TABLE interacciones (
    interaccionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    canalId INT NOT NULL,
    usuarioId INT,
    leadId INT,
    asunto NVARCHAR(200),
    contenido NVARCHAR(MAX),
    fechaInteraccion DATETIME2 DEFAULT GETDATE(),
    duracionMinutos INT,
    requiereSeguimiento BIT DEFAULT 0,
    createdAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_interacciones_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_interacciones_canal FOREIGN KEY (canalId) REFERENCES nv_canales(canalId),
    CONSTRAINT fk_interacciones_usuario FOREIGN KEY (usuarioId) REFERENCES usuarios(usuarioId),
    CONSTRAINT fk_interacciones_lead FOREIGN KEY (leadId) REFERENCES leads(leadId)
);

CREATE INDEX idx_interacciones_cliente ON interacciones(clienteId, fechaInteraccion);
CREATE INDEX idx_interacciones_deleted ON interacciones(deleted);

-- Conversiones de leads
CREATE TABLE conversiones_lead (
    conversionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    leadId INT NOT NULL,
    valorConversion DECIMAL(18,2) NOT NULL CHECK (valorConversion >= 0),
    tipoConversion NVARCHAR(50) DEFAULT 'venta',
    descripcion NVARCHAR(500),
    fechaConversion DATETIME2 DEFAULT GETDATE(),
    
    -- UTMs para atribución
    utmSource NVARCHAR(100),
    utmMedium NVARCHAR(100),
    utmCampaign NVARCHAR(100),
    
    creadoPor INT,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_conversiones_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_conversiones_lead FOREIGN KEY (leadId) REFERENCES leads(leadId),
    CONSTRAINT fk_conversiones_creador FOREIGN KEY (creadoPor) REFERENCES usuarios(usuarioId)
);

CREATE INDEX idx_conversiones_cliente ON conversiones_lead(clienteId);
CREATE INDEX idx_conversiones_fecha ON conversiones_lead(fechaConversion);
CREATE INDEX idx_conversiones_deleted ON conversiones_lead(deleted);

-- Relación clientes-campañas
CREATE TABLE campanas_cliente (
    relacionId INT IDENTITY(1,1) PRIMARY KEY,
    clienteId INT NOT NULL,
    referenciaId INT NOT NULL,
    fechaAsociacion DATETIME2 DEFAULT GETDATE(),
    activo BIT DEFAULT 1,
    deleted BIT DEFAULT 0,
    
    CONSTRAINT fk_campanas_cliente FOREIGN KEY (clienteId) REFERENCES clientes(clienteId),
    CONSTRAINT fk_campanas_referencia FOREIGN KEY (referenciaId) REFERENCES referencias_campanas(referenciaId),
    CONSTRAINT uq_campanas_cliente UNIQUE (clienteId, referenciaId)
);

CREATE INDEX idx_campanas_cliente ON campanas_cliente(clienteId);
CREATE INDEX idx_campanas_referencia ON campanas_cliente(referenciaId);

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================

-- Estados de cliente
INSERT INTO nv_estados_cliente (nombreEstado) VALUES 
    ('Prospecto'),
    ('Activo'),
    ('Inactivo'),
    ('Suspendido');

-- Tipos de cliente
INSERT INTO nv_tipos_cliente (nombreTipo) VALUES 
    ('Empresa'),
    ('Persona'),
    ('Gobierno');

-- Estados de lead
INSERT INTO nv_estados_lead (nombreEstado, ordenFlujo) VALUES 
    ('Nuevo', 1),
    ('Contactado', 2),
    ('Calificado', 3),
    ('Propuesta', 4),
    ('Negociación', 5),
    ('Ganado', 6),
    ('Perdido', 7);

-- Canales
INSERT INTO nv_canales (nombreCanal, esDigital) VALUES 
    ('Email', 1),
    ('Teléfono', 1),
    ('WhatsApp', 1),
    ('Facebook', 1),
    ('Instagram', 1),
    ('LinkedIn', 1),
    ('Presencial', 0);

-- Usuario de sistema
INSERT INTO usuarios (nombreUsuario, nombre, apellido, email) VALUES 
    ('admin', 'Admin', 'Sistema', 'admin@promptcrm.com'),
    ('ventas1', 'Juan', 'Pérez', 'juan.perez@promptcrm.com'),
    ('ventas2', 'María', 'González', 'maria.gonzalez@promptcrm.com');

GO

PRINT 'PromptCRM - Tablas creadas exitosamente (versión simplificada)';
GO