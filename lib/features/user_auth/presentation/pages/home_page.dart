// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'calendar_events_page.dart';
import 'desarrolloinicio.dart';
import 'login_page.dart';
import 'revistas.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Cierra sesión en Firebase
      await _googleSignIn.signOut(); // Cierra sesión en Google

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "University Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.deepPurple[700],
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple[700],
              ),
              child: const Text(
                'University Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Revistas'),
              onTap: () {
                // Navegar a la página de 
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RevistasPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navegar a la página de configuración
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _signOut(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenido, ${user?.displayName ?? 'Usuario'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            // Círculos en forma de rombo
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.yellow,
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                    ),
                    SizedBox(width: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // Navegar a otra pantalla si es necesario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DesarrolloInicio(),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                // Botón para acceder al calendario de Google
                GestureDetector(
                  onTap: () {
                    // Navegar a la página del calendario si es necesario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarEventsPage(),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.calendar_today, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ver Calendario de Google",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
