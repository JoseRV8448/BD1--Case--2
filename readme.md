# 🚀 PromptSales - Caso #2 (42%)

## 📝 Descripción
Sistema end-to-end de marketing y ventas con IA. 4 bases de datos especializadas que automatizan desde creación de contenido hasta cierre de ventas. Cada subsistema puede operar independiente pero se integran via MCP servers y ETL.

## 👥 Equipo
| Miembro | BD Asignada | Discord | GitHub | Estado |
|---------|-------------|---------|--------|---------|
| [Nombre 1] | Redis + MongoDB | @user1 | @git1 | ✅ |
| [Nombre 2] | SQL Server (Ads) | @user2 | @git2 | ⏳ |
| [Nombre 3] | SQL Server (CRM) | @user3 | @git3 | ⏳ |
| [Nombre 4] | PostgreSQL + ETL | @user4 | @git4 | ⏳ |

## 📊 Arquitectura

### Vista Simplificada
Flujo principal de datos entre subsistemas:
```mermaid
graph LR
    subgraph Central
        PS[(PromptSales<br/>PostgreSQL)]
    end
    
    subgraph Subsistemas
        PC[(PromptContent<br/>MongoDB)]
        PA[(PromptAds<br/>SQL Server)]
        PCRM[(PromptCRM<br/>SQL Server)]
    end
    
    REDIS[(Redis<br/>Cache)]
    
    PC ==> PS
    PA ==> PS
    PCRM ==> PS
    
    PC --> REDIS
    PA --> REDIS
    PCRM --> REDIS
    PS --> REDIS
    
    PC <--> PA
    PA <--> PCRM
    PCRM <--> PC
    
    style PS fill:#336791,color:#fff
    style PC fill:#13aa52,color:#fff
    style PA fill:#cc2927,color:#fff
    style PCRM fill:#cc2927,color:#fff
    style REDIS fill:#dc382d,color:#fff
```

### Vista Detallada
Arquitectura completa incluyendo integraciones externas, ETL, MCP servers y deployment:
```mermaid
graph TB
    subgraph ext["🔌 EXTERNAS"]
        EXT1[Canva/Adobe/OpenAI]
        EXT2[Google Ads/Meta/TikTok]
        EXT3[HubSpot/Salesforce/WhatsApp]
    end
    
    subgraph sub["📊 SUBSISTEMAS"]
        PC[(PromptContent<br/>MongoDB<br/>Imágenes & Contenido)]
        PA[(PromptAds<br/>SQL Server<br/>1000 Campañas)]
        PCRM[(PromptCRM<br/>SQL Server<br/>500K Clientes)]
    end
    
    subgraph cache["⚡ CACHE"]
        REDIS[(Redis<br/>< 400ms<br/>Token Optimization)]
    end
    
    subgraph central["🏢 CENTRAL"]
        PS[(PromptSales<br/>PostgreSQL<br/>Data Warehouse)]
    end
    
    subgraph infra["☸️ KUBERNETES"]
        K8S[5 Pods Independientes<br/>Auto-scaling]
    end
    
    EXT1 -.->|REST API| PC
    EXT2 -.->|REST API| PA
    EXT3 -.->|REST API| PCRM
    
    PC <-->|MCP Server| PA
    PA <-->|MCP + LinkServer| PCRM
    PCRM <-->|MCP Server| PC
    
    PC -->|Cache API/MCP| REDIS
    PA -->|Cache Queries| REDIS
    PCRM -->|Cache Queries| REDIS
    
    PC ==>|ETL 11min<br/>Delta Only| PS
    PA ==>|ETL 11min<br/>Delta Only| PS
    PCRM ==>|ETL 11min<br/>Delta Only| PS
    
    PS -.->|Cache Results| REDIS
    
    PC -.->|Deploy| K8S
    PA -.->|Deploy| K8S
    PCRM -.->|Deploy| K8S
    PS -.->|Deploy| K8S
    REDIS -.->|Deploy| K8S
    
    style PC fill:#13aa52,color:#fff,stroke:#0d7d3d,stroke-width:3px
    style PA fill:#cc2927,color:#fff,stroke:#8b1c1a,stroke-width:3px
    style PCRM fill:#cc2927,color:#fff,stroke:#8b1c1a,stroke-width:3px
    style PS fill:#336791,color:#fff,stroke:#234a65,stroke-width:3px
    style REDIS fill:#dc382d,color:#fff,stroke:#9b2721,stroke-width:3px
    style K8S fill:#326ce5,color:#fff,stroke:#2574a9,stroke-width:3px
    style EXT1 fill:#7f8c8d,color:#fff
    style EXT2 fill:#7f8c8d,color:#fff
    style EXT3 fill:#7f8c8d,color:#fff
```

## 🗂️ Bases de Datos

| BD | Motor | Requisitos | Estado |
|----|-------|------------|---------|
| **Redis** | Cache | TTL, Rate limiting | ✅ |
| **PromptContent** | MongoDB | 100 imágenes + vectorización Pinecone | ✅ |
| **PromptAds** | SQL Server | 1000 campañas (30% activas) | ⏳ |
| **PromptCrm** | SQL Server | 500K clientes + X.509 + LinkServer | ⏳ |
| **PromptSales** | PostgreSQL | SSO + ETL deltas | ⏳ |

---

## 📐 Modelos de Datos Completados

### Redis Cache - Estructura de Llaves
**📁 Archivo de diseño:** [redis_design.txt](database/redis/design/redis_design.txt)
```mermaid
graph TB
    subgraph API["Cache de APIs/MCP"]
        A1["api:resultados:service:method:hash<br/>TTL: 1h"]
        A2["api:stats:service<br/>Hash | TTL: 24h"]
    end
    
    subgraph AI["Optimización de Tokens AI"]
        AI1["ai:generacion:model:hash<br/>TTL: 24h"]
        AI2["ai:tokens:user:month<br/>Hash | TTL: 30d"]
    end
    
    subgraph CONTENT["Búsqueda de Contenido"]
        C1["contenido:busqueda:hash<br/>TTL: 2h"]
    end
    
    subgraph ETL["Control de Deltas ETL"]
        E1["etl:delta:db:table<br/>TTL: 22min"]
        E2["estadisticas:campana:id<br/>Hash | TTL: 11min"]
    end
    
    subgraph SESSION["Sesiones y Auth"]
        S1["sesion:user_id<br/>Hash | TTL: 2h"]
        S2["ratelimit:service:user<br/>Counter"]
    end
    
    subgraph MCP["Servidores MCP"]
        M1["mcp:servidor:name<br/>Hash | TTL: 5min"]
    end
    
    subgraph JOBS["Cola de Trabajos"]
        J1["queue:jobs:type<br/>List"]
        J2["job:id<br/>Hash | TTL: 24h"]
        J3["lock:resource:id<br/>TTL: 30s"]
    end
    
    style API fill:#2c3e50,color:#ecf0f1
    style AI fill:#34495e,color:#ecf0f1
    style CONTENT fill:#2c3e50,color:#ecf0f1
    style ETL fill:#34495e,color:#ecf0f1
    style SESSION fill:#2c3e50,color:#ecf0f1
    style MCP fill:#34495e,color:#ecf0f1
    style JOBS fill:#2c3e50,color:#ecf0f1
```

**Patrones de Llaves:**
- Nomenclatura: `{dominio}:{entidad}:{identificador}`
- TTL Estratégico: Según frecuencia de cambio (5min - 30días)
- Cumple: Respuesta < 400ms (reduce a 5-50ms)

---

### MongoDB PromptContent - Colecciones
**📁 Archivo de diseño:** [mongodb_promptcontent_design.js](database/mongodb/design/mongodb_promptcontent_design.js)
```mermaid
graph TB
    subgraph IMAGES["imagenes (100+ docs)"]
        IMG["_id: ObjectId<br/>url_imagen, url_thumbnail<br/>descripcion<br/>hashtags<br/>categoria<br/>vector_id_pinecone<br/>metadata técnica<br/>campanas_asociadas"]
    end
    
    subgraph SERVICES["servicios_terceros"]
        SVC["nombre_servicio<br/>url_base<br/>metodos_disponibles<br/>autenticacion OAuth2 POST<br/>rate_limits<br/>estado"]
    end
    
    subgraph LOGS["bitacora_solicitudes"]
        LOG["servicio_utilizado<br/>request/response<br/>resultado<br/>tiempo_respuesta_ms<br/>tokens_consumidos"]
    end
    
    subgraph CAMP["logs_campanas"]
        CAMP_LOG["id_campana<br/>id_cliente<br/>descripcion_campana<br/>publico_meta<br/>mensajes_poblacion<br/>generacion_metadata"]
    end
    
    subgraph MCP_DB["mcp_servers"]
        MCP_S["nombre_servidor<br/>tools: getContent<br/>generateCampaignContent<br/>configuracion<br/>metricas_uso"]
    end
    
    subgraph CRED["credenciales_cifradas"]
        CREDS["servicio_referencia<br/>tipo_credencial<br/>valor_cifrado<br/>algoritmo: X.509<br/>ultima_rotacion"]
    end
    
    IMG -.->|vector_id| PINECONE[Pinecone<br/>Vectores 1536d]
    IMG -.->|usa| SVC
    LOG -->|registra| SVC
    CAMP_LOG -->|referencia| IMG
    MCP_S -->|consulta| IMG
    SVC -.->|auth| CRED
    
    style IMAGES fill:#2c3e50,color:#ecf0f1
    style SERVICES fill:#34495e,color:#ecf0f1
    style LOGS fill:#2c3e50,color:#ecf0f1
    style CAMP fill:#34495e,color:#ecf0f1
    style MCP_DB fill:#2c3e50,color:#ecf0f1
    style CRED fill:#34495e,color:#ecf0f1
    style PINECONE fill:#7f8c8d,color:#ecf0f1
```

**Decisiones Clave de Diseño:**
- Vectorización: Pinecone (1536 dims) - embeddings en cloud
- Imágenes: URLs a S3/CloudFront - MongoDB solo metadata
- Auth: Canva API con OAuth2 POST (cumple requisito)
- Usuarios: Centralizados en PromptSales PostgreSQL (SSO)
- MCP Tools: getContent (búsqueda semántica) + generateCampaignContent (3 mensajes/población)

---

# 📁 Estructura del Proyecto

```
PromptSales/
├── README.md                          # Documentación principal del proyecto
├── .gitignore                         # Archivos ignorados por Git
├── docker-compose.yml                 # Configuración de contenedores Docker
├── kubernetes/                        # Archivos de despliegue en Kubernetes
│   ├── mongodb-deployment.yaml       # Configuración para desplegar MongoDB
│   ├── sqlserver-ads-deployment.yaml # Configuración para desplegar SQL Server (Ads)
│   ├── sqlserver-crm-deployment.yaml # Configuración para desplegar SQL Server (CRM)
│   ├── postgresql-deployment.yaml    # Configuración para desplegar PostgreSQL
│   └── redis-deployment.yaml          # Configuración para desplegar Redis
├── database/                          # Bases de datos del sistema
│   ├── mongodb/                      # Base de datos PromptContent
│   │   ├── design/                   # Diseño y esquemas de colecciones
│   │   ├── scripts/                  # Scripts de llenado y mantenimiento
│   │   └── mcp/                      # Servidores MCP para MongoDB
│   ├── sqlserver_ads/                # Base de datos PromptAds
│   │   ├── schema/                   # Esquema de tablas y relaciones
│   │   ├── procedures/               # Procedimientos almacenados
│   │   └── scripts/                  # Scripts de llenado (1000 campañas)
│   ├── sqlserver_crm/                # Base de datos PromptCRM
│   │   ├── schema/                   # Esquema de tablas y relaciones
│   │   ├── security/                 # Configuración de cifrado X.509
│   │   ├── procedures/               # Procedimientos almacenados
│   │   └── scripts/                  # Scripts de llenado (500k clientes)
│   ├── postgresql/                   # Base de datos PromptSales (centralizada)
│   │   ├── schema/                   # Esquema de tablas centralizadas
│   │   ├── etl/                      # Configuración de ETL y deltas
│   │   └── mcp/                      # Servidor MCP para consultas
│   └── redis/                        # Base de datos caché
│       ├── design/                   # Diseño de llaves y TTLs
│       └── config/                   # Configuración de Redis
├── etl/                              # Pipelines de extracción y transformación
│   ├── pentaho/                     # Configuración de Pentaho (herramienta visual)
│   └── documentation/                # Documentación del proceso ETL
├── mcp_servers/                      # Servidores de Model Context Protocol
│   ├── content_generator/           # MCP para generación de contenido
│   ├── ads_optimizer/                # MCP para optimización de anuncios
│   ├── crm_analyzer/                 # MCP para análisis de CRM
│   └── sales_dashboard/              # MCP para dashboard de ventas
├── documentation/                    # Documentación del proyecto
│   ├── AI_USAGE_LOG.md             # Bitácora obligatoria de uso de IA
│   ├── DESIGN_DECISIONS.md         # Decisiones de diseño tomadas
│   └── API_DOCUMENTATION.md        # Documentación de APIs externas
└── tests/                           # Pruebas del sistema
    ├── deadlock_tests/              # Pruebas de interbloqueo (3 niveles)
    ├── performance_tests/           # Pruebas de rendimiento e índices
    └── integration_tests/           # Pruebas de integración entre BDs
```

## 📝 Descripción de Carpetas Principales

### `/database`
Contiene los 5 motores de base de datos del ecosistema:
- **mongodb**: Gestión de contenido multimedia (100+ imágenes)
- **sqlserver_ads**: Campañas publicitarias (1000 registros)
- **sqlserver_crm**: Clientes y ventas (500k registros)
- **postgresql**: Portal centralizado y usuarios
- **redis**: Caché para optimización

### `/kubernetes`
Archivos YAML para orquestación de contenedores, permitiendo despliegue automático de toda la infraestructura.

### `/mcp_servers`
Implementación de servidores MCP (Model Context Protocol) para comunicación entre IA y bases de datos. Mínimo 2 tools por cada BD.

### `/etl`
Pipeline de datos que se ejecuta cada 11 minutos para sincronizar información entre las bases de datos usando herramientas visuales (NO código).

### `/tests`
Pruebas críticas requeridas:
- Deadlock en cascada (3 transacciones)
- Problemas de concurrencia (Dirty Read, Lost Update)
- Comparación de rendimiento con/sin índices

### `/documentation`
- **AI_USAGE_LOG.md**: OBLIGATORIO - registrar TODO uso de IA
- **DESIGN_DECISIONS.md**: Justificar decisiones técnicas
- **API_DOCUMENTATION.md**: Documentar integraciones externas

## ⚠️ Archivos Críticos

| Archivo | Propósito | Prioridad |
|---------|-----------|-----------|
| `AI_USAGE_LOG.md` | Registrar prompts y validaciones | 🔴 CRÍTICO |
| `docker-compose.yml` | Levantar ambiente local | 🟡 IMPORTANTE |
| `.env` | Credenciales y configuración | 🔴 CRÍTICO |
| Scripts de llenado | Generar datos de prueba | 🔴 CRÍTICO |

## ✅ Requisitos Críticos

### Datos
- 100+ imágenes con descripciones y hashtags
- 1000 campañas (picos: dic, ene, +1 mes)
- 500,000 clientes algorítmicos
- Coherencia entre BDs

### Técnicos
- [ ] SP transaccional con TVPs
- [ ] Link Server CRM ↔ Ads
- [ ] Cifrado X.509 (datos sensibles)
- [ ] MCP Server (2 tools/BD)
- [ ] ETL cada 11 min (solo deltas)

### Pruebas
- [ ] Deadlock cascada (3 transacciones)
- [ ] Dirty Read / Lost Update / Incorrect Summary
- [ ] Deadlock 2 PCs diferentes
- [ ] Execution Plan (antes/después índices)
- [ ] Monitoreo rendimiento

### Consultas SQL
**PromptAds**: EXCEPT, INTERSECT, MERGE, LTRIM, LOWERCASE, FLOOR, CEIL, UPDATE-SELECT  
**PromptCrm**: CTE, PARTITION, RANK, distancia geográfica  
**PromptSales**: Triggers, Cursores, COALESCE, CASE, JOINs, GRANT/REVOKE

## 🚀 Quick Start
```bash
git clone [repo] && cd PromptSales
kubectl apply -f kubernetes/
./scripts/load_all.sh
```

## 📅 Fechas
- **28 Oct**: Última revisión diseños
- **16-22 Nov**: Presentación final

## ⚠️ Reglas
1. NO portal web
2. ETL visual (no código)
3. Documentar TODA IA
4. Commits diarios
5. Datos coherentes

## 📝 Bitácora IA (OBLIGATORIO)
| Fecha | Nombre | Prompt | Validación |
|-------|--------|--------|------------|
| - | - | - | - |

---
v1.0 | 2025-10-22
