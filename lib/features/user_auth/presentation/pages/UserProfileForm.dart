import 'package:flutter/material.dart';
import 'Formularios/EmotionalForm.dart';
import 'Formularios/IntellectualForm.dart';
import 'Formularios/PhysicalForm.dart';
import 'Formularios/SocialForm.dart';
import 'home_page.dart'; // Asegúrate de importar la página HomePage

class UserProfileForm extends StatelessWidget {
  final String userId;

  const UserProfileForm({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completa tu perfil"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.purple.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  "Que cada uno brille con su propia luz",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                Text(
                  "Completa tu perfil y desbloquea tu máximo potencial en cada aspecto de tu vida.",
                  style: TextStyle(color: Colors.purple, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTile(
                  context,
                  "Bienestar Físico",
                  "Descubre cómo mejorar tu energía diaria y cuidar tu salud física.",
                  Icons.fitness_center,
                  Colors.blue,
                  () {
                    // Navega al formulario de bienestar físico
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PhysicalForm(userId: userId)),
                    );
                  },
                ),
                _buildTile(
                  context,
                  "Bienestar Emocional",
                  "Encuentra equilibrio emocional y reduce tus niveles de estrés.",
                  Icons.sentiment_satisfied,
                  Colors.pink,
                  () {
                    // Navega al formulario de bienestar emocional
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmotionalForm(userId: userId)),
                    );
                  },
                ),
                _buildTile(
                  context,
                  "Bienestar Intelectual",
                  "Potencia tu aprendizaje y habilidades tecnológicas.",
                  Icons.school,
                  Colors.green,
                  () {
                    // Navega al formulario de bienestar intelectual
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IntellectualForm(userId: userId)),
                    );
                  },
                ),
                _buildTile(
                  context,
                  "Bienestar Social",
                  "Mejora tus relaciones sociales y encuentra tiempo para ti mismo.",
                  Icons.people,
                  Colors.orange,
                  () {
                    // Navega al formulario de bienestar social
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SocialForm(userId: userId)),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navega a la página principal
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text("Ir a la página principal"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
