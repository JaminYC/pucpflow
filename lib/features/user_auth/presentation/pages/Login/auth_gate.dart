import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Login/CustomLoginPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
Widget build(BuildContext context) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshotPrefs) {
      if (!snapshotPrefs.hasData) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      final prefs = snapshotPrefs.data!;
      final bool esLoginEmpresarial = prefs.getBool("login_empresarial") ?? false;

      // 🟢 SI ES LOGIN EMPRESARIAL, SALTAR FIREBASE Y MOSTRAR HOME DIRECTO
      if (esLoginEmpresarial) {
        debugPrint("🟢 Acceso por login empresarial");
        return  HomePage();
      }

      // 🔁 Solo si NO es login empresarial, usar FirebaseAuth
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshotFirebase) {
          if (snapshotFirebase.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (snapshotFirebase.hasError) {
            return const Scaffold(
              body: Center(child: Text("Error de autenticación.")),
            );
          }

          final usuarioFirebase = snapshotFirebase.data;

          if (usuarioFirebase != null) {
            debugPrint("🟢 Acceso por Firebase: ${usuarioFirebase.email}");
            return  HomePage();
          }

          debugPrint("🔒 Ningún login detectado, mostrando CustomLoginPage");
          return const CustomLoginPage();
        },
      );
    },
  );
}

}
