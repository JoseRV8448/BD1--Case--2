# PromptContent - MongoDB

> AI content management with MCP server integration

## 💡 What We Learned

**Key insights from this proof of concept:**

1. **API Error Handling** - 429 error actually proves connection works (authentication successful, just no credit)
2. **Batch Processing** - Vector embeddings need batching (20/request) to respect rate limits
3. **MCP Debugging** - Stdio transport is silent; created `test_mcp_tools.js` for direct testing
4. **Docker Benefits** - Consistent MongoDB environment across team machines


---

## 📊 Status

✅ **Proof of Concept Complete**

- 100 images with AI metadata
- 4 collections (contenido_generado, log_llamadas_api, configuracion_mcp, integraciones_api)
- MCP Server with 2 tools (getContent, generateCampaignMessages)
- External API integration verified (OpenAI 429)

---

## 🚀 Quick Start
```bash
# 1. Start MongoDB
docker run -d --name mongodb -p 27017:27017 mongo:7.0

# 2. Generate data
cd scripts && npm install
node fill_data.js

# 3. Test API
cd ../mcp && npm install
npm run test:api

# 4. Start MCP Server
npm start
```

---

## 📂 Structure
```
mongodb/
├── design/          # Database schema (JSON examples)
├── scripts/         # Data generation
├── mcp/             # MCP Server + tools
└── evidence/        # 📸 Screenshots & detailed findings
```

---

## 📋 Requirements

| Requirement | Status |
|------------|--------|
| 100+ images | ✅ |
| Vector embeddings | ✅ (code ready) |
| External API | ✅ (429 verified) |
| MCP Server | ✅ |
