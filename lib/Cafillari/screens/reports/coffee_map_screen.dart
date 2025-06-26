import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardCafetalero extends StatefulWidget {
  const DashboardCafetalero({Key? key}) : super(key: key);

  @override
  State<DashboardCafetalero> createState() => _DashboardCafetaleroState();
}

class _DashboardCafetaleroState extends State<DashboardCafetalero> {
  Map<String, dynamic>? selectedZona;
  final List<Map<String, dynamic>> zonasData = [
    {
      'nombre': 'Cajamarca',
      'latLng': LatLng(-7.1569, -78.5155),
      'productoresActivos': 850,
      'lotesMonitoreados': 1200,
      'temperatura': 22.5,
      'humedad': 78.2,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Amazonas',
      'latLng': LatLng(-6.2306, -77.8736),
      'productoresActivos': 720,
      'lotesMonitoreados': 980,
      'temperatura': 24.1,
      'humedad': 82.4,
      'estado': 'Alerta',
      'imagen': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'San Martín',
      'latLng': LatLng(-6.4869, -76.3625),
      'productoresActivos': 680,
      'lotesMonitoreados': 920,
      'temperatura': 25.3,
      'humedad': 79.6,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Junín',
      'latLng': LatLng(-11.1581, -75.9914),
      'productoresActivos': 590,
      'lotesMonitoreados': 810,
      'temperatura': 21.8,
      'humedad': 76.1,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1497636577773-f1231844b336?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Cusco',
      'latLng': LatLng(-12.5943, -72.0814),
      'productoresActivos': 520,
      'lotesMonitoreados': 740,
      'temperatura': 20.9,
      'humedad': 75.8,
      'estado': 'Crítico',
      'imagen': 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Puno',
      'latLng': LatLng(-14.2414, -69.6118),
      'productoresActivos': 480,
      'lotesMonitoreados': 650,
      'temperatura': 19.5,
      'humedad': 74.2,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Pasco',
      'latLng': LatLng(-10.6728, -75.2521),
      'productoresActivos': 420,
      'lotesMonitoreados': 580,
      'temperatura': 18.7,
      'humedad': 81.3,
      'estado': 'Alerta',
      'imagen': 'https://images.unsplash.com/photo-1497436072909-f5e4be769312?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Ayacucho',
      'latLng': LatLng(-13.1631, -74.2236),
      'productoresActivos': 380,
      'lotesMonitoreados': 520,
      'temperatura': 20.2,
      'humedad': 73.9,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Huánuco',
      'latLng': LatLng(-9.9306, -76.2422),
      'productoresActivos': 350,
      'lotesMonitoreados': 480,
      'temperatura': 22.1,
      'humedad': 77.5,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1464207687429-7505649dae38?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Piura',
      'latLng': LatLng(-5.1945, -80.6328),
      'productoresActivos': 320,
      'lotesMonitoreados': 420,
      'temperatura': 26.8,
      'humedad': 68.4,
      'estado': 'Alerta',
      'imagen': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=300&h=200&fit=crop'
    },
    {
      'nombre': 'Huancavelica',
      'latLng': LatLng(-12.7863, -74.9772),
      'productoresActivos': 290,
      'lotesMonitoreados': 380,
      'temperatura': 17.9,
      'humedad': 79.8,
      'estado': 'Estable',
      'imagen': 'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=300&h=200&fit=crop'
    }
  ];

  List<Map<String, dynamic>> get topRegiones {
    var sorted = List<Map<String, dynamic>>.from(zonasData);
    sorted.sort((a, b) => b['productoresActivos'].compareTo(a['productoresActivos']));
    return sorted.take(5).toList();
  }

  int get totalLotes => zonasData.fold(0, (sum, zona) => sum + zona['lotesMonitoreados'] as int);
  
  double get temperaturaPromedio => zonasData.fold(0.0, (sum, zona) => sum + zona['temperatura']) / zonasData.length;
  
  double get humedadPromedio => zonasData.fold(0.0, (sum, zona) => sum + zona['humedad']) / zonasData.length;
  
  int get regionesEnAlerta => zonasData.where((zona) => zona['estado'] != 'Estable').length;

  Color getEstadoColor(String estado) {
    switch (estado) {
      case 'Estable':
        return Colors.green;
      case 'Alerta':
        return Colors.orange;
      case 'Crítico':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getEstadoIcon(String estado) {
    switch (estado) {
      case 'Estable':
        return '✅';
      case 'Alerta':
        return '⚠️';
      case 'Crítico':
        return '❌';
      default:
        return '❓';
    }
  }

  String getRankingEmoji(int index) {
    switch (index) {
      case 0:
        return '1️⃣';
      case 1:
        return '2️⃣';
      case 2:
        return '3️⃣';
      case 3:
        return '4️⃣';
      case 4:
        return '5️⃣';
      default:
        return '${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Dashboard Cafetalero - Perú',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6B4423),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(-9.19, -75.0152),
                      initialZoom: 5.8,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: zonasData
                            .map((zona) => Marker(
                                  point: zona['latLng'],
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedZona = zona;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selectedZona == zona 
                                            ? Colors.orange[700]
                                            : Colors.brown[600],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selectedZona == zona 
                                              ? Colors.orange[300]! 
                                              : Colors.white, 
                                          width: 2
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '☕',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indicadores KPI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4423),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Regiones',
                          '${zonasData.length}',
                          Icons.location_on,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          'Lotes',
                          '$totalLotes',
                          Icons.crop_landscape,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Temp. Prom.',
                          '${temperaturaPromedio.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          'Hum. Prom.',
                          '${humedadPromedio.toStringAsFixed(1)}%',
                          Icons.water_drop,
                          Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    'Regiones en Alerta',
                    '$regionesEnAlerta',
                    Icons.warning,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  if (selectedZona != null) ...[
                    const Text(
                      'Información de Región Seleccionada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4423),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    selectedZona!['imagen'],
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 80,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.landscape, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedZona!['nombre'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6B4423),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            getEstadoIcon(selectedZona!['estado']),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            selectedZona!['estado'],
                                            style: TextStyle(
                                              color: getEstadoColor(selectedZona!['estado']),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Productores',
                                    '${selectedZona!['productoresActivos']}',
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Lotes',
                                    '${selectedZona!['lotesMonitoreados']}',
                                    Icons.landscape,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Temp.',
                                    '${selectedZona!['temperatura']}°C',
                                    Icons.thermostat,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Hum.',
                                    '${selectedZona!['humedad']}%',
                                    Icons.water_drop,
                                    Colors.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Ranking Top 5 Regiones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4423),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowHeight: 50,
                            dataRowHeight: 90,
                            columnSpacing: 40,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4423),
                              fontSize: 13,
                            ),
                            columns: const [
                              DataColumn(label: Text('Pos.')),
                              DataColumn(label: Text('Región')),
                              DataColumn(label: Text('Prod.')),
                              DataColumn(label: Text('Lotes')),
                              DataColumn(label: Text('Temp.')),
                              DataColumn(label: Text('Hum.')),
                              DataColumn(label: Text('Estado')),
                            ],
                            rows: topRegiones.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> zona = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    getRankingEmoji(index),
                                    style: const TextStyle(fontSize: 16),
                                  )),
                                  DataCell(Text(
                                    zona['nombre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  )),
                                  DataCell(Text(
                                    '${zona['productoresActivos']}',
                                    style: const TextStyle(fontSize: 13),
                                  )),
                                  DataCell(Text(
                                    '${zona['lotesMonitoreados']}',
                                    style: const TextStyle(fontSize: 13),
                                  )),
                                  DataCell(Text(
                                    '${zona['temperatura']}°',
                                    style: const TextStyle(fontSize: 13),
                                  )),
                                  DataCell(Text(
                                    '${zona['humedad']}%',
                                    style: const TextStyle(fontSize: 13),
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        getEstadoIcon(zona['estado']),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const SizedBox(width: 4),
                                                                              Text(
                                        zona['estado'],
                                        style: TextStyle(
                                          color: getEstadoColor(zona['estado']),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}