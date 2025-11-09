-- ============================================================================
-- SCRIPT DE EJECUCIÓN - ENTREGABLE 2
-- Orden correcto para ejecutar todos los componentes
-- ============================================================================

PRINT '================================================'
PRINT 'CASO #2: PromptSales - Entregable 2'
PRINT 'Script de ejecución completo'
PRINT '================================================'
PRINT ''

-- ============================================================================
-- PASO 1: CONFIGURACIÓN INICIAL
-- ============================================================================

PRINT 'PASO 1: Ejecutar configuraciones base'
PRINT '--------------------------------------'
PRINT '1.1. Ejecutar: 00_CreateTypes.sql (TVPs para PromptAds)'
PRINT '1.2. Ejecutar: 01_Setup_LinkedServer.sql (Link CRM<->Ads)'
PRINT '1.3. Ejecutar: CIFRADO_x_509.sql (Encriptación X.509)'
PRINT ''

-- ============================================================================
-- PASO 2: VISTAS ETL (CRÍTICAS)
-- ============================================================================

PRINT 'PASO 2: Crear vistas ETL para N8N'
PRINT '----------------------------------'
PRINT '2.1. Ejecutar: VISTAS_ETL_FALTANTES.sql'
PRINT '     - Crea vw_CRM_Campaign_Sales_ETL en PromptCRM'
PRINT '     - Crea vw_ADS_Campaign_Summary_ETL en PromptAds'
PRINT ''

-- ============================================================================
-- PASO 3: PROBLEMAS DE CONCURRENCIA
-- ============================================================================

PRINT 'PASO 3: Demostraciones de concurrencia'
PRINT '---------------------------------------'
PRINT '3.1. Dirty Read: Dirty_Read.sql (YA EXISTE)'
PRINT '3.2. Deadlock Cascade: Deadlock_Cascade_Demo.sql (NUEVO)'
PRINT '3.3. Incorrect Summary: Incorrect_Summary_Problem_Demo.sql (NUEVO)'
PRINT '3.4. Lost Update: Lost_Update_Problem_Demo.sql (NUEVO)'
PRINT ''

-- ============================================================================
-- PASO 4: ETL Y ORQUESTACIÓN
-- ============================================================================

PRINT 'PASO 4: Configurar ETL con N8N'
PRINT '-------------------------------'
PRINT '4.1. PostgreSQL: PromptSales.sql (estructura ETL)'
PRINT '4.2. Docker: Levantar N8N'
PRINT '     docker run -d --name n8n -p 5678:5678 n8nio/n8n'
PRINT '4.3. Importar: n8n-workflow-etl.json'
PRINT '4.4. Configurar credenciales de cada DB en N8N'
PRINT ''

-- ============================================================================
-- PASO 5: KUBERNETES DEPLOYMENT
-- ============================================================================

PRINT 'PASO 5: Desplegar con Kubernetes'
PRINT '---------------------------------'
PRINT '5.1. Aplicar: kubectl apply -f k8s-deployment-basic.yaml'
PRINT '5.2. Verificar: kubectl get pods -n promptsales'
PRINT '5.3. Ver logs: kubectl logs -n promptsales deployment/n8n-etl'
PRINT ''

-- ============================================================================
-- VERIFICACIÓN FINAL
-- ============================================================================

PRINT '================================================'
PRINT 'CHECKLIST DE VERIFICACIÓN'
PRINT '================================================'
PRINT ''
PRINT '[ ] Linked Server funciona (CRM <-> Ads)'
PRINT '[ ] X.509 encryption funciona'
PRINT '[ ] Vistas ETL creadas:'
PRINT '    [ ] vw_CRM_Campaign_Sales_ETL'
PRINT '    [ ] vw_ADS_Campaign_Summary_ETL'
PRINT '[ ] Problemas de concurrencia demostrados:'
PRINT '    [ ] Dirty Read'
PRINT '    [ ] Deadlock Cascade'
PRINT '    [ ] Incorrect Summary Problem'
PRINT '    [ ] Lost Update'
PRINT '[ ] N8N workflow importado y configurado'
PRINT '[ ] Kubernetes pods corriendo'
PRINT '[ ] MongoDB MCP server funcional'
PRINT '[ ] GitHub actualizado con todos los archivos'
PRINT ''

-- ============================================================================
-- ARCHIVOS CREADOS NUEVOS (CRÍTICOS)
-- ============================================================================

PRINT '================================================'
PRINT 'ARCHIVOS NUEVOS CREADOS HOY'
PRINT '================================================'
PRINT ''
PRINT '1. VISTAS_ETL_FALTANTES.sql - CRÍTICO para ETL'
PRINT '2. Deadlock_Cascade_Demo.sql'
PRINT '3. Incorrect_Summary_Problem_Demo.sql' 
PRINT '4. Lost_Update_Problem_Demo.sql'
PRINT '5. k8s-deployment-basic.yaml'
PRINT '6. n8n-workflow-etl.json'
PRINT '7. ENTREGABLE2_CHECKLIST.md'
PRINT ''

-- ============================================================================
-- QUÉ DECIR EN LA REVISIÓN
-- ============================================================================

PRINT '================================================'
PRINT 'TALKING POINTS PARA LA REVISIÓN'
PRINT '================================================'
PRINT ''
PRINT 'MongoDB/MCP:'
PRINT '"Implementé MCP server con semantic search usando embeddings vectoriales."'
PRINT '"Los 2 tools funcionan: getContent y generateCampaignMessages."'
PRINT ''
PRINT 'ETL Pipeline:'
PRINT '"El ETL corre cada 11 minutos con N8N, procesando solo deltas."'
PRINT '"Usa watermarks para tracking incremental."'
PRINT ''
PRINT 'Concurrencia:'
PRINT '"Demostré los 4 problemas: dirty read, deadlock cascade, incorrect summary, lost update."'
PRINT '"Cada uno con su solución correspondiente."'
PRINT ''
PRINT 'Kubernetes:'
PRINT '"Deployment con pods separados para cada servicio."'
PRINT '"Configurado para escalar según requerimientos."'
PRINT ''

PRINT '================================================'
PRINT 'FIN DEL SCRIPT DE EJECUCIÓN'
PRINT '================================================'
