# Sistema de Overlays Persistentes

## Resumen
Se ha implementado exitosamente un **sistema de overlays globales** que permite mostrar widgets flotantes (Pomodoro y ADAN) que **persisten en todas las pantallas** sin perderse al navegar.

---

## ✅ Características Implementadas

### 1. GlobalOverlayService (Singleton)
**Archivo**: [lib/services/global_overlay_service.dart](lib/services/global_overlay_service.dart)

Servicio centralizado que gestiona todos los overlays globales de la aplicación:

- ✅ Patrón Singleton (similar a NotificationService y WakeWordService)
- ✅ Gestión de FAB de ADAN persistente
- ✅ Gestión de Pomodoro flotante y arrastrable
- ✅ Estado reactivo con show/hide

**Métodos principales:**
```dart
// FAB de ADAN
GlobalOverlayService().showAdanFab(context);
GlobalOverlayService().hideAdanFab();

// Pomodoro
GlobalOverlayService().showPomodoro(context, widget);
GlobalOverlayService().hidePomodoro();

// Estado
bool isPomodoroVisible = GlobalOverlayService().isPomodoroVisible;
bool isAdanFabVisible = GlobalOverlayService().isAdanFabVisible;
```

### 2. PomodoroCompactWidget
**Archivo**: [lib/features/user_auth/presentation/pages/pomodoro/PomodoroCompactWidget.dart](lib/features/user_auth/presentation/pages/pomodoro/PomodoroCompactWidget.dart)

Widget minimalista de Pomodoro optimizado para el overlay:

- ✅ Diseño compacto (300x400px expandido, 60x60px minimizado)
- ✅ Controles esenciales: Play/Pause, Reset, Skip
- ✅ Indicador visual de modo (Trabajo/Descanso)
- ✅ Timer circular con progreso
- ✅ Persistencia de configuración con SharedPreferences

### 3. Widget de Posición Fija
**Clase interna**: `_FixedOverlayWidget`

Widget centrado en pantalla (no arrastrable):

- ✅ Posición fija centrada en la pantalla
- ✅ Fondo semitransparente (se cierra al tocar afuera)
- ✅ Barra de título con botón de cerrar
- ✅ Diseño tipo modal/diálogo
- ✅ Sombra y elevación para mejor UX

### 4. FAB de ADAN Global
**Clase interna**: `_AdanFloatingButton`

Botón flotante persistente para abrir ADAN desde cualquier pantalla:

- ✅ Posición fija (bottom-right)
- ✅ Navegación directa a AsistentePageNew
- ✅ Visible en todas las pantallas (excepto Web)
- ✅ Hero disabled para evitar conflictos

---

## 🔧 Integración en la App

### En main.dart

El FAB de ADAN se inicializa automáticamente al arrancar la app:

```dart
MaterialApp(
  builder: (context, child) {
    // Inicializar FAB global de ADAN después de que el overlay esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb && context.mounted) {
        GlobalOverlayService().showAdanFab(context);
      }
    });
    return child ?? const SizedBox.shrink();
  },
  // ...
)
```

### En HomePage

El botón de Pomodoro ahora usa el overlay en lugar de Navigator:

```dart
FloatingActionButton(
  heroTag: "pomodoro",
  onPressed: () {
    if (GlobalOverlayService().isPomodoroVisible) {
      GlobalOverlayService().hidePomodoro();
    } else {
      GlobalOverlayService().showPomodoro(
        context,
        const PomodoroCompactWidget(),
      );
    }
  },
  child: const Icon(Icons.timer),
)
```

---

## 🎯 Cómo Funciona

### Arquitectura de Overlays

```
┌─────────────────────────────────────┐
│     MaterialApp (Root Widget)       │
├─────────────────────────────────────┤
│           Overlay Layer             │  ← Aquí viven los overlays
│  ┌────────────────────────────────┐ │
│  │  FAB de ADAN (persistente)     │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Pomodoro (arrastrable)        │ │
│  └────────────────────────────────┘ │
├─────────────────────────────────────┤
│      Navigator (páginas normales)   │
│  ┌────────────────────────────────┐ │
│  │  HomePage → ProyectosPage      │ │
│  │  (navegación normal)           │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Flujo de Vida de un Overlay

1. **Creación**: Se llama a `showPomodoro()` o `showAdanFab()`
2. **Inserción**: Se crea un `OverlayEntry` y se inserta en el `Overlay` raíz
3. **Persistencia**: El `OverlayEntry` permanece **independiente del Navigator**
4. **Navegación**: Puedes navegar entre páginas sin afectar el overlay
5. **Remoción**: Se llama a `hidePomodoro()` o `hideAdanFab()` para eliminar

---

## 📱 Uso en la App

### Como Usuario

**Pomodoro:**
1. En HomePage, presiona el botón de Timer (🕐)
2. Aparece el Pomodoro centrado en pantalla con fondo semitransparente
3. El Pomodoro **permanece en posición fija** (no se puede arrastrar)
4. Navega a cualquier pantalla → **el Pomodoro sigue visible**
5. Cierra tocando el fondo, el botón `×`, o vuelve a presionar el botón de Timer

**ADAN:**
1. El FAB de ADAN (🤖) está siempre visible en la esquina inferior derecha
2. Presiona para abrir el asistente
3. El FAB persiste incluso después de cerrar ADAN

### Como Desarrollador

**Agregar un nuevo overlay:**

```dart
// 1. En GlobalOverlayService, agregar:
OverlayEntry? _miOverlayEntry;
bool _isMiOverlayVisible = false;

void showMiOverlay(BuildContext context, Widget widget) {
  if (_isMiOverlayVisible) return;

  _miOverlayEntry = OverlayEntry(
    builder: (context) => _DraggableOverlayWidget(
      child: widget,
      onClose: () => hideMiOverlay(),
    ),
  );

  Overlay.of(context).insert(_miOverlayEntry!);
  _isMiOverlayVisible = true;
}

void hideMiOverlay() {
  _miOverlayEntry?.remove();
  _miOverlayEntry = null;
  _isMiOverlayVisible = false;
}

// 2. Usar en cualquier página:
GlobalOverlayService().showMiOverlay(context, MiWidget());
```

---

## 🔍 Detalles Técnicos

### ¿Por qué Overlay y no Stack?

**Stack en MaterialApp.builder** (problema anterior):
- ❌ Causaba pantalla roja
- ❌ Necesita dimensiones explícitas
- ❌ Compite con el Navigator por el layout

**Overlay** (solución actual):
- ✅ Layer independiente del Navigator
- ✅ Diseñado para elementos flotantes
- ✅ No interfiere con la navegación
- ✅ API simple y robusta

### ¿Por qué Singleton?

El patrón Singleton garantiza:
- ✅ Un solo servicio de overlay para toda la app
- ✅ Estado consistente (no hay múltiples instancias)
- ✅ Acceso global desde cualquier widget
- ✅ Menos consumo de memoria

### Gestión de Memoria

Los overlays se limpian automáticamente:
- Los `OverlayEntry` se eliminan al llamar `remove()`
- Los `Timer` en PomodoroCompactWidget se cancelan en `dispose()`
- No hay memory leaks si se usa correctamente

---

## 🧪 Testing

### Verificar que persiste al navegar

1. Abrir Pomodoro desde HomePage
2. Navegar a ProyectosPage (botón inferior)
3. ✅ El Pomodoro debe seguir visible
4. Navegar de regreso a HomePage
5. ✅ El Pomodoro sigue en la misma posición

### Verificar FAB de ADAN

1. Reiniciar la app
2. ✅ El FAB de ADAN debe aparecer automáticamente
3. Navegar entre diferentes páginas
4. ✅ El FAB persiste en todas las pantallas
5. Abrir ADAN y cerrarlo
6. ✅ El FAB vuelve a estar disponible

---

## 🚀 Próximas Mejoras

### Persistencia de Estado
- [ ] Guardar posición del Pomodoro en SharedPreferences
- [ ] Restaurar Pomodoro al reiniciar app si estaba activo
- [ ] Sincronizar tiempo de Pomodoro con backend

### Más Overlays
- [ ] Calculadora flotante
- [ ] Notas rápidas flotantes
- [ ] Mini reproductor de música

### Mejoras UX
- [ ] Animaciones al mostrar/ocultar overlays
- [ ] Snap to edges (magnetismo a bordes)
- [ ] Doble tap para minimizar/expandir
- [ ] Gestos de swipe para cerrar

---

## 📝 Archivos Clave

| Archivo | Descripción |
|---------|-------------|
| [lib/services/global_overlay_service.dart](lib/services/global_overlay_service.dart) | Servicio principal de overlays |
| [lib/features/user_auth/presentation/pages/pomodoro/PomodoroCompactWidget.dart](lib/features/user_auth/presentation/pages/pomodoro/PomodoroCompactWidget.dart) | Widget compacto de Pomodoro |
| [lib/main.dart](lib/main.dart) | Inicialización del FAB de ADAN |
| [lib/features/user_auth/presentation/pages/Login/home_page.dart](lib/features/user_auth/presentation/pages/Login/home_page.dart) | Integración del botón de Pomodoro |

---

## ⚠️ Notas Importantes

1. **Solo Android/iOS**: El FAB de ADAN se oculta en Web (`if (!kIsWeb)`)
2. **Context requirement**: Todos los métodos de show necesitan un `BuildContext` válido
3. **Dispose**: Los widgets en overlay deben manejar su propio `dispose()` para limpiar recursos
4. **Z-index**: Los overlays están siempre encima de todo (excepto dialogs del sistema)

---

**Última actualización**: 24/12/2024
**Estado**: ✅ Completado y funcionando
