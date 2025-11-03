// MCP Server - 2 tools requeridos
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

// TOOL 1: getContent
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

// TOOL 2: generateCampaignMessages
async function generateCampaignMessages({ descripcion_campana, publico_meta }) {
  // 1. Generar mensajes con OpenAI
  const prompt = `Genera 3 mensajes publicitarios para:
Producto: ${descripcion_campana}
Público: ${publico_meta.pais || 'Costa Rica'}, edad ${publico_meta.edad_min}-${publico_meta.edad_max}

Responde JSON:
{
  "mensajes": [
    {"numero": 1, "texto": "...", "tono": "profesional"},
    {"numero": 2, "texto": "...", "tono": "casual"},
    {"numero": 3, "texto": "...", "tono": "motivacional"}
  ]
}`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4-turbo',
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' }
  });

  const mensajes = JSON.parse(completion.choices[0].message.content);
  const campana_id = `camp_${Date.now()}`;

  // 2. Almacenar en MongoDB
  await db.collection('campana_mensajes').insertOne({
    campana_id,
    descripcion_campana,
    publico_meta,
    mensajes_generados: mensajes.mensajes,
    created_at: new Date()
  });

  return { campana_id, ...mensajes };
}

// Iniciar MCP Server
async function main() {
  await initialize();
  const server = new MCPServer({ name: 'promptcontent-mcp', version: '1.0.0' });

  server.tool('getContent', 'Busca imágenes por descripción',
    { descripcion: { type: 'string' }, tipo: { type: 'string' }, limite: { type: 'number' } },
    getContent
  );

  server.tool('generateCampaignMessages', 'Genera 3 mensajes de campaña',
    { descripcion_campana: { type: 'string' }, publico_meta: { type: 'object' } },
    generateCampaignMessages
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('🚀 MCP Server listo');
}

process.on('SIGINT', async () => {
  if (mongoClient) await mongoClient.close();
  process.exit(0);
});

main().catch(console.error);
