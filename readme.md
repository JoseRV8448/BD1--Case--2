# 🚀 PromptSales - Caso #2 (42%)

## 📝 Descripción
Sistema end-to-end de marketing y ventas con IA. 4 bases de datos especializadas que automatizan desde creación de contenido hasta cierre de ventas. Cada subsistema puede operar independiente pero se integran via MCP servers y ETL.

## 👥 Equipo
| Miembro | BD Asignada | Discord | GitHub | Estado |
|---------|-------------|---------|--------|---------|
| [Nombre 1] | Redis + MongoDB | @user1 | @git1 | Revision⏳ |
| [Nombre 2] | SQL Server (Ads) | @user2 | @git2 | Revision⏳ |
| [Nombre 3] | SQL Server (CRM) | @user3 | @git3 | Revision⏳ |
| [Nombre 4] | PostgreSQL + ETL | @user4 | @git4 | Revision⏳ |

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
**📁 Archivo de diseño:** [redis_design.txt](PromptSales/database/redis/design/redis_design.txt)
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
**📁 Archivo de diseño:** [mongodb_promptcontent_design.js](PromptSales/database/mongodb/design/mongodb_promptcontent_design.js)
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
## PromptSales PostgreSQL - Diagrama ER Completo

### Vista General de Modulos

```mermaid
graph TB
    subgraph AUTH["AUTENTICACION Y USUARIOS"]
        U[Users]
        US[UserSession]
        UP[UserPermissions]
    end
    
    subgraph SUBS["SUSCRIPCIONES Y PLANES"]
        P[Plans]
        PF[PlanFeatures]
        S[Subscriptions]
        SU[SubscriptionUsage]
    end
    
    subgraph PROV["PROVEEDORES Y APIs"]
        PT[ProviderTypes]
        PR[Providers]
        PA[ProviderApis]
        PC[ProviderCredentials]
    end
    
    subgraph CAMP["CAMPANAS CORE"]
        C[Campaigns]
        CO[CampaignObjectives]
        CS[CampaignSchedule]
        CA[CampaignApprovals]
    end
    
    subgraph TARGET["TARGETING Y SEGMENTACION"]
        T[Targets]
        TC[TargetConfiguration]
        POP[PopulationFeatures]
        POPV[PopulationFeatureValues]
    end
    
    subgraph SUMMARY["DATOS SUMARIZADOS ETL"]
        CONT[ContentSummary]
        ADS[AdsSummary]
        CRM[CrmSummary]
        PERF[CampaignPerformance]
    end
    
    subgraph TRANS["TRANSACCIONES Y PAGOS"]
        PM[PaymentMethods]
        TR[Transactions]
        CBT[CampaignBudgetTransactions]
    end
    
    subgraph LOGS["ETL Y AUDITORIA"]
        EW[EtlWatermarks]
        EL[EtlExecutionLogs]
        SL[SystemLogs]
        AL[ApiCallLogs]
    end
    
    U --> US
    U --> UP
    U --> S
    U --> C
    U --> PM
    U --> TR
    U --> SL
    U --> CA
    
    P --> PF
    P --> S
    S --> SU
    PF --> SU
    S --> TR
    
    PT --> PR
    PR --> PA
    PR --> PC
    PR --> PM
    PR --> AL
    
    C --> CO
    C --> CS
    C --> CA
    C --> T
    C --> CBT
    C --> TR
    C --> CONT
    C --> ADS
    C --> CRM
    C --> PERF
    
    T --> TC
    POP --> TC
    POPV --> TC
    POP --> POPV
    
    PM --> TR
    C --> CBT
    
    CONT --> PERF
    ADS --> PERF
    CRM --> PERF
    
    style AUTH fill:#3498db,color:#fff
    style SUBS fill:#9b59b6,color:#fff
    style PROV fill:#e74c3c,color:#fff
    style CAMP fill:#2ecc71,color:#fff
    style TARGET fill:#f39c12,color:#fff
    style SUMMARY fill:#1abc9c,color:#fff
    style TRANS fill:#34495e,color:#fff
    style LOGS fill:#95a5a6,color:#fff
```

---

### Modulo 1: Autenticacion y Usuarios

```mermaid
erDiagram
    Users ||--o{ UserSession : "tiene"
    Users ||--o{ UserPermissions : "tiene"
    Users ||--o{ Subscriptions : "contrata"
    Users ||--o{ Campaigns : "crea"
    Users ||--o{ PaymentMethods : "registra"
    Users ||--o{ Transactions : "realiza"
    Users ||--o{ SystemLogs : "genera"
    Users ||--o{ CampaignApprovals : "solicita"
    Users ||--o{ CampaignApprovals : "aprueba"
    Users ||--o{ CampaignSchedule : "ejecuta"
    Users ||--o{ CampaignBudgetTransactions : "crea"
    
    Users {
        uuid user_id PK
        varchar email UK "NOT NULL"
        varchar name "NOT NULL"
        varchar phone
        text password_hash "NOT NULL"
        varchar user_type "customer|admin|marketer|sales_agent"
        varchar timezone "DEFAULT America/Costa_Rica"
        boolean is_active "DEFAULT true"
        timestamp created_at "DEFAULT NOW"
        timestamp updated_at "DEFAULT NOW"
    }
    
    UserSession {
        uuid session_id PK
        uuid user_id FK "NOT NULL"
        text refresh_token "NOT NULL"
        text access_token "NOT NULL"
        varchar oauth_provider "Google|Facebook|LinkedIn NULL"
        boolean mfa_enabled "DEFAULT false"
        timestamp login_at "DEFAULT NOW"
        timestamp expires_at "NOT NULL"
        inet ip_address
        text user_agent
        varchar device_type
        varchar location_country
        varchar location_city
    }
    
    UserPermissions {
        uuid permission_id PK
        uuid user_id FK "NOT NULL"
        varchar subsystem "content|ads|crm|sales NOT NULL"
        varchar role "read|write|admin NOT NULL"
        timestamp granted_at "DEFAULT NOW"
        uuid granted_by FK "Users.user_id"
        timestamp revoked_at
    }
```

---

### Modulo 2: Suscripciones y Planes

```mermaid
erDiagram
    Plans ||--o{ PlanFeatures : "incluye"
    Plans ||--o{ Subscriptions : "define"
    Subscriptions ||--o{ SubscriptionUsage : "trackea"
    PlanFeatures ||--o{ SubscriptionUsage : "limita"
    Users ||--o{ Subscriptions : "contrata"
    Subscriptions ||--o{ Transactions : "genera"
    
    Plans {
        uuid plan_id PK
        varchar name UK "NOT NULL"
        text description
        varchar subsystem "content|ads|crm|all NOT NULL"
        varchar billing_cycle "monthly|annual NOT NULL"
        decimal price "NOT NULL CHECK >= 0"
        varchar currency "DEFAULT USD"
        timestamp created_at "DEFAULT NOW"
        boolean is_active "DEFAULT true"
        integer trial_days "DEFAULT 0"
        integer max_users "NULL unlimited"
    }
    
    PlanFeatures {
        uuid feature_id PK
        uuid plan_id FK "NOT NULL"
        varchar feature_name "api_calls|campaigns|storage_gb NOT NULL"
        varchar feature_value "NOT NULL"
        varchar feature_type "limit|boolean|quota NOT NULL"
        varchar unit "calls|GB|campaigns"
        integer sort_order "DEFAULT 0"
    }
    
    Subscriptions {
        uuid subscription_id PK
        uuid user_id FK "NOT NULL"
        uuid plan_id FK "NOT NULL"
        varchar status "active|cancelled|expired|trial NOT NULL"
        date start_date "NOT NULL"
        date end_date "NOT NULL"
        boolean auto_renew "DEFAULT true"
        timestamp cancelled_at
        varchar cancellation_reason
        decimal amount_paid
        timestamp created_at "DEFAULT NOW"
    }
    
    SubscriptionUsage {
        uuid usage_id PK
        uuid subscription_id FK "NOT NULL"
        uuid feature_id FK "NOT NULL"
        integer current_usage "DEFAULT 0"
        integer usage_limit "NOT NULL"
        date last_reset "DEFAULT CURRENT_DATE"
        timestamp updated_at "DEFAULT NOW"
    }
```

---

### Modulo 3: Proveedores y APIs Externas

```mermaid
erDiagram
    ProviderTypes ||--o{ Providers : "categoriza"
    Providers ||--o{ ProviderApis : "expone"
    Providers ||--o{ ProviderCredentials : "requiere"
    Providers ||--o{ PaymentMethods : "procesa"
    Providers ||--o{ ApiCallLogs : "registra"
    Users ||--o{ ApiCallLogs : "ejecuta"
    
    ProviderTypes {
        uuid provider_type_id PK
        varchar type_name UK "payment|ai|design|analytics|crm NOT NULL"
        text description
        varchar icon_url
    }
    
    Providers {
        uuid provider_id PK
        varchar name UK "Stripe|OpenAI|Canva|Meta NOT NULL"
        uuid provider_type_id FK "NOT NULL"
        text description
        boolean is_active "DEFAULT true"
        varchar website_url
        varchar documentation_url
        varchar support_email
        timestamp created_at "DEFAULT NOW"
    }
    
    ProviderApis {
        uuid api_id PK
        uuid provider_id FK "NOT NULL"
        varchar endpoint_name "NOT NULL"
        text endpoint_url "NOT NULL"
        varchar http_method "GET|POST|PUT|DELETE NOT NULL"
        varchar auth_method "oauth|api_key|jwt|basic NOT NULL"
        jsonb config_json "NOT NULL"
        integer rate_limit_per_minute "DEFAULT 60"
        integer timeout_ms "DEFAULT 30000"
        boolean requires_authentication "DEFAULT true"
        timestamp created_at "DEFAULT NOW"
    }
    
    ProviderCredentials {
        uuid credential_id PK
        uuid provider_id FK "NOT NULL"
        uuid user_id FK "NULL global credentials"
        text api_key_encrypted "NOT NULL"
        text secret_encrypted
        text oauth_token_encrypted
        timestamp expires_at
        timestamp last_used_at
        boolean is_active "DEFAULT true"
        timestamp created_at "DEFAULT NOW"
    }
    
    ApiCallLogs {
        uuid call_id PK
        uuid provider_id FK "NOT NULL"
        uuid user_id FK
        varchar endpoint "NOT NULL"
        varchar request_method "NOT NULL"
        text request_body
        integer response_status "NOT NULL"
        text response_body
        integer duration_ms "NOT NULL"
        boolean from_cache "DEFAULT false"
        timestamp called_at "DEFAULT NOW"
    }
```

---

### Modulo 4: Campanas Core Business Logic

```mermaid
erDiagram
    Campaigns ||--o{ CampaignObjectives : "persigue"
    Campaigns ||--o{ CampaignSchedule : "programa"
    Campaigns ||--o{ Targets : "define"
    Campaigns ||--o{ CampaignBudgetTransactions : "gasta"
    Campaigns ||--o{ ContentSummary : "consume"
    Campaigns ||--o{ AdsSummary : "publica"
    Campaigns ||--o{ CrmSummary : "genera"
    Campaigns ||--o{ CampaignApprovals : "requiere"
    Campaigns ||--o{ Transactions : "financia"
    Users ||--o{ Campaigns : "crea"
    Users ||--o{ CampaignApprovals : "solicita_aprueba"
    Users ||--o{ CampaignSchedule : "asigna"
    Users ||--o{ CampaignBudgetTransactions : "registra"
    
    Campaigns {
        uuid campaign_id PK
        uuid user_id FK "NOT NULL"
        varchar name "NOT NULL"
        text description
        varchar status "draft|pending|active|paused|completed|cancelled NOT NULL"
        decimal budget_total "NOT NULL CHECK >= 0"
        decimal budget_spent "DEFAULT 0"
        decimal budget_available "GENERATED budget_total - budget_spent"
        date start_date "NOT NULL"
        date end_date "NOT NULL CHECK >= start_date"
        timestamp created_at "DEFAULT NOW"
        timestamp updated_at "DEFAULT NOW"
        uuid approved_by FK "Users.user_id"
        timestamp approved_at
        varchar currency "DEFAULT USD"
        varchar industry
        jsonb metadata "DEFAULT {}"
    }
    
    CampaignObjectives {
        uuid objective_id PK
        uuid campaign_id FK "NOT NULL"
        varchar objective_type "awareness|lead_gen|conversion|engagement|sales NOT NULL"
        varchar target_metric "impressions|clicks|leads|revenue NOT NULL"
        decimal target_value "NOT NULL CHECK > 0"
        decimal current_value "DEFAULT 0"
        varchar unit "count|usd|percentage NOT NULL"
        timestamp created_at "DEFAULT NOW"
    }
    
    CampaignSchedule {
        uuid schedule_id PK
        uuid campaign_id FK "NOT NULL"
        text task_description "NOT NULL"
        varchar task_type "content_review|approval|publish|report NOT NULL"
        timestamp scheduled_at "NOT NULL"
        varchar status "pending|in_progress|completed|failed|cancelled NOT NULL"
        boolean reminder_sent "DEFAULT false"
        timestamp reminder_sent_at
        timestamp completed_at
        uuid assigned_to FK "Users.user_id"
        text notes
    }
    
    CampaignApprovals {
        uuid approval_id PK
        uuid campaign_id FK "NOT NULL"
        uuid requested_by FK "Users.user_id NOT NULL"
        uuid approved_by FK "Users.user_id"
        varchar approval_type "budget|content|schedule|launch NOT NULL"
        varchar status "pending|approved|rejected NOT NULL"
        text comments
        timestamp requested_at "DEFAULT NOW"
        timestamp resolved_at
    }
    
    CampaignBudgetTransactions {
        uuid budget_tx_id PK
        uuid campaign_id FK "NOT NULL"
        decimal amount "NOT NULL"
        varchar transaction_type "deposit|spent|refund|adjustment NOT NULL"
        text description "NOT NULL"
        uuid created_by FK "Users.user_id NOT NULL"
        timestamp created_at "DEFAULT NOW"
        decimal balance_after "NOT NULL"
        varchar source_system "ads|content|crm"
        varchar reference_id
    }
```

---

### Modulo 5: Targeting y Segmentacion

```mermaid
erDiagram
    Targets ||--o{ TargetConfiguration : "configura"
    PopulationFeatures ||--o{ PopulationFeatureValues : "contiene"
    PopulationFeatures ||--o{ TargetConfiguration : "filtra_por"
    PopulationFeatureValues ||--o{ TargetConfiguration : "especifica"
    Campaigns ||--o{ Targets : "define"
    
    Targets {
        uuid target_id PK
        uuid campaign_id FK "NOT NULL"
        varchar name "NOT NULL"
        text description
        boolean is_enabled "DEFAULT true"
        integer estimated_reach
        timestamp created_at "DEFAULT NOW"
        timestamp updated_at "DEFAULT NOW"
    }
    
    TargetConfiguration {
        uuid config_id PK
        uuid target_id FK "NOT NULL"
        uuid feature_id FK "PopulationFeatures NOT NULL"
        uuid feature_value_id FK "PopulationFeatureValues NOT NULL"
        timestamp created_at "DEFAULT NOW"
    }
    
    PopulationFeatures {
        uuid feature_id PK
        varchar feature_name UK "country|city|age|gender|profession|education|workplace|interests NOT NULL"
        varchar feature_category "demographic|geographic|psychographic|behavioral NOT NULL"
        varchar data_type "string|integer|date|boolean NOT NULL"
        text description
        boolean is_active "DEFAULT true"
        integer sort_order "DEFAULT 0"
    }
    
    PopulationFeatureValues {
        uuid value_id PK
        uuid feature_id FK "NOT NULL"
        varchar value_type "exact|range|list NOT NULL"
        numeric min_value "for ranges"
        numeric max_value "for ranges"
        varchar exact_value "for exact matches"
        text list_values "JSON array for lists"
        varchar display_name "NOT NULL"
        timestamp created_at "DEFAULT NOW"
    }
```

---

### Modulo 6: Datos Sumarizados desde ETL

```mermaid
erDiagram
    Campaigns ||--o{ ContentSummary : "consume"
    Campaigns ||--o{ AdsSummary : "publica"
    Campaigns ||--o{ CrmSummary : "genera"
    Campaigns ||--o{ CampaignPerformance : "consolida"
    ContentSummary ||--o{ CampaignPerformance : "agrega"
    AdsSummary ||--o{ CampaignPerformance : "agrega"
    CrmSummary ||--o{ CampaignPerformance : "agrega"
    
    ContentSummary {
        uuid summary_id PK
        uuid campaign_id FK "NOT NULL"
        date summary_date "NOT NULL"
        varchar content_type "image|video|text|audio NOT NULL"
        integer total_pieces "DEFAULT 0"
        integer approved_pieces "DEFAULT 0"
        integer rejected_pieces "DEFAULT 0"
        integer pending_review "DEFAULT 0"
        jsonb metadata "DEFAULT {}"
        timestamp updated_at "DEFAULT NOW"
        timestamp etl_processed_at "DEFAULT NOW"
    }
    
    AdsSummary {
        uuid summary_id PK
        uuid campaign_id FK "NOT NULL"
        date summary_date "NOT NULL"
        varchar channel "facebook|instagram|youtube|tiktok|google|tv|radio|newspaper|influencer NOT NULL"
        bigint impressions "DEFAULT 0"
        bigint clicks "DEFAULT 0"
        decimal ctr "GENERATED clicks / NULLIF impressions 0 * 100"
        decimal spent "DEFAULT 0 CHECK >= 0"
        bigint reach "DEFAULT 0"
        bigint engagement "DEFAULT 0"
        decimal engagement_rate "GENERATED engagement / NULLIF reach 0 * 100"
        integer conversions "DEFAULT 0"
        decimal cost_per_click "GENERATED spent / NULLIF clicks 0"
        decimal cost_per_conversion "GENERATED spent / NULLIF conversions 0"
        timestamp updated_at "DEFAULT NOW"
        timestamp etl_processed_at "DEFAULT NOW"
    }
    
    CrmSummary {
        uuid summary_id PK
        uuid campaign_id FK "NOT NULL"
        date summary_date "NOT NULL"
        integer leads_total "DEFAULT 0"
        integer leads_qualified "DEFAULT 0"
        integer prospects_total "DEFAULT 0"
        integer customers_converted "DEFAULT 0"
        decimal revenue_generated "DEFAULT 0 CHECK >= 0"
        decimal conversion_rate "GENERATED customers_converted / NULLIF leads_total 0 * 100"
        decimal avg_deal_size "GENERATED revenue_generated / NULLIF customers_converted 0"
        integer active_funnels "DEFAULT 0"
        timestamp updated_at "DEFAULT NOW"
        timestamp etl_processed_at "DEFAULT NOW"
    }
    
    CampaignPerformance {
        uuid campaign_id PK
        varchar campaign_name "NOT NULL"
        varchar campaign_status "NOT NULL"
        decimal budget_total "NOT NULL"
        decimal budget_spent "NOT NULL"
        decimal budget_utilization "percentage"
        bigint total_impressions
        bigint total_clicks
        decimal avg_ctr
        integer total_leads
        integer total_customers
        decimal total_revenue
        decimal roi "percentage"
        decimal cost_per_lead
        decimal cost_per_acquisition
        date start_date
        date end_date
        timestamp last_updated "DEFAULT NOW"
    }
```

---

### Modulo 7: Transacciones y Pagos

```mermaid
erDiagram
    PaymentMethods ||--o{ Transactions : "procesa"
    Users ||--o{ PaymentMethods : "registra"
    Users ||--o{ Transactions : "realiza"
    Subscriptions ||--o{ Transactions : "genera_pago"
    Campaigns ||--o{ Transactions : "recarga_presupuesto"
    Providers ||--o{ PaymentMethods : "procesa_via"
    
    PaymentMethods {
        uuid payment_method_id PK
        uuid user_id FK "NOT NULL"
        uuid provider_id FK "Providers NOT NULL"
        varchar method_type "credit_card|debit_card|bank_account|paypal|stripe NOT NULL"
        varchar card_brand "Visa|Mastercard|Amex"
        varchar last_four
        varchar cardholder_name
        date expires_at
        boolean is_default "DEFAULT false"
        boolean is_active "DEFAULT true"
        text billing_address
        varchar postal_code
        varchar country
        timestamp created_at "DEFAULT NOW"
    }
    
    Transactions {
        uuid transaction_id PK
        uuid user_id FK "Users NOT NULL"
        uuid subscription_id FK "Subscriptions"
        uuid campaign_id FK "Campaigns"
        decimal amount "NOT NULL"
        varchar currency "DEFAULT USD"
        varchar transaction_type "subscription|campaign_budget|refund|adjustment NOT NULL"
        varchar status "pending|completed|failed|refunded NOT NULL"
        uuid payment_method_id FK "PaymentMethods"
        timestamp processed_at
        varchar provider_transaction_id
        text failure_reason
        jsonb metadata "DEFAULT {}"
        timestamp created_at "DEFAULT NOW"
    }
```

---

### Modulo 8: ETL Control y Auditoria

```mermaid
erDiagram
    EtlWatermarks ||--o{ EtlExecutionLogs : "controla"
    Users ||--o{ SystemLogs : "genera"
    
    EtlWatermarks {
        uuid watermark_id PK
        varchar source_system UK "content|ads|crm NOT NULL"
        timestamp last_updated_at "NOT NULL"
        varchar last_processed_id
        timestamp next_run_at "NOT NULL"
        varchar etl_status "idle|running|failed NOT NULL"
        integer records_processed "DEFAULT 0"
        text error_message
        timestamp created_at "DEFAULT NOW"
    }
    
    EtlExecutionLogs {
        uuid execution_id PK
        varchar etl_name "content_summary|ads_summary|crm_summary NOT NULL"
        varchar status "running|success|failed|partial NOT NULL"
        integer records_processed "DEFAULT 0"
        integer records_failed "DEFAULT 0"
        timestamp started_at "DEFAULT NOW"
        timestamp completed_at
        text error_message
        jsonb execution_metadata "DEFAULT {}"
    }
    
    SystemLogs {
        uuid log_id PK
        uuid user_id FK "Users"
        varchar event_type "login|logout|campaign_create|approval|budget_change|permission_grant NOT NULL"
        varchar severity "info|warning|error|critical NOT NULL"
        text description "NOT NULL"
        inet ip_address
        jsonb metadata_json "DEFAULT {}"
        timestamp created_at "DEFAULT NOW"
    }
```

---

### Diagrama ER Completo Integrado

```mermaid
erDiagram
    Users ||--o{ UserSession : ""
    Users ||--o{ UserPermissions : ""
    Users ||--o{ Subscriptions : ""
    Users ||--o{ Campaigns : ""
    Users ||--o{ PaymentMethods : ""
    Users ||--o{ Transactions : ""
    Users ||--o{ SystemLogs : ""
    Users ||--o{ CampaignApprovals : "solicita"
    Users ||--o{ CampaignApprovals : "aprueba"
    
    Plans ||--o{ PlanFeatures : ""
    Plans ||--o{ Subscriptions : ""
    Subscriptions ||--o{ SubscriptionUsage : ""
    PlanFeatures ||--o{ SubscriptionUsage : ""
    Subscriptions ||--o{ Transactions : ""
    
    ProviderTypes ||--o{ Providers : ""
    Providers ||--o{ ProviderApis : ""
    Providers ||--o{ ProviderCredentials : ""
    Providers ||--o{ PaymentMethods : ""
    Providers ||--o{ ApiCallLogs : ""
    
    Campaigns ||--o{ CampaignObjectives : ""
    Campaigns ||--o{ CampaignSchedule : ""
    Campaigns ||--o{ Targets : ""
    Campaigns ||--o{ CampaignBudgetTransactions : ""
    Campaigns ||--o{ ContentSummary : ""
    Campaigns ||--o{ AdsSummary : ""
    Campaigns ||--o{ CrmSummary : ""
    Campaigns ||--o{ CampaignApprovals : ""
    Campaigns ||--o{ Transactions : ""
    Campaigns ||--o{ CampaignPerformance : ""
    
    Targets ||--o{ TargetConfiguration : ""
    PopulationFeatures ||--o{ PopulationFeatureValues : ""
    PopulationFeatures ||--o{ TargetConfiguration : ""
    PopulationFeatureValues ||--o{ TargetConfiguration : ""
    
    PaymentMethods ||--o{ Transactions : ""
    
    EtlWatermarks ||--o{ EtlExecutionLogs : ""
    
    ContentSummary ||--o{ CampaignPerformance : ""
    AdsSummary ||--o{ CampaignPerformance : ""
    CrmSummary ||--o{ CampaignPerformance : ""
    
    Users {
        uuid user_id PK
        varchar email UK
        varchar name
        varchar phone
        text password_hash
        varchar user_type
        varchar timezone
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    UserSession {
        uuid session_id PK
        uuid user_id FK
        text refresh_token
        text access_token
        varchar oauth_provider
        boolean mfa_enabled
        timestamp login_at
        timestamp expires_at
        inet ip_address
        text user_agent
    }
    
    UserPermissions {
        uuid permission_id PK
        uuid user_id FK
        varchar subsystem
        varchar role
        timestamp granted_at
        uuid granted_by FK
        timestamp revoked_at
    }
    
    Plans {
        uuid plan_id PK
        varchar name UK
        text description
        varchar subsystem
        varchar billing_cycle
        decimal price
        varchar currency
        timestamp created_at
        boolean is_active
        integer trial_days
        integer max_users
    }
    
    PlanFeatures {
        uuid feature_id PK
        uuid plan_id FK
        varchar feature_name
        varchar feature_value
        varchar feature_type
        varchar unit
        integer sort_order
    }
    
    Subscriptions {
        uuid subscription_id PK
        uuid user_id FK
        uuid plan_id FK
        varchar status
        date start_date
        date end_date
        boolean auto_renew
        timestamp cancelled_at
        varchar cancellation_reason
        decimal amount_paid
        timestamp created_at
    }
    
    SubscriptionUsage {
        uuid usage_id PK
        uuid subscription_id FK
        uuid feature_id FK
        integer current_usage
        integer usage_limit
        date last_reset
        timestamp updated_at
    }
    
    ProviderTypes {
        uuid provider_type_id PK
        varchar type_name UK
        text description
        varchar icon_url
    }
    
    Providers {
        uuid provider_id PK
        varchar name UK
        uuid provider_type_id FK
        text description
        boolean is_active
        varchar website_url
        timestamp created_at
    }
    
    ProviderApis {
        uuid api_id PK
        uuid provider_id FK
        varchar endpoint_name
        text endpoint_url
        varchar http_method
        varchar auth_method
        jsonb config_json
        integer rate_limit_per_minute
        integer timeout_ms
        timestamp created_at
    }
    
    ProviderCredentials {
        uuid credential_id PK
        uuid provider_id FK
        uuid user_id FK
        text api_key_encrypted
        text secret_encrypted
        timestamp expires_at
        timestamp last_used_at
        boolean is_active
        timestamp created_at
    }
    
    Campaigns {
        uuid campaign_id PK
        uuid user_id FK
        varchar name
        text description
        varchar status
        decimal budget_total
        decimal budget_spent
        decimal budget_available
        date start_date
        date end_date
        timestamp created_at
        timestamp updated_at
        uuid approved_by FK
        timestamp approved_at
        varchar currency
        varchar industry
        jsonb metadata
    }
    
    CampaignObjectives {
        uuid objective_id PK
        uuid campaign_id FK
        varchar objective_type
        varchar target_metric
        decimal target_value
        decimal current_value
        varchar unit
        timestamp created_at
    }
    
    CampaignSchedule {
        uuid schedule_id PK
        uuid campaign_id FK
        text task_description
        varchar task_type
        timestamp scheduled_at
        varchar status
        boolean reminder_sent
        timestamp completed_at
        uuid assigned_to FK
    }
    
    CampaignApprovals {
        uuid approval_id PK
        uuid campaign_id FK
        uuid requested_by FK
        uuid approved_by FK
        varchar approval_type
        varchar status
        text comments
        timestamp requested_at
        timestamp resolved_at
    }
    
    CampaignBudgetTransactions {
        uuid budget_tx_id PK
        uuid campaign_id FK
        decimal amount
        varchar transaction_type
        text description
        uuid created_by FK
        timestamp created_at
        decimal balance_after
        varchar source_system
        varchar reference_id
    }
    
    Targets {
        uuid target_id PK
        uuid campaign_id FK
        varchar name
        text description
        boolean is_enabled
        integer estimated_reach
        timestamp created_at
        timestamp updated_at
    }
    
    TargetConfiguration {
        uuid config_id PK
        uuid target_id FK
        uuid feature_id FK
        uuid feature_value_id FK
        timestamp created_at
    }
    
    PopulationFeatures {
        uuid feature_id PK
        varchar feature_name UK
        varchar feature_category
        varchar data_type
        text description
        boolean is_active
        integer sort_order
    }
    
    PopulationFeatureValues {
        uuid value_id PK
        uuid feature_id FK
        varchar value_type
        numeric min_value
        numeric max_value
        varchar exact_value
        text list_values
        varchar display_name
        timestamp created_at
    }
    
    ContentSummary {
        uuid summary_id PK
        uuid campaign_id FK
        date summary_date
        varchar content_type
        integer total_pieces
        integer approved_pieces
        integer rejected_pieces
        integer pending_review
        timestamp etl_processed_at
    }
    
    AdsSummary {
        uuid summary_id PK
        uuid campaign_id FK
        date summary_date
        varchar channel
        bigint impressions
        bigint clicks
        decimal ctr
        decimal spent
        bigint reach
        bigint engagement
        integer conversions
        timestamp etl_processed_at
    }
    
    CrmSummary {
        uuid summary_id PK
        uuid campaign_id FK
        date summary_date
        integer leads_total
        integer leads_qualified
        integer prospects_total
        integer customers_converted
        decimal revenue_generated
        decimal conversion_rate
        timestamp etl_processed_at
    }
    
    CampaignPerformance {
        uuid campaign_id PK
        varchar campaign_name
        varchar campaign_status
        decimal budget_total
        decimal budget_spent
        bigint total_impressions
        bigint total_clicks
        decimal avg_ctr
        integer total_leads
        integer total_customers
        decimal total_revenue
        decimal roi
        timestamp last_updated
    }
    
    PaymentMethods {
        uuid payment_method_id PK
        uuid user_id FK
        uuid provider_id FK
        varchar method_type
        varchar card_brand
        varchar last_four
        date expires_at
        boolean is_default
        boolean is_active
        timestamp created_at
    }
    
    Transactions {
        uuid transaction_id PK
        uuid user_id FK
        uuid subscription_id FK
        uuid campaign_id FK
        decimal amount
        varchar currency
        varchar transaction_type
        varchar status
        uuid payment_method_id FK
        timestamp processed_at
        varchar provider_transaction_id
        timestamp created_at
    }
    
    EtlWatermarks {
        uuid watermark_id PK
        varchar source_system UK
        timestamp last_updated_at
        varchar last_processed_id
        timestamp next_run_at
        varchar etl_status
        integer records_processed
        text error_message
    }
    
    EtlExecutionLogs {
        uuid execution_id PK
        varchar etl_name
        varchar status
        integer records_processed
        integer records_failed
        timestamp started_at
        timestamp completed_at
        text error_message
    }
    
    SystemLogs {
        uuid log_id PK
        uuid user_id FK
        varchar event_type
        varchar severity
        text description
        inet ip_address
        timestamp created_at
    }
    
    ApiCallLogs {
        uuid call_id PK
        uuid provider_id FK
        uuid user_id FK
        varchar endpoint
        varchar request_method
        integer response_status
        integer duration_ms
        boolean from_cache
        timestamp called_at
    }
```


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
| 2025-10-27 | Lee-Sang-cheol | Diseñar modelo ER completo PromptSales (PostgreSQL) con 8 módulos: Auth SSO, Suscripciones, Proveedores, Campañas, Targeting, Summaries ETL, Transacciones, Logs | Revisé contra requisitos Caso #2, confirmé cardinalidades, verifiqué tipos de datos PostgreSQL, comparé con apuntes clase |
| 2025-10-29 | Lee-Sang-cheol | Crear scripts SQL: triggers, cursors, deadlock 3-way, queries con COALESCE/CASE/JOINs, metadata, monitoring, GRANT/REVOKE | Probé sintaxis en PostgreSQL 14 local, verifiqué lógica de deadlock circular, confirmé que queries cumplen requisitos |

---
v6.0 | 2025-10-29
