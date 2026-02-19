
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Authentication
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core para inicializar Firebase
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Permite detectar la plataforma (Web o Móvil)
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Para manejar variables de entorno
import 'package:intl/date_symbol_data_local.dart'; // Para manejar formatos de fecha en diferentes idiomas
import 'package:pucpflow/features/app/splash_screen/splash_screen.dart'; // Importa la pantalla de Splash
import 'package:pucpflow/features/user_auth/presentation/pages/Login/CustomLoginPage.dart'; // Página de login personalizada
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart'; // Página principal luego del login
import 'package:pucpflow/features/user_auth/presentation/pages/login_page.dart'; // Otra opción de página de login
import 'package:pucpflow/features/user_auth/presentation/pages/Login/sign_up_page.dart'; // Página de registro
import 'package:pucpflow/features/user_auth/presentation/pages/proyectos/ProyectosPage.dart';
import 'package:pucpflow/LandingPage/VastoriaMainLanding.dart'; // Landing principal del ecosistema con SSO
import 'package:pucpflow/Cafillari/screens/home/CafillariHomePage.dart'; // Cafillari - IoT para cafetales
import 'package:provider/provider.dart';
import 'package:pucpflow/providers/theme_provider.dart';
import 'package:pucpflow/utils/notification_service.dart';

import 'package:webview_flutter/webview_flutter.dart' as webview;
import 'package:webview_flutter_android/webview_flutter_android.dart'; // SurfaceAndroidWebView ✅

// 🔹 Configuración de Firebase para Web
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyBNXEkHOWBqRnojN9pkXVJKCQZDgY6wkTE",
  authDomain: "pucp-flow.firebaseapp.com",
  projectId: "pucp-flow",
  storageBucket: "pucp-flow.firebasestorage.app",
  messagingSenderId: "547054267025",
  appId: "1:547054267025:web:eaa1dcee42475981d8ed30",
  measurementId: "G-FKF059M50",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseOptions);
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL); // 🔐 importante para mantener sesión
  } else {
    await Firebase.initializeApp();
    // Registrar handler de notificaciones background (solo móvil)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Detecta qué aplicación mostrar según el subdominio (solo en Web)
  Widget _getInitialPage() {
    if (kIsWeb) {
      final currentUrl = Uri.base.host.toLowerCase();

      // Detectar subdominio
      if (currentUrl.contains('flow.')) {
        // flow.teamvastoria.com → App Flow
        return const SplashScreen();
      } else if (currentUrl == 'teamvastoria.com' || currentUrl == 'www.teamvastoria.com') {
        // teamvastoria.com → Landing del ecosistema
        return const VastoriaMainLanding();
      } else if (currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1')) {
        // Desarrollo local → App Flow por defecto
        return const SplashScreen();
      } else {
        // Cualquier otro subdominio → Landing por defecto
        return const VastoriaMainLanding();
      }
    } else {
      // En móvil, siempre mostrar Flow
      return const SplashScreen();
    }
  }

@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta el banner de "Debug"
      title: kIsWeb && Uri.base.host.contains('flow.')
          ? 'Flow - Gestión de Proyectos | Vastoria'
          : 'Vastoria - Ecosistema de Soluciones',
      theme: ThemeData(
      fontFamily: 'Poppins', // 🔥 Aplica Poppins a toda la app
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed, // ← clave para aplicar fondo negro bien
        ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      // Puedes agregar más personalizaciones si deseas
    ),
    home: _getInitialPage(),
    routes: {
      // 🌐 Ecosistema Vastoria
      '/ecosystem': (context) => const VastoriaMainLanding(),

      // 🍅 FLOW - Gestión de Proyectos
      '/flow': (context) => const SplashScreen(), // Entry point de Flow
      '/flow/login': (context) => const CustomLoginPage(),
      '/flow/signup': (context) => const SignUpPage(),
      '/flow/home': (context) => HomePage(),
      '/flow/proyectos': (context) => ProyectosPage(),

      // ☕ CAFILLARI - IoT para Cafetales (acceso sin login)
      '/cafillari': (context) => const CafillariHomePage(),

      // ⚠️ Rutas legacy (mantener por compatibilidad)
      '/home': (context) => HomePage(),
      '/login': (context) => const CustomLoginPage(),
      '/signUp': (context) => const SignUpPage(),
      '/proyectos': (context) => ProyectosPage(),
    },
   ),
  );
}

}
