import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/vastoria_ai_service.dart';

class SavedPlacesSheet extends StatefulWidget {
  const SavedPlacesSheet({super.key});

  @override
  State<SavedPlacesSheet> createState() => _SavedPlacesSheetState();
}

class _SavedPlacesSheetState extends State<SavedPlacesSheet> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VastoriaAIService _aiService = VastoriaAIService();

  Stream<List<_SavedPlace>> _watchSavedPlaces(User user) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_places')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _SavedPlace(
          id: doc.id,
          name: (data['name'] as String?) ?? 'Lugar',
          description: (data['description'] as String?) ?? '',
          type: (data['type'] as String?) ?? 'lugar',
          estimatedTimeHours:
              (data['estimatedTimeHours'] as num?)?.toDouble() ?? 0,
          departmentId: (data['departmentId'] as String?) ?? '',
        );
      }).toList();
    });
  }

  Future<void> _removeSavedPlace(User user, _SavedPlace place) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_places')
        .doc(place.id)
        .delete();
  }

  Future<void> _generateItinerary(List<_SavedPlace> places) async {
    if (places.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('ADAN esta creando tu itinerario...'),
          ],
        ),
      ),
    );

    try {
      final payload = places
          .map((place) => {
                'name': place.name,
                'type': place.type,
                'description': place.description,
                'estimatedHours': place.estimatedTimeHours,
              })
          .toList();

      final itinerary = await _aiService.generateItinerary(
        places: payload,
        days: (places.length / 2).ceil(),
        preferences: ['turismo', 'cultura'],
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildItinerarySheet(itinerary),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return _buildBaseContainer(
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Inicia sesion para ver tus lugares guardados.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return StreamBuilder<List<_SavedPlace>>(
          stream: _watchSavedPlaces(user),
          builder: (context, snapshot) {
            final places = snapshot.data ?? const [];

            return _buildBaseContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: Color(0xFF3B82F6),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lugares guardados',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${places.length} lugares',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
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
                  Flexible(
                    child: places.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aun no tienes lugares guardados.',
                              style: TextStyle(fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: places.length,
                            itemBuilder: (context, index) {
                              final place = places[index];
                              return _buildSavedPlaceTile(user, place);
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: places.isEmpty
                                ? null
                                : () => _generateItinerary(places),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Generar itinerario con guardados'),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedPlaceTile(User user, _SavedPlace place) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.place,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (place.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    place.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildChip(place.type),
                    if (place.departmentId.isNotEmpty)
                      _buildChip(place.departmentId),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeSavedPlace(user, place),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Quitar',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildBaseContainer({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
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
                      'Itinerario con guardados',
                      style: TextStyle(
                        fontSize: 20,
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
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                itinerary['itinerary']?.toString() ??
                    'No se pudo generar el itinerario',
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
}

class _SavedPlace {
  final String id;
  final String name;
  final String description;
  final String type;
  final double estimatedTimeHours;
  final String departmentId;

  const _SavedPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.estimatedTimeHours,
    required this.departmentId,
  });
}
