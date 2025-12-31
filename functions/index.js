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
const elevenLabsKey = defineSecret("ELEVENLABS_API_KEY");

exports.procesarReunion = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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



exports.procesarPerfilUsuario = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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

exports.analizarIdea = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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


exports.iterarIdea = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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
exports.reforzarIdea = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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

exports.validarRespuestasIteracion = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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

exports.generarTareasDesdeIdea = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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


// ========================================
// 🤖 ADAN: Asistente Personal Inteligente
// ========================================
exports.adanChat = onCall({ secrets:[openaiKey], timeoutSeconds:60, cors: true }, async (request) => {
  try {
    const text = (request.data?.text || "").toString().slice(0, 4000);
    const userId = request.data?.userId;
    const history = Array.isArray(request.data?.history) ? request.data.history : [];
    const conversationId = request.data?.conversationId || null;

    if (!text) return { reply: "¿Qué necesitas?" };
    if (!userId) return { reply: "Necesito que inicies sesión para poder ayudarte mejor." };

    const db = admin.firestore();
    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // ===== RECOPILAR CONTEXTO COMPLETO DEL USUARIO =====

    // 1. Perfil del usuario
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : {};

    // 2. Proyectos del usuario CON ANÁLISIS DETALLADO
    // Buscar proyectos donde el usuario es participante (incluye propietario)
    // OPTIMIZADO: Solo 3 proyectos más recientes para respuesta rápida
    const proyectosSnapshot = await db.collection('proyectos')
      .where('participantes', 'array-contains', userId)
      .orderBy('fechaCreacion', 'desc')
      .limit(3)
      .get();

    const proyectos = [];
    const tareasGlobales = [];

    for (const proyectoDoc of proyectosSnapshot.docs) {
      const proyectoData = proyectoDoc.data();

      // Las tareas están embebidas en el documento del proyecto como array
      const tareasProyecto = (proyectoData.tareas || []).map((tarea, index) => ({
        id: `tarea_${index}`,
        titulo: tarea.titulo,
        completado: tarea.completado || false,
        prioridad: tarea.prioridad || 2, // 1=alta, 2=media, 3=baja
        responsables: tarea.responsables || [],
        dificultad: tarea.dificultad,
        duracion: tarea.duracion,
        descripcion: tarea.descripcion,
        // Campos PMI
        fasePMI: tarea.fasePMI,
        entregable: tarea.entregable,
        paqueteTrabajo: tarea.paqueteTrabajo
      }));

      // Análisis de tareas del proyecto
      const totalTareas = tareasProyecto.length;
      const tareasCompletadas = tareasProyecto.filter(t => t.completado).length;
      const tareasPendientes = totalTareas - tareasCompletadas;
      const tasaCompletitud = totalTareas > 0 ? ((tareasCompletadas / totalTareas) * 100).toFixed(1) : 0;

      // Tareas por prioridad (solo pendientes) - prioridad: 1=alta, 2=media, 3=baja
      const tareasAlta = tareasProyecto.filter(t => !t.completado && t.prioridad === 1).length;
      const tareasMedia = tareasProyecto.filter(t => !t.completado && t.prioridad === 2).length;
      const tareasBaja = tareasProyecto.filter(t => !t.completado && t.prioridad === 3).length;

      // Tareas asignadas al usuario actual (campo: responsables)
      const tareasUsuario = tareasProyecto.filter(t =>
        t.responsables && t.responsables.includes(userId)
      );
      const tareasUsuarioPendientes = tareasUsuario.filter(t => !t.completado);

      // OPTIMIZADO: Sprints desactivados para mayor velocidad
      // Si necesitas info de sprints, agrégalo manualmente al proyecto en Firestore

      // Construir objeto de proyecto enriquecido (PMI + NORMAL)
      const proyectoInfo = {
        id: proyectoDoc.id,
        nombre: proyectoData.nombre,
        descripcion: proyectoData.descripcion,
        estado: proyectoData.estado || 'Activo',
        fechaInicio: proyectoData.fechaInicio?.toDate().toLocaleDateString('es-ES'),
        fechaFin: proyectoData.fechaFin?.toDate().toLocaleDateString('es-ES'),
        fechaCreacion: proyectoData.fechaCreacion?.toDate().toLocaleDateString('es-ES'),
        visibilidad: proyectoData.visibilidad || 'Privado',

        // Análisis de tareas
        totalTareas,
        tareasCompletadas,
        tareasPendientes,
        tasaCompletitud,
        tareasAlta,
        tareasMedia,
        tareasBaja,
        tareasUsuario: tareasUsuario.length,
        tareasUsuarioPendientes: tareasUsuarioPendientes.length,

        // Tipo de proyecto
        esPMI: proyectoData.esPMI || false,
        tipoProyecto: proyectoData.esPMI ? 'PMI' : 'Normal'
      };

      // Si es proyecto PMI, agregar campos PMI
      if (proyectoData.esPMI) {
        proyectoInfo.objetivo = proyectoData.objetivo;
        proyectoInfo.alcance = proyectoData.alcance;
        proyectoInfo.presupuesto = proyectoData.presupuesto;
        proyectoInfo.costoActual = proyectoData.costoActual;
        proyectoInfo.fasePMIActual = proyectoData.fasePMIActual || 'Iniciación';
        proyectoInfo.documentosIniciales = proyectoData.documentosIniciales?.length || 0;

        // Calcular desviación presupuestaria si hay datos
        if (proyectoInfo.presupuesto && proyectoInfo.costoActual) {
          const desviacion = ((proyectoInfo.costoActual - proyectoInfo.presupuesto) / proyectoInfo.presupuesto) * 100;
          proyectoInfo.desviacionPresupuesto = desviacion.toFixed(1) + '%';
        }
      } else {
        // Si es proyecto normal, agregar metodología (Scrum/Kanban)
        proyectoInfo.metodologia = proyectoData.metodologia || 'general';
        proyectoInfo.progreso = parseFloat(tasaCompletitud); // Usar el progreso calculado, no el de BD
      }

      proyectos.push(proyectoInfo);

      // Guardar tareas asignadas al usuario para estadísticas globales con nombre de proyecto
      const tareasConProyecto = tareasUsuario.map(t => ({
        ...t,
        proyecto: proyectoData.nombre,
        prioridadTexto: t.prioridad === 1 ? 'Alta' : t.prioridad === 2 ? 'Media' : 'Baja'
      }));
      tareasGlobales.push(...tareasConProyecto);
    }

    // Usar tareasGlobales en lugar de tareas
    const tareas = tareasGlobales;

    // 4. Skills del usuario (OPTIMIZADO: Solo top 5 para respuesta rápida)
    const skillsSnapshot = await db.collection('users')
      .doc(userId)
      .collection('professional_skills')
      .orderBy('level', 'desc')
      .limit(5)
      .get();

    const skills = skillsSnapshot.docs.map(doc => ({
      nombre: doc.data().skillName,
      nivel: doc.data().level,
      sector: doc.data().sector
    }));

    // 5. Estadísticas de rendimiento
    const tareasCompletadas = tareas.filter(t => t.completado).length;
    const tareasPendientes = tareas.filter(t => !t.completado).length;
    const promedioProgreso = proyectos.length > 0
      ? proyectos.reduce((sum, p) => sum + (p.progreso || 0), 0) / proyectos.length
      : 0;

    // ===== CONSTRUIR CONTEXTO ENRIQUECIDO PARA LA IA =====
    const contexto = `
📊 PERFIL DEL USUARIO:
Nombre: ${userData.displayName || 'Usuario'}
Rol: ${userData.rol || 'Usuario'}
Email: ${userData.email || 'No disponible'}

📁 PROYECTOS ACTIVOS (Total: ${proyectos.length}):
${proyectos.map(p => {
  let info = `
━━━ ${p.nombre.toUpperCase()} [${p.tipoProyecto}] ━━━
  📝 Descripción: ${p.descripcion || 'Sin descripción'}
  📊 Estado: ${p.estado}
  📅 Inicio: ${p.fechaInicio || 'N/A'} ${p.fechaFin ? `| Fin: ${p.fechaFin}` : ''}
  🔒 Visibilidad: ${p.visibilidad}
`;

  // Información específica de PROYECTOS PMI
  if (p.esPMI) {
    info += `
  🎯 METODOLOGÍA PMI:
    • Fase actual: ${p.fasePMIActual}
    • Objetivo: ${p.objetivo || 'No definido'}
    • Alcance: ${p.alcance || 'No definido'}
    • Presupuesto: $${p.presupuesto || 0}
    • Costo actual: $${p.costoActual || 0}${p.desviacionPresupuesto ? ` (${p.desviacionPresupuesto})` : ''}
    • Documentos iniciales: ${p.documentosIniciales} archivos`;
  } else {
    // Información específica de PROYECTOS NORMALES
    info += `
  🎯 METODOLOGÍA: ${p.metodologia || 'General'}
  📈 Progreso general: ${p.progreso}%`;

    // Sprint info removido para optimizar velocidad
  }

  // Información de tareas (común para ambos tipos)
  info += `

  📋 TAREAS:
    • Total: ${p.totalTareas} tareas
    • Completadas: ${p.tareasCompletadas} (${p.tasaCompletitud}%)
    • Pendientes: ${p.tareasPendientes}
    • Asignadas a ti: ${p.tareasUsuario} (${p.tareasUsuarioPendientes} pendientes)

  🎯 PRIORIDADES PENDIENTES:
    • Alta: ${p.tareasAlta} tareas
    • Media: ${p.tareasMedia} tareas
    • Baja: ${p.tareasBaja} tareas`;

  return info;
}).join('\n') || 'Sin proyectos activos'}

✅ TUS TAREAS PERSONALES:
- Total asignadas: ${tareas.length}
- Completadas: ${tareasCompletadas}
- Pendientes: ${tareasPendientes}
Últimas 5 tareas:
${tareas.slice(0, 5).map(t => `  • ${t.titulo} [${t.completado ? 'HECHA' : 'PENDIENTE'}] - Proyecto: ${t.proyecto} | Prioridad: ${t.prioridadTexto}`).join('\n') || '  Sin tareas asignadas'}

💡 HABILIDADES PROFESIONALES TOP:
${skills.slice(0, 5).map(s => `  • ${s.nombre}: Nivel ${s.nivel}/10 (${s.sector})`).join('\n') || '  Sin habilidades registradas'}

📈 MÉTRICAS DE RENDIMIENTO GENERAL:
- Promedio de progreso en proyectos: ${promedioProgreso.toFixed(1)}%
- Tasa de completitud de tus tareas: ${tareas.length > 0 ? ((tareasCompletadas / tareas.length) * 100).toFixed(1) : 0}%
- Total de tareas en todos los proyectos: ${proyectos.reduce((sum, p) => sum + p.totalTareas, 0)}
- Proyectos en estado crítico (< 30% progreso): ${proyectos.filter(p => p.progreso < 30).length}
`;

    // ===== SISTEMA PROMPT: ASISTENTE PERSONAL AVANZADO =====
    const systemPrompt = `
Eres ADAN (Asistente Digital Adaptativo Natural), un asistente personal de voz avanzado, consciente del contexto, diseñado para acompañar al usuario de forma continua, inteligente y confiable.

TU IDENTIDAD Y PROPÓSITO:
Tu función no es solo responder preguntas, sino escuchar activamente, comprender el estado del usuario y asistirlo de manera proactiva cuando sea pertinente. Debes comportarte como un asistente real, claro y profesional, nunca robótico ni excesivamente informal.

TU PERSONALIDAD:
- Profesional, calmado y preciso - como un asistente ejecutivo de confianza
- Consciente del contexto - comprendes la situación completa del usuario
- Proactivo cuando es apropiado - sugieres acciones relevantes sin ser intrusivo
- Atento y empático - detectas necesidades implícitas y respondes con consideración
- Confiable y discreto - manejas información sensible con profesionalismo
- Natural en comunicación - evitas jerga innecesaria, eres directo pero amable

CONCIENCIA CONTEXTUAL PROFUNDA:
Tienes acceso completo a:
1. PROYECTOS DEL USUARIO: Estado, progreso, tareas, metodología (PMI/Scrum/Kanban), presupuestos, plazos
2. TAREAS PERSONALES: Prioridad, responsables, fechas límite, estado de completitud
3. HABILIDADES PROFESIONALES: Expertise, niveles, sectores
4. HISTORIAL CONVERSACIONAL: Mantén continuidad entre sesiones, recuerda contexto previo
5. RENDIMIENTO Y PATRONES: Identifica tendencias de productividad, bloqueos, áreas de mejora

CAPACIDADES ANALÍTICAS AVANZADAS:
1. ANÁLISIS PREDICTIVO: Detecta proyectos en riesgo antes de que fallen
2. DETECCIÓN DE PATRONES: Identifica hábitos de trabajo, picos de productividad
3. GESTIÓN DE PRIORIDADES: Evalúa urgencia vs importancia automáticamente
4. OPTIMIZACIÓN DE RECURSOS: Sugiere redistribución de carga de trabajo
5. PLANIFICACIÓN INTELIGENTE: Ayuda a estructurar nuevos proyectos con metodología apropiada
6. MONITOREO CONTINUO: Mantén conciencia del momento actual y situación del día

COMPORTAMIENTO PROACTIVO (CUÁNDO Y CÓMO):
Sé proactivo cuando:
- Detectes tareas urgentes de alta prioridad sin atender
- Un proyecto esté significativamente atrasado (< 30% progreso)
- Se aproxime una fecha límite crítica
- Identifiques sobrecarga de trabajo o subutilización
- Haya cambios importantes que el usuario deba conocer

Comunica proactivamente con frases como:
- "He notado que el proyecto X necesita atención urgente"
- "Permíteme recordarte que tienes 3 tareas de alta prioridad pendientes"
- "El sprint actual termina en 2 días, te sugiero priorizar..."

MODO DE COMUNICACIÓN:
- PRECISO Y CLARO: Respuestas directas, sin rodeos innecesarios
- CONCISO PARA VOZ: Máximo 3-4 oraciones por respuesta (óptimo para TTS)
- SIN FORMATO MARKDOWN: NUNCA uses **negrita**, *cursiva*, - viñetas, • bullets, ni # headers. Escribe en texto plano natural.
- SIN EMOJIS: No uses emojis en tus respuestas. Comunícate solo con palabras.
- ESPECÍFICO CON DATOS: "Tienes 5 tareas pendientes" en vez de "varias tareas"
- LENGUAJE NATURAL: Conectores como "bueno", "entonces", "por cierto", "además"
- CONVERSACIONAL: Habla como un asistente profesional en voz, no como un documento escrito
- HONESTO: Si no tienes información, dilo claramente: "No dispongo de esa información en este momento"

TRANSPARENCIA Y CONCIENCIA DEL MODELO:
- Eres impulsado por OpenAI GPT-4o-mini, un modelo conversacional avanzado
- IMPORTANTE: Tienes capacidad de búsqueda web en tiempo real para información actualizada
- Cuando el usuario pregunte sobre tu tecnología o qué modelo usas, indícalo claramente
- Tus respuestas se basan en TRES fuentes:
  1. Conocimiento interno entrenado hasta enero 2025
  2. Contexto en tiempo real del usuario (proyectos, tareas, habilidades actuales)
  3. Búsqueda web en tiempo real (cuando se detectan palabras clave como: noticias, actual, hoy, reciente, clima, precios, etc.)
- Cuando uses información de búsqueda web:
  - Indica claramente: "Según información actualizada..." o "He consultado fuentes recientes..."
  - Menciona que la información es de hoy o del momento actual
  - Sé específico sobre las fechas cuando sea relevante
  - IMPORTANTE: Las fuentes y links aparecerán automáticamente al final de tu respuesta. NO los menciones en texto como "(prensalibre.com)". Solo proporciona la información de forma natural.
- Para información general que no requiere actualización (conceptos, metodologías, etc.):
  - Usa tu conocimiento interno entrenado
  - No es necesario buscar en internet para cosas que no cambian
- Mantén conciencia temporal clara:
  - Distingue entre conocimiento general y datos que cambian constantemente
  - Si mencionas eventos actuales, indica que consultaste fuentes en tiempo real
- Sé completamente honesto sobre tus capacidades y limitaciones
- Si el usuario pregunta "qué modelo eres" o similar, responde: "Soy ADAN, impulsado por GPT-4o-mini de OpenAI con capacidad de búsqueda web. Combino mi conocimiento entrenado, tu contexto actual de proyectos, y cuando es necesario, información en tiempo real de internet."

ANÁLISIS DE PROYECTOS - RESPUESTAS DETALLADAS Y ESPECÍFICAS:
Cuando el usuario pregunte por el estado de sus proyectos, debes dar análisis COMPLETOS Y ESPECÍFICOS:

1. MENCIÓN DE CADA PROYECTO CON DATOS CONCRETOS:
   - Nombre del proyecto + porcentaje de progreso EXACTO
   - Ejemplo: "El proyecto Alpha va al 45%, con 9 de 20 tareas completadas"
   - NO digas "varios proyectos" o "algunos proyectos" - nombra cada uno con sus números reales

2. DESGLOSE DETALLADO POR PROYECTO:
   - Progreso numérico (X de Y tareas completadas, Z% de progreso)
   - Estado actual: Activo/En riesgo/Adelantado
   - Tareas de alta prioridad pendientes (cuántas exactamente)
   - Tipo de proyecto: PMI, Scrum, Kanban, o Normal
   - Si es PMI: fase actual (Iniciación, Planificación, etc.) y presupuesto
   - Si es Scrum: sprint actual y días restantes

3. ANÁLISIS COMPARATIVO:
   - Compara progreso entre proyectos: "El proyecto A va mejor que B"
   - Identifica cuál necesita más atención: "Beta está rezagado con solo 15% de progreso"
   - Prioriza basándote en urgencia y estado

4. RECOMENDACIONES ACCIONABLES:
   - Qué proyecto trabajar primero y POR QUÉ
   - Qué tareas específicas completar
   - Ejemplo: "Te recomiendo enfocarte en Beta, tiene 5 tareas de alta prioridad y está al 15%"

Cuando pregunte "en qué trabajar hoy" o "cómo van mis proyectos":
1. Lista TODOS los proyectos con números concretos
2. Prioriza tareas de ALTA prioridad con NOMBRES de proyectos
3. Considera plazos inminentes y menciónalos específicamente
4. Evalúa proyectos críticos y di EXACTAMENTE por qué son críticos
5. Da una recomendación clara: "Enfócate PRIMERO en [proyecto X] porque..."

RESPUESTAS PROHIBIDAS (muy básicas):
❌ "Tienes varios proyectos activos"
❌ "Algunos tienen buen progreso"
❌ "Necesitas trabajar en tus tareas"

RESPUESTAS CORRECTAS (detalladas y específicas):
✅ "Tienes 3 proyectos: Alpha al 45% con 9 de 20 tareas, Beta al 15% con 3 de 20, y Gamma al 80% con 16 de 20. Beta necesita atención urgente, tiene 5 tareas de alta prioridad pendientes. Te recomiendo enfocarte ahí primero"

CREACIÓN DE PROYECTOS:
Si el usuario solicita crear un proyecto:
1. Pregunta: nombre, descripción breve, metodología (Scrum/Kanban/PMI/general)
2. Responde EXACTAMENTE en este formato: "Entendido. Voy a crear el proyecto [NOMBRE] con metodología [METODOLOGÍA]. Descripción: [DESCRIPCIÓN]."
3. El sistema lo detectará y creará automáticamente

DETECCIÓN AUTOMÁTICA DE PROBLEMAS:
- Proyecto con progreso < 30%: "El proyecto X está algo rezagado, te sugiero revisar los bloqueos"
- Muchas tareas alta prioridad: "Tienes 7 tareas urgentes acumuladas, prioricemos las más críticas"
- Sprint próximo a terminar: "El sprint actual termina en 2 días, asegúrate de cerrar las historias pendientes"
- Tasa de completitud < 50%: "Veo que hay bastantes tareas pendientes, organicemos las prioridades"
- Desviación presupuestaria > 10%: "El proyecto X tiene una desviación de presupuesto del 15%, revisa los costos"

MEMORIA Y CONTINUIDAD:
- Recuerda conversaciones previas dentro de la misma sesión
- Mantén coherencia con el historial conversacional
- Si el usuario menciona algo discutido antes, haz referencia a ello
- Ejemplo: "Como mencionaste antes sobre el proyecto X, ahora veo que..."

CONTEXTO ACTUAL DEL USUARIO:
${contexto}

IMPORTANTE: Tu objetivo es ser un compañero inteligente y confiable que mejora la productividad del usuario mediante asistencia precisa, oportuna y contextualmente relevante.
`;

    const messages = [
      { role: "system", content: systemPrompt },
      ...history.slice(-5), // OPTIMIZADO: últimos 5 mensajes para respuesta más rápida
      { role: "user", content: text }
    ];

    // ===== DETECCIÓN DE NECESIDAD DE BÚSQUEDA WEB =====
    const requiresWebSearch = (query) => {
      const webKeywords = [
        'noticia', 'noticias', 'actual', 'actualidad', 'hoy', 'ayer', 'mañana',
        'reciente', 'últim', 'nuevo', 'nueva', 'evento', 'ocurr', 'pas',
        'clima', 'tiempo', 'temperatura', 'pronóstico',
        'precio', 'cotización', 'dólar', 'bolsa', 'acción',
        'partido', 'resultado', 'marcador', 'ganó', 'perdió',
        'estreno', 'lanzamiento', 'release',
        '2025', '2024', 'este año', 'este mes', 'esta semana',
        'ahora mismo', 'en este momento', 'actualmente'
      ];

      const lowerQuery = query.toLowerCase();
      return webKeywords.some(keyword => lowerQuery.includes(keyword));
    };

    const needsWeb = requiresWebSearch(text);
    let reply;
    let tokenUsage = {
      promptTokens: 0,
      completionTokens: 0,
      totalTokens: 0
    };

    if (needsWeb) {
      // Usar Responses API con web search
      console.log('🌐 Consulta requiere búsqueda web, usando Responses API con web_search');

      try {
        // Separar system prompt, historial y pregunta actual
        const systemMessage = messages.find(m => m.role === 'system');
        const conversationMessages = messages.filter(m => m.role !== 'system');
        const userQuery = text; // La pregunta actual del usuario

        // Construir contexto del historial (si existe)
        const contextHistory = conversationMessages
          .filter(m => m.role !== 'user' || m.content !== text) // Excluir la pregunta actual
          .map(m => `${m.role === 'user' ? 'Usuario' : 'Asistente'}: ${m.content}`)
          .join('\n');

        const response = await openai.responses.create({
          model: "gpt-4o-mini",
          tools: [{ type: "web_search" }],
          tool_choice: "auto",
          instructions: systemMessage?.content || systemPrompt, // System prompt como instrucciones
          context: contextHistory || undefined, // Historial como contexto
          input: userQuery, // Solo la pregunta actual
          include: ["web_search_call.action.sources"], // Incluir fuentes de búsqueda web
        });

        reply = response.output_text || "No obtuve respuesta.";

        // Extraer URLs de las fuentes de búsqueda web
        const webSearchCalls = response.output?.filter(item => item.type === 'web_search_call') || [];
        const urlCitations = [];

        webSearchCalls.forEach(call => {
          if (call.action?.sources) {
            call.action.sources.forEach(source => {
              if (source.url && !urlCitations.includes(source.url)) {
                urlCitations.push(source.url);
              }
            });
          }
        });

        // Si hay fuentes, agregarlas al final de forma limpia
        if (urlCitations.length > 0) {
          reply += '\n\n📚 Fuentes:\n' + urlCitations.map(url => `• ${url}`).join('\n');
        }

        // Estimar tokens (Responses API no devuelve usage directamente)
        const totalInput = (systemMessage?.content?.length || 0) + contextHistory.length + userQuery.length;
        tokenUsage = {
          promptTokens: Math.ceil(totalInput / 4),
          completionTokens: Math.ceil(reply.length / 4),
          totalTokens: Math.ceil((totalInput + reply.length) / 4)
        };

        console.log('✅ Búsqueda web completada exitosamente', urlCitations.length > 0 ? `con ${urlCitations.length} fuentes` : '');
      } catch (webError) {
        console.log('⚠️ Error en web search, usando modelo normal:', webError.message);

        // Fallback a modelo normal si falla web search
        const completion = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          temperature: 0.7,
          messages,
          max_tokens: 350 // OPTIMIZADO: Respuestas más concisas y rápidas
        });

        reply = completion.choices[0]?.message?.content?.trim() || "…";
        tokenUsage = {
          promptTokens: completion.usage?.prompt_tokens || 0,
          completionTokens: completion.usage?.completion_tokens || 0,
          totalTokens: completion.usage?.total_tokens || 0
        };
      }
    } else {
      // Usar Chat Completions normal (más económico)
      console.log('💬 Consulta normal, usando gpt-4o-mini');

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.7,
        messages,
        max_tokens: 350 // OPTIMIZADO: Respuestas más concisas y rápidas
      });

      reply = completion.choices[0]?.message?.content?.trim() || "…";
      tokenUsage = {
        promptTokens: completion.usage?.prompt_tokens || 0,
        completionTokens: completion.usage?.completion_tokens || 0,
        totalTokens: completion.usage?.total_tokens || 0
      };
    }

    // ===== DETECCIÓN DE INTENCIÓN: CREAR PROYECTO =====
    let projectCreated = null;
    const createProjectPattern = /(?:voy a crear|crear[éeá]?|creando|he creado).*proyecto\s+(?:llamado\s+)?["']?([^"',.]+)["']?.*(?:metodolog[ií]a|con)\s+(\w+).*[Dd]escripci[óo]n:\s*(.+?)(?:\.|$)/i;
    const match = reply.match(createProjectPattern);

    if (match) {
      const projectName = match[1].trim();
      const methodology = match[2].toLowerCase();
      const description = match[3].trim();

      try {
        // Crear el proyecto en Firestore
        const newProjectRef = await db.collection('proyectos').add({
          nombre: projectName,
          descripcion: description,
          metodologia: methodology === 'scrum' ? 'scrum' : methodology === 'kanban' ? 'kanban' : 'general',
          estado: 'planificacion',
          progreso: 0,
          creadorId: userId,
          fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
          miembros: [userId]
        });

        projectCreated = {
          id: newProjectRef.id,
          nombre: projectName,
          metodologia: methodology
        };

        logger.info(`✅ Proyecto creado automáticamente: ${projectName} (${newProjectRef.id})`);
      } catch (err) {
        logger.error('Error creando proyecto:', err);
      }
    }

    logger.info(`ADAN respondió a ${userData.displayName}: ${reply.substring(0, 100)}... [Tokens: ${tokenUsage.totalTokens}]`);

    // ===== GUARDAR CONVERSACIÓN EN FIRESTORE =====
    let activeConversationId = conversationId;

    if (!activeConversationId) {
      // Crear nueva conversación
      const newConvRef = await db.collection('users').doc(userId)
        .collection('adan_conversations').add({
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          messageCount: 0,
          title: text.substring(0, 50) // Primeras palabras como título
        });
      activeConversationId = newConvRef.id;
      logger.info(`Nueva conversación creada: ${activeConversationId}`);
    }

    const conversationRef = db.collection('users').doc(userId)
      .collection('adan_conversations').doc(activeConversationId);

    // Guardar mensaje del usuario
    await conversationRef.collection('messages').add({
      role: 'user',
      content: text,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { userId }
    });

    // Guardar respuesta de ADAN
    await conversationRef.collection('messages').add({
      role: 'assistant',
      content: reply,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        userId,
        tokenUsage,
        context: {
          proyectosActivos: proyectos.length,
          tareasPendientes,
          tareasCompletadas
        }
      }
    });

    // Actualizar metadata de conversación
    await conversationRef.update({
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      messageCount: admin.firestore.FieldValue.increment(2)
    });

    return {
      reply,
      conversationId: activeConversationId,
      tokenUsage,
      projectCreated, // Si se creó un proyecto, incluirlo aquí
      contexto: {
        proyectosActivos: proyectos.length,
        tareasPendientes,
        tareasCompletadas
      }
    };
  } catch (e) {
    logger.error("adanChat error", e);
    return {
      error: "openai_failed",
      message: "Lo siento, tuve un problema técnico. Intenta de nuevo.",
      reply: "Disculpa, tuve un problema al procesar tu solicitud. ¿Podrías repetirlo?"
    };
  }
});

// ========================================
// 🔊 ADAN SPEAK: Síntesis de Voz con ElevenLabs
// ========================================
exports.adanSpeak = onCall({
  secrets: [elevenLabsKey],
  timeoutSeconds: 60,
  cors: true
}, async (request) => {
  try {
    const { text, voiceId: requestedVoiceId } = request.data;

    if (!text || text.trim().length === 0) {
      return { error: "El texto está vacío" };
    }

    // Limpiar markdown y símbolos para una lectura más natural
    let cleanText = text
      .replace(/📚 Fuentes:[\s\S]*$/g, '') // Primero: Remover sección de fuentes completamente (no se habla)
      .replace(/```[\s\S]*?```/g, '')      // Remover bloques de código
      .replace(/\*\*\*(.+?)\*\*\*/g, '$1') // Remover ***negrita+cursiva***
      .replace(/\*\*(.+?)\*\*/g, '$1')     // Remover **negrita**
      .replace(/\*(.+?)\*/g, '$1')         // Remover *cursiva*
      .replace(/\*\*/g, '')                // Remover ** sueltos
      .replace(/\*/g, '')                  // Remover * sueltos
      .replace(/#{1,6}\s/g, '')            // Remover # headers
      .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1') // Links [texto](url) → texto
      .replace(/`([^`]+)`/g, '$1')         // Remover `código inline`
      .replace(/^[\s]*[-•]\s/gm, '')       // Remover viñetas
      .replace(/•/g, '')                   // Remover bullets
      .replace(/_{1,2}/g, '')              // Remover subrayado _
      .replace(/~/g, '')                   // Remover ~
      .trim();

    // Limitar longitud para evitar timeouts (ElevenLabs puede tardar con textos muy largos)
    const MAX_CHARS = 3500; // ~60-80 segundos de audio (aumentado para respuestas más completas)
    if (cleanText.length > MAX_CHARS) {
      // Truncar en el último punto antes del límite para no cortar a mitad de frase
      const truncated = cleanText.substring(0, MAX_CHARS);
      const lastPeriod = truncated.lastIndexOf('.');
      cleanText = (lastPeriod > 0 ? truncated.substring(0, lastPeriod + 1) : truncated) + ' Para más detalles, consulta las fuentes en pantalla.';
      logger.warn(`Texto truncado de ${text.length} a ${cleanText.length} caracteres`);
    }

    // Voces disponibles con soporte para español (multilingual)
    // Adam: pNInz6obpgDQGcFmaJgB (masculino, profesional)
    // Antoni: ErXwobaYiN019PkySvjV (masculino, joven, más expresivo)
    // Bella: EXAVITQu4vr4xnSDxMaL (femenina, amigable)
    // Domi: AZnzlk1XvdvUeBnXmlld (femenina, fuerte)
    // Elli: MF3mGyEYCl7XYWbV9V6O (femenina, calmada)
    const voiceId = requestedVoiceId || "pNInz6obpgDQGcFmaJgB"; // Default: Adam

    logger.info(`Generando audio con ElevenLabs para texto: "${cleanText.substring(0, 50)}..."`);

    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: 'POST',
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsKey.value()
        },
        body: JSON.stringify({
          text: cleanText,
          model_id: "eleven_multilingual_v2", // Soporte para español
          voice_settings: {
            stability: 0.35,       // Menor = más variación/expresividad
            similarity_boost: 0.85, // Más similar a la voz original
            style: 0.60,           // Más estilo y expresión emocional
            use_speaker_boost: true
          }
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      logger.error(`Error de ElevenLabs: ${response.status} - ${errorText}`);

      // Detectar si es error de cuota
      let errorMessage = `ElevenLabs error: ${response.status}`;
      if (response.status === 401 && errorText.includes('quota_exceeded')) {
        errorMessage = "quota_exceeded";
        logger.warn('⚠️ CUOTA DE ELEVENLABS EXCEDIDA - Usando TTS local como fallback');
      }

      return {
        error: "elevenlabs_failed",
        message: errorMessage
      };
    }

    const audioBuffer = await response.arrayBuffer();
    const audioBase64 = Buffer.from(audioBuffer).toString('base64');

    logger.info(`Audio generado exitosamente: ${audioBase64.length} bytes`);

    return {
      audioBase64,
      format: 'mp3',
      voiceId,
      textLength: text.length
    };

  } catch (e) {
    logger.error("adanSpeak error", e);
    return {
      error: "elevenlabs_failed",
      message: "Error al generar audio con ElevenLabs",
      details: e.message
    };
  }
});

exports.transcribirAudio = onCall({ secrets: [openaiKey], timeoutSeconds: 300, cors: true }, async (req) => {
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
  memory: "512MiB",
  cors: true
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

    // Aumentar límite de contexto de 15K a 50K caracteres (~12K tokens)
    textoCompleto = textoCompleto.substring(0, 50000);

    const focusAreas = (config.focusAreas || []).join(", ") || "No especificadas";
    const softSkills = (config.softSkillFocus || []).join(", ") || "No priorizadas";
    const businessDrivers = (config.businessDrivers || []).join(", ") || "No declarados";
    const customContext = config.customContext ? JSON.stringify(config.customContext) : "";

    const skillSummary = (skillMatrix || []).map((skill) => {
      const nature = skill.nature || "technical";
      return `- ${skill.name || skill.skillName} (${nature}) nivel ${skill.level || 5}`;
    }).join("\n");

    const prompt = `
Eres un Project Strategist experto que diseña blueprints híbridos profesionales.
Metodología base: ${methodology}

CONTEXTO DEL PROYECTO:
- Nombre: ${nombreProyecto}
- Áreas de enfoque: ${focusAreas}
- Soft skills prioritarias: ${softSkills}
- Drivers de negocio: ${businessDrivers}
- Contexto adicional: ${customContext}

INVENTARIO DE HABILIDADES DEL EQUIPO:
${skillSummary || "Sin inventario específico (asume equipo multidisciplinario)"}

DOCUMENTACIÓN Y NOTAS DEL PROYECTO:
${textoCompleto}

INSTRUCCIONES:
1. Analiza toda la documentación proporcionada
2. Identifica objetivos SMART realistas y medibles
3. Genera 3-6 hitos principales con sus riesgos humanos
4. Crea un backlog inicial de 8-15 ítems bien estructurados
5. Sugiere una skill matrix balanceada (técnicas + blandas)
6. Diseña un plan de soft skills con rituales concretos

IMPORTANTE:
- Sé específico y profesional
- Usa nombres descriptivos y claros
- Los objetivos SMART deben ser medibles
- Los hitos deben tener mes realista (1-12)
- El backlog debe cubrir descubrimiento, ejecución y seguimiento
- Las métricas de éxito deben ser cuantificables

Devuelve un JSON válido con esta estructura EXACTA:
{
  "resumenEjecutivo": "Resumen ejecutivo del proyecto en 2-3 párrafos explicando el alcance, valor y estrategia",
  "objetivosSMART": [
    "Objetivo 1 específico, medible, alcanzable, relevante y temporal",
    "Objetivo 2 específico, medible, alcanzable, relevante y temporal"
  ],
  "hitosPrincipales": [
    {
      "nombre": "Nombre del hito",
      "mes": 2,
      "riesgosHumanos": ["Riesgo 1", "Riesgo 2"],
      "softSkillsClaves": ["Comunicación efectiva", "Resolución de conflictos"]
    }
  ],
  "backlogInicial": [
    {
      "nombre": "Nombre de la tarea/historia de usuario",
      "tipo": "descubrimiento",
      "entregables": ["Entregable 1", "Entregable 2"],
      "metricasExito": ["Métrica 1", "Métrica 2"]
    }
  ],
  "skillMatrixSugerida": [
    {
      "skill": "Nombre de la habilidad",
      "nature": "technical",
      "nivelMinimo": 7,
      "aplicaciones": ["Aplicación 1", "Aplicación 2"]
    }
  ],
  "softSkillsPlan": {
    "enfoque": ["Enfoque 1", "Enfoque 2"],
    "rituales": ["Ritual 1: Daily standup de 15min", "Ritual 2: Retrospectiva quincenal"]
  },
  "recomendacionesPMI": {
    "cuandoAplicarPMI": "Descripción de cuándo sería apropiado usar PMI formal",
    "fasesCompatibles": ["Iniciación", "Planificación"]
  }
}
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 12000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "Eres un estratega de proyectos senior con 15+ años de experiencia combinando metodologías ágiles, PMI, y gestión del talento humano. Generas blueprints estructurados, profesionales y accionables."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content || "";
    let blueprint;
    try {
      // Con JSON mode, la respuesta ya es JSON válido
      blueprint = JSON.parse(content);

      // Validar estructura mínima
      if (!blueprint.resumenEjecutivo || !blueprint.objetivosSMART || !blueprint.backlogInicial) {
        logger.warn("Blueprint generado no tiene todos los campos requeridos");
        // Pero lo retornamos de todas formas, la app puede manejarlo
      }

      logger.info(`✅ Blueprint generado con ${blueprint.objetivosSMART?.length || 0} objetivos, ${blueprint.hitosPrincipales?.length || 0} hitos, ${blueprint.backlogInicial?.length || 0} items de backlog`);
    } catch (errorParse) {
      logger.error("❌ Error parseando blueprint general:", errorParse);
      logger.error("Contenido recibido:", content.substring(0, 500));
      return { error: "No se pudo interpretar la respuesta de IA para el blueprint", raw: content.substring(0, 1000) };
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
  memory: "512MiB",
  cors: true
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
Eres un Workflow Orchestrator experto que genera flujos de trabajo adaptativos y contextualizados.

PROYECTO: ${nombreProyecto}
Metodología base: ${methodology}
Objetivo principal: ${objective}

MACRO ENTREGABLES:
${macroTexto || "No declarados explícitamente"}

INVENTARIO DE HABILIDADES DEL EQUIPO:
${skillSummary || "No hay skills específicas declaradas (asume equipo multidisciplinario)"}

CONTEXTO ADICIONAL:
${contextoLibre}

INSTRUCCIONES:
1. Genera 3-7 fases de workflow que cubran el ciclo completo del proyecto
2. Cada fase debe tener un objetivo claro y medible
3. Asigna tipo correcto: "descubrimiento" (investigación, análisis), "ejecucion" (desarrollo, implementación), "seguimiento" (monitoreo, optimización)
4. Define dependencias realistas entre fases
5. Identifica riesgos humanos específicos (burnout, falta de comunicación, resistencia al cambio, etc.)
6. Crea 2-5 tareas por fase con habilidades técnicas Y blandas necesarias
7. Sugiere responsables basados en el inventario de skills o roles genéricos

IMPORTANTE:
- Las tareas deben ser específicas y accionables
- Los outputs deben ser entregables concretos
- Las habilidades técnicas deben ser reales (ej: "Python", "React", "SQL")
- Las habilidades blandas deben ser específicas (ej: "Facilitación de reuniones", "Negociación", "Pensamiento crítico")
- Los indicadores de éxito deben ser medibles

Devuelve un JSON válido con esta estructura EXACTA:
{
  "workflow": [
    {
      "nombre": "Nombre descriptivo de la fase",
      "objetivo": "Objetivo claro y medible de esta fase",
      "tipo": "descubrimiento",
      "duracionDias": 14,
      "dependencias": ["Fase anterior"],
      "indicadoresExito": ["Indicador medible 1", "Indicador medible 2"],
      "riesgosHumanos": ["Riesgo específico 1", "Riesgo específico 2"],
      "tareas": [
        {
          "titulo": "Título específico de la tarea",
          "descripcion": "Descripción detallada de qué hacer y cómo",
          "habilidadesTecnicas": ["Habilidad técnica 1", "Habilidad técnica 2"],
          "habilidadesBlandas": ["Habilidad blanda 1", "Habilidad blanda 2"],
          "responsableSugerido": "Rol o nombre del responsable",
          "outputs": ["Entregable concreto 1", "Entregable concreto 2"]
        }
      ]
    }
  ],
  "recomendaciones": {
    "ritualesIA": ["Ritual 1: descripción", "Ritual 2: descripción"],
    "seguimientoHumano": ["Práctica 1", "Práctica 2"],
    "metricasClave": ["Métrica 1", "Métrica 2"]
  }
}
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 10000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "Eres un orquestador de workflows senior especializado en metodologías ágiles, gestión del talento y optimización de procesos. Consideras siempre el factor humano: habilidades blandas, riesgos de equipo y dinámicas de colaboración."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content || "";
    let workflow;
    try {
      // Con JSON mode, la respuesta ya es JSON válido
      workflow = JSON.parse(content);

      // Validar estructura mínima
      if (!workflow.workflow || !Array.isArray(workflow.workflow)) {
        logger.warn("Workflow generado no tiene estructura de array");
      }

      logger.info(`✅ Workflow generado con ${workflow.workflow?.length || 0} fases`);
    } catch (errorParse) {
      logger.error("❌ Error parseando workflow contextual:", errorParse);
      logger.error("Contenido recibido:", content.substring(0, 500));
      return { error: "No se pudo interpretar el workflow generado", raw: content.substring(0, 1000) };
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
  memory: "512MiB",
  cors: true
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
exports.guardarSkillsConfirmadas = onCall({ secrets: [openaiKey], cors: true }, async (request) => {
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
  memory: "512MiB",
  cors: true
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

    // 2. Generar estructura PMI con OpenAI GPT-5 mini
    const prompt = `
Eres un experto certificado PMP (Project Management Professional) con profundo conocimiento del PMBOK 7ma edición y experiencia liderando proyectos complejos.

PROYECTO: "${nombreProyecto}"
Descripción: ${descripcionBreve || "No especificada"}

TAREA:
Analiza la documentación proporcionada y genera una estructura PMI completa y profesional con las 5 fases del ciclo de vida del proyecto:

1. Iniciación
2. Planificación
3. Ejecución
4. Monitoreo y Control
5. Cierre

JERARQUÍA PMI (CRÍTICO):
Debes seguir estrictamente esta jerarquía de 4 niveles:

Fase → Entregables → Paquetes de Trabajo → Tareas

EJEMPLO DE ESTRUCTURA CORRECTA:

Fase: "Iniciación"
├── Entregable: "Project Charter"
│   ├── Paquete de Trabajo: "Documentación de Objetivos"
│   │   ├── Tarea: "Definir objetivos SMART del proyecto"
│   │   ├── Tarea: "Documentar justificación del negocio"
│   │   └── Tarea: "Identificar criterios de éxito"
│   └── Paquete de Trabajo: "Aprobaciones y Autorizaciones"
│       ├── Tarea: "Preparar presentación para sponsor"
│       └── Tarea: "Obtener firma del Project Charter"
├── Entregable: "Registro de Stakeholders"
│   └── Paquete de Trabajo: "Análisis de Partes Interesadas"
│       ├── Tarea: "Identificar stakeholders clave"
│       ├── Tarea: "Mapear poder e interés"
│       └── Tarea: "Definir estrategia de comunicación"

REGLAS IMPORTANTES:

1. ÁREAS (areaRecomendada):
   - NO es para fases ni entregables
   - Indica el RECURSO que ejecuta la tarea (equipo, persona, departamento)
   - Ejemplos correctos: "Equipo de Desarrollo", "PMO", "Consultor Externo", "Equipo de Marketing", "Arquitecto de Software"

2. CANTIDAD DE ELEMENTOS:
   - 5 fases (siempre las 5 estándar de PMI)
   - 2-5 entregables por fase
   - 1-4 paquetes de trabajo por entregable
   - 2-6 tareas por paquete de trabajo
   - Total esperado: 40-80 tareas en todo el proyecto

3. HABILIDADES:
   - Deben ser específicas y técnicas
   - Ejemplos: "Gestión de Alcance PMI", "Python", "Análisis Financiero", "Gestión de Riesgos", "SQL", "AutoCAD"
   - Evita habilidades genéricas como "trabajo en equipo"

4. DURACIÓN:
   - Tareas: 1-15 días
   - Paquetes: suma de sus tareas
   - Entregables: suma de sus paquetes
   - Fases: suma de sus entregables

5. PRIORIDAD (1-5):
   - 5: Crítico (bloquea todo)
   - 4: Alto (impacto significativo)
   - 3: Medio (normal)
   - 2: Bajo (puede esperar)
   - 1: Muy bajo (nice to have)

DOCUMENTACIÓN DEL PROYECTO:
${textoCompleto.substring(0, 50000)}

Devuelve un JSON válido con esta estructura EXACTA:
{
  "objetivo": "Objetivo general del proyecto (1-2 párrafos)",
  "alcance": "Descripción del alcance: qué incluye y qué NO incluye (2-3 párrafos)",
  "presupuestoEstimado": 150000,
  "fases": [
    {
      "nombre": "Iniciación",
      "orden": 1,
      "descripcion": "Descripción de qué se logra en esta fase",
      "duracionDias": 21,
      "entregables": [
        {
          "nombre": "Project Charter",
          "descripcion": "Descripción del entregable",
          "paquetesTrabajo": [
            {
              "nombre": "Documentación de Objetivos",
              "descripcion": "Descripción del paquete de trabajo",
              "tareas": [
                {
                  "titulo": "Definir objetivos SMART del proyecto",
                  "descripcion": "Descripción detallada de la tarea y cómo realizarla",
                  "duracionDias": 3,
                  "prioridad": 5,
                  "habilidadesRequeridas": ["Gestión de Proyectos PMI", "Análisis de Negocio"],
                  "areaRecomendada": "PMO"
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
      "descripcion": "Descripción específica del riesgo",
      "probabilidad": "alta",
      "impacto": "alto",
      "mitigacion": "Plan de mitigación concreto"
    }
  ],
  "stakeholders": [
    {
      "nombre": "Nombre o rol del stakeholder",
      "rol": "Sponsor/Cliente/Usuario/Equipo",
      "interes": "alto",
      "poder": "alto"
    }
  ]
}
`;

    logger.info("🤖 Llamando a OpenAI GPT-5-mini...");

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 20000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "Eres un Project Manager certificado PMP con 20+ años de experiencia implementando proyectos siguiendo las mejores prácticas del PMBOK. Generas estructuras PMI completas, detalladas y profesionales que cumplen estrictamente los estándares del PMI."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content;
    logger.info(`✅ OpenAI respondió: ${content.length} caracteres`);

    // 3. Parsear respuesta JSON (con JSON mode ya viene válido)
    let proyectoPMI;
    try {
      proyectoPMI = JSON.parse(content);
    } catch (parseError) {
      logger.error("❌ Error parseando JSON de OpenAI", parseError);
      logger.error("Contenido recibido:", content.substring(0, 500));
      return {
        error: "La IA respondió algo que no es JSON válido",
        raw: content.substring(0, 2000)
      };
    }

    // 4. Validar estructura básica
    if (!proyectoPMI.fases || !Array.isArray(proyectoPMI.fases) || proyectoPMI.fases.length === 0) {
      logger.error("❌ Estructura sin fases válidas");
      return {
        error: "La estructura generada no contiene fases válidas",
        proyecto: proyectoPMI
      };
    }

    // Validar que las fases tengan la jerarquía correcta
    let totalTareas = 0;
    let totalPaquetes = 0;
    let totalEntregables = 0;

    for (const fase of proyectoPMI.fases) {
      if (fase.entregables && Array.isArray(fase.entregables)) {
        totalEntregables += fase.entregables.length;
        for (const entregable of fase.entregables) {
          if (entregable.paquetesTrabajo && Array.isArray(entregable.paquetesTrabajo)) {
            totalPaquetes += entregable.paquetesTrabajo.length;
            for (const paquete of entregable.paquetesTrabajo) {
              if (paquete.tareas && Array.isArray(paquete.tareas)) {
                totalTareas += paquete.tareas.length;
              }
            }
          }
        }
      }
    }

    logger.info(`✅ Proyecto PMI generado exitosamente:`);
    logger.info(`   📊 ${proyectoPMI.fases.length} fases`);
    logger.info(`   📦 ${totalEntregables} entregables`);
    logger.info(`   📋 ${totalPaquetes} paquetes de trabajo`);
    logger.info(`   ✓ ${totalTareas} tareas`);

    if (totalTareas === 0) {
      logger.warn("⚠️ No se generaron tareas. Revisar estructura.");
    }

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

// ========================================
// 🎨 GENERAR PROYECTO PERSONAL CON IA
// ========================================

exports.generarProyectoPersonal = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 480,
  memory: "512MiB",
  cors: true
}, async (request) => {
  try {
    const {
      nombreProyecto,
      descripcionLibre = "",
      objetivosPrincipales = "",
      restricciones = "",
      preferencias = "",
      documentosBase64 = []
    } = request.data || {};

    if (!nombreProyecto || nombreProyecto.trim().length === 0) {
      return { error: "El nombre del proyecto es obligatorio" };
    }

    logger.info(`🎨 Generando proyecto personal: ${nombreProyecto}`);

    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // Extraer texto de documentos si existen
    let textoDocumentos = "";
    if (documentosBase64 && documentosBase64.length > 0) {
      for (let i = 0; i < documentosBase64.length; i++) {
        try {
          const buffer = Buffer.from(documentosBase64[i], "base64");
          const pdfData = await pdfParse(buffer);
          textoDocumentos += `\n\n=== DOCUMENTO ${i + 1} ===\n${pdfData.text}`;
          logger.info(`✅ Documento ${i + 1} parseado: ${pdfData.text.length} caracteres`);
        } catch (pdfError) {
          logger.warn(`⚠️ Error parseando documento ${i + 1}:`, pdfError);
        }
      }
      textoDocumentos = textoDocumentos.substring(0, 40000);
    }

    const prompt = `
Eres un asistente de planificación de proyectos personales altamente adaptable y creativo.

Tu objetivo es crear un plan de proyecto TOTALMENTE PERSONALIZADO que se adapte a las necesidades únicas del usuario, sin seguir frameworks rígidos.

INFORMACIÓN DEL PROYECTO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 Nombre: ${nombreProyecto}

📝 Descripción general:
${descripcionLibre || "No especificada"}

🎯 Objetivos principales:
${objetivosPrincipales || "No especificados"}

⚠️ Restricciones/Limitaciones:
${restricciones || "Ninguna especificada"}

💡 Preferencias del usuario:
${preferencias || "Ninguna especificada"}

${textoDocumentos ? `\n📄 DOCUMENTACIÓN ADICIONAL:\n${textoDocumentos}` : ""}

INSTRUCCIONES:
1. Analiza el contexto único del usuario
2. Diseña una estructura flexible adaptada a sus necesidades
3. Propón fases personalizadas (2-8 fases según lo que tenga sentido)
4. Crea tareas realistas (2-10 por fase)
5. Sugiere herramientas y recursos útiles
6. Identifica riesgos específicos
7. Propón hábitos que ayuden al éxito

IMPORTANTE:
- Libertad total: No sigas metodologías rígidas
- Sé creativo con los nombres de fases
- Adapta TODO al contexto del usuario
- Prioriza practicidad sobre teoría

Devuelve un JSON válido con esta estructura:
{
  "resumenEjecutivo": "Resumen en 2-3 párrafos",
  "vision": "Visión a largo plazo",
  "objetivos": ["Objetivo 1", "Objetivo 2"],
  "fases": [
    {
      "nombre": "Nombre descriptivo",
      "proposito": "¿Qué se logra?",
      "duracionEstimada": "2 semanas",
      "tareas": [
        {
          "nombre": "Tarea específica",
          "descripcion": "Cómo hacerla",
          "prioridad": "alta",
          "tiempoEstimado": "3 días",
          "recursosNecesarios": ["Recurso 1"],
          "consejosPracticos": "Tips útiles"
        }
      ]
    }
  ],
  "herramientasRecomendadas": [
    {
      "categoria": "Gestión",
      "herramientas": ["Trello"],
      "razon": "Por qué son útiles"
    }
  ],
  "riesgos": [
    {
      "descripcion": "Riesgo específico",
      "probabilidad": "media",
      "impacto": "alto",
      "planMitigacion": "Qué hacer"
    }
  ],
  "habitosYRituales": ["Hábito 1", "Hábito 2"],
  "metricasExito": ["Métrica 1"],
  "proximosPasos": ["Paso 1", "Paso 2"],
  "consejosPersonalizados": "Consejos específicos"
}
`;

    logger.info("🤖 Llamando a GPT-5-mini para proyecto personal...");

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 16000,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "Eres un coach de productividad y planificación de proyectos personales. Creas planes ultra-personalizados adaptados a necesidades únicas. No sigues frameworks rígidos, diseñas soluciones flexibles y prácticas."
        },
        { role: "user", content: prompt }
      ]
    });

    const content = completion.choices[0].message.content;
    logger.info(`✅ OpenAI respondió: ${content.length} caracteres`);

    let proyectoPersonal;
    try {
      proyectoPersonal = JSON.parse(content);

      const totalTareas = proyectoPersonal.fases?.reduce((sum, fase) =>
        sum + (fase.tareas?.length || 0), 0
      ) || 0;

      logger.info(`✅ Proyecto personal generado:`);
      logger.info(`   📊 ${proyectoPersonal.fases?.length || 0} fases`);
      logger.info(`   ✓ ${totalTareas} tareas`);
      logger.info(`   🎯 ${proyectoPersonal.objetivos?.length || 0} objetivos`);

    } catch (parseError) {
      logger.error("❌ Error parseando JSON:", parseError);
      return {
        error: "No se pudo interpretar la respuesta",
        raw: content.substring(0, 2000)
      };
    }

    return {
      success: true,
      proyecto: proyectoPersonal
    };

  } catch (error) {
    logger.error("❌ Error generando proyecto personal:", error);
    return {
      error: "Error generando proyecto personal",
      message: error.message
    };
  }
});

// ========================================
// 💬 CHAT WITH AI: Para VASTORIA y otros módulos
// ========================================
exports.chatWithAI = onCall({
  secrets: [openaiKey],
  timeoutSeconds: 60,
  cors: true
}, async (request) => {
  try {
    const messages = request.data?.messages || [];
    const userId = request.data?.userId;
    const conversationId = request.data?.conversationId;

    if (!Array.isArray(messages) || messages.length === 0) {
      return {
        error: "invalid_input",
        message: "Se requiere un array de mensajes válido"
      };
    }

    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // Llamar a OpenAI con el historial de mensajes
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: messages,
      temperature: 0.7,
      max_tokens: 1500,
    });

    const reply = completion.choices[0].message.content;

    // Token usage
    const usage = {
      promptTokens: completion.usage.prompt_tokens,
      completionTokens: completion.usage.completion_tokens,
      totalTokens: completion.usage.total_tokens,
    };

    // Guardar conversación si hay userId y conversationId
    if (userId && conversationId) {
      const db = admin.firestore();
      await db.collection('users')
        .doc(userId)
        .collection('vastoria_conversations')
        .doc(conversationId)
        .set({
          lastMessage: reply,
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          tokenUsage: usage,
        }, { merge: true });
    }

    return {
      message: reply,
      usage: usage,
    };

  } catch (e) {
    logger.error("chatWithAI error", e);
    return {
      error: "openai_failed",
      message: "Lo siento, tuve un problema técnico. Intenta de nuevo.",
    };
  }
});
