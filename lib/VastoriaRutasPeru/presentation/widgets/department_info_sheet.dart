import 'package:flutter/material.dart';

/// BottomSheet con información del departamento seleccionado
class DepartmentInfoSheet extends StatelessWidget {
  final String departmentId;
  final String departmentName;
  final VoidCallback onClose;

  const DepartmentInfoSheet({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.onClose,
  });

  // Información de departamentos de Perú
  static final Map<String, Map<String, dynamic>> _departmentData = {
    'lima': {
      'name': 'Lima',
      'region': 'Costa',
      'capital': 'Lima',
      'description': 'Capital del Perú y centro económico del país',
      'attractions': ['Plaza de Armas', 'Miraflores', 'Barranco', 'Centro Histórico'],
      'icon': '🏛️',
    },
    'cusco': {
      'name': 'Cusco',
      'region': 'Sierra',
      'capital': 'Cusco',
      'description': 'Capital arqueológica de América, hogar de Machu Picchu',
      'attractions': ['Machu Picchu', 'Valle Sagrado', 'Sacsayhuamán', 'Ollantaytambo'],
      'icon': '🏔️',
    },
    'arequipa': {
      'name': 'Arequipa',
      'region': 'Sierra',
      'capital': 'Arequipa',
      'description': 'La Ciudad Blanca, conocida por su arquitectura colonial',
      'attractions': ['Monasterio de Santa Catalina', 'Cañón del Colca', 'Plaza de Armas'],
      'icon': '🌋',
    },
    'loreto': {
      'name': 'Loreto',
      'region': 'Selva',
      'capital': 'Iquitos',
      'description': 'Puerta de entrada a la Amazonía peruana',
      'attractions': ['Río Amazonas', 'Reserva Pacaya-Samiria', 'Iquitos'],
      'icon': '🌳',
    },
    'puno': {
      'name': 'Puno',
      'region': 'Sierra',
      'capital': 'Puno',
      'description': 'Capital folklórica del Perú, a orillas del Lago Titicaca',
      'attractions': ['Lago Titicaca', 'Islas Flotantes de los Uros', 'Taquile'],
      'icon': '🛶',
    },
    'la_libertad': {
      'name': 'La Libertad',
      'region': 'Costa',
      'capital': 'Trujillo',
      'description': 'Cuna de la civilización Mochica y Chimú',
      'attractions': ['Chan Chan', 'Huaca de la Luna', 'Trujillo'],
      'icon': '🏺',
    },
    'piura': {
      'name': 'Piura',
      'region': 'Costa',
      'capital': 'Piura',
      'description': 'Playas paradisíacas del norte peruano',
      'attractions': ['Máncora', 'Cabo Blanco', 'Vichayito'],
      'icon': '🏖️',
    },
    'ica': {
      'name': 'Ica',
      'region': 'Costa',
      'capital': 'Ica',
      'description': 'Oasis en el desierto, famoso por el pisco y las dunas',
      'attractions': ['Líneas de Nazca', 'Huacachina', 'Islas Ballestas'],
      'icon': '🏜️',
    },
  };

  Map<String, dynamic> get _deptInfo {
    final normalizedId = departmentId.toLowerCase().replaceAll(' ', '_');
    return _departmentData[normalizedId] ?? {
      'name': departmentName,
      'region': 'Perú',
      'capital': departmentName,
      'description': 'Descubre las maravillas de $departmentName',
      'attractions': [],
      'icon': '📍',
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _deptInfo;

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

          // Header con emoji e info básica
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Emoji del departamento
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
                            info['name'] as String,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción
                Text(
                  info['description'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Atracciones principales
                if ((info['attractions'] as List).isNotEmpty) ...[
                  const Text(
                    '✨ Atracciones Principales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (info['attractions'] as List<String>)
                        .map((attraction) => Chip(
                              label: Text(
                                attraction,
                                style: const TextStyle(fontSize: 13),
                              ),
                              backgroundColor: const Color(0xFF57C0FF)
                                  .withValues(alpha: 0.1),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // Botón de explorar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navegar a página de exploración del departamento
                      onClose();
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explorar Rutas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57C0FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getRegionColor(String region) {
    switch (region.toLowerCase()) {
      case 'costa':
        return const Color(0xFF3B82F6); // Azul
      case 'sierra':
        return const Color(0xFF10B981); // Verde
      case 'selva':
        return const Color(0xFFF59E0B); // Naranja
      default:
        return const Color(0xFF8B5CF6); // Púrpura
    }
  }
}
