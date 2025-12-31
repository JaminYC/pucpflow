# 🎈 Cómo Usar Tu Bubble Button de Rive

¡Tu botón animado ya está integrado y listo para usar! Aquí está todo lo que necesitas saber.

---

## 🎯 Ver el Demo

### Opción 1: Desde HomePage
1. Abre la app
2. En el AppBar (arriba a la derecha) verás un nuevo botón con icono de burbujas 🎈
3. Presiona el botón **"Ver Bubble Button"**
4. ¡Verás tu animación en acción!

### Opción 2: Navegación directa desde código
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const BubbleButtonDemo()),
);
```

---

## 📦 Tu Archivo

**Nombre del archivo:** `24900-46503-bubble-button.riv`
**Ubicación:** `assets/rive/24900-46503-bubble-button.riv`
**Estado:** ✅ Configurado en pubspec.yaml
**Rive versión:** 0.14.0

---

## 💻 Cómo Usar en Tu Código

### Método 1: Botón Interactivo (Recomendado)

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

// En tu build method:
RiveInteractiveButton(
  assetPath: 'assets/rive/24900-46503-bubble-button.riv',
  onPressed: () {
    print('¡Botón presionado!');
    // Tu código aquí
  },
  width: 120,
  height: 120,
)
```

### Método 2: Solo Mostrar la Animación

```dart
import 'package:pucpflow/widgets/rive_widget.dart';

SimpleRiveAnimation(
  assetPath: 'assets/rive/24900-46503-bubble-button.riv',
  width: 100,
  height: 100,
)
```

---

## 🎨 Ejemplos de Uso

### 1. Como Botón de Acción Principal

```dart
Center(
  child: RiveInteractiveButton(
    assetPath: 'assets/rive/24900-46503-bubble-button.riv',
    onPressed: () {
      // Crear nuevo proyecto
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CrearProyectoPage()),
      );
    },
    width: 150,
    height: 150,
  ),
)
```

### 2. Como Botón de Like/Favorito

```dart
RiveInteractiveButton(
  assetPath: 'assets/rive/24900-46503-bubble-button.riv',
  onPressed: () {
    // Marcar como favorito
    setState(() {
      isFavorite = !isFavorite;
    });
  },
  width: 60,
  height: 60,
)
```

### 3. Como Botón de Completar Tarea

```dart
RiveInteractiveButton(
  assetPath: 'assets/rive/24900-46503-bubble-button.riv',
  onPressed: () async {
    // Marcar tarea como completada
    await _marcarTareaCompletada(tarea);
    _mostrarMensajeExito();
  },
  width: 80,
  height: 80,
)
```

### 4. Dentro de una Card

```dart
Card(
  child: Column(
    children: [
      Text('Mi Proyecto'),
      Text('Descripción...'),
      RiveInteractiveButton(
        assetPath: 'assets/rive/24900-46503-bubble-button.riv',
        onPressed: () => _verDetalles(),
        width: 100,
        height: 100,
      ),
    ],
  ),
)
```

---

## 🎛️ Parámetros Disponibles

### RiveInteractiveButton

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `assetPath` | String | ✅ Sí | Ruta al archivo .riv |
| `onPressed` | VoidCallback | ✅ Sí | Función al presionar |
| `width` | double? | ❌ No | Ancho (default: 64) |
| `height` | double? | ❌ No | Alto (default: 64) |
| `fit` | Fit | ❌ No | Ajuste (default: Fit.contain) |

### SimpleRiveAnimation

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `assetPath` | String | ✅ Sí | Ruta al archivo .riv |
| `width` | double? | ❌ No | Ancho |
| `height` | double? | ❌ No | Alto |
| `fit` | Fit | ❌ No | Ajuste (default: Fit.contain) |
| `alignment` | Alignment | ❌ No | Alineación (default: center) |

---

## 📐 Tamaños Recomendados

| Uso | Tamaño | Ejemplo |
|-----|--------|---------|
| Botón pequeño (icono) | 40x40 - 60x60 | Botón de like, favorito |
| Botón mediano (card) | 80x80 - 120x120 | Acciones en tarjetas |
| Botón grande (principal) | 150x150 - 200x200 | CTA principal, hero button |
| Botón gigante (landing) | 250x250 - 300x300 | Landing page |

---

## 🎯 Ideas de Dónde Usarlo

### En HomePage
- ✅ Botón para crear nueva tarea
- ✅ Botón para acceder a proyectos
- ✅ Botón de acción flotante (FAB)

### En ProyectosPage
- ✅ Botón para crear nuevo proyecto
- ✅ Botón de like en cada proyecto
- ✅ Botón de compartir

### En TareasPage
- ✅ Botón para marcar tarea como completada
- ✅ Botón para agregar nueva tarea
- ✅ Botón de favorito

### En Perfil
- ✅ Botón para editar perfil
- ✅ Botón para compartir perfil
- ✅ Botón de configuración

---

## 🔥 Ejemplo Completo: Integrar en HomePage

```dart
// En home_page.dart

// 1. Importar
import 'package:pucpflow/widgets/rive_widget.dart';

// 2. Agregar en el build (por ejemplo, como FAB)
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Home')),
    body: _tuContenido(),

    // FAB con tu botón animado
    floatingActionButton: RiveInteractiveButton(
      assetPath: 'assets/rive/24900-46503-bubble-button.riv',
      onPressed: () {
        // Mostrar diálogo para crear tarea
        _mostrarDialogoCrearTarea();
      },
      width: 80,
      height: 80,
    ),
  );
}
```

---

## 📥 Descargar Más Animaciones

¿Quieres más botones animados? Visita:

1. **Rive Community**: https://rive.app/community
2. Busca: "button", "like", "click", "tap"
3. Descarga el archivo `.riv`
4. Coloca en `assets/rive/`
5. Usa con `SimpleRiveAnimation` o `RiveInteractiveButton`

### Animaciones Recomendadas:
- **Like Button** - Para favoritos
- **Success Button** - Para completar tareas
- **Loading Button** - Para acciones con espera
- **Add Button** - Para crear nuevo contenido
- **Share Button** - Para compartir
- **Settings Button** - Para configuración

---

## 🐛 Solución de Problemas

### El botón no se muestra
- ✅ Verifica que el archivo esté en `assets/rive/`
- ✅ Verifica que `pubspec.yaml` tenga `- assets/rive/`
- ✅ Ejecuta `flutter pub get`
- ✅ Reinicia la app completamente

### La animación se ve cortada
- Ajusta el parámetro `fit`:
  ```dart
  fit: Fit.contain  // Mantiene proporciones
  fit: Fit.cover    // Cubre todo el espacio
  fit: Fit.fill     // Estira para llenar
  ```

### El botón no responde al click
- Verifica que estés usando `RiveInteractiveButton` (no `SimpleRiveAnimation`)
- Verifica que `onPressed` tenga código

---

## 📚 Recursos

- **Página de Demo**: `lib/demo/bubble_button_demo.dart`
- **Widget Helper**: `lib/widgets/rive_widget.dart`
- **Guía Completa**: `GUIA_RIVE_0.14_ACTUALIZADA.md`
- **Documentación Rive**: https://rive.app/docs

---

## 🎉 ¡Listo!

Tu botón animado está completamente integrado y listo para usar.

**Para verlo en acción:**
1. Corre la app: `flutter run`
2. Ve a HomePage
3. Presiona el botón de burbujas 🎈 en el AppBar
4. ¡Disfruta tu animación!

**Para usarlo en tu código:**
```dart
import 'package:pucpflow/widgets/rive_widget.dart';

RiveInteractiveButton(
  assetPath: 'assets/rive/24900-46503-bubble-button.riv',
  onPressed: () => print('Click!'),
  width: 120,
  height: 120,
)
```

¡A crear UIs increíbles! 🚀
