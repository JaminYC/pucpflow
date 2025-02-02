import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'UserProfileForm.dart';
import 'package:pucpflow/global/common/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      showToast(message: "Sign-in canceled");
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    User? user = userCredential.user;

    if (user != null) {
      // Verificar si el usuario ya existe en Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Crear un perfil inicial para el usuario
        await _firestore.collection('users').doc(user.uid).set({
          'username': user.displayName ?? "New User",
          'email': user.email,
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

        // Confirmación de guardado
        print("User data saved successfully in Firestore!");

        // Redirigir a la pantalla de completar perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileForm(userId: user.uid),
          ),
        );
      } else {
        // Usuario ya existe, redirigir al HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    }
  } catch (e) {
    showToast(message: "Error during Google Sign-In: $e");
    print("Error during Google Sign-In: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo para toda la pantalla
          Positioned.fill(
            child: Image.asset(
              'assets/gatonegro.jpg', // Ruta a tu imagen
              fit: BoxFit.cover,
            ),
          ),
          // Formulario de inicio de sesión con imagen de fondo dentro del cuadro
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/Mantanegro.jpg'), // Fondo de cuadro
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "PUCP FLOW",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Color.fromARGB(66, 187, 132, 183),
                          offset: Offset(2, 2),
                        ),
                      ],
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Campos de entrada para Usuario y Contraseña
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white.withOpacity(0.7),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white.withOpacity(0.7),
                      filled: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  // Botón de inicio de sesión con Google
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Sign in with Google",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Become a member", style: TextStyle(color: Colors.white)),
                      Text("Forgot password?", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
