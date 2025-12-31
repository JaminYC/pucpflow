# 🎮 Setup Completo: gamification.riv

## 📸 Análisis de Tu Screenshot

Basado en la imagen del editor de Rive que compartiste:

### ✅ Información Detectada

| Componente | Valor |
|------------|-------|
| **State Machine** | `State Machine 1` |
| **Input Principal** | `switch` |
| **Animaciones** | `pop tête lvl 0`, `pop tête lvl 3`, `pop tete lvl 2` |
| **Estados Auxiliares** | `3 stars`, `2 stars`, `1 star` |
| **Estados de Transición** | `passage étoile`, `idle`, `bounce`, `passage tête` |
| **Punto de Entrada** | `Entry` |

---

## 🎯 RESPUESTAS EXACTAS A TUS PREGUNTAS

### 1) ¿Qué inputs debo setear para pop 0/1/2/3 estrellas?

Según tu screenshot, tienes **1 input llamado `switch`**.

```dart
// Para controlar las estrellas, usa el input "switch"
final switchInput = controller.findInput<bool>('switch');

// Probablemente necesitas alternar el switch para cambiar entre estados
switchInput?.value = true;  // O false, dependiendo de la lógica
```

**NOTA:** Sin ver los detalles del input `switch` en el panel de inputs, las opciones son:

- **Si es BOOLEAN**: Alterna entre true/false para cambiar estados
- **Si es NUMBER**: Establece valores 0, 1, 2, 3
- **Si es TRIGGER**: Dispáralo para avanzar entre estados

### 2) ¿Necesito triggers, booleans o number inputs?

Basado en tu screenshot:

**YA TIENES:** Input `switch` (tipo a confirmar)

**Para un sistema de estrellas completo, típicamente necesitarías:**

| Enfoque | Input Necesario | Cómo Funciona |
|---------|-----------------|---------------|
| **Opción A** | 1 NUMBER `stars` | Valores: 0.0, 1.0, 2.0, 3.0 |
| **Opción B** | 1 BOOLEAN `switch` | Alterna entre estados predefinidos |
| **Opción C** | 4 TRIGGERs | `pop0`, `pop1`, `pop2`, `pop3` |

**TU CASO:** Parece que usas **1 input** (switch) que controla transiciones entre los estados `pop tête lvl 0/2/3`.

### 3) Plan de Prueba Mínimo

#### ✅ Fase 1: Runtime Validation (SIN modificar .riv)

**Paso 1: Agregar Botón de Acceso**

En cualquier página (ej: `home_page.dart`), agrega:

```dart
import 'package:pucpflow/demo/gamification_quick_access.dart';

// Opción 1: Como FloatingActionButton
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... tu contenido existente
    floatingActionButton: GamificationQuickAccessButton(
      isFloatingActionButton: true,
    ),
  );
}

// Opción 2: Como IconButton en AppBar
appBar: AppBar(
  title: Text('Home'),
  actions: [
    GamificationQuickAccessButton(),
  ],
),

// Opción 3: Como Card en el body
body: Column(
  children: [
    GamificationQuickAccessCard(),
    // ... resto del contenido
  ],
),
```

**Paso 2: Correr la App**

```bash
flutter run
```

**Paso 3: Navegar a la Prueba**

1. Toca el botón de estrellas (⭐)
2. Verás la página `GamificationTestPage`
3. Observa que la animación carga ✅

#### ✅ Fase 2: Inspección Detallada

**Paso 1: Confirmar Tipo del Input**

En el editor de Rive (tu screenshot):
1. Haz clic en el panel **"Inputs"** (lado izquierdo)
2. Selecciona `switch`
3. Observa el tipo:
   - 🟢 **Number** → Valores numéricos
   - 🔵 **Boolean** → true/false
   - 🟡 **Trigger** → Disparo único

**Paso 2: Anotar Configuración**

```
State Machine: State Machine 1
Input: switch
Tipo: [COMPLETA AQUÍ: Number/Boolean/Trigger]
Valor por defecto: [COMPLETA AQUÍ]
Rango (si es Number): [COMPLETA AQUÍ: ej. 0-3]
```

#### ✅ Fase 3: Código Específico

Una vez que confirmes el tipo de `switch`, usa:

**Si es NUMBER:**
```dart
final switchInput = controller.findInput<double>('switch');
switchInput?.value = 0.0; // 0 estrellas
switchInput?.value = 1.0; // 1 estrella
switchInput?.value = 2.0; // 2 estrellas
switchInput?.value = 3.0; // 3 estrellas
```

**Si es BOOLEAN:**
```dart
final switchInput = controller.findInput<bool>('switch');
switchInput?.value = false; // Estado inicial
switchInput?.value = true;  // Estado activado
```

**Si es TRIGGER:**
```dart
final switchInput = controller.findInput<bool>('switch');
switchInput?.fire(); // Disparar transición
```

---

## 🚀 ACCIÓN INMEDIATA

### Paso 1: Agregar Botón de Acceso (2 minutos)

Edita cualquier archivo de página (ej: `home_page.dart`):

```dart
// 1. Agregar import al inicio del archivo
import 'package:pucpflow/demo/gamification_quick_access.dart';

// 2. Buscar el Scaffold y agregar FAB
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Home')),
    body: YourContent(),

    // AGREGAR ESTO ↓
    floatingActionButton: GamificationQuickAccessButton(
      isFloatingActionButton: true,
      tooltip: 'Probar Gamification',
    ),
  );
}
```

### Paso 2: Correr y Probar (1 minuto)

```bash
flutter run
```

Toca el botón flotante con icono de estrellas ⭐

### Paso 3: Confirmar Tipo de Input (2 minutos)

1. Ve al editor de Rive (tu screenshot)
2. Haz clic en `switch` en el panel "Inputs"
3. Anota el tipo y rango

---

## 📊 Código Completo de Ejemplo

```dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class GamificationExample extends StatefulWidget {
  @override
  State<GamificationExample> createState() => _GamificationExampleState();
}

class _GamificationExampleState extends State<GamificationExample> {
  late final FileLoader _fileLoader;
  StateMachine? _stateMachine;

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
    if (_stateMachine == null) return;

    // OPCIÓN A: Si "switch" es NUMBER
    final input = _stateMachine!.findInput<double>('switch');
    input?.value = stars.toDouble();

    // OPCIÓN B: Si "switch" es BOOLEAN (alterna)
    // final input = _stateMachine!.findInput<bool>('switch');
    // input?.value = !input.value;

    // OPCIÓN C: Si "switch" es TRIGGER
    // final input = _stateMachine!.findInput<bool>('switch');
    // input?.fire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gamification Test')),
      body: Column(
        children: [
          // Animación
          Expanded(
            child: RiveWidgetBuilder(
              fileLoader: _fileLoader,
              builder: (context, state) {
                return switch (state) {
                  RiveLoading() => Center(child: CircularProgressIndicator()),
                  RiveFailed() => Center(child: Icon(Icons.error)),
                  RiveLoaded() => RiveWidget(
                      controller: state.controller,
                      fit: Fit.contain,
                      onInit: _onRiveInit,
                    ),
                };
              },
            ),
          ),

          // Controles
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _setStars(0),
                  child: Text('0 ⭐'),
                ),
                ElevatedButton(
                  onPressed: () => _setStars(1),
                  child: Text('1 ⭐'),
                ),
                ElevatedButton(
                  onPressed: () => _setStars(2),
                  child: Text('2 ⭐'),
                ),
                ElevatedButton(
                  onPressed: () => _setStars(3),
                  child: Text('3 ⭐'),
                ),
              ],
            ),
          ),
        ],
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

---

## 🎯 Checklist Final

### Pre-código
- [ ] ✅ Archivo `gamification.riv` en `assets/rive/`
- [ ] ✅ Página de prueba creada (`GamificationTestPage`)
- [ ] ✅ Botón de acceso rápido creado (`GamificationQuickAccessButton`)

### Runtime Validation
- [ ] ⏳ Agregar botón de acceso a una página
- [ ] ⏳ Correr app y tocar botón de estrellas
- [ ] ⏳ Verificar que animación carga sin errores

### Inspección
- [ ] ⏳ Confirmar tipo del input `switch` (Number/Boolean/Trigger)
- [ ] ⏳ Anotar rango de valores (si es Number)
- [ ] ⏳ Probar valores en código

### Implementación
- [ ] ⏳ Usar código específico según tipo de input
- [ ] ⏳ Probar 0, 1, 2, 3 estrellas
- [ ] ⏳ Validar que animaciones se muestran correctamente

---

## 🆘 Solución Rápida

Si quieres probar YA sin agregar código:

```bash
# Corre la app
flutter run

# En el código, navega directamente:
# Desde cualquier botón existente, cambia su onPressed a:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const GamificationTestPage(),
  ),
);
```

---

## 📞 Próximos Pasos

1. **AHORA:** Agrega el botón de acceso rápido
2. **2 MIN:** Corre la app y prueba
3. **5 MIN:** Confirma tipo del input `switch` en Rive
4. **10 MIN:** Implementa código específico

¡Todo listo para probar! 🎉
