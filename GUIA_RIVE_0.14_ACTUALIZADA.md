# 🎬 Guía Completa: Usar Archivos .riv con Rive 0.14.0

Esta guía te enseña paso a paso cómo usar animaciones Rive descargadas o creadas (archivos `.riv`) en tu app Flutter usando la **nueva API de Rive 0.14.0**.

---

## ⚠️ IMPORTANTE: Cambios en Rive 0.14.0

La versión 0.14.0 tiene **cambios importantes**:
- ❌ **`RiveAnimation.asset()` YA NO EXISTE**
- ❌ **`Rive` widget eliminado**
- ✅ Usar `RiveWidget` + `RiveWidgetBuilder` + `FileLoader`
- ✅ **OBLIGATORIO**: Inicializar `RiveNative.init()` en `main()`

---

## 🚀 Paso 0: Inicializar Rive (OBLIGATORIO)

**ANTES de usar cualquier animación**, actualiza tu `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ ESTO ES OBLIGATORIO PARA RIVE 0.14.0
  await RiveNative.init();

  runApp(const MyApp());
}
```

---

## 📥 Paso 1: Conseguir Archivos .riv

### Opción A: Descargar de Rive Community (GRATIS)

1. Ve a: **https://rive.app/community**
2. Busca animaciones:
   - "loading" → spinners, loaders
   - "success" → checkmarks, confetti
   - "error" → alertas
   - "button" → botones interactivos
3. Click en "Download .riv file"
4. Guarda el archivo

### Opción B: Crear tus propias

1. Ve a **https://rive.app**
2. Crea cuenta gratis
3. Diseña tu animación
4. Exporta como `.riv`

---

## 📂 Paso 2: Organizar Archivos

### Estructura del proyecto:

```
tu_proyecto/
├── lib/
├── assets/
│   └── rive/
│       ├── loading.riv
│       ├── success.riv
│       ├── error.riv
│       └── button.riv
└── pubspec.yaml
```

### Configurar `pubspec.yaml`:

```yaml
dependencies:
  rive: ^0.14.0

flutter:
  assets:
    - assets/rive/
```

Ejecuta:
```bash
flutter pub get
```

---

## 🎨 Paso 3: Usar las Animaciones

### ✅ Método 1: Usar nuestro wrapper (MÁS FÁCIL)

Ya creamos widgets helpers en `lib/widgets/rive_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:pucpflow/widgets/rive_widget.dart';

class MiPagina extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SimpleRiveAnimation(
          assetPath: 'assets/rive/loading.riv',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
```

### ✅ Método 2: API directa de Rive 0.14.0

Si prefieres usar la API directa:

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AnimacionDirecta extends StatefulWidget {
  const AnimacionDirecta({super.key});

  @override
  State<AnimacionDirecta> createState() => _AnimacionDirectaState();
}

class _AnimacionDirectaState extends State<AnimacionDirecta> {
  late final FileLoader _fileLoader;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/rive/loading.riv',
      riveFactory: Factory.rive,
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: RiveWidgetBuilder(
            fileLoader: _fileLoader,
            builder: (context, state) => switch (state) {
              RiveLoading() => const CircularProgressIndicator(),
              RiveFailed() => const Icon(Icons.error, color: Colors.red),
              RiveLoaded() => RiveWidget(
                  controller: state.controller,
                  fit: Fit.cover,
                ),
            },
          ),
        ),
      ),
    );
  }
}
```

---

## 📦 Ejemplos Prácticos

### 1. Loading Spinner

```dart
SimpleRiveAnimation(
  assetPath: 'assets/rive/loading.riv',
  width: 100,
  height: 100,
)
```

### 2. Success Checkmark

```dart
SimpleRiveAnimation(
  assetPath: 'assets/rive/success.riv',
  width: 150,
  height: 150,
)
```

### 3. Loading con Mensaje

```dart
RiveLoadingWidget(
  assetPath: 'assets/rive/loading.riv',
  message: 'Cargando datos...',
  size: 120,
)
```

### 4. Feedback de Éxito

```dart
RiveFeedback.showSuccess(
  context,
  'assets/rive/success.riv',
  '¡Guardado exitosamente!',
)
```

### 5. Botón con Animación

```dart
RiveInteractiveButton(
  assetPath: 'assets/rive/button.riv',
  onPressed: () {
    print('Botón presionado!');
  },
  width: 80,
  height: 80,
)
```

---

## 🎯 Animaciones Recomendadas de Rive Community

### Para tu app de gestión de proyectos:

1. **Loading/Spinner**
   - Busca: "loading spinner"
   - Usar en: carga de datos, procesamiento

2. **Success/Checkmark**
   - Busca: "success checkmark"
   - Usar en: tarea completada, guardado exitoso

3. **Error/Alert**
   - Busca: "error alert"
   - Usar en: errores, validaciones

4. **Like Button**
   - Busca: "like button animated"
   - Usar en: marcar favoritos, reacciones

5. **Progress Bar**
   - Busca: "progress bar"
   - Usar en: progreso de tareas/proyectos

6. **Menu Icon**
   - Busca: "hamburger menu animated"
   - Usar en: navegación

---

## 🔧 Parámetros Comunes

### Fit (ajuste de la animación):

```dart
SimpleRiveAnimation(
  assetPath: 'assets/rive/loading.riv',
  fit: Fit.contain,    // Contiene dentro del espacio
  // fit: Fit.cover,   // Cubre todo el espacio
  // fit: Fit.fill,    // Llena estirando
  // fit: Fit.fitWidth,// Ajusta al ancho
  // fit: Fit.fitHeight,// Ajusta a la altura
)
```

### Alignment (alineación):

```dart
SimpleRiveAnimation(
  assetPath: 'assets/rive/loading.riv',
  alignment: Alignment.center,      // Centro
  // alignment: Alignment.topLeft,  // Arriba izquierda
  // alignment: Alignment.bottomRight, // Abajo derecha
)
```

---

## ❌ Errores Comunes y Soluciones

### Error 1: "Undefined name 'RiveAnimation'"
❌ **Problema**: Estás usando la API antigua
✅ **Solución**: Usar `RiveWidget` + `RiveWidgetBuilder` o nuestro wrapper `SimpleRiveAnimation`

### Error 2: "RiveNative.init() was not called"
❌ **Problema**: No inicializaste Rive
✅ **Solución**: Agregar `await RiveNative.init()` en `main()`

### Error 3: "Unable to load asset"
❌ **Problema**: Ruta incorrecta o falta en `pubspec.yaml`
✅ **Solución**:
1. Verificar que el archivo exista en `assets/rive/`
2. Verificar `pubspec.yaml` tenga `- assets/rive/`
3. Ejecutar `flutter pub get`
4. Reiniciar la app

### Error 4: Animación no se ve
❌ **Problema**: Tamaño muy pequeño o `fit` incorrecto
✅ **Solución**: Especificar `width` y `height` explícitamente

---

## 🎨 Tips de Diseño

1. **Tamaños Recomendados**:
   - Loading spinner: 80-120px
   - Success/Error: 120-150px
   - Botones: 60-80px
   - Iconos de navegación: 24-32px

2. **Performance**:
   - No uses animaciones muy complejas en listas largas
   - Usa `RepaintBoundary` para animaciones pesadas
   - Limita animaciones simultáneas a 5-10

3. **UX**:
   - Animaciones rápidas: 300-500ms
   - Animaciones de feedback: 1-2 segundos
   - Loops infinitos solo para loading

---

## 📚 Recursos

- **Rive Community**: https://rive.app/community
- **Documentación Rive**: https://rive.app/docs
- **Flutter Rive Package**: https://pub.dev/packages/rive
- **Guía de Migración**: https://rive.app/docs/runtimes/flutter/migration-guide

---

## ✅ Checklist de Implementación

- [ ] ✅ Agregar `await RiveNative.init()` en `main()`
- [ ] ✅ Descargar archivos `.riv` que necesitas
- [ ] ✅ Copiar archivos a `assets/rive/`
- [ ] ✅ Actualizar `pubspec.yaml` con assets
- [ ] ✅ Ejecutar `flutter pub get`
- [ ] ✅ Usar `SimpleRiveAnimation` o `RiveWidgetBuilder`
- [ ] ✅ Probar en dispositivo/emulador

---

## 🎉 ¡Listo!

Ahora puedes usar animaciones Rive profesionales en tu app. Los widgets helpers ya están creados en `lib/widgets/rive_widget.dart` para facilitarte el trabajo.

**Ejemplos funcionales en**: `lib/demo/animations_demo_page.dart` (accesible desde el botón 🎨 en HomePage)
