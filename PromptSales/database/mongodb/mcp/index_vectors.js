// Indexar vectores en Pinecone
const { MongoClient } = require('mongodb');
const { Pinecone } = require('@pinecone-database/pinecone');
const { OpenAI } = require('openai');
require('dotenv').config();

async function indexVectors() {
  // Conectar
  const mongoClient = new MongoClient(process.env.MONGODB_URI);
  await mongoClient.connect();
  const db = mongoClient.db('PromptContent');

  const pinecone = new Pinecone({
    apiKey: process.env.PINECONE_API_KEY
  });
  const index = pinecone.index(process.env.PINECONE_INDEX);

  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  console.log('🚀 Iniciando indexación...');

  // Obtener documentos que ya tienen embeddings
  const contenidos = await db.collection('contenido_generado')
    .find({ vector_embedding: { $exists: true, $ne: null } })
    .toArray();
  
  console.log(`📊 ${contenidos.length} documentos encontrados`);

  if (contenidos.length === 0) {
    console.log('❌ No hay documentos con embeddings. Ejecuta fill_data.js primero.');
    await mongoClient.close();
    return;
  }

  // Procesar en batches de 100
  for (let i = 0; i < contenidos.length; i += 100) {
    const batch = contenidos.slice(i, i + 100);

    // Preparar vectores
    const vectors = batch.map((doc) => ({
      id: doc._id.toString(),
      values: doc.vector_embedding,
      metadata: {
        descripcion: doc.descripcion_amplia.substring(0, 200),
        hashtags: doc.hashtags.join(',')
      }
    }));

    // Subir a Pinecone
    await index.upsert(vectors);
    console.log(`✅ Batch ${Math.floor(i / 100) + 1} indexado`);
  }

  await mongoClient.close();
  console.log('🎉 Indexación completada');
}

indexVectors().catch(console.error);