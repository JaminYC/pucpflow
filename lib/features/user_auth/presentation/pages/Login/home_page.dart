// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:pucpflow/features/user_auth/presentation/pages/Login/VastoriaHomePage.dart' show VastoriaHomePage;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pucpflow/features/app/splash_screen/splash_screen.dart'; // Importa la pantalla de Splash

import 'package:provider/provider.dart';
import 'package:pucpflow/demo/animations_demo_page.dart'; // Demo de animaciones
import 'package:pucpflow/demo/bubble_button_demo.dart'; // Demo del botón de burbujas
import 'package:pucpflow/demo/gamification_quick_access.dart'; // Demo de gamification
import 'package:pucpflow/providers/theme_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:image_picker/image_picker.dart';

import 'package:pucpflow/features/user_auth/Usuario/PerfilUsuarioPage.dart' show PerfilUsuarioPage;

import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';

import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/services/global_overlay_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/pomodoro/PomodoroFloatingButton.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/AsistentePageNew.dart';

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

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetalleKanbanPage.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/categoria_migration.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPage.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Briefing/briefing_diario_page.dart';

import '../dashboard.dart';

import 'package:flutter/foundation.dart' show kIsWeb;



class HomePage extends StatefulWidget {

  HomePage({super.key});



  @override

  _HomePageState createState() => _HomePageState();

}



class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleCalendarService _calendarService = GoogleCalendarService();

  final ScrollController _scrollControllerAsignadas = ScrollController();

  final ScrollController _scrollControllerLibres = ScrollController();

  Widget? _currentPage;

  String? userId;

  bool _isLoading = true;

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

  String _filtroCategoriaTareas = "Todas";

  bool _accesoPermitido = false;







  @override

  void initState() {

    super.initState();

    // Inicializar animación de fondo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

  _determinarUserId().then((_) {
    if (userId != null) {
      CategoriaMigration.runIfNeeded(uid: userId!);
    }

    _verificarAcceso();

    _loadUserData();

    _cargarTareasUsuario();

    // No sincronizar automáticamente - solo cuando el usuario lo solicite
    // _sincronizarTareasConCalendario();

    _escucharCambiosEnTareas();

  });



  }

  @override

  void dispose() {

    _animationController.dispose();

    super.dispose();

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

    // 🔁 Pequeño retraso para suavizar el cambio

    await Future.delayed(const Duration(milliseconds: 300));



    setState(() {

      _selectedIndex = index;

      _currentPage = _pages[index];

    });

  }

  // Los colores ahora se obtienen del ThemeProvider
  // No se necesitan getters locales - usar Provider.of<ThemeProvider>(context)







Widget _buildMainScaffold(BuildContext context){

  if (_isLoading) {

    return const Scaffold(body: Center(child: CircularProgressIndicator()));

  }

  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      return Scaffold(

        backgroundColor: themeProvider.backgroundColor,

        appBar: AppBar(

          iconTheme: IconThemeData(color: themeProvider.textPrimaryColor),

          title: Text(

            "FLOW",

            style: TextStyle(

              fontWeight: FontWeight.w800,

              fontSize: 22,

              color: themeProvider.textPrimaryColor,
              letterSpacing: 2.0,

            ),

          ),

          centerTitle: true,

          backgroundColor: themeProvider.isDarkMode
              ? ThemeProvider.darkCard
              : Colors.white.withOpacity(0.95),

          elevation: 0,

          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? ThemeProvider.darkCard
                  : Colors.white.withOpacity(0.95),
              border: Border(
                bottom: BorderSide(
                  color: themeProvider.borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),

          actions: [
            // 🎨 Botón para ver DEMO de animaciones
            IconButton(
              icon: const Icon(Icons.animation),
              tooltip: '🎨 Ver Demo Animaciones',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnimationsDemoPage()),
                );
              },
            ),

            // Botón para ver tu Bubble Button
            IconButton(
              icon: const Icon(Icons.bubble_chart),
              tooltip: '🎈 Ver Bubble Button',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BubbleButtonDemo()),
                );
              },
            ),

            // 🎮 Botón para Gamification Test
            const GamificationQuickAccessButton(),

            // Toggle de tema elegante (tipo switch)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: GestureDetector(
                  onTap: () => themeProvider.toggleTheme(),
                  child: Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: themeProvider.isDarkMode
                            ? [ThemeProvider.accentPurple, ThemeProvider.accentBlue]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? ThemeProvider.accentPurple.withOpacity(0.4)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          alignment: themeProvider.isDarkMode
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              size: 16,
                              color: themeProvider.isDarkMode
                                  ? ThemeProvider.accentPurple
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Botón de Calendario

            IconButton(

              icon: Icon(
                Icons.calendar_today,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : ThemeProvider.accentBlue,
              ),

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

              icon: Icon(
                Icons.more_vert,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : ThemeProvider.accentBlue,
              ),

              tooltip: 'Más opciones',

              color: themeProvider.cardColor,

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

                PopupMenuItem(

                  value: 'ranking',

                  child: Row(

                    children: [

                      Icon(Icons.emoji_events, color: Colors.amber),

                      SizedBox(width: 12),

                      Text('Ranking', style: TextStyle(color: themeProvider.textPrimaryColor)),

                    ],

                  ),

                ),

                PopupMenuItem(

                  value: 'noticias',

                  child: Row(

                    children: [

                      Icon(Icons.article, color: ThemeProvider.accentBlue),

                      SizedBox(width: 12),

                      Text('Noticias', style: TextStyle(color: themeProvider.textPrimaryColor)),

                    ],

                  ),

                ),

                PopupMenuItem(

                  value: 'buscar',

                  child: Row(

                    children: [

                      Icon(Icons.search, color: ThemeProvider.accentGreen),

                      SizedBox(width: 12),

                      Text('Buscar Usuarios', style: TextStyle(color: themeProvider.textPrimaryColor)),

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

        // Fondo minimalista elegante
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F5F7), // Gris muy claro (estilo Apple)
                Color(0xFFFFFFFF), // Blanco puro
                Color(0xFFF5F5F7), // Gris muy claro
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Patrón sutil de puntos minimalista
        Positioned.fill(
          child: CustomPaint(
            painter: MinimalDotPattern(),
          ),
        ),



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

          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF133E87), Color(0xFF0A2351)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF133E87).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton(

              heroTag: "asistente",

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(builder: (context) => const AsistentePageNew()),

                );

              },

              backgroundColor: Colors.transparent,
              elevation: 0,

              child: const Icon(Icons.mic, color: Colors.white),

            ),
          ),

        ),



        // 🍅 Botón flotante de Pomodoro con timer integrado
        const Positioned(
          right: 16,
          bottom: 20,
          child: PomodoroFloatingButton(),
        ),

      ],

    ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? ThemeProvider.darkCard
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(

            backgroundColor: Colors.transparent,
            elevation: 0,

            currentIndex: _selectedIndex,

            onTap: _onItemTapped,

            selectedItemColor: ThemeProvider.accentPurple,

            unselectedItemColor: themeProvider.isDarkMode
                ? Colors.white70
                : const Color(0xFF8E8E93),

            type: BottomNavigationBarType.fixed,

            items: const [

              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),

              BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Proyectos'),

            ],

          ),
        ),

      );
    },
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
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isMobile = MediaQuery.of(context).size.width < 600;
  final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
  final secondaryTextColor = themeProvider.isDarkMode ? Colors.white70 : Colors.black54;

  return ConstrainedBox(

    constraints: BoxConstraints(

      maxHeight: MediaQuery.of(context).size.height * 0.85, // ✅ máximo 85% de pantalla

    ),

    child: Container(

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: themeProvider.isDarkMode
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.15),
          width: 2
        ),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeProvider.isDarkMode
            ? [
                ThemeProvider.darkCard,
                ThemeProvider.darkCard.withValues(alpha: 0.9),
              ]
            : [
                const Color(0xFFFAFAFA), // Gris muy claro en vez de blanco puro
                const Color(0xFFF0F0F0), // Gris más oscuro
              ],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: themeProvider.isDarkMode ? 0.4 : 0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],

      ),

      padding: EdgeInsets.all(isMobile ? 12 : 16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  Flexible(
                    child: Text(

                      "Resumen de Tareas",

                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,

                    ),
                  ),

                  ElevatedButton.icon(

                    style: ElevatedButton.styleFrom(

                      backgroundColor: ThemeProvider.accentBlue,

                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 14,
                        vertical: isMobile ? 8 : 10,
                      ),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),

                        side: BorderSide(
                          color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.3)
                            : ThemeProvider.accentBlue.withValues(alpha: 0.5),
                          width: 1.5
                        ),

                      ),

                      elevation: 3,

                    ),

                    onPressed: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(builder: (_) => const CalendarEventsPage()),

                      );

                    },

                    icon: Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: isMobile ? 16 : 18,
                    ),

                    label: Text(
                      "Calendario",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 11 : 13,
                      ),
                    ),

                  ),

                ],

              ),

              SizedBox(height: isMobile ? 8 : 10),
              Row(
                children: [
                  Text(
                    "Categoria:",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2)
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filtroCategoriaTareas,
                        dropdownColor: themeProvider.isDarkMode ? ThemeProvider.darkCard : Colors.white,
                        iconEnabledColor: textColor,
                        style: TextStyle(
                          color: textColor,
                          fontSize: isMobile ? 11 : 12,
                        ),
                        onChanged: (value) {
                          setState(() => _filtroCategoriaTareas = value ?? "Todas");
                        },
                        items: ["Todas", "Laboral", "Personal"]
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                      ),
                    ),
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
                      Expanded(child: _buildTareaSection("Tareas Asignadas", _mostrarTareasAsignadas())),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTareaSection("Tareas Libres", _mostrarTareasLibres())),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildTareaSection("Tareas Asignadas", _mostrarTareasAsignadas())),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTareaSection("Tareas Libres", _mostrarTareasLibres())),
                    ],
                  ),
          ),

        ],

      ),

    ),

  );

}



Widget _buildTareaSection(String titulo, Widget contenido) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Expanded(child: contenido),
    ],
  );
}

Color _colorPorCategoria(String? categoria) {
  switch (categoria?.toLowerCase()) {
    case 'personal':
      return const Color(0xFFEC4899);
    case 'laboral':
      return const Color(0xFF2D9BF0);
    default:
      return const Color(0xFF9CA3AF);
  }
}

String _normalizarCategoria(String? categoria) {
  final value = (categoria ?? 'Laboral').toString().trim();
  if (value.isEmpty) return 'Laboral';
  final lower = value.toLowerCase();
  if (lower == 'vida') return 'Personal';
  if (lower == 'laboral') return 'Laboral';
  if (lower == 'personal') return 'Personal';
  return value;
}

bool _pasaFiltroCategoria(String? categoria) {
  if (_filtroCategoriaTareas == "Todas") return true;
  return _normalizarCategoria(categoria) == _normalizarCategoria(_filtroCategoriaTareas);
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
        final rawCategoria = data['categoria'] ?? data['categoriaProyecto'] ?? data['tipo'];
        final categoriaProyecto = _normalizarCategoria(rawCategoria?.toString());
        final imagenProyecto = data['imagenUrl'] ?? data['imagen'] ?? '';



        final participantes = data['participantes'];

        if (participantes is List && participantes.isNotEmpty && !participantes.contains(userId)) {
          continue; // ✅ solo si participa
        }
        if (!_pasaFiltroCategoria(categoriaProyecto)) continue;



        final List<dynamic> tareas = data["tareas"] ?? [];



        for (var tareaJson in tareas) {

          final tarea = Tarea.fromJson(tareaJson);

          if (tarea.responsables.isEmpty && !tarea.completado && tarea.tipoTarea == "Libre") {

            tareasLibres.add({

              'tarea': tarea,

              'proyecto': nombreProyecto,

              'docId': doc.id,
              'categoria': categoriaProyecto,
              'imagen': imagenProyecto,

            });

          }

        }

      }



      if (tareasLibres.isEmpty) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

        return Center(

          child: Text("🆓 No hay tareas libres disponibles.", style: TextStyle(color: textColor)),

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
              context,
              tarea: tarea,
              proyecto: proyecto,
              userId: userId,
              imagenProyecto: tareasLibres[index]['imagen'] as String?,
              categoria: tareasLibres[index]['categoria'] as String?,
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
        final rawCategoria = data['categoria'] ?? data['categoriaProyecto'] ?? data['tipo'];
        final categoriaProyecto = _normalizarCategoria(rawCategoria?.toString());
        final imagenProyecto = data['imagenUrl'] ?? data['imagen'] ?? '';

        List<dynamic> tareas = data["tareas"] ?? [];
        if (!_pasaFiltroCategoria(categoriaProyecto)) continue;



        for (var tareaJson in tareas) {

          Tarea tarea = Tarea.fromJson(tareaJson);



          if (tarea.responsables.contains(userId) && !tarea.completado) {

            tareasAsignadas.add({

              'tarea': tarea,

              'proyecto': nombreProyecto,

              'imagen': imagenProyecto,
              'categoria': categoriaProyecto,

            });

          }

        }

      }



      if (tareasAsignadas.isEmpty) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

        return Center(

          child: Text("🎉 No tienes tareas pendientes.",

              style: TextStyle(color: textColor)),

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

            context,

            tarea: tarea,

            proyecto: proyecto,

            userId: userId,

            imagenProyecto: imagen,
            categoria: tareasAsignadas[index]['categoria'] as String?,

            onPrimaryAction: () => marcarTareaComoCompletada(tarea, proyecto),

          );

        },

      );

    },

  );

}



Widget _buildTareaCard(
  BuildContext context, {
  required Tarea tarea,
  required String proyecto,
  required String userId,
  String? categoria,
  String? imagenProyecto,
  bool esLibre = false,
  VoidCallback? onPrimaryAction,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isMobile = MediaQuery.of(context).size.width < 600;
  final bool completada = tarea.completado;
  final Color statusColor = completada ? const Color(0xFF34C759) : const Color(0xFF2D9BF0);
  final Color accent = esLibre ? const Color(0xFF5D5FEF) : statusColor;
  final String categoriaLabel = _normalizarCategoria(categoria);
  final Color categoriaColor = _colorPorCategoria(categoriaLabel);
  final Color baseBorderColor = themeProvider.isDarkMode
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.08);
  final Color badgeColor = (tarea.dificultad?.toLowerCase() == 'alta')
      ? const Color(0xFFE74C3C)
      : (tarea.dificultad?.toLowerCase() == 'media')
          ? const Color(0xFFFFA351)
          : const Color(0xFF5BE4A8);
  final bool disableAction = esLibre ? false : completada;
  final String actionLabel = esLibre ? "Tomar tarea" : (completada ? "Completada" : "Marcar completada");

  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: isMobile ? 2 : 8,
      vertical: isMobile ? 4 : 8,
    ),
    padding: EdgeInsets.all(isMobile ? 8 : 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(isMobile ? 12 : 22),
      gradient: LinearGradient(
        colors: themeProvider.isDarkMode
          ? [const Color(0xFF101524), const Color(0xFF111C32)]
          : [Colors.white, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: themeProvider.isDarkMode ? 0.35 : 0.12),
          blurRadius: isMobile ? 10 : 15,
          spreadRadius: isMobile ? 0 : 1,
          offset: Offset(0, isMobile ? 3 : 5),
        ),
      ],
      border: Border.all(
        color: themeProvider.isDarkMode
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
        width: 1,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: categoriaColor, width: isMobile ? 3 : 4),
        ),
      ),
      padding: EdgeInsets.only(left: isMobile ? 8 : 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              _buildProjectImage(context, imagenProyecto, proyecto),
            if (!isMobile)
              SizedBox(width: isMobile ? 10 : 16),
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
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 18,
                                fontWeight: FontWeight.w700,
                                color: themeProvider.isDarkMode ? Colors.white : Color(0xFF1A1A1A),
                              ),
                              maxLines: isMobile ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isMobile ? 3 : 4),
                            Row(
                              children: [
                                Container(
                                  width: isMobile ? 5 : 8,
                                  height: isMobile ? 5 : 8,
                                  decoration: BoxDecoration(
                                    color: categoriaColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    categoriaLabel,
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode ? Colors.white70 : Color(0xFF4A4A4A),
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 2 : 4),
                            Text(
                              proyecto,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white54 : Color(0xFF4A4A4A),
                                fontSize: isMobile ? 10 : 13,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isMobile ? 4 : 8),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 12,
                            vertical: isMobile ? 3 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            tarea.dificultad?.toUpperCase() ?? 'NORMAL',
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 9 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tarea.descripcion != null && !isMobile) ...[
                    SizedBox(height: isMobile ? 6 : 10),
                    Text(
                      tarea.descripcion!,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Color(0xFF4A4A4A),
                        height: 1.4,
                        fontSize: isMobile ? 11 : 14,
                      ),
                      maxLines: isMobile ? 1 : null,
                      overflow: isMobile ? TextOverflow.ellipsis : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildInfoChip(context, Icons.schedule, "${tarea.duracion} min"),
              SizedBox(width: isMobile ? 6 : 10),
              if (tarea.fecha != null)
                _buildInfoChip(
                  context,
                  Icons.event,
                  "${tarea.fecha!.day}/${tarea.fecha!.month} ${tarea.fecha!.hour}:${tarea.fecha!.minute.toString().padLeft(2, '0')}",
                ),
              if (tarea.fecha != null)
                SizedBox(width: isMobile ? 6 : 10),
              _buildInfoChip(context, Icons.label, tarea.tipoTarea),
            ],
          ),
        ),
        if (!esLibre) ...[
          SizedBox(height: isMobile ? 12 : 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            child: LinearProgressIndicator(
              value: completada ? 1 : 0.35,
              minHeight: isMobile ? 8 : 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
        SizedBox(height: isMobile ? 8 : 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: ElevatedButton.icon(
                icon: Icon(
                  esLibre ? Icons.playlist_add : (completada ? Icons.check_circle : Icons.check),
                  color: Colors.white,
                  size: isMobile ? 14 : 18,
                ),
                label: Text(
                  actionLabel,
                  style: TextStyle(fontSize: isMobile ? 11 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 20,
                    vertical: isMobile ? 6 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 14),
                  ),
                  elevation: disableAction ? 0 : 4,
                ),
                onPressed: disableAction ? null : onPrimaryAction,
              ),
            ),
          ],
        ),
      ],
    ),
    ),
  );
}

Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isMobile = MediaQuery.of(context).size.width < 600;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 8 : 10,
      vertical: isMobile ? 4 : 6,
    ),
    decoration: BoxDecoration(
      color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
      border: Border.all(color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: themeProvider.isDarkMode ? Colors.white70 : Color(0xFF4A4A4A),
          size: isMobile ? 12 : 14,
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Color(0xFF4A4A4A),
            fontSize: isMobile ? 10 : 12,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProjectImage(BuildContext context, String? url, String proyecto) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isMobile = MediaQuery.of(context).size.width < 600;
  final imageSize = isMobile ? 50.0 : 70.0;
  final borderRadius = isMobile ? 12.0 : 18.0;
  final fontSize = isMobile ? 16.0 : 22.0;

  final placeholder = Container(
    width: imageSize,
    height: imageSize,
    decoration: BoxDecoration(
      color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: themeProvider.isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.1)),
    ),
    child: Center(
      child: Text(
        proyecto.isNotEmpty ? proyecto[0].toUpperCase() : '?',
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : Color(0xFF4A4A4A),
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    ),
  );

  if (url == null || url.isEmpty) return placeholder;

  return Container(
    width: imageSize,
    height: imageSize,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: themeProvider.isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.1)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(

      children: [

        Icon(icon, color: iconColor, size: isMobile ? 24 : 30),

        SizedBox(height: isMobile ? 4 : 5),

        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        Text(
          "$count",
          style: TextStyle(
            color: textColor,
            fontSize: isMobile ? 16 : 20,
          ),
        ),

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

          leading: const Icon(Icons.bar_chart, color: Colors.white70),

          title: const Text('Mi Progreso', style: TextStyle(color: Colors.white)),

          onTap: () {

            Navigator.pop(context);

            Navigator.push(

              context,

              MaterialPageRoute(builder: (_) => const DashboardPage()),

            );

          },

        ),

        // 🆕 Briefing Diario
        ListTile(
          leading: const Icon(Icons.wb_sunny, color: Color(0xFF5BE4A8)),
          title: const Text('Briefing del Día', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Tu plan diario', style: TextStyle(color: Colors.white60, fontSize: 12)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BriefingDiarioPage()),
            );
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

        ListTile(

          leading: const Icon(Icons.logout, color: Colors.redAccent),

          title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),

          onTap: () {

            cerrarSesion(context);

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

  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      final primaryTextColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
      final secondaryTextColor = themeProvider.isDarkMode ? Colors.white70 : Colors.black54;
      return Stack(

        children: [

          // Fondo dinámico según tema
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeProvider.isDarkMode
                    ? [
                        const Color(0xFF0A0E27), // FLOW dark
                        const Color(0xFF1A1F3A), // FLOW dark card
                        const Color(0xFF0A0E27), // FLOW dark
                      ]
                    : [
                        const Color(0xFFF5F5F7), // Gris muy claro
                        const Color(0xFFFFFFFF), // Blanco puro
                        const Color(0xFFF5F5F7), // Gris muy claro
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Patrón sutil de puntos con animación
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedMinimalPattern(
                    animationValue: _fadeAnimation.value,
                    isDarkMode: themeProvider.isDarkMode,
                  ),
                );
              },
            ),
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

                            Text("Hola 👋", style: TextStyle(color: secondaryTextColor, fontSize: 14)),

                            Text(

                              userName ?? "Usuario",

                              style: TextStyle(color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),

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
    },
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























/// CustomPainter para patrón minimalista de puntos
class MinimalDotPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const double dotRadius = 1.0;
    const double spacing = 40.0;

    // Patrón de puntos muy sutil
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }

    // Líneas horizontales sutiles
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.01)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 100; y < size.height; y += 150) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



/// CustomPainter para patrón minimalista con animación de pulsos
class AnimatedMinimalPattern extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  AnimatedMinimalPattern({
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Opacidad pulsante
    final pulseAlpha = 0.02 + (animationValue * 0.03);

    // Patrón de puntos sutiles - blanco en modo oscuro, negro en modo claro
    final dotPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.fill;

    const double dotRadius = 1.5;
    const double spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }

    // Líneas de conexión sutiles que pulsan
    final linePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: 0.01 + (animationValue * 0.02))
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Líneas diagonales minimalistas
    final path1 = Path();
    path1.moveTo(size.width * 0.2, 0);
    path1.lineTo(size.width, size.height * 0.8);
    canvas.drawPath(path1, linePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.3);
    path2.lineTo(size.width * 0.7, size.height);
    canvas.drawPath(path2, linePaint);

    // Círculos sutiles con escala pulsante
    final pulseScale = 0.95 + (animationValue * 0.1);
    final circlePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: 0.02 + (animationValue * 0.02))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      100 * pulseScale,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.7),
      120 * pulseScale,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant AnimatedMinimalPattern oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}
