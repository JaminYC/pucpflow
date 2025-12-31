import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/google_routes_service.dart';

/// BottomSheet avanzado con rutas y direcciones REAL
class DepartmentRouteSheet extends StatefulWidget {
  final String departmentId;
  final String departmentName;
  final LatLng? userLocation;
  final Function(RouteDirections route) onRouteGenerated;

  const DepartmentRouteSheet({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.userLocation,
    required this.onRouteGenerated,
  });

  @override
  State<DepartmentRouteSheet> createState() => _DepartmentRouteSheetState();
}

class _DepartmentRouteSheetState extends State<DepartmentRouteSheet> {
  final GoogleRoutesService _routesService = GoogleRoutesService();
  bool _isLoadingRoute = false;
  RouteDirections? _currentRoute;
  String? _error;

  // Coordenadas de capitales de departamentos
  static final Map<String, LatLng> _departmentCoordinates = {
    'lima': LatLng(-12.0464, -77.0428),
    'cusco': LatLng(-13.5319, -71.9675),
    'arequipa': LatLng(-16.4090, -71.5375),
    'loreto': LatLng(-3.7495, -73.2526), // Iquitos
    'puno': LatLng(-15.8402, -70.0219),
    'la_libertad': LatLng(-8.1116, -79.0288), // Trujillo
    'piura': LatLng(-5.1945, -80.6328),
    'ica': LatLng(-14.0678, -75.7286),
    'lambayeque': LatLng(-6.7011, -79.9061), // Chiclayo
    'ancash': LatLng(-9.5256, -77.5283), // Huaraz
    'junin': LatLng(-12.0689, -75.2043), // Huancayo
    'cajamarca': LatLng(-7.1614, -78.5128),
    'ucayali': LatLng(-8.3791, -74.5539), // Pucallpa
    'ayacucho': LatLng(-13.1587, -74.2235),
    'huanuco': LatLng(-9.9306, -76.2419),
  };

  LatLng get _destinationCoords {
    final normalizedId = widget.departmentId.toLowerCase().replaceAll(' ', '_');
    return _departmentCoordinates[normalizedId] ?? LatLng(-12.0464, -77.0428);
  }

  Map<String, dynamic> get _deptInfo {
    final normalizedId = widget.departmentId.toLowerCase().replaceAll(' ', '_');
    final data = {
      'lima': {
        'icon': '🏛️',
        'region': 'Costa',
        'distance': '0 km',
        'time': 'Estás aquí',
      },
      'cusco': {
        'icon': '🏔️',
        'region': 'Sierra',
        'distance': '~1,100 km',
        'time': '22 horas',
      },
      'arequipa': {
        'icon': '🌋',
        'region': 'Sierra',
        'distance': '~1,000 km',
        'time': '16 horas',
      },
      'loreto': {
        'icon': '🌳',
        'region': 'Selva',
        'distance': '~1,500 km',
        'time': '2 días',
      },
      'puno': {
        'icon': '🛶',
        'region': 'Sierra',
        'distance': '~1,300 km',
        'time': '20 horas',
      },
    };

    return data[normalizedId] ?? {
      'icon': '📍',
      'region': 'Perú',
      'distance': 'Calculando...',
      'time': 'Calculando...',
    };
  }

  Future<void> _calculateRoute() async {
    if (widget.userLocation == null) {
      setState(() {
        _error = 'Activa tu ubicación primero';
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _error = null;
    });

    try {
      final route = await _routesService.getDirections(
        origin: widget.userLocation!,
        destination: _destinationCoords,
        mode: 'driving',
      );

      setState(() {
        _currentRoute = route;
        _isLoadingRoute = false;
      });

      // Notificar al mapa para trazar la ruta
      widget.onRouteGenerated(route);
    } catch (e) {
      setState(() {
        _error = 'Error calculando ruta: ${e.toString()}';
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _deptInfo;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        info['icon'] as String,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.departmentName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRegionColor(info['region'] as String)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                info['region'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRegionColor(info['region'] as String),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Información de ruta calculada o estimada
                  if (_currentRoute != null) ...[
                    _buildRouteInfo(_currentRoute!),
                    const SizedBox(height: 16),
                    _buildRouteSteps(_currentRoute!),
                  ] else if (!_isLoadingRoute) ...[
                    _buildEstimatedInfo(info),
                  ],

                  const SizedBox(height: 24),

                  // Botones de acción
                  if (widget.userLocation != null)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingRoute ? null : _calculateRoute,
                            icon: _isLoadingRoute
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.directions),
                            label: Text(_currentRoute == null ? 'Cómo Llegar' : 'Recalcular'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.star_border),
                            label: const Text('Guardar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Activa tu ubicación para calcular la ruta',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(RouteDirections route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Color(0xFF10B981), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  '${route.durationHours.toStringAsFixed(1)} horas de viaje',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedInfo(Map<String, dynamic> info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF57C0FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF57C0FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distancia estimada: ${info['distance']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tiempo estimado: ${info['time']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSteps(RouteDirections route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Indicaciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: route.steps.length > 5 ? 5 : route.steps.length,
            itemBuilder: (context, index) {
              final step = route.steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF57C0FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.instructions,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${(step.distanceMeters / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (route.steps.length > 5)
          Text(
            '+ ${route.steps.length - 5} pasos más',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Color _getRegionColor(String region) {
    switch (region.toLowerCase()) {
      case 'costa':
        return const Color(0xFF3B82F6);
      case 'sierra':
        return const Color(0xFF10B981);
      case 'selva':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}
