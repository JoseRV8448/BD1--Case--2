// ============================================
// TOOL 1: getContent ✅ CON VALIDACIÓN
// ============================================
async function getContent({ descripcion, tipo = 'imagen', limite = 10 }) {
  // ✅ VALIDACIONES
  if (!descripcion || descripcion.trim() === '') {
    throw new Error('❌ Descripción es requerida');
  }
  
  if (limite < 1 || limite > 50) {
    throw new Error('❌ Límite debe estar entre 1-50');
  }

  const tiposValidos = ['imagen', 'video', 'texto', 'audio'];
  if (!tiposValidos.includes(tipo)) {
    throw new Error(`❌ Tipo debe ser: ${tiposValidos.join(', ')}`);
  }

  try {
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
      }),
      metadata: {
        total_encontrados: contenidos.length,
        tipo_busqueda: tipo,
        query_original: descripcion
      }
    };
  } catch (error) {
    console.error('❌ Error en getContent:', error);
    throw new Error(`Error buscando contenido: ${error.message}`);
  }
}

// ============================================
// TOOL 2: generateCampaignMessages CON VALIDACIÓN
// ============================================
async function generateCampaignMessages({ descripcion_campana, publico_meta }) {
  // ✅ VALIDACIONES
  if (!descripcion_campana || descripcion_campana.trim() === '') {
    throw new Error('❌ Descripción de campaña es requerida');
  }

  if (!publico_meta || typeof publico_meta !== 'object') {
    throw new Error('❌ Público meta debe ser un objeto');
  }

  try {
    const campana_id = `camp_${Date.now()}`;
    
    const segmentos = Array.isArray(publico_meta.segmentos) 
      ? publico_meta.segmentos 
      : [publico_meta];
    
    const bitacora_completa = [];

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
      
      // ✅ MEJOR ESTIMACIÓN DE TOKENS
      bitacora_completa.push({
        segmento_poblacional: segmento,
        descripcion_segmento: segmento_descripcion,
        mensajes: resultado.mensajes.map(m => ({
          ...m,
          generado_at: new Date(),
          tokens_estimados: Math.ceil(m.texto.length / 4) // ✅ Mejor que split(' ')
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
  } catch (error) {
    console.error('❌ Error en generateCampaignMessages:', error);
    throw new Error(`Error generando mensajes: ${error.message}`);
  }
}