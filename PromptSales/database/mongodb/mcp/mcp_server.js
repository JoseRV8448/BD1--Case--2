// MCP Server - VERSIÓN CORREGIDA - 2 tools cumpliendo requisitos
const { MCPServer } = require('@modelcontextprotocol/sdk/server');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio');
const { MongoClient, ObjectId } = require('mongodb');
const { OpenAI } = require('openai');
const { PineconeClient } = require('@pinecone-database/pinecone');

// Config
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const PINECONE_API_KEY = process.env.PINECONE_API_KEY;
const PINECONE_ENV = process.env.PINECONE_ENVIRONMENT || 'us-east-1-aws';
const PINECONE_INDEX = process.env.PINECONE_INDEX || 'promptcontent-images';

let mongoClient, db, openai, pineconeIndex;

async function initialize() {
  mongoClient = new MongoClient(MONGODB_URI);
  await mongoClient.connect();
  db = mongoClient.db('PromptContent');
  
  openai = new OpenAI({ apiKey: OPENAI_API_KEY });
  
  const pinecone = new PineconeClient();
  await pinecone.init({ apiKey: PINECONE_API_KEY, environment: PINECONE_ENV });
  pineconeIndex = pinecone.Index(PINECONE_INDEX);
  
  console.error('✅ Conectado');
}

// ============================================
// TOOL 1: getContent ✅ CORRECTO
// ============================================
async function getContent({ descripcion, tipo = 'imagen', limite = 10 }) {
  // 1. Generar embedding
  const embeddingRes = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: descripcion
  });
  const vector = embeddingRes.data[0].embedding;

  // 2. Buscar en Pinecone
  const searchRes = await pineconeIndex.query({
    vector,
    topK: limite,
    includeMetadata: true
  });

  // 3. Traer detalles de MongoDB
  const ids = searchRes.matches.map(m => new ObjectId(m.id));
  const contenidos = await db.collection('contenido_generado')
    .find({ _id: { $in: ids }, tipo })
    .limit(limite)
    .toArray();

  // 4. Combinar resultados
  return {
    resultados: contenidos.map(doc => {
      const match = searchRes.matches.find(m => m.id === doc._id.toString());
      return {
        id: doc._id,
        url: doc.url,
        descripcion: doc.descripcion_amplia,
        hashtags: doc.hashtags,
        score: match?.score || 0
      };
    })
  };
}

// ============================================
// TOOL 2: generateCampaignMessages 🔧 CORREGIDO
// ============================================
async function generateCampaignMessages({ descripcion_campana, publico_meta }) {
  const campana_id = `camp_${Date.now()}`;
  
  // Convertir publico_meta a array de segmentos si no lo es
  // Ej: publico_meta = { segmentos: [{edad_min:18, edad_max:25}, {edad_min:26, edad_max:40}] }
  // O: publico_meta = { edad_min: 18, edad_max: 30 } (un solo segmento)
  const segmentos = Array.isArray(publico_meta.segmentos) 
    ? publico_meta.segmentos 
    : [publico_meta];
  
  const bitacora_completa = [];

  // Generar 3 mensajes POR CADA segmento poblacional
  for (const segmento of segmentos) {
    const segmento_descripcion = [
      `País: ${segmento.pais || 'Costa Rica'}`,
      `Edad: ${segmento.edad_min}-${segmento.edad_max}`,
      segmento.genero ? `Género: ${segmento.genero}` : '',
      segmento.profesion ? `Profesión: ${segmento.profesion}` : '',
      segmento.intereses ? `Intereses: ${segmento.intereses}` : ''
    ].filter(Boolean).join(', ');

    const prompt = `Genera 3 mensajes publicitarios para:
Producto/Campaña: ${descripcion_campana}
Segmento poblacional: ${segmento_descripcion}

IMPORTANTE: Adapta el lenguaje, tono y referencias culturales a este segmento específico.

Responde JSON:
{
  "mensajes": [
    {"numero": 1, "texto": "mensaje adaptado al segmento", "tono": "profesional"},
    {"numero": 2, "texto": "mensaje adaptado al segmento", "tono": "casual"},
    {"numero": 3, "texto": "mensaje adaptado al segmento", "tono": "motivacional"}
  ]
}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' }
    });

    const resultado = JSON.parse(completion.choices[0].message.content);
    
    // Agregar a bitácora con identificación del segmento
    bitacora_completa.push({
      segmento_poblacional: segmento,
      descripcion_segmento: segmento_descripcion,
      mensajes: resultado.mensajes.map(m => ({
        ...m,
        generado_at: new Date(),
        tokens_estimados: m.texto.split(' ').length * 1.3 // Estimación
      })),
      timestamp: new Date()
    });
  }

  // Almacenar en MongoDB
  await db.collection('campana_mensajes').insertOne({
    campana_id,
    descripcion_campana,
    publico_meta_original: publico_meta,
    bitacora_por_segmento: bitacora_completa,
    resumen: {
      total_segmentos: segmentos.length,
      total_mensajes: bitacora_completa.length * 3,
      mensajes_por_segmento: 3
    },
    created_at: new Date()
  });

  return { 
    campana_id,
    resumen: {
      segmentos_procesados: segmentos.length,
      mensajes_generados_total: bitacora_completa.length * 3,
      mensajes_por_segmento: 3
    },
    bitacora: bitacora_completa 
  };
}

// ============================================
// Iniciar MCP Server
// ============================================
async function main() {
  await initialize();
  const server = new MCPServer({ name: 'promptcontent-mcp', version: '1.0.0' });

  server.tool('getContent', 'Busca imágenes por descripción semántica usando búsqueda vectorial',
    { 
      descripcion: { type: 'string', description: 'Descripción textual del contenido buscado' }, 
      tipo: { type: 'string', description: 'Tipo de contenido (imagen|video|texto)', default: 'imagen' }, 
      limite: { type: 'number', description: 'Cantidad máxima de resultados', default: 10 } 
    },
    getContent
  );

  server.tool('generateCampaignMessages', 
    'Genera 3 mensajes de campaña POR CADA segmento poblacional y almacena bitácora',
    { 
      descripcion_campana: { 
        type: 'string', 
        description: 'Descripción del producto/servicio a promocionar' 
      }, 
      publico_meta: { 
        type: 'object', 
        description: 'Puede ser un segmento {edad_min, edad_max, pais...} o múltiples {segmentos: [{...}, {...}]}' 
      } 
    },
    generateCampaignMessages
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('🚀 MCP Server listo (versión corregida)');
}

process.on('SIGINT', async () => {
  if (mongoClient) await mongoClient.close();
  process.exit(0);
});

main().catch(console.error);