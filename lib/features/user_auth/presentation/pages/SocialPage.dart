import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/proyectos/ProyectosPage.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/fondodashboard.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Impacto Social y Proyectos',
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
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🎥 Fondo de video
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // 🌑 Capa oscura para mejor contraste
          Container(color: Colors.black.withOpacity(0.6)),

          // 📦 Contenido principal con botones centrados
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _customButton(
                      context,
                      icon: Icons.folder_open,
                      label: 'Explorar Proyectos',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProyectosPage()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _customButton(
                      context,
                      icon: Icons.map_outlined,
                      label: 'Ver Mapa Interactivo',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 20),
                    _customButton(
                      context,
                      icon: Icons.public,
                      label: 'Mapa PUCP',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 20),
                    _customButton(
                      context,
                      icon: Icons.lightbulb,
                      label: 'Proponer Proyecto',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 20),
                    _customButton(
                      context,
                      icon: Icons.people,
                      label: 'Colaborar con la Comunidad',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
        ),
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
