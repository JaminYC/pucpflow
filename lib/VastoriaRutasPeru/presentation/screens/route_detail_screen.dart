import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:intl/intl.dart';

import '../../data/firestore_repository.dart';
import '../../data/models/route_model_extended.dart';
import '../../data/models/waypoint_model.dart';
import '../../data/models/day_itinerary_model.dart';
import 'route_navigation_screen.dart';

/// Pantalla de detalle completo de una ruta turística
class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  final String deptId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
    required this.deptId,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final FirestoreRepository _repository = FirestoreRepository();

  DateTime? _selectedStartDate;
  int _numberOfPeople = 1;
  bool _showDatePicker = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: StreamBuilder<RouteModelExtended>(
        stream: _repository.watchRouteExtended(widget.deptId, widget.routeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF57C0FF)),
            );
          }

          final route = snapshot.data!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(route),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteMap(route),
                    _buildQuickStats(route),
                    _buildDateSelector(route),
                    if (_selectedStartDate != null)
                      _buildDemandIndicator(route, _selectedStartDate!),
                    _buildDailyItinerary(route),
                    _buildWaypointsList(route),
                    _buildCostEstimate(route),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedStartDate != null
          ? FloatingActionButton.extended(
              onPressed: () => _startNavigation(context),
              backgroundColor: const Color(0xFF57C0FF),
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text(
                'Iniciar Viaje',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(RouteModelExtended route) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E27),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          route.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.3),
                    const Color(0xFF3B82F6).withOpacity(0.3),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0E27).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMap(RouteModelExtended route) {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(
            route.startPoint.latitude,
            route.startPoint.longitude,
          ),
          zoom: 10,
        ),
        markers: _buildMapMarkers(route),
        polylines: _buildPolylines(route),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  Set<gmaps.Marker> _buildMapMarkers(RouteModelExtended route) {
    final markers = <gmaps.Marker>{};

    // Marcador de inicio
    markers.add(gmaps.Marker(
      markerId: const gmaps.MarkerId('start'),
      position: gmaps.LatLng(
        route.startPoint.latitude,
        route.startPoint.longitude,
      ),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueGreen,
      ),
      infoWindow: const gmaps.InfoWindow(title: 'Inicio'),
    ));

    // Marcador de fin
    markers.add(gmaps.Marker(
      markerId: const gmaps.MarkerId('end'),
      position: gmaps.LatLng(
        route.endPoint.latitude,
        route.endPoint.longitude,
      ),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueRed,
      ),
      infoWindow: const gmaps.InfoWindow(title: 'Fin'),
    ));

    // Marcadores de waypoints
    for (var waypoint in route.waypoints) {
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId(waypoint.id),
        position: gmaps.LatLng(
          waypoint.location.latitude,
          waypoint.location.longitude,
        ),
        infoWindow: gmaps.InfoWindow(title: waypoint.name),
      ));
    }

    return markers;
  }

  Set<gmaps.Polyline> _buildPolylines(RouteModelExtended route) {
    // TODO: Usar Google Directions API para obtener la ruta real
    // Por ahora, línea recta entre inicio y fin
    return {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route'),
        points: [
          gmaps.LatLng(route.startPoint.latitude, route.startPoint.longitude),
          gmaps.LatLng(route.endPoint.latitude, route.endPoint.longitude),
        ],
        color: const Color(0xFF57C0FF),
        width: 4,
      ),
    };
  }

  Widget _buildQuickStats(RouteModelExtended route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statChip(
            icon: Icons.calendar_today,
            label: '${route.durationDays} días',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _statChip(
            icon: Icons.straighten,
            label: '${route.estimatedDistanceKm.toStringAsFixed(0)} km',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          _statChip(
            icon: Icons.trending_up,
            label: route.difficulty,
            color: _getDifficultyColor(route.difficulty),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'baja':
        return const Color(0xFF10B981);
      case 'media':
        return const Color(0xFFF59E0B);
      case 'alta':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildDateSelector(RouteModelExtended route) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: Color(0xFF57C0FF)),
              const SizedBox(width: 8),
              const Text(
                '¿Cuándo quieres viajar?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(context, route),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF57C0FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF57C0FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedStartDate == null
                        ? 'Seleccionar fecha de inicio'
                        : DateFormat('dd MMM yyyy', 'es').format(_selectedStartDate!),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.calendar_month, color: Color(0xFF57C0FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Número de personas:',
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_numberOfPeople > 1) {
                    setState(() => _numberOfPeople--);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              ),
              Text(
                '$_numberOfPeople',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _numberOfPeople++),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, RouteModelExtended route) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF57C0FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  Widget _buildDemandIndicator(RouteModelExtended route, DateTime date) {
    final demand = route.getDemandForMonth(date.month);
    final message = route.getDemandMessage(date);
    final isRecommended = route.isRecommendedDate(date);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isRecommended
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (route.recommendedSeason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Temporada recomendada: ${route.recommendedSeason}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyItinerary(RouteModelExtended route) {
    if (route.dailyPlan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Itinerario por día',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...route.dailyPlan.entries.map((entry) {
          return _buildDayCard(entry.key, entry.value, route);
        }),
      ],
    );
  }

  Widget _buildDayCard(int dayNumber, DayItineraryModel day, RouteModelExtended route) {
    // Obtener waypoints de este día
    final dayWaypoints = route.waypoints
        .where((w) => w.dayNumber == dayNumber)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Theme(
        data: ThemeData.dark(),
        child: ExpansionTile(
          title: Text(
            day.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${dayWaypoints.length} paradas • ${day.estimatedDurationHours.toStringAsFixed(1)}h',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...dayWaypoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final waypoint = entry.value;
                    return _buildWaypointItem(waypoint, index + 1);
                  }),
                  if (day.accommodationName != null) ...[
                    const Divider(color: Colors.white12, height: 24),
                    Row(
                      children: [
                        const Icon(Icons.hotel, color: Color(0xFF8B5CF6), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alojamiento: ${day.accommodationName}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (day.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      day.notes,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
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

  Widget _buildWaypointItem(WaypointModel waypoint, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF57C0FF).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF57C0FF), width: 2),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF57C0FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                  '${waypoint.getTypeIcon()} ${waypoint.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  waypoint.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '⏱️ ${waypoint.estimatedTimeHours.toStringAsFixed(1)}h',
                  style: const TextStyle(color: Color(0xFF57C0FF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointsList(RouteModelExtended route) {
    // Esta sección ya está cubierta en el itinerario por día
    return const SizedBox.shrink();
  }

  Widget _buildCostEstimate(RouteModelExtended route) {
    if (route.averageCostPerPerson == null) return const SizedBox.shrink();

    final totalCost = route.averageCostPerPerson! * _numberOfPeople;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Costo estimado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Por persona:',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '\$${route.averageCostPerPerson!.toStringAsFixed(0)} USD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($_numberOfPeople ${_numberOfPeople > 1 ? 'personas' : 'persona'}):',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${totalCost.toStringAsFixed(0)} USD',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '* Incluye alojamiento, comidas y entradas. No incluye transporte hasta el punto de inicio.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _startNavigation(BuildContext context) {
    // TODO: Navegar a RouteNavigationScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegación en desarrollo...'),
        backgroundColor: Color(0xFF57C0FF),
      ),
    );
  }
}
