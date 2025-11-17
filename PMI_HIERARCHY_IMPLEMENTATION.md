# ✅ Implementación de Jerarquía PMI Completa

## 🎯 Problema Resuelto

**Pedido del Usuario:**
> "Claro osea las areas serían las personas materiales herramientas próximamente etapa de inventario y recursos y las fases entregables paquetes de trabajo son la estructura del proyecto donde cada persona va a realizar las tareas de acuerdo a lo que corresponde"

### ❌ Problema Anterior:
- Campo `area` se usaba incorrectamente para almacenar la **fase PMI** ("Iniciación", "Planificación")
- No existía jerarquía PMI: Fase → Entregables → Paquetes de Trabajo → Tareas
- No se distinguía entre **estructura del proyecto** y **recursos**

### ✅ Solución Implementada:
- Campo `area` ahora almacena **RECURSOS** ("Equipo Desarrollo", "Consultor PMI")
- Nuevos campos PMI:
  - `fasePMI`: Fase del proyecto ("Iniciación", "Planificación", etc.)
  - `entregable`: Producto esperado ("Project Charter", "Plan de Proyecto")
  - `paqueteTrabajo`: Grupo de tareas relacionadas ("Documentación Inicial", "Análisis de Riesgos")

---

## 📊 Jerarquía PMI Correcta

```
Proyecto PMI
│
├── Fase: Iniciación
│   ├── Entregable: Project Charter
│   │   ├── Paquete de Trabajo: Documentación Inicial
│   │   │   ├── Tarea: "Redactar objetivos del proyecto"
│   │   │   │   ├── fasePMI: "Iniciación"
│   │   │   │   ├── entregable: "Project Charter"
│   │   │   │   ├── paqueteTrabajo: "Documentación Inicial"
│   │   │   │   └── area: "Equipo PM" ← RECURSO
│   │   │   └── Tarea: "Definir alcance preliminar"
│   │   │       ├── fasePMI: "Iniciación"
│   │   │       ├── entregable: "Project Charter"
│   │   │       ├── paqueteTrabajo: "Documentación Inicial"
│   │   │       └── area: "Equipo PM"
│   │   └── Paquete de Trabajo: Aprobaciones
│   │       └── Tarea: "Obtener firma del sponsor"
│   │           ├── fasePMI: "Iniciación"
│   │           ├── entregable: "Project Charter"
│   │           ├── paqueteTrabajo: "Aprobaciones"
│   │           └── area: "Gerencia"
│   └── Entregable: Registro de Stakeholders
│       └── Paquete de Trabajo: Identificación de Partes Interesadas
│           └── Tarea: "Listar stakeholders clave"
│               ├── fasePMI: "Iniciación"
│               ├── entregable: "Registro de Stakeholders"
│               ├── paqueteTrabajo: "Identificación de Partes Interesadas"
│               └── area: "Equipo PM"
│
├── Fase: Planificación
│   ├── Entregable: Plan de Gestión del Proyecto
│   ├── Entregable: WBS (Work Breakdown Structure)
│   └── Entregable: Cronograma del Proyecto
│
└── ... (Ejecución, Monitoreo, Cierre)
```

---

## 🔧 Cambios Implementados

### 1. Modelo `Tarea` Extendido

**Archivo:** [tarea_model.dart](lib/features/user_auth/presentation/pages/Proyectos/tarea_model.dart)

#### Campos Agregados (líneas 17-22):
```dart
// ========================================
// 🆕 CAMPOS PMI - Jerarquía del Proyecto
// ========================================
String? fasePMI;        // "Iniciación", "Planificación", "Ejecución", "Monitoreo", "Cierre"
String? entregable;     // "Project Charter", "Plan de Proyecto", "Informe Final"
String? paqueteTrabajo; // "Documentación Inicial", "Análisis de Riesgos", "Testing"
```

#### Campo `area` Clarificado (línea 14):
```dart
String area; // ✅ Para recursos: "Equipo Desarrollo", "Consultor Externo", etc.
```

#### Constructor Actualizado (líneas 43-45):
```dart
// Campos PMI opcionales
this.fasePMI,
this.entregable,
this.paqueteTrabajo,
```

#### Serialización/Deserialización (líneas 66-68, 89-91):
```dart
// toJson()
'fasePMI': fasePMI,
'entregable': entregable,
'paqueteTrabajo': paqueteTrabajo,

// fromJson()
fasePMI: json['fasePMI'],
entregable: json['entregable'],
paqueteTrabajo: json['paqueteTrabajo'],
```

---

### 2. Cloud Function Actualizada

**Archivo:** [functions/index.js](functions/index.js)

#### Prompt Mejorado (líneas 1187-1273):

**Antes:**
```javascript
"tareas": [
  {
    "titulo": "...",
    "descripcion": "...",
    "duracionDias": 0,
    "prioridad": 1-5,
    "habilidadesRequeridas": ["skill1", "skill2"]
  }
]
```

**Después:**
```javascript
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
            "areaRecomendada": "Equipo PM"  // ✅ NUEVO: Recurso recomendado
          }
        ]
      }
    ]
  }
]
```

#### Instrucciones Clave Agregadas:
```
JERARQUÍA PMI (MUY IMPORTANTE):
Para cada fase, debes generar entregables, y dentro de cada entregable,
paquetes de trabajo, y dentro de cada paquete, tareas.

Fase → Entregables → Paquetes de Trabajo → Tareas

IMPORTANTE sobre ÁREAS:
- El campo "area" NO es para fases, es para RECURSOS (personas, equipos, materiales)
- Ejemplos de áreas correctas: "Equipo Desarrollo", "Consultor PMI", "Equipo Marketing"
- El campo "area" indica QUIÉN o QUÉ RECURSO ejecutará la tarea
```

#### Métricas Esperadas:
```javascript
IMPORTANTE:
- Genera 2-4 entregables por fase
- Cada entregable debe tener 1-3 paquetes de trabajo
- Cada paquete de trabajo debe tener 2-5 tareas
- Total aproximado: 30-50 tareas en todo el proyecto
```

---

### 3. Lógica de Guardado Actualizada

**Archivo:** [crear_proyecto_pmi_page.dart](lib/features/user_auth/presentation/pages/Proyectos/crear_proyecto_pmi_page.dart)

#### Método `_guardarTareasEnProyecto()` Refactorizado (líneas 109-163):

**Antes (estructura plana):**
```dart
for (var faseData in fasesData) {
  final nombreFase = faseData['nombre'] ?? '';
  final tareasData = faseData['tareas'] as List<dynamic>? ?? [];

  for (var tareaData in tareasData) {
    final tarea = Tarea(
      titulo: tareaData['titulo'],
      area: nombreFase, // ❌ INCORRECTO
      // ...
    );
  }
}
```

**Después (estructura jerárquica):**
```dart
// Procesar cada fase → entregables → paquetes de trabajo → tareas
for (var faseData in fasesData) {
  final nombreFase = faseData['nombre'] ?? '';
  final entregablesData = faseData['entregables'] as List<dynamic>? ?? [];

  for (var entregableData in entregablesData) {
    final nombreEntregable = entregableData['nombre'] ?? 'Entregable';
    totalEntregables++;

    final paquetesData = entregableData['paquetesTrabajo'] as List<dynamic>? ?? [];

    for (var paqueteData in paquetesData) {
      final nombrePaquete = paqueteData['nombre'] ?? 'Paquete de Trabajo';
      totalPaquetes++;

      final tareasData = paqueteData['tareas'] as List<dynamic>? ?? [];

      for (var tareaData in tareasData) {
        final tarea = Tarea(
          titulo: tareaData['titulo'] ?? 'Tarea sin título',
          descripcion: tareaData['descripcion'] ?? '',
          area: tareaData['areaRecomendada'] ?? 'Sin asignar', // ✅ Recurso
          // ✅ Campos PMI - Jerarquía del proyecto
          fasePMI: nombreFase,
          entregable: nombreEntregable,
          paqueteTrabajo: nombrePaquete,
          // ... otros campos
        );
        todasLasTareas.add(tarea);
      }
    }
  }
}
```

#### Logs de Diagnóstico (líneas 159-163):
```dart
print('📊 Estructura PMI generada:');
print('   - ${fasesData.length} fases');
print('   - $totalEntregables entregables');
print('   - $totalPaquetes paquetes de trabajo');
print('   - ${todasLasTareas.length} tareas');
```

#### Actualización de Fases (líneas 183-185):
```dart
// Contar tareas de esta fase
int tareasEnFase = todasLasTareas
    .where((t) => t.fasePMI == faseData['nombre'])
    .length;
```

---

## 📋 Estructura de Datos en Firestore

### Documento `proyectos/{proyectoId}`

```json
{
  "id": "abc123",
  "nombre": "Sistema de Gestión ERP",
  "esPMI": true,
  "objetivo": "Implementar sistema ERP...",
  "alcance": "El proyecto incluye...",
  "presupuesto": 50000,
  "fasePMIActual": "Iniciación",

  "tareas": [
    {
      "titulo": "Redactar objetivos del proyecto",
      "descripcion": "Documento formal que define...",
      "duracion": 180,
      "prioridad": 5,
      "completado": false,
      "colorId": 0xFF4CAF50,
      "area": "Equipo PM",
      "habilidadesRequeridas": ["Gestión de Proyectos", "Redacción"],

      "fasePMI": "Iniciación",
      "entregable": "Project Charter",
      "paqueteTrabajo": "Documentación Inicial",

      "responsables": [],
      "tipoTarea": "Automática",
      "dificultad": "alta"
    },
    {
      "titulo": "Definir alcance preliminar",
      "descripcion": "Establecer límites del proyecto...",
      "duracion": 120,
      "prioridad": 5,
      "completado": false,
      "colorId": 0xFF4CAF50,
      "area": "Equipo PM",

      "fasePMI": "Iniciación",
      "entregable": "Project Charter",
      "paqueteTrabajo": "Documentación Inicial",

      "habilidadesRequeridas": ["Análisis de Negocios"]
    },
    {
      "titulo": "Listar stakeholders clave",
      "descripcion": "Identificar todas las partes interesadas...",
      "duracion": 60,
      "prioridad": 4,
      "area": "Equipo PM",

      "fasePMI": "Iniciación",
      "entregable": "Registro de Stakeholders",
      "paqueteTrabajo": "Identificación de Partes Interesadas"
    }
  ],

  "metadatasPMI": {
    "riesgos": [...],
    "stakeholders": [...],
    "generadoPorIA": true
  }
}
```

---

## 🔍 Queries para Visualización

### 1. Agrupar Tareas por Fase
```dart
Map<String, List<Tarea>> tareasPorFase = {};

for (var tarea in proyecto.tareas) {
  final fase = tarea.fasePMI ?? 'Sin fase';
  if (!tareasPorFase.containsKey(fase)) {
    tareasPorFase[fase] = [];
  }
  tareasPorFase[fase]!.add(tarea);
}
```

### 2. Agrupar por Fase → Entregable
```dart
Map<String, Map<String, List<Tarea>>> jerarquia = {};

for (var tarea in proyecto.tareas) {
  final fase = tarea.fasePMI ?? 'Sin fase';
  final entregable = tarea.entregable ?? 'Sin entregable';

  if (!jerarquia.containsKey(fase)) {
    jerarquia[fase] = {};
  }
  if (!jerarquia[fase]!.containsKey(entregable)) {
    jerarquia[fase]![entregable] = [];
  }
  jerarquia[fase]![entregable]!.add(tarea);
}
```

### 3. Agrupar por Fase → Entregable → Paquete de Trabajo
```dart
Map<String, Map<String, Map<String, List<Tarea>>>> jerarquiaCompleta = {};

for (var tarea in proyecto.tareas) {
  final fase = tarea.fasePMI ?? 'Sin fase';
  final entregable = tarea.entregable ?? 'Sin entregable';
  final paquete = tarea.paqueteTrabajo ?? 'Sin paquete';

  jerarquiaCompleta.putIfAbsent(fase, () => {});
  jerarquiaCompleta[fase]!.putIfAbsent(entregable, () => {});
  jerarquiaCompleta[fase]![entregable]!.putIfAbsent(paquete, () => []);
  jerarquiaCompleta[fase]![entregable]![paquete]!.add(tarea);
}
```

### 4. Agrupar Tareas por Área (Recursos)
```dart
Map<String, List<Tarea>> tareasPorRecurso = {};

for (var tarea in proyecto.tareas) {
  final recurso = tarea.area;
  if (!tareasPorRecurso.containsKey(recurso)) {
    tareasPorRecurso[recurso] = [];
  }
  tareasPorRecurso[recurso]!.add(tarea);
}

// Ejemplo de output:
// "Equipo PM": [10 tareas]
// "Equipo Desarrollo": [15 tareas]
// "Consultor Legal": [3 tareas]
```

---

## 🎨 Ejemplo de UI para ProyectoDetallePage

### Vista por Fases PMI:

```
┌─────────────────────────────────────────────────┐
│ 📊 Proyecto: Sistema de Gestión ERP            │
├─────────────────────────────────────────────────┤
│ [Iniciación] [Planificación] [Ejecución] ...   │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 🟢 Fase: Iniciación (12 tareas)                │
│                                                 │
│ 📦 Entregable: Project Charter                 │
│   ├─ 📋 Paquete: Documentación Inicial (3)     │
│   │   ├─ ✅ Redactar objetivos                 │
│   │   ├─ 🔲 Definir alcance                    │
│   │   └─ 🔲 Establecer restricciones           │
│   └─ 📋 Paquete: Aprobaciones (2)              │
│       ├─ 🔲 Obtener firma del sponsor          │
│       └─ 🔲 Presentación a stakeholders        │
│                                                 │
│ 📦 Entregable: Registro de Stakeholders        │
│   └─ 📋 Paquete: Identificación (4)            │
│       ├─ 🔲 Listar stakeholders clave          │
│       ├─ 🔲 Analizar intereses                 │
│       ├─ 🔲 Mapear influencia                  │
│       └─ 🔲 Definir estrategias                │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 🔵 Fase: Planificación (18 tareas)             │
│ [Click para expandir]                           │
└─────────────────────────────────────────────────┘
```

### Vista por Recursos:

```
┌─────────────────────────────────────────────────┐
│ 👥 Recursos del Proyecto                       │
├─────────────────────────────────────────────────┤
│                                                 │
│ 🏢 Equipo PM (10 tareas)                       │
│   ├─ 🟢 [Iniciación] Redactar objetivos        │
│   ├─ 🟢 [Iniciación] Definir alcance           │
│   ├─ 🔵 [Planificación] Crear WBS              │
│   └─ ...                                        │
│                                                 │
│ 💻 Equipo Desarrollo (15 tareas)               │
│   ├─ 🟠 [Ejecución] Configurar entorno         │
│   ├─ 🟠 [Ejecución] Desarrollar módulos        │
│   └─ ...                                        │
│                                                 │
│ ⚖️ Consultor Legal (3 tareas)                  │
│   ├─ 🟢 [Iniciación] Revisar contratos         │
│   └─ ...                                        │
└─────────────────────────────────────────────────┘
```

---

## ✅ Resultados Esperados

### Al Crear un Proyecto PMI:

```
Usuario sube PDFs → Cloud Function analiza
  ↓
IA genera estructura JSON:
  {
    "fases": [
      {
        "nombre": "Iniciación",
        "entregables": [
          {
            "nombre": "Project Charter",
            "paquetesTrabajo": [
              {
                "nombre": "Documentación Inicial",
                "tareas": [
                  {
                    "titulo": "Redactar objetivos",
                    "areaRecomendada": "Equipo PM"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
  ↓
Flutter procesa jerarquía:
  - 5 fases
  - 12 entregables
  - 25 paquetes de trabajo
  - 42 tareas
  ↓
Firestore guarda tareas con:
  - fasePMI ✅
  - entregable ✅
  - paqueteTrabajo ✅
  - area (recurso) ✅
  ↓
Usuario ve proyecto completo con jerarquía PMI
```

### Console Output Esperado:
```
📊 Estructura PMI generada:
   - 5 fases
   - 12 entregables
   - 25 paquetes de trabajo
   - 42 tareas
✅ 42 tareas guardadas en el proyecto
✅ Metadatas PMI guardadas
```

---

## 🔮 Próximos Pasos

### 1. Vista de Proyecto PMI (Pendiente)
Crear `ProyectoDetallePMIPage.dart` o modificar `ProyectoDetallePage.dart` para:
- Detectar si `proyecto.esPMI == true`
- Mostrar pestañas/acordeones por fase
- Dentro de cada fase, mostrar entregables
- Dentro de cada entregable, mostrar paquetes de trabajo
- Dentro de cada paquete, mostrar tareas
- Mostrar vista alternativa por recursos (área)

### 2. Gestión de Recursos
- Crear página para agregar/editar recursos del proyecto
- Asignar recursos (áreas) a tareas
- Vista de carga de trabajo por recurso

### 3. Migración de Proyectos Existentes
Los proyectos antiguos seguirán funcionando porque:
- `fasePMI`, `entregable`, `paqueteTrabajo` son opcionales (`String?`)
- `fromJson()` maneja valores null
- Pueden convivir proyectos normales y PMI

---

## 📝 Diferencias Clave

| Concepto | Antes | Ahora |
|----------|-------|-------|
| **Fase PMI** | Almacenada en `area` ❌ | Almacenada en `fasePMI` ✅ |
| **Entregable** | No existía | Campo `entregable` ✅ |
| **Paquete de Trabajo** | No existía | Campo `paqueteTrabajo` ✅ |
| **Área** | "Iniciación", "Planificación" ❌ | "Equipo PM", "Consultor" ✅ |
| **Jerarquía** | Plana (solo tareas) | 4 niveles (Fase → Entregable → Paquete → Tarea) ✅ |
| **Recursos** | No se identificaban | Campo `area` + `areaRecomendada` ✅ |

---

## 🚀 Deployment

✅ **Cloud Function desplegada exitosamente**
```bash
cd functions
firebase deploy --only functions:generarProyectoPMI

+ functions[generarProyectoPMI(us-central1)] Successful update operation.
+ Deploy complete!
```

---

**Autor:** Claude (Anthropic)
**Fecha:** 2025-11-16
**Versión:** 2.0.0 (Jerarquía PMI Completa)
