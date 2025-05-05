import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pucpflow/LandingPage/CustomLandingPage.dart' show CustomLandingPage;
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_empresa_page.dart' show HomeEmpresaPage;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _navegacionRealizada = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _verificarLogin());
  }

  Future<void> _verificarLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool esLoginEmpresarial = prefs.getBool("login_empresarial") ?? false;
    final uid = prefs.getString("uid_empresarial");
    final firebaseUser = FirebaseAuth.instance.currentUser;

    debugPrint("🧪 Login Empresarial: $esLoginEmpresarial");
    debugPrint("🧪 FirebaseAuth User: ${firebaseUser?.uid}");
    debugPrint("🧪 UID: ${uid ?? firebaseUser?.uid}");

    if (esLoginEmpresarial && uid != null) {
      _navegar(HomeEmpresaPage()); // <- esta es tu vista empresarial correcta
    } else if (firebaseUser != null) {
      _navegar( HomePage());
    } else {
      debugPrint("🔒 No se detectó login. Mostrando video splash.");
      await _initializeVideo();
    }
  }

  void _navegar(Widget destino) {
    if (!mounted || _navegacionRealizada) return;
    _navegacionRealizada = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  Future<void> _initializeVideo() async {
  _controller = VideoPlayerController.asset("assets/VideoDelLogo.mp4");

  try {
    await _controller!.initialize();
    _controller!
      ..setLooping(false)
      ..setVolume(0)
      ..play();

    setState(() {}); // para que se muestre el video

    _controller!.addListener(() {
      if (!mounted || _navegacionRealizada) return;
      final isFinished = _controller!.value.position >= _controller!.value.duration;

      if (isFinished) {
        _navegar(const CustomLandingPage()); // ⬅️ Ahora navega al Landing
      }
    });
  } catch (e) {
    debugPrint("❌ Error al inicializar el video: $e");
    _navegar(const CustomLandingPage()); // fallback si el video falla
  }
}

  @override
  void dispose() {
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              ClipOval(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Transform.scale(
                    scale: 1.2,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            const SizedBox(height: 20),
            const Text(
              "Bienvenido a Vastoria",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
