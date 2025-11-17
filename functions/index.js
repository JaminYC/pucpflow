// ✅ index.js completo y funcional con Firebase Functions v2
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const OpenAI = require("openai");
const pdfParse = require("pdf-parse");

// ✅ Inicializar Firebase Admin (IMPORTANTE: debe estar al inicio)
admin.initializeApp();

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
  const transcripcionFase1 = datos.transcripcionFase1 || "";
  const transcripcionFase2 = datos.transcripcionFase2 || "";
  const imagenURL1 = datos.imagenURL1 || "";
  const imagenURL2 = datos.imagenURL2 || "";
  
  const promptBase = `
  El usuario ha propuesto una idea de innovación. A partir de los siguientes datos, genera:

  1. 🧠 Resumen del problema.
  2. 💡 Resumen de la solución.
  3. ✅ Evaluación de viabilidad técnica y económica.
  4. 🔄 Sugerencias o mejoras posibles.
  5. 📊 Nivel de madurez estimado (valor entre 0% y 100%).
  6. ⚙️ Esfuerzo estimado para implementar la idea (bajo, medio o alto).
  7. 🧭 Campo o área de mejora principal (ej. sostenibilidad, viabilidad técnica, modelo de negocio).
  8. ⚠️ Lista de riesgos detectados.
  9. ✅ Lista de acciones recomendadas para mejorar la idea.
  10. 🏷️ Título sugerido para la idea/proyecto.
  Datos ingresados:

  🧠 Fase 1: Exploración
  - Contexto: ${datos.contexto}
  - Proceso actual: ${datos.proceso}
  - Problema identificado: ${datos.problema}
  - Causas: ${datos.causas}
  - Herramientas involucradas: ${datos.herramientas}
  - Transcripción por voz (Fase 1): ${transcripcionFase1}
  - Imagen asociada (Fase 1): ${imagenURL1}

  💡 Fase 2: Propuesta de Solución
  - Solución propuesta: ${datos.solucion}
  - Cómo ataca el problema: ${datos.ataque}
  - Materiales necesarios: ${datos.materiales}
  - Transcripción por voz (Fase 2): ${transcripcionFase2}
  - Imagen asociada (Fase 2): ${imagenURL2}

  Devuélvelo en formato JSON así:
  {
    "resumenProblema": "...",
    "resumenSolucion": "...",
    "evaluacion": "...",
    "sugerencias": ["..."],
    "madurez": 78,
    "esfuerzo": "medio",
    "campo": "sostenibilidad",
    "riesgosDetectados": ["..."],
    "accionesRecomendadas": ["..."]
    "titulo": "...",
  }
  `;


  const contenidoTecnico =`Operación del Sistema de Relaves LingaMina Cerro Verde
        La operación de Relaves Linga se inicia con la descarga del relave espesado proveniente de los cuatro espesadores principales hacia los boxes 102 y 2203, puntos estratégicos para la distribución del material hacia diferentes etapas del proceso.

        Desde el Box 102, el relave se dirige por gravedad hacia los puntos de deposición (DPs) que forman parte de la estrategia de construcción del dique: DP14, DP15, DP16, DP13, F17, DP18, DP19, DP01, DP02A, DP03 y DP11A. El otro 50% del flujo es derivado al Box 2203, el cual alimenta directamente a la primera estación de ciclones, un sistema de clasificación fundamental para garantizar las condiciones ideales del relave que será finalmente depositado.

        1. Clasificación por Ciclones
        En la primera estación, se encuentran dos baterías de ciclones Gmax-15, con 30 unidades cada una. Estas clasifican el relave en:

        Underflow: partículas gruesas, recolectadas en el Box 2204.

        Overflow: partículas finas, conducidas por el sistema Jacking Overflow hacia la playa del embalse.

        Posteriormente, el material del Box 2204 se bombea a la segunda estación de ciclones, que cuenta con 14 ciclones Gmax-26 de alta capacidad. Nuevamente se separa el:

        Overflow hacia la playa del embalse.

        Underflow hacia el Box 2115, donde se almacena el relave grueso ya clasificado.

        Este relave debe cumplir con estándares técnicos: menos del 10.5% de finos en su composición para asegurar buena compactación, y no superar el 15% de finos una vez depositado.

        2. Gestión del Dique de Relaves
        El dique contiene el embalse de relaves y se encuentra segmentado en seis zonas (de la zona -1 a la 4), lo cual permite un plan de descarga ordenado. Esta estructura también incluye un sistema de drenes horizontales y verticales que canalizan las filtraciones hacia el pozo Seepage.

        En este pozo operan tres barcazas con bombas sumergibles:

        PW71, PW72, y PW73, encargadas de bombear el agua recuperada hacia los:

        Tanques 47 → 26 → 2126, desde donde el agua es reutilizada principalmente en la segunda estación de ciclones.

        3. Recuperación de Agua del Embalse
        El relave que llega a la playa del embalse mediante Jacking Overflow se consolida naturalmente. Sin embargo, en épocas de alta humedad o baja evaporación, este proceso no es suficiente. Por ello se emplean equipos MudMaster, que:

        Realizan consolidación mecánica del relave.

        Abren canales de evacuación de aguas parásitas, mejorando la conducción del agua hacia el valle central de recuperación.

        Este valle central mantiene normalmente 1 millón de m³ de agua, volumen crítico para el proceso de recirculación. Dos barcazas con cuatro bombas cada una (PW11) extraen el agua acumulada y la trasladan a los tanques de proceso TK-730 y TK-731, desde donde se reinyecta a la concentradora.

        Operaciones Técnicas Detalladas según el PETS SORpr0030
        A continuación, se listan las operaciones clave descritas en el PETS de bombeo de agua recuperada:

        A. Operación de Barcazas Seepage
        Verificación diaria del estado de bombas PW71 a PW73.
        Supervisión del nivel del pozo Seepage.
        Coordinación con la sala de control para encendido/apagado remoto.
        Monitoreo de presiones de succión/descarga de las bombas.
        Drenado del pozo en condiciones de lluvia intensa.

        B. Operación de Barcazas Valle Central
        Control y operación de las barcazas equipadas con bombas centrífugas verticales (PW11).
        Revisión y limpieza de filtros de succión.
        Control de caudal mediante válvulas de compuerta y check válvulas.
        Inspección de mangueras, niveles de aceite y temperatura de motores.

        C. Sistemas de Bombeo Auxiliares
        Tanques 2126 y 47 incluyen bombas verticales tipo turbina (VTP) que elevan el agua hacia el sistema de recirculación.
        Estas bombas operan con variadores de velocidad y sensores de nivel en tanques para automatizar el control.

        D. Sistemas Eléctricos y de Control
        Los tableros de control para bombas y barcazas son monitoreados desde la Sala Eléctrica C-103 y C-120.
        Se emplean variadores VFD y arrancadores suaves para control de motores.
        Las alarmas por alta temperatura, sobrecorriente o fallo de presión son atendidas según protocolo.

        Resumen de Equipos Críticos
        Bombas de ciclones:
        Primera estación: 3820-PP-2901, PP-2902
        Segunda estación: 3830-PP-2901, PP-2902, PP-2903

        Boxes de control:
        Box 102: entrada principal de relave.
        Box 2203: previo a 1ra estación de ciclones.
        Box 2204: previo a 2da estación.
        Box 2115: salida final hacia deposición de relave grueso.
        `;

  const openai = new OpenAI({ apiKey: openaiKey.value() });

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    temperature: 0.4,
    messages: [
      { role: "system", content: "Eres un asistente experto en innovación tecnológica en procesos en mineria." },
      { role: "user",  content: `${promptBase}\n\n${contenidoTecnico}`},
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
exports.reforzarIdea = onCall({ secrets: [openaiKey] }, async (request) => {
  const { ideaId, respuestas, comentariosAdicionales } = request.data;

  const prompt = `
  El usuario ha proporcionado nuevas respuestas para mejorar su idea de innovación.
  A partir de estas respuestas, evalúa nuevamente la idea:

  Respuestas del usuario:
  ${Object.entries(respuestas).map(([q, r]) => `Q: ${q}\nA: ${r}`).join('\n\n')}

  Comentarios adicionales: ${comentariosAdicionales}

  Devuélvelo en formato JSON:
  {
    "resumenProblema": "...",
    "resumenSolucion": "...",
    "evaluacion": "...",
    "sugerencias": ["..."],
    "madurez": 84,
    "esfuerzo": "medio",
    "campo": "viabilidad técnica",
    "riesgosDetectados": ["..."],
    "accionesRecomendadas": ["..."]
  }
  `;

  const openai = new OpenAI({ apiKey: openaiKey.value() });

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    temperature: 0.4,
    messages: [
      { role: "system", content: "Eres un asistente de innovación industrial." },
      { role: "user", content: prompt },
    ],
  });

  const content = completion.choices[0].message.content;

  try {
    const resultado = JSON.parse(content.slice(content.indexOf("{"), content.lastIndexOf("}") + 1));

    // Actualiza Firestore con el nuevo análisis
    await admin.firestore().collection("ideas").doc(ideaId).update({
      resultadoIA: resultado,
      estado: "reforzada",
      fechaReforzada: admin.firestore.FieldValue.serverTimestamp(),
    });

    return resultado;
  } catch (err) {
    return { error: "❌ Falló el análisis IA", raw: content };
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


// === ADAN: chat conversacional genérico ===
// === ADAN: chat conversacional con historial ===
exports.adanChat = onCall({ secrets:[openaiKey], timeoutSeconds:60 }, async (request) => {
  try {
    const text     = (request.data?.text || "").toString().slice(0, 4000);
    const profile  = request.data?.profile || {};
    const history  = Array.isArray(request.data?.history) ? request.data.history : []; // [{role, content}]
    if (!text) return { reply: "¿Qué necesitas?" };

    const openai = new OpenAI({ apiKey: openaiKey.value() });

    const messages = [
      {
        role: "system",
        content:
          "Eres ADAN, un asistente personal cálido y claro. " +
          "Responde con frases cortas y naturales (apto para TTS), usa pausas, " +
          "confirma entendidos y sugiere el siguiente paso. Adapta el tono al usuario. " +
          "Siempre responde en el idioma del usuario."
      },
      { role: "system", content: `Perfil: ${JSON.stringify(profile)}` },
      ...history,                     // contexto previo
      { role: "user", content: text }
    ];

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.7,
      messages,
      max_tokens: 500
    });

    const reply = completion.choices[0]?.message?.content?.trim() || "…";
    return { reply };
  } catch (e) {
    logger.error("adanChat error", e);
    return { error: "openai_failed", message: "No pude consultar la IA." };
  }
});

exports.transcribirAudio = onCall({ secrets: [openaiKey], timeoutSeconds: 300 }, async (req) => {
  try {
    const { audioBase64, fileName = "audio.m4a", language = "es" , prompt = "" } = req.data || {};
    if (!audioBase64) return { error: "Falta audioBase64" };

    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // Construye un "file" a partir de base64
    const buffer = Buffer.from(audioBase64, "base64");
    const file = await openai.files.create({
      file: new File([buffer], fileName, { type: "audio/m4a" }),
      purpose: "assistants", // solo para hosting temporal
    });

    // Modelo rápido y bueno para STT
    const resp = await openai.audio.transcriptions.create({
      model: "gpt-4o-mini-transcribe",     // o "gpt-4o-transcribe"
      file: file,                           // o { file: fs.createReadStream(...) }
      response_format: "text",              // "json" o "text"
      language,                             // "es" para español
      prompt,                               // opcional: jerga/tema
    });

    return { text: resp.text || "" };
  } catch (e) {
    console.error("transcribirAudio error:", e);
    return { error: "openai_failed", message: e.message };
  }
});

// ========================================
// GENERAR BLUEPRINT GENERAL CON IA
// ========================================

exports.generarBlueprintProyecto = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 420,
  memory: "512MiB"
}, async (request) => {
  try {
    const {
      documentosBase64 = [],
      nombreProyecto = "Proyecto sin nombre",
      descripcionBreve = "",
      methodology = "general",
      config = {},
      skillMatrix = [],
      workflowContext = {}
    } = request.data || {};

    if ((!documentosBase64 || documentosBase64.length === 0) &&
        !descripcionBreve &&
        !config.customContext) {
      return { error: "Debes proporcionar documentos, una descripción o un contexto base" };
    }

    const openai = new OpenAI({ apiKey: openaiKey.value() });
    let textoCompleto = descripcionBreve || "";

    for (let i = 0; i < documentosBase64.length; i++) {
      try {
        const buffer = Buffer.from(documentosBase64[i], "base64");
        const pdfData = await pdfParse(buffer);
        textoCompleto += `\n\n=== DOCUMENTO ${i + 1} ===\n${pdfData.text}`;
      } catch (pdfError) {
        logger.warn("�?O Error parseando documento para blueprint general:", pdfError);
      }
    }

    textoCompleto = textoCompleto.substring(0, 15000);

    const focusAreas = (config.focusAreas || []).join(", ") || "No especificadas";
    const softSkills = (config.softSkillFocus || []).join(", ") || "No priorizadas";
    const businessDrivers = (config.businessDrivers || []).join(", ") || "No declarados";
    const customContext = config.customContext ? JSON.stringify(config.customContext) : "";

    const skillSummary = (skillMatrix || []).map((skill) => {
      const nature = skill.nature || "technical";
      return `- ${skill.name || skill.skillName} (${nature}) nivel ${skill.level || 5}`;
    }).join("\n");

    const prompt = `
Eres un Project Strategist que diseña blueprints híbridos (metodología base: ${methodology}).
Necesitas combinar visión de negocio + habilidades blandas + IA contextual.

Áreas de enfoque: ${focusAreas}
Soft skills prioritarias: ${softSkills}
Drivers de negocio: ${businessDrivers}
Contexto adjunto: ${customContext}

Inventario de habilidades:
${skillSummary || "Sin inventario (asume equipo multidisciplinario)"}

Documentación / notas:
${textoCompleto}

Devuelve SOLO un JSON con esta estructura:
{
  "resumenEjecutivo": "...",
  "objetivosSMART": ["...", "..."],
  "hitosPrincipales": [
    { "nombre": "...", "mes": 1, "riesgosHumanos": ["..."], "softSkillsClaves": ["..."] }
  ],
  "backlogInicial": [
    { "nombre": "...", "tipo": "descubrimiento|ejecucion|seguimiento", "entregables": ["..."], "metricasExito": ["..."] }
  ],
  "skillMatrixSugerida": [
    { "skill": "...", "nature": "soft|technical|leadership|creative", "nivelMinimo": 7, "aplicaciones": ["..."] }
  ],
  "softSkillsPlan": {
    "enfoque": ["..."],
    "rituales": ["..."]
  },
  "recomendacionesPMI": {
    "cuandoAplicarPMI": "...",
    "fasesCompatibles": ["..."]
  }
}
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.35,
      max_tokens: 3200,
      messages: [
        {
          role: "system",
          content: "Eres un estratega de proyectos que combina contexto humano, habilidades blandas y frameworks ágiles/PMI."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content || "";
    let blueprint;
    try {
      const start = content.indexOf("{");
      const end = content.lastIndexOf("}");
      const jsonString = content.slice(start, end + 1);
      blueprint = JSON.parse(jsonString);
    } catch (errorParse) {
      logger.error("�?O Error parseando blueprint general:", errorParse);
      return { error: "No se pudo interpretar la respuesta de IA para el blueprint" };
    }

    return {
      success: true,
      blueprint
    };
  } catch (error) {
    logger.error("�?O Error generando blueprint general:", error);
    return { error: "Error generando blueprint general", message: error.message };
  }
});

// ========================================
// GENERAR WORKFLOW CONTEXTUAL
// ========================================

exports.generarWorkflowContextual = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 360,
  memory: "512MiB"
}, async (request) => {
  try {
    const {
      nombreProyecto,
      methodology = "general",
      objective = "",
      macroEntregables = [],
      skillMatrix = [],
      contexto = {},
      config = {}
    } = request.data || {};

    if (!nombreProyecto) {
      return { error: "nombreProyecto es requerido" };
    }

    const openai = new OpenAI({ apiKey: openaiKey.value() });
    const skillSummary = (skillMatrix || []).map((skill) => {
      const nature = skill.nature || "technical";
      const sector = skill.sector || "General";
      return `- ${skill.name || skill.skillName} (${nature}) [${sector}] nivel ${skill.level || 5}`;
    }).join("\n");

    const macroTexto = (macroEntregables || []).map((item, idx) => `${idx + 1}. ${item}`).join("\n");
    const contextoLibre = JSON.stringify(contexto || {});

    const prompt = `
Eres un Workflow Orchestrator que debe generar flujos IA-contextualizados.
Metodología base: ${methodology}
Objetivo principal: ${objective}

Macro entregables:
${macroTexto || "No declarados"}

Inventario de skills:
${skillSummary || "No hay skills declaradas"}

Contexto adicional:
${contextoLibre}

Devuelve SOLO un JSON
{
  "workflow": [
    {
      "nombre": "...",
      "objetivo": "...",
      "tipo": "descubrimiento|ejecucion|seguimiento",
      "duracionDias": 0,
      "dependencias": ["..."],
      "indicadoresExito": ["..."],
      "riesgosHumanos": ["..."],
      "tareas": [
        {
          "titulo": "...",
          "descripcion": "...",
          "habilidadesTecnicas": ["..."],
          "habilidadesBlandas": ["..."],
          "responsableSugerido": "Equipo/rol",
          "outputs": ["..."]
        }
      ]
    }
  ],
  "recomendaciones": {
    "ritualesIA": ["..."],
    "seguimientoHumano": ["..."],
    "metricasClave": ["..."]
  }
}
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.4,
      max_tokens: 2500,
      messages: [
        {
          role: "system",
          content: "Actúas como orquestador de workflows considerando habilidades blandas, riesgos humanos y foco de negocio."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content || "";
    let workflow;
    try {
      const start = content.indexOf("{");
      const end = content.lastIndexOf("}");
      const jsonString = content.slice(start, end + 1);
      workflow = JSON.parse(jsonString);
    } catch (errorParse) {
      logger.error("�?O Error parseando workflow contextual:", errorParse);
      return { error: "No se pudo interpretar el workflow generado" };
    }

    return {
      success: true,
      workflow,
      config
    };
  } catch (error) {
    logger.error("�?O Error generando workflow contextual:", error);
    return { error: "Error generando workflow contextual", message: error.message };
  }
});

// ========================================
// 📄 SISTEMA DE EXTRACCIÓN DE CV Y SKILLS
// ========================================

/**
 * Extrae información de un CV (PDF en base64) usando OpenAI
 * Mapea las skills extraídas contra la base de datos de Firestore
 *
 * Input: { cvBase64: string, userId: string }
 * Output: {
 *   profile: { name, email, phone, summary },
 *   skills: {
 *     found: [{ aiSkill, dbSkillId, dbSkillName, sector, level }],
 *     notFound: [string]
 *   }
 * }
 */
exports.extraerCV = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 300,
  memory: "512MiB"
}, async (request) => {
  try {
    const { cvBase64, userId } = request.data || {};

    // Validaciones
    if (!cvBase64) {
      return { error: "❌ Falta el archivo CV en base64" };
    }
    if (!userId) {
      return { error: "❌ Falta el ID del usuario" };
    }

    logger.info(`📄 Procesando CV para usuario: ${userId}`);

    // 1. Convertir PDF base64 a texto usando pdf-parse
    const buffer = Buffer.from(cvBase64, "base64");
    let cvText = "";

    try {
      const pdfData = await pdfParse(buffer);
      cvText = pdfData.text;
      logger.info(`✅ PDF parseado correctamente. ${cvText.length} caracteres extraídos`);
      logger.info(`📄 Primeros 500 caracteres del CV: ${cvText.substring(0, 500)}`);

      if (!cvText || cvText.trim().length < 50) {
        logger.warn("⚠️ PDF tiene muy poco texto o está vacío");
        return {
          error: "El PDF no contiene texto extraíble. Puede ser una imagen escaneada. Por favor, usa un PDF con texto seleccionable."
        };
      }
    } catch (pdfError) {
      logger.error("❌ Error parseando PDF:", pdfError);
      return {
        error: "Error al leer el PDF. Asegúrate de que sea un archivo PDF válido."
      };
    }

    // 2. Obtener skills de la BD para que OpenAI las priorice
    const db = admin.firestore();
    const skillsSnapshot = await db.collection('skills').get();
    const availableSkills = [];
    skillsSnapshot.forEach(doc => {
      availableSkills.push(doc.data().name);
    });

    // 3. Preparar OpenAI
    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // 4. Llamar a OpenAI para extraer perfil estructurado
    const extractionPrompt = `
Eres un asistente experto en análisis de CVs. Analiza el siguiente CV y extrae información estructurada.

SKILLS DISPONIBLES EN NUESTRA BASE DE DATOS (USA ESTOS NOMBRES EXACTOS cuando sea posible):
${availableSkills.slice(0, 100).join(', ')}

IMPORTANTE: Extrae TODAS las habilidades técnicas que encuentres en TODO el documento:
- Lenguajes de programación (Python, Java, JavaScript, TypeScript, C++, C#, Go, Rust, etc.)
- Frameworks y librerías (React, Angular, Vue, Django, Flask, Spring, .NET, etc.)
- Bases de datos (MySQL, PostgreSQL, MongoDB, Redis, Oracle, SQL Server, etc.)
- Cloud y DevOps (AWS, Azure, GCP, Docker, Kubernetes, Jenkins, GitLab CI, etc.)
- Herramientas (Git, Jira, Figma, Photoshop, VS Code, etc.)
- Metodologías (Scrum, Agile, TDD, etc.)

Busca skills en:
1. Sección de habilidades/skills
2. Descripción de experiencia laboral
3. Proyectos mencionados
4. Tecnologías usadas en cada trabajo
5. Certificaciones

Devuelve ÚNICAMENTE un objeto JSON válido con esta estructura:
{
  "name": "Nombre completo del candidato",
  "email": "email@ejemplo.com",
  "phone": "teléfono si está disponible",
  "summary": "Resumen profesional en 2-3 líneas",
  "skills": [
    {"name": "Python", "level": 8},
    {"name": "Django", "level": 7}
  ],
  "experience": [
    {
      "title": "Cargo",
      "company": "Empresa",
      "duration": "2020-2024",
      "description": "Breve descripción"
    }
  ],
  "education": [
    {
      "degree": "Título",
      "institution": "Institución",
      "year": "2019"
    }
  ]
}

Para "level" (1-10):
- 9-10: Experto (5+ años, senior, tech lead)
- 7-8: Avanzado (3-5 años, proyectos complejos)
- 5-6: Intermedio (1-3 años, múltiples proyectos)
- 3-4: Básico (< 1 año, proyectos pequeños)
- 1-2: Principiante (solo mencionado, sin experiencia)

NO devuelvas ejemplos, devuelve SOLO el análisis real del CV.
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2, // Más determinístico
      messages: [
        { role: "system", content: extractionPrompt },
        { role: "user", content: `Analiza este CV y extrae TODAS las skills técnicas:\n\n${cvText}` }
      ],
      max_tokens: 3000 // Aumentado para permitir más skills
    });

    const content = completion.choices[0].message.content;
    logger.info("✅ Respuesta de OpenAI recibida");

    // 5. Parsear JSON
    let profile;
    try {
      const start = content.indexOf('{');
      const end = content.lastIndexOf('}');
      const jsonString = content.slice(start, end + 1);
      profile = JSON.parse(jsonString);
      logger.info("📋 Perfil parseado:", JSON.stringify(profile, null, 2));
    } catch (parseError) {
      logger.error("❌ Error parseando JSON de OpenAI", parseError);
      logger.error("❌ Contenido recibido:", content);
      return {
        error: "La IA respondió algo que no es JSON válido",
        raw: content
      };
    }

    // 6. Mapear skills contra base de datos de Firestore
    const aiSkills = profile.skills || [];
    logger.info(`🔍 Skills en perfil: ${aiSkills.length}`, aiSkills);
    const found = [];
    const notFound = [];

    logger.info(`🔍 Mapeando ${aiSkills.length} skills extraídas...`);

    // Reconstruir lista de skills de la BD con IDs
    const dbSkills = [];
    skillsSnapshot.forEach(doc => {
      dbSkills.push({
        id: doc.id,
        ...doc.data()
      });
    });

    // Helper: calcular similitud entre dos strings (Levenshtein simplificado)
    function similarity(s1, s2) {
      const longer = s1.length > s2.length ? s1 : s2;
      const shorter = s1.length > s2.length ? s2 : s1;
      if (longer.length === 0) return 1.0;

      const editDistance = (s1, s2) => {
        s1 = s1.toLowerCase();
        s2 = s2.toLowerCase();
        const costs = [];
        for (let i = 0; i <= s1.length; i++) {
          let lastValue = i;
          for (let j = 0; j <= s2.length; j++) {
            if (i === 0) costs[j] = j;
            else if (j > 0) {
              let newValue = costs[j - 1];
              if (s1.charAt(i - 1) !== s2.charAt(j - 1))
                newValue = Math.min(Math.min(newValue, lastValue), costs[j]) + 1;
              costs[j - 1] = lastValue;
              lastValue = newValue;
            }
          }
          if (i > 0) costs[s2.length] = lastValue;
        }
        return costs[s2.length];
      };

      return (longer.length - editDistance(longer, shorter)) / longer.length;
    }

    // Mapear cada skill extraída por IA con búsqueda inteligente
    for (const aiSkill of aiSkills) {
      const skillName = (aiSkill.name || '').trim();
      const skillNameLower = skillName.toLowerCase();
      const level = aiSkill.level || 5;
      let dbSkill = null;

      // 1. Búsqueda exacta (case-insensitive)
      dbSkill = dbSkills.find(s => s.name.toLowerCase() === skillNameLower);

      // 2. Búsqueda con variaciones comunes
      if (!dbSkill) {
        const variations = {
          // Software
          'js': 'javascript',
          'ts': 'typescript',
          'py': 'python',
          'react.js': 'react',
          'reactjs': 'react',
          'vue.js': 'vue',
          'vuejs': 'vue',
          'node.js': 'node',
          'nodejs': 'node',
          'next.js': 'nextjs',
          'express.js': 'express',
          'postgresql': 'postgres',
          'mongodb': 'mongo',
          'mysql': 'sql',
          'k8s': 'kubernetes',
          'aws lambda': 'lambda',
          'aws s3': 's3',
          'gcp': 'google cloud',
          'azure devops': 'azure',

          // CAD/CAM
          'solidworks': 'solidworks',
          'solid works': 'solidworks',
          'autocad': 'autocad',
          'auto cad': 'autocad',
          'autodesk inventor': 'inventor',
          'fusion360': 'fusion 360',
          'rhino3d': 'rhino',
          'rhinoceros': 'rhino',
          'sketchup': 'sketchup',

          // Simulación
          'matlab': 'matlab',
          'ansys workbench': 'ansys',
          'ansys mechanical': 'ansys',
          'comsol multiphysics': 'comsol',
          'solidworks simulation': 'solidworks simulation',

          // Manufactura
          'cnc': 'cnc programming',
          'lean': 'lean manufacturing',
          '6 sigma': 'six sigma',
          '6sigma': 'six sigma',
          'gd&t': 'gd&t',
          'geometric dimensioning': 'gd&t',
          'iso9001': 'iso 9001',
          '3d print': '3d printing',
          'additive manufacturing': '3d printing',

          // Electrónica/Automatización
          'plc': 'plc programming',
          'ladder logic': 'plc programming',
          'eagle': 'eagle pcb',
          'kicad': 'kicad',

          // Ingeniería Civil
          'autodesk civil 3d': 'civil 3d',
          'bim 360': 'bim',
          'building information modeling': 'bim',
          'ms project': 'ms project',
          'microsoft project': 'ms project',

          // Química
          'aspen': 'aspen plus',
          'aspentech': 'aspen plus',

          // Otros
          'ms excel': 'excel',
          'microsoft excel': 'excel',
          'powerbi': 'power bi',
          'microsoft power bi': 'power bi'
        };

        const normalized = variations[skillNameLower] || skillNameLower;
        dbSkill = dbSkills.find(s => s.name.toLowerCase() === normalized);

        // También buscar al revés
        if (!dbSkill) {
          const reverseKey = Object.keys(variations).find(key => variations[key] === skillNameLower);
          if (reverseKey) {
            dbSkill = dbSkills.find(s => s.name.toLowerCase() === reverseKey);
          }
        }
      }

      // 3. Búsqueda por similitud (fuzzy matching) > 80%
      if (!dbSkill) {
        let bestMatch = null;
        let bestScore = 0;

        for (const s of dbSkills) {
          const score = similarity(skillNameLower, s.name.toLowerCase());
          if (score > bestScore && score >= 0.8) {
            bestScore = score;
            bestMatch = s;
          }
        }

        if (bestMatch) {
          dbSkill = bestMatch;
          logger.info(`🔍 Fuzzy match: ${aiSkill.name} → ${bestMatch.name} (${Math.round(bestScore * 100)}%)`);
        }
      }

      if (dbSkill) {
        // Skill encontrada en BD
        found.push({
          aiSkill: aiSkill.name,
          dbSkillId: dbSkill.id,
          dbSkillName: dbSkill.name,
          sector: dbSkill.sector || 'General',
          level: level
        });
        logger.info(`✅ Skill mapeada: ${aiSkill.name} → ${dbSkill.name}`);
      } else {
        // Skill no encontrada - retornar como sugerencia
        notFound.push({
          name: aiSkill.name,
          level: level,
          suggested: true // Flag para que el usuario decida si agregar
        });
        logger.info(`⚠️ Skill no encontrada en BD: ${aiSkill.name}`);
      }
    }

    logger.info(`✅ Mapeo completado: ${found.length} encontradas, ${notFound.length} no encontradas`);

    // 7. Retornar resultado estructurado
    return {
      success: true,
      profile: {
        name: profile.name || '',
        email: profile.email || '',
        phone: profile.phone || '',
        summary: profile.summary || '',
        experience: profile.experience || [],
        education: profile.education || []
      },
      skills: {
        found: found,
        notFound: notFound
      }
    };

  } catch (error) {
    logger.error("❌ Error en extraerCV:", error);
    return {
      error: "Error procesando CV",
      message: error.message
    };
  }
});

/**
 * Guarda las skills confirmadas por el usuario en su perfil
 *
 * Input: {
 *   userId: string,
 *   confirmedSkills: [{ skillId: string, level: number, notes?: string }]
 * }
 * Output: { success: boolean, savedCount: number }
 */
exports.guardarSkillsConfirmadas = onCall({ secrets: [openaiKey] }, async (request) => {
  try {
    const { userId, confirmedSkills } = request.data || {};

    if (!userId || !Array.isArray(confirmedSkills)) {
      return { error: "❌ Parámetros inválidos" };
    }

    const db = admin.firestore();

    logger.info(`💾 Guardando ${confirmedSkills.length} skills para usuario ${userId}`);

    // Usar batch para operaciones atómicas
    const batch = db.batch();
    const userSkillsRef = db.collection('users').doc(userId).collection('professional_skills');

    for (const skillData of confirmedSkills) {
      const { skillId, level, notes } = skillData;

      // Obtener datos de la skill de la BD
      const skillDoc = await db.collection('skills').doc(skillId).get();
      if (!skillDoc.exists) {
        logger.warn(`⚠️ Skill no encontrada: ${skillId}`);
        continue;
      }

      const skillInfo = skillDoc.data();

      // Crear o actualizar UserSkill
      const userSkillRef = userSkillsRef.doc(skillId);
      batch.set(userSkillRef, {
        skillId: skillId,
        skillName: skillInfo.name,
        sector: skillInfo.sector || 'General',
        nature: skillInfo.nature || 'technical',
        skillNature: skillInfo.nature || 'technical',
        level: Math.min(Math.max(level, 1), 10), // Validar 1-10
        notes: notes || '',
        acquiredAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    await batch.commit();
    logger.info(`✅ Skills guardadas exitosamente`);

    return {
      success: true,
      savedCount: confirmedSkills.length
    };

  } catch (error) {
    logger.error("❌ Error guardando skills:", error);
    return {
      error: "Error guardando skills",
      message: error.message
    };
  }
});

// ========================================
// 🎯 GENERAR PROYECTO PMI CON IA
// ========================================

exports.generarProyectoPMI = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 540,
  memory: "512MiB"
}, async (request) => {
  try {
    const {
      documentosBase64,  // Array de documentos en base64
      nombreProyecto,
      descripcionBreve,
      userId
    } = request.data;

    if (!documentosBase64 || documentosBase64.length === 0) {
      throw new Error("Debe proporcionar al menos un documento");
    }

    logger.info(`📄 Generando proyecto PMI para: ${nombreProyecto}`);
    logger.info(`📦 Documentos recibidos: ${documentosBase64.length}`);

    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // 1. Extraer texto de todos los documentos PDF
    let textoCompleto = "";
    for (let i = 0; i < documentosBase64.length; i++) {
      try {
        const buffer = Buffer.from(documentosBase64[i], "base64");
        const pdfData = await pdfParse(buffer);
        textoCompleto += `\n\n=== DOCUMENTO ${i + 1} ===\n${pdfData.text}`;
        logger.info(`✅ Documento ${i + 1} parseado: ${pdfData.text.length} caracteres`);
      } catch (pdfError) {
        logger.error(`❌ Error parseando documento ${i + 1}:`, pdfError);
      }
    }

    if (!textoCompleto || textoCompleto.trim().length < 100) {
      return {
        error: "Los documentos no contienen suficiente texto extraíble"
      };
    }

    logger.info(`📝 Texto total extraído: ${textoCompleto.length} caracteres`);

    // 2. Generar estructura PMI con OpenAI
    const prompt = `
Eres un experto en gestión de proyectos siguiendo la metodología PMI (Project Management Institute).

Se te proporciona documentación de un proyecto llamado "${nombreProyecto}".
Descripción breve: ${descripcionBreve || "No especificada"}

Tu tarea es analizar los documentos y generar una estructura completa de proyecto PMI con las 5 fases estándar:
1. Iniciación
2. Planificación
3. Ejecución
4. Monitoreo y Control
5. Cierre

JERARQUÍA PMI (MUY IMPORTANTE):
Para cada fase, debes generar entregables, y dentro de cada entregable, paquetes de trabajo, y dentro de cada paquete, tareas.

Fase → Entregables → Paquetes de Trabajo → Tareas

Ejemplo de estructura correcta:
- Fase: "Iniciación"
  - Entregable: "Project Charter"
    - Paquete de Trabajo: "Documentación Inicial"
      - Tarea: "Redactar objetivos del proyecto"
      - Tarea: "Definir alcance preliminar"
    - Paquete de Trabajo: "Aprobaciones"
      - Tarea: "Obtener firma del sponsor"
  - Entregable: "Registro de Stakeholders"
    - Paquete de Trabajo: "Identificación de Partes Interesadas"
      - Tarea: "Listar stakeholders clave"

IMPORTANTE sobre ÁREAS:
- El campo "area" NO es para fases, es para RECURSOS (personas, equipos, materiales)
- Ejemplos de áreas correctas: "Equipo Desarrollo", "Consultor PMI", "Equipo Marketing"
- El campo "area" indica QUIÉN o QUÉ RECURSO ejecutará la tarea

DOCUMENTOS DEL PROYECTO:
${textoCompleto.substring(0, 15000)}

Devuelve la respuesta en formato JSON con esta estructura EXACTA:
{
  "objetivo": "...",
  "alcance": "...",
  "presupuestoEstimado": 0,
  "fases": [
    {
      "nombre": "Iniciación",
      "orden": 1,
      "descripcion": "...",
      "duracionDias": 0,
      "entregables": [
        {
          "nombre": "Project Charter",
          "descripcion": "...",
          "paquetesTrabajo": [
            {
              "nombre": "Documentación Inicial",
              "descripcion": "...",
              "tareas": [
                {
                  "titulo": "Redactar objetivos del proyecto",
                  "descripcion": "...",
                  "duracionDias": 3,
                  "prioridad": 5,
                  "habilidadesRequeridas": ["Gestión de Proyectos", "Redacción"],
                  "areaRecomendada": "Equipo PM"
                }
              ]
            }
          ]
        }
      ]
    }
  ],
  "riesgos": [
    {
      "descripcion": "...",
      "probabilidad": "alta|media|baja",
      "impacto": "alto|medio|bajo",
      "mitigacion": "..."
    }
  ],
  "stakeholders": [
    {
      "nombre": "...",
      "rol": "...",
      "interes": "alto|medio|bajo",
      "poder": "alto|medio|bajo"
    }
  ]
}

IMPORTANTE:
- Genera 2-4 entregables por fase
- Cada entregable debe tener 1-3 paquetes de trabajo
- Cada paquete de trabajo debe tener 2-5 tareas
- Total aproximado: 30-50 tareas en todo el proyecto
- Sé específico y profesional
- Usa habilidades técnicas reales (ej: "Python", "AutoCAD", "Gestión de riesgos")
- En "areaRecomendada" sugiere equipos/recursos específicos ("Equipo Backend", "Consultor Legal", etc.)
- Retorna SOLO el JSON válido, sin texto adicional
`;

    logger.info("🤖 Llamando a OpenAI GPT-4o-mini...");

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.3,
      max_tokens: 4000,
      messages: [
        {
          role: "system",
          content: "Eres un experto Project Manager certificado en PMI que estructura proyectos siguiendo las mejores prácticas del PMBOK."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content;
    logger.info(`✅ OpenAI respondió: ${content.length} caracteres`);

    // 3. Parsear respuesta JSON
    let proyectoPMI;
    try {
      const start = content.indexOf('{');
      const end = content.lastIndexOf('}');
      const jsonString = content.slice(start, end + 1);
      proyectoPMI = JSON.parse(jsonString);
    } catch (parseError) {
      logger.error("❌ Error parseando JSON de OpenAI", parseError);
      return {
        error: "La IA respondió algo que no es JSON válido",
        raw: content
      };
    }

    // 4. Validar estructura básica
    if (!proyectoPMI.fases || proyectoPMI.fases.length === 0) {
      return {
        error: "La estructura generada no contiene fases válidas"
      };
    }

    logger.info(`✅ Proyecto PMI generado con ${proyectoPMI.fases.length} fases`);

    const totalTareas = proyectoPMI.fases.reduce((sum, fase) =>
      sum + (fase.tareas?.length || 0), 0
    );
    logger.info(`📋 Total de tareas generadas: ${totalTareas}`);

    // 5. Retornar estructura completa
    return {
      success: true,
      proyecto: {
        nombre: nombreProyecto,
        descripcion: descripcionBreve || "",
        objetivo: proyectoPMI.objetivo,
        alcance: proyectoPMI.alcance,
        presupuestoEstimado: proyectoPMI.presupuestoEstimado || 0,
        fases: proyectoPMI.fases,
        riesgos: proyectoPMI.riesgos || [],
        stakeholders: proyectoPMI.stakeholders || [],
        generadoPorIA: true,
        fechaGeneracion: admin.firestore.FieldValue.serverTimestamp()
      }
    };

  } catch (error) {
    logger.error("❌ Error generando proyecto PMI:", error);
    return {
      error: "Error generando proyecto PMI",
      message: error.message
    };
  }
});
