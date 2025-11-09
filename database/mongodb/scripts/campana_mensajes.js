// Agregar collection para Tool 2
db = db.getSiblingDB("PromptContent");

db.campana_mensajes.insertOne({
  campana_id: "example",
  descripcion_campana: "ejemplo",
  publico_meta: {},
  mensajes_generados: [],
  created_at: new Date()
});

print("✅ Collection campana_mensajes creada");
