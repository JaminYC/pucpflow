import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/google_routes_service.dart';

/// Barra de búsqueda premium para lugares
class SearchBarWidget extends StatefulWidget {
  final Function(PlaceResult place) onPlaceSelected;

  const SearchBarWidget({
    super.key,
    required this.onPlaceSelected,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleRoutesService _placesService = GoogleRoutesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Usar Places Autocomplete para búsqueda inteligente
      final results = await _placesService.searchPlaces(
        query: query,
        location: const LatLng(-12.0464, -77.0428), // Centrado en Perú
      );

      setState(() {
        _searchResults = results;
        _showResults = true;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _savePlace(PlaceResult place) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesion para guardar lugares.')),
        );
      }
      return;
    }

    final docId = place.placeId.isNotEmpty ? place.placeId : _slugify(place.name);
    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_places')
        .doc('search__$docId');

    await ref.set({
      'departmentId': '',
      'name': place.name,
      'type': 'busqueda',
      'description': place.vicinity ?? '',
      'estimatedTimeHours': 0,
      'lat': place.location.latitude,
      'lng': place.location.longitude,
      'placeId': place.placeId,
      'rating': place.rating,
      'source': 'search',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado: ${place.name}')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra de búsqueda
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            onChanged: (value) {
              // Debounce: buscar después de 500ms de inactividad
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _performSearch(value);
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar lugares, atracciones, hoteles...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showResults = false;
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF57C0FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF57C0FF),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    place.vicinity ?? 'Perú',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (place.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        onPressed: () => _savePlace(place),
                        icon: const Icon(Icons.bookmark_border),
                        tooltip: 'Guardar',
                      ),
                    ],
                  ),
                  onTap: () {
                    widget.onPlaceSelected(place);
                    setState(() {
                      _showResults = false;
                      _searchController.clear();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
