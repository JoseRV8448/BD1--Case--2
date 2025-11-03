// MongoDB PromptContent - Script de llenado algorítmico
// Genera 100+ imágenes con descripciones amplias y hashtags clasificadores

// Conectar a la BD
db = db.getSiblingDB("PromptContent");

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

for(let i = 1; i <= 100; i++) {
  const categoria = categorias[i % 12];
  const provider = ai_providers[i % 5];
  
  db.contenido_generado.insertOne({
    tipo: "imagen",
    url: `s3://promptsales/img${i}.jpg`,
    descripcion_amplia: `Imagen promocional para ${categoria}. Muestra productos/servicios de alta calidad con enfoque en beneficios para el cliente. Colores vibrantes, composición profesional, elementos que transmiten confianza y modernidad.`,
    hashtags: [`#${categoria}`, "#marketing", "#costarica", "#2025", "#promocion"],
    vector_embedding: Array(1536).fill(0).map(() => Math.random()),
    prompt_instrucciones: {
      mensaje_core: `Vender productos de ${categoria} a público objetivo`,
      tono: tonos[i % 5],
      objetivos: ["generar_interes", "mostrar_calidad", "crear_urgencia"],
      restricciones: ["no_texto_pequeño", "incluir_marca", "colores_corporativos"]
    },
    ai_provider: provider,
    modelo: provider === "OpenAI" ? "dall-e-3" : "modelo-base",
    tokens_consumidos: Math.floor(Math.random() * 2000) + 500,
    created_at: new Date(2024, 9, Math.floor(Math.random() * 28) + 1)
  });
}

print("100 imágenes insertadas con descripciones amplias y coherentes");
