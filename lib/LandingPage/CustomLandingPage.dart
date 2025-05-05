import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CustomLandingPage extends StatefulWidget {
  const CustomLandingPage({Key? key}) : super(key: key);

  @override
  State<CustomLandingPage> createState() => _CustomLandingPageState();
}
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
class _CustomLandingPageState extends State<CustomLandingPage> {
  late VideoPlayerController _backgroundVideo;
  late YoutubePlayerController _youtubeController;

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

      _youtubeController = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId('https://www.youtube.com/watch?v=r9QIUY9tZy0')!,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // ⚡ No autoPlay para que no lo bloquee Chrome
          mute: false,
          controlsVisibleAtStart: true,
          enableCaption: false,
        ),
      );

  }

  @override
  void dispose() {
    _backgroundVideo.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.jpg', height: 40),
            const SizedBox(width: 8),
            const Text('VASTORIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          _buildHeaderButton('Inicio'),
          _buildHeaderButton('Ecosistema'),
          _buildHeaderButton('Productos'),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signUp');
            },
            child: const Text('Registrarse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
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
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroSection(),
                  _buildAboutSection(),
                  _buildVideoSection(),
                  _buildProductsSection(),
                  _buildStartNowSection(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

Widget _buildHeroSection() {
  return Container(
    height: MediaQuery.of(context).size.height * 1.1, // un poquito más alto
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo muy grande y bien ajustado en círculo
        ClipOval(
          child: Container(
            color: Colors.white10,
            width: 350,
            height: 350,
            child: Image.asset(
              'assets/logovastoria.png',
              fit: BoxFit.cover, // Para que llene todo el círculo
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'VASTORIA',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '"En el vasto mundo de talentos, solo algunos hacemos historia."',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ecosistema de Talento y Proyectos Colaborativos',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        const Text(
          'Construimos el futuro de los proyectos colaborativos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.white54),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text(
            'Comienza Gratis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
    ),
  );
}




  Widget _buildAboutSection() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: const [
          Text('¿Qué es Vastoria?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 16),
          Text(
            'Vastoria es un ecosistema digital que conecta talento, proyectos y habilidades para transformar ideas en realidades, organizando equipos multidisciplinarios y visibilizando el esfuerzo de cada persona.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }
Widget _buildVideoSection() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    color: Colors.black,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conoce FLOW en acción',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // 🖥️ Pantallas grandes
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AspectRatio(
                      aspectRatio: 16/9,
                      child: kIsWeb 
                        ? InAppWebView(
                            initialUrlRequest: URLRequest(
                              url:WebUri('https://www.youtube.com/embed/r9QIUY9tZy0'),
                            ),
                            initialOptions: InAppWebViewGroupOptions(
                              crossPlatform: InAppWebViewOptions(
                                mediaPlaybackRequiresUserGesture: false,
                                javaScriptEnabled: true,
                              ),
                            ),
                          )
                        : YoutubePlayer(
                            controller: _youtubeController,
                            showVideoProgressIndicator: true,
                          ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 2,
                    child: _buildFlowFeatures(),
                  ),
                ],
              );
            } else {
              // 📱 Pantallas pequeñas
              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16/9,
                    child: kIsWeb 
                      ? InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri('https://www.youtube.com/embed/r9QIUY9tZy0'),
                          ),
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              mediaPlaybackRequiresUserGesture: false,
                              javaScriptEnabled: true,
                            ),
                          ),
                        )
                      : YoutubePlayer(
                          controller: _youtubeController,
                          showVideoProgressIndicator: true,
                        ),
                  ),
                  const SizedBox(height: 30),
                  _buildFlowFeatures(),
                ],
              );
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildFlowFeatures() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        "💡 Desde el momento en que surge una idea, FLOW te acompaña:",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 20),
      _FeatureItem("✔️ Reuniones presenciales con transcripción automática (IA Speech-to-Text)"),
      _FeatureItem("✔️ Resumen automático de reuniones con inteligencia artificial"),
      _FeatureItem("✔️ Generación inteligente de tareas a partir de ideas o reuniones"),
      _FeatureItem("✔️ Organización automática de tareas por prioridad, duración y responsables"),
      _FeatureItem("✔️ Gestión de tareas por proyectos (asignación, edición, tipo, dificultad)"),
      _FeatureItem("✔️ Trazabilidad del progreso del proyecto (estado y tiempo)"),
      _FeatureItem("✔️ Asignación automática por habilidades (match inteligente)"),
      _FeatureItem("✔️ Sistema de puntos y habilidades del usuario (ranking y evolución)"),
      _FeatureItem("✔️ Sincronización directa con Google Calendar"),
      _FeatureItem("✔️ Ambientes visuales y dinámicos (modo concentrado)"),
      SizedBox(height: 30),
      Text(
        "🔐 Cuenta demo:",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      _FeatureItem("👤 Usuario: demo@flow.com"),
      _FeatureItem("🔑 Contraseña: flow1234"),
    ],
  );
}




  Widget _buildProductsSection() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Text('Nuestros Productos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildProductCard(
            title: 'FLOW',
            description: 'Organiza tus proyectos, conecta tareas y potencia tu talento.',
            imageAsset: 'assets/logo.jpg',
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({required String title, required String description, required String imageAsset, required VoidCallback onTap}) {
    return Card(
      color: Colors.blueGrey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset(imageAsset, width: 120, height: 120),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Explorar FLOW', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartNowSection() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('¿Listo para comenzar?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black,
      child: const Center(
        child: Text('© 2025 VASTORIA - Todos los derechos reservados', style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}
