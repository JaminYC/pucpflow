# 📊 ANÁLISIS COMPLETO: PROYECTO PERSONAL

**Fecha:** 2025-12-30
**Estado:** Análisis pre-corrección

---

## 🔍 1. INPUTS (Lo que recibe)

### Frontend (crear_proyecto_personal_page.dart)

**Formulario de usuario:**
```dart
- nombreProyecto: String (obligatorio)
- descripcionLibre: String (opcional)
- objetivosPrincipales: String (opcional)
- restricciones: String (opcional)
- preferencias: String (opcional)
- categoria: String (dropdown: "Laboral", "Personal", etc.)
- documentosBase64: List<String> (PDFs opcionales)
```

### Backend (functions/index.js - generarProyectoPersonal)

**Recibe del frontend:**
```javascript
{
  nombreProyecto: "string",
  descripcionLibre: "string",
  objetivosPrincipales: "string",
  restricciones: "string",
  preferencias: "string",
  documentosBase64: ["base64_string_1", "base64_string_2"]
}
```

**Procesa:**
- Extrae texto de PDFs (hasta 40,000 caracteres)
- Construye prompt personalizado para OpenAI
- Llama a gpt-4o-mini con max_completion_tokens: 16000

---

## 📤 2. OUTPUTS (Lo que genera)

### Respuesta de Cloud Function:

```javascript
{
  success: true,
  proyecto: {
    resumenEjecutivo: "string",
    vision: "string",
    objetivos: ["string", "string"],
    fases: [
      {
        nombre: "string",
        proposito: "string",
        duracionEstimada: "string",
        tareas: [
          {
            nombre: "string",
            descripcion: "string",
            prioridad: "alta|media|baja",
            tiempoEstimado: "string",
            recursosNecesarios: ["string"],
            consejosPracticos: "string"
          }
        ]
      }
    ],
    herramientasRecomendadas: [...],
    riesgos: [...],
    habitosYRituales: [...],
    metricasExito: [...],
    proximosPasos: [...],
    consejosPersonalizados: "string"
  }
}
```

### Conversión a Firestore (crear_proyecto_personal_page.dart líneas 154-211):

**Por cada fase:**
- Itera `fases` array
- Extrae `tareas` de cada fase
- Crea objetos `Tarea` con:
  ```dart
  titulo: tareaData['nombre']
  descripcion: tareaData['descripcion']
  fecha: DateTime.now() // ⚠️ TODAS LAS TAREAS TIENEN LA MISMA FECHA
  duracion: _parseDuracion(tareaData['tiempoEstimado'])
  prioridad: _parsePrioridad(tareaData['prioridad'])
  completado: false
  colorId: _getColorForPhase(nombreFase)
  responsables: [] // ⚠️ SIEMPRE VACÍO
  tipoTarea: nombreFase // ⚠️ USA NOMBRE DE FASE
  requisitos: {}
  dificultad: prioridad == 'alta' ? 'alta' : 'media'
  tareasPrevias: []
  area: 'Personal' // ✅ CORRECTO: Una sola área
  habilidadesRequeridas: tareaData['recursosNecesarios']
  fasePMI: nombreFase // Fase para agrupar
  entregable: null
  paqueteTrabajo: null
  ```

**Proyecto final en Firestore:**
```dart
Proyecto(
  id: auto-generado,
  nombre: nombreController.text,
  descripcion: proyectoGenerado['resumenEjecutivo'],
  vision: proyectoGenerado['vision'],
  fechaInicio: DateTime.now(),
  fechaFin: null,
  propietario: user.uid,
  participantes: [user.uid],
  categoria: "Laboral|Personal|etc",
  tareas: [Tarea, Tarea, ...],
  areas: {'Personal': []}, // ✅ UNA SOLA ÁREA
  blueprintIA: proyectoGenerado,
  objetivo: proyectoGenerado['vision'],
  alcance: proyectoGenerado['objetivos'].join(' | ')
)
```

---

## 🐛 3. PROBLEMAS POTENCIALES AL HACER CLICK EN TAREAS

### A. PROBLEMA CON DROPDOWN DE ÁREAS ✅ RESUELTO

**Estado actual (línea 182, 207):**
```dart
area: 'Personal' // ✅ SIEMPRE "Personal"
areas: {'Personal': []} // ✅ UNA SOLA ÁREA
```

**✅ CORRECTO:** Ya no debería haber errores de dropdown porque:
- Todas las tareas tienen `area: 'Personal'`
- El proyecto tiene `areas: {'Personal': []}`
- No hay duplicados ni valores inconsistentes

---

### B. PROBLEMA CON FECHA LÍMITE ⚠️ PENDIENTE

**Código actual (línea 172):**
```dart
fecha: DateTime.now(), // ⚠️ TODAS LAS TAREAS TIENEN LA MISMA FECHA
```

**Problema:**
- Todas las tareas se crean con la fecha de HOY
- No se calcula una fecha límite basada en la duración
- No hay progresión temporal entre tareas

**Debería ser:**
```dart
// Calcular fecha límite basada en duración estimada
fecha: DateTime.now().add(Duration(minutes: duracion))
// O acumular duraciones de tareas previas
```

---

### C. PROBLEMA CON RESPONSABLES ⚠️ PENDIENTE

**Código actual (línea 177):**
```dart
responsables: [], // ⚠️ SIEMPRE VACÍO
```

**Problema:**
- Proyectos personales SIEMPRE tienen responsables vacíos
- Debería auto-asignarse al creador del proyecto

**Debería ser:**
```dart
responsables: [user.uid], // Auto-asignar al creador
```

---

### D. PROBLEMA CON TIPO DE TAREA ⚠️ INCONSISTENTE

**Código actual (línea 178):**
```dart
tipoTarea: nombreFase, // Usa el nombre de la fase
```

**Problema:**
- `tipoTarea` debería ser: "Libre", "Asignada", o "Automática"
- Actualmente usa nombres de fases como: "Investigación", "Desarrollo", etc.
- Esto puede causar problemas en la UI si espera valores específicos

**Según ESTRUCTURA_PROYECTOS.md:**
- Proyectos Personales deberían usar nombre de fase en `tipoTarea`
- PERO el formulario espera "Libre", "Asignada", "Automática"

**Opciones:**
1. Cambiar a `tipoTarea: 'Libre'` para proyectos personales
2. O mantener nombre de fase pero actualizar UI para aceptar cualquier valor

---

## 🎯 4. CAMPOS FALTANTES EN TAREA

Según el nuevo `TareaFormWidget.dart` actualizado:

### ✅ Campos que SÍ se están guardando:
- titulo ✅
- descripcion ✅
- duracion ✅
- dificultad ✅
- tipoTarea ✅ (pero con valor inconsistente)
- requisitos ✅
- responsables ✅ (pero vacío)
- completado ✅
- prioridad ✅
- colorId ✅
- area ✅

### ⚠️ Campos NUEVOS del formulario que NO se están guardando:
- **fecha** ⚠️ (se guarda pero es `DateTime.now()`, no calcula deadline)

**NUEVO en TareaFormWidget:**
- `fechaLimite` (deadline) - Se debe usar el campo `fecha` existente

---

## 📋 5. FLUJO COMPLETO

```
Usuario
  ↓
[Formulario de Proyecto Personal]
  - Nombre ✅
  - Descripción ✅
  - Objetivos ✅
  - Restricciones ✅
  - Preferencias ✅
  - PDFs (opcional) ✅
  ↓
[Botón "Generar con IA"]
  ↓
Cloud Function: generarProyectoPersonal
  - Procesa PDFs ✅
  - Construye prompt ✅
  - Llama a GPT-4o-mini ✅
  - Genera estructura flexible ✅
  ↓
[Respuesta con fases y tareas]
  ↓
[Botón "Crear Proyecto"]
  ↓
Conversión a Firestore
  - Itera fases ✅
  - Convierte tareas ⚠️ (problemas detectados)
  - Guarda en Firestore ✅
  ↓
[Navega a ProyectoDetalleKanbanPage]
  ↓
[Usuario hace click en tarea]
  ↓
[Abre TareaFormWidget]
  - Dropdown de Áreas ✅ (funciona con 'Personal')
  - Selector de Responsables ⚠️ (vacío)
  - Selector de Fecha Límite ⚠️ (todos misma fecha)
  - Tipo de Tarea ⚠️ (valor inconsistente)
```

---

## 🔧 6. CORRECCIONES NECESARIAS

### CRÍTICO 🔴
1. **Calcular fecha límite real** en lugar de `DateTime.now()`
2. **Auto-asignar responsable** al creador del proyecto

### IMPORTANTE 🟡
3. **Estandarizar `tipoTarea`** - Decidir si usar "Libre" o nombre de fase
4. **Validar que no haya duplicados en áreas** (ya debería estar OK)

### OPCIONAL 🟢
5. Mejorar prompt de IA para proyectos personales (similar a PMI)
6. Agregar validaciones en el formulario

---

## 🧪 7. ESCENARIO DE PRUEBA

**Para verificar que TODO funciona:**

1. Crear proyecto personal con:
   - Nombre: "Aprender Flutter Avanzado"
   - Descripción: "Proyecto para dominar estado, arquitectura y testing"
   - Objetivos: "Completar 3 apps complejas en 2 meses"
   - Sin PDFs

2. Generar con IA → Debería crear 3-6 fases con 10-30 tareas

3. Crear proyecto → Guardar en Firestore

4. Abrir proyecto → Ver tablero Kanban

5. **PRUEBA CRÍTICA:** Hacer click en una tarea
   - ✅ Dropdown de áreas debe mostrar solo "Personal"
   - ⚠️ Verificar que fecha límite tenga sentido
   - ⚠️ Verificar que responsables esté asignado al usuario

---

## 📊 8. COMPARACIÓN: PERSONAL vs PMI vs CONTEXTUAL

| Aspecto | Personal | PMI | Contextual |
|---------|----------|-----|------------|
| **Inputs** | Texto libre + PDFs opcionales | PDFs obligatorios | Descripción + contexto |
| **Áreas** | `{'Personal': []}` | Dinámicas normalizadas | `{'Blueprint IA': [], 'Hitos': []}` |
| **tipoTarea** | Nombre de fase ⚠️ | `'Automática'` | `'Desarrollo'/'Hito'` |
| **Responsables** | Vacío ⚠️ | Vacío (para asignar) | Vacío (para asignar) |
| **Fecha límite** | `DateTime.now()` ⚠️ | Calculada por IA | Calculada por IA |
| **Estructura** | Flexible (2-8 fases) | Fija (5 fases PMI) | Fija (Blueprint + Hitos) |
| **Prompts IA** | Genérico ⚠️ | Mejorado ✅ | Genérico ⚠️ |

---

## ✅ 9. ESTADO ACTUAL vs DESEADO

### ✅ LO QUE FUNCIONA:
- Generación de proyecto ✅
- Conversión de fases a tareas ✅
- Guardado en Firestore ✅
- Área única 'Personal' ✅ (evita dropdown error)

### ⚠️ LO QUE NECESITA CORRECCIÓN:
- Fecha límite no calculada ⚠️
- Responsables no asignados ⚠️
- tipoTarea inconsistente ⚠️
- Prompts IA genéricos ⚠️

---

## 🎯 10. SIGUIENTE PASO RECOMENDADO

**ANTES DE CODIFICAR:**
1. ✅ Confirmar que áreas funciona correctamente
2. ⚠️ Decidir estrategia para `tipoTarea`: ¿"Libre" o nombre de fase?
3. ⚠️ Decidir estrategia para fecha límite: ¿suma acumulativa o +7 días por tarea?
4. ⚠️ Confirmar auto-asignación de responsables

**USUARIO: ¿Qué quieres que corrija primero?**
