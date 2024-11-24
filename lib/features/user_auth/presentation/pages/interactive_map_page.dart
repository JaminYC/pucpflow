import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'department_details_page.dart';

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({Key? key}) : super(key: key);

  @override
  _InteractiveMapPageState createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(-9.19, -75.015); // Centro aproximado de Perú

  // Lista de marcadores
  final Set<Marker> _markers = {};

  // Mapa de departamentos con latitud, longitud y sectores laborales
  final Map<String, Map<String, dynamic>> departments = {
    'Amazonas': {
      'sectors': 'Turismo, Agricultura',
      'location': LatLng(-6.229, -78.183),
    },
    'Áncash': {
      'sectors': 'Minería, Pesca',
      'location': LatLng(-9.528, -77.531),
    },
    'Apurímac': {
      'sectors': 'Minería, Agricultura',
      'location': LatLng(-13.635, -72.881),
    },
    'Arequipa': {
      'sectors': 'Industria, Turismo',
      'location': LatLng(-16.409, -71.537),
    },
    'Ayacucho': {
      'sectors': 'Agricultura, Textil',
      'location': LatLng(-13.158, -74.223),
    },
    'Cajamarca': {
      'sectors': 'Minería, Agricultura',
      'location': LatLng(-7.149, -78.522),
    },
    'Callao': {
      'sectors': 'Logística, Comercio Exterior',
      'location': LatLng(-12.056, -77.118),
    },
    'Cusco': {
      'sectors': 'Turismo, Artesanía',
      'location': LatLng(-13.531, -71.967),
    },
    'Huancavelica': {
      'sectors': 'Minería, Agricultura',
      'location': LatLng(-12.782, -74.976),
    },
    'Huánuco': {
      'sectors': 'Agricultura, Comercio',
      'location': LatLng(-9.93, -76.242),
    },
    'Ica': {
      'sectors': 'Agroindustria, Pesca',
      'location': LatLng(-14.067, -75.729),
    },
    'Junín': {
      'sectors': 'Agricultura, Industria',
      'location': LatLng(-11.158, -75.993),
    },
    'La Libertad': {
      'sectors': 'Agroindustria, Turismo',
      'location': LatLng(-8.115, -79.035),
    },
    'Lambayeque': {
      'sectors': 'Agricultura, Pesca',
      'location': LatLng(-6.771, -79.906),
    },
    'Lima': {
      'sectors': 'Servicios, Industria',
      'location': LatLng(-12.046, -77.042),
    },
    'Loreto': {
      'sectors': 'Petróleo, Turismo',
      'location': LatLng(-3.749, -73.253),
    },
    'Madre de Dios': {
      'sectors': 'Minería, Turismo',
      'location': LatLng(-12.593, -69.183),
    },
    'Moquegua': {
      'sectors': 'Minería, Pesca',
      'location': LatLng(-17.194, -70.936),
    },
    'Pasco': {
      'sectors': 'Minería, Agricultura',
      'location': LatLng(-10.68, -76.265),
    },
    'Piura': {
      'sectors': 'Pesca, Agricultura',
      'location': LatLng(-5.194, -80.632),
    },
    'Puno': {
      'sectors': 'Turismo, Agricultura',
      'location': LatLng(-15.84, -70.027),
    },
    'San Martín': {
      'sectors': 'Agricultura, Turismo',
      'location': LatLng(-6.485, -76.361),
    },
    'Tacna': {
      'sectors': 'Comercio, Minería',
      'location': LatLng(-18.013, -70.253),
    },
    'Tumbes': {
      'sectors': 'Turismo, Pesca',
      'location': LatLng(-3.57, -80.451),
    },
    'Ucayali': {
      'sectors': 'Madera, Agricultura',
      'location': LatLng(-8.379, -74.553),
    },
  };

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions(); // Solicita permisos al cargar la página
    _addDepartmentMarkers();
  }

  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addDepartmentMarkers() {
    departments.forEach((key, details) {
      _markers.add(
        Marker(
          markerId: MarkerId(key),
          position: details['location'],
          infoWindow: InfoWindow(
            title: key,
            snippet: "Sectores: ${details['sectors']}",
          ),
          onTap: () {
            // Aquí puedes añadir navegación o acciones adicionales
           // Navegar a la página de detalles del departamento
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DepartmentDetailsPage(
                    departmentName: key,
                    sectors: details['sectors'],
                    companies: details['companies'],
                    students: details['students'],
                  ),
                ),
              );
          },
        ),
      );
    });
    setState(() {}); // Actualiza la UI con los nuevos marcadores
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 5.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        markers: _markers,
      ),
    );
  }
}
