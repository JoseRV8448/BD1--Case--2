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
```
┌──────────────[PromptSales - PostgreSQL]──────────────┐
│                    Portal Centralizado                 │
└────────────────────┬──ETL 11min──┬────────────────────┘
                     ↓              ↓
    [PromptContent]  [PromptAds]  [PromptCrm]  [Redis]
      MongoDB       SQL Server   SQL Server    Cache
```

## 🗂️ Bases de Datos

| BD | Motor | Requisitos | Estado |
|----|-------|------------|---------|
| **Redis** | Cache | TTL, Rate limiting | ✅ |
| **PromptContent** | MongoDB | 100 imágenes + vectorización Pinecone | ✅ |
| **PromptAds** | SQL Server | 1000 campañas (30% activas) | ⏳ |
| **PromptCrm** | SQL Server | 500K clientes + X.509 + LinkServer | ⏳ |
| **PromptSales** | PostgreSQL | SSO + ETL deltas | ⏳ |

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