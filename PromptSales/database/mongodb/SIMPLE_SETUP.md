# Setup Rápido - Entregable #2



## ⚙️ Instalación (5 pasos):

### 1. MongoDB - Agregar collection
```bash
mongosh
use PromptContent
load("scripts/fill_data.js")
load("scripts/campana_mensajes.js")
exit
```

### 2. Crear cuenta Pinecone
```
https://www.pinecone.io/
→ Sign up (gratis)
→ Create Index:
   - Name: promptcontent-images
   - Dimensions: 1536
   - Metric: cosine
→ Copy API Key
```

### 3. Configurar .env
```bash
cd database/mongodb/mcp
notepad .env
```

Editar:
```
OPENAI_API_KEY=sk-proj-TU_KEY_AQUI
PINECONE_API_KEY=TU_KEY_AQUI
```

### 4. Instalar e indexar
```bash
npm install
node index_vectors.js
```

### 5. Iniciar MCP Server
```bash
npm start
```

Debe mostrar: `🚀 MCP Server listo`

---

## Verificar

### Test Tool 1:
```javascript
// Crear test.js:
const testInput = {
  method: 'tools/call',
  params: {
    name: 'getContent',
    arguments: {
      descripcion: 'persona corriendo en playa',
      limite: 5
    }
  }
};
```

### Test Tool 2:
```javascript
const testInput2 = {
  method: 'tools/call',
  params: {
    name: 'generateCampaignMessages',
    arguments: {
      descripcion_campana: 'Zapatos deportivos X-Speed',
      publico_meta: {
        pais: 'Costa Rica',
        edad_min: 18,
        edad_max: 30
      }
    }
  }
};
```

---

## Problemas

**"Cannot find module"**
```bash
npm install
```

**"MongoDB connection failed"**
```bash
net start MongoDB
```

**"OpenAI API error"**
```bash
# Verificar API key en .env
```

**"Pinecone index not found"**
```bash
# Crear índice en Pinecone Console
```

---

## Listo para Entregable #2

MCP Server con 2 tools
Vector search funcionando
Mensajes generándose y guardándose

---
