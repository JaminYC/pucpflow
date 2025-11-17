# ✅ PMI Task Saving Fix - Implementado

## 🐛 Problema Detectado

**Reporte del Usuario:**
> "Bien ahora que lo ha creado que de ia analizado porque ahroa veo solo el proyecto vacio sin areas designadas ademas el flujo de tareas por area esta con errores ese flujo deberia verse por fases no luego entregables paquetes de trabajo ya asi no ??"

### Síntomas:
1. ❌ Proyecto PMI se creaba pero aparecía vacío
2. ❌ No se mostraban tareas generadas por la IA
3. ❌ Las fases no tenían tareas asociadas
4. ❌ Los riesgos y stakeholders no se guardaban

### Causa Raíz:
El flujo de generación tenía estos pasos:
```
1. Cloud Function genera estructura PMI (fases + tareas + riesgos + stakeholders)
2. Flutter recibe el JSON con toda la estructura
3. Flutter crea el proyecto en Firestore con campos básicos PMI
4. Flutter crea las 5 fases PMI vacías
5. ❌ AQUÍ ESTABA EL PROBLEMA: Las tareas nunca se guardaban
6. Usuario ve proyecto vacío
```

**Código problemático anterior:**
```dart
// Solo creaba el proyecto y las fases vacías
final proyectoId = await pmiService.crearProyectoPMI(
  nombre: nombreProyecto,
  objetivo: proyectoIA['objetivo'],
  alcance: proyectoIA['alcance'],
  presupuesto: proyectoIA['presupuestoEstimado'],
);

// ❌ FALTABA: Guardar proyectoIA['fases'][].tareas
// ❌ FALTABA: Guardar proyectoIA['riesgos']
// ❌ FALTABA: Guardar proyectoIA['stakeholders']
```

---

## ✅ Solución Implementada

### Cambios en [crear_proyecto_pmi_page.dart](lib/features/user_auth/presentation/pages/Proyectos/crear_proyecto_pmi_page.dart)

#### 1. Imports Agregados (líneas 2-5)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarea_model.dart';
```

**Por qué:** Necesitamos acceso directo a Firestore para actualizar el proyecto con tareas, y el modelo Tarea para convertir los datos de la IA.

---

#### 2. Método `_guardarTareasEnProyecto()` (líneas 99-183)

**Propósito:** Procesa el JSON de la IA y guarda todas las tareas en el proyecto.

**Flujo:**
```
1. Extrae fases del proyectoIA['fases']
2. Por cada fase:
   - Extrae array de tareas
   - Por cada tarea:
     - Convierte JSON → objeto Tarea
     - Asigna color según fase
     - Asigna área = nombre de fase
     - Agrega a lista todasLasTareas
3. Guarda todas las tareas en Firestore (campo 'tareas')
4. Actualiza cada fase con totalTareas
5. Guarda metadatasPMI (riesgos + stakeholders)
```

**Código:**
```dart
Future<void> _guardarTareasEnProyecto(
  String proyectoId,
  Map<String, dynamic> proyectoIA,
) async {
  try {
    final fasesData = proyectoIA['fases'] as List<dynamic>? ?? [];
    List<Tarea> todasLasTareas = [];

    // Procesar cada fase y extraer tareas
    for (var faseData in fasesData) {
      final nombreFase = faseData['nombre'] ?? '';
      final tareasData = faseData['tareas'] as List<dynamic>? ?? [];

      for (var tareaData in tareasData) {
        // Crear objeto Tarea desde los datos de la IA
        final tarea = Tarea(
          titulo: tareaData['titulo'] ?? 'Tarea sin título',
          descripcion: tareaData['descripcion'] ?? '',
          fecha: DateTime.now().add(
            Duration(days: tareaData['duracionDias'] ?? 7),
          ),
          duracion: (tareaData['duracionDias'] ?? 1) * 60, // Días → minutos
          prioridad: tareaData['prioridad'] ?? 3,
          completado: false,
          colorId: _obtenerColorPorFase(nombreFase),
          responsables: [],
          tipoTarea: 'Automática',
          requisitos: {},
          dificultad: _calcularDificultad(tareaData['prioridad'] ?? 3),
          tareasPrevias: [],
          area: nombreFase, // ⭐ Usar nombre de fase como área
          habilidadesRequeridas: List<String>.from(
            tareaData['habilidadesRequeridas'] ?? [],
          ),
        );

        todasLasTareas.add(tarea);
      }
    }

    // Guardar todas las tareas en el proyecto
    if (todasLasTareas.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(proyectoId)
          .update({
        'tareas': todasLasTareas.map((t) => t.toJson()).toList(),
      });

      print('✅ ${todasLasTareas.length} tareas guardadas en el proyecto');
    }

    // Actualizar contadores de tareas por fase
    final pmiService = _pmiIAService.pmiService;
    for (var faseData in fasesData) {
      final faseId = _obtenerIdFase(faseData['nombre']);
      final tareasData = faseData['tareas'] as List<dynamic>? ?? [];

      await pmiService.actualizarFase(proyectoId, faseId, {
        'totalTareas': tareasData.length,
        'descripcion': faseData['descripcion'] ?? '',
      });
    }

    // Guardar riesgos y stakeholders en metadatasPMI
    final metadatas = {
      'riesgos': proyectoIA['riesgos'] ?? [],
      'stakeholders': proyectoIA['stakeholders'] ?? [],
      'generadoPorIA': true,
      'fechaGeneracion': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('proyectos')
        .doc(proyectoId)
        .update({
      'metadatasPMI': metadatas,
    });

    print('✅ Metadatas PMI guardadas');
  } catch (e) {
    print('❌ Error guardando tareas: $e');
    throw e;
  }
}
```

---

#### 3. Métodos Auxiliares (líneas 54-96)

##### `_obtenerIdFase(String nombre)` (líneas 54-70)
**Propósito:** Convierte nombre de fase → ID de fase para Firestore.

**Mapeo:**
```dart
'Iniciación' → 'iniciacion'
'Planificación' → 'planificacion'
'Ejecución' → 'ejecucion'
'Monitoreo y Control' → 'monitoreo'
'Monitoreo' → 'monitoreo'
'Cierre' → 'cierre'
```

##### `_obtenerColorPorFase(String nombreFase)` (líneas 73-89)
**Propósito:** Asigna un color distintivo a cada fase PMI.

**Paleta de Colores:**
```dart
Iniciación → 0xFF4CAF50 (Verde)
Planificación → 0xFF2196F3 (Azul)
Ejecución → 0xFFFF9800 (Naranja)
Monitoreo → 0xFF9C27B0 (Púrpura)
Cierre → 0xFF607D8B (Gris azulado)
```

##### `_calcularDificultad(int prioridad)` (líneas 92-96)
**Propósito:** Mapea prioridad numérica → nivel de dificultad textual.

**Mapeo:**
```dart
prioridad <= 2 → 'baja'
prioridad <= 3 → 'media'
prioridad >= 4 → 'alta'
```

---

#### 4. Actualización del Método `_generarProyecto()` (líneas 281-292)

**Antes:**
```dart
setState(() {
  _progreso = 0.9;
  _progresoMensaje = 'Guardando información adicional...';
});

await Future.delayed(const Duration(milliseconds: 500));

setState(() {
  _progreso = 1.0;
  _progresoMensaje = '✅ Proyecto PMI creado exitosamente';
});
```

**Después:**
```dart
setState(() {
  _progreso = 0.8;
  _progresoMensaje = 'Guardando tareas y fases...';
});

// ⭐ NUEVO: Guardar tareas generadas por IA
await _guardarTareasEnProyecto(proyectoId, proyectoIA);

setState(() {
  _progreso = 0.9;
  _progresoMensaje = 'Guardando información adicional...';
});

await Future.delayed(const Duration(milliseconds: 500));

setState(() {
  _progreso = 1.0;
  _progresoMensaje = '✅ Proyecto PMI creado exitosamente';
});
```

**Nuevo Flujo de Progreso:**
```
10% - Convirtiendo documentos
20% - Analizando con IA (2-3 min)
70% - Creando proyecto base
80% - ⭐ Guardando tareas y fases
90% - Guardando información adicional
100% - ✅ Completo
```

---

## 📊 Estructura de Datos

### JSON Generado por Cloud Function
```json
{
  "success": true,
  "proyecto": {
    "objetivo": "Implementar sistema de gestión...",
    "alcance": "El proyecto incluye...",
    "descripcion": "Proyecto para...",
    "presupuestoEstimado": 50000,
    "fases": [
      {
        "nombre": "Iniciación",
        "descripcion": "Fase inicial del proyecto...",
        "tareas": [
          {
            "titulo": "Elaborar Project Charter",
            "descripcion": "Documento formal que autoriza...",
            "duracionDias": 5,
            "prioridad": 5,
            "habilidadesRequeridas": ["Gestión de Proyectos", "Documentación"]
          },
          {
            "titulo": "Identificar stakeholders",
            "descripcion": "Listar todas las partes interesadas...",
            "duracionDias": 3,
            "prioridad": 4,
            "habilidadesRequeridas": ["Comunicación", "Análisis"]
          }
        ]
      },
      {
        "nombre": "Planificación",
        "descripcion": "Planificación detallada...",
        "tareas": [...]
      },
      // ... 3 fases más
    ],
    "riesgos": [
      {
        "descripcion": "Falta de recursos técnicos especializados",
        "impacto": "Alto",
        "probabilidad": "Media",
        "estrategia": "Contratar consultores externos"
      }
    ],
    "stakeholders": [
      {
        "nombre": "Gerente de TI",
        "rol": "Sponsor",
        "interes": "Alto",
        "influencia": "Alta"
      }
    ]
  }
}
```

### Estructura en Firestore

**Documento Principal:** `proyectos/{proyectoId}`
```json
{
  "id": "abc123",
  "nombre": "Sistema de Gestión ERP",
  "descripcion": "Proyecto para...",
  "esPMI": true,
  "objetivo": "Implementar sistema...",
  "alcance": "El proyecto incluye...",
  "presupuesto": 50000,
  "costoActual": 0,
  "fasePMIActual": "Iniciación",
  "fechaInicio": "2025-11-16T00:00:00Z",
  "propietario": "user123",
  "participantes": ["user123"],
  "tareas": [
    {
      "titulo": "Elaborar Project Charter",
      "descripcion": "Documento formal...",
      "fecha": "2025-11-21T00:00:00Z",
      "duracion": 300,
      "prioridad": 5,
      "completado": false,
      "colorId": 0xFF4CAF50,
      "responsables": [],
      "tipoTarea": "Automática",
      "requisitos": {},
      "dificultad": "alta",
      "tareasPrevias": [],
      "area": "Iniciación",
      "habilidadesRequeridas": ["Gestión de Proyectos", "Documentación"]
    },
    // ... más tareas
  ],
  "metadatasPMI": {
    "riesgos": [...],
    "stakeholders": [...],
    "generadoPorIA": true,
    "fechaGeneracion": "2025-11-16T12:30:00Z"
  }
}
```

**Subcollection:** `proyectos/{proyectoId}/fases_pmi/{faseId}`
```json
{
  "id": "iniciacion",
  "nombre": "Iniciación",
  "orden": 1,
  "estado": "in_progress",
  "totalTareas": 8,
  "tareasCompletadas": 0,
  "progreso": 0.0,
  "descripcion": "Fase inicial del proyecto...",
  "tareasIds": [],
  "documentosIds": []
}
```

---

## 🎯 Mapeo de Datos: IA → Tarea

| Campo IA | Campo Tarea | Transformación |
|----------|-------------|----------------|
| `titulo` | `titulo` | Directo |
| `descripcion` | `descripcion` | Directo |
| `duracionDias` | `fecha` | `DateTime.now() + Duration(days: duracionDias)` |
| `duracionDias` | `duracion` | `duracionDias * 60` (convertir a minutos) |
| `prioridad` | `prioridad` | Directo (1-5) |
| `prioridad` | `dificultad` | `_calcularDificultad()` |
| `habilidadesRequeridas` | `habilidadesRequeridas` | `List<String>.from()` |
| `fase.nombre` | `area` | Directo |
| `fase.nombre` | `colorId` | `_obtenerColorPorFase()` |
| N/A | `completado` | `false` (por defecto) |
| N/A | `responsables` | `[]` (vacío inicialmente) |
| N/A | `tipoTarea` | `'Automática'` |
| N/A | `requisitos` | `{}` (vacío) |
| N/A | `tareasPrevias` | `[]` (vacío) |

---

## ✅ Resultados Esperados

### Antes del Fix:
```
Usuario crea proyecto PMI con IA
  ↓
Cloud Function genera estructura completa
  ↓
Flutter crea proyecto base + 5 fases vacías
  ↓
❌ Usuario ve proyecto vacío
  - 0 tareas
  - Sin riesgos
  - Sin stakeholders
  - Fases sin descripción
```

### Después del Fix:
```
Usuario crea proyecto PMI con IA
  ↓
Cloud Function genera estructura completa
  ↓
Flutter crea proyecto base + 5 fases
  ↓
Flutter guarda todas las tareas (25-40 tareas)
  ↓
Flutter actualiza contadores de fases
  ↓
Flutter guarda metadatasPMI
  ↓
✅ Usuario ve proyecto completo
  - 25-40 tareas distribuidas en 5 fases
  - 3-5 riesgos identificados
  - 2-4 stakeholders
  - Cada fase con descripción y contador de tareas
```

---

## 🔍 Verificación

### Queries de Firestore para Verificar:

```javascript
// 1. Verificar que el proyecto tiene tareas
db.collection('proyectos').doc(proyectoId).get()
  .then(doc => console.log(`Tareas: ${doc.data().tareas.length}`));

// 2. Verificar metadatasPMI
db.collection('proyectos').doc(proyectoId).get()
  .then(doc => {
    console.log('Riesgos:', doc.data().metadatasPMI.riesgos.length);
    console.log('Stakeholders:', doc.data().metadatasPMI.stakeholders.length);
  });

// 3. Verificar contadores de fases
db.collection('proyectos').doc(proyectoId)
  .collection('fases_pmi').get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      console.log(`${doc.id}: ${doc.data().totalTareas} tareas`);
    });
  });
```

### Outputs Esperados en Console:
```
✅ 32 tareas guardadas en el proyecto
✅ Metadatas PMI guardadas

// Por cada fase:
Fase iniciacion actualizada con 8 tareas
Fase planificacion actualizada con 10 tareas
Fase ejecucion actualizada con 9 tareas
Fase monitoreo actualizada con 3 tareas
Fase cierre actualizada con 2 tareas
```

---

## 🚀 Siguientes Pasos

### ✅ Completado:
1. ✅ Crear método `_guardarTareasEnProyecto()`
2. ✅ Integrar en flujo de generación
3. ✅ Mapear JSON de IA → objetos Tarea
4. ✅ Guardar tareas en Firestore
5. ✅ Actualizar contadores de fases
6. ✅ Guardar metadatasPMI

### 🔜 Pendiente (segundo pedido del usuario):
> "ese flujo deberia verse por fases no luego entregables paquetes de trabajo ya asi no ??"

**Interpretación:**
- Actualmente ProyectoDetallePage muestra tareas por "áreas"
- Debería mostrar por "fases PMI" con jerarquía:
  - **Fases** → **Entregables** → **Paquetes de Trabajo** → **Actividades**

**Trabajo por hacer:**
1. Crear nueva vista PMI específica o modificar ProyectoDetallePage
2. Mostrar pestañas/acordeones por fase
3. Agrupar tareas dentro de cada fase
4. Mostrar progreso por fase
5. Mostrar riesgos y stakeholders de metadatasPMI

---

## 📝 Notas Técnicas

### Por qué guardamos tareas en el documento principal:
- **Compatibilidad**: El sistema actual usa `proyecto.tareas` como array
- **Simplicidad**: Una sola query para obtener proyecto + tareas
- **Migración gradual**: Más adelante se pueden mover a subcollection

### Límite de Firestore:
- Documento máximo: 1 MB
- Cada tarea ~500 bytes
- Límite teórico: ~2000 tareas por proyecto
- Límite práctico recomendado: ~200 tareas
- Proyectos PMI generados: 25-40 tareas ✅ Bien dentro del límite

---

**Autor:** Claude (Anthropic)
**Fecha:** 2025-11-16
**Versión:** 1.0.0
