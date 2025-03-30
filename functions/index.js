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

exports.analizarIdea = onCall({ secrets: [openaiKey] }, async (request) => {
  const datos = request.data;

  const prompt = `
El usuario ha propuesto una idea de innovación. A partir de los siguientes datos, genera:

1. 🧠 Resumen del problema.
2. 💡 Resumen de la solución.
3. ✅ Evaluación de viabilidad técnica y económica.
4. 🔄 Sugerencias o mejoras posibles.

Datos ingresados:

- Contexto: ${datos.contexto}
- Proceso actual: ${datos.proceso}
- Problema identificado: ${datos.problema}
- Causas: ${datos.causas}
- Herramientas involucradas: ${datos.herramientas}
- Solución propuesta: ${datos.solucion}
- Cómo ataca el problema: ${datos.ataque}
- Materiales necesarios: ${datos.materiales}

Devuélvelo en JSON así:
{
  "resumenProblema": "...",
  "resumenSolucion": "...",
  "evaluacion": "...",
  "sugerencias": "..."
}
`;

  const openai = new OpenAI({ apiKey: openaiKey.value() });

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    temperature: 0.4,
    messages: [
      { role: "system", content: "Eres un asistente experto en innovación tecnológica." },
      { role: "user", content: prompt },
    ],
  });

  const content = completion.choices[0].message.content;

  try {
    const json = JSON.parse(content.slice(content.indexOf('{'), content.lastIndexOf('}') + 1));
    return json;
  } catch (err) {
    return { error: "❌ No se pudo interpretar la respuesta de la IA", raw: content };
  }
});


exports.iterarIdea = onCall({ secrets: [openaiKey] }, async (request) => {
  const datos = request.data;

  const prompt = `
Eres un experto evaluador de innovación tecnológica. El usuario ha propuesto una idea con el siguiente resumen:

Resumen del problema:
${datos.resumenProblema || "No proporcionado"}

Resumen de la solución:
${datos.resumenSolucion || "No proporcionado"}

Evaluación inicial:
${datos.evaluacion || "No proporcionada"}

Tu tarea es realizar una iteración inteligente:
1. Detectar debilidades o vacíos en la idea.
2. Formular 3 preguntas clave para afinar la propuesta.
3. Estimar el nivel de madurez de la idea (de 0 a 100).
4. Detectar posibles riesgos.
5. Recomendar acciones o mejoras.

Devuelve el resultado en este formato JSON:
{
  "preguntasIterativas": ["...", "...", "..."],
  "madurez": 0-100,
  "riesgosDetectados": ["..."],
  "accionesRecomendadas": ["..."]
}`;

  try {
    const openai = new OpenAI({ apiKey: openaiKey.value() });

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      temperature: 0.5,
      messages: [
        { role: "system", content: "Eres un asesor experto en innovación y validación de ideas." },
        { role: "user", content: prompt },
      ],
    });

    const content = completion.choices[0].message.content;

    const start = content.indexOf('{');
    const end = content.lastIndexOf('}');
    const json = JSON.parse(content.slice(start, end + 1));

    return json;
  } catch (err) {
    return { error: "❌ Error en iterarIdea", detalles: err.message };
  }
});

exports.validarRespuestasIteracion = onCall({ secrets: [openaiKey] }, async (request) => {
  const datos = request.data;

  const prompt = `
Actúa como un evaluador experto en innovación.
Se te han dado las preguntas que generaste en la fase de iteración IA, junto con las respuestas escritas por el usuario.
Tu tarea es evaluar si la idea ha madurado lo suficiente como para convertirse en un proyecto piloto.

Resumen del problema:
${datos.resumenProblema}

Resumen de la solución:
${datos.resumenSolucion}

Preguntas y respuestas del usuario:
${Object.entries(datos.respuestasIteracion).map(([pregunta, respuesta]) => `Pregunta: ${pregunta}\nRespuesta: ${respuesta}`).join("\n\n")}

Responde en formato JSON:
{
  "madurezActualizada": (0-100),
  "aprobadaParaPrototipo": true/false,
  "comentarioFinal": "..."
}
`;

  try {
    const openai = new OpenAI({ apiKey: openaiKey.value() });
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      temperature: 0.4,
      messages: [
        { role: "system", content: "Eres un evaluador experto que valida ideas basadas en respuestas del usuario." },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content;
    const start = content.indexOf('{');
    const end = content.lastIndexOf('}');
    const json = JSON.parse(content.slice(start, end + 1));
    return json;
  } catch (err) {
    return { error: "❌ Error al validar respuestas de iteración IA", detalles: err.message };
  }
});


exports.generarTareasDesdeIdea = onCall({ secrets: [openaiKey] }, async (request) => {
  const { resumenProblema, resumenSolucion, comentarioFinal } = request.data;

  const prompt = `
Actúa como un asistente experto en gestión de proyectos. A partir del resumen de una idea aprobada para ser prototipo, genera tareas claras y accionables.

Resumen del problema:
${resumenProblema}

Resumen de la solución:
${resumenSolucion}

Comentario final de la IA:
${comentarioFinal}

Tu objetivo es generar una lista de tareas iniciales para ejecutar el proyecto en su fase piloto. Para cada tarea incluye:
- título (obligatorio)
- descripción (corta)
- dificultad (Baja, Media, Alta)
- duración estimada (en horas, número entero)

Devuelve solo en formato JSON:
{
  "tareas": [
    {
      "titulo": "...",
      "descripcion": "...",
      "dificultad": "Media",
      "duracionHoras": 6
    },
    ...
  ]
}
`;

  try {
    const openai = new OpenAI({ apiKey: openaiKey.value() });
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      temperature: 0.4,
      messages: [
        { role: "system", content: "Eres un generador de tareas para proyectos de innovación." },
        { role: "user", content: prompt },
      ],
    });

    const content = response.choices[0].message.content;
    const start = content.indexOf("{");
    const end = content.lastIndexOf("}");
    const json = JSON.parse(content.slice(start, end + 1));

    return json;
  } catch (err) {
    return { error: "❌ Error al generar tareas desde idea", detalles: err.message };
  }
});
