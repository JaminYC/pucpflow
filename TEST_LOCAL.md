# Guía de Pruebas Locales - Ecosistema Vastoria

## 🧪 Cómo Probar los Cambios Localmente

### 1. Probar la App Flow (Normal)

```bash
# Ejecutar en Chrome
flutter run -d chrome

# O en Windows/macOS/Linux
flutter run -d windows  # macOS: macos, Linux: linux
```

**Resultado esperado:**
- ✅ Debería mostrar el **SplashScreen** de Flow
- ✅ Luego el **Login** con el nuevo branding:
  - "COMUNIDAD VASTORIA" arriba
  - "FLOW" como título grande
  - Footer con "Parte del ecosistema VASTORIA"

---

### 2. Probar la Landing Page del Ecosistema

**Opción A: Modificar temporalmente main.dart**

```dart
// En lib/main.dart, línea ~62
Widget _getInitialPage() {
  if (kIsWeb) {
    // COMENTAR LA DETECCIÓN NORMAL
    // final currentUrl = Uri.base.host.toLowerCase();
    // ...

    // FORZAR LANDING PAGE TEMPORALMENTE
    return const VastoriaEcosystemLanding();
  }
  // ...
}
```

Luego ejecutar:
```bash
flutter run -d chrome
```

**Opción B: Agregar ruta de prueba**

Agregar botón temporal en HomePage:

```dart
// En HomePage
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/ecosystem');
  },
  child: Text('Ver Landing Vastoria'),
)
```

---

### 3. Probar VastoriaAppBar

**Paso 1:** Agregar a cualquier página (ej. ProyectosPage.dart)

```dart
import 'package:pucpflow/core/widgets/vastoria_app_bar.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: VastoriaAppBar(
      appName: 'Flow',
      subtitle: 'Proyectos',
      showEcosystemMenu: true,
    ),
    body: ...,
  );
}
```

**Paso 2:** Ejecutar app y verificar:
- ✅ Logo pequeño de Vastoria a la izquierda
- ✅ Texto "VASTORIA • FLOW"
- ✅ Menú de apps (ícono de apps) a la derecha
- ✅ Al hacer clic en el menú, muestra lista de apps

---

### 4. Probar VastoriaFooter

**Paso 1:** Agregar a cualquier página

```dart
import 'package:pucpflow/core/widgets/vastoria_footer.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        Expanded(child: Center(child: Text('Contenido'))),
        VastoriaFooter(),
      ],
    ),
  );
}
```

**Paso 2:** Verificar:
- ✅ Footer con texto "Parte del ecosistema VASTORIA"
- ✅ Copyright © 2025
- ✅ Al hacer clic en "VASTORIA", intenta abrir teamvastoria.com

---

## 📱 Probar en Diferentes Plataformas

### Web (Chrome)
```bash
flutter run -d chrome
```

### Windows Desktop
```bash
flutter run -d windows
```

### Android (Emulador)
```bash
flutter run -d emulator
```

### iOS (Simulador - solo en Mac)
```bash
flutter run -d simulator
```

---

## 🎨 Checklist Visual

### Login Page
- [ ] Header "COMUNIDAD VASTORIA" visible
- [ ] Título "FLOW" grande y blanco
- [ ] Subtítulo "Gestión de Proyectos con IA"
- [ ] Logo circular de Vastoria
- [ ] Footer con "Parte del ecosistema VASTORIA"
- [ ] Video de fondo se reproduce
- [ ] Botón "INGRESAR" funciona

### Landing Page del Ecosistema
- [ ] Logo grande de Vastoria arriba
- [ ] Título "VASTORIA" en grande
- [ ] Subtítulo "Ecosistema de Soluciones Inteligentes"
- [ ] 4 cards de apps visibles:
  - [ ] Flow (con botón "Acceder")
  - [ ] Cafillari (con "Próximamente")
  - [ ] Vitakua (con "Próximamente")
  - [ ] Innova (con "Próximamente")
- [ ] Sección "POR QUÉ VASTORIA" con 4 features
- [ ] Footer completo
- [ ] Scroll funciona correctamente
- [ ] Responsive en diferentes tamaños de pantalla

### VastoriaAppBar
- [ ] Logo pequeño visible (32x32)
- [ ] Texto "VASTORIA • FLOW" correcto
- [ ] Ícono de menú (apps) visible
- [ ] Al hacer clic en menú:
  - [ ] Se abre popup
  - [ ] Muestra 4 apps con descripciones
  - [ ] Muestra "Ver todas las apps"
  - [ ] Cada item tiene ícono apropiado

### VastoriaFooter
- [ ] Texto centrado
- [ ] Link "VASTORIA" subrayado
- [ ] Copyright con año correcto
- [ ] Colores apropiados

---

## 🐛 Troubleshooting

### Error: "Cannot find VastoriaEcosystemLanding"

**Solución:**
```bash
# Verificar que el archivo existe
ls lib/LandingPage/VastoriaEcosystemLanding.dart

# Ejecutar pub get
flutter pub get

# Clean y rebuild
flutter clean
flutter run -d chrome
```

### Error: "Cannot find vastoria_app_bar"

**Solución:**
```bash
# Verificar que la carpeta core/widgets existe
ls lib/core/widgets/

# Si no existe, crearla
mkdir -p lib/core/widgets

# Asegurar que los archivos están ahí
ls lib/core/widgets/vastoria_app_bar.dart
ls lib/core/widgets/vastoria_footer.dart

# Pub get y rebuild
flutter pub get
flutter clean
flutter run -d chrome
```

### Error: "Asset not found: assets/logovastoria.png"

**Solución temporal:**

El componente ya tiene manejo de error. Si no hay logo, mostrará un ícono por defecto.

**Solución permanente:**

Agregar el logo a `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/logovastoria.png
    # ... otros assets
```

Y colocar el archivo en `assets/logovastoria.png`

### Landing no se ve bien en móvil

**Esto es esperado.** La landing está optimizada para web. Para móvil, siempre se muestra Flow directamente.

### Menú de apps no abre URLs

**En desarrollo local**, los links a subdominios no funcionarán porque no existen localmente. Esto es normal. Funcionará correctamente una vez deployado en Firebase Hosting con dominios reales.

---

## 🔍 Inspeccionar en DevTools

### Ver logs de detección de subdominio

```dart
// Temporalmente agregar en main.dart _getInitialPage()
print('🌐 Current URL: ${Uri.base.host}');
print('📍 Showing: Landing or Flow?');
```

Luego en la consola de Flutter verás:
```
🌐 Current URL: localhost:12345
📍 Showing: Landing or Flow?
```

---

## 📊 Tabla de Compatibilidad

| Componente               | Web | Windows | macOS | Linux | Android | iOS |
|--------------------------|-----|---------|-------|-------|---------|-----|
| VastoriaAppBar          | ✅  | ✅      | ✅    | ✅    | ✅      | ✅  |
| VastoriaFooter          | ✅  | ✅      | ✅    | ✅    | ✅      | ✅  |
| Landing Page            | ✅  | ✅      | ✅    | ✅    | ⚠️*     | ⚠️* |
| Login actualizado       | ✅  | ✅      | ✅    | ✅    | ✅      | ✅  |
| Detección de subdominio | ✅  | ❌      | ❌    | ❌    | ❌      | ❌  |

**⚠️ Landing en móvil:** Se puede ver, pero no es el flujo principal. En móvil siempre se muestra Flow.

---

## 🎬 Demo Paso a Paso

### Escenario 1: Usuario nuevo en Web

1. Usuario visita `https://teamvastoria.com`
2. Ve landing page del ecosistema
3. Hace clic en card "Flow"
4. Redirige a `https://flow.teamvastoria.com`
5. Ve login con branding "COMUNIDAD VASTORIA"
6. Inicia sesión
7. Llega a HomePage de Flow
8. Hace clic en menú de apps (AppBar)
9. Puede navegar a otras apps del ecosistema

### Escenario 2: Usuario existente directo a Flow

1. Usuario visita directamente `https://flow.teamvastoria.com`
2. Ve login con branding
3. Inicia sesión
4. Usa la app normalmente

### Escenario 3: Usuario en móvil

1. Usuario abre app en Android/iOS
2. Ve SplashScreen de Flow
3. Luego login con branding
4. Usa Flow normalmente
5. (No ve landing del ecosistema, no es necesario)

---

## 🚀 Siguiente Paso: Deploy Real

Una vez que hayas probado todo localmente y esté funcionando:

1. Seguir guía en `VASTORIA_ECOSYSTEM_SETUP.md`
2. Configurar Firebase Hosting
3. Configurar DNS
4. Build para producción
5. Deploy
6. Verificar en URLs reales

---

## 📞 Soporte

Si algo no funciona:

1. Verificar logs de consola
2. Ejecutar `flutter doctor`
3. Revisar que todos los archivos nuevos existan
4. Ejecutar `flutter clean && flutter pub get`
5. Revisar errores de importación

---

**¡Listo para probar!** 🎉

Ejecuta `flutter run -d chrome` y verifica que el login muestre el nuevo branding de Vastoria.
