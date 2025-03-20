// ✅ index.js completo y funcional con Firebase Functions v2
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const OpenAI = require("openai");

// ✅ Se declara el secret seguro para la API Key de OpenAI
const openaiKey = defineSecret("OPENAI_API_KEY");
exports.procesarReunion = onCall({ secrets: [openaiKey] }, async (request) => {
  const texto = request.data.texto;
  const participantes = request.data.participantes || []; // [{ uid, nombre }]
  const habilidadesPorUID = request.data.habilidadesPorUID || {}; // { uid: ["..."] }

  if (!texto || texto.trim().length < 20) {
    throw new Error("❌ El texto proporcionado es muy corto o está vacío.");
  }

  const openai = new OpenAI({ apiKey: openaiKey.value() });

  // 🧠 Habilidades en texto
  const habilidadesTexto = participantes.map(p => {
    const habilidades = habilidadesPorUID[p.uid]?.join(", ") || "sin datos";
    return `- ${p.nombre}: ${habilidades}`;
  }).join("\n");

  const prompt = `
Eres un asistente experto en gestión de proyectos. A partir del siguiente texto de una reunión transcrita, debes hacer dos cosas:

1. Generar un resumen claro y profesional de los temas tratados.
2. Identificar y listar tareas importantes.

Para cada tarea incluye:
- Un título claro
- Una fecha de entrega tentativa (dentro de los próximos 7 días)

Participantes y sus habilidades:
${habilidadesTexto}

Transcripción:
"""
${texto}
"""

Devuelve la respuesta en formato JSON con esta estructura:
{
  "resumen": "...",
  "tareas": [
    { "titulo": "...", "fecha": "YYYY-MM-DD" }
  ]
}
`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4-0125-preview",
      temperature: 0.3,
      messages: [
        {
          role: "system",
          content: "Eres un asistente que resume reuniones y genera tareas con base en roles, habilidades y participantes.",
        },
        { role: "user", content: prompt },
      ],
    });

    const content = completion.choices[0].message.content;

    try {
      const start = content.indexOf('{');
      const end = content.lastIndexOf('}');
      const jsonString = content.slice(start, end + 1);
      const json = JSON.parse(jsonString);

      // ✅ MATCH INTELIGENTE: asignar responsable basado en habilidades
      // ✅ MATCH INTELIGENTE: asignar responsable basado en habilidades
      for (let tarea of json.tareas) {
        const titulo = tarea.titulo.toLowerCase();

        let mejorUID = null;
        let mejorHabilidad = null;
        let mayorCoincidencias = 0;

        for (const [uid, habilidades] of Object.entries(habilidadesPorUID)) {
          let coincidencias = 0;
          let habilidadDetectada = null;

          for (const habilidad of habilidades) {
            const clean = habilidad.toLowerCase().replace(/_/g, " ");
            if (titulo.includes(clean)) {
              coincidencias++;
              habilidadDetectada = habilidad;
            }
          }

          if (coincidencias > mayorCoincidencias) {
            mayorCoincidencias = coincidencias;
            mejorUID = uid;
            mejorHabilidad = habilidadDetectada;
          }
        }

        if (mejorUID) {
          tarea.responsable = mejorUID;
          if (mejorHabilidad) {
            tarea.matchHabilidad = mejorHabilidad;
          }
        
          console.log("✅ Tarea asignada por IA:", {
            titulo: tarea.titulo,
            responsable: mejorUID,
            habilidadUsada: mejorHabilidad,
          });
        } else {
          // 🔄 Fallback: asignar al usuario con más habilidades en total
          let uidSugerido = null;
          let mayorHabilidades = 0;
        
          for (const [uid, habilidades] of Object.entries(habilidadesPorUID)) {
            if (habilidades.length > mayorHabilidades) {
              mayorHabilidades = habilidades.length;
              uidSugerido = uid;
            }
          }
        
          if (uidSugerido) {
            tarea.responsable = uidSugerido;
            tarea.asignadoPorDefecto = true;
        
            console.log("🤖 Tarea asignada por defecto (fallback):", {
              titulo: tarea.titulo,
              responsable: uidSugerido,
              motivo: "Participante con más habilidades registradas",
            });
          } else {
            console.log("⚠️ Tarea sin responsable:", {
              titulo: tarea.titulo,
              motivo: "No se encontraron participantes con habilidades",
            });
          }
        }
        
        
          
      }


      logger.info("✅ Respuesta JSON válida recibida con asignación inteligente");
      return json;

    } catch (e) {
      logger.error("❌ Error al interpretar JSON de OpenAI", e);
      return {
        error: "La IA respondió algo que no es JSON válido.",
        raw: content,
      };
    }

  } catch (error) {
    logger.error("❌ Error al contactar con OpenAI:", error);
    return {
      error: "No se pudo contactar con OpenAI.",
      detalles: error.message,
    };
  }
});



exports.procesarPerfilUsuario = onCall({ secrets: [openaiKey] }, async (request) => {
  const { nombre, tipoPersonalidad, tareasHechas, estadoAnimo, nivelEstres } = request.data;

  const openai = new OpenAI({ apiKey: openaiKey.value() });

  const prompt = `
Usuario: ${nombre}
Tipo de personalidad: ${tipoPersonalidad || "no definido"}
Tareas recientes: ${tareasHechas.join(", ")}
Estado de ánimo: ${estadoAnimo}
Nivel de estrés: ${nivelEstres}
Si el tipo de personalidad está definido (por ejemplo: INTJ, ENFP...), úsalo como guía para perfilar el estilo de pensamiento, motivaciones y forma de trabajar del usuario.

Evalúa las siguientes 24 sub-habilidades con valores del 0 al 5:
- pensamiento_logico
- planeamiento_estrategico
- toma_de_decisiones
- gestion_del_tiempo
- planificacion
- seguimiento
- propuesta_de_ideas
- diseno_visual
- comunicacion_escrita
- comunicacion_efectiva
- empatia
- liderazgo
- aprendizaje_rapido
- resolucion_de_conflictos
- autonomia
- manejo_herramientas_digitales
- atencion_al_detalle
- concentracion
- persistencia
- adaptabilidad
- escucha_activa
- mediacion
- curiosidad
- innovacion

Luego, genera un resumen profesional extenso (mínimo 5 líneas) sobre el perfil del usuario. Devuélvelo en este formato:
- Rasgos sobresalientes
- Áreas de mejora
- Estilo de trabajo
- Contextos en los que destaca

Devuélvelo en este formato JSON:
{
  "habilidades": {
    "pensamiento_logico": 4,
    ...
  },
  "resumenIA": "..."
}`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4-0125-preview",
      temperature: 0.6,
      messages: [
        { role: "system", content: "Eres un analista de talento experto en IA." },
        { role: "user", content: prompt },
      ],
    });

    const content = completion.choices[0].message.content;

    // Asegura que la respuesta sea JSON parseable
    const start = content.indexOf('{');
    const end = content.lastIndexOf('}');
    const json = JSON.parse(content.slice(start, end + 1));

    return json;

  } catch (e) {
    console.error('Error procesando perfil con IA:', e);
    return { error: "❌ Error procesando perfil con OpenAI", detalles: e.message };
  }
});
