# 📊 ESTRUCTURA COMPLETA DE PROYECTOS

## 🎯 TIPOS DE PROYECTOS

### 1. **PROYECTO PERSONAL**
**Archivo**: `crear_proyecto_personal_page.dart`
**Propósito**: Proyectos individuales generados por IA basados en PDFs
**Usuario**: Una sola persona

#### Estructura de Áreas:
- ✅ **UNA SOLA ÁREA**: `"Personal"`
- ❌ NO usa múltiples áreas
- ❌ NO necesita recursos/equipos

#### Estructura de Tareas:
```dart
Tarea(
  titulo: "Nombre de la tarea",
  tipoTarea: "Nombre de la Fase",  // Ej: "Preparación", "Desarrollo"
  area: "Personal",                 // SIEMPRE "Personal"
  fasePMI: "Nombre de la Fase",     // Para agrupar por fase
  // ... otros campos
)
```

#### Map de Áreas en Firestore:
```dart
areas: {
  "Personal": []  // Sin participantes (es personal)
}
```

---

### 2. **PROYECTO PMI**
**Archivo**: `crear_proyecto_pmi_page.dart`
**Propósito**: Proyectos empresariales con metodología PMI (5 fases)
**Usuario**: Equipos grandes con recursos especializados

#### Estructura de Áreas:
- ✅ **MÚLTIPLES ÁREAS**: Generadas por IA basadas en roles/equipos
- ✅ Ejemplos: `"Equipo Desarrollo"`, `"Equipo QA"`, `"Consultores"`, `"Administración"`
- ✅ Las áreas se llaman **"recursos"** en el modelo PMI

#### Estructura de Tareas:
```dart
Tarea(
  titulo: "Nombre de la tarea",
  tipoTarea: "Automática",          // Siempre "Automática" (generada por IA)
  area: "Equipo Desarrollo",        // Área recomendada por IA
  fasePMI: "Iniciación",            // Una de las 5 fases PMI
  entregable: "Project Charter",    // Entregable de la fase
  paqueteTrabajo: "Documentación",  // Paquete de trabajo
  // ... otros campos
)
```

#### Las 5 Fases PMI:
1. **Iniciación**
2. **Planificación**
3. **Ejecución**
4. **Monitoreo y Control**
5. **Cierre**

#### Map de Áreas (Recursos) en Firestore:
```dart
recursos: {  // ⚠️ Se llama "recursos" NO "areas"
  "Equipo Desarrollo": [],
  "Equipo QA": [],
  "Consultores": [],
  "Administración": []
}
```

---

### 3. **PROYECTO CONTEXTUAL / COLABORATIVO**
**Archivo**: `crear_proyecto_contextual_page.dart`
**Propósito**: Proyectos flexibles con metodologías Agile/Scrum/Kanban
**Usuario**: Equipos colaborativos con contextos específicos

#### Estructura de Áreas:
- ✅ **DOS ÁREAS FIJAS**: `"Blueprint IA"` y `"Hitos"`
- ❌ NO genera áreas dinámicas
- ❌ NO cambian según el proyecto

#### Estructura de Tareas:
```dart
// Tareas del Backlog
Tarea(
  titulo: "Nombre de la tarea",
  tipoTarea: "Desarrollo" / "Diseño" / "Testing" / "Seguimiento",
  area: "Blueprint IA",              // SIEMPRE "Blueprint IA"
  entregable: "Backlog IA",
  // ... otros campos
)

// Tareas de Hitos
Tarea(
  titulo: "Nombre del hito",
  tipoTarea: "Hito",                 // SIEMPRE "Hito"
  area: "Hitos",                     // SIEMPRE "Hitos"
  entregable: "Hito IA",
  // ... otros campos
)
```

#### Map de Áreas en Firestore:
```dart
areas: {
  "Blueprint IA": [],
  "Hitos": []
}
```

---

## 🔑 REGLAS FUNDAMENTALES

### ✅ GARANTÍAS ANTI-DUPLICADOS:

1. **Proyectos Personales**:
   - Solo una área: `"Personal"`
   - Imposible tener duplicados

2. **Proyectos PMI**:
   - Áreas generadas por IA → Normalización obligatoria
   - Usar `Set<String>` para recopilar áreas únicas
   - Crear Map solo con áreas normalizadas

3. **Proyectos Contextuales**:
   - Áreas fijas hardcodeadas: `"Blueprint IA"` y `"Hitos"`
   - Imposible tener duplicados

### ❌ NUNCA:

- ❌ Usar nombres de fases como áreas (en proyectos personales)
- ❌ Usar nombres de tareas como áreas
- ❌ Permitir áreas con saltos de línea o espacios extra
- ❌ Crear áreas dinámicamente desde `_mergeAreasWithTaskAreas` sin normalización

---

## 🛠️ CAMPOS DE TAREA POR TIPO

### Campos Comunes:
```dart
- titulo: String
- descripcion: String
- fecha: DateTime
- duracion: int (minutos)
- prioridad: int (1-5)
- completado: bool
- colorId: int
- responsables: List<String>
- requisitos: Map<String, int>
- dificultad: String ('baja', 'media', 'alta')
- tareasPrevias: List<String>
- habilidadesRequeridas: List<String>
```

### Campos Específicos por Tipo:

#### Personal:
```dart
- tipoTarea: "Nombre de la Fase"
- area: "Personal"
- fasePMI: "Nombre de la Fase"
- entregable: null
- paqueteTrabajo: null
```

#### PMI:
```dart
- tipoTarea: "Automática"
- area: "Equipo X" (generado por IA)
- fasePMI: "Iniciación" | "Planificación" | "Ejecución" | "Monitoreo" | "Cierre"
- entregable: "Nombre del entregable"
- paqueteTrabajo: "Nombre del paquete"
```

#### Contextual:
```dart
- tipoTarea: "Desarrollo" | "Diseño" | "Testing" | "Seguimiento" | "Hito"
- area: "Blueprint IA" | "Hitos"
- fasePMI: null
- entregable: "Backlog IA" | "Hito IA"
- paqueteTrabajo: null
```

---

## 📝 RESUMEN EJECUTIVO

| Tipo | Áreas | Dónde se definen | Pueden duplicarse |
|------|-------|------------------|-------------------|
| **Personal** | 1 fija: `"Personal"` | Hardcodeado | ❌ NO |
| **PMI** | N dinámicas | IA → Normalización | ❌ NO (Set) |
| **Contextual** | 2 fijas: `"Blueprint IA"`, `"Hitos"` | Hardcodeado | ❌ NO |

---

## 🚨 PROBLEMA ANTERIOR

**Error**: "There should be exactly one item with [DropdownButton]'s value: Explorador Principiante"

**Causa**:
- Proyectos personales usaban nombres de fases como áreas
- Múltiples tareas con el mismo nombre de fase → Áreas duplicadas en el dropdown

**Solución**:
- Proyectos personales ahora usan área única: `"Personal"`
- Proyectos PMI normalizan áreas con `Set`
- Proyectos contextuales usan áreas fijas hardcodeadas
