# 🚀 Plan de Implementación: Sistema PMI con IA

## 📊 Resumen del Sistema

Sistema de gestión de proyectos basado en metodología PMI con:
- ✅ Creación automática de tareas desde documentos (OpenAI)
- ✅ Asignación inteligente basada en skills profesionales
- ✅ Workflow visual con nodos (fases PMI)
- ✅ Sistema de aprobaciones multi-nivel
- ✅ Portfolio dinámico que aumenta skills

---

## 🎯 FASE 1: Estructura de Datos para Proyectos PMI

### Modelo de Datos en Firestore

```
proyectos_pmi/
├── {projectId}/
│   ├── metadata/
│   │   ├── nombre: string
│   │   ├── descripcion: string
│   │   ├── createdAt: timestamp
│   │   ├── createdBy: userId
│   │   ├── estado: "draft" | "active" | "completed"
│   │   ├── metodologia: "PMI"
│   │   └── generadoConIA: boolean
│   │
│   ├── documentos_iniciales/  (subcollection)
│   │   ├── {docId}/
│   │   │   ├── nombre: string
│   │   │   ├── url: string (Firebase Storage)
│   │   │   ├── tipo: "pdf" | "docx" | "xlsx"
│   │   │   ├── extractedText: string (para análisis IA)
│   │   │   └── uploadedAt: timestamp
│   │
│   ├── fases_pmi/  (subcollection - Niveles PMI)
│   │   ├── {faseId}/
│   │   │   ├── nombre: "Iniciación" | "Planificación" | "Ejecución" | "Monitoreo" | "Cierre"
│   │   │   ├── orden: number (1-5)
│   │   │   ├── estado: "pending" | "in_progress" | "completed"
│   │   │   ├── nodos/  (subcollection)
│   │   │   │   ├── {nodoId}/
│   │   │   │   │   ├── nombre: string (ej: "Business Case", "Charter")
│   │   │   │   │   ├── tipo: "entregable" | "paquete_trabajo"
│   │   │   │   │   ├── estado: "pending" | "in_review" | "approved" | "rejected" | "returned" | "blocked"
│   │   │   │   │   ├── reglaAprobacion: "AND" | "OR"
│   │   │   │   │   ├── aprobadores/
│   │   │   │   │   │   ├── {userId}/
│   │   │   │   │   │   │   ├── rol: string (ej: "CEO", "PM")
│   │   │   │   │   │   │   ├── estado: "pending" | "approved" | "rejected"
│   │   │   │   │   │   │   ├── fecha: timestamp?
│   │   │   │   │   │   │   └── comentario: string?
│   │   │   │   │   ├── dependencias: [nodoId]  (IDs de nodos que deben estar aprobados)
│   │   │   │   │   ├── tareas/  (subcollection)
│   │   │   │   │   │   ├── {tareaId}/
│   │   │   │   │   │   │   ├── titulo: string
│   │   │   │   │   │   │   ├── descripcion: string
│   │   │   │   │   │   │   ├── estado: "pending" | "in_progress" | "completed"
│   │   │   │   │   │   │   ├── asignadoA: userId? (null si es libre)
│   │   │   │   │   │   │   ├── skillsRequeridas: [string]  (IDs de skills)
│   │   │   │   │   │   │   ├── duracion: number (minutos)
│   │   │   │   │   │   │   ├── prioridad: "baja" | "media" | "alta"
│   │   │   │   │   │   │   └── skillsGanadas: [{ skillId, xpGanado }]
│   │   │   │   │   ├── documentos/  (subcollection)
│   │   │   │   │   │   ├── {docId}/
│   │   │   │   │   │   │   ├── nombre: string
│   │   │   │   │   │   │   ├── url: string
│   │   │   │   │   │   │   ├── requerido: boolean
│   │   │   │   │   │   │   └── uploadedBy: userId?
│   │   │   │   │   └── badges/
│   │   │   │   │       ├── tareasCompletadas: number
│   │   │   │   │       ├── tareasTotales: number
│   │   │   │   │       ├── docsSubidos: number
│   │   │   │   │       ├── docsTotales: number
│   │   │   │   │       ├── participantes: number
│   │   │   │   │       └── comentarios: number
│   │
│   ├── integrantes/  (subcollection)
│   │   ├── {userId}/
│   │   │   ├── rol: "owner" | "member" | "viewer"
│   │   │   ├── joinedAt: timestamp
│   │   │   ├── skillsProfesionales: [skillId]  (referencia a skills/)
│   │   │   ├── tareasAsignadas: number
│   │   │   └── tareasCompletadas: number
│   │
│   └── timeline/  (subcollection)
│       ├── {eventId}/
│       │   ├── timestamp: timestamp
│       │   ├── tipo: "nodo_creado" | "nodo_aprobado" | "nodo_rechazado" | "tarea_completada"
│       │   ├── userId: userId
│       │   ├── nodoId: nodoId?
│       │   ├── descripcion: string
│       │   └── metadata: object
```

### Modelos Dart a crear

1. **PMIProject** - Proyecto principal
2. **PMIFase** - Fase (Iniciación, Planificación, etc.)
3. **PMINodo** - Nodo (Business Case, Charter, etc.)
4. **PMITarea** - Tarea dentro de un nodo
5. **PMIAprobador** - Aprobador de un nodo
6. **PMIDocumento** - Documento adjunto
7. **PMIIntegrante** - Miembro del proyecto
8. **PMITimelineEvent** - Evento en el timeline

---

## 🎯 FASE 2: Creación de Proyecto con IA

### Flujo de Usuario

```
1. Usuario: "Crear Proyecto"
   ├─ Opción A: Manual (en blanco)
   └─ Opción B: Con IA ✨

2. Usuario selecciona: "Con IA"
   ├─ Paso 1: Subir documentos (PDF, DOCX, XLSX)
   │   ├─ Business requirements
   │   ├─ Project charter draft
   │   ├─ Stakeholder list
   │   └─ Presupuesto

3. Sistema: Analiza documentos con OpenAI
   ├─ Extrae texto de PDFs
   ├─ Identifica:
   │   ├─ Objetivo del proyecto
   │   ├─ Entregables principales
   │   ├─ Stakeholders
   │   ├─ Restricciones de tiempo/presupuesto
   │   └─ Skills técnicas requeridas

4. IA genera estructura PMI:
   ├─ Fase 1: Iniciación
   │   ├─ Business Case
   │   │   ├─ Tarea 1: Validar objetivos
   │   │   ├─ Tarea 2: Aprobar presupuesto
   │   │   └─ Doc requerido: Business Case v1.0
   │   └─ Charter
   │       ├─ Tarea 1: Definir alcance
   │       ├─ Tarea 2: Identificar riesgos
   │       └─ Doc requerido: Project Charter
   ├─ Fase 2: Planificación
   │   ├─ WBS (Work Breakdown Structure)
   │   ├─ Cronograma
   │   └─ Plan de Recursos
   └─ ...

5. Usuario revisa estructura generada
   ├─ Puede editar/eliminar nodos
   ├─ Puede agregar/quitar tareas
   └─ Confirma creación

6. Sistema crea proyecto en Firestore
```

### Cloud Function: `generarProyectoPMI`

```javascript
exports.generarProyectoPMI = onCall(async (request) => {
  const { documentosBase64, nombreProyecto, userId } = request.data;

  // 1. Extraer texto de documentos
  const textosExtraidos = [];
  for (const doc of documentosBase64) {
    const texto = await extraerTextoDeDocumento(doc);
    textosExtraidos.push(texto);
  }

  // 2. Construir prompt para OpenAI
  const prompt = `
    Eres un experto en metodología PMI. Analiza los siguientes documentos de proyecto
    y genera una estructura completa siguiendo el PMBOK:

    Documentos:
    ${textosExtraidos.join('\n\n')}

    Genera un JSON con esta estructura:
    {
      "fases": [
        {
          "nombre": "Iniciación",
          "nodos": [
            {
              "nombre": "Business Case",
              "tipo": "entregable",
              "tareas": [
                {
                  "titulo": "Validar objetivos",
                  "descripcion": "...",
                  "skillsRequeridas": ["Análisis de Negocios", "Excel"],
                  "duracion": 120
                }
              ],
              "documentosRequeridos": ["Business Case v1.0"],
              "aprobadores": [{ "rol": "CEO" }, { "rol": "CFO" }],
              "reglaAprobacion": "AND"
            }
          ]
        }
      ]
    }
  `;

  // 3. Llamar a OpenAI
  const respuesta = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [{ role: "user", content: prompt }],
    temperature: 0.3,
    max_tokens: 8000
  });

  // 4. Parsear respuesta
  const estructura = JSON.parse(respuesta.choices[0].message.content);

  // 5. Crear proyecto en Firestore
  const projectRef = await db.collection('proyectos_pmi').add({
    nombre: nombreProyecto,
    createdBy: userId,
    createdAt: FieldValue.serverTimestamp(),
    estado: 'draft',
    generadoConIA: true
  });

  // 6. Crear fases y nodos
  for (const fase of estructura.fases) {
    const faseRef = await projectRef.collection('fases_pmi').add({
      nombre: fase.nombre,
      orden: estructura.fases.indexOf(fase) + 1,
      estado: 'pending'
    });

    for (const nodo of fase.nodos) {
      await faseRef.collection('nodos').add(nodo);
    }
  }

  return { projectId: projectRef.id, estructura };
});
```

---

## 🎯 FASE 3: Asignación Inteligente de Tareas

### Flujo de Asignación

```
OPCIÓN A: Asignación durante creación del proyecto
──────────────────────────────────────────────────

1. Usuario crea proyecto con IA
2. Sistema genera tareas con skillsRequeridas
3. Usuario ve lista de integrantes del proyecto
   ├─ Si hay integrantes:
   │   └─ Botón: "Asignar automáticamente" ✨
   └─ Si no hay integrantes:
       └─ Mensaje: "Agrega integrantes para asignación automática"

4. Usuario presiona "Asignar automáticamente"
5. Sistema:
   ├─ Para cada tarea:
   │   ├─ Obtiene skillsRequeridas
   │   ├─ Busca integrante con mejor match
   │   ├─ Calcula score: (skills_coincidentes / skills_requeridas) * nivel_promedio
   │   └─ Asigna al integrante con mayor score
   └─ Muestra resumen:
       ├─ Tareas asignadas: 45
       ├─ Tareas sin asignar: 3 (falta skill "Blockchain")
       └─ Distribución por integrante


OPCIÓN B: Asignación posterior
───────────────────────────────

1. Proyecto ya creado, tareas están libres
2. Usuario agrega integrantes al proyecto
3. Va a sección "Tareas Libres"
4. Botón flotante: "Asignar con IA" 🤖
5. Sistema ejecuta mismo algoritmo
```

### Algoritmo de Matching

```typescript
interface TareaLibre {
  id: string;
  titulo: string;
  skillsRequeridas: string[];  // IDs de skills
  duracion: number;
}

interface Integrante {
  userId: string;
  skillsProfesionales: Array<{
    skillId: string;
    skillName: string;
    level: number;  // 1-10
  }>;
  tareasAsignadas: number;
}

function asignarTareasInteligentemente(
  tareas: TareaLibre[],
  integrantes: Integrante[]
): Map<string, string> {  // Map<tareaId, userId>

  const asignaciones = new Map();

  for (const tarea of tareas) {
    let mejorIntegrante: Integrante | null = null;
    let mejorScore = 0;

    for (const integrante of integrantes) {
      // 1. Calcular skills que coinciden
      const skillsCoincidentes = tarea.skillsRequeridas.filter(skillReq =>
        integrante.skillsProfesionales.some(sp => sp.skillId === skillReq)
      );

      // 2. Calcular nivel promedio de esas skills
      const nivelesCoincidentes = skillsCoincidentes.map(skillId => {
        const skill = integrante.skillsProfesionales.find(sp => sp.skillId === skillId);
        return skill?.level || 0;
      });
      const nivelPromedio = nivelesCoincidentes.length > 0
        ? nivelesCoincidentes.reduce((a, b) => a + b, 0) / nivelesCoincidentes.length
        : 0;

      // 3. Calcular score
      const cobertura = skillsCoincidentes.length / tarea.skillsRequeridas.length;
      const penalizacionCarga = 1 - (integrante.tareasAsignadas * 0.1);  // Penaliza sobrecarga
      const score = cobertura * nivelPromedio * penalizacionCarga;

      // 4. Actualizar mejor match
      if (score > mejorScore) {
        mejorScore = score;
        mejorIntegrante = integrante;
      }
    }

    // 5. Asignar si hay match > 50%
    if (mejorIntegrante && mejorScore >= 0.5) {
      asignaciones.set(tarea.id, mejorIntegrante.userId);
      mejorIntegrante.tareasAsignadas++;  // Incrementar carga
    }
  }

  return asignaciones;
}
```

### Cloud Function: `asignarTareasConIA`

```javascript
exports.asignarTareasConIA = onCall(async (request) => {
  const { projectId } = request.data;

  // 1. Obtener tareas libres del proyecto
  const tareasLibres = await obtenerTareasLibres(projectId);

  // 2. Obtener integrantes con sus skills
  const integrantes = await obtenerIntegrantesConSkills(projectId);

  // 3. Ejecutar algoritmo de matching
  const asignaciones = asignarTareasInteligentemente(tareasLibres, integrantes);

  // 4. Guardar asignaciones en Firestore
  const batch = db.batch();
  for (const [tareaId, userId] of asignaciones) {
    const tareaRef = db.doc(`proyectos_pmi/${projectId}/tareas/${tareaId}`);
    batch.update(tareaRef, { asignadoA: userId });
  }
  await batch.commit();

  // 5. Registrar en timeline
  await db.collection(`proyectos_pmi/${projectId}/timeline`).add({
    tipo: 'asignacion_automatica',
    timestamp: FieldValue.serverTimestamp(),
    tareasAsignadas: asignaciones.size,
    tareasSinAsignar: tareasLibres.length - asignaciones.size
  });

  return {
    success: true,
    tareasAsignadas: asignaciones.size,
    tareasSinAsignar: tareasLibres.length - asignaciones.size
  };
});
```

---

## 🎯 FASE 4: Portfolio Dinámico - Ganar Skills

### Sistema de XP y Niveles

```
Completar Tarea → Gana XP en skills usadas → Sube de nivel

Ejemplo:
───────
Tarea: "Implementar API REST"
Skills requeridas:
  - Node.js
  - Express
  - MongoDB

Usuario completa tarea (60 min de duración)
  ├─ Gana 60 XP en Node.js
  ├─ Gana 60 XP en Express
  └─ Gana 60 XP en MongoDB

XP acumulado:
  - Node.js: 180 XP → Nivel 3 → Nivel 4 ✨
  - Express: 120 XP → Nivel 2
  - MongoDB: 60 XP → Nivel 1

Firestore update:
  users/{uid}/professional_skills/NodeJS
    level: 3 → 4
    xp: 180 → 240
    updatedAt: now()
```

### Tabla de XP por Nivel

```
Nivel 1 →  0 XP
Nivel 2 →  100 XP
Nivel 3 →  250 XP
Nivel 4 →  450 XP
Nivel 5 →  700 XP
Nivel 6 → 1000 XP
Nivel 7 → 1350 XP
Nivel 8 → 1750 XP
Nivel 9 → 2200 XP
Nivel 10 → 2700 XP
```

---

## 📝 Próximos Pasos

### ¿Por dónde empezamos?

Sugiero empezar por:

1. **FASE 1A: Modelos Dart básicos**
   - Crear `PMIProject`, `PMIFase`, `PMINodo`, `PMITarea`
   - Sin IA aún, solo estructura de datos

2. **FASE 1B: Crear proyecto manual**
   - UI para crear proyecto en blanco
   - Agregar fases manualmente
   - Agregar nodos manualmente

3. **FASE 2: Agregar IA**
   - Cloud Function para generar estructura desde docs
   - Integrar con OpenAI

4. **FASE 3: Asignación inteligente**
   - Algoritmo de matching
   - Botón "Asignar con IA"

5. **FASE 4: Workflow visual**
   - Canvas con nodos
   - Drag & drop
   - Panel lateral

¿Con cuál fase quieres que empiece? 🚀
