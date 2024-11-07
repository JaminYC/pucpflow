import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/app/splash_screen/splash_screen.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/home_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/login_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/sign_up_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PUCP-FLOW',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signUp': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
      home: const SplashScreen(), // Modificamos para que SplashScreen verifique el estado del usuario
    );
  }
}
