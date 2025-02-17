import 'package:flutter/material.dart';
import 'cursos_page.dart';
import 'Proyectos/ProyectosPage.dart';

class DesarrolloInicio extends StatelessWidget {
  const DesarrolloInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: "heroDesarrollo",
          child: const Text(
            "Desarrollo Académico",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.white,
              shadows: [
                Shadow(offset: Offset(2.0, 2.0), blurRadius: 3.0, color: Colors.black),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blue[900]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  context,
                  title: "Cursos",
                  icon: Icons.school,
                  color: Colors.blue[700]!,
                  destination: CursosPage(),
                ),
                const SizedBox(height: 80), // 🔹 Espaciado entre los botones
                _buildButton(
                  context,
                  title: "Proyectos",
                  icon: Icons.folder,
                  color: Colors.black,
                  destination: ProyectosPage(),
                ),
              ],
            ),

        ],
      ),
    );
  }

  /// 🔹 **Método para construir botones personalizados**
  Widget _buildButton(BuildContext context, {required String title, required IconData icon, required Color color, required Widget destination}) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shadowColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(offset: Offset(1.0, 1.0), blurRadius: 2.0, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
