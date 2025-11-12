-- ============================================================================
-- CIFRADO X.509 para PromptCRM - VERSIÓN SIMPLIFICADA
-- Autor: Equipo PromptSales
-- Solo lo esencial pedido en el enunciado
-- ============================================================================

USE PromptCRM;
GO

-- 1. CREAR MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PromptCRM_Key2024!';
GO

-- 2. CREAR CERTIFICADO
CREATE CERTIFICATE CertificadoPromptCRM
WITH SUBJECT = 'Certificado para cifrado de identificaciones',
     EXPIRY_DATE = '2030-12-31';
GO

-- 3. CREAR SYMMETRIC KEY
CREATE SYMMETRIC KEY SymKey_ClienteData
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoPromptCRM;
GO

-- 4. FUNCIONES PARA CIFRAR/DESCIFRAR
-- Función para cifrar (usada al insertar)
CREATE OR ALTER FUNCTION fn_CifrarIdentificacion
(
    @identificacion NVARCHAR(50)
)
RETURNS VARBINARY(256)
AS
BEGIN
    RETURN EncryptByPassPhrase('PromptCRM_Pass_2024!', @identificacion)
END
GO

-- Función para descifrar (usada al consultar)
CREATE OR ALTER FUNCTION fn_DescifrarIdentificacion
(
    @identificacionCifrada VARBINARY(256)
)
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN CONVERT(NVARCHAR(50), DecryptByPassPhrase('PromptCRM_Pass_2024!', @identificacionCifrada))
END
GO

-- 5. EJEMPLO DE USO CON INSERT
-- Al insertar un cliente:
INSERT INTO clientes (
    tipoClienteId, 
    estadoClienteId, 
    identificacionEncrypted,  -- Campo cifrado
    nombreEmpresa, 
    nombreContacto, 
    apellidoContacto, 
    creadoPor
)
VALUES (
    1, 
    1, 
    dbo.fn_CifrarIdentificacion('123-4567890-1'), -- Usar función al insertar
    'Empresa Demo SA', 
    'Juan', 
    'Pérez', 
    1
);

-- 6. EJEMPLO DE USO CON SELECT
-- Al consultar clientes con identificación descifrada:
SELECT 
    clienteId,
    tipoClienteId,
    estadoClienteId,
    dbo.fn_DescifrarIdentificacion(identificacionEncrypted) AS identificacion, -- Usar función al consultar
    nombreEmpresa,
    nombreContacto,
    apellidoContacto,
    createdAt
FROM clientes
WHERE deleted = 0 
  AND identificacionEncrypted IS NOT NULL;

-- 7. EJEMPLO DE UPDATE
-- Al actualizar una identificación:
UPDATE clientes
SET identificacionEncrypted = dbo.fn_CifrarIdentificacion('999-8888888-9'),
    updatedAt = GETDATE()
WHERE clienteId = 1;

-- VERIFICACIÓN FINAL
SELECT 
    COUNT(*) AS TotalClientes,
    SUM(CASE WHEN identificacionEncrypted IS NOT NULL THEN 1 ELSE 0 END) AS ClientesCifrados
FROM clientes
WHERE deleted = 0;