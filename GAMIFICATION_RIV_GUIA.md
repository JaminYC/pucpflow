# 🎮 Guía: gamification.riv - Validación Runtime

## 📋 Respuestas a Tus Preguntas

### 1) ¿Qué inputs debo setear para disparar 0/1/2/3 estrellas?

**DEPENDE del diseño de tu archivo .riv**. Hay 3 posibilidades comunes:

#### Opción A: Input tipo NUMBER
```dart
// Si tienes un input llamado "stars" o "rating"
final starsInput = controller.findInput<double>('stars');

// Disparar 0 estrellas
starsInput?.value = 0.0;

// Disparar 1 estrella
starsInput?.value = 1.0;

// Disparar 2 estrellas
starsInput?.value = 2.0;

// Disparar 3 estrellas
starsInput?.value = 3.0;
```

#### Opción B: TRIGGERs individuales
```dart
// Si tienes triggers como "pop0", "pop1", "pop2", "pop3"

// Disparar 0 estrellas
controller.findInput<bool>('pop0')?.fire();

// Disparar 1 estrella
controller.findInput<bool>('pop1')?.fire();

// Disparar 2 estrellas
controller.findInput<bool>('pop2')?.fire();

// Disparar 3 estrellas
controller.findInput<bool>('pop3')?.fire();
```

#### Opción C: BOOLEAN + NUMBER combinados
```dart
// Activar el sistema
controller.findInput<bool>('isActive')?.value = true;

// Luego establecer la cantidad
controller.findInput<double>('stars')?.value = 3.0;
```

---

### 2) ¿Necesito triggers, booleans o number inputs?

**Para un sistema de estrellas (0-3), típicamente necesitas:**

| Tipo | Uso Recomendado | Ejemplo |
|------|-----------------|---------|
| **NUMBER** | ⭐ MEJOR para estrellas | `stars` con valores 0.0, 1.0, 2.0, 3.0 |
| **TRIGGER** | Eventos únicos/transiciones | `pop0`, `pop1`, `pop2`, `pop3` |
| **BOOLEAN** | Activar/desactivar | `isActive`, `show`, `hidden` |

**Respuesta directa:**
- **Si quieres simplicidad**: Usa 1 input **NUMBER** llamado "stars"
- **Si quieres animaciones únicas por nivel**: Usa 4 **TRIGGERs** (pop0, pop1, pop2, pop3)
- **Si quieres control on/off**: Agrega 1 **BOOLEAN** (isActive)

---

### 3) Plan de Prueba Mínimo (SIN modificar el .riv)

#### ✅ Validación Runtime

**Paso 1: Verifica que carga**
```bash
# Corre la página de prueba
flutter run
# Navega a: GamificationTestPage
```

**Resultado esperado:**
- ✅ La animación se muestra
- ✅ No hay errores en consola
- ✅ El indicador muestra "Cargado"

**Paso 2: Inspecciona el archivo original**

Para saber los nombres exactos SIN modificar el .riv:

1. Abre https://rive.app
2. Sube `gamification.riv`
3. Ve al panel "Animations" → Selecciona la State Machine
4. Anota el nombre exacto (ej: "State Machine 1")
5. Ve al panel "Inputs"
6. Anota cada input:
   - Nombre (ej: "stars", "pop0", etc.)
   - Tipo (Number, Trigger, Boolean)
   - Valor por defecto

**Paso 3: Prueba en código**

Usa exactamente los nombres que anotaste:

```dart
import 'package:rive/rive.dart';

// Crear State Machine
final controller = StateMachine.fromArtboard(
  artboard,
  'State Machine 1', // ← Usa el nombre exacto
);

// Probar input
final input = controller.findInput<double>('stars'); // ← Usa el nombre exacto
input?.value = 3.0;

// Verificar
print('Input encontrado: ${input != null}');
print('Valor actual: ${input?.value}');
```

**Paso 4: Validación visual**

- Cambia el valor del input
- Observa que la animación cambia
- Verifica que muestra 0/1/2/3 estrellas correctamente

---

## 🔍 Cómo Obtener la Info SIN Screenshot

### Método 1: Usar la Página de Prueba

Ya creé una página de prueba para ti:

```dart
import 'package:pucpflow/demo/gamification_test_page.dart';

// Navegar a la página
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const GamificationTestPage(),
  ),
);
```

Esta página:
- ✅ Carga y muestra tu animación
- ✅ Valida que funciona en runtime
- ✅ Muestra guías de inspección
- ✅ Incluye ejemplos de código

### Método 2: Inspección Directa en Rive Editor

1. Ve a https://rive.app
2. Abre `gamification.riv`
3. Inspecciona:
   - Panel "Animations" → State Machine name
   - Panel "Inputs" → Lista de inputs
   - Panel "States" → Lógica de transiciones

---

## 📊 Checklist de Validación

### Runtime (Flutter/Web)
- [ ] ✅ Archivo carga sin errores
- [ ] ✅ Animación se muestra
- [ ] ✅ No hay warnings en consola
- [ ] ✅ Funciona en Flutter/Web (probado en GamificationTestPage)

### Información del Archivo
- [ ] ⏳ Nombre de State Machine (obtener del editor)
- [ ] ⏳ Lista de inputs (obtener del editor)
- [ ] ⏳ Tipos de inputs (obtener del editor)
- [ ] ⏳ Valores por defecto (obtener del editor)

### Código
- [ ] ⏳ Usar nombres exactos del editor
- [ ] ⏳ Probar cada input individualmente
- [ ] ⏳ Verificar que la animación responde
- [ ] ⏳ Validar valores: 0, 1, 2, 3 estrellas

---

## 💡 Ejemplos de Uso Común

### Escenario 1: Mostrar Resultado de Evaluación

```dart
class ResultadoPage extends StatefulWidget {
  final int estrellas; // 0, 1, 2, o 3

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RiveAnimation.asset(
          'assets/rive/gamification.riv',
          stateMachines: ['State Machine 1'],
          onInit: (artboard) {
            final controller = StateMachineController.fromArtboard(
              artboard,
              'State Machine 1',
            );

            if (controller != null) {
              artboard.addController(controller);

              // Establecer estrellas
              final input = controller.findInput<double>('stars');
              input?.value = estrellas.toDouble();
            }
          },
        ),
      ),
    );
  }
}
```

### Escenario 2: Animación de Logro

```dart
void _mostrarLogro(int nivel) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 300,
        height: 300,
        child: RiveAnimation.asset(
          'assets/rive/gamification.riv',
          stateMachines: ['State Machine 1'],
          onInit: (artboard) {
            final controller = StateMachineController.fromArtboard(
              artboard,
              'State Machine 1',
            );

            if (controller != null) {
              artboard.addController(controller);

              // Disparar trigger según nivel
              final trigger = controller.findInput<bool>('pop$nivel');
              trigger?.fire();
            }
          },
        ),
      ),
    ),
  );
}
```

---

## 🚨 Importante: Rive 0.14

**NOTA:** Rive 0.14 deprecó `StateMachineController.inputs` en favor de Data Binding.

### Soluciones:

#### Opción 1: Usar inputs clásicos (actual)
```dart
// Esto funciona pero muestra warning de deprecation
final input = controller.findInput<double>('stars');
input?.value = 3.0;
```

#### Opción 2: Migrar a Data Binding (recomendado a futuro)
```dart
// Necesita refactorizar el archivo .riv para usar Data Binding
// Ver: https://rive.app/docs/data-binding
```

**Por ahora:** El método clásico funciona perfectamente. El warning es solo informativo.

---

## 🎯 Resumen Final

### Respuestas Directas:

1. **¿Qué inputs setear?**
   - Abre el archivo en https://rive.app
   - Ve al panel "Inputs"
   - Usa exactamente esos nombres en código
   - Probablemente: `stars` (NUMBER) o `pop0`/`pop1`/`pop2`/`pop3` (TRIGGERs)

2. **¿Qué tipos necesito?**
   - **NUMBER**: Para valores numéricos (0-3)
   - **TRIGGER**: Para eventos únicos
   - **BOOLEAN**: Para on/off
   - **Lo más común**: 1 input NUMBER llamado "stars"

3. **Plan de prueba mínimo:**
   - ✅ Corre `GamificationTestPage`
   - ✅ Verifica que carga
   - ✅ Abre el .riv en Rive editor
   - ✅ Anota nombres de inputs
   - ✅ Usa esos nombres en código
   - ✅ Prueba cada valor: 0, 1, 2, 3

### ✅ Validación Runtime (SIN modificar .riv)

**YA PUEDES VALIDAR:**
```bash
flutter run
# Navega a GamificationTestPage
```

Si la animación se muestra → **✅ Funciona en runtime**

---

## 📞 Próximos Pasos

1. Corre la app y ve a `GamificationTestPage`
2. Verifica que el archivo carga
3. Abre el .riv en https://rive.app
4. Anota los nombres de inputs
5. Regresa y dame esa info para código específico

¡Listo! 🎉
