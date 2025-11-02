# PromptSales - Caso #2 (42%)

## Descripción
Sistema de marketing digital con 4 bases de datos + Redis cache.

## Bases de Datos
1. **Redis**: Cache (< 400ms respuesta)
2. **MongoDB**: PromptContent (100 imágenes + vectorización)  
3. **SQL Server**: PromptAds (1000 campañas) + PromptCRM (500K clientes)
4. **PostgreSQL**: PromptSales (datos sumarizados, ETL cada 11 min)

## Requisitos Cumplidos
- ✅ SP con TVPs
- ✅ Link Server CRM ↔ Ads
- ✅ Cifrado X.509
- ✅ MCP Servers (2 tools/BD)
- ✅ ETL visual (Pentaho)
- ✅ Simulaciones: Deadlock, Dirty Read, Lost Update
- ✅ Queries: EXCEPT, INTERSECT, MERGE, CTEs, PARTITION, etc.

## Fechas
- 28 Oct: Revisión diseños
- 16-22 Nov: Entrega final

## Bitácora IA
[Ver AI_USAGE_LOG.md](AI_USAGE_LOG.md)
