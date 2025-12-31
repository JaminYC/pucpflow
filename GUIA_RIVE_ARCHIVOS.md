# 🎬 Guía Completa: Usar Archivos .riv en Flutter

## 📥 PASO 1: Conseguir Animaciones .riv

### Opción A: Descargar de Rive Community (GRATIS)
1. Ve a: **https://rive.app/community**
2. Busca animaciones (ejemplos):
   - "loading" → spinners, loaders
   - "success" → checkmarks, confetti
   - "error" → alertas, errores
   - "button" → botones interactivos
   - "navigation" → iconos de menú

3. Click en la animación que te guste
4. Click en **"Download .riv file"**
5. Guarda el archivo (ejemplo: `loading.riv`)

### Opción B: Crear tus propias animaciones
1. Ve a: **https://rive.app**
2. Crea cuenta gratis
3. Usa el editor para crear animaciones
4. Exporta como `.riv`

---

## 📁 PASO 2: Organizar los Archivos

### 2.1 Crear carpeta de assets
Ya existe: `c:\Users\User\pucpflow\assets\rive\`

### 2.2 Copiar archivos .riv
Coloca tus archivos `.riv` en esa carpeta:
```
assets/
  rive/
    loading.riv
    success.riv
    error.riv
    button_like.riv
    nav_menu.riv
```

### 2.3 Actualizar pubspec.yaml

Abre `pubspec.yaml` y agrega:

```yaml
flutter:
  assets:
    - assets/rive/
    # O específicamente:
    - assets/rive/loading.riv
    - assets/rive/success.riv
    - assets/rive/error.riv
```

### 2.4 Ejecutar
```bash
flutter pub get
```

---

## 💻 PASO 3: Usar Animaciones .riv en tu Código

### Ejemplo 1: Animación Simple (Loop Automático)

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoadingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      child: RiveAnimation.asset(
        'assets/rive/loading.riv',
        fit: BoxFit.cover,
      ),
    );
  }
}
```

### Ejemplo 2: Animación con Control (Play/Pause)

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class ControlledAnimation extends StatefulWidget {
  @override
  State<ControlledAnimation> createState() => _ControlledAnimationState();
}

class _ControlledAnimationState extends State<ControlledAnimation> {
  SMITrigger? _trigger;
  SMIBool? _isActive;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Nombre en Rive
    );

    if (controller != null) {
      artboard.addController(controller);
      _trigger = controller.findInput<bool>('Trigger') as SMITrigger?;
      _isActive = controller.findInput<bool>('isActive') as SMIBool?;
    }
  }

  void _onTap() {
    _trigger?.fire(); // Ejecutar trigger
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: 150,
        height: 150,
        child: RiveAnimation.asset(
          'assets/rive/button_like.riv',
          onInit: _onRiveInit,
        ),
      ),
    );
  }
}
```

### Ejemplo 3: Botón Animado con .riv

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveButtonWidget extends StatefulWidget {
  final String rivePath;
  final VoidCallback onPressed;
  final Widget? child;

  const RiveButtonWidget({
    super.key,
    required this.rivePath,
    required this.onPressed,
    this.child,
  });

  @override
  State<RiveButtonWidget> createState() => _RiveButtonWidgetState();
}

class _RiveButtonWidgetState extends State<RiveButtonWidget> {
  SMITrigger? _pressTrigger;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );

    if (controller != null) {
      artboard.addController(controller);
      _pressTrigger = controller.findInput<bool>('press') as SMITrigger?;
    }
  }

  void _handleTap() {
    _pressTrigger?.fire();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 80,
            child: RiveAnimation.asset(
              widget.rivePath,
              onInit: _onRiveInit,
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

// USO:
RiveButtonWidget(
  rivePath: 'assets/rive/button_like.riv',
  onPressed: () => print('¡Botón presionado!'),
  child: Text('Me gusta', style: TextStyle(color: Colors.white)),
)
```

---

## 🎯 PASO 4: Widget Reutilizable para Rive

Voy a crear un widget genérico que puedas usar fácilmente:

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Widget genérico para mostrar animaciones Rive
class RiveAnimationWidget extends StatefulWidget {
  final String assetPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? stateMachineName;
  final Function(Artboard)? onInit;
  final bool autoPlay;

  const RiveAnimationWidget({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.stateMachineName,
    this.onInit,
    this.autoPlay = true,
  });

  @override
  State<RiveAnimationWidget> createState() => _RiveAnimationWidgetState();
}

class _RiveAnimationWidgetState extends State<RiveAnimationWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      child: widget.stateMachineName != null
          ? RiveAnimation.asset(
              widget.assetPath,
              fit: widget.fit,
              stateMachines: [widget.stateMachineName!],
              onInit: widget.onInit,
            )
          : RiveAnimation.asset(
              widget.assetPath,
              fit: widget.fit,
              onInit: widget.onInit,
            ),
    );
  }
}

// USO FÁCIL:
RiveAnimationWidget(
  assetPath: 'assets/rive/loading.riv',
  width: 100,
  height: 100,
)
```

---

## 🎬 Casos de Uso Comunes

### 1. Loading Spinner
```dart
RiveAnimationWidget(
  assetPath: 'assets/rive/loading.riv',
  width: 80,
  height: 80,
)
```

### 2. Success Animation
```dart
RiveAnimationWidget(
  assetPath: 'assets/rive/success.riv',
  width: 120,
  height: 120,
)
```

### 3. Error Animation
```dart
RiveAnimationWidget(
  assetPath: 'assets/rive/error.riv',
  width: 100,
  height: 100,
)
```

### 4. Botón Like Interactivo
```dart
class LikeButton extends StatefulWidget {
  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  SMITrigger? _like;
  bool _isLiked = false;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );

    if (controller != null) {
      artboard.addController(controller);
      _like = controller.findInput<bool>('Like') as SMITrigger?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _like?.fire();
        setState(() => _isLiked = !_isLiked);
      },
      child: SizedBox(
        width: 64,
        height: 64,
        child: RiveAnimation.asset(
          'assets/rive/like_button.riv',
          onInit: _onRiveInit,
        ),
      ),
    );
  }
}
```

---

## 📚 Recursos Recomendados

### Animaciones Populares (Buscar en Rive Community):
1. **Loading Spinners**:
   - "Simple Loader"
   - "Animated Spinner"
   - "Loading Dots"

2. **Success/Error**:
   - "Success Checkmark"
   - "Error Alert"
   - "Confetti Celebration"

3. **Botones**:
   - "Like Button"
   - "Menu Toggle"
   - "Download Button"

4. **Navegación**:
   - "Nav Bar Icons"
   - "Menu Animation"
   - "Tab Bar"

---

## ⚡ Tips de Performance

1. **Tamaño de archivos**: Mantén los .riv por debajo de 200KB
2. **Número de animaciones**: No más de 3-4 animaciones simultáneas
3. **Dispose**: Siempre libera recursos cuando no se usen
4. **Caché**: Rive cachea automáticamente, no te preocupes

---

## 🔧 Troubleshooting

### Error: "Unable to load asset"
```bash
# Solución:
flutter clean
flutter pub get
flutter run
```

### Error: "StateMachine not found"
- Verifica el nombre exacto en el archivo .riv
- Abre el .riv en rive.app para ver los nombres

### Animación no se reproduce
- Verifica que tenga un State Machine o Animation
- Asegúrate de que autoPlay esté habilitado

---

## ✅ Checklist de Integración

- [ ] Descargar archivo .riv
- [ ] Copiar a `assets/rive/`
- [ ] Actualizar `pubspec.yaml`
- [ ] Ejecutar `flutter pub get`
- [ ] Importar `package:rive/rive.dart`
- [ ] Usar `RiveAnimation.asset()`
- [ ] ¡Probar!

---

## 🎓 Siguiente Paso

¿Quieres que te cree un widget específico para tu uso? Por ejemplo:
- Botón de like animado
- Loading spinner
- Success/Error feedback
- Navegación animada

¡Solo dime qué necesitas!
