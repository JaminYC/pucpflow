import 'package:flutter/material.dart';

class ColaborarComunidadPage extends StatelessWidget {
  const ColaborarComunidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> projects = [
      {
        'title': 'Reforestación en Lomas de Villa',
        'description':
            'Únete a nuestro equipo para plantar árboles y conservar las áreas verdes.',
        'date': '10 de Enero, 2025',
      },
      {
        'title': 'Campaña de Alfabetización',
        'description':
            'Colabora enseñando a leer y escribir en comunidades rurales.',
        'date': '15 de Enero, 2025',
      },
      {
        'title': 'Reciclaje Creativo en Escuelas',
        'description':
            'Participa en talleres para enseñar a los niños a reciclar y crear arte.',
        'date': '20 de Enero, 2025',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Colaborar con la Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projects[index]['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    projects[index]['description']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fecha: ${projects[index]['date']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showJoinDialog(context, projects[index]['title']!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[700],
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                    child: const Text(
                      'Unirse al Proyecto',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unirse a "$projectName"'),
        content: const Text(
            'Gracias por unirte a este proyecto. Nos pondremos en contacto contigo para más detalles.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
