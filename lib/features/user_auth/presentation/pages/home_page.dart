// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'calendar_events_page.dart';
import 'desarrolloinicio.dart';
import 'interactive_map_page.dart';
import 'login_page.dart';
import 'revistas.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = false; // Variable para alternar entre modo oscuro y claro
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
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode; // Alterna entre modo oscuro y claro
              });
            },
          ),
        ],
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
                _signOut(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: isDarkMode ? Colors.black : Colors.white, // Fondo dinámico
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido, ${user?.displayName ?? 'Usuario'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.deepPurple, // Color dinámico del texto
                ),
              ),
              const SizedBox(height: 20),
              // Círculos en forma de rombo
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InteractiveMapPage(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.yellow,
                    ),
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
                        backgroundColor: Color.fromARGB(255, 111, 111, 105),
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
      ),
    );
  }
}
