# PromptContent - MongoDB

> AI content management with vector search & MCP server

## 📊 Database Design

**6 Collections** :
1. `contenido_generado` - 100+ multimedia con embeddings + campana_id
2. `log_llamadas_api` - External API calls (body completo)
3. `configuracion_mcp` - MCP servers/clients config (K8s deployment)
4. `bitacora_solicitudes` - MCP tool request tracking (NEW)
5. `integraciones_api` - 7 AI providers (OpenAI, Anthropic, etc)
6. `campana_mensajes` - Generated campaign messages

**Correcciones principales:**
- Campo "tipo" → `metadata.formato` (embedded document)
- MCP config completo (deployment, auth, params)
- Vinculación campañas en contenido_generado

---

## 🚀 Quick Start

```bash
# 1. Start MongoDB
docker run -d --name mongodb -p 27017:27017 mongo:7.0

# 2. Configure .env in scripts/ and mcp/
MONGODB_URI=mongodb://localhost:27017
OPENAI_API_KEY=sk-proj-xxx
PINECONE_API_KEY=xxx
PINECONE_INDEX=promptcontent-images

# 3. Generate data
cd scripts
node fill_data.js

# 4. Index vectors (Pinecone)
cd ../mcp
node index_vectors.js

# 5. Test API
node test_external_api.js

# 6. Start MCP Server
node mcp_server.js
```

---

## 📂 Structure

```
mongodb/
├── design/              # Schema corregido (6 collections)
│   └── mongodb_promptcontent_CORREGIDO.js
├── scripts/             # Data generation
│   ├── fill_data.js     # 100 docs + OpenAI embeddings
│   └── package.json
├── mcp/                 # MCP Server
│   ├── mcp_server.js    # 2 tools (getContent, generateCampaignMessages)
│   ├── index_vectors.js # Pinecone upload
│   └── test_external_api.js
└── evidence/            # Screenshots + README
```

---

## 🎯 Entregable 2 Status

| Requirement | Status |
|------------|--------|
| 100+ images algorítmicos | ✅ |
| Vector indexing (Pinecone) | ✅ código |
| External API POST | ✅ 429 verified |
| MCP tool: getContent | ✅ |
| MCP tool: generateCampaignMessages | ✅ |

**Nota:** OpenAI quota exceeded (429) - arquitectura completa, requiere billing.

---

## 🔧 MCP Tools

**1. getContent**
- Búsqueda semántica con Pinecone
- Input: descripción, tipo, límite
- Output: contenido + score

**2. generateCampaignMessages**  
- Genera 3 mensajes por segmento
- Input: descripción_campaña, público_meta
- Output: mensajes personalizados + bitácora

---

## 📸 Evidence

Ver carpeta `evidence/` para screenshots y detalles.