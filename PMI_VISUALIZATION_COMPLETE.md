# ✅ Visualización PMI Completa - Implementada

## 🎯 Resumen de la Implementación

Se ha creado una visualización completa de la jerarquía PMI que muestra la estructura del proyecto en dos vistas diferentes:

1. **Vista de Jerarquía PMI**: Fases → Entregables → Paquetes de Trabajo → Tareas
2. **Vista de Recursos**: Agrupación por equipos/personas con sus tareas organizadas por fase

---

## 📁 Archivos Creados/Modificados

### 1. **NUEVO:** [grafo_tareas_pmi_page.dart](lib/features/user_auth/presentation/pages/Proyectos/grafo_tareas_pmi_page.dart)

Página de visualización especializada para proyectos PMI con dos modos de vista.

#### Características Principales:

**Toggle de Vistas:**
```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(
      value: 'jerarquia',
      label: Text('Fases PMI'),
      icon: Icon(Icons.account_tree),
    ),
    ButtonSegment(
      value: 'recursos',
      label: Text('Recursos'),
      icon: Icon(Icons.people),
    ),
  ],
  selected: {vistaActual},
  onSelectionChanged: (Set<String> newSelection) {
    setState(() {
      vistaActual = newSelection.first;
    });
  },
)
```

---

## 🎨 Vista 1: Jerarquía PMI

### Estructura Visual:

```
┌─────────────────────────────────────────────────┐
│ 🟢 Fase: Iniciación (12 tareas)                │
│ Progress: ████████░░░░░░ 66%                    │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📦 Entregable: Project Charter              │ │
│ │                                             │ │
│ │ ┌─────────────────────────────────────────┐ │ │
│ │ │ 📋 Paquete: Documentación Inicial       │ │ │
│ │ │                                         │ │ │
│ │ │ ✅ Redactar objetivos del proyecto      │ │ │
│ │ │    👥 Equipo PM | 🎯 alta | ⏱️ 180 min  │ │ │
│ │ │                                         │ │ │
│ │ │ 🔲 Definir alcance preliminar           │ │ │
│ │ │    👥 Equipo PM | 🎯 alta | ⏱️ 120 min  │ │ │
│ │ └─────────────────────────────────────────┘ │ │
│ │                                             │ │
│ │ ┌─────────────────────────────────────────┐ │ │
│ │ │ 📋 Paquete: Aprobaciones                │ │ │
│ │ │                                         │ │ │
│ │ │ 🔲 Obtener firma del sponsor            │ │ │
│ │ └─────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📦 Entregable: Registro de Stakeholders    │ │
│ │ ...                                         │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Implementación:

```dart
Widget _buildVistaJerarquiaPMI() {
  // Agrupar tareas por Fase → Entregable → Paquete
  final Map<String, Map<String, Map<String, List<Tarea>>>> jerarquia = {};

  for (var tarea in widget.tareas) {
    final fase = tarea.fasePMI ?? 'Sin fase';
    final entregable = tarea.entregable ?? 'Sin entregable';
    final paquete = tarea.paqueteTrabajo ?? 'Sin paquete';

    jerarquia.putIfAbsent(fase, () => {});
    jerarquia[fase]!.putIfAbsent(entregable, () => {});
    jerarquia[fase]![entregable]!.putIfAbsent(paquete, () => []);
    jerarquia[fase]![entregable]![paquete]!.add(tarea);
  }

  // Ordenar fases según orden PMI
  final fasesOrdenadas = _ordenarFasesPMI(jerarquia.keys.toList());

  return ListView(
    padding: const EdgeInsets.all(16),
    children: fasesOrdenadas.map((fase) {
      final colorFase = _obtenerColorFase(fase);
      final entregables = jerarquia[fase]!;
      return _buildFaseCard(fase, entregables, colorFase);
    }).toList(),
  );
}
```

### Componentes Visuales:

#### 1. Card de Fase (ExpansionTile)
```dart
Widget _buildFaseCard(String nombreFase, ...) {
  int totalTareas = 0;
  int tareasCompletadas = 0;

  // Calcular progreso
  final progreso = totalTareas > 0 ? tareasCompletadas / totalTareas : 0.0;

  return Card(
    color: Colors.grey.shade900,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colorFase, width: 2),
    ),
    child: ExpansionTile(
      leading: Container(
        decoration: BoxDecoration(
          color: colorFase.withOpacity(0.2),
          border: Border.all(color: colorFase, width: 2),
        ),
        child: Icon(_obtenerIconoFase(nombreFase), color: colorFase),
      ),
      title: Text(nombreFase, style: TextStyle(color: Colors.white)),
      subtitle: LinearProgressIndicator(
        value: progreso,
        valueColor: AlwaysStoppedAnimation<Color>(colorFase),
      ),
      children: [...entregables],
    ),
  );
}
```

#### 2. Sección de Entregable
```dart
Widget _buildEntregableSection(String nombreEntregable, ...) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorFase.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Row([
          Icon(Icons.inventory_2, color: colorFase),
          Text('📦 $nombreEntregable', style: TextStyle(color: colorFase)),
        ]),
        ...paquetes.map((paquete) => _buildPaqueteTrabajoSection(paquete)),
      ],
    ),
  );
}
```

#### 3. Sección de Paquete de Trabajo
```dart
Widget _buildPaqueteTrabajoSection(String nombrePaquete, List<Tarea> tareas, ...) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade800.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Row([
          Icon(Icons.folder_open, color: Colors.white70),
          Text(nombrePaquete),
          Chip(label: Text('${tareas.length} tareas')),
        ]),
        ...tareas.map((tarea) => _buildTareaItem(tarea, colorFase)),
      ],
    ),
  );
}
```

#### 4. Item de Tarea
```dart
Widget _buildTareaItem(Tarea tarea, Color colorFase) {
  return Container(
    decoration: BoxDecoration(
      color: tarea.completado
        ? Colors.green.shade900.withOpacity(0.3)
        : Colors.grey.shade900,
      border: Border.all(
        color: tarea.completado ? Colors.green : Colors.white.withOpacity(0.2),
      ),
    ),
    child: Row(
      children: [
        Icon(
          tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
          color: tarea.completado ? Colors.green : Colors.white54,
        ),
        Expanded(
          child: Column(
            children: [
              Text(tarea.titulo, style: TextStyle(
                decoration: tarea.completado ? TextDecoration.lineThrough : null,
              )),
              Wrap([
                _buildChip('👥 ${tarea.area}', Colors.blue.shade700),
                _buildChip('🎯 ${tarea.dificultad}', Colors.purple.shade700),
                _buildChip('⏱️ ${tarea.duracion} min', Colors.indigo.shade700),
                if (tarea.prioridad >= 4)
                  _buildChip('🔥 Alta prioridad', Colors.red.shade700),
              ]),
            ],
          ),
        ),
      ],
    ),
  );
}
```

---

## 👥 Vista 2: Recursos

### Estructura Visual:

```
┌─────────────────────────────────────────────────┐
│ 👥 Equipo PM (10 tareas)                       │
│ Progress: ████████████ 80%                      │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 🟢 Iniciación (4 tareas)                    │ │
│ │                                             │ │
│ │ ✅ Redactar objetivos del proyecto          │ │
│ │ ✅ Definir alcance preliminar               │ │
│ │ 🔲 Elaborar Project Charter                 │ │
│ │ 🔲 Identificar stakeholders                 │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 🔵 Planificación (6 tareas)                 │ │
│ │ ...                                         │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 💻 Equipo Desarrollo (15 tareas)               │
│ Progress: ██████░░░░░░ 40%                      │
│ ...                                             │
└─────────────────────────────────────────────────┘
```

### Implementación:

```dart
Widget _buildVistaRecursos() {
  // Agrupar tareas por área (recurso)
  final Map<String, List<Tarea>> tareasPorRecurso = {};

  for (var tarea in widget.tareas) {
    final recurso = tarea.area;
    tareasPorRecurso.putIfAbsent(recurso, () => []);
    tareasPorRecurso[recurso]!.add(tarea);
  }

  return ListView(
    children: recursosOrdenados.map((recurso) {
      final tareas = tareasPorRecurso[recurso]!;
      return _buildRecursoCard(recurso, tareas, colorRecurso);
    }).toList(),
  );
}
```

```dart
Widget _buildRecursoCard(String nombreRecurso, List<Tarea> tareas, ...) {
  // Agrupar tareas por fase dentro del recurso
  final Map<String, List<Tarea>> tareasPorFase = {};
  for (var tarea in tareas) {
    final fase = tarea.fasePMI ?? 'Sin fase';
    tareasPorFase.putIfAbsent(fase, () => []);
    tareasPorFase[fase]!.add(tarea);
  }

  return Card(
    child: ExpansionTile(
      leading: Icon(Icons.group, color: colorRecurso),
      title: Text(nombreRecurso),
      subtitle: LinearProgressIndicator(value: progreso),
      children: fasesOrdenadas.map((fase) {
        final tareasEnFase = tareasPorFase[fase]!;
        return _buildFaseSection(fase, tareasEnFase);
      }).toList(),
    ),
  );
}
```

---

## 🎨 Sistema de Colores

### Colores por Fase PMI:

```dart
Color _obtenerColorFase(String fase) {
  switch (fase) {
    case 'Iniciación':
      return const Color(0xFF4CAF50); // 🟢 Verde
    case 'Planificación':
      return const Color(0xFF2196F3); // 🔵 Azul
    case 'Ejecución':
      return const Color(0xFFFF9800); // 🟠 Naranja
    case 'Monitoreo y Control':
    case 'Monitoreo':
      return const Color(0xFF9C27B0); // 🟣 Púrpura
    case 'Cierre':
      return const Color(0xFF607D8B); // ⚫ Gris azulado
    default:
      return const Color(0xFF757575); // Gris
  }
}
```

### Iconos por Fase:

```dart
IconData _obtenerIconoFase(String fase) {
  switch (fase) {
    case 'Iniciación':
      return Icons.flag;          // 🚩
    case 'Planificación':
      return Icons.edit_calendar; // 📅
    case 'Ejecución':
      return Icons.build;         // 🔧
    case 'Monitoreo y Control':
    case 'Monitoreo':
      return Icons.monitor_heart; // 💓
    case 'Cierre':
      return Icons.check_circle;  // ✅
    default:
      return Icons.work;          // 💼
  }
}
```

### Colores por Recurso:

```dart
Color _obtenerColorRecurso(String recurso) {
  final hash = recurso.hashCode;
  final paleta = [
    Colors.blue.shade600,    // Equipo 1
    Colors.purple.shade600,  // Equipo 2
    Colors.teal.shade600,    // Equipo 3
    Colors.orange.shade600,  // Consultor 1
    Colors.pink.shade600,    // Consultor 2
    Colors.cyan.shade600,    // Equipo 4
    Colors.indigo.shade600,  // Equipo 5
    Colors.lime.shade700,    // Equipo 6
  ];
  return paleta[hash % paleta.length];
}
```

---

## 🔗 Integración con ProyectoDetallePage

### Modificación: [ProyectoDetallePage.dart](lib/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart#L1033-L1055)

```dart
// Importar nueva página
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/grafo_tareas_pmi_page.dart';

// En el AppBar, botón de flujo de tareas:
IconButton(
  icon: const Icon(Icons.account_tree, color: Colors.white, size: 28),
  tooltip: "Visualizar flujo de tareas del proyecto",
  onPressed: () {
    // Detectar si es proyecto PMI
    final esPMI = proyecto.esPMI;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => esPMI
            ? GrafoTareasPMIPage(              // ✅ Vista PMI
                tareas: tareas,
                nombreResponsables: nombreResponsables,
              )
            : GrafoTareasPage(                 // Vista normal
                tareas: tareas,
                nombreResponsables: nombreResponsables,
              ),
      ),
    );
  },
),
```

---

## 📊 Utilidades de Ordenamiento

### Ordenar Fases PMI:

```dart
List<String> _ordenarFasesPMI(List<String> fases) {
  final orden = {
    'Iniciación': 1,
    'Planificación': 2,
    'Ejecución': 3,
    'Monitoreo y Control': 4,
    'Monitoreo': 4,
    'Cierre': 5,
  };

  fases.sort((a, b) {
    final ordenA = orden[a] ?? 999;
    final ordenB = orden[b] ?? 999;
    return ordenA.compareTo(ordenB);
  });

  return fases;
}
```

---

## 🎯 Flujo de Usuario

### Escenario: Usuario con Proyecto PMI

```
1. Usuario abre ProyectoDetallePage
   ↓
2. Sistema detecta que proyecto.esPMI == true
   ↓
3. Usuario hace clic en botón "Flujo de tareas" (account_tree icon)
   ↓
4. Sistema navega a GrafoTareasPMIPage
   ↓
5. Usuario ve dos opciones:
   - 📊 Vista "Fases PMI" (jerarquía)
   - 👥 Vista "Recursos" (equipos)
   ↓
6. En Vista Fases PMI:
   - Ve 5 fases expandibles
   - Cada fase muestra entregables
   - Cada entregable muestra paquetes de trabajo
   - Cada paquete muestra tareas individuales
   - Puede expandir/colapsar niveles
   ↓
7. En Vista Recursos:
   - Ve recursos/equipos agrupados
   - Dentro de cada recurso, tareas agrupadas por fase
   - Puede ver carga de trabajo por equipo
   - Progreso visual por recurso
```

### Escenario: Usuario con Proyecto Normal

```
1. Usuario abre ProyectoDetallePage
   ↓
2. Sistema detecta que proyecto.esPMI == false
   ↓
3. Usuario hace clic en botón "Flujo de tareas"
   ↓
4. Sistema navega a GrafoTareasPage (vista original por áreas)
   ↓
5. Usuario ve grafo tradicional con nodos conectados
```

---

## 📈 Métricas Calculadas

### Por Fase:
```dart
int totalTareas = 0;
int tareasCompletadas = 0;

entregables.forEach((_, paquetes) {
  paquetes.forEach((_, tareas) {
    totalTareas += tareas.length;
    tareasCompletadas += tareas.where((t) => t.completado).length;
  });
});

final progreso = totalTareas > 0 ? tareasCompletadas / totalTareas : 0.0;
```

### Por Recurso:
```dart
final tareasCompletadas = tareas.where((t) => t.completado).length;
final progreso = tareas.isNotEmpty ? tareasCompletadas / tareas.length : 0.0;
```

---

## 🎨 Componente Reutilizable: Chip

```dart
Widget _buildChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.8),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

**Uso:**
```dart
_buildChip('👥 Equipo PM', Colors.blue.shade700)
_buildChip('🎯 alta', Colors.purple.shade700)
_buildChip('⏱️ 180 min', Colors.indigo.shade700)
_buildChip('🔥 Alta prioridad', Colors.red.shade700)
```

---

## ✅ Funcionalidades Implementadas

### Vista Jerarquía PMI:
- [x] Agrupación por Fase → Entregable → Paquete → Tarea
- [x] Cards expandibles por fase
- [x] Indicador de progreso por fase
- [x] Colores distintivos por fase
- [x] Iconos representativos por fase
- [x] Contador de tareas totales y completadas
- [x] Visualización de estado de tareas (completada/pendiente)
- [x] Chips informativos (área, dificultad, duración, prioridad)
- [x] Ordenamiento correcto de fases PMI

### Vista Recursos:
- [x] Agrupación por recurso/equipo
- [x] Cards expandibles por recurso
- [x] Indicador de progreso por recurso
- [x] Colores distintivos por recurso (hash-based)
- [x] Sub-agrupación por fases dentro de cada recurso
- [x] Contador de tareas por recurso
- [x] Visualización de carga de trabajo

### Navegación y UX:
- [x] Toggle entre vistas con SegmentedButton
- [x] Detección automática de proyectos PMI
- [x] Navegación desde ProyectoDetallePage
- [x] Tema oscuro consistente
- [x] Responsive design
- [x] Scroll suave

---

## 🔄 Comparación: Vista Normal vs Vista PMI

| Aspecto | Vista Normal (GrafoTareasPage) | Vista PMI (GrafoTareasPMIPage) |
|---------|-------------------------------|-------------------------------|
| **Agrupación** | Por área solamente | Por Fase → Entregable → Paquete |
| **Visualización** | Grafo con nodos conectados | Lista jerárquica expandible |
| **Niveles de jerarquía** | 1 nivel (área) | 4 niveles (Fase/Entregable/Paquete/Tarea) |
| **Toggle de vistas** | No | Sí (Jerarquía/Recursos) |
| **Progreso por grupo** | No | Sí (por fase y por recurso) |
| **Colores** | Por área | Por fase PMI |
| **Iconos** | No | Sí (por fase) |
| **Uso** | Proyectos tradicionales | Proyectos PMI |

---

## 🚀 Ejemplo de Datos Renderizados

### Proyecto PMI: "Sistema de Gestión ERP"

**Entrada (Firestore):**
```json
{
  "esPMI": true,
  "tareas": [
    {
      "titulo": "Redactar objetivos del proyecto",
      "fasePMI": "Iniciación",
      "entregable": "Project Charter",
      "paqueteTrabajo": "Documentación Inicial",
      "area": "Equipo PM",
      "duracion": 180,
      "prioridad": 5,
      "dificultad": "alta",
      "completado": true
    },
    {
      "titulo": "Definir alcance preliminar",
      "fasePMI": "Iniciación",
      "entregable": "Project Charter",
      "paqueteTrabajo": "Documentación Inicial",
      "area": "Equipo PM",
      "duracion": 120,
      "prioridad": 5,
      "dificultad": "alta",
      "completado": false
    },
    // ... más tareas
  ]
}
```

**Salida Renderizada:**

```
Vista: Fases PMI
================

🟢 Iniciación (12 tareas)
Progress: ████████░░░░░░ 66%

  📦 Project Charter
    📋 Documentación Inicial (3 tareas)
      ✅ Redactar objetivos del proyecto
         👥 Equipo PM | 🎯 alta | ⏱️ 180 min | 🔥 Alta prioridad

      🔲 Definir alcance preliminar
         👥 Equipo PM | 🎯 alta | ⏱️ 120 min | 🔥 Alta prioridad

      🔲 Establecer restricciones del proyecto
         👥 Equipo PM | 🎯 media | ⏱️ 90 min

    📋 Aprobaciones (2 tareas)
      🔲 Obtener firma del sponsor
      🔲 Presentación a stakeholders

  📦 Registro de Stakeholders
    📋 Identificación de Partes Interesadas (4 tareas)
      ...

──────────────────────────────────────

Vista: Recursos
===============

👥 Equipo PM (10 tareas)
Progress: ████████████ 80%

  🟢 Iniciación (4 tareas)
    ✅ Redactar objetivos del proyecto
    🔲 Definir alcance preliminar
    🔲 Establecer restricciones
    🔲 Listar stakeholders

  🔵 Planificación (6 tareas)
    🔲 Crear WBS
    🔲 Definir cronograma
    ...

──────────────────────────────────────

💻 Equipo Desarrollo (15 tareas)
Progress: ██████░░░░░░ 40%

  🟠 Ejecución (12 tareas)
    ✅ Configurar entorno
    ✅ Desarrollar módulo auth
    🔲 Desarrollar módulo reportes
    ...
```

---

## 📝 Notas Técnicas

### Rendimiento:
- Las agrupaciones se calculan una sola vez en el `build()`
- Los `ExpansionTile` se renderizan solo cuando se expanden
- El toggle de vistas solo reconstruye el widget correspondiente

### Compatibilidad:
- Funciona con proyectos que tienen campos PMI (`fasePMI`, `entregable`, `paqueteTrabajo`)
- Maneja correctamente tareas sin campos PMI (muestra "Sin fase", "Sin entregable")
- Totalmente compatible con proyectos no-PMI

### Accesibilidad:
- Tooltips en botones
- Colores con buen contraste
- Iconos descriptivos
- Texto legible en tema oscuro

---

## ✅ Checklist de Completitud

### Visualización PMI:
- [x] Vista de Jerarquía PMI completa
- [x] Vista de Recursos completa
- [x] Toggle entre vistas
- [x] Agrupación de 4 niveles
- [x] Indicadores de progreso
- [x] Sistema de colores consistente
- [x] Iconos representativos
- [x] Ordenamiento correcto de fases

### Integración:
- [x] Importado en ProyectoDetallePage
- [x] Detección automática de proyectos PMI
- [x] Navegación condicional
- [x] Manejo de proyectos no-PMI

### UX/UI:
- [x] Tema oscuro consistente
- [x] Diseño responsive
- [x] Cards expandibles
- [x] Chips informativos
- [x] Progreso visual
- [x] Estados de tareas (completada/pendiente)

---

## 🎯 Resultados

### Antes:
- ❌ Proyectos PMI se veían como proyectos normales
- ❌ No se mostraba la jerarquía PMI
- ❌ Flujo de tareas solo por áreas

### Ahora:
- ✅ Proyectos PMI tienen visualización especializada
- ✅ Jerarquía de 4 niveles visible
- ✅ Dos vistas complementarias (Jerarquía + Recursos)
- ✅ Progreso por fase y por recurso
- ✅ Detección automática del tipo de proyecto

---

**Autor:** Claude (Anthropic)
**Fecha:** 2025-11-16
**Versión:** 3.0.0 (Visualización PMI Completa)
