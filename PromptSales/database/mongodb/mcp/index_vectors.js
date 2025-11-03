// Indexar vectores en Pinecone
const { MongoClient } = require('mongodb');
const { PineconeClient } = require('@pinecone-database/pinecone');
const { OpenAI } = require('openai');
require('dotenv').config();

async function indexVectors() {
  // Conectar
  const mongoClient = new MongoClient(process.env.MONGODB_URI);
  await mongoClient.connect();
  const db = mongoClient.db('PromptContent');

  const pinecone = new PineconeClient();
  await pinecone.init({
    apiKey: process.env.PINECONE_API_KEY,
    environment: process.env.PINECONE_ENVIRONMENT
  });
  const index = pinecone.Index(process.env.PINECONE_INDEX);

  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  console.log('🚀 Iniciando indexación...');

  // Obtener documentos
  const contenidos = await db.collection('contenido_generado').find({}).toArray();
  console.log(`📊 ${contenidos.length} documentos encontrados`);

  // Procesar en batches de 100
  for (let i = 0; i < contenidos.length; i += 100) {
    const batch = contenidos.slice(i, i + 100);
    
    // Generar embeddings
    const textos = batch.map(c => c.descripcion_amplia);
    const embeddingRes = await openai.embeddings.create({
      model: 'text-embedding-3-small',
      input: textos
    });

    // Preparar vectores
    const vectors = batch.map((doc, idx) => ({
      id: doc._id.toString(),
      values: embeddingRes.data[idx].embedding,
      metadata: {
        tipo: doc.tipo,
        hashtags: doc.hashtags.join(',')
      }
    }));

    // Subir a Pinecone
    await index.upsert({ vectors });
    console.log(`✅ Batch ${Math.floor(i / 100) + 1} indexado`);
  }

  await mongoClient.close();
  console.log('🎉 Indexación completada');
}

indexVectors().catch(console.error);
