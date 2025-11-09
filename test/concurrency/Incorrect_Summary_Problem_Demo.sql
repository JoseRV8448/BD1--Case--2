-- ============================================================================
-- DEMOSTRACIÓN: INCORRECT SUMMARY PROBLEM
-- Base de datos: PromptCRM
-- ============================================================================

USE PromptCRM
GO

-- Crear tabla de prueba
IF OBJECT_ID('test_summary_problem', 'U') IS NOT NULL
    DROP TABLE test_summary_problem
GO

CREATE TABLE test_summary_problem (
    cuenta_id INT PRIMARY KEY,
    saldo DECIMAL(10,2),
    ultima_actualizacion DATETIME DEFAULT GETDATE()
)
GO

-- Insertar datos de prueba
INSERT INTO test_summary_problem (cuenta_id, saldo) VALUES 
(1, 1000.00),
(2, 2000.00),
(3, 3000.00)
GO

PRINT '============================================'
PRINT 'INCORRECT SUMMARY PROBLEM - DEMOSTRACIÓN'
PRINT '============================================'
PRINT ''
PRINT 'Problema: Una transacción calcula un resumen mientras'
PRINT 'otra está modificando los datos base'
PRINT ''

-- ============================================================================
-- ESCENARIO CON PROBLEMA
-- ============================================================================

PRINT '--- ESCENARIO CON PROBLEMA ---'
PRINT ''

-- SESIÓN 1: Modificando saldos
/*
-- Ejecutar en Ventana 1:

USE PromptCRM
GO

PRINT 'SESIÓN 1: Iniciando transferencia...'
BEGIN TRANSACTION

    -- Restar de cuenta 1
    UPDATE test_summary_problem 
    SET saldo = saldo - 500
    WHERE cuenta_id = 1
    
    PRINT 'Sesión 1: Restó 500 de cuenta 1'
    PRINT 'Esperando 5 segundos antes de sumar a cuenta 2...'
    
    -- Simular procesamiento lento
    WAITFOR DELAY '00:00:05'
    
    -- Sumar a cuenta 2
    UPDATE test_summary_problem 
    SET saldo = saldo + 500
    WHERE cuenta_id = 2
    
    PRINT 'Sesión 1: Sumó 500 a cuenta 2'
    PRINT 'Transacción completada'

COMMIT TRANSACTION

-- Verificar saldos finales
SELECT 
    'Después de transferencia' as Estado,
    SUM(saldo) as SaldoTotal 
FROM test_summary_problem
*/

-- SESIÓN 2: Calculando resumen
/*
-- Ejecutar en Ventana 2 (2 segundos después de Ventana 1):

USE PromptCRM
GO

PRINT 'SESIÓN 2: Calculando resumen de saldos...'

-- Sin aislamiento apropiado, puede leer estado inconsistente
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
    'Resumen durante transferencia' as Estado,
    COUNT(*) as TotalCuentas,
    SUM(saldo) as SaldoTotal,
    AVG(saldo) as SaldoPromedio,
    MIN(saldo) as SaldoMinimo,
    MAX(saldo) as SaldoMaximo
FROM test_summary_problem

-- PROBLEMA: El resumen puede mostrar:
-- - Saldo total = 5500 (incorrecto, debería ser 6000)
-- - Porque ve cuenta 1 con -500 pero cuenta 2 aún sin +500
*/

-- ============================================================================
-- VERSIÓN CORREGIDA
-- ============================================================================

PRINT ''
PRINT '--- VERSIÓN CORREGIDA ---'
PRINT ''

-- SOLUCIÓN 1: Usar SNAPSHOT ISOLATION
/*
-- Configurar la base de datos
ALTER DATABASE PromptCRM SET ALLOW_SNAPSHOT_ISOLATION ON
GO

-- SESIÓN 2 CORREGIDA:
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
    
    SELECT 
        'Resumen con Snapshot' as Estado,
        COUNT(*) as TotalCuentas,
        SUM(saldo) as SaldoTotal,
        AVG(saldo) as SaldoPromedio
    FROM test_summary_problem
    
    -- Siempre verá un estado consistente

COMMIT TRANSACTION
*/

-- SOLUCIÓN 2: Usar READ COMMITTED con LOCK
/*
-- SESIÓN 2 CORREGIDA:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION

    SELECT 
        'Resumen con Lock' as Estado,
        COUNT(*) as TotalCuentas,
        SUM(saldo) as SaldoTotal,
        AVG(saldo) as SaldoPromedio
    FROM test_summary_problem WITH (TABLOCKX)
    
    -- Espera hasta que la transferencia complete

COMMIT TRANSACTION
*/

-- SOLUCIÓN 3: Implementar tabla de resumen con trigger
/*
CREATE TABLE resumen_saldos (
    fecha DATE PRIMARY KEY,
    total_saldo DECIMAL(10,2),
    ultima_actualizacion DATETIME
)

CREATE TRIGGER trg_actualizar_resumen
ON test_summary_problem
AFTER UPDATE
AS
BEGIN
    UPDATE resumen_saldos 
    SET total_saldo = (SELECT SUM(saldo) FROM test_summary_problem),
        ultima_actualizacion = GETDATE()
    WHERE fecha = CAST(GETDATE() AS DATE)
    
    IF @@ROWCOUNT = 0
        INSERT INTO resumen_saldos 
        VALUES (
            CAST(GETDATE() AS DATE),
            (SELECT SUM(saldo) FROM test_summary_problem),
            GETDATE()
        )
END
*/

-- ============================================================================
-- DEMOSTRACIÓN PRÁCTICA
-- ============================================================================

PRINT ''
PRINT '============================================'
PRINT 'PASOS PARA REPRODUCIR EL PROBLEMA:'
PRINT '============================================'
PRINT '1. Abrir 2 ventanas de SSMS'
PRINT '2. En Ventana 1: Ejecutar transferencia (tarda 5 segundos)'
PRINT '3. En Ventana 2: Ejecutar resumen 2 segundos después'
PRINT '4. Observar: Resumen muestra total incorrecto (5500 vs 6000)'
PRINT ''
PRINT 'RESULTADO ESPERADO DEL PROBLEMA:'
PRINT '- Saldo inicial total: 6000'
PRINT '- Durante transferencia: 5500 (incorrecto)'
PRINT '- Después transferencia: 6000 (correcto)'
PRINT '============================================'

-- Resetear datos para prueba
UPDATE test_summary_problem SET saldo = 1000 WHERE cuenta_id = 1
UPDATE test_summary_problem SET saldo = 2000 WHERE cuenta_id = 2
UPDATE test_summary_problem SET saldo = 3000 WHERE cuenta_id = 3

SELECT 'Estado Inicial' as Estado, * FROM test_summary_problem
SELECT 'Total Inicial' as Info, SUM(saldo) as SaldoTotal FROM test_summary_problem
GO

-- ============================================================================
-- LIMPIEZA
-- ============================================================================
/*
DROP TABLE IF EXISTS test_summary_problem
DROP TABLE IF EXISTS resumen_saldos
*/
