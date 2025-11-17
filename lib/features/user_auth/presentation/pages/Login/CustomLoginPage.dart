import 'dart:io' show Platform; // 🟢 Para detectar Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // 🔹 Para detectar si está en Web
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/UserProfileForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/login_empresarial_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'package:pucpflow/global/common/toast.dart';
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/app/splash_screen/splash_screen.dart'; // Importa la pantalla de Splash
import 'package:pucpflow/features/user_auth/presentation/pages/Login/VastoriaHomePage.dart';
class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  State<CustomLoginPage> createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _empresaUsuarioController = TextEditingController();
  final TextEditingController _empresaContrasenaController = TextEditingController();

  bool _isNavigating = false; // Agrega esto como variable global dentro de tu StatefulWidget

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
    clientId: kIsWeb ? "547054267025-62eputqjlamebrmshg37rfohl9s10q0c.apps.googleusercontent.com" : null,
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  late VideoPlayerController _backgroundVideo;

  bool _isLoggingIn = false;

  bool _isSigningIn = false;

  bool _navegando = false; // Al nivel del widget


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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logInWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      showToast(message: "Please enter a valid email");
      return;
    }
    if (_passwordController.text.isEmpty) {
      showToast(message: "Please enter your password");
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VastoriaHomePage()));
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
      setState(() => _isLoggingIn = false);
    }
  }

Future<void> _signInWithGoogle() async {
  if (_isNavigating) return;

  try {
    if (_firebaseAuth.currentUser != null) {
      _isNavigating = true;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      return;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      showToast(message: "Inicio de sesión cancelado.");
      return;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    _isNavigating = true;

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "email": user.email ?? "No email",
        "full_name": user.displayName ?? "No name",
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

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserProfileForm(userId: user.uid)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    }

  } catch (e) {
    _isNavigating = false;
    showToast(message: "Error al iniciar sesión con Google: $e");
  }
}

Future<void> _loginEmpresarial() async {
  final String username = _empresaUsuarioController.text.trim();
  final String password = _empresaContrasenaController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Por favor completa todos los campos")),
    );
    return;
  }

  try {
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .where("password", isEqualTo: password)
        .where("rol", isEqualTo: "empresa")
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final userDoc = query.docs.first;
      final uid = userDoc.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("login_empresarial", true);
      await prefs.setString("uid_empresarial", uid);
      await prefs.reload();

      debugPrint("➡️ Login empresarial detectado. UID: $uid");

      if (!mounted) return;

      // Espera un microtask antes de navegar (esto evita el Future already completed)
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Usuario o contraseña incorrectos")),
      );
    }
  } catch (e) {
    debugPrint("❌ Error en login empresarial: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Error al intentar iniciar sesión")),
    );
  }
}




@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
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
        SafeArea(
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header superior con botón de regreso a Vastoria
                _buildVastoriaHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          // Header Comunidad Vastoria
                          const Text(
                            'COMUNIDAD VASTORIA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 2.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'FLOW',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gestión de Proyectos con IA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white60,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _buildLogo(),
                          const SizedBox(height: 30),
                          /// 🔹 Login estándar con email
                          _buildTextField(_emailController, "Email", false),
                          const SizedBox(height: 10),
                          _buildTextField(_passwordController, "Password", true),
                          const SizedBox(height: 10),
                          _buildLoginButton(),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.white70),
                          const SizedBox(height: 10),

                          /// 🔹 Login empresarial personalizado
                          const Text("Ingreso Empresarial",
                              style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginEmpresarialPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[800],
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Ingreso Empresarial", style: TextStyle(color: Colors.white)),
                          ),

                          const SizedBox(height: 20),
                          _buildGoogleSignInButton(),
                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignUpPage()),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Parte del ecosistema VASTORIA",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFF7F7F7), fontSize: 11, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "© 2025 Vastoria. Todos los derechos reservados.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
                      ),
                    ],
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

  Widget _buildVastoriaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Botón de regreso
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (kIsWeb) {
                  // En web, navegar a la landing del ecosistema
                  Navigator.pushReplacementNamed(context, '/ecosystem');
                } else {
                  // En móvil, mostrar mensaje o no hacer nada
                  showToast(message: "Usa la navegación del sistema");
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'VASTORIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Ecosistema',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Logo pequeño opcional
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logovastoria.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apps,
                  color: Colors.white60,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresarialField(TextEditingController controller, String hint, bool obscureText) {
  return SizedBox(
    width: 280,
    height: 42,
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: Colors.blueGrey[900],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFF133E87), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5)),
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
        width: 280,
        height: 42,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Color(0xFFFFFAEC), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFFFFAEC), fontSize: 14),
            filled: true,
            fillColor: Color(0xFF3D3D3D),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        backgroundColor: const Color(0xFF133E87),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _logInWithEmailAndPassword,
      child: _isLoggingIn
          ? const CircularProgressIndicator(color: Color(0xFFFFFAEC))
          : const Text("INGRESAR", style: TextStyle(fontSize: 16, color: Color(0xFFFFFAEC))),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D3D3D),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
