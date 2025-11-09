// ============================================================================
// MongoDB Aggregation View para ETL
// Base de datos: PromptContent
// ============================================================================

// Conectar a MongoDB
use PromptContent;

// Eliminar vista si existe
db.vw_campaign_msgs_etl.drop();

// Crear vista de agregación para ETL
db.createView(
  "vw_campaign_msgs_etl",
  "contenido_generado",
  [
    // Stage 1: Filtrar solo contenido aprobado
    {
      $match: {
        "aprobacion.estado": "aprobado"
      }
    },
    
    // Stage 2: Agrupar por campaña
    {
      $group: {
        _id: "$campana_id",
        campaign_id: { $first: "$campana_id" },
        approved_msgs: { $sum: 1 },
        assets_used: {
          $sum: {
            $cond: [
              { $in: ["$metadata.formato", ["imagen", "video"]] },
              1,
              0
            ]
          }
        },
        total_ai_tokens: { $sum: "$ai_metadata.tokens_usados" },
        total_ai_cost: { $sum: "$ai_metadata.costo_usd" },
        avg_generation_time: { $avg: "$ai_metadata.tiempo_generacion_ms" },
        last_change: { $max: "$updated_at" }
      }
    },
    
    // Stage 3: Proyección final
    {
      $project: {
        _id: 0,
        campaign_id: 1,
        approved_msgs: 1,
        assets_used: 1,
        total_ai_tokens: 1,
        total_ai_cost: { $round: ["$total_ai_cost", 2] },
        avg_generation_time: { $round: ["$avg_generation_time", 0] },
        last_change: 1
      }
    },
    
    // Stage 4: Ordenar por campaign_id
    {
      $sort: { campaign_id: 1 }
    }
  ]
);

print("Vista vw_campaign_msgs_etl creada exitosamente");

// ============================================================================
// Verificar la vista
// ============================================================================

print("\n=== Verificando vista ETL ===");
print("Primeros 5 registros:");
db.vw_campaign_msgs_etl.find().limit(5).pretty();

// ============================================================================
// Query para N8N
// ============================================================================

print("\n=== Query para usar en N8N ===");
print(`
// En N8N MongoDB Node, usar esta query:
db.vw_campaign_msgs_etl.find({
  last_change: { 
    $gte: new Date("{{lastWatermark}}") 
  }
}).toArray()
`);

// ============================================================================
// Alternativa: Pipeline directo sin vista
// ============================================================================

print("\n=== Alternativa: Pipeline directo en N8N ===");
print(`
// Si prefieres no usar vista, ejecuta este pipeline en N8N:
[
  {
    $match: {
      "aprobacion.estado": "aprobado",
      "updated_at": { $gte: new Date("{{lastWatermark}}") }
    }
  },
  {
    $group: {
      _id: "$campana_id",
      campaign_id: { $first: "$campana_id" },
      approved_msgs: { $sum: 1 },
      assets_used: { $sum: { $cond: [{ $in: ["$metadata.formato", ["imagen", "video"]] }, 1, 0] } },
      last_change: { $max: "$updated_at" }
    }
  },
  {
    $project: {
      _id: 0,
      campaign_id: 1,
      approved_msgs: 1,
      assets_used: 1,
      last_change: 1
    }
  }
]
`);

// ============================================================================
// Índice para mejorar performance
// ============================================================================

print("\n=== Creando índices para ETL ===");

// Índice compuesto para queries de ETL
db.contenido_generado.createIndex(
  { 
    "updated_at": 1, 
    "campana_id": 1,
    "aprobacion.estado": 1
  },
  { 
    name: "idx_etl_watermark" 
  }
);

print("Índice idx_etl_watermark creado");

// ============================================================================
// Datos de prueba para verificar
// ============================================================================

print("\n=== Insertando datos de prueba ===");

// Insertar algunos documentos de prueba si no existen
if (db.contenido_generado.countDocuments() === 0) {
  db.contenido_generado.insertMany([
    {
      campana_id: "camp_2025_test_001",
      metadata: { formato: "imagen" },
      aprobacion: { estado: "aprobado" },
      ai_metadata: { 
        tokens_usados: 100,
        costo_usd: 0.02,
        tiempo_generacion_ms: 5000
      },
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      campana_id: "camp_2025_test_001",
      metadata: { formato: "texto" },
      aprobacion: { estado: "aprobado" },
      ai_metadata: { 
        tokens_usados: 50,
        costo_usd: 0.01,
        tiempo_generacion_ms: 2000
      },
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      campana_id: "camp_2025_test_002",
      metadata: { formato: "video" },
      aprobacion: { estado: "aprobado" },
      ai_metadata: { 
        tokens_usados: 500,
        costo_usd: 0.10,
        tiempo_generacion_ms: 15000
      },
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
  
  print("Datos de prueba insertados");
}

// ============================================================================
// Resumen final
// ============================================================================

print("\n================================================");
print("MONGODB ETL SETUP COMPLETO");
print("================================================");
print("1. Vista: vw_campaign_msgs_etl");
print("2. Índice: idx_etl_watermark");
print("3. Pipeline para N8N configurado");
print("");
print("Usar en N8N:");
print("- Collection: vw_campaign_msgs_etl");
print("- Query: { last_change: { $gte: '{{lastWatermark}}' } }");
print("================================================");
