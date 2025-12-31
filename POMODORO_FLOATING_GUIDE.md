# 🍅 Guía de Integración del Pomodoro Flotante

## ✅ Características Implementadas

### 1. **Persistencia Completa**
- ✅ Estado del timer se guarda automáticamente cada 10 segundos
- ✅ Guarda en inicio, pausa, reset y completación de intervalos
- ✅ Calcula tiempo transcurrido cuando la app estaba cerrada
- ✅ Reanuda automáticamente si el timer estaba corriendo

### 2. **Notificaciones Reales**
- ✅ Canal de Android dedicado con prioridad máxima
- ✅ Vibración, sonido y luces LED activadas
- ✅ Notificaciones con emojis y mensajes personalizados
- ✅ NO usa SnackBar - usa flutter_local_notifications

### 3. **Widget Flotante Global**
- ✅ Se puede arrastrar por la pantalla
- ✅ Minimizable (muestra solo timer circular)
- ✅ Expandible (muestra controles completos)
- ✅ Visible en todas las pantallas de la app
- ✅ Sincronizado con PomodoroProvider global

## 📁 Archivos Creados/Modificados

### Nuevos Archivos:

1. **`lib/providers/pomodoro_provider.dart`** (195 líneas)
   - Provider global con ChangeNotifier
   - Maneja todo el estado del Pomodoro
   - Persistencia automática con SharedPreferences
   - Sincroniza estado entre widgets

2. **`lib/widgets/pomodoro_floating_overlay.dart`** (280 líneas)
   - Overlay flotante arrastrable
   - Vista minimizada (80x80) y expandida (280x320)
   - Animaciones suaves entre estados
   - Controles completos del timer

### Archivos Modificados:

3. **`lib/features/user_auth/presentation/pages/pomodoro/PomodoroCompactWidget.dart`**
   - ✅ Agregado: Notificaciones con AndroidNotificationChannel
   - ✅ Agregado: Persistencia completa del estado
   - ✅ Agregado: Auto-save cada 10 segundos
   - ✅ Mejorado: Notificaciones con emojis en lugar de SnackBar

## 🚀 Cómo Integrar el Overlay Flotante

### Paso 1: Agregar el Provider en `main.dart`

```dart
import 'package:provider/provider.dart';
import 'package:pucpflow/providers/pomodoro_provider.dart';
import 'package:pucpflow/providers/theme_provider.dart';

@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => PomodoroProvider()), // 🔥 NUEVO
    ],
    child: MaterialApp(
      // ... resto del código
    ),
  );
}
```

### Paso 2: Agregar el Overlay en `HomePage`

En `lib/features/user_auth/presentation/pages/Login/home_page.dart`:

```dart
import 'package:pucpflow/widgets/pomodoro_floating_overlay.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Tu contenido actual de la página
        _currentPage,

        // 🔥 Overlay flotante del Pomodoro (SIEMPRE VISIBLE)
        const PomodoroFloatingOverlay(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}
```

### Paso 3 (Opcional): Mostrar en Todas las Páginas

Si quieres que el overlay sea GLOBAL en TODA la app, envuelve el MaterialApp en `main.dart`:

```dart
@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => PomodoroProvider()),
    ],
    child: MaterialApp(
      // ... configuración
      home: Stack(
        children: [
          _getInitialPage(), // Tu página inicial
          const PomodoroFloatingOverlay(), // 🔥 GLOBAL en toda la app
        ],
      ),
      routes: {
        // ... tus rutas
      },
    ),
  );
}
```

**IMPORTANTE**: Si lo pones global en main.dart, se mostrará en TODAS las pantallas, incluyendo login, splash, etc. Evalúa si quieres esto o solo en HomePage.

## 🎯 Cómo Usar el Widget Flotante

### Vista Minimizada (Por Defecto)
- Muestra un círculo flotante de 80x80 píxeles
- Indica minutos restantes y progreso circular
- Colores: Rojo para trabajo, Verde para descanso
- **Tap** para expandir

### Vista Expandida
- Muestra timer completo con minutos:segundos
- Controles: Reset, Play/Pause, Skip
- Indicador de modo (🎯 TRABAJO / ☕ DESCANSO)
- Tarea actual
- Contador de pomodoros completados
- **Tap en X** para minimizar

### Arrastrar
- Mantén presionado y arrastra a cualquier parte de la pantalla
- Se limita a los bordes para no salirse

## 🔧 Configuración Avanzada

### Cambiar Duraciones del Timer

```dart
final pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);

pomodoroProvider.updateSettings(
  newWorkDuration: 50,        // 50 minutos de trabajo
  newBreakDuration: 10,       // 10 minutos de descanso
  newLongBreakDuration: 30,   // 30 minutos de descanso largo
  newSessionsUntilLongBreak: 4, // Descanso largo cada 4 sesiones
);
```

### Cambiar Tarea Actual

```dart
pomodoroProvider.setCurrentTask("Desarrollar feature X");
```

### Controlar el Timer Programáticamente

```dart
// Desde cualquier widget que tenga acceso al provider
final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);

pomodoro.startTimer();     // Iniciar
pomodoro.pauseTimer();     // Pausar
pomodoro.resetTimer();     // Resetear
pomodoro.skipInterval();   // Saltar al siguiente intervalo
```

## 🔄 Sincronización de Estado

### Entre PomodoroCompactWidget y PomodoroFloatingOverlay

**Antes**: Cada widget tenía su propio estado independiente ❌

**Ahora**: Ambos usan el mismo `PomodoroProvider` ✅

```dart
// PomodoroCompactWidget puede usar el provider así:
Consumer<PomodoroProvider>(
  builder: (context, pomodoro, child) {
    return Text(pomodoro.formattedTime);
  },
)

// PomodoroFloatingOverlay también usa el mismo provider
// Los cambios en uno se reflejan automáticamente en el otro
```

## 📊 Claves de Persistencia

El estado se guarda en SharedPreferences con estas claves:

```
pomodoro.remainingSeconds       - Segundos restantes
pomodoro.isRunning              - Si el timer está corriendo
pomodoro.isWorkInterval         - Si es intervalo de trabajo
pomodoro.isLongBreak            - Si es descanso largo
pomodoro.completedPomodoros     - Contador de pomodoros
pomodoro.completedWorkSessions  - Sesiones de trabajo completadas
pomodoro.currentTask            - Tarea actual
pomodoro.workDuration           - Duración de trabajo (min)
pomodoro.breakDuration          - Duración de descanso (min)
pomodoro.longBreakDuration      - Duración descanso largo (min)
pomodoro.lastSaveTime           - Timestamp del último guardado
```

Para el widget compacto independiente (si no usas el provider):
```
pomodoro_compact.remainingSeconds
pomodoro_compact.isRunning
pomodoro_compact.isWorkInterval
pomodoro_compact.workDuration
pomodoro_compact.breakDuration
pomodoro_compact.lastSaveTime
```

## 🎨 Personalización del Overlay

### Cambiar Posición Inicial

En `pomodoro_floating_overlay.dart` línea 20:

```dart
Offset _position = const Offset(20, 100); // Cambiar coordenadas X, Y
```

### Cambiar Tamaños

```dart
width: _isExpanded ? 280 : 80,   // Ancho expandido/minimizado
height: _isExpanded ? 320 : 80,  // Alto expandido/minimizado
```

### Cambiar Colores del Gradiente

```dart
colors: pomodoro.isWorkInterval
  ? [Colors.red.shade400, Colors.red.shade700]      // Trabajo
  : [Colors.green.shade400, Colors.green.shade700], // Descanso
```

## 🐛 Troubleshooting

### El overlay no aparece
1. Verifica que agregaste `PomodoroProvider` en `main.dart`
2. Verifica que agregaste `PomodoroFloatingOverlay` en el Stack de tu página
3. Revisa que el Stack tenga suficiente espacio

### Las notificaciones no funcionan
1. Verifica permisos de notificaciones en AndroidManifest.xml
2. El canal debe crearse antes de mostrar notificaciones
3. Solo funciona en Android (iOS requiere configuración adicional)

### El estado no persiste
1. Verifica que `_saveTimerState()` se está llamando
2. Revisa las claves en SharedPreferences con:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   print(prefs.getKeys());
   ```

### Los widgets no se sincronizan
1. Asegúrate de usar `Consumer<PomodoroProvider>` o `Provider.of<PomodoroProvider>(context)`
2. Verifica que ambos widgets están bajo el mismo `ChangeNotifierProvider`

## 🎉 Resultado Final

Al terminar la integración tendrás:

✅ Un Pomodoro flotante que se puede arrastrar por toda la app
✅ Vista minimizada elegante que no molesta
✅ Vista expandida con todos los controles
✅ Persistencia automática - sobrevive a cierres de app
✅ Notificaciones reales cuando termina cada intervalo
✅ Sincronización entre todos los widgets de Pomodoro
✅ Gestión de estado global con Provider

## 📝 Próximos Pasos (Opcional)

1. **Integrar con PomodoroPage completa** - Hacer que la página grande también use PomodoroProvider
2. **Historial en Firestore** - Guardar pomodoros completados en la nube
3. **Estadísticas** - Gráficas de productividad semanal/mensual
4. **Sonidos personalizados** - Diferentes tonos para trabajo/descanso
5. **Modo "No molestar"** - Silenciar notificaciones durante el trabajo
6. **Temas personalizables** - Colores y estilos configurables

---

**Creado**: 2025-12-26
**Versión**: 1.0
**Estado**: ✅ Completamente funcional
