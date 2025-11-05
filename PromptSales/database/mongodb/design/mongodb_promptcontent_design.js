/*
 * ============================================
 * PromptContent - MongoDB Database Design
 * ============================================
 * 
 * PROPÓSITO:
 * Base de datos para gestión de contenido multimedia generado con IA,
 * logs de APIs externas, y configuración de MCP servers.
 * 
 * COLLECTIONS: 4
 * 
 * 1. contenido_generado (100+ docs)
 *    - Contenido multimedia (imágenes, videos, audio, texto)
 *    - Embeddings vectoriales para búsqueda semántica
 *    - Metadata de generación AI (provider, modelo, tokens)
 * 
 * 2. log_llamadas_api
 *    - Registro completo de requests/responses a APIs externas
 *    - Incluye headers, body, latencia
 * 
 * 3. configuracion_mcp
 *    - Configuración de MCP servers y clients
 *    - Tools disponibles: getContent, generateCampaignMessages
 * 
 * 4. integraciones_api
 *    - Catálogo de APIs disponibles (OpenAI, Anthropic, Canva, etc.)
 *    - Rate limits y endpoints
 * 
 * DESIGN PRINCIPLES:
 * - Schema-less para flexibilidad multi-provider
 * - Embedded documents para configuración MCP
 * - Vector embeddings preparados para Pinecone
 * - Logs completos para auditoría
 * 
 * NOTA: Este archivo muestra la estructura conceptual.
 * Para datos reales ejecutar: fill_data.js
 * Los "..." indican campos abreviados por claridad.
 */



// MongoDB PromptContent
// ============ COLECCIONES ============

// 1. contenido_generado (NO limitado a imagenes)
db.contenido_generado.insertOne({
  tipo: "imagen", // imagen|video|texto|audio
  url: "s3://promptsales/content/img001.jpg",
  descripcion_amplia: "Anuncio de zapatos deportivos mostrando persona corriendo en playa al amanecer, enfoque en comodidad y libertad",
  hashtags: ["#deporte", "#running", "#costarica", "#verano2025"],
  vector_embedding: [0.12, 0.45, 0.78, /* ... 1533 valores más */],
  
  // NUEVO: Instrucciones para generación (faltaba!)
  prompt_instrucciones: {
    mensaje_core: "Promocionar zapatos X-Speed para corredores",
    tono: "inspiracional",
    objetivos: ["mostrar_beneficios", "crear_deseo"],
    restricciones: ["no_mencionar_competencia", "incluir_logo"]
  },
  
  // NUEVO: Soportar múltiples AI providers
  ai_provider: "OpenAI", // OpenAI|Anthropic|Gemini|Llama|MidJourney|StableDiffusion
  modelo: "dall-e-3",
  tokens_consumidos: 890,
  created_at: ISODate("2024-10-28T10:30:00Z")
});

// 2. log_llamadas_api (CORREGIDO: incluir body completo)
db.log_llamadas_api.insertOne({
  servicio: "Canva",
  endpoint: "/v1/designs/generate",
  request: {
    method: "POST",
    headers: {
      "Authorization": "Bearer xxx",
      "Content-Type": "application/json"
    },
    body: {  // BODY COMPLETO!
      "template_id": "instagram_post_1080",
      "brand_kit_id": "abc123",
      "elements": {
        "headline": "Corre más rápido",
        "description": "Con X-Speed",
        "image_prompt": "runner at beach"
      }
    },
    timestamp_envio: ISODate("2024-10-28T10:31:00Z")
  },
  response: {
    status: 200,
    body: {  // Respuesta completa
      "design_id": "xyz789",
      "url": "https://canva.com/design/xyz789",
      "export_url": "https://export.canva.com/xyz789.png"
    },
    timestamp_recepcion: ISODate("2024-10-28T10:31:02Z")
  },
  latencia_ms: 2000
});

// 3. configuracion_mcp (CORREGIDO: servers Y clients)
db.configuracion_mcp.insertOne({
  // MCP Servers disponibles
  mcp_servers: [
    {
      nombre: "content_mcp_server",
      host: "localhost:3001",
      tools: [
        {
          nombre: "getContent",
          descripcion: "Busca contenido por descripción",
          parametros: ["descripcion", "tipo", "limite"]
        },
        {
          nombre: "generateCampaignMessages",
          descripcion: "Genera 3 mensajes por segmento poblacional",
          parametros: ["campaign_id", "segmentos"]
        }
      ]
    }
  ],
  
  // MCP Clients que se conectan
  mcp_clients: [
    {
      nombre: "promptads_client",
      conecta_a: "content_mcp_server",
      permisos: ["read", "execute"],
      timeout_ms: 5000
    },
    {
      nombre: "promptcrm_client",
      conecta_a: "content_mcp_server",
      permisos: ["read"],
      timeout_ms: 3000
    }
  ],
  
  updated_at: ISODate("2024-10-28T09:00:00Z")
});

// 4. integraciones_api (múltiples providers)
db.integraciones_api.insertOne({
  nombre: "OpenAI",  // Ya no limitado a un solo provider
  tipo: "ai_generation",
  endpoints: [
    {
      path: "/v1/images/generations",
      metodo: "POST",
      rate_limit: 50
    }
  ]
});

// MÁS PROVIDERS
db.integraciones_api.insertMany([
  {nombre: "Anthropic", tipo: "ai_text"},
  {nombre: "Gemini", tipo: "ai_multimodal"},
  {nombre: "MidJourney", tipo: "ai_images"},
  {nombre: "Canva", tipo: "design"},
  {nombre: "Adobe", tipo: "design"}
]);
