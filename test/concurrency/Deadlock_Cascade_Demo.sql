-- ============================================================================
-- DEMOSTRACIÓN: DEADLOCK EN CASCADA DE 3 TRANSACCIONES
-- Base de datos: PromptCRM
-- ============================================================================

USE PromptCRM
GO

-- Crear tabla de prueba para el deadlock
IF OBJECT_ID('test_deadlock_cascade', 'U') IS NOT NULL
    DROP TABLE test_deadlock_cascade
GO

CREATE TABLE test_deadlock_cascade (
    id INT PRIMARY KEY,
    valor INT,
    bloqueado_por VARCHAR(50)
)
GO

-- Insertar datos de prueba
INSERT INTO test_deadlock_cascade VALUES 
(1, 100, NULL),
(2, 200, NULL),
(3, 300, NULL)
GO

PRINT '============================================'
PRINT 'DEADLOCK CASCADE - 3 TRANSACCIONES'
PRINT '============================================'
PRINT ''
PRINT 'Ejecutar cada sesión en una ventana diferente de SSMS'
PRINT ''

-- ============================================================================
-- SESIÓN 1 (Ventana 1 en SSMS)
-- ============================================================================
/*
-- Copiar y ejecutar en Ventana 1:

USE PromptCRM
GO

PRINT 'SESIÓN 1: Iniciando transacción...'
BEGIN TRANSACTION

    -- Paso 1: Sesión 1 bloquea registro 1
    UPDATE test_deadlock_cascade 
    SET valor = valor + 10,
        bloqueado_por = 'Sesion1'
    WHERE id = 1
    
    PRINT 'Sesión 1: Bloqueó registro 1'
    PRINT 'Esperando 5 segundos...'
    WAITFOR DELAY '00:00:05'
    
    -- Paso 4: Sesión 1 intenta acceder registro 2 (bloqueado por Sesión 2)
    PRINT 'Sesión 1: Intentando acceder registro 2...'
    UPDATE test_deadlock_cascade 
    SET valor = valor + 10
    WHERE id = 2
    
    PRINT 'Sesión 1: Completada'

COMMIT TRANSACTION
*/

-- ============================================================================
-- SESIÓN 2 (Ventana 2 en SSMS)
-- ============================================================================
/*
-- Copiar y ejecutar en Ventana 2 (1 segundo después de Ventana 1):

USE PromptCRM
GO

PRINT 'SESIÓN 2: Iniciando transacción...'
BEGIN TRANSACTION

    -- Paso 2: Sesión 2 bloquea registro 2
    UPDATE test_deadlock_cascade 
    SET valor = valor + 20,
        bloqueado_por = 'Sesion2'
    WHERE id = 2
    
    PRINT 'Sesión 2: Bloqueó registro 2'
    PRINT 'Esperando 5 segundos...'
    WAITFOR DELAY '00:00:05'
    
    -- Paso 5: Sesión 2 intenta acceder registro 3 (bloqueado por Sesión 3)
    PRINT 'Sesión 2: Intentando acceder registro 3...'
    UPDATE test_deadlock_cascade 
    SET valor = valor + 20
    WHERE id = 3
    
    PRINT 'Sesión 2: Completada'

COMMIT TRANSACTION
*/

-- ============================================================================
-- SESIÓN 3 (Ventana 3 en SSMS)
-- ============================================================================
/*
-- Copiar y ejecutar en Ventana 3 (2 segundos después de Ventana 1):

USE PromptCRM
GO

PRINT 'SESIÓN 3: Iniciando transacción...'
BEGIN TRANSACTION

    -- Paso 3: Sesión 3 bloquea registro 3
    UPDATE test_deadlock_cascade 
    SET valor = valor + 30,
        bloqueado_por = 'Sesion3'
    WHERE id = 3
    
    PRINT 'Sesión 3: Bloqueó registro 3'
    PRINT 'Esperando 5 segundos...'
    WAITFOR DELAY '00:00:05'
    
    -- Paso 6: Sesión 3 intenta acceder registro 1 (bloqueado por Sesión 1)
    -- ESTO CAUSA EL DEADLOCK EN CASCADA!
    PRINT 'Sesión 3: Intentando acceder registro 1...'
    UPDATE test_deadlock_cascade 
    SET valor = valor + 30
    WHERE id = 1
    
    PRINT 'Sesión 3: Completada'

COMMIT TRANSACTION
*/

-- ============================================================================
-- MONITOREO DEL DEADLOCK
-- ============================================================================
-- Ejecutar en una ventana separada para ver los bloqueos:

/*
SELECT 
    session_id,
    blocking_session_id,
    wait_type,
    wait_time,
    wait_resource,
    command,
    status
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0
*/

-- ============================================================================
-- RESULTADO ESPERADO
-- ============================================================================
/*
El deadlock ocurre porque:
1. Sesión 1 tiene lock en Registro 1, quiere Registro 2
2. Sesión 2 tiene lock en Registro 2, quiere Registro 3  
3. Sesión 3 tiene lock en Registro 3, quiere Registro 1

Esto forma un ciclo: 1→2→3→1

SQL Server detectará el deadlock y elegirá una víctima (generalmente la 
transacción con menor costo de rollback). Esa sesión recibirá el error:

"Msg 1205, Level 13, State 51
Transaction (Process ID XX) was deadlocked on lock resources with another 
process and has been chosen as the deadlock victim. Rerun the transaction."
*/

-- ============================================================================
-- VERSIÓN CORREGIDA - PREVENIR DEADLOCK CASCADE
-- ============================================================================

PRINT ''
PRINT '============================================'
PRINT 'VERSIÓN CORREGIDA - SIN DEADLOCK'
PRINT '============================================'
PRINT ''

-- Solución 1: Acceder recursos en el mismo orden
/*
-- Todas las sesiones acceden en orden: 1, 2, 3

-- SESIÓN 1 CORREGIDA:
BEGIN TRANSACTION
    UPDATE test_deadlock_cascade SET valor = valor + 10 WHERE id = 1
    UPDATE test_deadlock_cascade SET valor = valor + 10 WHERE id = 2
COMMIT

-- SESIÓN 2 CORREGIDA:  
BEGIN TRANSACTION
    UPDATE test_deadlock_cascade SET valor = valor + 20 WHERE id = 2
    UPDATE test_deadlock_cascade SET valor = valor + 20 WHERE id = 3
COMMIT

-- SESIÓN 3 CORREGIDA:
BEGIN TRANSACTION
    UPDATE test_deadlock_cascade SET valor = valor + 30 WHERE id = 1
    UPDATE test_deadlock_cascade SET valor = valor + 30 WHERE id = 3
COMMIT
*/

-- Solución 2: Usar NOWAIT para fallar rápido
/*
BEGIN TRANSACTION
    SET LOCK_TIMEOUT 1000 -- Timeout de 1 segundo
    
    UPDATE test_deadlock_cascade WITH (NOWAIT)
    SET valor = valor + 10 
    WHERE id = 1
    
    -- Si no puede obtener el lock inmediatamente, falla
COMMIT
*/

-- Solución 3: Usar niveles de aislamiento apropiados
/*
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
    -- Las lecturas no bloquean escrituras
    -- Las escrituras no bloquean lecturas
COMMIT
*/

-- ============================================================================
-- LIMPIEZA
-- ============================================================================
/*
DROP TABLE IF EXISTS test_deadlock_cascade
*/

PRINT ''
PRINT '============================================'
PRINT 'FIN DE DEMOSTRACIÓN DEADLOCK CASCADE'
PRINT '============================================'
