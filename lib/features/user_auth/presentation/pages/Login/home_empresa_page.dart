import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ProponerIdeaPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ProponerIdeaPageNuevo.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/VerIdeasPage.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Innova/WorkflowMockupPage.dart';
import 'package:video_player/video_player.dart';


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

final List<String> _fondos = [
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
bool _esVideo = false;
VideoPlayerController? _videoController;
late Timer _timer;


@override
void initState() {
  super.initState();
  _cargarTareas();
  _cambiarFondo(); // inicia el ciclo
}


@override
void dispose() {
  _videoController?.dispose();
  _timer.cancel();
  super.dispose();
}


void _iniciarRotacion() {
  _cambiarFondo();
  _timer = Timer.periodic(Duration(seconds: 7), (_) {
    _cambiarFondo();
  });
}

Future<void> _cambiarFondo() async {
  final fondo = _fondos[_indiceActual];
  _indiceActual = (_indiceActual + 1) % _fondos.length;

  if (fondo.endsWith('.mp4')) {
    _esVideo = true;
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(fondo);
    await _videoController!.initialize();
    _videoController!.setVolume(0.0); // 🔇 SILENCIAR
    _videoController!.setLooping(false);
    await _videoController!.play();

    // Esperar duración real del video antes de pasar al siguiente
    final duracion = _videoController!.value.duration;
    Future.delayed(duracion, _cambiarFondo);
  } else {
    _esVideo = false;
    _videoController?.pause();

    // Mostrar imagen durante 5 segundos
    _timer = Timer(const Duration(seconds: 5), _cambiarFondo);
  }

  setState(() {});
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProyectosPage())),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Proponer Idea'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProponerIdeaPage())),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: _esVideo && _videoController?.value.isInitialized == true
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  : Image.asset(
                      _fondos[_indiceActual],
                      key: ValueKey(_fondos[_indiceActual]),
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
            ),
          ),


          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.6))),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "📋 Tareas de la Empresa",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildResumenTareas(),
                  _construirListaTareas("Tareas Asignadas", tareasAsignadas),
                  _construirListaTareas("Tareas Libres", tareasLibres),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )

        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "proyectos",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProyectosPage()));
            },
            icon: const Icon(Icons.folder_open, color: Colors.white),
            label: const Text("Ir a Proyectos", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.tealAccent[700],
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: "Iniciar Idea",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProponerIdeaPage()));
            },
            icon: const Icon(Icons.lightbulb, color: Colors.white),
            label: const Text("Iniciar Idea", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.indigo,
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: "verIdeas",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VerIdeasPage()));
            },
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text("Ver Ideas", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
