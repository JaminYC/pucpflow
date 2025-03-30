import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/app/splash_screen/welcome_screen.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/login_page.dart';
import 'package:pucpflow/global/common/toast.dart';
import 'package:pucpflow/splash_screen/user_profile_service.dart';
import 'UserProfileForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/CustomLoginPage.dart'; // Página de login personalizada

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
      UserModel? user = await _auth.signUpWithEmailAndPassword(email, password, username);

      if (user != null) {
        await _userProfileService.createUserProfile(user.id, {
          'username': user.nombre,
          'email': user.correoElectronico,
          'google_calendar_events': [],
          'performance': {
            'global_score': 0,
            'tasks_pending': 0,
            'tasks_completed': 0,
          },
          'preferences': {
            'theme': 'dark',
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileForm(userId: user.id),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // 🔹 Logo
              Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.webp',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Título
              const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Campo de Username
              _customTextField(_usernameController, "Username"),
              const SizedBox(height: 12),

              // 🔹 Campo de Email
              _customTextField(_emailController, "Email", keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),

              // 🔹 Campo de Password
              _customTextField(_passwordController, "Password", obscureText: true),
              const SizedBox(height: 30),

              // 🔹 Botón Sign Up
              GestureDetector(
                onTap: _signUp,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Degradado morado
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSigningUp
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Enlace para Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomLoginPage()));
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xFF8E2DE2),
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

  // 🔹 Función para estilizar los campos de entrada
  Widget _customTextField(TextEditingController controller, String hintText,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
