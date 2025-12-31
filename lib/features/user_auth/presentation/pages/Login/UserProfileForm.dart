import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/EmotionalForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/IntellectualForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/PhysicalForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/SocialForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Formularios/FinancialForm.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart';
import 'package:pucpflow/LandingPage/VastoriaMainLanding.dart';

class UserProfileForm extends StatelessWidget {
  final String userId;

  const UserProfileForm({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completa tu perfil",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                offset: Offset(1, 1),
                color: Colors.black,
              ),
            ],
          ),
          ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "✨ Que cada uno brille con su propia luz",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "Completa tu perfil y desbloquea tu máximo potencial en cada aspecto de tu vida.",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  _buildTile(
                    context,
                    "Bienestar Físico",
                    "Descubre cómo mejorar tu energía diaria y cuidar tu salud física.",
                    Icons.fitness_center,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PhysicalForm(userId: userId)),
                    ),
                  ),
                  _buildTile(
                    context,
                    "Bienestar Emocional",
                    "Encuentra equilibrio emocional y reduce tus niveles de estrés.",
                    Icons.sentiment_satisfied,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmotionalForm(userId: userId)),
                    ),
                  ),
                  _buildTile(
                    context,
                    "Bienestar Intelectual",
                    "Potencia tu aprendizaje y habilidades tecnológicas.",
                    Icons.school,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IntellectualForm(userId: userId)),
                    ),
                  ),
                  _buildTile(
                    context,
                    "Bienestar Social",
                    "Mejora tus relaciones sociales y encuentra tiempo para ti mismo.",
                    Icons.people,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SocialForm(userId: userId)),
                    ),
                  ),
                  _buildTile(
                    context,
                    "Bienestar Financiero",
                    "Refuerza tu salud financiera y toma mejores decisiones económicas.",
                    Icons.account_balance_wallet,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FinancialForm(userId: userId)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const VastoriaMainLanding()),
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text("Ir a la página principal"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.1),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
