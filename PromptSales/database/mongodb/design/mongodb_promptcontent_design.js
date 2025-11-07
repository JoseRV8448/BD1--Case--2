/*
 * ============================================
 * PromptContent - MongoDB Database Design
 * VERSIÓN CORREGIDA según feedback del profesor
 * ============================================
 * 
 * PROPÓSITO:
 * Base de datos para gestión de contenido multimedia generado con IA,
 * logs de APIs externas, y configuración de MCP servers.
 * 
 * COLLECTIONS: 5 (se agregó bitacora_solicitudes)
 * 
 * CAMBIOS PRINCIPALES:
 * 1. ✅ Eliminado campo "tipo" - ahora es parte de metadata embebida
 * 2. ✅ Agregada referencia a campañas en contenido_generado
 * 3. ✅ MCP servers con configuración completa de conexión
 * 4. ✅ Nueva collection: bitacora_solicitudes (tracking de generateCampaignMessages)
 * 5. ✅ Instrucciones detalladas de generación AI para cada tipo de contenido
 */

// ============================================
// COLLECTION 1: contenido_generado
// ============================================
// CORRECCIÓN: Agregada referencia a campañas + metadata embebida en vez de campo "tipo"

db.contenido_generado.insertOne({
  // ✅ NUEVO: Vinculación con campañas
  campana_id: "camp_2024_zapatos_running", // null si es contenido genérico
  cliente_id: "cliente_nike_cr",
  
  // Metadata del contenido (embedded document)
  metadata: {
    formato: "imagen",  // imagen|video|texto|audio
    mime_type: "image/jpeg",
    resolucion: "1080x1080",
    duracion_segundos: null,  // para videos/audio
    tamaño_bytes: 245000,
    url_almacenamiento: "s3://promptsales/content/img001.jpg",
    url_thumbnail: "s3://promptsales/content/thumbnails/img001_thumb.jpg"
  },
  
  // Contenido descriptivo
  descripcion_amplia: "Anuncio de zapatos deportivos mostrando persona corriendo en playa al amanecer, enfoque en comodidad y libertad",
  hashtags: ["#deporte", "#running", "#costarica", "#verano2025", "#nike"],
  palabras_clave: ["zapatos", "running", "playa", "amanecer", "libertad"],
  
  // Vector embedding para búsqueda semántica
  vector_embedding: [0.12, 0.45, 0.78 /* ... 1533 valores más */],
  
  // ✅ INSTRUCCIONES COMPLETAS DE GENERACIÓN
  instrucciones_generacion: {
    prompt_original: "Genera una imagen promocional de zapatos deportivos Nike en la playa de Costa Rica al amanecer, mostrando a un corredor en acción. La imagen debe transmitir libertad, energía y comodidad. Usar colores cálidos del amanecer.",
    
    parametros_ai: {
      mensaje_core: "Promocionar zapatos X-Speed para corredores costarricenses",
      tono: "inspiracional",
      estilo_visual: "fotografía deportiva profesional",
      colores_principales: ["naranja", "azul", "dorado"],
      elementos_requeridos: ["logo_nike", "zapatos_visible", "playa_costarica"],
      elementos_prohibidos: ["competencia", "texto_pequeño", "personas_no_latinas"]
    },
    
    objetivos: ["mostrar_beneficios", "crear_deseo", "asociar_con_libertad"],
    restricciones: ["no_mencionar_competencia", "incluir_logo", "colores_corporativos"],
    publico_objetivo: {
      edad: "25-40",
      genero: "ambos",
      ubicacion: "Costa Rica",
      intereses: ["deporte", "salud", "bienestar"]
    }
  },
  
  // Metadata de generación AI
  ai_metadata: {
    provider: "OpenAI", // OpenAI|Anthropic|Gemini|MidJourney|StableDiffusion|Canva|Adobe
    modelo: "dall-e-3",
    version_modelo: "v1.0",
    tokens_consumidos: 890,
    costo_usd: 0.04,
    tiempo_generacion_ms: 8500,
    intentos: 1,
    fecha_generacion: ISODate("2024-10-28T10:30:00Z")
  },
  
  // Metadata de aprobación
  aprobacion: {
    estado: "aprobado", // pendiente|aprobado|rechazado|revision
    aprobado_por: "user_123",
    fecha_aprobacion: ISODate("2024-10-28T11:00:00Z"),
    comentarios: "Excelente, usar para campaña principal"
  },
  
  // Métricas de uso
  metricas: {
    veces_usado: 5,
    campañas_asociadas: ["camp_2024_zapatos_running", "camp_2024_verano"],
    engagement_promedio: 0.045, // calculado desde PromptAds
    ultima_actualizacion: ISODate("2024-11-01T10:00:00Z")
  },
  
  created_at: ISODate("2024-10-28T10:30:00Z"),
  updated_at: ISODate("2024-11-01T10:00:00Z")
});

// Ejemplo de contenido tipo VIDEO
db.contenido_generado.insertOne({
  campana_id: "camp_2024_zapatos_running",
  cliente_id: "cliente_nike_cr",
  
  metadata: {
    formato: "video",
    mime_type: "video/mp4",
    resolucion: "1920x1080",
    duracion_segundos: 30,
    tamaño_bytes: 12500000,
    url_almacenamiento: "s3://promptsales/content/video001.mp4",
    url_thumbnail: "s3://promptsales/content/thumbnails/video001_thumb.jpg",
    fps: 30,
    codec: "h264"
  },
  
  descripcion_amplia: "Video promocional de 30 segundos mostrando atletas corriendo en diferentes paisajes de Costa Rica, con enfoque en los zapatos Nike X-Speed",
  hashtags: ["#nike", "#running", "#costarica", "#video"],
  palabras_clave: ["zapatos", "running", "costa rica", "atletas", "velocidad"],
  vector_embedding: [0.23, 0.56, 0.89 /* ... */],
  
  instrucciones_generacion: {
    prompt_original: "Genera un video de 30 segundos mostrando atletas corriendo en paisajes icónicos de Costa Rica. Incluir montañas, playas y ciudad. Enfatizar los zapatos Nike X-Speed. Música energética de fondo.",
    
    parametros_ai: {
      mensaje_core: "Mostrar versatilidad de Nike X-Speed en diferentes terrenos",
      tono: "energético",
      estilo_visual: "cinematográfico deportivo",
      duracion_segundos: 30,
      transiciones: ["cortes_rapidos", "slow_motion_zapatos"],
      audio: {
        musica: "energetica_instrumental",
        efectos_sonido: ["pasos", "viento", "olas"],
        voz_narracion: false
      }
    },
    
    objetivos: ["mostrar_versatilidad", "crear_aspiracion", "destacar_tecnologia"],
    restricciones: ["duracion_maxima_30s", "incluir_logo_final", "sin_texto_pantalla"],
    publico_objetivo: {
      edad: "25-40",
      genero: "ambos",
      ubicacion: "Costa Rica"
    }
  },
  
  ai_metadata: {
    provider: "RunwayML",
    modelo: "gen-2",
    tokens_consumidos: 3500,
    costo_usd: 1.20,
    tiempo_generacion_ms: 120000
  },
  
  created_at: ISODate("2024-10-29T14:00:00Z")
});


// ============================================
// COLLECTION 2: log_llamadas_api
// ============================================
// ✅ YA CORRECTO: Body completo en request y response

db.log_llamadas_api.insertOne({
  servicio: "OpenAI",
  endpoint: "/v1/images/generations",
  
  request: {
    method: "POST",
    headers: {
      "Authorization": "Bearer sk-***",
      "Content-Type": "application/json",
      "User-Agent": "PromptContent/1.0"
    },
    body: {
      model: "dall-e-3",
      prompt: "Professional running shoes on beach at sunrise in Costa Rica",
      n: 1,
      size: "1024x1024",
      quality: "hd",
      style: "natural"
    },
    timestamp_envio: ISODate("2024-10-28T10:30:00Z")
  },
  
  response: {
    status: 200,
    headers: {
      "content-type": "application/json",
      "x-request-id": "req_abc123"
    },
    body: {
      created: 1698480600,
      data: [
        {
          url: "https://oaidalleapiprodscus.blob.core.windows.net/private/...",
          revised_prompt: "A professional photograph of running shoes on a beach..."
        }
      ]
    },
    timestamp_recepcion: ISODate("2024-10-28T10:30:08Z")
  },
  
  latencia_ms: 8500,
  
  // Metadata adicional
  metadata: {
    campana_id: "camp_2024_zapatos_running",
    contenido_id: ObjectId("507f1f77bcf86cd799439011"),
    usuario_solicitante: "user_123",
    intento_numero: 1,
    resultado: "exitoso",
    tokens_consumidos: 890,
    costo_estimado_usd: 0.04
  },
  
  created_at: ISODate("2024-10-28T10:30:08Z")
});

// Log de llamada a servicio externo de diseño (Canva)
db.log_llamadas_api.insertOne({
  servicio: "Canva",
  endpoint: "/v1/designs/generate",
  
  request: {
    method: "POST",
    headers: {
      "Authorization": "Bearer canva_token_***",
      "Content-Type": "application/json"
    },
    body: {
      template_id: "instagram_post_1080",
      brand_kit_id: "nike_cr_brandkit",
      elements: {
        headline: "Corre más rápido",
        description: "Con X-Speed Nike",
        image_url: "s3://promptsales/content/img001.jpg",
        colors: {
          primary: "#FF6B00",
          secondary: "#001489"
        }
      },
      export_format: "png"
    },
    timestamp_envio: ISODate("2024-10-28T10:31:00Z")
  },
  
  response: {
    status: 200,
    body: {
      design_id: "xyz789",
      url: "https://canva.com/design/xyz789",
      export_url: "https://export.canva.com/xyz789.png",
      thumbnail_url: "https://export.canva.com/xyz789_thumb.png"
    },
    timestamp_recepcion: ISODate("2024-10-28T10:31:02Z")
  },
  
  latencia_ms: 2000,
  created_at: ISODate("2024-10-28T10:31:02Z")
});


// ============================================
// COLLECTION 3: configuracion_mcp
// ============================================
// ✅ CORRECCIÓN MAYOR: Configuración completa de servers y clients con parámetros detallados

db.configuracion_mcp.insertOne({
  // ============================================
  // MCP SERVERS (los que NOSOTROS levantamos)
  // ============================================
  mcp_servers: [
    {
      nombre: "content_mcp_server",
      descripcion: "Servidor MCP para búsqueda y generación de contenido",
      
      // Configuración de despliegue
      deployment: {
        host: "0.0.0.0",
        port: 3001,
        protocolo: "http",
        url_completa: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent",
        pod_name: "content-mcp-server-pod",
        replicas: 3
      },
      
      // Configuración de autenticación
      autenticacion: {
        tipo: "api_key", // api_key|oauth2|jwt
        header_name: "X-MCP-API-Key",
        timeout_segundos: 30,
        reintentos_maximos: 3
      },
      
      // Tools disponibles en este server
      tools: [
        {
          nombre: "getContent",
          version: "1.0",
          descripcion: "Busca contenido multimedia por descripción semántica usando embeddings vectoriales",
          
          parametros: {
            descripcion: {
              tipo: "string",
              requerido: true,
              descripcion: "Texto descriptivo del contenido buscado",
              ejemplo: "zapatos deportivos en la playa"
            },
            tipo_contenido: {
              tipo: "string",
              requerido: false,
              valores_permitidos: ["imagen", "video", "texto", "audio"],
              default: "imagen",
              descripcion: "Tipo de contenido multimedia a buscar"
            },
            limite: {
              tipo: "integer",
              requerido: false,
              min: 1,
              max: 50,
              default: 10,
              descripcion: "Cantidad máxima de resultados"
            },
            campana_id: {
              tipo: "string",
              requerido: false,
              descripcion: "Filtrar por campaña específica"
            },
            min_score: {
              tipo: "float",
              requerido: false,
              min: 0.0,
              max: 1.0,
              default: 0.7,
              descripcion: "Score mínimo de similitud semántica"
            }
          },
          
          respuesta: {
            formato: "json",
            estructura: {
              resultados: "array",
              metadata: "object"
            }
          },
          
          dependencias: [
            "MongoDB.contenido_generado",
            "Pinecone.content_index",
            "OpenAI.embeddings"
          ],
          
          tiempo_promedio_ms: 350,
          rate_limit: "100/minuto"
        },
        
        {
          nombre: "generateCampaignMessages",
          version: "1.0",
          descripcion: "Genera mensajes publicitarios personalizados por segmento poblacional usando IA",
          
          parametros: {
            campana_id: {
              tipo: "string",
              requerido: true,
              descripcion: "ID de la campaña para tracking",
              ejemplo: "camp_2024_zapatos_running"
            },
            descripcion_campana: {
              tipo: "string",
              requerido: true,
              descripcion: "Descripción completa del producto/servicio a promocionar",
              ejemplo: "Zapatos deportivos Nike X-Speed para corredores, enfoque en comodidad y velocidad"
            },
            publico_meta: {
              tipo: "object",
              requerido: true,
              estructura: {
                segmentos: {
                  tipo: "array",
                  requerido: true,
                  item_estructura: {
                    pais: "string",
                    edad_min: "integer",
                    edad_max: "integer",
                    genero: "string",
                    profesion: "string",
                    intereses: "array",
                    nivel_economico: "string"
                  }
                }
              },
              descripcion: "Segmentos poblacionales para personalizar mensajes"
            },
            cantidad_mensajes: {
              tipo: "integer",
              requerido: false,
              default: 3,
              min: 1,
              max: 10,
              descripcion: "Cantidad de mensajes a generar por segmento"
            },
            tonos_requeridos: {
              tipo: "array",
              requerido: false,
              default: ["profesional", "casual", "motivacional"],
              descripcion: "Tonos específicos para los mensajes"
            }
          },
          
          respuesta: {
            formato: "json",
            estructura: {
              campana_id: "string",
              resumen: "object",
              bitacora: "array"
            }
          },
          
          // ✅ INSTRUCCIONES DETALLADAS DE GENERACIÓN AI
          instrucciones_generacion_ai: {
            modelo_recomendado: "gpt-4-turbo",
            
            plantilla_prompt: `Genera {cantidad_mensajes} mensajes publicitarios para:

Producto/Campaña: {descripcion_campana}
Segmento poblacional: {segmento_descripcion}

INSTRUCCIONES ESPECÍFICAS:
1. Adapta el lenguaje, tono y referencias culturales al segmento
2. Cada mensaje debe tener entre 50-150 caracteres
3. Incluye call-to-action relevante para el segmento
4. Usa emojis apropiados si el segmento es joven
5. Referencias culturales del país especificado
6. Evita clichés y frases genéricas

Tonos a usar: {tonos_requeridos}

IMPORTANTE: Los mensajes deben ser DIFERENTES entre sí, no variaciones del mismo mensaje.

Responde en formato JSON:
{
  "mensajes": [
    {
      "numero": 1,
      "texto": "mensaje adaptado al segmento",
      "tono": "profesional",
      "call_to_action": "texto_cta",
      "emojis_usados": ["🏃", "⚡"],
      "justificacion": "por qué este mensaje funciona para este segmento"
    }
  ]
}`,
            
            validaciones_post_generacion: [
              "longitud_entre_50_150_caracteres",
              "contiene_call_to_action",
              "no_menciona_competencia",
              "lenguaje_apropiado_para_edad"
            ],
            
            parametros_modelo: {
              temperature: 0.8,
              max_tokens: 500,
              response_format: { type: "json_object" }
            }
          },
          
          dependencias: [
            "MongoDB.campana_mensajes",
            "OpenAI.chat_completions"
          ],
          
          tiempo_promedio_ms: 4500,
          rate_limit: "20/minuto"
        }
      ],
      
      // Configuración de performance
      performance: {
        max_concurrent_requests: 50,
        timeout_global_ms: 30000,
        retry_policy: {
          max_intentos: 3,
          backoff_ms: [1000, 2000, 4000]
        }
      },
      
      // Health check
      health_check: {
        endpoint: "/health",
        intervalo_segundos: 30
      },
      
      estado: "activo",
      version: "1.0.0",
      updated_at: ISODate("2024-10-28T09:00:00Z")
    }
  ],
  
  // ============================================
  // MCP CLIENTS (los que SE CONECTAN a nuestros servers)
  // ============================================
  mcp_clients: [
    {
      nombre: "promptads_client",
      descripcion: "Cliente MCP desde PromptAds para búsqueda de contenido",
      
      // A qué server se conecta
      conecta_a: {
        server_nombre: "content_mcp_server",
        url: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent"
      },
      
      // Configuración de autenticación del cliente
      autenticacion: {
        api_key: "promptads_api_key_***",
        header_name: "X-MCP-API-Key"
      },
      
      // Permisos y limitaciones
      permisos: {
        tools_permitidos: ["getContent"],
        tools_prohibidos: ["generateCampaignMessages"],
        rate_limit_personalizado: "200/minuto",
        max_requests_por_hora: 5000
      },
      
      // Configuración de timeout y reintentos
      configuracion_conexion: {
        timeout_ms: 5000,
        max_reintentos: 3,
        backoff_exponencial: true,
        keep_alive: true
      },
      
      // Metadata del cliente
      metadata: {
        origen_namespace: "promptads",
        origen_pod_pattern: "promptads-api-*",
        proposito: "Búsqueda de contenido visual para campañas publicitarias"
      },
      
      estado: "activo",
      created_at: ISODate("2024-10-20T10:00:00Z")
    },
    
    {
      nombre: "promptcrm_client",
      descripcion: "Cliente MCP desde PromptCRM para generación de mensajes",
      
      conecta_a: {
        server_nombre: "content_mcp_server",
        url: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent"
      },
      
      autenticacion: {
        api_key: "promptcrm_api_key_***",
        header_name: "X-MCP-API-Key"
      },
      
      permisos: {
        tools_permitidos: ["generateCampaignMessages"],
        tools_prohibidos: ["getContent"],
        rate_limit_personalizado: "50/minuto",
        max_requests_por_hora: 2000
      },
      
      configuracion_conexion: {
        timeout_ms: 10000,  // Mayor timeout para generación AI
        max_reintentos: 2,
        backoff_exponencial: true
      },
      
      metadata: {
        origen_namespace: "promptcrm",
        origen_pod_pattern: "promptcrm-api-*",
        proposito: "Generación automática de mensajes para leads"
      },
      
      estado: "activo",
      created_at: ISODate("2024-10-20T10:00:00Z")
    },
    
    {
      nombre: "promptsales_portal_client",
      descripcion: "Cliente MCP desde portal principal PromptSales",
      
      conecta_a: {
        server_nombre: "content_mcp_server",
        url: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent"
      },
      
      autenticacion: {
        api_key: "promptsales_portal_api_key_***",
        header_name: "X-MCP-API-Key"
      },
      
      permisos: {
        tools_permitidos: ["getContent", "generateCampaignMessages"],
        rate_limit_personalizado: "500/minuto",
        max_requests_por_hora: 20000
      },
      
      configuracion_conexion: {
        timeout_ms: 8000,
        max_reintentos: 3,
        backoff_exponencial: true
      },
      
      metadata: {
        origen_namespace: "promptsales",
        origen_pod_pattern: "promptsales-portal-*",
        proposito: "Acceso completo desde portal principal"
      },
      
      estado: "activo",
      created_at: ISODate("2024-10-20T10:00:00Z")
    }
  ],
  
  // ============================================
  // CONEXIONES EXTERNAS (APIs de terceros)
  // ============================================
  conexiones_externas: [
    {
      nombre: "OpenAI API",
      url: "https://api.openai.com/v1",
      tipo: "ai_generation",
      
      autenticacion: {
        tipo: "bearer_token",
        header: "Authorization: Bearer {api_key}"
      },
      
      endpoints_usados: [
        {
          path: "/images/generations",
          metodo: "POST",
          proposito: "Generación de imágenes"
        },
        {
          path: "/embeddings",
          metodo: "POST",
          proposito: "Generación de embeddings vectoriales"
        },
        {
          path: "/chat/completions",
          metodo: "POST",
          proposito: "Generación de texto (mensajes campaña)"
        }
      ],
      
      rate_limits: {
        requests_por_minuto: 500,
        tokens_por_minuto: 90000
      }
    },
    
    {
      nombre: "Pinecone",
      url: "https://api.pinecone.io",
      tipo: "vector_database",
      
      autenticacion: {
        tipo: "api_key",
        header: "Api-Key: {api_key}"
      },
      
      configuracion: {
        index_name: "promptcontent-vectors",
        environment: "us-east-1-aws",
        dimension: 1536,
        metric: "cosine"
      }
    }
  ],
  
  version: "2.0",
  updated_at: ISODate("2024-11-06T10:00:00Z")
});


// ============================================
// COLLECTION 4: bitacora_solicitudes
// ============================================
// ✅ NUEVA COLLECTION: Track completo de solicitudes al tool generateCampaignMessages

db.bitacora_solicitudes.insertOne({
  solicitud_id: "req_20241106_001",
  tool_name: "generateCampaignMessages",
  
  // Request completo
  request: {
    campana_id: "camp_2024_zapatos_running",
    descripcion_campana: "Zapatos deportivos Nike X-Speed para corredores costarricenses, enfoque en comodidad, velocidad y terrenos variados",
    
    publico_meta: {
      segmentos: [
        {
          pais: "Costa Rica",
          edad_min: 25,
          edad_max: 35,
          genero: "masculino",
          profesion: "profesional_deportivo",
          intereses: ["running", "fitness", "competencias"],
          nivel_economico: "medio-alto"
        },
        {
          pais: "Costa Rica",
          edad_min: 18,
          edad_max: 24,
          genero: "femenino",
          profesion: "estudiante_universitaria",
          intereses: ["fitness", "redes_sociales", "moda_deportiva"],
          nivel_economico: "medio"
        },
        {
          pais: "Costa Rica",
          edad_min: 40,
          edad_max: 55,
          genero: "ambos",
          profesion: "ejecutivo",
          intereses: ["salud", "bienestar", "running_casual"],
          nivel_economico: "alto"
        }
      ]
    },
    
    cantidad_mensajes: 3,
    tonos_requeridos: ["profesional", "casual", "motivacional"],
    
    timestamp_solicitud: ISODate("2024-11-06T10:15:00Z")
  },
  
  // Body enviado a la AI (OpenAI)
  ai_request_body: {
    model: "gpt-4-turbo",
    messages: [
      {
        role: "system",
        content: "Eres un experto en marketing digital que crea mensajes publicitarios personalizados por segmento poblacional."
      },
      {
        role: "user",
        content: `Genera 3 mensajes publicitarios para:

Producto/Campaña: Zapatos deportivos Nike X-Speed para corredores costarricenses, enfoque en comodidad, velocidad y terrenos variados

Segmento poblacional: País: Costa Rica, Edad: 25-35, Género: masculino, Profesión: profesional_deportivo, Intereses: running, fitness, competencias, Nivel económico: medio-alto

INSTRUCCIONES ESPECÍFICAS:
1. Adapta el lenguaje, tono y referencias culturales al segmento
2. Cada mensaje debe tener entre 50-150 caracteres
3. Incluye call-to-action relevante para el segmento
4. Usa emojis apropiados si el segmento es joven
5. Referencias culturales de Costa Rica
6. Evita clichés y frases genéricas

Tonos a usar: profesional, casual, motivacional

IMPORTANTE: Los mensajes deben ser DIFERENTES entre sí, no variaciones del mismo mensaje.

Responde en formato JSON:
{
  "mensajes": [
    {
      "numero": 1,
      "texto": "mensaje adaptado al segmento",
      "tono": "profesional",
      "call_to_action": "texto_cta",
      "emojis_usados": ["🏃", "⚡"],
      "justificacion": "por qué este mensaje funciona para este segmento"
    }
  ]
}`
      }
    ],
    temperature: 0.8,
    max_tokens: 500,
    response_format: { type: "json_object" }
  },
  
  // Response de la AI
  ai_response: {
    mensajes: [
      {
        numero: 1,
        texto: "Supera tus límites con Nike X-Speed. Diseñados para conquistar Chirripó y la ciudad. ⚡🏃‍♂️",
        tono: "profesional",
        call_to_action: "Conquista cualquier terreno",
        emojis_usados: ["⚡", "🏃‍♂️"],
        justificacion: "Referencia al Chirripó (icono running CR), enfoque en versatilidad terreno"
      },
      {
        numero: 2,
        texto: "¿Maratón o trail? X-Speed te lleva más lejos. Comodidad que transforma cada zancada 🔥",
        tono: "casual",
        call_to_action: "Llega más lejos",
        emojis_usados: ["🔥"],
        justificacion: "Lenguaje directo, pregunta que conecta con su práctica deportiva"
      },
      {
        numero: 3,
        texto: "Tu próximo PR empieza aquí. Nike X-Speed: velocidad, comodidad, rendimiento. 🏆💪",
        tono: "motivacional",
        call_to_action: "Alcanza tu mejor marca",
        emojis_usados: ["🏆", "💪"],
        justificacion: "PR (Personal Record) es término conocido en comunidad running, motivacional"
      }
    ]
  },
  
  // Metadata de ejecución
  metadata: {
    segmento_procesado: {
      pais: "Costa Rica",
      edad_min: 25,
      edad_max: 35,
      genero: "masculino",
      profesion: "profesional_deportivo"
    },
    
    tokens_consumidos: 385,
    costo_estimado_usd: 0.0039,
    tiempo_generacion_ms: 4200,
    
    validaciones: {
      longitud_mensajes: "OK",
      tiene_call_to_action: "OK",
      sin_mencion_competencia: "OK",
      lenguaje_apropiado: "OK"
    },
    
    resultado: "exitoso",
    intentos: 1
  },
  
  // Cliente que hizo la solicitud
  cliente_info: {
    client_name: "promptcrm_client",
    origen_namespace: "promptcrm",
    ip_origen: "10.0.2.45"
  },
  
  created_at: ISODate("2024-11-06T10:15:04Z")
});

// Ejemplo de solicitud con MÚLTIPLES segmentos
db.bitacora_solicitudes.insertOne({
  solicitud_id: "req_20241106_002",
  tool_name: "generateCampaignMessages",
  
  request: {
    campana_id: "camp_2024_zapatos_running",
    descripcion_campana: "Zapatos deportivos Nike X-Speed",
    publico_meta: {
      segmentos: [
        { pais: "Costa Rica", edad_min: 25, edad_max: 35, genero: "masculino" },
        { pais: "Costa Rica", edad_min: 18, edad_max: 24, genero: "femenino" },
        { pais: "Costa Rica", edad_min: 40, edad_max: 55, genero: "ambos" }
      ]
    }
  },
  
  // Array de respuestas (una por segmento)
  resultados_por_segmento: [
    {
      segmento_index: 0,
      segmento: { pais: "Costa Rica", edad_min: 25, edad_max: 35, genero: "masculino" },
      mensajes: [/* ... */],
      tokens_consumidos: 385,
      tiempo_ms: 4200
    },
    {
      segmento_index: 1,
      segmento: { pais: "Costa Rica", edad_min: 18, edad_max: 24, genero: "femenino" },
      mensajes: [/* ... */],
      tokens_consumidos: 410,
      tiempo_ms: 4500
    },
    {
      segmento_index: 2,
      segmento: { pais: "Costa Rica", edad_min: 40, edad_max: 55, genero: "ambos" },
      mensajes: [/* ... */],
      tokens_consumidos: 395,
      tiempo_ms: 4100
    }
  ],
  
  resumen: {
    total_segmentos: 3,
    total_mensajes: 9,
    tokens_totales: 1190,
    costo_total_usd: 0.0119,
    tiempo_total_ms: 12800
  },
  
  created_at: ISODate("2024-11-06T10:20:00Z")
});


// ============================================
// COLLECTION 5: integraciones_api
// ============================================
// ✅ YA CORRECTO: Múltiples providers

db.integraciones_api.insertMany([
  {
    nombre: "OpenAI",
    tipo: "ai_generation",
    proveedor: "OpenAI Inc.",
    
    servicios: [
      {
        servicio: "image_generation",
        modelos: ["dall-e-2", "dall-e-3"],
        endpoint: "/v1/images/generations",
        metodo: "POST",
        rate_limit: "50/minuto"
      },
      {
        servicio: "embeddings",
        modelos: ["text-embedding-3-small", "text-embedding-3-large"],
        endpoint: "/v1/embeddings",
        metodo: "POST",
        rate_limit: "3000/minuto"
      },
      {
        servicio: "chat_completions",
        modelos: ["gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"],
        endpoint: "/v1/chat/completions",
        metodo: "POST",
        rate_limit: "500/minuto"
      }
    ],
    
    configuracion: {
      url_base: "https://api.openai.com",
      autenticacion: "Bearer Token",
      formato_respuesta: "json"
    },
    
    estado: "activo"
  },
  
  {
    nombre: "Anthropic",
    tipo: "ai_text",
    proveedor: "Anthropic PBC",
    
    servicios: [
      {
        servicio: "chat_completions",
        modelos: ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"],
        endpoint: "/v1/messages",
        metodo: "POST",
        rate_limit: "50/minuto"
      }
    ],
    
    configuracion: {
      url_base: "https://api.anthropic.com",
      autenticacion: "API Key (x-api-key header)"
    },
    
    estado: "activo"
  },
  
  {
    nombre: "Google Gemini",
    tipo: "ai_multimodal",
    proveedor: "Google LLC",
    
    servicios: [
      {
        servicio: "multimodal_generation",
        modelos: ["gemini-pro", "gemini-pro-vision"],
        endpoint: "/v1/models/gemini-pro:generateContent",
        metodo: "POST"
      }
    ],
    
    estado: "activo"
  },
  
  {
    nombre: "MidJourney",
    tipo: "ai_images",
    proveedor: "Midjourney Inc.",
    
    servicios: [
      {
        servicio: "image_generation",
        modelos: ["midjourney-v6"],
        endpoint: "/api/v1/imagine",
        metodo: "POST"
      }
    ],
    
    estado: "activo"
  },
  
  {
    nombre: "Stability AI",
    tipo: "ai_images",
    proveedor: "Stability AI",
    
    servicios: [
      {
        servicio: "image_generation",
        modelos: ["stable-diffusion-xl", "stable-diffusion-3"],
        endpoint: "/v1/generation/text-to-image",
        metodo: "POST"
      }
    ],
    
    estado: "activo"
  },
  
  {
    nombre: "Canva",
    tipo: "design",
    proveedor: "Canva Pty Ltd",
    
    servicios: [
      {
        servicio: "design_generation",
        endpoint: "/v1/designs/generate",
        metodo: "POST"
      },
      {
        servicio: "template_access",
        endpoint: "/v1/templates",
        metodo: "GET"
      }
    ],
    
    estado: "activo"
  },
  
  {
    nombre: "Adobe Express",
    tipo: "design",
    proveedor: "Adobe Inc.",
    
    servicios: [
      {
        servicio: "creative_automation",
        endpoint: "/v1/creative/generate",
        metodo: "POST"
      }
    ],
    
    estado: "activo"
  }
]);


// ============================================
// COLLECTION 6: campana_mensajes
// ============================================
// Collection para almacenar resultados del tool generateCampaignMessages

db.campana_mensajes.insertOne({
  campana_id: "camp_2024_zapatos_running",
  descripcion_campana: "Zapatos deportivos Nike X-Speed para corredores costarricenses",
  
  publico_meta_original: {
    segmentos: [
      {
        pais: "Costa Rica",
        edad_min: 25,
        edad_max: 35,
        genero: "masculino",
        profesion: "profesional_deportivo"
      },
      {
        pais: "Costa Rica",
        edad_min: 18,
        edad_max: 24,
        genero: "femenino",
        profesion: "estudiante_universitaria"
      }
    ]
  },
  
  bitacora_por_segmento: [
    {
      segmento_poblacional: {
        pais: "Costa Rica",
        edad_min: 25,
        edad_max: 35,
        genero: "masculino",
        profesion: "profesional_deportivo"
      },
      
      descripcion_segmento: "País: Costa Rica, Edad: 25-35, Género: masculino, Profesión: profesional_deportivo",
      
      mensajes: [
        {
          numero: 1,
          texto: "Supera tus límites con Nike X-Speed. Diseñados para conquistar Chirripó y la ciudad. ⚡🏃‍♂️",
          tono: "profesional",
          call_to_action: "Conquista cualquier terreno",
          emojis_usados: ["⚡", "🏃‍♂️"],
          justificacion: "Referencia al Chirripó (icono running CR)",
          generado_at: ISODate("2024-11-06T10:15:04Z"),
          tokens_estimados: 20
        },
        {
          numero: 2,
          texto: "¿Maratón o trail? X-Speed te lleva más lejos. Comodidad que transforma cada zancada 🔥",
          tono: "casual",
          call_to_action: "Llega más lejos",
          generado_at: ISODate("2024-11-06T10:15:04Z"),
          tokens_estimados: 18
        },
        {
          numero: 3,
          texto: "Tu próximo PR empieza aquí. Nike X-Speed: velocidad, comodidad, rendimiento. 🏆💪",
          tono: "motivacional",
          call_to_action: "Alcanza tu mejor marca",
          generado_at: ISODate("2024-11-06T10:15:04Z"),
          tokens_estimados: 16
        }
      ],
      
      timestamp: ISODate("2024-11-06T10:15:04Z")
    },
    
    {
      segmento_poblacional: {
        pais: "Costa Rica",
        edad_min: 18,
        edad_max: 24,
        genero: "femenino",
        profesion: "estudiante_universitaria"
      },
      
      descripcion_segmento: "País: Costa Rica, Edad: 18-24, Género: femenino, Profesión: estudiante_universitaria",
      
      mensajes: [
        {
          numero: 1,
          texto: "Corre con estilo 💕 X-Speed combina moda y rendimiento. Perfectos para tu vida activa ✨",
          tono: "profesional",
          generado_at: ISODate("2024-11-06T10:15:08Z"),
          tokens_estimados: 17
        },
        {
          numero: 2,
          texto: "De la U al gym sin cambiar de look 👟✨ Nike X-Speed, tu mejor compañero de aventuras",
          tono: "casual",
          generado_at: ISODate("2024-11-06T10:15:08Z"),
          tokens_estimados: 19
        },
        {
          numero: 3,
          texto: "¡Siente la libertad! X-Speed para chicas que no se detienen. Comodidad + estilo 🔥💪",
          tono: "motivacional",
          generado_at: ISODate("2024-11-06T10:15:08Z"),
          tokens_estimados: 18
        }
      ],
      
      timestamp: ISODate("2024-11-06T10:15:08Z")
    }
  ],
  
  resumen: {
    total_segmentos: 2,
    total_mensajes: 6,
    mensajes_por_segmento: 3,
    tokens_totales_estimados: 108,
    fecha_generacion: ISODate("2024-11-06T10:15:08Z")
  },
  
  created_at: ISODate("2024-11-06T10:15:08Z"),
  updated_at: ISODate("2024-11-06T10:15:08Z")
});


// ============================================
// ÍNDICES RECOMENDADOS
// ============================================

// contenido_generado
db.contenido_generado.createIndex({ campana_id: 1 });
db.contenido_generado.createIndex({ cliente_id: 1 });
db.contenido_generado.createIndex({ "metadata.formato": 1 });
db.contenido_generado.createIndex({ hashtags: 1 });
db.contenido_generado.createIndex({ "ai_metadata.provider": 1 });
db.contenido_generado.createIndex({ created_at: -1 });
db.contenido_generado.createIndex({ "aprobacion.estado": 1 });

// log_llamadas_api
db.log_llamadas_api.createIndex({ servicio: 1, created_at: -1 });
db.log_llamadas_api.createIndex({ "metadata.campana_id": 1 });
db.log_llamadas_api.createIndex({ "response.status": 1 });
db.log_llamadas_api.createIndex({ latencia_ms: -1 });

// bitacora_solicitudes
db.bitacora_solicitudes.createIndex({ "request.campana_id": 1 });
db.bitacora_solicitudes.createIndex({ tool_name: 1, created_at: -1 });
db.bitacora_solicitudes.createIndex({ "cliente_info.client_name": 1 });
db.bitacora_solicitudes.createIndex({ created_at: -1 });

// campana_mensajes
db.campana_mensajes.createIndex({ campana_id: 1 });
db.campana_mensajes.createIndex({ created_at: -1 });

// integraciones_api
db.integraciones_api.createIndex({ nombre: 1 });
db.integraciones_api.createIndex({ tipo: 1 });
db.integraciones_api.createIndex({ estado: 1 });