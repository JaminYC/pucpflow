# 🎬 Guía Completa: Descargar e Integrar Animaciones Rive

Esta guía te muestra **paso a paso** cómo descargar animaciones profesionales de Rive y usarlas en tu app.

---

## 📥 PASO 1: Descargar Animaciones de Rive Community

### Opción A: Descarga Manual (Recomendada)

1. **Abre tu navegador** y ve a: **https://rive.app/community**

2. **Busca las animaciones** que necesitas. Te recomiendo estas búsquedas:

   | Búsqueda | Para qué sirve | Prioridad |
   |----------|----------------|-----------|
   | "loading spinner" | Indicadores de carga | ⭐⭐⭐ ALTA |
   | "success checkmark" | Confirmaciones exitosas | ⭐⭐⭐ ALTA |
   | "error" | Mensajes de error | ⭐⭐⭐ ALTA |
   | "confetti" | Celebraciones | ⭐⭐ MEDIA |
   | "like button" | Botones de favorito | ⭐⭐ MEDIA |
   | "progress bar" | Barras de progreso | ⭐⭐ MEDIA |

3. **Haz clic en la animación** que te guste

4. **Descarga el archivo**:
   - Busca el botón "Download" o "Get File"
   - Haz clic en **"Download .riv file"**
   - Se descargará un archivo con extensión `.riv`

5. **Mueve el archivo** a tu proyecto:
   ```
   c:\Users\User\pucpflow\assets\rive\
   ```

### Opción B: Animaciones Recomendadas (Links Directos)

Estas son animaciones **gratuitas y de alta calidad** que puedes usar:

#### 1. Loading Spinner
- **Link**: https://rive.app/community/2040-3901-loading-spinner/
- **Nombre sugerido**: `loading-spinner.riv`
- **Uso**: Pantallas de carga, espera de API

#### 2. Success Checkmark
- **Link**: https://rive.app/community/1189-2383-success/
- **Nombre sugerido**: `success-check.riv`
- **Uso**: Tarea completada, guardado exitoso

#### 3. Error Icon
- **Link**: https://rive.app/community/1542-2994-error/
- **Nombre sugerido**: `error-icon.riv`
- **Uso**: Mensajes de error, validaciones fallidas

#### 4. Confetti Celebration
- **Link**: https://rive.app/community/4771-9463-confetti/
- **Nombre sugerido**: `confetti.riv`
- **Uso**: Proyecto completado, logros

#### 5. Like Button
- **Link**: https://rive.app/community/1486-2934-like-button/
- **Nombre sugerido**: `like-button.riv`
- **Uso**: Favoritos, reacciones

---

## 📂 PASO 2: Organizar los Archivos

Después de descargar, tu carpeta `assets/rive/` debe verse así:

```
c:\Users\User\pucpflow\assets\rive\
├── 24900-46503-bubble-button.riv (ya tienes este)
├── loading-spinner.riv (nuevo)
├── success-check.riv (nuevo)
├── error-icon.riv (nuevo)
├── confetti.riv (nuevo)
└── like-button.riv (nuevo)
```

**IMPORTANTE**: Ya tienes configurado `pubspec.yaml` correctamente, así que no necesitas modificarlo.

---

## 🎨 PASO 3: Usar las Animaciones

Ya tienes widgets listos para usar. Aquí te muestro cómo:

### Ejemplo 1: Loading Spinner

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// En cualquier parte donde necesites loading
RiveLoadingWidget(
  assetPath: 'assets/rive/loading-spinner.riv',
  message: 'Cargando proyectos...',
  size: 100,
)
```

### Ejemplo 2: Success Feedback

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// Mostrar cuando se guarda algo
RiveFeedback.showSuccess(
  context,
  'assets/rive/success-check.riv',
  '¡Proyecto creado exitosamente!',
)
```

### Ejemplo 3: Error Feedback

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// Mostrar cuando hay un error
RiveFeedback.showError(
  context,
  'assets/rive/error-icon.riv',
  'Error al guardar el proyecto',
)
```

### Ejemplo 4: Like Button Animado

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

RiveInteractiveButton(
  assetPath: 'assets/rive/like-button.riv',
  onPressed: () {
    setState(() {
      isFavorite = !isFavorite;
    });
  },
  width: 60,
  height: 60,
)
```

### Ejemplo 5: Confetti al Completar

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// Mostrar cuando completan todas las tareas
SimpleRiveAnimation(
  assetPath: 'assets/rive/confetti.riv',
  width: 200,
  height: 200,
)
```

---

## 🚀 PASO 4: Integración en Páginas Reales

### HomePage - Reemplazar Loading

**ANTES:**
```dart
if (isLoading) {
  return CircularProgressIndicator();
}
```

**DESPUÉS:**
```dart
import 'package:pucpflow/widgets/rive_widget.dart';

if (isLoading) {
  return RiveLoadingWidget(
    assetPath: 'assets/rive/loading-spinner.riv',
    message: 'Cargando tareas...',
  );
}
```

### ProyectosPage - Botón de Like

**ANTES:**
```dart
IconButton(
  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
  onPressed: () => toggleFavorite(),
)
```

**DESPUÉS:**
```dart
import 'package:pucpflow/widgets/rive_widget.dart';

RiveInteractiveButton(
  assetPath: 'assets/rive/like-button.riv',
  onPressed: () => toggleFavorite(),
  width: 50,
  height: 50,
)
```

### Crear Proyecto - Success Feedback

**ANTES:**
```dart
// Después de crear proyecto
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Proyecto creado')),
);
```

**DESPUÉS:**
```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// Después de crear proyecto
RiveFeedback.showSuccess(
  context,
  'assets/rive/success-check.riv',
  '¡Proyecto creado exitosamente!',
);
```

---

## 🎯 Casos de Uso Específicos

### 1. Loading en Llamadas a Firebase

```dart
class MiWidget extends StatefulWidget {
  @override
  State<MiWidget> createState() => _MiWidgetState();
}

class _MiWidgetState extends State<MiWidget> {
  bool _isLoading = false;

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Tu código de Firebase
      await FirebaseFirestore.instance.collection('tareas').get();

      // Mostrar success
      RiveFeedback.showSuccess(
        context,
        'assets/rive/success-check.riv',
        'Datos cargados',
      );
    } catch (e) {
      // Mostrar error
      RiveFeedback.showError(
        context,
        'assets/rive/error-icon.riv',
        'Error: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return RiveLoadingWidget(
        assetPath: 'assets/rive/loading-spinner.riv',
        message: 'Cargando datos...',
      );
    }

    return YourContent();
  }
}
```

### 2. Tarea Completada con Confetti

```dart
Future<void> _completarTarea(String tareaId) async {
  await FirebaseFirestore.instance
    .collection('tareas')
    .doc(tareaId)
    .update({'completada': true});

  // Mostrar confetti
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: SimpleRiveAnimation(
        assetPath: 'assets/rive/confetti.riv',
        width: 300,
        height: 300,
      ),
    ),
  );

  // Auto-cerrar después de 2 segundos
  Future.delayed(Duration(seconds: 2), () {
    if (mounted) Navigator.pop(context);
  });
}
```

### 3. Validación de Formulario

```dart
void _validarFormulario() {
  if (_formKey.currentState!.validate()) {
    // Éxito
    RiveFeedback.showSuccess(
      context,
      'assets/rive/success-check.riv',
      'Formulario válido',
    );
  } else {
    // Error
    RiveFeedback.showError(
      context,
      'assets/rive/error-icon.riv',
      'Por favor completa todos los campos',
    );
  }
}
```

---

## 📋 Checklist de Integración

- [ ] Ir a rive.app/community
- [ ] Descargar al menos 3 animaciones (.riv)
- [ ] Copiar archivos a `assets/rive/`
- [ ] Ejecutar `flutter pub get` (opcional, pero recomendado)
- [ ] Importar `package:pucpflow/widgets/rive_widget.dart` en tus páginas
- [ ] Reemplazar CircularProgressIndicator con RiveLoadingWidget
- [ ] Usar RiveFeedback para success/error
- [ ] Probar en emulador/dispositivo

---

## 🎨 Tips de Diseño

### Tamaños Recomendados

| Tipo de Animación | Tamaño | Uso |
|-------------------|--------|-----|
| Loading Spinner | 80-120px | Centro de pantalla |
| Success/Error | 120-150px | Diálogos de feedback |
| Like Button | 40-60px | Iconos inline |
| Confetti | 200-300px | Celebraciones fullscreen |

### Paleta de Colores

Ya tienes widgets configurados con buenos colores:
- **Success**: Verde `#10B981`
- **Error**: Rojo `#EF4444`
- **Warning**: Amarillo `#FBBF24`
- **Info**: Azul `#2D9BF0`

---

## 🐛 Troubleshooting

### "Unable to load asset"
- Verifica que el archivo esté en `assets/rive/`
- Verifica que el nombre del archivo sea correcto (case-sensitive)
- Reinicia la app completamente

### La animación no se reproduce
- Verifica que hayas usado el widget correcto (`SimpleRiveAnimation` o `RiveInteractiveButton`)
- Verifica que el archivo .riv no esté corrupto (re-descárgalo)

### La app se crashea al usar Rive
- Verifica que `main.dart` tenga `await RiveNative.init()` (ya lo tienes configurado)

---

## 🎉 ¡Listo!

Con esta guía ya puedes:
1. ✅ Descargar animaciones profesionales de Rive
2. ✅ Integrarlas en tu app
3. ✅ Usarlas en casos reales (loading, success, error)
4. ✅ Crear una mejor experiencia de usuario

**Próximo paso**: ¡Descarga tus primeras animaciones y pruébalas!
