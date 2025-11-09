------------------- CREAR MASTER KEY EN LA BASE DE DATOS -------------------

-- La Master Key es la clave principal solo se crea UNA VEZ por base de datos

USE PromptCRM;
GO

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DatabaseKey_PromptCRM_2024!Strong';
    SELECT 'Master Key creada exitosamente' AS Resultado;
END
ELSE
BEGIN
    SELECT 'Master Key ya existe - No se requiere acción' AS Resultado;
END
GO

------------------- CREAR CERTIFICADO -------------------

-- El certificado tiene fecha de expiración y se puede hacer backup

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoPromptCRM')
BEGIN
    CREATE CERTIFICATE CertificadoPromptCRM
    WITH SUBJECT = 'Certificado para cifrado de datos sensibles PromptCRM',
         EXPIRY_DATE = '2030-12-31';
    
    SELECT 'Certificado creado exitosamente' AS Resultado;
END
ELSE
BEGIN
    SELECT 'Certificado ya existe - No se requiere acción' AS Resultado;
END
GO

------------------- HACER BACKUP DEL CERTIFICADO -------------------

-- DEBES hacer backup del certificado para poder restaurar la base de datos en otro servidor

-- 1. Crear carpeta: C:\Backups\Certificados (o cambiar la ruta)
-- 2. Ejecutar este comando (ajusta las rutas según tu servidor):

BACKUP CERTIFICATE CertificadoPromptCRM
TO FILE = 'C:\Backups\Certificados\CertificadoPromptCRM.cer'
WITH PRIVATE KEY (
    FILE = 'C:\Backups\Certificados\CertificadoPromptCRM.pvk',
    ENCRYPTION BY PASSWORD = 'CertPrivateKey_2024!Secure'
);

--		Esto archivos se deben guardar ya que sin estos no se puede descifrar los datos despues de un restore
--    - CertificadoPromptCRM.cer (certificado público)
--    - CertificadoPromptCRM.pvk (clave privada - SECRETO!)


GO

------------------- CREAR SYMMETRIC KEY -------------------

-- Esta clave se usa para cifrar/descifrar los datos reales

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'SymKey_ClienteData')
BEGIN
    CREATE SYMMETRIC KEY SymKey_ClienteData
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoPromptCRM;
    
    SELECT 'Symmetric Key creada exitosamente' AS Resultado;
END
ELSE
BEGIN
    SELECT 'Symmetric Key ya existe - No se requiere acción' AS Resultado;
END
GO

------------------- STORED PROCEDURES PARA CIFRAR/DESCIFRAR -------------------

-- No podemos usar funciones porque OPEN/CLOSE SYMMETRIC KEY
-- no están permitidos en funciones. Usamos SPs en su lugar.

-- SP: Cifrar una identificación
CREATE OR ALTER PROCEDURE sp_CifrarIdentificacion
    @identificacion NVARCHAR(50),
    @encrypted VARBINARY(256) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Abrir la clave simétrica
    OPEN SYMMETRIC KEY SymKey_ClienteData
    DECRYPTION BY CERTIFICATE CertificadoPromptCRM;
    
    -- Cifrar el dato
    SET @encrypted = EncryptByKey(Key_GUID('SymKey_ClienteData'), @identificacion);
    
    -- Cerrar la clave
    CLOSE SYMMETRIC KEY SymKey_ClienteData;
END
GO

-- SP: Descifrar una identificación
CREATE OR ALTER PROCEDURE sp_DescifrarIdentificacion
    @encrypted VARBINARY(256),
    @decrypted NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Abrir la clave simétrica
    OPEN SYMMETRIC KEY SymKey_ClienteData
    DECRYPTION BY CERTIFICATE CertificadoPromptCRM;
    
    -- Descifrar el dato
    SET @decrypted = CAST(DecryptByKey(@encrypted) AS NVARCHAR(50));
    
    -- Cerrar la clave
    CLOSE SYMMETRIC KEY SymKey_ClienteData;
END
GO

------------------- STORED PROCEDURE PARA INSERTAR CLIENTES -------------------

-- Este SP cifra automáticamente la identificación antes de guardarla

CREATE OR ALTER PROCEDURE sp_InsertarClienteConCifrado
    @tipoClienteId INT,
    @estadoClienteId INT,
    @identificacion NVARCHAR(50),
    @nombreEmpresa NVARCHAR(200) = NULL,
    @nombreContacto NVARCHAR(100) = NULL,
    @apellidoContacto NVARCHAR(100) = NULL,
    @creadoPor INT,
    @clienteId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Cifrar la identificación usando el SP
        DECLARE @identificacionCifrada VARBINARY(256);
        EXEC sp_CifrarIdentificacion @identificacion, @identificacionCifrada OUTPUT;
        
        -- Insertar el cliente con la identificación cifrada
        INSERT INTO clientes (
            tipoClienteId, 
            estadoClienteId, 
            identificacionEncrypted,
            nombreEmpresa, 
            nombreContacto, 
            apellidoContacto, 
            creadoPor
        )
        VALUES (
            @tipoClienteId, 
            @estadoClienteId, 
            @identificacionCifrada,
            @nombreEmpresa, 
            @nombreContacto, 
            @apellidoContacto, 
            @creadoPor
        );
        
        -- Obtener el ID del cliente recién creado
        SET @clienteId = SCOPE_IDENTITY();
        
        SELECT 'Cliente insertado exitosamente con ID: ' + CAST(@clienteId AS VARCHAR(10)) AS Resultado;
        
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1;
    END CATCH
END
GO

-------------------STORED PROCEDURE PARA CONSULTAR CLIENTES -------------------

-- Este SP devuelve clientes con identificaciones descifradas

CREATE OR ALTER PROCEDURE sp_ConsultarClientesConIdentificacion
    @clienteId INT = NULL  -- NULL = traer todos
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Crear tabla temporal para resultados
    CREATE TABLE #ResultadosClientes (
        clienteId INT,
        tipoClienteId INT,
        estadoClienteId INT,
        nombreEmpresa NVARCHAR(200),
        nombreContacto NVARCHAR(100),
        apellidoContacto NVARCHAR(100),
        identificacion NVARCHAR(50),
        createdAt DATETIME2,
        updatedAt DATETIME2
    );
    
    -- Obtener clientes
    DECLARE @currentClienteId INT;
    DECLARE @encrypted VARBINARY(256);
    DECLARE @decrypted NVARCHAR(50);
    DECLARE @tipoClienteId INT;
    DECLARE @estadoClienteId INT;
    DECLARE @nombreEmpresa NVARCHAR(200);
    DECLARE @nombreContacto NVARCHAR(100);
    DECLARE @apellidoContacto NVARCHAR(100);
    DECLARE @createdAt DATETIME2;
    DECLARE @updatedAt DATETIME2;
    
    DECLARE cliente_cursor CURSOR FOR
    SELECT clienteId, tipoClienteId, estadoClienteId, nombreEmpresa, 
           nombreContacto, apellidoContacto, identificacionEncrypted,
           createdAt, updatedAt
    FROM clientes
    WHERE deleted = 0 
      AND identificacionEncrypted IS NOT NULL
      AND (@clienteId IS NULL OR clienteId = @clienteId);
    
    OPEN cliente_cursor;
    
    FETCH NEXT FROM cliente_cursor INTO 
        @currentClienteId, @tipoClienteId, @estadoClienteId, @nombreEmpresa,
        @nombreContacto, @apellidoContacto, @encrypted, @createdAt, @updatedAt;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Descifrar la identificación
        EXEC sp_DescifrarIdentificacion @encrypted, @decrypted OUTPUT;
        
        -- Insertar en tabla temporal
        INSERT INTO #ResultadosClientes
        VALUES (@currentClienteId, @tipoClienteId, @estadoClienteId, 
                @nombreEmpresa, @nombreContacto, @apellidoContacto,
                @decrypted, @createdAt, @updatedAt);
        
        FETCH NEXT FROM cliente_cursor INTO 
            @currentClienteId, @tipoClienteId, @estadoClienteId, @nombreEmpresa,
            @nombreContacto, @apellidoContacto, @encrypted, @createdAt, @updatedAt;
    END
    
    CLOSE cliente_cursor;
    DEALLOCATE cliente_cursor;
    
    -- Devolver resultados
    SELECT * FROM #ResultadosClientes ORDER BY clienteId;
    
    DROP TABLE #ResultadosClientes;
END
GO

------------------- STORED PROCEDURE PARA ACTUALIZAR IDENTIFICACIÓN -------------------


CREATE OR ALTER PROCEDURE sp_ActualizarIdentificacionCliente
    @clienteId INT,
    @nuevaIdentificacion NVARCHAR(50),
    @modificadoPor INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Cifrar la nueva identificación
        DECLARE @identificacionCifrada VARBINARY(256);
        EXEC sp_CifrarIdentificacion @nuevaIdentificacion, @identificacionCifrada OUTPUT;
        
        -- Actualizar el cliente
        UPDATE clientes
        SET identificacionEncrypted = @identificacionCifrada,
            modificadoPor = @modificadoPor,
            updatedAt = GETDATE()
        WHERE clienteId = @clienteId;
        
        IF @@ROWCOUNT > 0
            SELECT 'Identificación actualizada exitosamente' AS Resultado;
        ELSE
            SELECT 'Cliente no encontrado' AS Resultado;
        
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1;
    END CATCH
END
GO

-- 
------------------------------------------------------ PRUEBAS Y DEMOSTRACIÓN ------------------------------------------------------


-- 1. Insertar un cliente de prueba con identificación cifrada
DECLARE @nuevoClienteId INT;

EXEC sp_InsertarClienteConCifrado
    @tipoClienteId = 1,
    @estadoClienteId = 1,
    @identificacion = '123-4567890-1',
    @nombreEmpresa = 'Empresa Demo SA',
    @nombreContacto = 'Juan',
    @apellidoContacto = 'Pérez',
    @creadoPor = 1,
    @clienteId = @nuevoClienteId OUTPUT;
GO

-- 2. Insertar otro cliente para tener más datos
DECLARE @nuevoClienteId INT;

EXEC sp_InsertarClienteConCifrado
    @tipoClienteId = 1,
    @estadoClienteId = 1,
    @identificacion = '999-8888888-9',
    @nombreEmpresa = 'TechCorp Solutions',
    @nombreContacto = 'María',
    @apellidoContacto = 'González',
    @creadoPor = 1,
    @clienteId = @nuevoClienteId OUTPUT;
GO

-- 3. Ver la identificación CIFRADA (datos binarios)
SELECT TOP 5
    clienteId,
    nombreEmpresa,
    identificacionEncrypted AS 'Identificación Cifrada (bytes)',
    LEN(identificacionEncrypted) AS 'Tamaño en bytes'
FROM clientes
WHERE identificacionEncrypted IS NOT NULL
ORDER BY clienteId DESC;
GO

-- 4. Ver la identificación DESCIFRADA (texto legible)
EXEC sp_ConsultarClientesConIdentificacion;
GO

-- 5. Consultar un cliente específico
EXEC sp_ConsultarClientesConIdentificacion @clienteId = 1;
GO

-- 6. Actualizar una identificación
EXEC sp_ActualizarIdentificacionCliente
    @clienteId = 1,
    @nuevaIdentificacion = '555-6666666-7',
    @modificadoPor = 1;
GO

-- 7. Verificar la actualización
EXEC sp_ConsultarClientesConIdentificacion @clienteId = 1;
GO

-- Estadísticas de clientes con identificación cifrada
SELECT 
    COUNT(*) AS TotalClientes,
    SUM(CASE WHEN identificacionEncrypted IS NOT NULL THEN 1 ELSE 0 END) AS ClientesCifrados,
    CAST(SUM(CASE WHEN identificacionEncrypted IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) 
         AS DECIMAL(5,2)) AS PorcentajeCifrado
FROM clientes
WHERE deleted = 0;
GO


/*
-- Eliminar objetos de cifrado
DROP PROCEDURE IF EXISTS sp_ConsultarClientesConIdentificacion;
DROP PROCEDURE IF EXISTS sp_InsertarClienteConCifrado;
DROP PROCEDURE IF EXISTS sp_ActualizarIdentificacionCliente;
DROP PROCEDURE IF EXISTS sp_CifrarIdentificacion;
DROP PROCEDURE IF EXISTS sp_DescifrarIdentificacion;

DROP SYMMETRIC KEY IF EXISTS SymKey_ClienteData;
DROP CERTIFICATE IF EXISTS CertificadoPromptCRM;
DROP MASTER KEY;

-- Limpiar datos de prueba
DELETE FROM clientes WHERE nombreEmpresa IN ('Empresa Demo SA', 'TechCorp Solutions');
*/