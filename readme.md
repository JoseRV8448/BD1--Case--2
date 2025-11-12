# PromptSales - Caso #2 (42%)

Sistema de marketing digital con arquitectura multi-base de datos para gestión de campañas publicitarias con IA.

## Navegación del Proyecto

### Bases de Datos
- **[MongoDB - PromptContent](./database/mongodb/)** → Contenido multimedia y vectorización semántica  
- **[SQL Server - PromptAds](./database/sqlserver_ads/)** → Gestión de campañas publicitarias (1000+)  
- **[SQL Server - PromptCRM](./database/sqlserver_crm/)** → Información y métricas de clientes (500K registros)  
- **[PostgreSQL - PromptSales](./database/postgresql/)** → Data warehouse centralizado y reportes  
- **[Redis Cache](./database/redis/)** → Cache de respuestas de alta velocidad (<400 ms)

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
