import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPageInnova.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/categoria_migration.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ProponerIdeaPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ProponerIdeaPageNuevo.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/VerIdeasPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/Historicodeideaspage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/geolocator.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/mapa_dique_tiempo_real.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Innova/WorkflowMockupPage.dart';
import 'package:video_player/video_player.dart';

class _CarruselVisual extends StatefulWidget {
  final List<String> fondos;
  const _CarruselVisual({required this.fondos});

  @override
  State<_CarruselVisual> createState() => _CarruselVisualState();
}

class _CarruselVisualState extends State<_CarruselVisual> {
  int _indiceActual = 0;
  VideoPlayerController? _videoController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cambiarContenido();
  }

  void _cambiarContenido() async {
    final actual = widget.fondos[_indiceActual];
    _indiceActual = (_indiceActual + 1) % widget.fondos.length;

    if (actual.endsWith('.mp4')) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.asset(actual);
      await _videoController!.initialize();
      _videoController!.setLooping(false);
      _videoController!.setVolume(0);
      _videoController!.play();
      setState(() {});

      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _cambiarContenido();
        }
      });
    } else {
      _videoController?.pause();
      setState(() {});
      _timer = Timer(const Duration(seconds: 5), _cambiarContenido);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fondoActual = widget.fondos[(_indiceActual - 1 + widget.fondos.length) % widget.fondos.length];

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _videoController != null && _videoController!.value.isInitialized
            ? VideoPlayer(_videoController!)
            : Image.asset(fondoActual, fit: BoxFit.cover),
      ),
    );
  }
}

class HomeEmpresaPage extends StatefulWidget {
  @override
  _HomeEmpresaPageState createState() => _HomeEmpresaPageState();
}

class _HomeEmpresaPageState extends State<HomeEmpresaPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Tarea> tareasAsignadas = [];
  List<Tarea> tareasLibres = [];
  String? uidEmpresa;
  String? empresaNombre;
  String? empresaCorreo;

final List<String> _fondos  = [
  'assets/innova/videorelave1.mp4',
  'assets/innova/videorelave2.mp4',
  'assets/innova/imagenrelave1.png',
  'assets/innova/imagenrelave2.png',
  'assets/innova/imagenrelave3.png',
  'assets/innova/imagenrelave4.png',
  'assets/innova/imagenrelave5.png',
  'assets/innova/imagenrelave6.png',
  'assets/innova/imagenrelave7.png',
  'assets/innova/imagenrelave8.png',
  'assets/innova/imagenrelave9.png',
  'assets/innova/imagenrelave10.png',
  'assets/innova/imagenrelave11.png',
  'assets/innova/imagenrelave12.png',
];



int _indiceActual = 0;
VideoPlayerController? _videoController;
late Timer _timer;


@override
void initState() {
  super.initState();
  _runCategoriaMigration();
  _cargarTareas();
  _cambiarFondo();
}

Future<void> _runCategoriaMigration() async {
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString("uid_empresarial");
  if (uid == null) return;
  await CategoriaMigration.runIfNeeded(uid: uid);
}


@override
void dispose() {
  _videoController?.dispose();
  _timer.cancel();
  super.dispose();
}

void _cambiarFondo() async {
  final actual = _fondos[_indiceActual];
  _indiceActual = (_indiceActual + 1) % _fondos.length;

  if (actual.endsWith('.mp4')) {
    try {
      _videoController?.dispose();
      final controller = VideoPlayerController.asset(actual);
      await controller.initialize();
      controller.setLooping(false);
      controller.setVolume(0);
      controller.play();

      controller.addListener(() {
        if (controller.value.position >= controller.value.duration && mounted) {
          _cambiarFondo();
        }
      });

      setState(() {
        _videoController = controller;
      });
    } catch (e) {
      print("Error cargando video: $e");
      _cambiarFondo(); // salta al siguiente
    }
  } else {
    _videoController?.dispose();
    _videoController = null;
    setState(() {});
    _timer = Timer(const Duration(seconds: 5), _cambiarFondo);
  }
}


  Future<void> _cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("uid_empresarial");
    final nombre = prefs.getString("empresaNombre");
    final correo = prefs.getString("empresaCorreo");
    if (uid == null) return;
    uidEmpresa = uid;
    empresaNombre = nombre;
    empresaCorreo = correo;

    final proyectosSnapshot = await _firestore
        .collection("proyectos")
        .where("participantes", arrayContains: uid)
        .get();

    List<Tarea> asignadas = [];
    List<Tarea> libres = [];

    for (var proyectoDoc in proyectosSnapshot.docs) {
      final data = proyectoDoc.data();
      final tareasData = data["tareas"] as List<dynamic>? ?? [];
      for (var tareaJson in tareasData) {
        final tarea = Tarea.fromJson(tareaJson);
        if (tarea.responsables == uid) {
          asignadas.add(tarea);
        // ignore: unnecessary_null_comparison
        } else if (tarea.responsables == null) {
          libres.add(tarea);
        }
      }
    }

    setState(() {
      tareasAsignadas = asignadas;
      tareasLibres = libres;
    });
  }

  Widget _construirListaTareas(String titulo, List<Tarea> tareas) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(80), // ✅ equivalente a 0.75 de opacidad
 // translúcido
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // efecto vidrio
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Text(
            titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
          ),
          children: tareas.map((tarea) => ListTile(
            leading: Icon(Icons.task_alt, color: Colors.blue[800]),
            title: Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Tipo: ${tarea.tipoTarea}"),
          )).toList(),
        ),
      ),
    ),
  );
}


  Widget _buildResumenTareas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildResumenCard("Asignadas", tareasAsignadas.length, Colors.blueAccent),
          _buildResumenCard("Libres", tareasLibres.length, Colors.orangeAccent),
          _buildResumenCard("Total", tareasAsignadas.length + tareasLibres.length, Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _buildResumenCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildBotonesCentrales() {
    final Color colorBoton = const Color(0xFF5B4115);

    final botones = [
      {'texto': "CREAR IDEA", 'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProponerIdeaPageEstiloInnova()))},
      {'texto': "HISTÓRICO DE IDEAS", 'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => HistoricoDeIdeasPage()))},
      {'texto': "PROYECTOS EN PROCESO", 'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProyectosPageInnova()))},
      {'texto': "PONLO A PRUEBA", 'onTap': () {/* … */}},
      // {'texto': "MAPA", …}  ⟵  fuera del grid
    ];


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(), // para que no interfiera con el scroll general
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: botones.map((btn) {
          return ElevatedButton(
            onPressed: btn['onTap'] as void Function(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBoton,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              btn['texto'] as String, // 👈 evita el error aquí
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

Widget _buildCarruselDeVideos() {
  final actualFondo = _fondos[(_indiceActual - 1 + _fondos.length) % _fondos.length];

  return Container(
    height: 200,
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _videoController != null && _videoController!.value.isInitialized
          ? VideoPlayer(_videoController!)
          : Image.asset(actualFondo, fit: BoxFit.cover),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/vortystorm.jpg'),
                    radius: 24,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    empresaNombre ?? "Empresa",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (empresaCorreo != null)
                    Text(
                      empresaCorreo!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  const Text(
                    "Conquista tus proyectos 🚀",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Mis Proyectos'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProyectosPageInnova())),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Proponer Idea'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProponerIdeaPageEstiloInnova())),
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Ver Ideas'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerIdeasPage())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        elevation: 4,
        titleSpacing: 16,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/vortystorm.jpg'),
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                empresaNombre ?? "Empresa",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // ← aquí:
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => obtenerYProcesarUbicacion(context),
              child: CircleAvatar(
                radius: 22,                       // tamaño del círculo
                backgroundColor: const Color(0xFF5B4115), // dorado-negro que ya usas
                child: const Icon(Icons.map_outlined,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ],

      ),

        body: Stack(
          children: [
            // Fondo
            Positioned.fill(
              child: Image.asset(
                'assets/nucleo_fondo.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Contenido desplazable
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 350),
                
                  // Botones
                  _buildBotonesCentrales(),


                  // Carrusel
                  _buildCarruselDeVideos(),
                ],
              ),
            ),
          ],
        ),

    );
  }
}
