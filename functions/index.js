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
