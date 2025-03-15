import 'dart:io' show Platform; // 🟢 Para detectar Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // 🔹 Para detectar si está en Web
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/UserProfileForm.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'package:pucpflow/global/common/toast.dart'; // 🟢 Método para mostrar mensajes
import 'package:video_player/video_player.dart';
class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  State<CustomLoginPage> createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // 🟢 Solo para Android/iOS
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late VideoPlayerController _backgroundVideo;

  bool _isLoggingIn = false;
    @override
    void initState() {
      super.initState();

      _backgroundVideo = VideoPlayerController.asset("assets/background.mp4")
        ..initialize().then((_) {
          _backgroundVideo.setLooping(true);
          _backgroundVideo.setVolume(0); // Silencioso
          _backgroundVideo.play();
          setState(() {});
        });
    }
    @override
    void dispose() {
      _backgroundVideo.dispose(); // ⬅️ Muy importante
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

  /// 🔹 Iniciar sesión con email y contraseña
  Future<void> _logInWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      showToast(message: "Please enter a valid email");
      return;
    }
    if (_passwordController.text.isEmpty) {
      showToast(message: "Please enter your password");
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is badly formatted.";
          break;
        default:
          errorMessage = "An unexpected error occurred.";
      }
      showToast(message: errorMessage);
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  /// 🔹 Iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // 🌐 Web: Usar FirebaseAuth.signInWithPopup
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(authProvider);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 📱 Android/iOS: Usar GoogleSignIn
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          showToast(message: "Sign in cancelled");
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      } else {
        throw Exception("Unsupported platform");
      }

      final User? user = userCredential.user;
      if (user == null) return;

      String userId = user.uid;
      String userEmail = user.email ?? "No email";
      String userName = user.displayName ?? "No name";

      // 🔹 Verificar si el usuario ya existe en Firestore antes de crearlo
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userId).set({
          "uid": userId,
          "email": userEmail,
          "full_name": userName,
          "created_at": FieldValue.serverTimestamp(),
          "lifestyle": {
            "wake_up_time": "06:30 AM",
            "sleep_time": "11:00 PM",
            "exercise_days": ["Monday", "Wednesday", "Friday"],
            "exercise_type": "Cardio",
          },
          "preferences": {
            "theme": "light",
            "language": "en",
            "notifications": true,
          },
          "performance": {
            "global_score": 0,
            "tasks_completed": 0,
            "tasks_pending": 0,
          },
          "schedule": {
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": [],
          },
        });

        // 🔹 Redirigir al formulario de perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserProfileForm(userId: userId)),
        );
      } else {
        // 🔹 Usuario ya registrado → Redirigir a HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      showToast(message: "FirebaseAuth Error: ${e.message}");
    } on Exception catch (e) {
      showToast(message: "Error during Google sign-in: $e");
    }
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        // 🎬 Fondo de video
        if (_backgroundVideo.value.isInitialized == true)
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

        // 📱 Contenido encima del video
        SafeArea(
          child: Container(
            color: Colors.black.withOpacity(0.4), // ✅ Oscurece un poco para mejor lectura
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          _buildLogo(),
                          const SizedBox(height: 30),
                          _buildTextField(_emailController, "Email", false),
                          const SizedBox(height: 10),
                          _buildTextField(_passwordController, "Password", true),
                          const SizedBox(height: 20),
                          _buildLoginButton(),
                          const SizedBox(height: 10),
                          _buildGoogleSignInButton(),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            ),
                            child: const Text(
                              "¿No tienes cuenta? Regístrate",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.black.withOpacity(0.5),
                  child: const Text(
                    "Aplicación desarrollada por VASTORIA © 2025.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF7F7F7),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLogo() {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Color(0xFF133E87), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipOval(
      child: Image.asset('assets/logo.jpg', height: 120, width: 120, fit: BoxFit.cover),
    ),
  );
}

Widget _buildTextField(TextEditingController controller, String hint, bool obscureText) {
  return Center(
    child: SizedBox(
      width: 280, // ✅ Más delgado (ajústalo según diseño)
      height: 42,  // ✅ Más compacto en altura
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFFFFFAEC),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFFFFAEC), fontSize: 14),
          filled: true,
          fillColor: Color(0xFF3D3D3D),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 🔹 Compacto
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );
}



Widget _buildLoginButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF133E87), // verde-gris equilibrado
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: _logInWithEmailAndPassword,
    child: _isLoggingIn
        ? const CircularProgressIndicator(color: Color(0xFFFFFAEC)) // blanco suave
        : const Text("INGRESAR", style: TextStyle(fontSize: 16, color: Color(0xFFFFFAEC))),
  );
}


Widget _buildGoogleSignInButton() {
  return SizedBox(
    height: 50, // 🔒 Altura fija del botón
    child: ElevatedButton(
      onPressed: _signInWithGoogle,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D3D3D),
        padding: const EdgeInsets.symmetric(horizontal: 24), // Sin vertical para no forzar altura
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔍 Logo de tamaño más grande
          Container(
            height: 60,
            width: 60,
            child: Image.asset('assets/google_logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.login, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Continuar con Google",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

}  