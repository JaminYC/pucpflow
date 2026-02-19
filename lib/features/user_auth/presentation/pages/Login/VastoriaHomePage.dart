import 'package:flutter/material.dart';
import 'package:pucpflow/Cafillari/screens/home/CafillariHomePage.dart' show CafillariHomePage;
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart'; // HomePage de FLOW
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/FlowVitakua/presentationVitakua/pagesVitakua/vitakua_home_page.dart';
import 'package:pucpflow/VastoriaRutasPeru/presentation/screens/peru_dashboard_screen.dart';


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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/ecosystem',
              (route) => false,
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logovastoria.png',
              height: isMobile ? 28 : 40,
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Flexible(
              child: Text(
                'VASTORIA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: isMobile ? 1 : 2,
                  fontSize: isMobile ? 14 : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildUserInfo(),
            ),
        ],
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
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildHeroSection(),
                  SizedBox(height: isMobile ? 24 : 40),
                  Text(
                    "Programas Disponibles",
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.auto_graph,
                    title: "FLOW",
                    description: "Plataforma de gestion de proyectos, ideas y reuniones inteligentes.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
                    },
                  ),
                  SizedBox(height: isMobile ? 16 : 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.local_cafe,
                    title: "CAFILLARI",
                    description: "La nueva generacion del cafe peruano: frescura, tecnologia y raices andinas.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CafillariHomePage()));
                    },
                  ),
                  SizedBox(height: isMobile ? 16 : 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.water_drop,
                    title: "FLOW VITAKUA",
                    description: "Tecnologia inteligente para acceso justo y sostenible al agua.",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VitakuaHomePage()));
                    },
                  ),
                  SizedBox(height: isMobile ? 16 : 30),
                  _buildProgramButton(
                    context: context,
                    icon: Icons.map_outlined,
                    title: "VASTORIA RUTAS PERU",
                    description: "Mapa interactivo por departamentos y rutas destacadas.",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PeruDashboardScreen()),
                      );
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 40),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline,
          color: Colors.white70,
          size: isMobile ? 18 : 20,
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Flexible(
          child: Text(
            displayName,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 13 : 16,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: Column(
        children: [
          ClipOval(
            child: Container(
              width: isMobile ? 80 : 120,
              height: isMobile ? 80 : 120,
              color: Colors.white10,
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              child: Image.asset('assets/logovastoria.png', fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Bienvenido a Vastoria',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Donde las ideas toman vida.',
            style: TextStyle(
              fontSize: isMobile ? 13 : 16,
              color: Colors.white70,
            ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isMobile ? 20 : 50),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 12 : 16,
          horizontal: isMobile ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          borderRadius: BorderRadius.circular(isMobile ? 20 : 50),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isMobile ? 24 : 32,
              color: Colors.amberAccent,
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 3 : 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: isMobile ? 12 : 14,
                    ),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: isMobile ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }
}

