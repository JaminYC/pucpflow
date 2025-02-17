// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/AsistentePage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/CustomLoginPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/DashboardPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/EmotionalForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/IntellectualForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/profile_forms_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/UserProfileForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';
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
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart';


import 'dashboard.dart';


class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  bool _isLoading = true;
  bool isDarkMode = false;
  int _selectedIndex = 0;
  File? _profileImage;
  String? userProfilePhoto;
  String? userName;
  int totalTareas = 0;
  int tareasCompletadas = 0;
  int tareasPendientes = 0;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarTareasUsuario();
    _sincronizarTareasConCalendario(); // ✅ Ahora sí la encuentra
    _escucharCambiosEnTareas();
  }
Future<void> _sincronizarTareasConCalendario() async {
  final userId = _auth.currentUser!.uid;
  final calendarApi = await _calendarService.signInAndGetCalendarApi();

  if (calendarApi == null) return;

  final querySnapshot = await _firestore.collection("proyectos").get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    List<dynamic> tareas = data["tareas"] ?? [];

    for (var tareaJson in tareas) {
      final tarea = Tarea.fromJson(tareaJson);

      if (tarea.responsable == userId) {
        // 🔹 Verificar si la tarea ya existe en Google Calendar antes de agregarla
        bool existeEnCalendario = await _calendarService.verificarTareaEnCalendario(calendarApi, tarea);

        if (!existeEnCalendario) {
          await _calendarService.agendarEventoEnCalendario(calendarApi, tarea);
          print("✅ Tarea '${tarea.titulo}' sincronizada con Google Calendar de $userId");
        } else {
          print("⚠️ La tarea '${tarea.titulo}' ya existe en Google Calendar. No se duplica.");
        }
      }
    }
  }
}
  /// ✅ **Escucha cambios en las tareas en tiempo real**
  void _escucharCambiosEnTareas() {
    _firestore.collection("proyectos").snapshots().listen((querySnapshot) {
      _cargarTareasUsuario();
    });
  }


  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userProfilePhoto = user.photoURL;
        userName = user.displayName ?? "Usuario";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
   /// ✅ **Carga las tareas asignadas al usuario**
  Future<void> _cargarTareasUsuario() async {
    final userId = _auth.currentUser!.uid;
    final querySnapshot = await _firestore.collection("proyectos").get();

    int total = 0;
    int completadas = 0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];

      for (var tarea in tareas) {
        if (tarea["responsable"] == userId) {
          total++;
          if (tarea["completado"] == true) {
            completadas++;
          }
        }
      }
    }

    setState(() {
      totalTareas = total;
      tareasCompletadas = completadas;
      tareasPendientes = total - completadas;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
     appBar: AppBar(
        title: const Text(
          "Flow Start",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color.fromARGB(255, 255, 255, 255)),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),  // ✅ Mantiene el Drawer lateral
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PomodoroPage()));
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.timer, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard, color: Color(0xFFF2D64B)), label: 'Tablero'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard, color: Color(0xFFF2D64B)), label: 'Rankings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications, color: Color(0xFFF2D64B)), label: 'Alertas'),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFF2D64B),
      ),
    );
  }
   /// ✅ **Dashboard con datos en tiempo real**
Widget _buildDashboard() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white, width: 2), // ✅ Contorno blanco
    ),
    child: Card(
      elevation: 0, // ✅ Sin sombra
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen de Tareas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDashboardItem(Icons.task, "Total", totalTareas, Colors.white),
                _buildDashboardItem(Icons.check_circle, "Completadas", tareasCompletadas, Colors.green),
                _buildDashboardItem(Icons.hourglass_bottom, "Pendientes", tareasPendientes, Colors.orange),
              ],
            ),
            const SizedBox(height: 10),

            // 📌 **Lista de tareas con scroll limitado**
            const Text(
              "📌 Tareas Asignadas:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),

            /// 🔹 **Hacemos la lista deslizable**
            SizedBox(
              height: 150, // ✅ Altura limitada para que no ocupe toda la pantalla
              child: _mostrarTareasAsignadas(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _mostrarTareasAsignadas() {
  final userId = _auth.currentUser!.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection("proyectos").snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      List<Tarea> tareasAsignadas = [];

      for (var doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> tareas = data["tareas"] ?? [];

        for (var tareaJson in tareas) {
          Tarea tarea = Tarea.fromJson(tareaJson);
          if (tarea.responsable == userId) {
            tareasAsignadas.add(tarea);
          }
        }
      }

      if (tareasAsignadas.isEmpty) {
        return const Center(
          child: Text(
            "🎉 No tienes tareas pendientes.",
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      return Scrollbar(
        thumbVisibility: true, // ✅ Hace visible el scrollbar
        child: SingleChildScrollView(
          child: Column(
            children: tareasAsignadas.map((tarea) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                color: tarea.completado ? Colors.green[200] : Colors.white, // ✅ Resalta completadas
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
                ),
                child: ListTile(
                  title: Text(
                    tarea.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tarea.completado ? Colors.green[900] : Colors.black,
                    ),
                  ),
                  subtitle: Text("📅 Fecha: ${tarea.fecha}"),
                  trailing: Checkbox(
                    value: tarea.completado,
                    onChanged: (bool? newValue) {
                      _marcarTareaCompletada(tarea, newValue ?? false);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}

Future<void> _marcarTareaCompletada(Tarea tarea, bool completado) async {
  final userId = _auth.currentUser!.uid;

  // ✅ Verificamos que el usuario sea el responsable
  if (userId != tarea.responsable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Solo el responsable de la tarea puede marcarla como completada.")),
    );
    return;
  }

  tarea.completado = completado;

  // ✅ Actualizamos Firestore
  final querySnapshot = await _firestore.collection("proyectos").get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> tareas = data["tareas"] ?? [];

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo && tareas[i]["responsable"] == tarea.responsable) {
        tareas[i]["completado"] = completado;
      }
    }

    await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
  }

  setState(() {});

  print("✅ Tarea marcada como ${completado ? 'completada' : 'pendiente'}");
}


  Widget _buildDashboardItem(IconData icon, String title, int count, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text("$count", style: const TextStyle(color: Colors.white, fontSize: 20)),
      ],
    );
  }
   /// ✅ **Drawer lateral para herramientas y logout**
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
            child: const Text(
              'Herramientas',
              style: TextStyle(color: Color(0xFFF2D64B), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileForm(userId: ''),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFF2D64B)),
            title: const Text('Logout', style: TextStyle(color: Colors.black)),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
Widget _buildAsistenteButton() {
  return AnimatedContainer(
    duration: const Duration(seconds: 1),
    curve: Curves.easeInOut,
    child: FloatingActionButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AsistentePage()));
      },
      backgroundColor: Colors.black,
      child: const Icon(Icons.mic, color: Colors.white, size: 36),
    ),
  );
}

/// ✅ **Distribución mejorada con Dashboard + Botones con fondo degradado**
Widget _buildBody() {
  return Stack(
    children: [
      // 🔹 Fondo degradado
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blue[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      Column(
        children: [
          const SizedBox(height: 10),

          /// 🔹 **Dashboard de tareas**
          _buildDashboard(),

          /// 🔹 **Mensaje de bienvenida**
          Text(
            "Bienvenido, $userName 👋",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),

          /// 🔹 **Botón para ver el calendario**
/// 🔹 **Botón para ver el calendario con contorno blanco**
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarEventsPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco agregado
                ),
                elevation: 5, // ✅ Agregamos sombra para un efecto más elegante
              ),
              child: const Text(
                "Ver Calendario",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),


          const SizedBox(height: 30),

          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Primera fila (Desarrollo y Social) más cerca del centro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // En lugar de spaceEvenly
                      children: [
                        _buildCircleButton(const DesarrolloInicio(), Colors.blue, Icons.settings, "heroDesarrollo"),
                        const SizedBox(width: 10), // Reduce este valor para acercar más los botones
                        _buildCircleButton(const SocialPage(), Colors.pink, Icons.group, "social"),
                      ],
                    ),
                    const SizedBox(height: 10), // Espaciado entre filas
                    // 🔹 Segunda fila (Revistas y Salud)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Alineados al centro
                      children: [
                        _buildCircleButton(const RevistasPage(), Colors.orange, Icons.library_books, "perfil"),
                        const SizedBox(width: 80), // Ajusta el espacio entre botones
                        _buildCircleButton(const HealthPage(), Colors.green, Icons.health_and_safety, "salud"),
                      ],
                    ),
                    const SizedBox(height: 40), // Espaciado antes del botón central
                  ],
                ),
                Positioned(
                  bottom: 20, // Ubicación del botón de micrófono
                  child: _buildCircleButton(AsistentePage(), Colors.black, Icons.mic, "asistente"),
                ),
              ],
            ),
          )


        ],
      ),
    ],
  );
}

  /// ✅ **Botón circular con borde y sombra**
Widget _buildCircleButton(Widget page, Color color, IconData icon, String heroTag) {
  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    },
    child: Hero(
      tag: heroTag,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2), // ✅ Contorno blanco
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color], // ✅ Degradado suave
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.transparent,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    ),
  );
}


}








