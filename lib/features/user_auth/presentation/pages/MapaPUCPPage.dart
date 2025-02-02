import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaPUCPPage extends StatefulWidget {
  const MapaPUCPPage({super.key});

  @override
  _MapaPUCPPageState createState() => _MapaPUCPPageState();
}

class _MapaPUCPPageState extends State<MapaPUCPPage> {
  late GoogleMapController _mapController;

  // Coordenadas centrales de la PUCP
  final LatLng _pucpLocation = const LatLng(-12.069622, -77.080185);

  // Marcadores de ejemplo (ubicaciones dentro del campus)
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('library'),
      position: LatLng(-12.069, -77.081), // Ubicación de la Biblioteca
      infoWindow: const InfoWindow(
        title: 'Biblioteca Central',
        snippet: 'Eventos y Proyectos Estudiantiles',
      ),
    ),
    Marker(
      markerId: const MarkerId('cafeteria'),
      position: LatLng(-12.070, -77.079), // Ubicación de la Cafetería
      infoWindow: const InfoWindow(
        title: 'Cafetería Central',
        snippet: 'Punto de Encuentro',
      ),
    ),
    Marker(
      markerId: const MarkerId('lab'),
      position: LatLng(-12.0685, -77.0815), // Ubicación de un laboratorio
      infoWindow: const InfoWindow(
        title: 'Laboratorio de Innovación',
        snippet: 'Proyectos Tecnológicos',
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa PUCP: Proyectos y Eventos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pucpLocation,
          zoom: 17.0,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetMapView,
        backgroundColor: Colors.deepPurple[700],
        child: const Icon(Icons.location_searching),
      ),
    );
  }

  void _resetMapView() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _pucpLocation,
          zoom: 17.0,
        ),
      ),
    );
  }
}
