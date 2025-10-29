// ========================================
// Diseño de Base de Datos MongoDB para PromptContent
// Versión: 4.0 - Revisado según requisitos del profesor
// Fecha: 2025-10-27
// ========================================

// ========================================
// DECISIONES DE DISEÑO CRÍTICAS
// ========================================
// 1. Usuarios/Suscripciones: CENTRALIZADAS en PromptSales (PostgreSQL)
//    - PromptContent solo guarda referencias (id_cliente, id_usuario)
//    - Justificación: Single Sign-On, evitar duplicación, gestión unificada
//
// 2. Vectorización: PINECONE (opción elegida)
//    - Alternativas evaluadas: Faiss (requiere infraestructura local), pgvector (limitado)
//    - Justificación: Escalable, managed service, mejor para búsqueda semántica
//    - Almacenamos vector_id_pinecone en MongoDB, vector real en Pinecone
//
// 3. Almacenamiento de imágenes: AWS S3 + CloudFront CDN
//    - MongoDB solo guarda URLs
//    - Justificación: Optimización de costos, velocidad de entrega global
//
// 4. API Externa con POST: CANVA API (cumple requisito)
//    - Autenticación OAuth2 via POST
//    - Alternativa considerada: Adobe Creative Cloud API
// ========================================

// ========================================
// REQUISITOS DEL DOCUMENTO
// ========================================
// ✅ Mínimo 100 imágenes generadas algorítmicamente
// ✅ Descripciones amplias y coherentes
// ✅ Hashtags clasificadores
// ✅ Indexación con base de datos vectorial (Pinecone)
// ✅ API externa con autenticación POST (Canva API)
// ✅ MCP Server con 2 tools (getContent, generateCampaignContent)
// ========================================

// ========================================
// Colección: imagenes
// Requisito: Mínimo 100 imágenes
// Distribución sugerida: 10 categorías × 10 imágenes = 100 total
// ========================================
{
  "_id": ObjectId("67123abc456def789012345"),
  
  // URLs y almacenamiento
  "url_imagen": "https://cdn.promptcontent.com/2025/10/img_sport_001.jpg",
  "url_thumbnail": "https://cdn.promptcontent.com/2025/10/thumb_sport_001.jpg",
  
  // Descripción para vectorización (crítico para búsqueda semántica)
  "descripcion": "Atleta profesional masculino de 30 años corriendo en una pista de atletismo al amanecer, con vestimenta deportiva de alta tecnología en colores azul y negro. La imagen transmite determinación, velocidad y profesionalismo. Fondo desenfocado con estadio moderno. Ideal para campañas de productos deportivos de alto rendimiento, suplementos nutricionales o tecnología wearable.",
  
  // Hashtags clasificadores (8-12 por imagen)
  "hashtags": [
    "#deportes",
    "#running",
    "#atletismo",
    "#fitness",
    "#profesional",
    "#rendimiento",
    "#tecnologiadeportiva",
    "#salud",
    "#motivacion",
    "#lifestyle"
  ],
  
  // Categoría principal (1 de 10 categorías predefinidas)
  "categoria": "articulos_deportivos",
  // Categorías: articulos_deportivos, tecnologia, moda, alimentos_bebidas,
  //             servicios_financieros, salud_bienestar, educacion, hogar_decoracion,
  //             viajes_turismo, entretenimiento
  
  // Vectorización con Pinecone
  "vector_id_pinecone": "img_sport_001_vec",
  "vector_namespace": "promptcontent_production",
  "vector_metadata": {
    "indexado": true,
    "fecha_indexacion": ISODate("2025-10-18T10:00:00Z"),
    "dimension": 1536, // OpenAI text-embedding-ada-002
    "ultimo_update": ISODate("2025-10-18T10:00:00Z")
  },
  // NOTA: El vector real (array de 1536 floats) está en Pinecone, NO aquí
  
  // Metadata técnica
  "metadata": {
    "formato": "jpg",
    "tamano_bytes": 2048576,
    "dimensiones": {
      "ancho": 1920,
      "alto": 1080,
      "aspect_ratio": "16:9"
    },
    "origen": "stock_photography", // generado_ai | stock_photography | usuario_upload
    "proveedor": "Shutterstock",
    "licencia": "comercial_unlimited",
    "id_licencia": "SHTR-2024-12345",
    "keywords_originales": ["athlete", "running", "professional", "sports"]
  },
  
  // Trazabilidad
  "fecha_creacion": ISODate("2025-10-18T10:00:00Z"),
  "fecha_actualizacion": ISODate("2025-10-18T10:00:00Z"),
  "creado_por": "sistema_carga_inicial", // o id_usuario
  "actualizado_por": null,
  
  // Estado del contenido
  "estado": "activo", // activo | inactivo | pendiente_revision | rechazado
  "aprobaciones": {
    "requiere_aprobacion": false,
    "aprobado_por": null,
    "fecha_aprobacion": null,
    "comentarios": null
  },
  
  // Relaciones y uso
  "id_cliente": null, // null = biblioteca general, o "cliente_123" = cliente específico
  "campanas_asociadas": ["campana_001", "campana_005"],
  "veces_usada": 12,
  "ultima_vez_usada": ISODate("2025-10-20T14:30:00Z"),
  
  // Analytics
  "metricas_uso": {
    "vistas_previas": 45,
    "descargas": 12,
    "guardado_en_favoritos": 3
  }
}

// ========================================
// Colección: servicios_terceros
// Requisito: Incluir API externa con autenticación POST
// ========================================
{
  "_id": ObjectId("67123abc456def789012346"),
  
  "nombre_servicio": "Canva API",
  "descripcion": "API para creación y edición de diseños gráficos",
  "url_base": "https://api.canva.com/v1",
  "documentacion_url": "https://www.canva.dev/docs/connect/",
  "proveedor": "Canva Pty Ltd",
  
  // Métodos disponibles
  "metodos_disponibles": [
    {
      "nombre": "createDesign",
      "descripcion": "Crea un nuevo diseño desde plantilla",
      "endpoint": "/designs",
      "metodo_http": "POST", // ✅ POST REQUERIDO
      "parametros": {
        "design_type": {
          "tipo": "string",
          "requerido": true,
          "valores_permitidos": ["instagram-post", "facebook-post", "banner"]
        },
        "title": {
          "tipo": "string",
          "requerido": false
        },
        "template_id": {
          "tipo": "string",
          "requerido": false
        }
      },
      "respuesta_ejemplo": {
        "design_id": "DAFxxxxx",
        "edit_url": "https://www.canva.com/design/...",
        "status": "created"
      },
      "rate_limit": "100 requests/hour"
    },
    {
      "nombre": "exportDesign",
      "descripcion": "Exporta diseño como imagen",
      "endpoint": "/designs/{design_id}/export",
      "metodo_http": "POST",
      "parametros": {
        "format": {
          "tipo": "string",
          "valores_permitidos": ["png", "jpg", "pdf"]
        },
        "quality": {
          "tipo": "string",
          "valores_permitidos": ["low", "medium", "high"]
        }
      }
    },
    {
      "nombre": "listDesigns",
      "descripcion": "Lista diseños del usuario",
      "endpoint": "/designs",
      "metodo_http": "GET",
      "parametros": {
        "page": {"tipo": "integer"},
        "limit": {"tipo": "integer", "max": 100}
      }
    }
  ],
  
  // Autenticación OAuth2 (POST requerido) ✅
  "autenticacion": {
    "tipo": "oauth2",
    "flujo": "client_credentials", // o "authorization_code" para usuarios
    "metodo_autenticacion": "POST", // ✅ REQUISITO CUMPLIDO
    
    // Endpoints de autenticación
    "token_endpoint": "https://api.canva.com/oauth/token",
    "authorize_endpoint": "https://www.canva.com/api/oauth/authorize",
    "revoke_endpoint": "https://api.canva.com/oauth/revoke",
    
    // Parámetros para obtener token (POST body)
    "parametros_token": {
      "grant_type": "client_credentials",
      "client_id": "referencia_a_secret_cifrado", // Ver collection: credenciales_cifradas
      "client_secret": "referencia_a_secret_cifrado",
      "scope": "design:read design:write asset:read"
    },
    
    // Ubicación del token en requests
    "ubicacion_token": "header",
    "header_name": "Authorization",
    "header_format": "Bearer {token}",
    
    // Gestión de tokens
    "token_actual": {
      "access_token_ref": "credencial_canva_token_001", // Referencia a credenciales_cifradas
      "expires_at": ISODate("2025-10-22T18:00:00Z"),
      "refresh_token_ref": null, // client_credentials no usa refresh
      "scopes": ["design:read", "design:write", "asset:read"]
    }
  },
  
  // Credenciales cifradas (X.509 en master DB)
  // NOTA: Los valores reales están en collection separada con cifrado
  "credenciales_cifradas": {
    "client_id_ref": "canva_client_id_encrypted_001",
    "client_secret_ref": "canva_client_secret_encrypted_001",
    "metodo_cifrado": "X.509",
    "certificado_usado": "promptcontent_prod_cert_2025"
  },
  
  // Límites y cuotas
  "limites": {
    "requests_por_minuto": 100,
    "requests_por_hora": 5000,
    "requests_por_dia": 50000,
    "concurrent_requests": 10,
    "max_export_size_mb": 25,
    "periodo_reset": "hora_en_punto" // 00:00 de cada hora
  },
  
  // Estado y monitoreo
  "estado": "activo", // activo | inactivo | mantenimiento | error
  "health_check": {
    "url": "https://api.canva.com/v1/health",
    "intervalo_minutos": 5,
    "ultima_verificacion": ISODate("2025-10-22T10:25:00Z"),
    "ultimo_estado": "healthy"
  },
  
  // Estadísticas de uso
  "estadisticas": {
    "fecha_primera_conexion": ISODate("2025-01-15T00:00:00Z"),
    "fecha_ultima_conexion": ISODate("2025-10-22T10:20:00Z"),
    "total_llamadas_exitosas": 15678,
    "total_llamadas_fallidas": 234,
    "tiempo_promedio_respuesta_ms": 456,
    "costo_acumulado_mes_actual": 234.56,
    "ultima_renovacion_token": ISODate("2025-10-22T06:00:00Z")
  },
  
  // Configuración de reintentos
  "retry_config": {
    "max_retries": 3,
    "backoff_strategy": "exponential",
    "initial_delay_ms": 1000,
    "max_delay_ms": 10000,
    "retry_on_status": [429, 500, 502, 503, 504]
  },
  
  // Webhooks (si el servicio los soporta)
  "webhooks": {
    "soporta_webhooks": true,
    "eventos_suscritos": ["design.published", "export.completed"],
    "url_callback": "https://promptcontent.com/api/webhooks/canva",
    "secret_verificacion_ref": "canva_webhook_secret_001"
  }
}

// ========================================
// SERVICIO ADICIONAL: OpenAI API (ya incluido originalmente)
// ========================================
{
  "_id": ObjectId("67123abc456def789012347"),
  "nombre_servicio": "OpenAI API",
  "descripcion": "API para generación de texto, imágenes y embeddings",
  "url_base": "https://api.openai.com/v1",
  
  "metodos_disponibles": [
    {
      "nombre": "generateImage",
      "endpoint": "/images/generations",
      "metodo_http": "POST",
      "parametros": {
        "prompt": {"tipo": "string", "requerido": true},
        "n": {"tipo": "integer", "default": 1, "max": 10},
        "size": {"tipo": "string", "valores_permitidos": ["256x256", "512x512", "1024x1024"]}
      }
    },
    {
      "nombre": "createEmbedding",
      "endpoint": "/embeddings",
      "metodo_http": "POST",
      "parametros": {
        "model": {"tipo": "string", "default": "text-embedding-ada-002"},
        "input": {"tipo": "string", "requerido": true}
      }
    },
    {
      "nombre": "chatCompletion",
      "endpoint": "/chat/completions",
      "metodo_http": "POST",
      "parametros": {
        "model": {"tipo": "string", "requerido": true},
        "messages": {"tipo": "array", "requerido": true},
        "temperature": {"tipo": "float", "default": 0.7}
      }
    }
  ],
  
  "autenticacion": {
    "tipo": "bearer_token",
    "metodo_autenticacion": "header",
    "header_name": "Authorization",
    "header_format": "Bearer {api_key}",
    "api_key_ref": "openai_api_key_encrypted_001"
  },
  
  "limites": {
    "requests_por_minuto": 3000,
    "tokens_por_minuto": 90000,
    "tokens_por_dia": 2000000
  },
  
  "estado": "activo"
}

// ========================================
// Colección: credenciales_cifradas
// Almacena credenciales con cifrado X.509
// ========================================
{
  "_id": "canva_client_id_encrypted_001",
  "servicio": "Canva API",
  "tipo_credencial": "client_id",
  "valor_cifrado": "0x4A5F3E2D1C0B9A8F...", // Cifrado con certificado X.509
  "certificado_id": "promptcontent_prod_cert_2025",
  "algoritmo_cifrado": "RSA-2048",
  "fecha_cifrado": ISODate("2025-01-15T00:00:00Z"),
  "fecha_expiracion": ISODate("2026-01-15T00:00:00Z"),
  "requiere_rotacion": false,
  "ultima_rotacion": null,
  "creado_por": "admin_user_001"
}

// ========================================
// Colección: bitacora_solicitudes
// Registro de todas las llamadas API/MCP
// ========================================
{
  "_id": ObjectId("67123abc456def789012348"),
  
  "tipo_solicitud": "generacion_contenido", // generacion_contenido | busqueda | modificacion | exportacion
  "servicio_utilizado": "Canva API", // OpenAI | Canva | Adobe | Interno | MCP
  
  // Datos del request
  "request": {
    "metodo": "POST",
    "endpoint": "/designs",
    "url_completa": "https://api.canva.com/v1/designs",
    "parametros": {
      "design_type": "instagram-post",
      "title": "Campaña Verano 2025"
    },
    "headers": {
      "Authorization": "Bearer [REDACTED]",
      "Content-Type": "application/json",
      "User-Agent": "PromptContent/1.0"
    },
    "body_size_bytes": 256
  },
  
  // Datos del response
  "response": {
    "codigo_estado": 201,
    "mensaje_estado": "Created",
    "datos": {
      "design_id": "DAFxxxxx123",
      "edit_url": "https://www.canva.com/design/DAFxxxxx123/edit"
    },
    "headers": {
      "X-Request-Id": "req_abc123",
      "X-RateLimit-Remaining": "95"
    },
    "body_size_bytes": 512,
    "tiempo_respuesta_ms": 1250
  },
  
  // Resultado
  "resultado": "exitoso", // exitoso | error | timeout | rate_limited
  "mensaje_error": null,
  "codigo_error": null,
  
  // Contexto
  "id_usuario": "usuario_456",
  "id_cliente": "cliente_123",
  "id_campana": "campana_001",
  "plataforma_origen": "portal_web", // portal_web | api | mcp_server | scheduled_job
  
  // Costos
  "tokens_consumidos": null, // Para APIs que usan tokens
  "costo_estimado_usd": 0.05, // Basado en pricing del servicio
  "costo_real_usd": null, // Cuando se factura realmente
  
  // Trazabilidad
  "fecha_hora": ISODate("2025-10-22T10:30:00Z"),
  "ip_origen": "192.168.1.100",
  "session_id": "sess_abc123",
  "request_id": "req_xyz789",
  "trace_id": "trace_001_abc", // Para distributed tracing
  
  // Almacenamiento del resultado (si aplica)
  "almacenamiento": {
    "ubicacion": "s3",
    "bucket": "promptcontent-production",
    "ruta": "/2025/10/22/design_DAFxxxxx123.png",
    "tamano_bytes": 2048576
  },
  
  // Metadata adicional
  "metadata": {
    "intento_numero": 1,
    "total_intentos": 1,
    "fue_retry": false,
    "cached_response": false,
    "cache_hit": false
  }
}

// ========================================
// Colección: tipos_contenido
// Catálogo de tipos de contenido soportados
// ========================================
{
  "_id": ObjectId("67123abc456def789012349"),
  
  "nombre_tipo": "imagen_publicitaria",
  "descripcion": "Imágenes optimizadas para campañas publicitarias en redes sociales",
  "categoria": "marketing_digital",
  
  // Formatos técnicos
  "formatos_permitidos": ["jpg", "png", "webp"],
  "formato_recomendado": "webp",
  
  // Especificaciones por plataforma
  "dimensiones_recomendadas": [
    {
      "plataforma": "instagram_feed",
      "nombre_visualizacion": "Instagram Feed (1:1)",
      "ancho": 1080,
      "alto": 1080,
      "aspect_ratio": "1:1",
      "tamano_min_mb": 0.1,
      "tamano_max_mb": 8
    },
    {
      "plataforma": "instagram_stories",
      "nombre_visualizacion": "Instagram Stories (9:16)",
      "ancho": 1080,
      "alto": 1920,
      "aspect_ratio": "9:16",
      "tamano_max_mb": 8
    },
    {
      "plataforma": "facebook_feed",
      "nombre_visualizacion": "Facebook Feed",
      "ancho": 1200,
      "alto": 630,
      "aspect_ratio": "1.91:1",
      "tamano_max_mb": 8
    },
    {
      "plataforma": "linkedin_post",
      "nombre_visualizacion": "LinkedIn Post",
      "ancho": 1200,
      "alto": 627,
      "aspect_ratio": "1.91:1",
      "tamano_max_mb": 5
    },
    {
      "plataforma": "twitter_post",
      "nombre_visualizacion": "Twitter/X Post",
      "ancho": 1200,
      "alto": 675,
      "aspect_ratio": "16:9",
      "tamano_max_mb": 5
    }
  ],
  
  // Restricciones
  "restricciones": {
    "tamano_maximo_mb": 8,
    "tamano_minimo_mb": 0.05,
    "resolucion_minima_px": 600,
    "duracion_maxima_segundos": null, // No aplica para imágenes
    "requiere_derechos_comerciales": true,
    "permite_marcas_agua": false
  },
  
  // Validaciones
  "validaciones": {
    "verificar_calidad": true,
    "minimo_dpi": 72,
    "recomendado_dpi": 300,
    "verificar_contenido_inapropiado": true,
    "verificar_texto_legible": true
  },
  
  // Uso
  "casos_uso": [
    "Campañas de producto",
    "Anuncios promocionales",
    "Contenido de marca",
    "Posts orgánicos"
  ],
  
  "estado": "activo"
}

// ========================================
// Colección: mcp_servers
// Configuración de Model Context Protocol Servers
// ========================================
{
  "_id": ObjectId("67123abc456def78901234a"),
  
  "nombre_servidor": "content_generator_mcp",
  "descripcion": "Servidor MCP para generación y búsqueda de contenido",
  "version": "1.0.0",
  "url_servidor": "http://mcp-content-server:3000",
  "health_check_endpoint": "/health",
  
  // Tools disponibles (2 requeridos por documento)
  "tools": [
    {
      "nombre": "getContent",
      "descripcion": "Recibe una descripción textual y retorna imágenes que coinciden con hashtags asociados",
      
      // Input Schema (JSON Schema)
      "input_schema": {
        "type": "object",
        "properties": {
          "descripcion": {
            "type": "string",
            "description": "Descripción del contenido visual buscado",
            "minLength": 10,
            "maxLength": 500,
            "example": "persona profesional trabajando en oficina moderna"
          },
          "cantidad": {
            "type": "integer",
            "description": "Número de imágenes a retornar",
            "default": 5,
            "minimum": 1,
            "maximum": 20
          },
          "categoria": {
            "type": "string",
            "description": "Categoría para filtrar resultados",
            "enum": [
              "articulos_deportivos",
              "tecnologia",
              "moda",
              "alimentos_bebidas",
              "servicios_financieros",
              "salud_bienestar",
              "educacion",
              "hogar_decoracion",
              "viajes_turismo",
              "entretenimiento"
            ],
            "example": "tecnologia"
          },
          "threshold_similitud": {
            "type": "number",
            "description": "Umbral mínimo de similitud (0-1)",
            "default": 0.7,
            "minimum": 0.0,
            "maximum": 1.0
          }
        },
        "required": ["descripcion"]
      },
      
      // Output Schema
      "output_schema": {
        "type": "object",
        "properties": {
          "total_resultados": {
            "type": "integer",
            "description": "Número total de imágenes encontradas"
          },
          "resultados": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "imagen_id": {"type": "string"},
                "url": {"type": "string", "format": "uri"},
                "url_thumbnail": {"type": "string", "format": "uri"},
                "descripcion": {"type": "string"},
                "hashtags": {
                  "type": "array",
                  "items": {"type": "string"}
                },
                "categoria": {"type": "string"},
                "score_similitud": {
                  "type": "number",
                  "description": "Puntuación de similitud (0-1)"
                },
                "metadata": {
                  "type": "object",
                  "properties": {
                    "formato": {"type": "string"},
                    "dimensiones": {"type": "object"}
                  }
                }
              }
            }
          },
          "tiempo_busqueda_ms": {"type": "integer"},
          "fuente_vectorial": {"type": "string"}
        }
      },
      
      // Metadata del tool
      "metadata": {
        "cache_ttl_segundos": 3600,
        "timeout_ms": 5000,
        "max_retries": 2,
        "idempotente": true
      }
    },
    
    {
      "nombre": "generateCampaignContent",
      "descripcion": "Recibe descripción de campaña y público meta, almacena la solicitud y genera una bitácora de EXACTAMENTE 3 MENSAJES por población objetivo",
      
      // Input Schema
      "input_schema": {
        "type": "object",
        "properties": {
          "descripcion_campana": {
            "type": "string",
            "description": "Descripción general de la campaña",
            "minLength": 20,
            "maxLength": 1000,
            "example": "Lanzamiento de nueva línea de productos deportivos para runners profesionales"
          },
          "publico_meta": {
            "type": "array",
            "description": "Segmentos de audiencia objetivo",
            "minItems": 1,
            "maxItems": 10,
            "items": {
              "type": "object",
              "properties": {
                "segmento": {
                  "type": "string",
                  "description": "Nombre del segmento",
                  "example": "jovenes_18_25"
                },
                "caracteristicas": {
                  "type": "object",
                  "properties": {
                    "edad_min": {"type": "integer"},
                    "edad_max": {"type": "integer"},
                    "genero": {"type": "string", "enum": ["masculino", "femenino", "todos"]},
                    "intereses": {"type": "array", "items": {"type": "string"}},
                    "nivel_socioeconomico": {"type": "string"},
                    "ubicacion": {"type": "string"}
                  }
                },
                "tono_preferido": {
                  "type": "string",
                  "enum": ["informal", "profesional", "formal", "inspiracional"],
                  "default": "profesional"
                }
              },
              "required": ["segmento", "caracteristicas"]
            }
          },
          "mensaje_base": {
            "type": "string",
            "description": "Mensaje principal de la campaña a adaptar",
            "example": "Descubre el futuro del running profesional"
          },
          "idioma": {
            "type": "string",
            "default": "es",
            "enum": ["es", "en", "pt"]
          }
        },
        "required": ["descripcion_campana", "publico_meta"]
      },
      
      // Output Schema
      "output_schema": {
        "type": "object",
        "properties": {
          "bitacora_id": {
            "type": "string",
            "description": "ID del log de campaña creado"
          },
          "id_campana": {
            "type": "string",
            "description": "ID de campaña generado"
          },
          "mensajes_generados": {
            "type": "array",
            "description": "Mensajes por segmento de audiencia",
            "items": {
              "type": "object",
              "properties": {
                "segmento": {"type": "string"},
                "mensajes": {
                  "type": "array",
                  "description": "EXACTAMENTE 3 mensajes por segmento",
                  "minItems": 3,
                  "maxItems": 3,
                  "items": {
                    "type": "object",
                    "properties": {
                      "orden": {
                        "type": "integer",
                        "enum": [1, 2, 3]
                      },
                      "mensaje": {"type": "string"},
                      "hashtags_sugeridos": {
                        "type": "array",
                        "items": {"type": "string"},
                        "minItems": 3,
                        "maxItems": 8
                      },
                      "tono": {"type": "string"},
                      "llamada_accion": {"type": "string"}
                    }
                  }
                },
                "caracteristicas_segmento": {"type": "object"}
              }
            }
          },
          "total_mensajes": {
            "type": "integer",
            "description": "Total de mensajes generados (debe ser publico_meta.length * 3)"
          },
          "tokens_consumidos": {"type": "integer"},
          "tiempo_generacion_ms": {"type": "integer"}
        }
      },
      
      // Metadata del tool
      "metadata": {
        "cache_ttl_segundos": 0, // No cachear (siempre generar nuevo)
        "timeout_ms": 15000,
        "max_retries": 1,
        "idempotente": false,
        "requiere_almacenamiento": true, // Debe crear documento en logs_campanas
        "genera_3_mensajes_por_poblacion": true // ✅ REQUISITO CRÍTICO
      }
    }
  ],
  
  // Estado del servidor
  "estado": "activo", // activo | inactivo | mantenimiento | error
  "fecha_deployment": ISODate("2025-10-18T10:00:00Z"),
  "ultima_actualizacion": ISODate("2025-10-22T08:00:00Z"),
  
  // Métricas de uso
  "metricas": {
    "llamadas_totales": 15678,
    "llamadas_exitosas": 15345,
    "llamadas_fallidas": 333,
    "tiempo_promedio_respuesta_ms": 850,
    "p95_response_time_ms": 1250,
    "p99_response_time_ms": 2100,
    "tasa_exito": 0.9787,
    "ultima_llamada": ISODate("2025-10-22T10:29:45Z")
  },
  
  // Configuración de recursos
  "recursos": {
    "max_concurrent_requests": 50,
    "queue_size": 100,
    "memory_limit_mb": 2048,
    "cpu_limit": "2 cores"
  },
  
  // Dependencias
  "dependencias": {
    "mongodb": "localhost:27017",
    "pinecone": "api.pinecone.io",
    "openai": "api.openai.com",
    "redis": "redis-cache:6379"
  }
}

// ========================================
// Colección: logs_campanas
// Registro de contenido generado para campañas
// ========================================
{
  "_id": ObjectId("67123abc456def78901234b"),
  
  "id_campana": "campana_001",
  "nombre_campana": "Lanzamiento Producto X - Verano 2025",
  "id_cliente": "cliente_123",
  "nombre_cliente": "Empresa Deportes SA",
  
  // Contenido generado
  "contenido_generado": [
    {
      "tipo": "imagen",
      "id_contenido": ObjectId("67123abc456def789012345"),
      "nombre_archivo": "img_sport_001.jpg",
      "url": "https://cdn.promptcontent.com/2025/10/img_sport_001.jpg",
      "version": 1,
      "plataforma_destino": "instagram_feed",
      "aprobado": true,
      "fecha_aprobacion": ISODate("2025-10-18T14:30:00Z"),
      "aprobado_por": "usuario_789",
      "comentarios_aprobacion": "Excelente, usar en fase 1"
    },
    {
      "tipo": "texto",
      "id_contenido": ObjectId("67123abc456def78901234c"),
      "contenido": "🏃‍♂️ ¡Descubre la nueva tendencia!...",
      "version": 2,
      "aprobado": true,
      "fecha_aprobacion": ISODate("2025-10-18T15:00:00Z"),
      "aprobado_por": "usuario_789"
    }
  ],
  
  // MENSAJES POR POBLACIÓN (3 mensajes cada uno) ✅
  "mensajes_poblacion": [
    {
      "segmento": "jovenes_18_25",
      "caracteristicas": {
        "edad_min": 18,
        "edad_max": 25,
        "intereses": ["fitness", "redes_sociales", "tecnologia"],
        "nivel_socioeconomico": "medio-alto"
      },
      "mensajes": [
        {
          "orden": 1,
          "mensaje": "🔥 ¡Descubre la nueva tendencia que está revolucionando el running! Tecnología de punta para atletas que buscan romper sus límites. #NoLimits",
          "tono": "informal",
          "hashtags": ["#NuevoProducto", "#Tendencia2025", "#RunningTech", "#NoLimits"],
          "llamada_accion": "Descubre más",
          "plataforma_recomendada": "instagram"
        },
        {
          "orden": 2,
          "mensaje": "💪 Tu entrenamiento nunca fue tan inteligente. Conecta, mide, supera. La próxima generación de equipamiento deportivo ya está aquí.",
          "tono": "informal",
          "hashtags": ["#SmartRunning", "#TechFitness", "#NextLevel", "#Innovation"],
          "llamada_accion": "Ver colección",
          "plataforma_recomendada": "instagram"
        },
        {
          "orden": 3,
          "mensaje": "🏆 Los récords se rompen con preparación. Y nosotros te damos las herramientas. ¿Listo para tu mejor versión?",
          "tono": "inspiracional",
          "hashtags": ["#Records", "#BestVersion", "#Athletes", "#Performance"],
          "llamada_accion": "Únete ahora",
          "plataforma_recomendada": "tiktok"
        }
      ]
    },
    {
      "segmento": "adultos_26_40",
      "caracteristicas": {
        "edad_min": 26,
        "edad_max": 40,
        "intereses": ["salud", "bienestar", "balance_vida"],
        "nivel_socioeconomico": "medio-alto-alto"
      },
      "mensajes": [
        {
          "orden": 1,
          "mensaje": "Innovación que mejora tu vida diaria. Diseñado para profesionales que valoran su tiempo y su salud. Descubre el equilibrio perfecto entre rendimiento y bienestar.",
          "tono": "profesional",
          "hashtags": ["#Innovacion", "#CalidadDeVida", "#Bienestar", "#Profesionales"],
          "llamada_accion": "Conoce más",
          "plataforma_recomendada": "linkedin"
        },
        {
          "orden": 2,
          "mensaje": "Tu salud es tu mayor inversión. Nuestro producto te ayuda a optimizar cada minuto de entrenamiento, sin sacrificar tu agenda. Eficiencia y resultados garantizados.",
          "tono": "profesional",
          "hashtags": ["#InversionEnSalud", "#Eficiencia", "#Resultados", "#SmartFitness"],
          "llamada_accion": "Solicita demo",
          "plataforma_recomendada": "facebook"
        },
        {
          "orden": 3,
          "mensaje": "Tecnología respaldada por ciencia. Datos reales para decisiones inteligentes sobre tu entrenamiento. Porque mereces lo mejor.",
          "tono": "profesional",
          "hashtags": ["#BasadoEnCiencia", "#DataDriven", "#SmartTraining", "#ResultadosReales"],
          "llamada_accion": "Ver estudios",
          "plataforma_recomendada": "linkedin"
        }
      ]
    },
    {
      "segmento": "mayores_40",
      "caracteristicas": {
        "edad_min": 41,
        "edad_max": 65,
        "intereses": ["salud", "longevidad", "calidad_vida"],
        "nivel_socioeconomico": "alto"
      },
      "mensajes": [
        {
          "orden": 1,
          "mensaje": "Confianza y calidad garantizada. Más de 25 años de experiencia respaldando a atletas de todas las edades. Su bienestar, nuestra prioridad.",
          "tono": "formal",
          "hashtags": ["#Confianza", "#Calidad", "#Experiencia", "#Bienestar"],
          "llamada_accion": "Consulte aquí",
          "plataforma_recomendada": "facebook"
        },
        {
          "orden": 2,
          "mensaje": "La edad es solo un número cuando tienes las herramientas correctas. Mantente activo, saludable y fuerte con tecnología adaptada a tus necesidades específicas.",
          "tono": "formal",
          "hashtags": ["#VidaActiva", "#Salud", "#BienestarTotal", "#SinLimites"],
          "llamada_accion": "Solicite información",
          "plataforma_recomendada": "email"
        },
        {
          "orden": 3,
          "mensaje": "Avalado por profesionales de la salud. Diseño ergonómico y seguro para cuidar sus articulaciones mientras alcanza sus objetivos de fitness.",
          "tono": "formal",
          "hashtags": ["#AvalMedico", "#Seguridad", "#DiseñoErgonomico", "#CuidadoArticular"],
          "llamada_accion": "Contáctenos",
          "plataforma_recomendada": "email"
        }
      ]
    }
  ],
  
  // Metadata de generación
  "generacion_metadata": {
    "generado_por_mcp": true,
    "mcp_server": "content_generator_mcp",
    "tool_usado": "generateCampaignContent",
    "version_tool": "1.0.0",
    "modelo_ai_usado": "gpt-4-turbo",
    "tokens_consumidos": 1845,
    "tiempo_generacion_ms": 3420,
    "fecha_generacion": ISODate("2025-10-18T10:00:00Z")
  },
  
  // Estados y aprobaciones
  "fecha_creacion": ISODate("2025-10-18T10:00:00Z"),
  "fecha_actualizacion": ISODate("2025-10-18T15:00:00Z"),
  "estado": "aprobado", // borrador | revision | aprobado | publicado | finalizado
  "estado_publicacion": {
    "publicado": true,
    "fecha_publicacion": ISODate("2025-10-19T09:00:00Z"),
    "plataformas_publicadas": ["instagram", "facebook", "linkedin"],
    "reach_estimado": 150000
  },
  
  // Workflow de aprobaciones
  "workflow_aprobaciones": {
    "requiere_aprobacion": true,
    "nivel_actual": "aprobado_final",
    "historial": [
      {
        "nivel": "revision_contenido",
        "aprobado_por": "usuario_789",
        "fecha": ISODate("2025-10-18T12:00:00Z"),
        "estado": "aprobado",
        "comentarios": "Contenido excelente, alineado con brand guidelines"
      },
      {
        "nivel": "revision_legal",
        "aprobado_por": "usuario_legal_001",
        "fecha": ISODate("2025-10-18T14:00:00Z"),
        "estado": "aprobado",
        "comentarios": "Sin problemas legales"
      },
      {
        "nivel": "aprobacion_final",
        "aprobado_por": "usuario_director_marketing",
        "fecha": ISODate("2025-10-18T15:00:00Z"),
        "estado": "aprobado",
        "comentarios": "Aprobado para publicación"
      }
    ]
  },
  
  // Analytics
  "metricas_rendimiento": {
    "total_impresiones": 0, // Se llena después de publicar
    "total_interacciones": 0,
    "tasa_engagement": 0.0,
    "costo_total": 0.0,
    "roi": 0.0
  }
}

// ========================================
// ÍNDICES RECOMENDADOS
// ========================================

// Para búsqueda de imágenes
db.imagenes.createIndex({ "hashtags": 1 });
db.imagenes.createIndex({ "categoria": 1, "estado": 1 });
db.imagenes.createIndex({ "fecha_creacion": -1 });
db.imagenes.createIndex({ "vector_id_pinecone": 1 }, { unique: true });

// Para bitácoras
db.bitacora_solicitudes.createIndex({ "fecha_hora": -1 });
db.bitacora_solicitudes.createIndex({ "servicio_utilizado": 1, "resultado": 1 });
db.bitacora_solicitudes.createIndex({ "id_usuario": 1, "fecha_hora": -1 });

// Para logs de campañas
db.logs_campanas.createIndex({ "id_campana": 1, "estado": 1 });
db.logs_campanas.createIndex({ "id_cliente": 1, "fecha_creacion": -1 });
db.logs_campanas.createIndex({ "mensajes_poblacion.segmento": 1 });

// Para servicios terceros
db.servicios_terceros.createIndex({ "nombre_servicio": 1 }, { unique: true });
db.servicios_terceros.createIndex({ "estado": 1 });

// Para MCP servers
db.mcp_servers.createIndex({ "nombre_servidor": 1 }, { unique: true });
db.mcp_servers.createIndex({ "tools.nombre": 1 });

// ========================================
// ESTRATEGIA DE VECTORIZACIÓN CON PINECONE
// ========================================

/*
FLUJO DE INDEXACIÓN:

1. Cuando se crea una imagen:
   - Generar embedding de la descripción usando OpenAI text-embedding-ada-002
   - Crear vector en Pinecone:
     pinecone.upsert({
       id: "img_sport_001_vec",
       values: [0.123, 0.456, ...], // 1536 dimensions
       metadata: {
         imagen_id: "ObjectId(...)",
         categoria: "articulos_deportivos",
         hashtags: ["#deportes", "#running"],
         url: "https://..."
       }
     })
   - Guardar vector_id_pinecone en MongoDB

2. Cuando se busca contenido (MCP tool getContent):
   - Generar embedding de la descripción de búsqueda
   - Query Pinecone:
     pinecone.query({
       vector: embedding_busqueda,
       topK: 10,
       includeMetadata: true,
       filter: { categoria: "articulos_deportivos" }
     })
   - Retornar resultados con scores de similitud
   - Cachear resultado en Redis

3. Sincronización:
   - Pinecone es source of truth para vectores
   - MongoDB tiene metadata completa
   - Si imagen se elimina: delete de Pinecone también

VENTAJAS DE PINECONE:
- Managed service (no infraestructura propia)
- Latencia <50ms en queries
- Escalable automáticamente
- Filtros metadata eficientes
*/

// ========================================
// CUMPLIMIENTO DE REQUISITOS
// ========================================

/*
✅ 100 imágenes mínimo: Collection imagenes + script de carga
✅ Descripciones amplias: Campo descripcion con >100 caracteres
✅ Hashtags clasificadores: Array hashtags con 8-12 tags
✅ Indexación vectorial: Pinecone con text-embedding-ada-002
✅ API POST autenticación: Canva API con OAuth2 POST
✅ MCP Server configurado: content_generator_mcp
✅ Tool #1 getContent: Búsqueda de imágenes con vectores
✅ Tool #2 generateCampaignContent: 3 mensajes por población
✅ Bitácora de solicitudes: Collection bitacora_solicitudes
✅ Integración servicios externos: Collection servicios_terceros
✅ Logs de campañas: Collection logs_campanas

NOTAS IMPORTANTES:
1. Credenciales cifradas con X.509 (separadas de servicios_terceros)
2. Usuarios/Planes centralizados en PromptSales PostgreSQL
3. Solo referencias (id_cliente, id_usuario) en MongoDB
4. Todos los costos/tokens rastreables
5. Rate limiting manejado por Redis
*/

// FIN DEL DISEÑO MONGODB
