// fill_data.js - VERSIÓN CORREGIDA con embeddings reales
const { MongoClient } = require('mongodb');
const { OpenAI } = require('openai');
require('dotenv').config();

const categorias = [
  "productos_electronicos",
  "servicios_financieros", 
  "articulos_deportivos",
  "moda_ropa",
  "comida_restaurantes",
  "viajes_turismo",
  "educacion_cursos",
  "salud_bienestar",
  "hogar_decoracion",
  "automotriz",
  "entretenimiento",
  "tecnologia_software"
];

const ai_providers = ["OpenAI", "Anthropic", "Gemini", "MidJourney", "StableDiffusion"];
const tonos = ["profesional", "casual", "juvenil", "elegante", "divertido"];

async function fillData() {
  const mongoClient = new MongoClient(process.env.MONGODB_URI);
  await mongoClient.connect();
  const db = mongoClient.db('PromptContent');

  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  console.log('🚀 Generando 100 imágenes con embeddings REALES...\n');

  const contenidos = [];

  for(let i = 1; i <= 100; i++) {
    const categoria = categorias[i % 12];
    const provider = ai_providers[i % 5];
    
    const descripcion = `Imagen promocional para ${categoria}. Muestra productos/servicios de alta calidad con enfoque en beneficios para el cliente. Colores vibrantes, composición profesional, elementos que transmiten confianza y modernidad.`;

    contenidos.push({
      tipo: "imagen",
      url: `s3://promptsales/img${i}.jpg`,
      descripcion_contenido: descripcion,
      hashtags: [`#${categoria}`, "#marketing", "#costarica", "#2025", "#promocion"],
      // ✅ EMBEDDING SERÁ GENERADO DESPUÉS (placeholder por ahora)
      embedding: null,
      prompt_instrucciones: {
        mensaje_core: `Vender productos de ${categoria} a público objetivo`,
        tono: tonos[i % 5],
        objetivos: ["generar_interes", "mostrar_calidad", "crear_urgencia"],
        restricciones: ["no_texto_pequeño", "incluir_marca", "colores_corporativos"]
      },
      provider_ia: provider,
      modelo: provider === "OpenAI" ? "dall-e-3" : "modelo-base",
      tokens_usados: Math.floor(Math.random() * 2000) + 500,
      created_at: new Date(2024, 9, Math.floor(Math.random() * 28) + 1)
    });
  }

  // ✅ INSERTAR PRIMERO
  const result = await db.collection('contenido_generado').insertMany(contenidos);
  console.log(`✅ ${contenidos.length} documentos insertados\n`);

  // ✅ AHORA GENERAR EMBEDDINGS REALES EN BATCH
  console.log('🔄 Generando embeddings reales con OpenAI...\n');

  const batchSize = 20; // OpenAI limita requests
  const insertedDocs = await db.collection('contenido_generado')
    .find({ embedding: null })
    .toArray();

  for (let i = 0; i < insertedDocs.length; i += batchSize) {
    const batch = insertedDocs.slice(i, i + batchSize);
    const textos = batch.map(doc => doc.descripcion_contenido);

    console.log(`   Procesando batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(insertedDocs.length/batchSize)}...`);

    const embeddingRes = await openai.embeddings.create({
      model: 'text-embedding-3-small',
      input: textos
    });

    // Actualizar cada documento con su embedding real
    for (let j = 0; j < batch.length; j++) {
      await db.collection('contenido_generado').updateOne(
        { _id: batch[j]._id },
        { $set: {embedding: embeddingRes.data[j].embedding } }
      );
    }
  }

  console.log('\n✅ Embeddings reales generados y guardados');
  console.log('💡 Ahora ejecuta: npm run index:vectors para subirlos a Pinecone\n');

  await mongoClient.close();
}

fillData().catch(console.error);