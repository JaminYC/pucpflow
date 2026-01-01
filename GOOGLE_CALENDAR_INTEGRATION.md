# 📅 Integración con Google Calendar - Guía Completa

## 🎯 Resumen de Funcionalidades

El sistema ahora cuenta con una integración completa y automática con Google Calendar que incluye:

1. ✅ **Sincronización Automática**: Las tareas se sincronizan automáticamente con Google Calendar al crearlas
2. ✅ **Redistribución Inteligente**: El sistema busca espacios libres en tu calendario para programar tareas
3. ✅ **Monitoreo Continuo**: Las tareas vencidas se redistribuyen automáticamente
4. ✅ **Gestión de Eventos**: Actualización y eliminación automática de eventos del calendario

---

## 🏗️ Arquitectura de la Integración

### Componentes Principales

#### 1. **GoogleCalendarService** (`google_calendar_service.dart`)
Servicio central para la comunicación con Google Calendar API.

**Métodos principales:**
- `signInAndGetCalendarApi()` - Conecta con Google Calendar
- `agendarEventoEnCalendario()` - Crea evento en el calendario (retorna eventId)
- `actualizarEventoEnCalendario()` - Actualiza evento existente
- `eliminarEventoDeCalendario()` - Elimina evento del calendario
- `encontrarHorarioDisponible()` - Encuentra slots libres
- `getBusyTimes()` - Obtiene periodos ocupados
- `verificarDisponibilidadHorario()` - Verifica si un horario está libre

#### 2. **TareaService** (`tarea_service.dart`)
Gestión de tareas con sincronización automática.

**Métodos actualizados:**
- `agregarTareaAProyecto()` - Ahora sincroniza automáticamente con Google Calendar
- `actualizarTareaEnProyecto()` - Actualiza evento en Google Calendar
- `eliminarTareaDeProyecto()` - Elimina evento de Google Calendar

**Parámetro opcional:** `syncToCalendar` (default: `true`)

#### 3. **RedistribucionTareasService** (`redistribucion_tareas_service.dart`)
Redistribución inteligente usando Google Calendar.

**Características:**
- Busca slots libres en el calendario del usuario
- Respeta horarios laborales (9 AM - 5 PM)
- Evita fines de semana
- Prioriza tareas por importancia (prioridad + dificultad)
- Búsqueda en intervalos de 30 minutos

**Métodos principales:**
- `redistribuirTareas()` - Ahora acepta `calendarApi` y `responsableUid` opcionales
- `_distribuirFechasConCalendar()` - Distribución usando Google Calendar
- `_encontrarSiguienteSlotLibre()` - Búsqueda inteligente de slots

#### 4. **AutoRedistribucionService** (`auto_redistribucion_service.dart`)
Monitoreo y redistribución automática de tareas vencidas.

**Métodos:**
- `verificarYRedistribuirTareasPendientes()` - Redistribuye tareas vencidas
- `redistribuirTodasLasTareasPendientes()` - Redistribución manual completa
- `obtenerEstadisticasTareasVencidas()` - Estadísticas de tareas vencidas

---

## 🔧 Modelo de Datos Actualizado

### Tarea Model - Nuevos Campos

```dart
class Tarea {
  // Campos de fechas mejorados
  DateTime? fechaLimite;              // Deadline - cuándo DEBE completarse
  DateTime? fechaProgramada;          // Hora programada - cuándo se HARÁ
  DateTime? fechaCompletada;          // Timestamp exacto de completado

  // Google Calendar Integration
  String? googleCalendarEventId;      // ID del evento en Google Calendar

  // ... otros campos existentes
}
```

**Diferencia entre campos de fecha:**
- `fechaLimite`: Es el **deadline** - fecha límite para completar la tarea
- `fechaProgramada`: Es la **fecha/hora programada** - cuándo el usuario planea hacer la tarea
- `fechaCompletada`: Timestamp exacto de cuándo se marcó como completada
- `fecha` (deprecado): Se mantiene por compatibilidad

---

## 📖 Cómo Usar la Integración

### 1. Crear una Tarea con Sincronización Automática

```dart
final tareaService = TareaService();

// Crear tarea con fecha programada
final nuevaTarea = Tarea(
  titulo: "Preparar presentación",
  duracion: 90, // 90 minutos
  fechaProgramada: DateTime(2024, 1, 15, 14, 0), // 15 enero, 2:00 PM
  fechaLimite: DateTime(2024, 1, 20), // Deadline: 20 enero
  prioridad: 3,
  colorId: 1,
  responsables: [userId],
  tipoTarea: "Documento",
);

// ✅ Se sincroniza automáticamente con Google Calendar
await tareaService.agregarTareaAProyecto(
  proyectoId,
  nuevaTarea,
  syncToCalendar: true, // Por defecto es true
);
```

### 2. Actualizar una Tarea

```dart
// Modificar la tarea
tareaEditada.fechaProgramada = DateTime(2024, 1, 16, 10, 0);

// ✅ El evento en Google Calendar se actualiza automáticamente
await tareaService.actualizarTareaEnProyecto(
  proyectoId,
  tareaOriginal,
  tareaEditada,
  syncToCalendar: true,
);
```

### 3. Eliminar una Tarea

```dart
// ✅ El evento se elimina automáticamente de Google Calendar
await tareaService.eliminarTareaDeProyecto(
  proyectoId,
  tarea,
  syncToCalendar: true,
);
```

### 4. Redistribuir Tareas Pendientes con Google Calendar

```dart
final redistribucionService = RedistribucionTareasService();
final calendarService = GoogleCalendarService();

// Obtener API de Google Calendar
final calendarApi = await calendarService.signInAndGetCalendarApi();

// Redistribuir usando slots libres del calendario
final resultado = await redistribucionService.redistribuirTareas(
  proyecto: proyecto,
  tareas: tareas,
  fechaInicioPersonalizada: DateTime.now(),
  fechaFinPersonalizada: proyecto.fechaFin,
  calendarApi: calendarApi, // ✅ Usa Google Calendar para encontrar slots
  responsableUid: userId,
);

print("Tareas redistribuidas: ${resultado.tareasRedistribuidas}");
print("Estadísticas: ${resultado.estadisticas}");
```

### 5. Monitorear y Redistribuir Tareas Vencidas Automáticamente

```dart
final autoRedistribucionService = AutoRedistribucionService();

// Verificar y redistribuir tareas vencidas
final resultado = await autoRedistribucionService.verificarYRedistribuirTareasPendientes(
  proyectoId: proyectoId,
  userId: userId,
);

if (resultado['success']) {
  print("Tareas redistribuidas: ${resultado['tareasRedistribuidas']}");
  print("Estadísticas: ${resultado['estadisticas']}");
}
```

### 6. Obtener Estadísticas de Tareas Vencidas

```dart
final estadisticas = await autoRedistribucionService.obtenerEstadisticasTareasVencidas(userId);

print("Total tareas vencidas: ${estadisticas['totalTareasVencidas']}");
print("Total tareas pendientes: ${estadisticas['totalTareasPendientes']}");
print("Porcentaje vencidas: ${estadisticas['porcentajeVencidas']}%");
```

---

## 🔄 Flujo de Sincronización

### Cuando se Crea una Tarea:

```
Usuario crea tarea
    ↓
TareaService.agregarTareaAProyecto()
    ↓
¿Tiene fechaProgramada o fechaLimite? → Sí
    ↓
GoogleCalendarService.signInAndGetCalendarApi()
    ↓
GoogleCalendarService.agendarEventoEnCalendario()
    ↓
Se guarda googleCalendarEventId en la tarea
    ↓
Se guarda la tarea en Firestore
```

### Cuando se Redistribuyen Tareas:

```
Usuario solicita redistribución
    ↓
AutoRedistribucionService.redistribuirTodasLasTareasPendientes()
    ↓
GoogleCalendarService.getBusyTimes() → Obtiene periodos ocupados
    ↓
RedistribucionTareasService._distribuirFechasConCalendar()
    ↓
Para cada tarea:
    ├─ _encontrarSiguienteSlotLibre() → Busca slot libre cada 30 min
    ├─ verificarDisponibilidadHorario() → Verifica que esté libre
    └─ Asigna fechaProgramada
    ↓
Se actualizan las tareas en Firestore
    ↓
Se sincronizan los eventos en Google Calendar
```

---

## ⚙️ Configuración de Horarios

### Configuración por Defecto:

- **Horario laboral:** 9:00 AM - 5:00 PM
- **Días laborales:** Lunes a Viernes
- **Intervalo de búsqueda:** 30 minutos
- **Días de búsqueda:** 14 días hacia adelante
- **Buffer entre tareas:** 15 minutos

### Personalizar Horarios:

Para cambiar los horarios, editar en `redistribucion_tareas_service.dart`:

```dart
// En _encontrarSiguienteSlotLibre()
const horaInicio = 9;  // 9 AM
const horaFin = 17;    // 5 PM

// En _distribuirFechasConCalendar()
fechaActual = slotEncontrado.add(Duration(minutes: tarea.duracion + 15)); // Buffer de 15 min
```

---

## 🎨 Integración con la UI

### Ejemplo: Botón de Redistribución en ProyectoDetallePage

```dart
// Agregar botón en la UI del proyecto
ElevatedButton.icon(
  icon: Icon(Icons.refresh),
  label: Text("Redistribuir Tareas Pendientes"),
  onPressed: () async {
    final autoService = AutoRedistribucionService();

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // Redistribuir
    final resultado = await autoService.redistribuirTodasLasTareasPendientes(
      proyectoId: widget.proyectoId,
      userId: FirebaseAuth.instance.currentUser!.uid,
    );

    // Cerrar diálogo
    Navigator.pop(context);

    // Mostrar resultado
    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ ${resultado['tareasRedistribuidas']} tareas redistribuidas"
          ),
        ),
      );

      // Recargar tareas
      setState(() {
        _cargarTareas();
      });
    }
  },
)
```

---

## 🔐 Seguridad y Permisos

### Scopes de Google Calendar Requeridos:

```dart
GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar',
  ],
)
```

### Eventos Privados:

Los eventos se crean como **privados** y **sin invitaciones**:

```dart
visibility: "private",      // Solo visible para el usuario
guestsCanModify: false,     // No se puede editar
guestsCanInviteOthers: false, // No se pueden enviar invitaciones
sendUpdates: "none",        // No enviar notificaciones por email
```

---

## 📊 Estadísticas y Monitoreo

### Campos de Estadísticas en ResultadoRedistribucion:

```dart
{
  'duracionTotalHoras': '15.5',
  'promedioTareasPorDia': '2.3',
  'diasDisponibles': 30,
  'distribucionPorDificultad': {
    'alta': 5,
    'media': 10,
    'baja': 3,
  },
  'cargaPorResponsable': {
    'userId1': 480, // minutos
    'userId2': 360,
  },
}
```

---

## 🐛 Manejo de Errores

### Errores Comunes:

1. **No se puede conectar a Google Calendar** → Continúa sin sincronización
2. **No hay slots disponibles** → Usa método tradicional de asignación
3. **Evento no encontrado** → Crea nuevo evento
4. **Sin permisos** → Solicita login interactivo

### Logging:

Todos los errores se registran en consola con prefijos:
- `✅` Operación exitosa
- `⚠️` Advertencia (continúa sin sincronización)
- `❌` Error crítico

---

## 🚀 Próximos Pasos Recomendados

1. **Agregar UI para redistribución manual** en ProyectoDetallePage
2. **Dashboard de tareas vencidas** en DashboardPage
3. **Notificaciones push** cuando hay tareas vencidas
4. **Background job** para redistribución automática diaria
5. **Configuración de horarios personalizados** por usuario

---

## 📝 Notas Técnicas

### Migración de Datos:

El modelo Tarea incluye migración automática:
- Si una tarea tiene `fecha` pero no `fechaLimite`, se migra automáticamente
- `googleCalendarEventId` es opcional (null-safe)

### Compatibilidad:

- ✅ Compatible con tareas existentes (sin Google Calendar)
- ✅ Funciona offline (sin sincronización)
- ✅ Retrocompatible con campo `fecha` legacy

### Performance:

- Búsqueda de slots: O(n × m) donde n=días, m=slots por día
- Máximo 14 días × 16 horas × 2 slots/hora = ~448 verificaciones por tarea
- Optimización: Se detiene al encontrar el primer slot libre

---

## 📞 Soporte

Para preguntas o problemas con la integración, revisar:
1. Logs en consola (buscar emojis ✅⚠️❌)
2. Verificar permisos de Google Calendar
3. Confirmar que el usuario está autenticado con Google

---

**Última actualización:** Enero 2025
**Versión:** 1.0.0
