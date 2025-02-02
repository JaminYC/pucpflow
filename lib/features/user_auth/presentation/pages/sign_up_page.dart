import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/app/splash_screen/welcome_screen.dart';
import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/login_page.dart';
import 'package:pucpflow/global/common/toast.dart';
import 'package:pucpflow/splash_screen/user_profile_service.dart';
import 'UserProfileForm.dart';
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UserProfileService _userProfileService = UserProfileService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_usernameController.text.isEmpty) {
      showToast(message: "Username cannot be empty.");
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      showToast(message: "Please enter a valid email.");
      return;
    }
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      showToast(message: "Password must be at least 6 characters long.");
      return;
    }

    setState(() {
      _isSigningUp = true;
    });

    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    try {
      // Registro en Firebase Authentication
      User? user = await _auth.signUpWithEmailAndPassword(email, password,username,);

      if (user != null) {
        // Guardar datos adicionales en Firestore
        await _userProfileService.createUserProfile(user.uid, {
          'username': username,
          'email': email,
          'google_calendar_events': [],
          'performance': {
            'global_score': 0,
            'tasks_pending': 0,
            'tasks_completed': 0,
          },
          'preferences': {
            'theme': 'light',
            'language': 'es',
            'notifications': true,
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
          'lifestyle': {
            'wake_up_time': "06:30 AM",
            'sleep_time': "11:00 PM",
            'exercise_days': ["Monday", "Wednesday", "Friday"],
            'exercise_type': "Cardio",
          },
        });

        showToast(message: "User successfully created!");

        // Navegar a la pantalla de bienvenida
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileForm(userId: user!.uid),
        ),
      );

      } else {
        showToast(message: "Registration failed. Please try again.");
      }
    } catch (e) {
      showToast(message: "An error occurred: $e");
    } finally {
      setState(() {
        _isSigningUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Logo
              Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.webp', // Cambia a la ruta de tu imagen
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Campo de nombre de usuario
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),

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
              const SizedBox(height: 30),

              // Botón de registro
              GestureDetector(
                onTap: _signUp,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigningUp
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Enlace para iniciar sesión
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
