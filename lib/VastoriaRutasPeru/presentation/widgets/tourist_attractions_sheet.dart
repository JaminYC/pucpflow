import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/google_routes_service.dart';
import '../../services/vastoria_ai_service.dart';

/// Modelo de atracción turística
class TouristAttraction {
  final String name;
  final String description;
  final LatLng location;
  final String type; // histórico, natural, cultural, aventura
  final double estimatedTimeHours;

  const TouristAttraction({
    required this.name,
    required this.description,
    required this.location,
    required this.type,
    required this.estimatedTimeHours,
  });
}

/// BottomSheet con checklist de atracciones turísticas
class TouristAttractionsSheet extends StatefulWidget {
  final String departmentId;
  final String departmentName;
  final LatLng? userLocation;
  final Function(LatLng destination, String placeName) onNavigateTo;

  const TouristAttractionsSheet({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.userLocation,
    required this.onNavigateTo,
  });

  @override
  State<TouristAttractionsSheet> createState() => _TouristAttractionsSheetState();
}

class _TouristAttractionsSheetState extends State<TouristAttractionsSheet> {
  final Set<String> _selectedPlaces = {};
  final VastoriaAIService _aiService = VastoriaAIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _normalizedDeptId =>
      widget.departmentId.toLowerCase().replaceAll(' ', '_');

  CollectionReference<Map<String, dynamic>> _savedPlacesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('saved_places');
  }

  // Base de datos de atracciones turísticas por departamento
  static final Map<String, List<TouristAttraction>> _attractions = {
    'cusco': [
      TouristAttraction(
        name: 'Machu Picchu',
        description: 'Ciudadela inca del siglo XV, una de las 7 maravillas del mundo',
        location: LatLng(-13.1631, -72.5450),
        type: 'histórico',
        estimatedTimeHours: 6,
      ),
      TouristAttraction(
        name: 'Valle Sagrado',
        description: 'Valle con sitios arqueológicos incas y pueblos coloniales',
        location: LatLng(-13.3197, -72.0869),
        type: 'histórico',
        estimatedTimeHours: 4,
      ),
      TouristAttraction(
        name: 'Sacsayhuamán',
        description: 'Fortaleza inca con muros de piedras gigantescas',
        location: LatLng(-13.5088, -71.9817),
        type: 'histórico',
        estimatedTimeHours: 2,
      ),
      TouristAttraction(
        name: 'Laguna Humantay',
        description: 'Laguna turquesa en los Andes a 4,200 msnm',
        location: LatLng(-13.7646, -72.7256),
        type: 'natural',
        estimatedTimeHours: 5,
      ),
    ],
    'lima': [
      TouristAttraction(
        name: 'Plaza de Armas',
        description: 'Centro histórico de Lima, patrimonio de la humanidad',
        location: LatLng(-12.0464, -77.0303),
        type: 'histórico',
        estimatedTimeHours: 2,
      ),
      TouristAttraction(
        name: 'Miraflores',
        description: 'Distrito moderno con malecón y vista al Pacífico',
        location: LatLng(-12.1198, -77.0287),
        type: 'cultural',
        estimatedTimeHours: 3,
      ),
      TouristAttraction(
        name: 'Barranco',
        description: 'Barrio bohemio con arte callejero y vida nocturna',
        location: LatLng(-12.1495, -77.0206),
        type: 'cultural',
        estimatedTimeHours: 2,
      ),
    ],
    'arequipa': [
      TouristAttraction(
        name: 'Cañón del Colca',
        description: 'Uno de los cañones más profundos del mundo, hogar de cóndores',
        location: LatLng(-15.6020, -71.8892),
        type: 'natural',
        estimatedTimeHours: 8,
      ),
      TouristAttraction(
        name: 'Monasterio de Santa Catalina',
        description: 'Ciudad dentro de la ciudad, arquitectura colonial del siglo XVI',
        location: LatLng(-16.3962, -71.5368),
        type: 'histórico',
        estimatedTimeHours: 2,
      ),
      TouristAttraction(
        name: 'Volcán Misti',
        description: 'Volcán activo a 5,822 msnm con vista panorámica',
        location: LatLng(-16.2940, -71.4093),
        type: 'aventura',
        estimatedTimeHours: 12,
      ),
    ],
    'puno': [
      TouristAttraction(
        name: 'Lago Titicaca',
        description: 'Lago navegable más alto del mundo',
        location: LatLng(-15.8402, -70.0219),
        type: 'natural',
        estimatedTimeHours: 6,
      ),
      TouristAttraction(
        name: 'Islas Uros',
        description: 'Islas flotantes hechas de totora',
        location: LatLng(-15.8205, -69.9595),
        type: 'cultural',
        estimatedTimeHours: 4,
      ),
    ],
    'ica': [
      TouristAttraction(
        name: 'Líneas de Nazca',
        description: 'Geoglifos misteriosos del desierto',
        location: LatLng(-14.7390, -75.1300),
        type: 'histórico',
        estimatedTimeHours: 5,
      ),
      TouristAttraction(
        name: 'Oasis de Huacachina',
        description: 'Oasis natural rodeado de dunas gigantes',
        location: LatLng(-14.0874, -75.7632),
        type: 'natural',
        estimatedTimeHours: 3,
      ),
    ],
  };

  List<TouristAttraction> get _departmentAttractions {
    return _attractions[_normalizedDeptId] ?? [];
  }

  String _placeDocId(TouristAttraction attraction) {
    final slug = _slugify(attraction.name);
    return '${_normalizedDeptId}__$slug';
  }

  String _slugify(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.toLowerCase().codeUnits) {
      final isAlphaNum = (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNum) {
        buffer.write(String.fromCharCode(codeUnit));
      } else if (codeUnit == 32 || codeUnit == 45 || codeUnit == 95) {
        if (buffer.isNotEmpty && !buffer.toString().endsWith('_')) {
          buffer.write('_');
        }
      }
    }
    final slug = buffer.toString();
    return slug.isEmpty ? 'place' : slug;
  }

  Stream<List<_SavedPlace>> _watchSavedPlaces(User user) {
    return _savedPlacesRef(user.uid)
        .where('departmentId', isEqualTo: _normalizedDeptId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] as String?) ?? '';
            final description = (data['description'] as String?) ?? '';
            final type = (data['type'] as String?) ?? 'lugar';
            final estimatedHours = (data['estimatedTimeHours'] as num?)
                    ?.toDouble() ??
                0;
            final lat = (data['lat'] as num?)?.toDouble() ?? 0;
            final lng = (data['lng'] as num?)?.toDouble() ?? 0;

            return _SavedPlace(
              id: doc.id,
              name: name,
              description: description,
              type: type,
              estimatedTimeHours: estimatedHours,
              location: LatLng(lat, lng),
            );
          }).toList();
        });
  }

  Future<void> _toggleSavedPlace(
    User? user,
    TouristAttraction attraction,
    bool isSaved,
  ) async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesion para guardar lugares.'),
          ),
        );
      }
      return;
    }

    final docId = _placeDocId(attraction);
    final ref = _savedPlacesRef(user.uid).doc(docId);

    if (isSaved) {
      await ref.delete();
      return;
    }

    await ref.set({
      'departmentId': _normalizedDeptId,
      'name': attraction.name,
      'type': attraction.type,
      'description': attraction.description,
      'estimatedTimeHours': attraction.estimatedTimeHours,
      'lat': attraction.location.latitude,
      'lng': attraction.location.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final attractions = _departmentAttractions;

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final savedStream = user == null
            ? Stream<List<_SavedPlace>>.value(<_SavedPlace>[])
            : _watchSavedPlaces(user);

        return StreamBuilder<List<_SavedPlace>>(
          stream: savedStream,
          builder: (context, savedSnapshot) {
            final savedPlaces = savedSnapshot.data ?? <_SavedPlace>[];
            final savedPlaceIds = savedPlaces.map((place) => place.id).toSet();
            final remainingAttractions = attractions
                .where((attraction) =>
                    !savedPlaceIds.contains(_placeDocId(attraction)))
                .toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF57C0FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Color(0xFF57C0FF),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.departmentName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${attractions.length} lugares para visitar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCountBadge(
                            label: 'Guardados',
                            count: savedPlaces.length,
                            color: const Color(0xFF3B82F6),
                          ),
                          _buildCountBadge(
                            label: 'Seleccionados',
                            count: _selectedPlaces.length,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de atracciones con checkbox
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (savedPlaces.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bookmark,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Guardados',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...savedPlaces.map((place) {
                    final attraction = TouristAttraction(
                      name: place.name,
                      description: place.description,
                      location: place.location,
                      type: place.type,
                      estimatedTimeHours: place.estimatedTimeHours,
                    );
                    return _buildAttractionTile(
                      attraction: attraction,
                      isSaved: true,
                      user: user,
                    );
                  }).toList(),
                  const SizedBox(height: 6),
                  const Divider(height: 24),
                ],
                ...remainingAttractions.map((attraction) {
                  return _buildAttractionTile(
                    attraction: attraction,
                    isSaved: false,
                    user: user,
                  );
                }).toList(),
              ],
            ),
          ),

          // Botón de crear itinerario con seleccionados
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Botón "Pregunta a ADAN sobre este departamento"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _askADANAboutDepartment(),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Pregunta a ADAN sobre este lugar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_selectedPlaces.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Botón "Crear itinerario inteligente"
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateSmartItinerary(),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text('Generar itinerario con ${_selectedPlaces.length} lugares'),
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
                      _buildAiBadge(),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
          },
        );
      },
    );
  }

  Widget _buildAttractionTile({
    required TouristAttraction attraction,
    required bool isSaved,
    required User? user,
  }) {
    final isSelected = _selectedPlaces.contains(attraction.name);
    final borderColor = isSelected
        ? const Color(0xFF10B981)
        : isSaved
            ? const Color(0xFF3B82F6)
            : Colors.grey.shade300;
    final borderWidth = (isSelected || isSaved) ? 2.0 : 1.0;
    final tileColor = isSelected
        ? const Color(0xFF10B981).withValues(alpha: 0.05)
        : isSaved
            ? const Color(0xFF3B82F6).withValues(alpha: 0.05)
            : Colors.white;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPlaces.remove(attraction.name);
          } else {
            _selectedPlaces.add(attraction.name);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(12),
          color: tileColor,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attraction.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildTypeChip(attraction.type),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attraction.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${attraction.estimatedTimeHours.toStringAsFixed(0)}h visita',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _toggleSavedPlace(
                    user,
                    attraction,
                    isSaved,
                  ),
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isSaved ? const Color(0xFF3B82F6) : Colors.grey.shade500,
                  ),
                  tooltip: isSaved ? 'Quitar guardado' : 'Guardar',
                ),
                IconButton(
                  onPressed: () {
                    widget.onNavigateTo(
                      attraction.location,
                      attraction.name,
                    );
                  },
                  icon: const Icon(
                    Icons.navigation,
                    color: Color(0xFF3B82F6),
                  ),
                  tooltip: 'Ir aqui',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene las atracciones del departamento actual
  List<TouristAttraction> _getAttractions() {
    return _attractions[_normalizedDeptId] ?? [];
  }

  /// Pregunta a ADAN sobre el departamento actual
  void _askADANAboutDepartment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            Text('ADAN - ${widget.departmentName}'),
          ],
        ),
        content: Text(
          'El chat de ADAN está disponible en el botón flotante del mapa.\n\n'
          'Toca el ícono de chat 💬 en la esquina inferior derecha para hablar con ADAN sobre '
          '${widget.departmentName} y obtener recomendaciones personalizadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Cerrar BottomSheet
            },
            icon: const Icon(Icons.chat),
            label: const Text('Ir al chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  /// Genera un itinerario inteligente con los lugares seleccionados
  Future<void> _generateSmartItinerary() async {
    // Obtener atracciones seleccionadas
    final attractions = _getAttractions();
    final selectedAttractions = attractions
        .where((a) => _selectedPlaces.contains(a.name))
        .toList();

    if (selectedAttractions.isEmpty) {
      return;
    }

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('ADAN está creando tu itinerario personalizado...'),
          ],
        ),
      ),
    );

    try {
      // Preparar datos para la IA
      final places = selectedAttractions.map((a) => {
        'name': a.name,
        'type': a.type,
        'description': a.description,
        'estimatedHours': a.estimatedTimeHours,
      }).toList();

      // Generar itinerario con IA
      final itinerary = await _aiService.generateItinerary(
        places: places,
        days: (selectedAttractions.length / 2).ceil(), // 2 lugares por día aprox
        preferences: ['turismo', 'cultura'],
      );

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // Mostrar itinerario generado
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildItinerarySheet(itinerary),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando itinerario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construye el BottomSheet con el itinerario generado
  Widget _buildItinerarySheet(Map<String, dynamic> itinerary) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Itinerario Inteligente',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Generado por ADAN',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Contenido del itinerario
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                itinerary['itinerary']?.toString() ??
                'No se pudo generar el itinerario',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón de cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    IconData icon;

    switch (type) {
      case 'histórico':
        color = const Color(0xFF8B5CF6);
        icon = Icons.castle;
        break;
      case 'natural':
        color = const Color(0xFF10B981);
        icon = Icons.landscape;
        break;
      case 'cultural':
        color = const Color(0xFFF59E0B);
        icon = Icons.palette;
        break;
      case 'aventura':
        color = const Color(0xFFEF4444);
        icon = Icons.hiking;
        break;
      default:
        color = Colors.grey;
        icon = Icons.place;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6)),
      ),
      child: const Text(
        'Ruta con IA',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

class _SavedPlace {
  final String id;
  final String name;
  final String description;
  final String type;
  final double estimatedTimeHours;
  final LatLng location;

  const _SavedPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.estimatedTimeHours,
    required this.location,
  });
}
