// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables 
import 'package:pucpflow/features/user_auth/presentation/pages/Login/VastoriaHomePage.dart' show VastoriaHomePage;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pucpflow/features/app/splash_screen/splash_screen.dart'; // Importa la pantalla de Splash

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pucpflow/features/user_auth/Usuario/PerfilUsuarioPage.dart' show PerfilUsuarioPage;
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/AsistentePage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Comunidad/SearchIntegrantesPage.dart' show SearchIntegrantesPage;
import 'package:pucpflow/features/user_auth/presentation/pages/Login/CustomLoginPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/DashboardPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/EmotionalForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/IntellectualForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/profile_forms_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/UserProfileForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';
import 'package:pucpflow/global/common/toast.dart';
import 'dart:io';
import '../Dashboard.dart';
import '../HealthPage.dart';
import '../pomodoro/PomodoroPage.dart';
import '../calendar_events_page.dart';
import '../desarrolloinicio.dart';
import '../login_page.dart';
import '../profile_preferences_page.dart';
import '../revistas.dart';  
import '../SocialPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Ranking/RankingPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Alerta/AlertPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart';

import 'package:video_player/video_player.dart';

import '../dashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  late VideoPlayerController _videoController;
  final ScrollController _scrollControllerAsignadas = ScrollController();
  final ScrollController _scrollControllerLibres = ScrollController();
  Widget? _currentPage;
  String? userId;
  bool _isLoading = true;
  bool isDarkMode = false;
  int _selectedIndex = 0;
  List<Widget> get _pages => [
    KeyedSubtree(key: const ValueKey("Inicio"), child: _buildBody()),
    const RankingPage(key: ValueKey("Ranking")),
    const AlertPage(key: ValueKey("Noticias")),
    const SocialPage(key: ValueKey("Proyectos")),
    const SearchIntegrantesPage(key: ValueKey("Buscar")),
  ];



  File? _profileImage;
  String? userProfilePhoto;
  String? userName;
  int totalTareas = 0;
  int tareasCompletadas = 0;
  int tareasPendientes = 0;
  bool _accesoPermitido = false;



  @override
  void initState() {
    super.initState();
  _determinarUserId().then((_) {
    _verificarAcceso();
    _loadUserData();
    _cargarTareasUsuario();
    _sincronizarTareasConCalendario();
    _escucharCambiosEnTareas();
  });

     WidgetsBinding.instance.addObserver(this);

    _videoController = VideoPlayerController.asset('assets/videopilar.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..addListener(() {
        if (_videoController.value.isInitialized && _selectedIndex == 0 && !_videoController.value.isPlaying) {
          _videoController.play();
        }
      })
      ..initialize().then((_) => setState(() {}));

  }
  @override
  void dispose() {
     WidgetsBinding.instance.removeObserver(this);
    _videoController.dispose();
    super.dispose();
  }
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_videoController.value.isInitialized && !_videoController.value.hasError) {
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      _videoController.play();
    } else if (state == AppLifecycleState.paused) {
      _videoController.pause();
    }
  }
}
Future<void> _determinarUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final loginEmpresarial = prefs.getBool("login_empresarial") ?? false;
  if (loginEmpresarial) {
    userId = prefs.getString("uid_empresarial");
  } else {
    userId = FirebaseAuth.instance.currentUser?.uid;
  }
}

Future<void> _sincronizarTareasConCalendario() async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return; // ✅ Evita errores si el usuario no está autenticado.

  final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
  if (calendarApi == null) return; // ❌ Si no hay conexión con Google Calendar, salir.

  final querySnapshot = await _firestore.collection("proyectos").get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    List<dynamic> tareas = data["tareas"] ?? [];

    for (var tareaJson in tareas) {
      final tarea = Tarea.fromJson(tareaJson);

      // ✅ Solo sincronizar tareas asignadas al usuario con fecha válida.
      if (tarea.responsables.contains(userId) && tarea.fecha != null) {
        // 🔹 Verificar si la tarea ya existe en el calendario
        bool existeEnCalendario = await _calendarService.verificarTareaEnCalendario(calendarApi, tarea, userId);

        if (!existeEnCalendario) {
          // 🔹 Verificar disponibilidad en la fecha asignada
          bool horarioOcupado = await _calendarService.verificarDisponibilidadHorario(
            calendarApi,
            userId,
            tarea.fecha!,
            tarea.fecha!.add(Duration(minutes: tarea.duracion))
          );

          // 🔹 Si el horario está ocupado, encontrar un nuevo horario disponible
          DateTime fechaFinal = tarea.fecha!;
          if (horarioOcupado) {
            print("⚠️ Horario ocupado para la tarea '${tarea.titulo}', buscando otro disponible...");
            DateTime? nuevaFecha = await _calendarService.encontrarHorarioDisponible(calendarApi, userId, tarea.duracion);

            if (nuevaFecha != null) {
              fechaFinal = nuevaFecha;
              print("✅ Nueva fecha asignada para '${tarea.titulo}': $fechaFinal");
            } else {
              print("❌ No se encontró un horario disponible para '${tarea.titulo}' en los próximos días.");
              continue;
            }
          }

          // 🔹 Agregar tarea al calendario con la fecha ajustada
          tarea.fecha = fechaFinal;
           await _calendarService.agendarEventoEnCalendario(calendarApi, tarea, userId);
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
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final prefs = await SharedPreferences.getInstance();
  final loginEmpresarial = prefs.getBool("login_empresarial") ?? false;

  if (firebaseUser != null) {
    setState(() {
      userProfilePhoto = firebaseUser.photoURL;
      userName = firebaseUser.displayName ?? "Usuario";
      _isLoading = false;
    });
  } else if (loginEmpresarial) {
    final uid = prefs.getString("uid_empresarial");
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final userData = userDoc.data();
    setState(() {
      userProfilePhoto = null;
      userName = userData?["username"] ?? "Empresa";
      _isLoading = false;
    });
  }

  }
Future<void> _cargarTareasUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final esEmpresarial = prefs.getBool("login_empresarial") ?? false;

  String? userId;
  if (esEmpresarial) {
    userId = prefs.getString("uid_empresarial");
  } else {
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  if (userId == null) {
    debugPrint("❌ No se pudo obtener el UID del usuario.");
    return;
  }

  final querySnapshot = await FirebaseFirestore.instance.collection("proyectos").get();

  int total = 0;
  int completadas = 0;

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    List<dynamic> tareasRaw = data["tareas"] ?? [];

    for (var tareaJson in tareasRaw) {
      final tarea = Tarea.fromJson(tareaJson);

      if (tarea.responsables.contains(userId)) {
        total++;
        if (tarea.completado) {
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

  debugPrint("📊 Tareas cargadas para UID: $userId | Total: $total | Completadas: $completadas");
}


/*********************************************************************************** */
Future<void> _cerrarSesionEmpresarial(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("login_empresarial");
  await prefs.remove("uid_empresarial");

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (route) => false,
  );
}

Future<bool> _verificarAcceso() async {
  final prefs = await SharedPreferences.getInstance();
  final loginEmpresarial = prefs.getBool("login_empresarial") ?? false;
  final uidEmpresarial = prefs.getString("uid_empresarial");

  final userFirebase = FirebaseAuth.instance.currentUser;

  debugPrint("🧪 FirebaseAuth User: ${userFirebase?.email}");
  debugPrint("🧪 Login Empresarial: $loginEmpresarial");
  debugPrint("🧪 UID: $uidEmpresarial");

  if (userFirebase != null || loginEmpresarial) {
    return true;
  }

  return false;
}

Future<void> cerrarSesion(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔥 Limpia sesión empresarial también

    if (kIsWeb) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect(); // 🔁 Fuerza logout de Google Web
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    }

    debugPrint("✅ Sesión cerrada correctamente.");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  } catch (e) {
    debugPrint("❌ Error al cerrar sesión: $e");
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
  void _onItemTapped(int index) async {
    final wasIndexZero = _selectedIndex == 0;
    final isIndexZero = index == 0;

    if (wasIndexZero && _videoController.value.isInitialized) {
      _videoController.pause();
    }

    // 🔁 Pequeño retraso para suavizar el cambio
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _selectedIndex = index;
      _currentPage = _pages[index];
    });

    if (_videoController.value.isInitialized && isIndexZero) {
      _videoController.play();
    }
  }



Widget _buildMainScaffold(BuildContext context){
  if (_isLoading) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
  return Scaffold(
    appBar: AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        "FLOW",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
    drawer: _buildDrawer(context),
    body: Stack(
      children: [
        Container(color: Colors.black), // Fondo negro sólido (base)
        if (_videoController.value.isInitialized)
          ValueListenableBuilder(
            valueListenable: _videoController,
            builder: (context, VideoPlayerValue value, _) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              );
            },
          ),

        Container(color: Colors.black.withOpacity(0.3)),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _pages[_selectedIndex],
        ),


        Positioned(
          left: 16,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: "asistente",
            onPressed: () {
              _videoController.pause();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AsistentePage()),
              ).then((_) {
                if (_selectedIndex == 0) _videoController.play();
              });
            },
            backgroundColor: Colors.black,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ),

        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: "pomodoro",
            onPressed: () {
              _videoController.pause();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PomodoroPage()),
              ).then((_) {
                if (_selectedIndex == 0) _videoController.play();
              });
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.timer, color: Colors.white),
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.black,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Ranking'),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Noticias'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Proyectos'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
      ],
    ),
  );
}
@override
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: _verificarAcceso(), // 👈 función que valida login
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        debugPrint("⏳ Esperando acceso...");
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (!snapshot.data!) {
        debugPrint("🔒 No se detectó login válido. Redirigiendo a CustomLoginPage.");
        return const CustomLoginPage(); // 👈 Redirige si no hay login válido
      }
      
       debugPrint("✅ Login válido. Mostrando HomePage.");
      // ✅ Si hay acceso válido (Firebase o empresarial), muestra tu HomePage normal
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          final salir = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("¿Salir de la aplicación?"),
              content: const Text("¿Deseas cerrar completamente la aplicación?"),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text("Salir"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (salir == true) {
            Navigator.of(context).maybePop();
          }
        },
        child: _buildMainScaffold(context), // 👈 Tu scaffold original
      );
    },
  );
}



   /// ✅ **Dashboard con datos en tiempo real**
/// ✅ Dashboard con tareas en columnas divididas
Widget _buildDashboard() {
  final isMobile = MediaQuery.of(context).size.width < 600;

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85, // ✅ máximo 85% de pantalla
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.black.withAlpha(153),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Resumen de Tareas",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CalendarEventsPage()),
                      );
                    },
                    icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                    label: const Text("Calendario", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
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
          const SizedBox(height: 20),

          // 👇 Esta parte se adapta dinámicamente a la pantalla
          Flexible(
            child: isMobile
                ? Column(
                    children: [
                      _buildTareaSection("Tareas Asignadas", _mostrarTareasAsignadas(), 200),
                      const SizedBox(height: 16),
                      _buildTareaSection("Tareas Libres", _mostrarTareasLibres(), 200),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildTareaSection("Tareas Asignadas", _mostrarTareasAsignadas(), 400)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTareaSection("Tareas Libres", _mostrarTareasLibres(), 400)),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTareaSection(String titulo, Widget contenido, double altura) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(
        height: altura,
        child: contenido,
      ),
    ],
  );
}


Widget _mostrarTareasLibres() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const SizedBox();

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection("proyectos").snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      List<Map<String, dynamic>> tareasLibres = [];

      for (var doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nombreProyecto = data['nombre'] ?? 'Proyecto sin nombre';

        final List<dynamic> participantes = data['participantes'] ?? [];
        if (!participantes.contains(userId)) continue; // ✅ solo si participa

        final List<dynamic> tareas = data["tareas"] ?? [];

        for (var tareaJson in tareas) {
          final tarea = Tarea.fromJson(tareaJson);
          if (tarea.responsables.isEmpty && !tarea.completado && tarea.tipoTarea == "Libre") {
            tareasLibres.add({
              'tarea': tarea,
              'proyecto': nombreProyecto,
              'docId': doc.id,
            });
          }
        }
      }

      if (tareasLibres.isEmpty) {
        return const Center(
          child: Text("🆓 No hay tareas libres disponibles.", style: TextStyle(color: Colors.white)),
        );
      }

      return Scrollbar(
        controller: _scrollControllerLibres,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollControllerLibres,
          itemCount: tareasLibres.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final tarea = tareasLibres[index]['tarea'] as Tarea;
            final proyecto = tareasLibres[index]['proyecto'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              color: const Color.fromARGB(255, 255, 255, 255),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              child: ListTile(
                title: Text(
                  tarea.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Proyecto: $proyecto", style: const TextStyle(color: Colors.black87)),
                      if (tarea.fecha != null)
                        Text("🕒 Fecha: ${tarea.fecha!.toLocal().toString().substring(0, 16)}", style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text("⏱️ Duración: ${tarea.duracion} min", style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text("🎯 Dificultad: ${tarea.dificultad}", style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),

                trailing: ElevatedButton(
                  onPressed: () => _asignarTareaUsuario(tarea),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text("Tomar Tarea", style: TextStyle(color: Colors.black)),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}




Future<void> _asignarTareaUsuario(Tarea tarea) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return;

  if (tarea.responsables.contains(userId)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Ya tienes asignada esta tarea.")),
    );
    return;
  }

  final querySnapshot = await _firestore.collection("proyectos").get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> tareas = data["tareas"] ?? [];
    bool actualizada = false;

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo) {
        // Agregar usuario a responsables
        List<String> responsables = List<String>.from(tareas[i]["responsables"] ?? []);
        if (!responsables.contains(userId)) {
          responsables.add(userId);
          tareas[i]["responsables"] = responsables;
        }

        // Cambiar tipo de tarea a "Asignada" si estaba como "Libre"
        if (tareas[i]["tipoTarea"] == "Libre") {
          tareas[i]["tipoTarea"] = "Asignada";
        }

        actualizada = true;
      }
    }

    if (actualizada) {
      await _firestore.collection("proyectos").doc(doc.id).update({
        "tareas": tareas,
      });
    }
  }

  setState(() {});
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Tarea tomada correctamente.")),
  );
}
Future<String?> _obtenerUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final loginEmpresarial = prefs.getBool("login_empresarial") ?? false;
  if (loginEmpresarial) {
    return prefs.getString("uid_empresarial");
  } else {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}



Widget _mostrarTareasAsignadas() {
  return FutureBuilder<String?>(
    future: _obtenerUserId(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final userId = snapshot.data!;
      return _buildStreamTareasAsignadas(userId);
    },
  );
}
Widget _buildStreamTareasAsignadas(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection("proyectos").snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      List<Map<String, dynamic>> tareasAsignadas = [];

      for (var doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nombreProyecto = data['nombre'] ?? 'Proyecto sin nombre';
        List<dynamic> tareas = data["tareas"] ?? [];

        for (var tareaJson in tareas) {
          Tarea tarea = Tarea.fromJson(tareaJson);

          if (tarea.responsables.contains(userId) && !tarea.completado) {
            tareasAsignadas.add({
              'tarea': tarea,
              'proyecto': nombreProyecto,
            });
          }
        }
      }

      if (tareasAsignadas.isEmpty) {
        return const Center(
          child: Text("🎉 No tienes tareas pendientes.",
              style: TextStyle(color: Colors.white)),
        );
      }

      return ListView.builder(
        controller: _scrollControllerAsignadas,
        itemCount: tareasAsignadas.length,
        itemBuilder: (context, index) {
          final tarea = tareasAsignadas[index]['tarea'] as Tarea;
          final proyecto = tareasAsignadas[index]['proyecto'];
          return _buildTareaCard(tarea, proyecto, userId);
        },
      );
    },
  );
}

Widget _buildTareaCard(Tarea tarea, String proyecto, String userId) {
  return Card(
    color: Colors.white,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tarea.titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (tarea.descripcion != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                tarea.descripcion!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(
                  tarea.tipoTarea,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black87,
              ),
              if (tarea.dificultad != null)
                Chip(
                  label: Text(
                    tarea.dificultad!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text("Proyecto: $proyecto", style: const TextStyle(fontSize: 13)),
          if (tarea.fecha != null)
            Text("Fecha: ${tarea.fecha!.toLocal()}".split(' ')[0]),
          Text("Duración: ${tarea.duracion} min"),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: tarea.completado ? 1.0 : 0.0,
            backgroundColor: Colors.grey[300],
            color: tarea.completado ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 10),
          if (!tarea.completado)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text("Marcar completada"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () => marcarTareaComoCompletada(tarea, proyecto),
              ),
            ),
        ],
      ),
    ),
  );
}
Future<void> marcarTareaComoCompletada(Tarea tarea, String nombreProyecto) async {
  final prefs = await SharedPreferences.getInstance();
  final bool esEmpresarial = prefs.getBool("login_empresarial") ?? false;

  final String? currentUserId = esEmpresarial
      ? prefs.getString("uid_empresarial")
      : FirebaseAuth.instance.currentUser?.uid;

  if (currentUserId == null) return;

  final proyectos = await _firestore.collection("proyectos").get();

  for (var doc in proyectos.docs) {
    final data = doc.data();
    final nombre = data['nombre'] ?? '';
    if (nombre != nombreProyecto) continue; // 🔁 Solo actualiza el proyecto correcto

    List<dynamic> tareas = data["tareas"] ?? [];

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo) {
        tareas[i]["completado"] = true;
      }
    }

    await _firestore.collection("proyectos").doc(doc.id).update({
      "tareas": tareas,
    });

    // 🔁 Puntos para todos los responsables
    for (String responsableId in tarea.responsables) {
      await _actualizarPuntosUsuario(responsableId, tarea);
    }

    break; // ✅ Salir del bucle una vez encontrado el proyecto
  }

  setState(() {});
}

Future<void> _actualizarPuntosUsuario(String userId, Tarea tarea) async {
  final userDoc = _firestore.collection("users").doc(userId);
  final userSnapshot = await userDoc.get();
  if (!userSnapshot.exists) return;

  final userData = userSnapshot.data() as Map<String, dynamic>;
  int puntosActuales = userData["puntosTotales"] ?? 0;
  Map<String, dynamic> habilidades = Map.from(userData["habilidades"] ?? {});

  int puntosGanados = 10;
  if (tarea.dificultad == "media") puntosGanados += 5;
  if (tarea.dificultad == "alta") puntosGanados += 10;

  tarea.requisitos.forEach((habilidad, impacto) {
    habilidades[habilidad] = (habilidades[habilidad] ?? 0) + impacto;
  });

  await userDoc.update({
    "puntosTotales": puntosActuales + puntosGanados,
    "habilidades": habilidades,
  });
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
    backgroundColor: Colors.black,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.black87,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/logovastoria.png', height: 60),
              const SizedBox(height: 10),
              const Text(
                'VASTORIA',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Conquista tus proyectos 🚀',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),

        ListTile(
          leading: const Icon(Icons.home, color: Colors.white70),
          title: const Text('Volver a Vastoria', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VastoriaHomePage()));
          },
        ),

        ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.white70),
          title: const Text('Perfil y Configuración', style: TextStyle(color: Colors.white)),
          onTap: () {
            // Aquí mandarías a ProfilePage()
          },
        ),

        ListTile(
          leading: const Icon(Icons.bar_chart, color: Colors.white70),
          title: const Text('Mi Progreso', style: TextStyle(color: Colors.white)),
          onTap: () {
            // Aquí mandarías a ProgressPage()
          },
        ),

        ListTile(
          leading: const Icon(Icons.folder_open, color: Colors.white70),
          title: const Text('Mis Proyectos', style: TextStyle(color: Colors.white)),
          onTap: () {
            // Aquí mandarías a MyProjectsPage()
          },
        ),

        const Divider(color: Colors.white24),

        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white70),
          title: const Text('Preferencias', style: TextStyle(color: Colors.white)),
          onTap: () {
            // Aquí mandarías a SettingsPage()
          },
        ),

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
          onTap: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}

Widget _buildBody() {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final bool isMobile = screenWidth < 600; // Umbral para considerar móvil

  return Stack(
    children: [
      // Fondo degradado
      ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _videoController,
        builder: (context, value, child) {
          if (!value.isInitialized) return const SizedBox.shrink();
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: value.size.width,
                height: value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          );
        },
      ),


      // Contenido principal en SingleChildScrollView para evitar overflow
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * (isMobile ? 0.05 : 0.04),
            vertical: screenHeight * (isMobile ? 0.02 : 0.01),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * (isMobile ? 0.02 : 0.015)),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🧑 Foto + Nombre
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PerfilUsuarioPage(uid: uid),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: userProfilePhoto != null
                                ? NetworkImage(userProfilePhoto!)
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                        ),

                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hola 👋", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(
                              userName ?? "Usuario",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 📅 Botón Ver Calendario a la derecha


                  ],
                ),

              SizedBox(height: screenHeight * 0.02),
              /// Dashboard adaptativo (ajusta _buildDashboard_ según lo necesites)
              _buildDashboard(),
              SizedBox(height: screenHeight * (isMobile ? 0.03 : 0.02)),
              SizedBox(height: screenHeight * (isMobile ? 0.02 : 0.01)),

              SizedBox(height: screenHeight * (isMobile ? 0.02 : 0.01)),
              /// Área de botones circulares adaptativos
            
            ],
          ),
        ),
      ),
    ],
  );
}

/// Botón circular adaptativo: calcula el radio y tamaño del ícono en función del ancho de la pantalla
Widget _buildCircleButton(
  Widget page,
  Color color,
  IconData icon,
  String heroTag,
  double screenWidth,
  bool isMobile,
) {
  // Valores ajustados: si es móvil usamos porcentajes mayores para que se vean más grandes.
  double circleRadius = isMobile ? screenWidth * 0.07 : screenWidth * 0.020;
  double circleIconSize = isMobile ? screenWidth * 0.05 : screenWidth * 0.020;

  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    },
    child: Hero(
      tag: heroTag,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
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
          radius: circleRadius,
          backgroundColor: Colors.transparent,
          child: Icon(
            icon,
            color: Colors.white,
            size: circleIconSize,
          ),
        ),
      ),
    ),
  );
}


}








