// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa FirebaseAuth para logout
import 'revistas.dart'; // Importa la pantalla de revistas
import 'desarrolloinicio.dart'; // Importa la pantalla desarrolloinicio
import 'calendar_events_page.dart'; // Importa la pantalla de eventos del calendario
import 'login_page.dart'; // Importa la página de Login para redirigir después del logout

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Cierra la sesión de Firebase
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Navega a la pantalla de login
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtén el usuario actual
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "University Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.deepPurple[700],
        elevation: 0,
        actions: [
          // Mostrar el correo y nombre del usuario autenticado
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.displayName ?? 'Usuario',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  user?.email ?? 'Correo no disponible',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
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
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _signOut(context); // Llama a la función de cierre de sesión
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido al University Dashboard",
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Selecciona una opción:",
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
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
