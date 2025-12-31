import 'package:flutter/material.dart';

import '../widgets/peru_map.dart';
import '../widgets/saved_places_sheet.dart';

class PeruDashboardScreen extends StatefulWidget {
  const PeruDashboardScreen({super.key});

  @override
  State<PeruDashboardScreen> createState() => _PeruDashboardScreenState();
}

class _PeruDashboardScreenState extends State<PeruDashboardScreen> {
  void _openSavedPlaces() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SavedPlacesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VASTORIA - Rutas Peru'),
        actions: [
          IconButton(
            onPressed: _openSavedPlaces,
            icon: const Icon(Icons.bookmark),
            tooltip: 'Lugares guardados',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          PeruMap(
            onDeptSelected: (_) {},
            enableSelection: false,
          ),
        ],
      ),
    );
  }
}
