import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart'; // Importa para abrir enlaces en el navegador

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({super.key});

  @override
  _InteractiveMapPageState createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  final LatLng _initialPosition = const LatLng(-9.19, -75.015); // Centro aproximado de Perú

  // Lista de marcadores
  final Set<Marker> _markers = {};

  // Mapa de departamentos con latitud, longitud y sectores laborales
    final Map<String, Map<String, dynamic>> departments = {
    'Amazonas': {
      'sectors': 'Turismo, Agricultura',
      'location': const LatLng(-6.229, -78.183),
      'links': ['https://www.empleosperu.gob.pe/portal-mtpe/#/', 'https://agricultura.amazonas.gob.pe'],
    },
    'Áncash': {
      'sectors': 'Minería, Pesca',
      'location': const LatLng(-9.528, -77.531),
      'links': ['https://mineria.ancash.gob.pe', 'https://pesca.ancash.gob.pe'],
    },
    'Apurímac': {
      'sectors': 'Minería, Agricultura',
      'location': const LatLng(-13.635, -72.881),
      'links': ['https://mineria.apurimac.gob.pe', 'https://agricultura.apurimac.gob.pe'],
    },
    'Arequipa': {
      'sectors': 'Industria, Turismo',
      'location': const LatLng(-16.409, -71.537),
      'links': ['https://industria.arequipa.gob.pe', 'https://turismo.arequipa.gob.pe'],
    },
    'Ayacucho': {
      'sectors': 'Agricultura, Textil',
      'location': const LatLng(-13.158, -74.223),
      'links': ['https://agricultura.ayacucho.gob.pe', 'https://textiles.ayacucho.gob.pe'],
    },
    'Cajamarca': {
      'sectors': 'Minería, Agricultura',
      'location': const LatLng(-7.149, -78.522),
      'links': ['https://mineria.cajamarca.gob.pe', 'https://agricultura.cajamarca.gob.pe'],
    },
    'Callao': {
      'sectors': 'Logística, Comercio Exterior',
      'location': const LatLng(-12.056, -77.118),
      'links': ['https://logistica.callao.gob.pe', 'https://comercio.callao.gob.pe'],
    },
    'Cusco': {
      'sectors': 'Turismo, Artesanía',
      'location': const LatLng(-13.531, -71.967),
      'links': ['https://turismo.cusco.gob.pe', 'https://artesania.cusco.gob.pe'],
    },
    'Huancavelica': {
      'sectors': 'Minería, Agricultura',
      'location': const LatLng(-12.782, -74.976),
      'links': ['https://mineria.huancavelica.gob.pe', 'https://agricultura.huancavelica.gob.pe'],
    },
    'Huánuco': {
      'sectors': 'Agricultura, Comercio',
      'location': const LatLng(-9.93, -76.242),
      'links': ['https://agricultura.huanuco.gob.pe', 'https://comercio.huanuco.gob.pe'],
    },
    'Ica': {
      'sectors': 'Agroindustria, Pesca',
      'location': const LatLng(-14.067, -75.729),
      'links': ['https://agroindustria.ica.gob.pe', 'https://pesca.ica.gob.pe'],
    },
    'Junín': {
      'sectors': 'Agricultura, Industria',
      'location': const LatLng(-11.158, -75.993),
      'links': ['https://agricultura.junin.gob.pe', 'https://industria.junin.gob.pe'],
    },
    'La Libertad': {
      'sectors': 'Agroindustria, Turismo',
      'location': const LatLng(-8.115, -79.035),
      'links': ['https://agroindustria.lalibertad.gob.pe', 'https://turismo.lalibertad.gob.pe'],
    },
    'Lambayeque': {
      'sectors': 'Agricultura, Pesca',
      'location': const LatLng(-6.771, -79.906),
      'links': ['https://agricultura.lambayeque.gob.pe', 'https://pesca.lambayeque.gob.pe'],
    },
    'Lima': {
      'sectors': 'Servicios, Industria',
      'location': const LatLng(-12.046, -77.042),
      'links': ['https://servicios.lima.gob.pe', 'https://industria.lima.gob.pe'],
    },
    'Loreto': {
      'sectors': 'Petróleo, Turismo',
      'location': const LatLng(-3.749, -73.253),
      'links': ['https://petroleo.loreto.gob.pe', 'https://turismo.loreto.gob.pe'],
    },
    'Madre de Dios': {
      'sectors': 'Minería, Turismo',
      'location': const LatLng(-12.593, -69.183),
      'links': ['https://mineria.madrededios.gob.pe', 'https://turismo.madrededios.gob.pe'],
    },
    'Moquegua': {
      'sectors': 'Minería, Pesca',
      'location': const LatLng(-17.194, -70.936),
      'links': ['https://mineria.moquegua.gob.pe', 'https://pesca.moquegua.gob.pe'],
    },
    'Pasco': {
      'sectors': 'Minería, Agricultura',
      'location': const LatLng(-10.68, -76.265),
      'links': ['https://mineria.pasco.gob.pe', 'https://agricultura.pasco.gob.pe'],
    },
    'Piura': {
      'sectors': 'Pesca, Agricultura',
      'location': const LatLng(-5.194, -80.632),
      'links': ['https://pesca.piura.gob.pe', 'https://agricultura.piura.gob.pe'],
    },
    'Puno': {
      'sectors': 'Turismo, Agricultura',
      'location': const LatLng(-15.84, -70.027),
      'links': ['https://turismo.puno.gob.pe', 'https://agricultura.puno.gob.pe'],
    },
    'San Martín': {
      'sectors': 'Agricultura, Turismo',
      'location': const LatLng(-6.485, -76.361),
      'links': ['https://agricultura.sanmartin.gob.pe', 'https://turismo.sanmartin.gob.pe'],
    },
    'Tacna': {
      'sectors': 'Comercio, Minería',
      'location': const LatLng(-18.013, -70.253),
      'links': ['https://comercio.tacna.gob.pe', 'https://mineria.tacna.gob.pe'],
    },
    'Tumbes': {
      'sectors': 'Turismo, Pesca',
      'location': const LatLng(-3.57, -80.451),
      'links': ['https://turismo.tumbes.gob.pe', 'https://pesca.tumbes.gob.pe'],
    },
    'Ucayali': {
      'sectors': 'Madera, Agricultura',
      'location': const LatLng(-8.379, -74.553),
      'links': ['https://madera.ucayali.gob.pe', 'https://agricultura.ucayali.gob.pe'],
    },
  };


  String _searchQuery = ''; // Para el filtro de departamentos y sectores

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
  }

  void _addDepartmentMarkers() {
    _markers.clear();
    departments.forEach((key, details) {
      // Si hay un filtro de búsqueda, solo mostrar departamentos o sectores que coincidan
      if (_searchQuery.isEmpty ||
          key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (details['sectors'] as String).toLowerCase().contains(_searchQuery.toLowerCase())) {
        _markers.add(
          Marker(
            markerId: MarkerId(key),
            position: details['location'],
            infoWindow: InfoWindow(
              title: key,
              snippet: "Sectores: ${details['sectors']}",
            ),
            onTap: () {
              // Acción al tocar el marcador
              _showSectorDetails(key, details['sectors'], details['links']);
            },
          ),
        );
      }
    });
    setState(() {}); // Actualiza la UI con los nuevos marcadores
  }

  void _showSectorDetails(String department, String sectors, List<String> links) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de $department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sectores: $sectors"),
            const SizedBox(height: 10),
            const Text(
              'Enlaces relacionados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (var link in links)
              GestureDetector(
                onTap: () async {
                  if (await canLaunch(link)) {
                    await launch(link);
                  } else {
                    throw 'No se pudo abrir $link';
                  }
                },
                child: Text(
                  link,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar departamento o sector',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _addDepartmentMarkers(); // Actualiza los marcadores según la búsqueda
                });
              },
            ),
          ),
          // Mapa
          Expanded(
            child: GoogleMap(
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
          ),
        ],
      ),
    );
  }
}
