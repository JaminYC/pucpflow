// 📄 PERFIL DE USUARIO REDISEÑADO - perfil_usuario_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth//firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/Usuario/OpenAIAssistantService.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final String uid;

  const PerfilUsuarioPage({super.key, required this.uid});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  UserModel? user;
  bool loading = true;
  late VideoPlayerController _videoController;
  final TextEditingController _tipoController = TextEditingController();

  Map<String, List<String>> categorias = {
    "Cognitivas": ["pensamiento_logico", "planeamiento_estrategico", "toma_de_decisiones"],
    "Organizativas": ["gestion_del_tiempo", "planificacion", "seguimiento"],
    "Creativas": ["propuesta_de_ideas", "diseno_visual", "comunicacion_escrita"],
    "Interpersonales": ["comunicacion_efectiva", "empatia", "liderazgo"],
    "Adaptativas": ["aprendizaje_rapido", "resolucion_de_conflictos", "autonomia"]
  };

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/background.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });
    cargarUsuario();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  Future<void> cargarUsuario() async {
    final data = await FirebaseAuthService().getUserFromFirestore(widget.uid);
    setState(() {
      user = data;
      loading = false;
      _tipoController.text = user?.tipoPersonalidad ?? "";
    });
  }

  Future<void> actualizarPerfilConIA() async {
    if (user != null) {
      setState(() => loading = true);
      user!.tipoPersonalidad = _tipoController.text;
      await OpenAIAssistantService().generarResumenYHabilidades(user!);
      await cargarUsuario();
    }
  }

  List<RadarEntry> generarRadarData() {
    return categorias.entries.map((entry) {
      final subSkills = entry.value;
      final promedio = subSkills.map((s) => user!.habilidades[s] ?? 0).fold(0, (a, b) => a + b) / subSkills.length;
      return RadarEntry(value: promedio.toDouble());
    }).toList();
  }

  Widget _buildSeccionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text("Página Personal",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                offset: Offset(1, 1),
                color: Colors.black,
              ),
            ],
          ),),
      ),
      body: Stack(
        children: [
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          Container(color: Colors.black.withOpacity(0.6)),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSeccionCard(
                  context,
                  title: "Tipo de personalidad",
                  child: TextField(
                    controller: _tipoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ej: INTJ",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (user!.resumenIA != null)
                  _buildSeccionCard(
                    context,
                    title: "Resumen generado por IA",
                    child: Text(user!.resumenIA!, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                _buildSeccionCard(
                  context,
                  title: "Dashboard de habilidades",
                  child: SizedBox(
                    height: 250,
                    child: RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: generarRadarData(),
                            fillColor: Colors.blue.withOpacity(0.4),
                            borderColor: Colors.cyan,
                            entryRadius: 3,
                          )
                        ],
                        radarBackgroundColor: Colors.transparent,
                        titleTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
                        getTitle: (index, _) => RadarChartTitle(text: categorias.keys.elementAt(index)),
                        tickCount: 6,
                        ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.white60),
                        tickBorderData: BorderSide(color: Colors.white24),
                        gridBorderData: const BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                _buildSeccionCard(
                  context,
                  title: "Tareas asignadas",
                  child: Text(
                    user!.tareasAsignadas.isNotEmpty ? user!.tareasAsignadas.join(", ") : "Sin tareas.",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                _buildSeccionCard(
                  context,
                  title: "Puntos totales",
                  child: Text("${user!.puntosTotales}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: actualizarPerfilConIA,
                    child: const Text("Actualizar perfil con IA"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
