# ⚡ Inicio Rápido: Integrar Rive en 5 Minutos

## 🎯 3 Pasos Simples

### 1️⃣ Descarga (2 min)

Ve a https://rive.app/community y busca **"loading spinner"**

Descarga el archivo `.riv` y guárdalo en:
```
c:\Users\User\pucpflow\assets\rive\loading-spinner.riv
```

### 2️⃣ Importa (10 seg)

En cualquier archivo donde quieras usar Rive:
```dart
import 'package:pucpflow/widgets/rive_helpers.dart';
```

### 3️⃣ Usa (1 min)

Reemplaza tu loading actual:

**ANTES:**
```dart
if (isLoading) {
  return CircularProgressIndicator();
}
```

**DESPUÉS:**
```dart
if (isLoading) {
  return RiveFullscreenLoading(
    message: 'Cargando datos...',
  );
}
```

---

## 🎨 Más Ejemplos Rápidos

### Success Message
```dart
await RiveSuccessDialog.show(
  context,
  message: '¡Guardado exitosamente!',
);
```

### Error Message
```dart
await RiveErrorDialog.show(
  context,
  message: 'Error al conectar',
);
```

### Todo Automático
```dart
await RiveAsyncOperation.execute(
  context: context,
  loadingMessage: 'Guardando...',
  successMessage: '¡Listo!',
  operation: () async {
    // Tu código aquí
  },
);
```

---

## 📚 Documentación Completa

Para más detalles, lee:
- [COMO_INTEGRAR_RIVE_COMPLETO.md](COMO_INTEGRAR_RIVE_COMPLETO.md) - Guía completa
- [GUIA_DESCARGA_RIVE.md](GUIA_DESCARGA_RIVE.md) - Cómo descargar animaciones

---

## 🚀 Ver Ejemplos Funcionando

Corre la app y navega a:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const RiveIntegrationExamples(),
  ),
);
```

**¡Listo!** 🎉 Ya sabes cómo usar Rive en tu app.
