import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/UserProfileForm.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'package:pucpflow/global/common/toast.dart'; // Asume que tienes un método para mostrar mensajes

class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  State<CustomLoginPage> createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggingIn = false;

  @override
  void dispose() {
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

  Future<void> _signInWithGoogle() async {
  try {
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

    UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Obtener el UID del usuario actual
      String userId = userCredential.user!.uid;

      // Verificar si el usuario ya existe en Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Crear el documento en Firestore para el usuario
        await _firestore.collection('users').doc(userId).set({
          'email': userCredential.user!.email ?? "No email",
          'full_name': googleUser.displayName ?? "No name",
          'created_at': FieldValue.serverTimestamp(),
          'lifestyle': {
            'wake_up_time': "06:30 AM",
            'sleep_time': "11:00 PM",
            'exercise_days': ["Monday", "Wednesday", "Friday"],
            'exercise_type': "Cardio",
          },
          'preferences': {
            'theme': 'light',
            'language': 'en',
            'notifications': true,
          },
          'performance': {
            'global_score': 0,
            'tasks_completed': 0,
            'tasks_pending': 0,
          },
          'schedule': {
            'monday': [],
            'tuesday': [],
            'wednesday': [],
            'thursday': [],
            'friday': [],
            'saturday': [],
            'sunday': [],
          },
        });
        // Redirigir al formulario de perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileForm(userId: userId),
          ),
        );
      } else {
        // Si el usuario ya existe, redirigir a la HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    }
  } catch (e) {
    showToast(message: "Error during Google sign-in: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.webp',
                        height: 300,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  const Center(
                    child: Text(
                      "PUCP FLOW",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo de correo electrónico
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  // Campo de contraseña
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),

                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _logInWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isLoggingIn
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "LOG IN",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 10),

                  // Botón para Google Sign-In
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón de registro
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Texto de Términos y Condiciones
                  Text(
                    "By tapping 'Continue' above, you agree to our Terms of Use and Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
