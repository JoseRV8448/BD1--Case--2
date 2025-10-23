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

## 📁 Estructura
```
PromptSales/
├── databases/      # Esquemas y scripts por BD
├── kubernetes/     # Deployment YAML
├── mcp-servers/    # 2 tools mínimo por BD
├── etl/           # Visual (Pentaho/NiFi)
├── scripts/       # Llenado algorítmico
├── docs/          # AI_LOG.md obligatorio
└── tests/         # Deadlocks, performance
```

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