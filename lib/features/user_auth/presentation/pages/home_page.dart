// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables 

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/CustomLoginPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/DashboardPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/UserProfileForm.dart';
import 'dart:io';
import 'Dashboard.dart';
import 'HealthPage.dart';
import 'PomodoroPage.dart';
import 'calendar_events_page.dart';
import 'desarrolloinicio.dart';
import 'login_page.dart';
import 'profile_preferences_page.dart';
import 'revistas.dart';  
import 'SocialPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Ranking/RankingPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Alerta/AlertPage.dart'; 

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isDarkMode = false; // Variable para alternar entre modo oscuro y claro
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late AnimationController _controller;
  bool isControllerInitialized = false; // Nueva bandera para evitar problemas

  int _selectedIndex = 0; // Índice para la barra de navegación inferior


  String? userProfilePhoto;
  File? _profileImage; // Imagen seleccionada del perfil

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeController();
    userProfilePhoto = FirebaseAuth.instance.currentUser?.photoURL;
  }

  void _initializeController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Animación de pulso
    setState(() {
      isControllerInitialized = true;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    if (isControllerInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Cierra sesión en Firebase
      await _googleSignIn.signOut(); // Cierra sesión en Google

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomLoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (!isControllerInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Indicador de carga mientras se inicializa
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flow Start",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2D64B),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
              color: Colors.black, // El color del ícono siempre será negro
            ),
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
                color: const Color(0xFF1C1C1E), // Fondo oscuro para mejor contraste
              ),
              child: const Text(
                'Herramientas',
                style: TextStyle(
                  color: Color(0xFFF2D64B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold, // Resalta el texto
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.data_usage_rounded, color: Color.fromARGB(255, 0, 0, 0)),
              title: const Text(
                'Preferencias',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Color del texto cambiado a dorado
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardVisual(      
                      userId: FirebaseAuth.instance.currentUser!.uid, // Usa el UID autenticado
    ),
                    
                  ),
                );

              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color.fromARGB(255, 0, 0, 0)),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Mismo ajuste de color
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFF2D64B)),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0), // Mismo ajuste de color
                ),
              ),
              onTap: () {
                _signOut(context);
              },
            ),
          ],
        ),  
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PomodoroPage(),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: Icon(Icons.timer, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

    body: _selectedIndex == 1
      ? const RankingPage() // ✅ Página de Rankings
      : _selectedIndex == 2
        ? const AlertPage() // ✅ Página de Alertas
        : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.grey.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarEventsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: const Color(0xFFF2D64B), // Color del texto
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Ver Calendario",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido, ${user?.displayName ?? 'Usuario'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF2D64B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage, // Seleccionar imagen desde la galería
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.black,
                            Color(0xFFF2D64B),
                          ],
                          stops: [0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (userProfilePhoto != null
                                  ? NetworkImage(userProfilePhoto!) as ImageProvider
                                  : null),
                          child: _profileImage == null && userProfilePhoto == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: const Color(0xFFF2D64B),
                                )
                              : null,
                          backgroundColor: const Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // Botón superior
                    Positioned(
                      top: 60,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SocialPage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.pink, // Color asociado al ámbito social
                          child: Icon(Icons.group, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    // Botón izquierdo
                    Positioned(
                      left: 40,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DesarrolloInicio(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue, // Azul para desarrollo de proyectos
                          child: Icon(Icons.settings, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    // Botón derecho
                    Positioned(
                      right: 40,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RevistasPage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.orange, // Naranja para curiosidad
                          child: Icon(Icons.library_books, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    // Botón inferior 
                    Positioned(
                      bottom: 30,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HealthPage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.green, // Verde para salud
                          child: Icon(Icons.health_and_safety, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF000000),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, color: Color(0xFFF2D64B)),
            label: 'Tablero',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard, color: Color(0xFFF2D64B)),
            label: 'Rankings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Color(0xFFF2D64B)),
            label: 'Alertas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFF2D64B),
        onTap: _onItemTapped, // ✅ Ya está correcto
      ),

    );
  }
}
