# README - ETL con SQL Server Agent

## Descripción
ETL incremental que se ejecuta cada 11 minutos usando SQL Server Agent (nativo).

## Componentes:

### 1. Vistas ETL (en bases origen)
- `vw_ADS_Campaign_Summary_ETL` (PromptAds)
- `vw_CRM_Campaign_Sales_ETL` (PromptCRM)

### 2. Data Warehouse (PromptSales_DW)
- Schema `staging`: Tablas temporales
- Schema `dw`: Fact tables finales
- Schema `etl`: Control y logs

### 3. Stored Procedure Principal
- `sp_ETL_Run_Every_11_Minutes`
- Usa MERGE con hash detection
- Watermarks para procesamiento incremental
- Transaccional (rollback si falla)

### 4. SQL Server Agent Job
- Nombre: `ETL_PromptSales_11min`
- Frecuencia: Cada 11 minutos
- Horario: 24/7

## Instalación:

```sql
-- 1. Ejecutar vistas en bases origen
sqlcmd -i VISTAS_ETL_FALTANTES.sql

-- 2. Crear DW y configurar ETL
sqlcmd -i ETL_SQLServerAgent_Complete.sql

-- 3. Iniciar job manualmente (opcional)
EXEC msdb.dbo.sp_start_job @job_name = 'ETL_PromptSales_11min'
```

## Monitoreo:

```sql
-- Ver últimas ejecuciones
SELECT TOP 10 * FROM PromptSales_DW.etl.execution_log ORDER BY log_id DESC;

-- Health check
EXEC PromptSales_DW.dbo.sp_ETL_HealthCheck;

-- Ver estado del job
EXEC msdb.dbo.sp_help_job @job_name = 'ETL_PromptSales_11min';
```

## Diferencias vs N8N:

| Aspecto | N8N ❌ | SQL Agent ✅ |
|---------|--------|--------------|
| Delta Processing | No | Sí (watermarks) |
| Transaccional | No | Sí (ROLLBACK) |
| Change Detection | No | Sí (HASH) |
| Performance | Lento | Rápido (nativo) |
| Dependencias | Node.js | Ninguna |
| ETL Real | No | Sí |

## Logs:

Los logs se guardan en `etl.execution_log`:
- Tiempo de ejecución
- Registros procesados  
- Duración en segundos
- Status (SUCCESS/ERROR)
- Mensaje de error si falla
