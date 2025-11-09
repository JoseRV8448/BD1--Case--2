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
 * COLLECTIONS: 6
 */

// ============================================
// COLLECTION 1: contenido_generado
// ============================================

db.contenido_generado.insertOne({
  campana_id: "camp_2025_tech_smartwatch",
  cliente_id: "cliente_samsung_latam",
  
  metadata: {
    formato: "imagen",
    mime_type: "image/jpeg",
    resolucion: "1080x1080",
    duracion_segundos: null,
    tamaño_bytes: 245000,
    url_almacenamiento: "s3://promptsales/content/img001.jpg",
    url_thumbnail: "s3://promptsales/content/thumbnails/img001_thumb.jpg"
  },
  
  descripcion_contenido: "Smartwatch deportivo Galaxy Watch Pro durante entrenamiento de ciclismo en montañas de Talamanca, Costa Rica",
  hashtags: ["#tech", "#cycling", "#costarica", "#fitness2025", "#samsung"],
  palabras_clave: ["smartwatch", "ciclismo", "montaña", "entrenamiento", "tecnologia"],
  
  embeddings: [0.12, 0.45, 0.78 /* ... 1533 valores más */],
  
  instrucciones_generacion: {
    prompt_original: "Genera imagen de smartwatch deportivo Samsung en ciclista profesional escalando montañas de Costa Rica. Mostrar pantalla del reloj con métricas. Ambiente de naturaleza y tecnología. Colores vibrantes del atardecer.",
    
    parametros_ai: {
      mensaje_core: "Promocionar Galaxy Watch Pro para atletas extremos costarricenses",
      tono: "tecnológico-inspiracional",
      estilo_visual: "fotografía deportiva tech",
      colores_principales: ["azul", "negro", "naranja"],
      elementos_requeridos: ["logo_samsung", "reloj_visible", "montañas_costarica"],
      elementos_prohibidos: ["otras_marcas", "texto_pequeño", "interiores"]
    },
    
    objetivos: ["destacar_tecnologia", "crear_aspiracion", "asociar_con_naturaleza"],
    restricciones: ["no_mencionar_competencia", "mostrar_pantalla", "colores_marca"],
    publico_objetivo: {
      edad: "28-45",
      genero: "ambos",
      ubicacion: "Costa Rica",
      intereses: ["ciclismo", "tecnologia", "naturaleza"]
    }
  },
  
  ai_metadata: {
    provider_ia: "OpenAI",
    modelo: "dall-e-3",
    version_modelo: "v1.0",
    tokens_usados: 920,
    costo_usd: 0.04,
    tiempo_generacion_ms: 8700,
    intentos: 1,
    fecha_generacion: ISODate("2025-01-15T10:30:00Z")
  },
  
  aprobacion: {
    estado: "aprobado",
    aprobado_por: "user_456",
    fecha_aprobacion: ISODate("2025-01-15T11:00:00Z"),
    comentarios: "Excelente composición tech-naturaleza"
  },
  
  metricas: {
    veces_usado: 8,
    campañas_asociadas: ["camp_2025_tech_smartwatch", "camp_2025_outdoor"],
    engagement_promedio: 0.052,
    ultima_actualizacion: ISODate("2025-01-20T10:00:00Z")
  },
  
  created_at: ISODate("2025-01-15T10:30:00Z"),
  updated_at: ISODate("2025-01-20T10:00:00Z")
});

// Ejemplo VIDEO
db.contenido_generado.insertOne({
  campana_id: "camp_2025_tech_smartwatch",
  cliente_id: "cliente_samsung_latam",
  
  metadata: {
    formato: "video",
    mime_type: "video/mp4",
    resolucion: "1920x1080",
    duracion_segundos: 30,
    tamaño_bytes: 12800000,
    url_almacenamiento: "s3://promptsales/content/video001.mp4",
    url_thumbnail: "s3://promptsales/content/thumbnails/video001_thumb.jpg",
    fps: 30,
    codec: "h264"
  },
  
  descripcion_contenido: "Video 30s atletas usando Galaxy Watch en diferentes deportes extremos de Costa Rica: surf, ciclismo montaña, trail running",
  hashtags: ["#samsung", "#extremesports", "#costarica", "#video"],
  palabras_clave: ["smartwatch", "deportes", "costa rica", "atletas", "aventura"],
  embeddings: [0.23, 0.56, 0.89 /* ... */],
  
  instrucciones_generacion: {
    prompt_original: "Video 30s atletas extremos CR con Galaxy Watch. Incluir surf Tamarindo, MTB volcán Arenal, trail Chirripó. Destacar métricas en pantalla. Música electrónica energética.",
    
    parametros_ai: {
      mensaje_core: "Mostrar versatilidad Galaxy Watch en deportes extremos",
      tono: "adrenalina-tech",
      estilo_visual: "cinematográfico deportivo",
      duracion_segundos: 30,
      transiciones: ["cortes_dinamicos", "slow_motion_metricas"],
      audio: {
        musica: "electronica_energetica",
        efectos_sonido: ["olas", "cadena_bici", "respiracion"],
        voz_narracion: false
      }
    },
    
    objetivos: ["mostrar_resistencia", "destacar_metricas", "crear_emocion"],
    restricciones: ["max_30s", "logo_final", "metricas_visibles"],
    publico_objetivo: {
      edad: "25-40",
      genero: "ambos",
      ubicacion: "Costa Rica"
    }
  },
  
  ai_metadata: {
    provider_ia: "RunwayML",
    modelo: "gen-2",
    tokens_usados: 3600,
    costo_usd: 1.25,
    tiempo_generacion_ms: 125000
  },
  
  created_at: ISODate("2025-01-16T14:00:00Z")
});


// ============================================
// COLLECTION 2: log_llamadas_api
// ============================================

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
      prompt: "Professional smartwatch on mountain cyclist in Costa Rica highlands",
      n: 1,
      size: "1024x1024",
      quality: "hd",
      style: "natural"
    },
    fecha_envio: ISODate("2025-01-15T10:30:00Z")
  },
  
  response: {
    status: 200,
    headers: {
      "content-type": "application/json",
      "x-request-id": "req_xyz456"
    },
    body: {
      created: 1737808200,
      data: [{
        url: "https://oaidalleapiprodscus.blob.core.windows.net/private/...",
        revised_prompt: "Professional photograph of cycling smartwatch..."
      }]
    },
    fecha_recepcion: ISODate("2025-01-15T10:30:08Z")
  },
  
  tiempo_ms: 8700,
  
  metadata: {
    campana_id: "camp_2025_tech_smartwatch",
    contenido_id: ObjectId("507f1f77bcf86cd799439011"),
    usuario_solicitante: "user_456",
    intento_numero: 1,
    resultado: "exitoso",
    tokens_usados: 920,
    costo_estimado_usd: 0.04
  },
  
  created_at: ISODate("2025-01-15T10:30:08Z")
});

db.log_llamadas_api.insertOne({
  servicio: "Adobe",
  endpoint: "/v1/creative/generate",
  
  request: {
    method: "POST",
    headers: {
      "Authorization": "Bearer adobe_token_***",
      "Content-Type": "application/json"
    },
    body: {
      template_id: "instagram_story_1080",
      brand_kit_id: "samsung_cr_brand",
      elements: {
        headline: "Tecnología en tu muñeca",
        description: "Galaxy Watch Pro",
        image_url: "s3://promptsales/content/img001.jpg",
        colors: {
          primary: "#1428A0",
          secondary: "#00D7FF"
        }
      },
      export_format: "png"
    },
    fecha_envio: ISODate("2025-01-15T10:31:00Z")
  },
  
  response: {
    status: 200,
    body: {
      design_id: "adobe_xyz123",
      url: "https://adobe.com/design/xyz123",
      export_url: "https://export.adobe.com/xyz123.png",
      thumbnail_url: "https://export.adobe.com/xyz123_thumb.png"
    },
    fecha_recepcion: ISODate("2025-01-15T10:31:02Z")
  },
  
  tiempo_ms: 2100,
  created_at: ISODate("2025-01-15T10:31:02Z")
});


// ============================================
// COLLECTION 3: configuracion_mcp
// ============================================

db.configuracion_mcp.insertOne({
  servidores: [
    {
      nombre: "content_mcp_server",
      descripcion: "Servidor MCP para búsqueda y generación de contenido",
      
      deployment: {
        host: "0.0.0.0",
        port: 3001,
        protocolo: "http",
        url_completa: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent",
        pod_name: "content-mcp-server-pod",
        replicas: 3
      },
      
      autenticacion: {
        tipo: "api_key",
        header_name: "X-MCP-API-Key",
        timeout_segundos: 30,
        reintentos_maximos: 3
      },
      
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
              ejemplo: "smartwatch en ciclismo montaña"
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
              ejemplo: "camp_2025_tech_smartwatch"
            },
            descripcion_campana: {
              tipo: "string",
              requerido: true,
              descripcion: "Descripción completa del producto/servicio a promocionar",
              ejemplo: "Smartwatch Samsung Galaxy Watch Pro para deportistas extremos"
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

IMPORTANTE: Los mensajes deben ser DIFERENTES entre sí.

Responde en formato JSON:
{
  "mensajes": [
    {
      "numero": 1,
      "texto": "mensaje adaptado al segmento",
      "tono": "profesional",
      "call_to_action": "texto_cta",
      "emojis_usados": ["🚴", "⌚"],
      "justificacion": "por qué este mensaje funciona"
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
      
      performance: {
        max_concurrent_requests: 50,
        timeout_global_ms: 30000,
        retry_policy: {
          max_intentos: 3,
          backoff_ms: [1000, 2000, 4000]
        }
      },
      
      health_check: {
        endpoint: "/health",
        intervalo_segundos: 30
      },
      
      estado: "activo",
      version: "1.0.0",
      updated_at: ISODate("2025-01-10T09:00:00Z")
    }
  ],
  
  clientes: [
    {
      nombre: "promptads_client",
      descripcion: "Cliente MCP desde PromptAds para búsqueda de contenido",
      
      conecta_a: {
        server_nombre: "content_mcp_server",
        url: "http://content-mcp-server:3001",
        namespace_k8s: "promptcontent"
      },
      
      autenticacion: {
        api_key: "promptads_api_key_***",
        header_name: "X-MCP-API-Key"
      },
      
      permisos: {
        tools_acceso: ["getContent"],
        tools_prohibidos: ["generateCampaignMessages"],
        rate_limit_personalizado: "200/minuto",
        max_requests_por_hora: 5000
      },
      
      configuracion_conexion: {
        timeout_ms: 5000,
        max_reintentos: 3,
        backoff_exponencial: true,
        keep_alive: true
      },
      
      metadata: {
        origen_namespace: "promptads",
        origen_pod_pattern: "promptads-api-*",
        proposito: "Búsqueda de contenido visual para campañas publicitarias"
      },
      
      estado: "activo",
      created_at: ISODate("2024-12-15T10:00:00Z")
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
        tools_acceso: ["generateCampaignMessages"],
        tools_prohibidos: ["getContent"],
        rate_limit_personalizado: "50/minuto",
        max_requests_por_hora: 2000
      },
      
      configuracion_conexion: {
        timeout_ms: 10000,
        max_reintentos: 2,
        backoff_exponencial: true
      },
      
      metadata: {
        origen_namespace: "promptcrm",
        origen_pod_pattern: "promptcrm-api-*",
        proposito: "Generación automática de mensajes para leads"
      },
      
      estado: "activo",
      created_at: ISODate("2024-12-15T10:00:00Z")
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
        tools_acceso: ["getContent", "generateCampaignMessages"],
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
      created_at: ISODate("2024-12-15T10:00:00Z")
    }
  ],
  
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
  updated_at: ISODate("2025-01-10T10:00:00Z")
});


// ============================================
// COLLECTION 4: bitacora_solicitudes
// ============================================

db.bitacora_solicitudes.insertOne({
  id_request: "req_20250115_001",
  tool_name: "generateCampaignMessages",
  
  request: {
    campana_id: "camp_2025_tech_smartwatch",
    descripcion_campana: "Smartwatch Samsung Galaxy Watch Pro para deportistas extremos costarricenses, resistencia agua IP68, GPS multideporte",
    
    publico_meta: {
      segmentos: [
        {
          pais: "Costa Rica",
          edad_min: 28,
          edad_max: 40,
          genero: "masculino",
          profesion: "atleta_profesional",
          intereses: ["ciclismo", "surf", "trail_running"],
          nivel_economico: "alto"
        },
        {
          pais: "Costa Rica",
          edad_min: 22,
          edad_max: 30,
          genero: "femenino",
          profesion: "instructor_fitness",
          intereses: ["yoga", "crossfit", "tecnologia"],
          nivel_economico: "medio-alto"
        },
        {
          pais: "Costa Rica",
          edad_min: 35,
          edad_max: 50,
          genero: "ambos",
          profesion: "ejecutivo_activo",
          intereses: ["salud", "outdoor", "gadgets"],
          nivel_economico: "alto"
        }
      ]
    },
    
    cantidad_mensajes: 3,
    tonos_requeridos: ["profesional", "casual", "motivacional"],
    
    timestamp_solicitud: ISODate("2025-01-15T10:15:00Z")
  },
  
  ai_request_body: {
    model: "gpt-4-turbo",
    messages: [
      {
        role: "system",
        content: "Eres un experto en marketing digital tech que crea mensajes personalizados por segmento."
      },
      {
        role: "user",
        content: `Genera 3 mensajes publicitarios para:

Producto/Campaña: Smartwatch Samsung Galaxy Watch Pro para deportistas extremos costarricenses, resistencia agua IP68, GPS multideporte

Segmento poblacional: País: Costa Rica, Edad: 28-40, Género: masculino, Profesión: atleta_profesional, Intereses: ciclismo, surf, trail_running, Nivel económico: alto

INSTRUCCIONES ESPECÍFICAS:
1. Adapta el lenguaje, tono y referencias culturales al segmento
2. Cada mensaje debe tener entre 50-150 caracteres
3. Incluye call-to-action relevante para el segmento
4. Usa emojis apropiados si el segmento es joven
5. Referencias culturales de Costa Rica
6. Evita clichés y frases genéricas

Tonos a usar: profesional, casual, motivacional

IMPORTANTE: Los mensajes deben ser DIFERENTES entre sí.

Responde en formato JSON:
{
  "mensajes": [
    {
      "numero": 1,
      "texto": "mensaje adaptado al segmento",
      "tono": "profesional",
      "call_to_action": "texto_cta",
      "emojis_usados": ["🚴", "⌚"],
      "justificacion": "por qué funciona"
    }
  ]
}`
      }
    ],
    temperature: 0.8,
    max_tokens: 500,
    response_format: { type: "json_object" }
  },
  
  ai_response: {
    mensajes: [
      {
        numero: 1,
        texto: "Domina Arenal y Tamarindo con Galaxy Watch Pro. IP68 + GPS multideporte para tus retos extremos 🏔️🌊",
        tono: "profesional",
        call_to_action: "Conquista cada terreno",
        emojis_usados: ["🏔️", "🌊"],
        justificacion: "Referencia a spots icónicos CR (Arenal, Tamarindo), destaca specs técnicas"
      },
      {
        numero: 2,
        texto: "¿Trail en Chirripó o surf en Jacó? Watch Pro se adapta a tu ritmo. Resistencia total 💪⌚",
        tono: "casual",
        call_to_action: "Cambia de deporte sin límites",
        emojis_usados: ["💪", "⌚"],
        justificacion: "Pregunta conecta con variedad deportiva del atleta CR"
      },
      {
        numero: 3,
        texto: "Tu próximo récord empieza en tu muñeca. Galaxy Watch Pro: precisión + resistencia extrema 🚴🏆",
        tono: "motivacional",
        call_to_action: "Supera tus límites",
        emojis_usados: ["🚴", "🏆"],
        justificacion: "Motivacional para atletas competitivos, enfoque en performance"
      }
    ]
  },
  
  metadata: {
    segmento_procesado: {
      pais: "Costa Rica",
      edad_min: 28,
      edad_max: 40,
      genero: "masculino",
      profesion: "atleta_profesional"
    },
    
    tokens_usados: 410,
    costo_estimado_usd: 0.0041,
    tiempo_generacion_ms: 4350,
    
    validaciones: {
      longitud_mensajes: "OK",
      tiene_call_to_action: "OK",
      sin_mencion_competencia: "OK",
      lenguaje_apropiado: "OK"
    },
    
    resultado: "exitoso",
    intentos: 1
  },
  
  cliente_info: {
    client_name: "promptcrm_client",
    origen_namespace: "promptcrm",
    ip_origen: "10.0.2.45"
  },
  
  created_at: ISODate("2025-01-15T10:15:04Z")
});

db.bitacora_solicitudes.insertOne({
  id_request: "req_20250115_002",
  tool_name: "generateCampaignMessages",
  
  request: {
    campana_id: "camp_2025_tech_smartwatch",
    descripcion_campana: "Smartwatch Samsung Galaxy Watch Pro",
    publico_meta: {
      segmentos: [
        { pais: "Costa Rica", edad_min: 28, edad_max: 40, genero: "masculino" },
        { pais: "Costa Rica", edad_min: 22, edad_max: 30, genero: "femenino" },
        { pais: "Costa Rica", edad_min: 35, edad_max: 50, genero: "ambos" }
      ]
    }
  },
  
  resultados_por_segmento: [
    {
      segmento_index: 0,
      segmento: { pais: "Costa Rica", edad_min: 28, edad_max: 40, genero: "masculino" },
      mensajes: [/* ... */],
      tokens_usados: 410,
      tiempo_ms: 4350
    },
    {
      segmento_index: 1,
      segmento: { pais: "Costa Rica", edad_min: 22, edad_max: 30, genero: "femenino" },
      mensajes: [/* ... */],
      tokens_usados: 425,
      tiempo_ms: 4600
    },
    {
      segmento_index: 2,
      segmento: { pais: "Costa Rica", edad_min: 35, edad_max: 50, genero: "ambos" },
      mensajes: [/* ... */],
      tokens_usados: 405,
      tiempo_ms: 4200
    }
  ],
  
  resumen: {
    total_segmentos: 3,
    total_mensajes: 9,
    tokens_totales: 1240,
    costo_total_usd: 0.0124,
    tiempo_total_ms: 13150
  },
  
  created_at: ISODate("2025-01-15T10:20:00Z")
});


// ============================================
// COLLECTION 5: integraciones_api
// ============================================

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

db.campana_mensajes.insertOne({
  campana_id: "camp_2025_tech_smartwatch",
  descripcion_campana: "Smartwatch Samsung Galaxy Watch Pro para deportistas extremos costarricenses",
  
  publico_meta_original: {
    segmentos: [
      {
        pais: "Costa Rica",
        edad_min: 28,
        edad_max: 40,
        genero: "masculino",
        profesion: "atleta_profesional"
      },
      {
        pais: "Costa Rica",
        edad_min: 22,
        edad_max: 30,
        genero: "femenino",
        profesion: "instructor_fitness"
      }
    ]
  },
  
  bitacora_por_segmento: [
    {
      segmento_poblacional: {
        pais: "Costa Rica",
        edad_min: 28,
        edad_max: 40,
        genero: "masculino",
        profesion: "atleta_profesional"
      },
      
      descripcion_segmento: "País: Costa Rica, Edad: 28-40, Género: masculino, Profesión: atleta_profesional",
      
      mensajes: [
        {
          numero: 1,
          texto: "Domina Arenal y Tamarindo con Galaxy Watch Pro. IP68 + GPS multideporte 🏔️🌊",
          tono: "profesional",
          call_to_action: "Conquista cada terreno",
          emojis_usados: ["🏔️", "🌊"],
          justificacion: "Referencia a spots icónicos CR",
          generado_at: ISODate("2025-01-15T10:15:04Z"),
          tokens_estimados: 18
        },
        {
          numero: 2,
          texto: "¿Trail en Chirripó o surf en Jacó? Watch Pro se adapta a tu ritmo 💪⌚",
          tono: "casual",
          call_to_action: "Cambia de deporte sin límites",
          generado_at: ISODate("2025-01-15T10:15:04Z"),
          tokens_estimados: 16
        },
        {
          numero: 3,
          texto: "Tu próximo récord empieza en tu muñeca. Galaxy Watch Pro 🚴🏆",
          tono: "motivacional",
          call_to_action: "Supera tus límites",
          generado_at: ISODate("2025-01-15T10:15:04Z"),
          tokens_estimados: 14
        }
      ],
      
      timestamp: ISODate("2025-01-15T10:15:04Z")
    },
    
    {
      segmento_poblacional: {
        pais: "Costa Rica",
        edad_min: 22,
        edad_max: 30,
        genero: "femenino",
        profesion: "instructor_fitness"
      },
      
      descripcion_segmento: "País: Costa Rica, Edad: 22-30, Género: femenino, Profesión: instructor_fitness",
      
      mensajes: [
        {
          numero: 1,
          texto: "Tecnología + estilo 💫 Galaxy Watch Pro para tu vida fitness activa ⌚✨",
          tono: "profesional",
          generado_at: ISODate("2025-01-15T10:15:08Z"),
          tokens_estimados: 15
        },
        {
          numero: 2,
          texto: "De la clase al trail sin cambiar de look 💪 Watch Pro tu compañero perfecto",
          tono: "casual",
          generado_at: ISODate("2025-01-15T10:15:08Z"),
          tokens_estimados: 17
        },
        {
          numero: 3,
          texto: "¡Impulsa tu rendimiento! Galaxy Watch Pro: métricas pro + diseño elegante 🔥⌚",
          tono: "motivacional",
          generado_at: ISODate("2025-01-15T10:15:08Z"),
          tokens_estimados: 16
        }
      ],
      
      timestamp: ISODate("2025-01-15T10:15:08Z")
    }
  ],
  
  resumen: {
    total_segmentos: 2,
    total_mensajes: 6,
    mensajes_por_segmento: 3,
    tokens_totales_estimados: 96,
    fecha_generacion: ISODate("2025-01-15T10:15:08Z")
  },
  
  created_at: ISODate("2025-01-15T10:15:08Z"),
  updated_at: ISODate("2025-01-15T10:15:08Z")
});


// ============================================
// ÍNDICES RECOMENDADOS
// ============================================

// contenido_generado
db.contenido_generado.createIndex({ campana_id: 1 });
db.contenido_generado.createIndex({ cliente_id: 1 });
db.contenido_generado.createIndex({ "metadata.formato": 1 });
db.contenido_generado.createIndex({ hashtags: 1 });
db.contenido_generado.createIndex({ "ai_metadata.provider_ia": 1 });
db.contenido_generado.createIndex({ created_at: -1 });
db.contenido_generado.createIndex({ "aprobacion.estado": 1 });

// log_llamadas_api
db.log_llamadas_api.createIndex({ servicio: 1, created_at: -1 });
db.log_llamadas_api.createIndex({ "metadata.campana_id": 1 });
db.log_llamadas_api.createIndex({ "response.status": 1 });
db.log_llamadas_api.createIndex({ tiempo_ms: -1 });

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
