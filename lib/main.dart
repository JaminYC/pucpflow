
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Authentication
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core para inicializar Firebase
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

import 'package:webview_flutter/webview_flutter.dart' as webview;

import 'package:webview_flutter_android/webview_flutter_android.dart'; // SurfaceAndroidWebView ✅

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';


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
  }

  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false, // Oculta el banner de "Debug"
    title: 'FLOW',
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
    home: const SplashScreen(),   
    routes: {
      '/home': (context) => HomePage(),
      '/login': (context) => const CustomLoginPage(),
      '/signUp': (context) => const SignUpPage(),
      '/proyectos': (context) =>  ProyectosPage(),
    },

  );
}

}
