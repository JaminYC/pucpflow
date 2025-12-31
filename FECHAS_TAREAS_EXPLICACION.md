# 📅 Explicación: Fechas en Tareas

**Fecha:** 2025-12-31
**Actualización:** Sistema de fechas mejorado

---

## 🎯 Problema Anterior

Antes solo existía **UN campo de fecha** (`fecha`) que se usaba de forma ambigua:
- A veces como **deadline** (fecha límite)
- A veces como **fecha programada** (cuándo hacer la tarea)
- Esto causaba confusión en el Briefing Diario

---

## ✅ Solución Implementada

Ahora existen **TRES campos de fecha** en el modelo `Tarea`:

### 1. **`fecha`** (DEPRECADO - Solo compatibilidad)
```dart
DateTime? fecha; // ⚠️ Se mantiene por compatibilidad con tareas existentes
```
- **NO USAR en código nuevo**
- Se mantiene solo para no romper tareas antiguas
- Al leer desde Firestore, se migra automáticamente a `fechaLimite`

### 2. **`fechaLimite`** (DEADLINE) ⏰
```dart
DateTime? fechaLimite; // Cuándo DEBE estar completa la tarea
```

**Uso:** Fecha límite de entrega
- **Ejemplo:** "Entregar informe el 15 de Enero 2025"
- **En el briefing:** Muestra alertas como "Deadline en 5h" o "⚠️ Deadline vencido"

### 3. **`fechaProgramada`** (HORA PROGRAMADA) 📍
```dart
DateTime? fechaProgramada; // Cuándo se HARÁ la tarea
```

**Uso:** Hora/fecha específica para realizar la tarea
- **Ejemplo:** "Reunión con cliente a las 09:00 AM"
- **En el briefing:** Ordena las tareas por hora y muestra "Inicio en 30 min"

---

## 🔄 Migración Automática

**Para tareas existentes:**
```dart
// Tarea antigua en Firestore:
{
  "fecha": "2025-12-31T14:00:00"
}

// Al leer, se migra automáticamente a:
{
  "fecha": "2025-12-31T14:00:00",        // Mantiene compatibilidad
  "fechaLimite": "2025-12-31T14:00:00",  // ✅ Asume que era deadline
  "fechaProgramada": null                 // No asigna nada
}
```

**No se pierde ninguna información** y todo sigue funcionando.

---

## 📝 Ejemplos de Uso

### Caso 1: Tarea con solo deadline
```dart
Tarea(
  titulo: "Completar diseño de mockups",
  fechaLimite: DateTime(2025, 1, 15), // Debe estar listo para el 15
  fechaProgramada: null,               // No tiene hora específica
  duracion: 240,                       // 4 horas de trabajo
)
```

**En el briefing:**
- Si es hoy, aparece en la lista
- Muestra "Deadline en X horas" si falta menos de 24h
- Se ordena por prioridad (no por hora)

### Caso 2: Tarea con hora programada
```dart
Tarea(
  titulo: "Reunión de sprint planning",
  fechaProgramada: DateTime(2025, 12, 31, 9, 0), // 9:00 AM
  fechaLimite: null,                               // No tiene deadline
  duracion: 90,                                    // 90 minutos
)
```

**En el briefing:**
- Aparece con `[09:00]` destacado
- Se ordena por hora (primero las más cercanas)
- Muestra "Inicio en 30 min" si está cerca

### Caso 3: Tarea con ambos
```dart
Tarea(
  titulo: "Presentar prototipo al cliente",
  fechaProgramada: DateTime(2025, 12, 31, 15, 0), // 3:00 PM - reunión
  fechaLimite: DateTime(2025, 12, 31, 17, 0),     // 5:00 PM - entrega
  duracion: 60,
)
```

**En el briefing:**
- Muestra `[15:00]` como hora de inicio
- Muestra "Deadline en 2h" como insight adicional
- **Muy crítica** si ambas fechas están cerca

---

## 🎨 Cómo se Muestran en el Briefing

### Priorización de Fechas:
```
1. fechaProgramada (si existe) → Para ordenar y mostrar hora
2. fechaLimite (si existe)     → Para deadline warnings
3. fecha (legacy)              → Fallback para compatibilidad
```

### Motivos de Prioridad que Genera:

**Con `fechaProgramada`:**
- ✅ "Inicio en 30 min" (si falta menos de 2 horas)
- ✅ "¡Debe iniciar ahora!" (si ya pasó la hora pero hace menos de 1h)

**Con `fechaLimite`:**
- ⚠️ "Deadline en 5h" (si falta menos de 24 horas)
- 🔴 "⚠️ Deadline vencido" (si ya pasó)

**Ambos:**
- "Inicio en 30 min • Deadline en 3h" (combinados)

---

## 🛠️ Para Desarrolladores

### Al crear una nueva tarea:

```dart
// Tarea sin hora específica
final tarea = Tarea(
  titulo: "Revisar código",
  fechaLimite: DateTime.now().add(Duration(days: 2)), // En 2 días
  duracion: 120,
  // ... otros campos
);

// Tarea con hora específica
final reunion = Tarea(
  titulo: "Daily standup",
  fechaProgramada: DateTime(2025, 12, 31, 10, 0), // 10:00 AM
  duracion: 15,
  // ... otros campos
);
```

### Al actualizar TareaFormWidget:

**Pendiente de actualizar:**
- Cambiar `fechaLimite` en el form para que guarde en `tarea.fechaLimite`
- Agregar nuevo selector para `fechaProgramada` (opcional)
- Esto será parte de una actualización futura

---

## 📊 Ventajas de Este Cambio

### 1. **Claridad Conceptual**
- ✅ Ya no hay ambigüedad sobre qué significa cada fecha
- ✅ El briefing puede dar insights más inteligentes

### 2. **Mejor Ordenamiento**
```
Antes:
- Tarea A: fecha = 15:00 (¿deadline o hora?)
- Tarea B: fecha = 09:00 (¿deadline o hora?)
- ¿Cuál va primero? 🤔

Ahora:
- Tarea A: fechaProgramada = 09:00 → Va primero (es hora de inicio)
- Tarea B: fechaLimite = 15:00 → Va después (es deadline)
- ¡Orden claro! ✅
```

### 3. **Insights Más Precisos**
```
Antes:
"Tarea a las 15:00" - ¿Qué significa?

Ahora:
"[15:00] Reunión con cliente" - Hora de inicio
"Entregar reporte (Deadline en 3h)" - Fecha límite
```

### 4. **Compatibilidad Total**
- ✅ Tareas antiguas siguen funcionando
- ✅ Migración automática sin pérdida de datos
- ✅ No requiere actualizar Firestore manualmente

---

## 🔄 Lógica de Migración

En `tarea_model.dart` - `fromJson()`:

```dart
// 1. Leer fecha antigua (si existe)
DateTime? fechaMigrada = json['fecha'] != null
    ? DateTime.parse(json['fecha'])
    : null;

// 2. Leer nuevos campos
DateTime? fechaLimiteMigrada = json['fechaLimite'] != null
    ? DateTime.parse(json['fechaLimite'])
    : null;

DateTime? fechaProgramadaMigrada = json['fechaProgramada'] != null
    ? DateTime.parse(json['fechaProgramada'])
    : null;

// 3. Si no hay fechaLimite pero sí fecha → migrar
if (fechaLimiteMigrada == null && fechaMigrada != null) {
  fechaLimiteMigrada = fechaMigrada; // ✅ Asumimos que era deadline
}

// 4. Crear tarea con todos los campos
return Tarea(
  fecha: fechaMigrada,                     // Mantener legacy
  fechaLimite: fechaLimiteMigrada,        // Nuevo campo
  fechaProgramada: fechaProgramadaMigrada, // Nuevo campo
  // ...
);
```

---

## 📱 Impacto en el UI

### TareaFormWidget (Actual)
```
📅 Fecha Límite / Deadline
[31/12/2025]  [📅]
```
- Actualmente guarda en `tarea.fecha`
- **Próxima actualización:** Guardará en `tarea.fechaLimite`

### TareaFormWidget (Futuro)
```
📅 Fecha Límite (Deadline)
[31/12/2025]  [📅]

🕐 Hora Programada (Opcional)
[No establecida]  [🕐]
```
- Dos selectores separados
- Ambos opcionales
- Mejor UX y claridad

---

## ✅ Checklist de Implementación

### Completado ✅
- [x] Agregar campos `fechaLimite` y `fechaProgramada` al modelo
- [x] Migración automática en `fromJson()`
- [x] Actualizar `toJson()` para guardar ambos campos
- [x] Actualizar `briefing_service.dart` para usar nueva lógica
- [x] Actualizar `briefing_models.dart` (TareaBriefing)
- [x] Priorización correcta en `_esTareaDelDia()`
- [x] Motivos de prioridad mejorados con ambas fechas

### Pendiente (Opcional - Fase 2+)
- [ ] Actualizar `TareaFormWidget` para usar `fechaLimite`
- [ ] Agregar selector de `fechaProgramada` en el form
- [ ] Actualizar vistas de calendario para diferenciar
- [ ] Agregar filtros por tipo de fecha en listas

---

## 🎯 Conclusión

Este cambio hace que el sistema de fechas sea:
- ✅ **Más claro**: Cada fecha tiene un propósito específico
- ✅ **Más inteligente**: El briefing puede dar mejores insights
- ✅ **Más flexible**: Puedes tener ambas o solo una
- ✅ **100% compatible**: No rompe nada existente

**El Briefing Diario ahora puede:**
1. Ordenar tareas por hora programada
2. Alertar sobre deadlines cercanos
3. Identificar conflictos de horario correctamente
4. Mostrar "¿cuándo hacer?" vs "¿cuándo entregar?"

---

**Actualizado por:** Claude Code
**Fecha:** 2025-12-31
