import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Proyectos/tarea_model.dart';
import 'package:intl/intl.dart';

/// Página de debug para ver TODAS las tareas sin filtros
class DebugTareasPage extends StatefulWidget {
  const DebugTareasPage({super.key});

  @override
  State<DebugTareasPage> createState() => _DebugTareasPageState();
}

class _DebugTareasPageState extends State<DebugTareasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _todasLasTareas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTodasLasTareas();
  }

  Future<void> _cargarTodasLasTareas() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final List<Map<String, dynamic>> tareas = [];

      // Obtener todos los proyectos
      final proyectosSnapshot = await _firestore
          .collection('proyectos')
          .where('uid', isEqualTo: user.uid)
          .get();

      debugPrint('📂 Total proyectos: ${proyectosSnapshot.docs.length}');

      for (var proyectoDoc in proyectosSnapshot.docs) {
        final proyectoNombre = proyectoDoc.data()['nombre'] ?? 'Sin nombre';

        // Obtener TODAS las tareas (sin filtro de completado)
        final tareasSnapshot = await _firestore
            .collection('proyectos')
            .doc(proyectoDoc.id)
            .collection('tareas')
            .get();

        debugPrint('   📝 $proyectoNombre: ${tareasSnapshot.docs.length} tareas');

        for (var tareaDoc in tareasSnapshot.docs) {
          final tareaData = tareaDoc.data();
          final tarea = Tarea.fromJson(tareaData);

          tareas.add({
            'proyecto': proyectoNombre,
            'titulo': tarea.titulo,
            'completado': tarea.completado,
            'fecha': tarea.fecha,
            'fechaLimite': tarea.fechaLimite,
            'fechaProgramada': tarea.fechaProgramada,
            'prioridad': tarea.prioridad,
          });
        }
      }

      setState(() {
        _todasLasTareas = tareas;
        _isLoading = false;
      });

      debugPrint('✅ Total tareas cargadas: ${tareas.length}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '❌ Sin fecha';
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(fecha);
  }

  bool _esHoy(DateTime? fecha) {
    if (fecha == null) return false;
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050915),
      appBar: AppBar(
        title: const Text('🔍 Debug: Todas las Tareas'),
        backgroundColor: const Color(0xFF1A1F3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTodasLasTareas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5BE4A8)))
          : _todasLasTareas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay tareas',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _todasLasTareas.length,
                  itemBuilder: (context, index) {
                    final tarea = _todasLasTareas[index];
                    final esHoyProgramada = _esHoy(tarea['fechaProgramada']);
                    final esHoyLimite = _esHoy(tarea['fechaLimite']);
                    final esHoyLegacy = _esHoy(tarea['fecha']);

                    return Card(
                      color: const Color(0xFF1A1F3A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título
                            Row(
                              children: [
                                Icon(
                                  tarea['completado'] ? Icons.check_circle : Icons.circle_outlined,
                                  color: tarea['completado'] ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tarea['titulo'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Proyecto
                            Text(
                              '📁 ${tarea['proyecto']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),

                            const Divider(color: Colors.white24, height: 24),

                            // Fechas
                            _buildFechaRow(
                              'fecha (legacy)',
                              tarea['fecha'],
                              esHoyLegacy,
                              Colors.grey,
                            ),
                            _buildFechaRow(
                              'fechaLimite',
                              tarea['fechaLimite'],
                              esHoyLimite,
                              Colors.purple,
                            ),
                            _buildFechaRow(
                              'fechaProgramada',
                              tarea['fechaProgramada'],
                              esHoyProgramada,
                              Colors.green,
                            ),

                            const SizedBox(height: 8),

                            // Info adicional
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPrioridadColor(tarea['prioridad']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Prioridad ${tarea['prioridad']}',
                                    style: TextStyle(
                                      color: _getPrioridadColor(tarea['prioridad']),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (tarea['completado'])
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ COMPLETADO',
                                      style: TextStyle(color: Colors.green, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildFechaRow(String campo, DateTime? fecha, bool esHoy, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              campo,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              _formatearFecha(fecha),
              style: TextStyle(
                color: esHoy ? Colors.greenAccent : Colors.white70,
                fontSize: 13,
                fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (esHoy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HOY',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPrioridadColor(int prioridad) {
    switch (prioridad) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
