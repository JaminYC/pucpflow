# Configuración del Ecosistema Vastoria

## Visión General

Vastoria es el ecosistema madre que contiene múltiples aplicaciones especializadas:

```
teamvastoria.com                    → Landing principal del ecosistema
├── flow.teamvastoria.com          → PUCPFLOW (Gestión de Proyectos con IA)
├── cafillari.teamvastoria.com     → Cafillari (IoT para Cafetales)
├── vitakua.teamvastoria.com       → FlowVitakua (Gestión de Agua)
└── innova.teamvastoria.com        → Innova (Innovación Empresarial)
```

---

## Paso 1: Configuración de Dominios en Firebase Hosting

### 1.1 Dominio Principal (teamvastoria.com)

```bash
# En la consola de Firebase
firebase hosting:channel:deploy production --only hosting:vastoria

# Configurar dominio personalizado
# Firebase Console → Hosting → Add custom domain
# Dominio: teamvastoria.com
```

### 1.2 Subdominios de Aplicaciones

Para cada subdominio, necesitas configurar un nuevo sitio en Firebase Hosting:

```bash
# Crear sitios adicionales en Firebase
firebase hosting:sites:create flow-vastoria
firebase hosting:sites:create cafillari-vastoria
firebase hosting:sites:create vitakua-vastoria
firebase hosting:sites:create innova-vastoria
```

### 1.3 Actualizar firebase.json

Crea o actualiza el archivo `firebase.json` en la raíz del proyecto:

```json
{
  "hosting": [
    {
      "site": "vastoria",
      "public": "build/web",
      "target": "vastoria",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "site": "flow-vastoria",
      "public": "build/web",
      "target": "flow",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "site": "cafillari-vastoria",
      "public": "build/web",
      "target": "cafillari",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "site": "vitakua-vastoria",
      "public": "build/web",
      "target": "vitakua",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "site": "innova-vastoria",
      "public": "build/web",
      "target": "innova",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ],
  "functions": {
    "source": "functions"
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

---

## Paso 2: Configuración de DNS en teamvastoria.com

En tu proveedor de DNS (donde compraste teamvastoria.com):

### Registros DNS necesarios:

```
Tipo    Nombre              Valor                           TTL
A       @                   [IP de Firebase Hosting]        3600
A       flow                [IP de Firebase Hosting]        3600
A       cafillari           [IP de Firebase Hosting]        3600
A       vitakua             [IP de Firebase Hosting]        3600
A       innova              [IP de Firebase Hosting]        3600
CNAME   www                 teamvastoria.com                3600
```

**Nota:** Las IPs de Firebase Hosting las obtienes desde la consola de Firebase al configurar cada dominio personalizado.

---

## Paso 3: Actualizar Rutas en la Aplicación Flutter

### 3.1 Modificar main.dart

Actualiza `lib/main.dart` para detectar el subdominio y mostrar la app correspondiente:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/LandingPage/VastoriaEcosystemLanding.dart';
import 'package:pucpflow/features/app/splash_screen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase...

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _getInitialPage() {
    if (kIsWeb) {
      final currentUrl = Uri.base.host;

      // Detectar qué subdominio es
      if (currentUrl.contains('flow.')) {
        return const SplashScreen(); // App Flow
      } else if (currentUrl.contains('cafillari.')) {
        return const CafillariHomePage(); // App Cafillari
      } else if (currentUrl.contains('vitakua.')) {
        return const VitakuaHomePage(); // App Vitakua
      } else if (currentUrl.contains('innova.')) {
        return const WorkflowMockupPage(); // App Innova
      } else {
        // teamvastoria.com → Landing principal
        return const VastoriaEcosystemLanding();
      }
    } else {
      // En móvil, siempre mostrar Flow por defecto
      return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vastoria',
      theme: ThemeData(
        fontFamily: 'Poppins',
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: _getInitialPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => const CustomLoginPage(),
        '/signUp': (context) => const SignUpPage(),
        '/proyectos': (context) => ProyectosPage(),
        '/ecosystem': (context) => const VastoriaEcosystemLanding(),
      },
    );
  }
}
```

---

## Paso 4: Build y Deploy

### 4.1 Build para Web

```bash
# Build optimizado para producción
flutter build web --release --web-renderer html

# Para mejor performance en navegadores modernos:
flutter build web --release --web-renderer canvaskit
```

### 4.2 Deploy a Firebase Hosting

```bash
# Deploy del landing principal (teamvastoria.com)
firebase deploy --only hosting:vastoria

# Deploy de Flow (flow.teamvastoria.com)
firebase deploy --only hosting:flow

# Deploy de Cafillari (cafillari.teamvastoria.com)
firebase deploy --only hosting:cafillari

# Deploy de Vitakua (vitakua.teamvastoria.com)
firebase deploy --only hosting:vitakua

# Deploy de Innova (innova.teamvastoria.com)
firebase deploy --only hosting:innova

# O deploy de todo a la vez:
firebase deploy --only hosting
```

---

## Paso 5: Usar VastoriaAppBar en las Páginas

Para mostrar el branding de Vastoria en todas las páginas:

```dart
import 'package:pucpflow/core/widgets/vastoria_app_bar.dart';

class MiPagina extends StatelessWidget {
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
}
```

---

## Paso 6: Verificación

### 6.1 Verificar Dominios

Después del deploy, verifica que todos los dominios funcionen:

- ✅ https://teamvastoria.com → Landing del ecosistema
- ✅ https://flow.teamvastoria.com → Login de Flow
- ✅ https://cafillari.teamvastoria.com → (Próximamente)
- ✅ https://vitakua.teamvastoria.com → (Próximamente)
- ✅ https://innova.teamvastoria.com → (Próximamente)

### 6.2 Verificar SSL

Firebase Hosting automáticamente provisiona certificados SSL. Verifica que:

- Todos los dominios redirijan HTTP → HTTPS
- No haya advertencias de certificado
- El candado verde aparezca en el navegador

---

## Paso 7: SEO y Metadata

### 7.1 Actualizar index.html

Actualiza `web/index.html` para cada app:

```html
<!-- Para Flow -->
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Flow - Gestión de Proyectos con IA | Vastoria</title>
  <meta name="description" content="Flow es parte del ecosistema Vastoria. Gestiona proyectos, tareas y equipos con inteligencia artificial.">
  <meta property="og:title" content="Flow - Vastoria">
  <meta property="og:description" content="Gestión de Proyectos con IA">
  <meta property="og:image" content="/assets/logo.jpg">
  <meta property="og:url" content="https://flow.teamvastoria.com">
</head>

<!-- Para Landing Principal -->
<head>
  <title>Vastoria - Ecosistema de Soluciones Inteligentes</title>
  <meta name="description" content="Vastoria es un ecosistema de aplicaciones inteligentes: Flow, Cafillari, Vitakua e Innova.">
</head>
```

---

## Estructura de Archivos Recomendada

```
pucpflow/
├── lib/
│   ├── core/
│   │   └── widgets/
│   │       ├── vastoria_app_bar.dart
│   │       └── vastoria_footer.dart
│   ├── LandingPage/
│   │   ├── VastoriaEcosystemLanding.dart
│   │   └── CustomLandingPage.dart
│   ├── features/
│   │   ├── user_auth/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           ├── Login/
│   │   │           │   └── CustomLoginPage.dart
│   │   │           └── ...
│   ├── Cafillari/
│   ├── FlowVitakua/
│   └── main.dart
├── web/
│   ├── index.html
│   ├── favicon.png
│   └── manifest.json
├── firebase.json
└── VASTORIA_ECOSYSTEM_SETUP.md
```

---

## Comandos Rápidos

```bash
# Build y deploy rápido (todo)
flutter build web --release && firebase deploy --only hosting

# Ver logs de hosting
firebase hosting:channel:list

# Rollback si algo sale mal
firebase hosting:clone SITE_ID:SOURCE_CHANNEL SITE_ID:DEST_CHANNEL
```

---

## Soporte y Documentación

- **Firebase Hosting:** https://firebase.google.com/docs/hosting
- **Flutter Web:** https://flutter.dev/web
- **DNS Configuration:** Consultar proveedor de dominio

---

## Notas Importantes

1. **Cache:** Firebase Hosting cachea agresivamente. Para forzar actualización:
   - Incrementa la versión en `pubspec.yaml`
   - Cambia el nombre de archivos estáticos
   - Usa parámetros de query: `?v=2`

2. **Performance:** Para mejor performance en web:
   - Usa `--web-renderer canvaskit` para gráficos complejos
   - Usa `--web-renderer html` para apps más ligeras
   - Implementa lazy loading de rutas

3. **Analytics:** Considera agregar Firebase Analytics para trackear:
   - Visitas por subdominio
   - Navegación entre apps
   - Conversión de landing → login

---

**Última actualización:** 2025-01-15
