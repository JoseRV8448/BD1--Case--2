-- ============================================================================
-- DEMOSTRACIÓN: LOST UPDATE PROBLEM
-- Base de datos: PromptCRM
-- ============================================================================

USE PromptCRM
GO

-- Crear tabla de prueba
IF OBJECT_ID('test_lost_update', 'U') IS NOT NULL
    DROP TABLE test_lost_update
GO

CREATE TABLE test_lost_update (
    producto_id INT PRIMARY KEY,
    nombre VARCHAR(50),
    stock INT,
    precio DECIMAL(10,2),
    version INT DEFAULT 0
)
GO

-- Insertar datos de prueba
INSERT INTO test_lost_update (producto_id, nombre, stock, precio) VALUES 
(1, 'Samsung Galaxy Watch', 100, 299.99),
(2, 'iPhone 15', 50, 999.99),
(3, 'AirPods Pro', 200, 249.99)
GO

PRINT '============================================'
PRINT 'LOST UPDATE PROBLEM - DEMOSTRACIÓN'
PRINT '============================================'
PRINT ''
PRINT 'Problema: Dos transacciones leen el mismo valor,'
PRINT 'lo modifican y una sobrescribe los cambios de la otra'
PRINT ''

-- ============================================================================
-- ESCENARIO CON PROBLEMA
-- ============================================================================

PRINT '--- ESCENARIO CON PROBLEMA ---'
PRINT 'Stock inicial: 100 unidades'
PRINT ''

-- SESIÓN 1: Vendedor A vende 5 unidades
/*
-- Ejecutar en Ventana 1:

USE PromptCRM
GO

DECLARE @stock_actual INT

PRINT 'VENDEDOR A: Procesando venta de 5 unidades...'

-- Paso 1: Leer stock actual
SELECT @stock_actual = stock 
FROM test_lost_update 
WHERE producto_id = 1

PRINT 'Vendedor A: Stock leído = ' + CAST(@stock_actual AS VARCHAR)

-- Simular tiempo de procesamiento
PRINT 'Vendedor A: Procesando pago del cliente...'
WAITFOR DELAY '00:00:05'

-- Paso 2: Actualizar con nuevo valor
UPDATE test_lost_update 
SET stock = @stock_actual - 5
WHERE producto_id = 1

PRINT 'Vendedor A: Stock actualizado a ' + CAST((@stock_actual - 5) AS VARCHAR)
PRINT 'Vendedor A: Venta completada'

-- Verificar
SELECT 'Después Vendedor A' as Estado, stock FROM test_lost_update WHERE producto_id = 1
*/

-- SESIÓN 2: Vendedor B vende 3 unidades
/*
-- Ejecutar en Ventana 2 (1 segundo después de Ventana 1):

USE PromptCRM
GO

DECLARE @stock_actual INT

PRINT 'VENDEDOR B: Procesando venta de 3 unidades...'

-- Paso 1: Leer stock actual (lee 100, no ve que A está procesando)
SELECT @stock_actual = stock 
FROM test_lost_update 
WHERE producto_id = 1

PRINT 'Vendedor B: Stock leído = ' + CAST(@stock_actual AS VARCHAR)

-- Simular tiempo de procesamiento
PRINT 'Vendedor B: Verificando tarjeta de crédito...'
WAITFOR DELAY '00:00:03'

-- Paso 2: Actualizar con nuevo valor
UPDATE test_lost_update 
SET stock = @stock_actual - 3
WHERE producto_id = 1

PRINT 'Vendedor B: Stock actualizado a ' + CAST((@stock_actual - 3) AS VARCHAR)
PRINT 'Vendedor B: Venta completada'

-- Verificar
SELECT 'Después Vendedor B' as Estado, stock FROM test_lost_update WHERE producto_id = 1

-- PROBLEMA: Stock final = 97 (perdió la actualización de A)
-- Debería ser: 100 - 5 - 3 = 92
*/

-- ============================================================================
-- VERSIÓN CORREGIDA - SOLUCIÓN 1: TRANSACCIÓN CON LOCK
-- ============================================================================

PRINT ''
PRINT '--- SOLUCIÓN 1: TRANSACCIÓN CON LOCK ---'
PRINT ''

/*
-- VENDEDOR A CORREGIDO:
BEGIN TRANSACTION
    
    DECLARE @stock_actual INT
    
    -- Lock exclusivo durante toda la transacción
    SELECT @stock_actual = stock 
    FROM test_lost_update WITH (UPDLOCK, HOLDLOCK)
    WHERE producto_id = 1
    
    PRINT 'Stock actual: ' + CAST(@stock_actual AS VARCHAR)
    
    -- Procesar venta
    WAITFOR DELAY '00:00:02'
    
    -- Actualizar
    UPDATE test_lost_update 
    SET stock = @stock_actual - 5
    WHERE producto_id = 1
    
COMMIT TRANSACTION
*/

-- ============================================================================
-- VERSIÓN CORREGIDA - SOLUCIÓN 2: OPTIMISTIC LOCKING (VERSIONING)
-- ============================================================================

PRINT ''
PRINT '--- SOLUCIÓN 2: OPTIMISTIC LOCKING ---'
PRINT ''

/*
-- VENDEDOR A CORREGIDO:
DECLARE @stock_actual INT
DECLARE @version_actual INT
DECLARE @filas_afectadas INT

-- Leer valores actuales
SELECT @stock_actual = stock, @version_actual = version
FROM test_lost_update 
WHERE producto_id = 1

PRINT 'Stock: ' + CAST(@stock_actual AS VARCHAR) + ', Version: ' + CAST(@version_actual AS VARCHAR)

-- Procesar venta
WAITFOR DELAY '00:00:02'

-- Actualizar solo si la versión no cambió
UPDATE test_lost_update 
SET stock = @stock_actual - 5,
    version = version + 1
WHERE producto_id = 1
  AND version = @version_actual

SET @filas_afectadas = @@ROWCOUNT

IF @filas_afectadas = 0
BEGIN
    PRINT 'ERROR: El registro fue modificado por otro usuario. Reintente.'
    -- Reintentar o informar al usuario
END
ELSE
BEGIN
    PRINT 'Actualización exitosa'
END
*/

-- ============================================================================
-- VERSIÓN CORREGIDA - SOLUCIÓN 3: STORED PROCEDURE ATÓMICO
-- ============================================================================

PRINT ''
PRINT '--- SOLUCIÓN 3: STORED PROCEDURE ATÓMICO ---'
PRINT ''

-- Crear procedimiento
IF OBJECT_ID('sp_actualizar_stock', 'P') IS NOT NULL
    DROP PROCEDURE sp_actualizar_stock
GO

CREATE PROCEDURE sp_actualizar_stock
    @producto_id INT,
    @cantidad INT,
    @resultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    BEGIN TRANSACTION
    
    -- Actualización atómica
    UPDATE test_lost_update WITH (ROWLOCK)
    SET stock = stock - @cantidad
    WHERE producto_id = @producto_id
      AND stock >= @cantidad
    
    IF @@ROWCOUNT = 0
    BEGIN
        SET @resultado = 0 -- No hay suficiente stock
        ROLLBACK TRANSACTION
    END
    ELSE
    BEGIN
        SET @resultado = 1 -- Éxito
        COMMIT TRANSACTION
    END
END
GO

/*
-- USO:
DECLARE @resultado INT
EXEC sp_actualizar_stock 
    @producto_id = 1, 
    @cantidad = 5, 
    @resultado = @resultado OUTPUT

IF @resultado = 1
    PRINT 'Venta exitosa'
ELSE
    PRINT 'Stock insuficiente'
*/

-- ============================================================================
-- DEMOSTRACIÓN PRÁCTICA
-- ============================================================================

PRINT ''
PRINT '============================================'
PRINT 'PASOS PARA REPRODUCIR EL PROBLEMA:'
PRINT '============================================'
PRINT '1. Resetear stock a 100'
PRINT '2. Ventana 1: Vendedor A vende 5 unidades (tarda 5 seg)'
PRINT '3. Ventana 2: Vendedor B vende 3 unidades (empieza 1 seg después)'
PRINT '4. Resultado erróneo: Stock = 97 (perdió update de A)'
PRINT '5. Resultado correcto: Stock = 92'
PRINT ''
PRINT 'CLAVE DEL PROBLEMA:'
PRINT '- Ambos leen stock = 100'
PRINT '- A calcula: 100 - 5 = 95'
PRINT '- B calcula: 100 - 3 = 97'
PRINT '- B sobrescribe el update de A'
PRINT '============================================'

-- Resetear para pruebas
UPDATE test_lost_update SET stock = 100, version = 0 WHERE producto_id = 1
SELECT 'Estado Inicial' as Estado, * FROM test_lost_update WHERE producto_id = 1
GO

-- ============================================================================
-- LIMPIEZA
-- ============================================================================
/*
DROP TABLE IF EXISTS test_lost_update
DROP PROCEDURE IF EXISTS sp_actualizar_stock
*/
