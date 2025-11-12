# PromptSales - Caso #2 (42%)

Sistema de marketing digital con arquitectura multi-base de datos para gestión de campañas publicitarias con IA.

## Navegación del Proyecto

### Bases de Datos
- **[MongoDB - PromptContent](./MongoDB/)** - Contenido multimedia y vectorización
- **[SQL Server - PromptAds](./SQLServer/PromptAds/)** - Gestión de campañas (1000+)
- **[SQL Server - PromptCRM](./SQLServer/PromptCRM/)** - Clientes (500K registros)
- **[PostgreSQL - PromptSales](./PostgreSQL/)** - Data warehouse centralizado
- **[Redis Cache](./Redis/)** - Cache de respuestas (<400ms)

### Componentes Técnicos
- **[MCP Servers](./MCP/)** - Servidores de comunicación entre sistemas
- **[ETL Pipeline](./ETL/)** - SQL Server Agent cada 11 minutos
- **[Seguridad](./Security/)** - Certificados X.509 y cifrado
- **[Kubernetes](./Kubernetes/)** - Configuración de deployment
- **[Simulaciones](./Simulations/)** - Problemas de concurrencia

## Estado del Proyecto

### Completado (Entregable 2)
- **MongoDB MCP Server**: 2 tools funcionales
  - `getContent`: Búsqueda semántica con embeddings
  - `generateCampaignMessages`: Generación de contenido con vectores
- **Vistas ETL**: Creadas en source DBs (SQL Server)
- **Simulaciones de Concurrencia**: Deadlock, Dirty Read, Lost Update
- **Linked Server**: Conexión bidireccional CRM ↔ Ads
- **Stored Procedures**: Con TVPs implementados

### En Proceso
- Integración completa del pipeline ETL con SQL Server Agent
- Optimización de queries con PARTITION BY

### Proceso y Decisiones Técnicas

#### Por qué MongoDB para PromptContent
- Flexibilidad para contenido multimedia variado
- Soporte nativo para vectores y búsqueda semántica
- Sin esquema rígido para evolución del contenido

#### Arquitectura ETL
```
Source DBs → Vistas ETL → SQL Agent Job → PostgreSQL DW
             (SQL Server)    (11 min)      (Agregados)
```

#### MCP Servers - Aprendizajes
- Inicialmente intentamos 4 tools, optimizamos a 2 principales
- Contexto de vectorización crucial para búsquedas precisas
- Separación por roles: marketing vs ventas vs usuarios

## Métricas del Proyecto

| Base de Datos | Registros | Estado |
|--------------|-----------|---------|
| MongoDB | 100 imágenes | ✅ Completado |
| PromptAds | 1,000 campañas | ✅ Completado |
| PromptCRM | 500K clientes | ✅ Completado |
| Redis | Cache dinámico | ✅ Configurado |

## Tecnologías Utilizadas
- **Bases**: MongoDB, SQL Server, PostgreSQL, Redis
- **Orquestación**: Docker, Kubernetes
- **ETL**: SQL Server Agent
- **APIs**: OpenAI, Pinecone
- **Seguridad**: X.509, OAuth2

## Equipo
- Lee-Sangcheol
- Sebas
- Bryan
- Josimar

## Bitácora de Uso de IA
Documentación completa del uso de herramientas de IA: [AI_USAGE_LOG.md](./AI_USAGE_LOG.md)