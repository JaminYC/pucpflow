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

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPage.dart';

import 'package:pucpflow/features/skills/pages/admin_skill_suggestions_page.dart';

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

    const SocialPage(key: ValueKey("Proyectos")),

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

  /// Verifica si el usuario actual es administrador
  Future<bool> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error verificando admin: $e');
      return false;
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

        // Botón de Calendario

        IconButton(

          icon: const Icon(Icons.calendar_today, color: Colors.white),

          tooltip: 'Calendario',

          onPressed: () {

            Navigator.push(

              context,

              MaterialPageRoute(builder: (context) => const CalendarEventsPage()),

            );

          },

        ),

        // Botón de Menú (Ranking y Noticias)

        PopupMenuButton<String>(

          icon: const Icon(Icons.more_vert, color: Colors.white),

          tooltip: 'Más opciones',

          color: Colors.grey.shade900,

          onSelected: (value) {

            if (value == 'ranking') {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (context) => const RankingPage()),

              );

            } else if (value == 'noticias') {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (context) => const AlertPage()),

              );

            } else if (value == 'buscar') {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (context) => const SearchIntegrantesPage()),

              );

            }

          },

          itemBuilder: (BuildContext context) => [

            const PopupMenuItem(

              value: 'ranking',

              child: Row(

                children: [

                  Icon(Icons.emoji_events, color: Colors.amber),

                  SizedBox(width: 12),

                  Text('Ranking', style: TextStyle(color: Colors.white)),

                ],

              ),

            ),

            const PopupMenuItem(

              value: 'noticias',

              child: Row(

                children: [

                  Icon(Icons.article, color: Colors.blue),

                  SizedBox(width: 12),

                  Text('Noticias', style: TextStyle(color: Colors.white)),

                ],

              ),

            ),

            const PopupMenuItem(

              value: 'buscar',

              child: Row(

                children: [

                  Icon(Icons.search, color: Colors.green),

                  SizedBox(width: 12),

                  Text('Buscar Usuarios', style: TextStyle(color: Colors.white)),

                ],

              ),

            ),

          ],

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

      type: BottomNavigationBarType.fixed,

      items: const [

        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),

        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Proyectos'),

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



            return _buildTareaCard(
              tarea: tarea,
              proyecto: proyecto,
              userId: userId,
              imagenProyecto: tareasLibres[index]['imagen'] as String?,
              esLibre: true,
              onPrimaryAction: () => _asignarTareaUsuario(tarea),
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

              'imagen': data['imagenUrl'] ?? data['imagen'] ?? '',

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

          final imagen = tareasAsignadas[index]['imagen'] as String?;

          return _buildTareaCard(

            tarea: tarea,

            proyecto: proyecto,

            userId: userId,

            imagenProyecto: imagen,

            onPrimaryAction: () => marcarTareaComoCompletada(tarea, proyecto),

          );

        },

      );

    },

  );

}



Widget _buildTareaCard({
  required Tarea tarea,
  required String proyecto,
  required String userId,
  String? imagenProyecto,
  bool esLibre = false,
  VoidCallback? onPrimaryAction,
}) {
  final bool completada = tarea.completado;
  final Color statusColor = completada ? const Color(0xFF34C759) : const Color(0xFF2D9BF0);
  final Color accent = esLibre ? const Color(0xFF5D5FEF) : statusColor;
  final Color badgeColor = (tarea.dificultad?.toLowerCase() == 'alta')
      ? const Color(0xFFE74C3C)
      : (tarea.dificultad?.toLowerCase() == 'media')
          ? const Color(0xFFFFA351)
          : const Color(0xFF5BE4A8);
  final bool disableAction = esLibre ? false : completada;
  final String actionLabel = esLibre ? "Tomar tarea" : (completada ? "Completada" : "Marcar completada");

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF101524), Color(0xFF111C32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectImage(imagenProyecto, proyecto),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarea.titulo,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              proyecto,
                              style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: badgeColor.withOpacity(0.6)),
                        ),
                        child: Text(
                          tarea.dificultad?.toUpperCase() ?? 'NORMAL',
                          style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (tarea.descripcion != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      tarea.descripcion!,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildInfoChip(Icons.schedule, "${tarea.duracion} min"),
            const SizedBox(width: 10),
            if (tarea.fecha != null)
              _buildInfoChip(
                Icons.event,
                "${tarea.fecha!.day}/${tarea.fecha!.month} ${tarea.fecha!.hour}:${tarea.fecha!.minute.toString().padLeft(2, '0')}",
              ),
            const Spacer(),
            _buildInfoChip(Icons.label, tarea.tipoTarea),
          ],
        ),
        if (!esLibre) ...[
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: completada ? 1 : 0.35,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton.icon(
            icon: Icon(
              esLibre ? Icons.playlist_add : (completada ? Icons.check_circle : Icons.check),
              color: Colors.white,
              size: 18,
            ),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: disableAction ? 0 : 4,
            ),
            onPressed: disableAction ? null : onPrimaryAction,
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );
}

Widget _buildProjectImage(String? url, String proyecto) {
  final placeholder = Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    child: Center(
      child: Text(
        proyecto.isNotEmpty ? proyecto[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 22),
      ),
    ),
  );

  if (url == null || url.isEmpty) return placeholder;

  return Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
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

            Navigator.pop(context);

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VastoriaHomePage()));

          },

        ),



        ListTile(

          leading: const Icon(Icons.person_outline, color: Colors.white70),

          title: const Text('Perfil y Configuración', style: TextStyle(color: Colors.white)),
          onTap: () {

            Navigator.pop(context);

            final uid = FirebaseAuth.instance.currentUser?.uid;

            if (uid != null) {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (_) => PerfilUsuarioPage(uid: uid)),

              );

            } else {

              showToast(message: "Inicia sesión para ver tu perfil");
            }

          },

        ),



        ListTile(

          leading: const Icon(Icons.folder_open, color: Colors.white70),

          title: const Text('Mis Proyectos', style: TextStyle(color: Colors.white)),

          onTap: () {

            Navigator.pop(context);

            Navigator.push(

              context,

              MaterialPageRoute(builder: (_) => ProyectosPage()),

            );

          },

        ),



        const Divider(color: Colors.white24),



        ListTile(

          leading: const Icon(Icons.settings, color: Colors.white70),

          title: const Text('Preferencias', style: TextStyle(color: Colors.white)),

          onTap: () {

            Navigator.pop(context);

            final uid = FirebaseAuth.instance.currentUser?.uid;

            if (uid != null) {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (_) => ProfilePreferencesPage(userId: uid)),

              );

            } else {

              showToast(message: "Inicia sesión para editar tus preferencias");
            }

          },

        ),

        // Admin: Gestionar Skills (solo visible para administradores)
        FutureBuilder<bool>(
          future: _checkIfAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Column(
                children: [
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                    title: const Text(
                      'Admin: Gestionar Skills',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSkillSuggestionsPage(),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const Divider(color: Colors.white24),

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





















