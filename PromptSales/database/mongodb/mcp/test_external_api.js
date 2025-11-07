// test_external_api.js 
const { MongoClient } = require('mongodb');
const { OpenAI } = require('openai');
require('dotenv').config();

async function testExternalAPI() {
  const mongoClient = new MongoClient(process.env.MONGODB_URI);
  await mongoClient.connect();
  const db = mongoClient.db('PromptContent');

  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  console.log('🚀 Probando conexión a API externa (OpenAI)...\n');

  const request_body = {
    model: "gpt-3.5-turbo",
    messages: [
      {
        role: "user",
        content: "Genera un slogan para una campaña de zapatos deportivos en Costa Rica"
      }
    ],
    max_tokens: 50
  };

  const inicio = new Date();

  try {
    // ✅ LLAMADA POST REAL A API EXTERNA
    const completion = await openai.chat.completions.create(request_body);
    
    const fin = new Date();
    const latencia = fin - inicio;

    const resultado = {
      servicio: "OpenAI",
      endpoint: "/v1/chat/completions",
      request: {
        method: "POST",
        headers: {
          "Authorization": "Bearer [OCULTO]",
          "Content-Type": "application/json"
        },
        body: request_body,
        timestamp_envio: inicio
      },
      response: {
        status: 200,
        body: {
          id: completion.id,
          model: completion.model,
          content: completion.choices[0].message.content,
          tokens_usados: completion.usage.total_tokens
        },
        timestamp_recepcion: fin
      },
      latencia_ms: latencia
    };

    // ✅ GUARDAR EN MONGODB
    await db.collection('log_llamadas_api').insertOne(resultado);

    console.log('✅ API externa llamada exitosamente');
    console.log('📊 Resultado:', completion.choices[0].message.content);
    console.log(`⏱️  Latencia: ${latencia}ms`);
    console.log('💾 Log guardado en MongoDB\n');

  } catch (error) {
    console.error('❌ Error al llamar API:', error.message);
    
    // Guardar error también
    await db.collection('log_llamadas_api').insertOne({
      servicio: "OpenAI",
      endpoint: "/v1/chat/completions",
      request: { method: "POST", body: request_body, timestamp_envio: inicio },
      response: { status: error.status || 500, error: error.message },
      latencia_ms: new Date() - inicio
    });
  }

  await mongoClient.close();
}

testExternalAPI().catch(console.error);