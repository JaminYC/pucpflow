import 'package:flutter/material.dart';
import 'package:pucpflow/Cafillari/screens/home/Cafillarihomepage.dart' show CafillariHomePage;
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart'; // HomePage de FLOW
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/FlowVitakua/presentationVitakua/pagesVitakua/vitakua_home_page.dart';


class VastoriaHomePage extends StatefulWidget {
  const VastoriaHomePage({Key? key}) : super(key: key);

  @override
  State<VastoriaHomePage> createState() => _VastoriaHomePageState();
}

class _VastoriaHomePageState extends State<VastoriaHomePage> {
  late VideoPlayerController _backgroundVideo;

  @override
  void initState() {
    super.initState();
    _backgroundVideo = VideoPlayerController.asset("assets/background.mp4")
      ..initialize().then((_) {
        _backgroundVideo.setLooping(true);
        _backgroundVideo.setVolume(0);
        _backgroundVideo.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _backgroundVideo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logovastoria.png', height: 40),
            const SizedBox(width: 8),
            const Text(
              'VASTORIA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const Spacer(),
            _buildUserInfo(),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (_backgroundVideo.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _backgroundVideo.value.size.width,
                  height: _backgroundVideo.value.size.height,
                  child: VideoPlayer(_backgroundVideo),
                ),
              ),
            ),
          Container(color: Colors.black.withOpacity(0.7)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeroSection(),
                  const SizedBox(height: 40),
                  const Text(
                    "Programas Disponibles",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.auto_graph,
                    title: "FLOW",
                    description: "Plataforma de gestión de proyectos, ideas y reuniones inteligentes.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
                    },
                  ),
                  // 🚀 Aquí en el futuro agregaríamos CAFILLARI como otro programa
                  // debajo del botón de FLOW
                  const SizedBox(height: 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.local_cafe,
                    title: "CAFILLARI",
                    description: "La nueva generación del café peruano: frescura, tecnología y raíces andinas.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CafillariHomePage()));
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.water_drop,
                    title: "FLOW VITAKUA",
                    description: "Tecnología inteligente para acceso justo y sostenible al agua.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VitakuaHomePage()));
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? "Usuario";

    return Row(
      children: [
        const Icon(Icons.person_outline, color: Colors.white70, size: 20),
        const SizedBox(width: 6),
        Text(
          displayName,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Center(
      child: Column(
        children: [
          ClipOval(
            child: Container(
              width: 120,
              height: 120,
              color: Colors.white10,
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/logovastoria.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido a Vastoria',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Donde las ideas toman vida.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.amberAccent),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
