# 🚀 Guía Rápida: Agregar Botón de Gamification

## ⚡ Opción 1: Agregar a HomePage (MÁS FÁCIL)

### Paso 1: Edita `home_page.dart`

Busca el archivo: `lib/features/user_auth/presentation/pages/Login/home_page.dart`

### Paso 2: Agrega el Import

Al inicio del archivo (alrededor de la línea 10), agrega:

```dart
import 'package:pucpflow/demo/gamification_quick_access.dart';
```

### Paso 3: Agrega el Botón

Busca el método `build` del Scaffold y agrega **UNA** de estas opciones:

#### **Opción A: Como Botón Flotante (FloatingActionButton)**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... tu código existente ...

    // AGREGAR ESTO ↓ (antes del último paréntesis del Scaffold)
    floatingActionButton: GamificationQuickAccessButton(
      isFloatingActionButton: true,
    ),
  );
}
```

#### **Opción B: Como Icono en AppBar**

Busca el `AppBar` y modifica:

```dart
appBar: AppBar(
  title: Text('Home'),
  actions: [
    // ... tus iconos existentes ...

    // AGREGAR ESTO ↓
    GamificationQuickAccessButton(),
  ],
),
```

#### **Opción C: Como Card en el Body**

Dentro del `body`, agrega:

```dart
body: SingleChildScrollView(
  child: Column(
    children: [
      // AGREGAR ESTO ↓
      GamificationQuickAccessCard(),

      // ... tu contenido existente ...
    ],
  ),
),
```

---

## ⚡ Opción 2: Crear Página Dedicada (5 MINUTOS)

Si prefieres una página separada para pruebas:

### Archivo Nuevo: `lib/demo/gamification_control_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class GamificationControlPage extends StatefulWidget {
  const GamificationControlPage({super.key});

  @override
  State<GamificationControlPage> createState() => _GamificationControlPageState();
}

class _GamificationControlPageState extends State<GamificationControlPage> {
  late final FileLoader _fileLoader;
  StateMachine? _stateMachine;
  int _currentStars = 0;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/rive/gamification.riv',
      riveFactory: Factory.rive,
    );
  }

  void _onRiveInit(RiveController controller) {
    if (controller is StateMachine) {
      setState(() {
        _stateMachine = controller;
      });
    }
  }

  void _setStars(int stars) {
    setState(() => _currentStars = stars);

    if (_stateMachine == null) return;

    // IMPORTANTE: Adapta según el tipo de tu input "switch"

    // Si "switch" es NUMBER:
    final input = _stateMachine!.findInput<double>('switch');
    if (input != null) {
      input.value = stars.toDouble();
      print('✅ Input NUMBER "switch" establecido a: $stars');
    }

    // Si "switch" es BOOLEAN (descomenta si es tu caso):
    // final input = _stateMachine!.findInput<bool>('switch');
    // if (input != null) {
    //   input.value = stars > 0;
    //   print('✅ Input BOOLEAN "switch" establecido a: ${stars > 0}');
    // }

    // Si "switch" es TRIGGER (descomenta si es tu caso):
    // final input = _stateMachine!.findInput<bool>('switch');
    // if (input != null) {
    //   input.fire();
    //   print('✅ TRIGGER "switch" disparado');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('🎮 Gamification Control'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // Estado actual
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Estrellas Actuales: $_currentStars',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Vista de la animación
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RiveWidgetBuilder(
                  fileLoader: _fileLoader,
                  builder: (context, state) {
                    return switch (state) {
                      RiveLoading() => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      RiveFailed() => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Error al cargar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      RiveLoaded() => RiveWidget(
                          controller: state.controller,
                          fit: Fit.contain,
                          onInit: _onRiveInit,
                        ),
                    };
                  },
                ),
              ),
            ),
          ),

          // Controles
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Controles:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStarButton(0, '0 ⭐'),
                    _buildStarButton(1, '1 ⭐'),
                    _buildStarButton(2, '2 ⭐⭐'),
                    _buildStarButton(3, '3 ⭐⭐⭐'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '💡 Tip: Presiona un botón para cambiar las estrellas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Observa cómo cambia la animación arriba',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarButton(int stars, String label) {
    final isSelected = _currentStars == stars;

    return ElevatedButton(
      onPressed: () => _setStars(stars),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFFBBF24)
            : Colors.white.withValues(alpha: 0.1),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFFBBF24)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }
}
```

### Navegar a Esta Página:

```dart
import 'package:pucpflow/demo/gamification_control_page.dart';

// Desde cualquier botón:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const GamificationControlPage(),
  ),
);
```

---

## ⚡ Opción 3: Acceso Directo (30 SEGUNDOS)

Si solo quieres probar RÁPIDO:

### En cualquier botón existente de tu app:

```dart
onPressed: () {
  // Reemplaza esto ↓
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const GamificationTestPage(), // ← o GamificationControlPage()
    ),
  );
},
```

---

## 📝 Resumen de Opciones

| Opción | Tiempo | Complejidad | Resultado |
|--------|--------|-------------|-----------|
| **Opción 1A**: FAB en HomePage | 1 min | Muy fácil | Botón flotante permanente |
| **Opción 1B**: Icono en AppBar | 1 min | Muy fácil | Icono en barra superior |
| **Opción 1C**: Card en Body | 2 min | Fácil | Card visual en lista |
| **Opción 2**: Página Control | 5 min | Media | Página completa con controles |
| **Opción 3**: Acceso Directo | 30 seg | Trivial | Prueba inmediata |

---

## 🎯 Recomendación

**Para empezar AHORA:**
1. Usa **Opción 1A** (FloatingActionButton)
2. Agrega 3 líneas de código a `home_page.dart`
3. Corre la app
4. Toca el botón flotante ⭐

**Total: 2 minutos para probar tu animación**

---

## ✅ Checklist

- [ ] Elegir una opción (1A, 1B, 1C, 2, o 3)
- [ ] Agregar import si es necesario
- [ ] Agregar widget/código
- [ ] Correr: `flutter run`
- [ ] Tocar botón y ver la animación
- [ ] Confirmar que carga sin errores

---

¡Listo para probar! 🚀
