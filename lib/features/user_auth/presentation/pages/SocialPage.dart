import 'package:flutter/material.dart';

import 'interactive_map_page.dart'; // Página del mapa interactivo de Perú
import 'MapaPUCPPage.dart'; // Página del mapa PUCP
import 'ProponerProyectoPage.dart'; // Página para proponer proyectos sociales
import 'ColaborarComunidadPage.dart'; // Página para colaborar con la comunidad

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Impacto Social y Proyectos',
          style: TextStyle(
            fontFamily: 'Montserrat', // Fuente moderna y amigable
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple[700]!, Colors.purple[300]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _customButton(
                context,
                icon: Icons.map_outlined,
                label: 'Explorar Regiones del Perú',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InteractiveMapPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _customButton(
                context,
                icon: Icons.school_outlined,
                label: 'Mapa PUCP: Proyectos y Eventos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapaPUCPPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _customButton(
                context,
                icon: Icons.volunteer_activism,
                label: 'Proponer Proyecto Social',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProponerProyectoPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _customButton(
                context,
                icon: Icons.group_outlined,
                label: 'Colaborar con la Comunidad',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ColaborarComunidadPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Fondo blanco para contraste
        foregroundColor: Colors.deepPurple[700], // Color del texto e íconos
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      icon: Icon(
        icon,
        size: 24,
        color: Colors.deepPurple[700], // Color del ícono
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat', // Tipografía moderna y cálida
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onPressed: onPressed,
    );
  }
}
