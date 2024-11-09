import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'package:pucpflow/global/common/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        showToast(message: "Inicio de sesión cancelado");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      showToast(message: "Error al iniciar sesión con Google: $e");
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
                      fontSize: 36, // Tamaño de fuente más grande
                      fontWeight: FontWeight.w900, // Fuente más gruesa y llamativa
                      color: Color.fromARGB(255, 255, 255, 255), // Color blanco para mayor contraste
                      letterSpacing: 2.0, // Espaciado entre letras para darle un toque moderno
                      shadows: [
                        Shadow(
                          blurRadius: 8.0, // Suaviza el borde de la sombra
                          color: Color.fromARGB(66, 187, 132, 183), // Sombra suave en negro con opacidad
                          offset: Offset(2, 2), // Desplazamiento de la sombra
                        ),
                      ],
                      fontFamily: 'Roboto', // Cambia la fuente si tienes una fuente minimalista cargada
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
                      Text("Become a member",style: TextStyle(color: Colors.white),),
                      Text("Forgot password?",style: TextStyle(color: Colors.white),),
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
