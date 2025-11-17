import 'package:flutter/material.dart';
import 'crear_proyecto_contextual_page.dart';
import 'crear_proyecto_pmi_page.dart';

class ProyectoIAGatewayPage extends StatelessWidget {
  const ProyectoIAGatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Proyectos con IA',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildOptionCard(
            context,
            title: 'Blueprint Contextual',
            description:
                'Genera un plan flexible basado en objetivos, habilidades blandas y foco de negocio. Ideal para proyectos ágiles o discovery.',
            gradient: [Colors.deepPurple.shade800, Colors.blue.shade600],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrearProyectoContextualPage(),
                ),
              );
            },
            tag: 'Beta',
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'Blueprint PMI (PMBOK)',
            description:
                'Crea automáticamente las 5 fases PMI con entregables, paquetes de trabajo y tareas jerarquizadas.',
            gradient: [Colors.blueGrey.shade800, Colors.lightBlue.shade700],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrearProyectoPMIPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
    String? tag,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Configurar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
