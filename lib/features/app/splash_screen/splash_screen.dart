import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/CustomLoginPage.dart';
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/login_page.dart';

/// Pantalla de carga (SplashScreen) con una animación en video.
/// Se encarga de mostrar una animación mientras verifica si el usuario está autenticado.
/// Si el usuario está autenticado, lo redirige a la pantalla HomePage.
/// Si el usuario NO está autenticado, lo redirige a la pantalla de inicio de sesión (CustomLoginPage).
class SplashScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller; // Controlador para reproducir el video.
  
  @override
  void initState() {
    super.initState();
    // Inicializa el video de bienvenida que se mostrará en la pantalla de carga.
    _controller = VideoPlayerController.asset("assets/VideoDelLogo.mp4")
      ..initialize().then((_) {
        _controller.setLooping(true); // Hace que el video se reproduzca en bucle.
        _controller.play(); // Reproduce el video automáticamente.
        setState(() {}); // Actualiza la UI cuando el video esté listo.
      });
     
    // Llama a la función que verifica si el usuario está autenticado y lo redirige.
    _checkAuthAndNavigate();
  }

  /// Verifica si el usuario está autenticado y navega a la pantalla correspondiente.
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 5)); // Espera 4 segundos antes de continuar.

    User? user = FirebaseAuth.instance.currentUser; // Obtiene el usuario actual de Firebase Auth.
    
    if (mounted) { // Verifica que el widget siga en la pantalla antes de hacer cambios.
      if (user != null) {
        // Si el usuario está autenticado, lo lleva a HomePage.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false, // Elimina la pantalla de carga de la pila de navegación.
        );
      } else {
        // Si el usuario NO está autenticado, lo lleva a la página de inicio de sesión.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CustomLoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera los recursos del video cuando la pantalla se cierre.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para la animación.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller.value.isInitialized) // Verifica si el video está listo para mostrarse.
                ClipOval(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Transform.scale(
                      scale: 1.2, // 🔥 Zoom fijo al 120%
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center, // Puedes ajustar si lo necesitas (ej. topCenter, bottomCenter)
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 20), // Espaciado entre el video y el texto.
            const Text(
              "Bienvenido a PUCP-FLOW", // Mensaje de bienvenida.
              style: TextStyle(
                color: Colors.white, // Texto en color blanco.
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
