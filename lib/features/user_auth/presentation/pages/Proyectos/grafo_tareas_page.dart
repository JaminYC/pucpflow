
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'tarea_model.dart';

class GrafoTareasPage extends StatelessWidget {
  final List<Tarea> tareas;

  final Map<String, String> nombreResponsables;

  const GrafoTareasPage({
    super.key,
    required this.tareas,
    required this.nombreResponsables,
  });

  @override
  Widget build(BuildContext context) {
    final Graph graph = Graph();
    final SugiyamaConfiguration builder = SugiyamaConfiguration()
      ..nodeSeparation = 100
      ..levelSeparation = 100
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    final Map<String, Node> nodos = {};
    final List<Color> paleta = [
      Colors.blueAccent,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.cyan,
      Colors.pinkAccent,
    ];

    final Map<String, List<Tarea>> tareasPorArea = {};
    for (var tarea in tareas) {
      tareasPorArea.putIfAbsent(tarea.area, () => []).add(tarea);
    }

    final List<String> areasOrdenadas = tareasPorArea.keys.toList()..sort();
    final Map<String, Color> coloresArea = {};
    for (int i = 0; i < areasOrdenadas.length; i++) {
      coloresArea[areasOrdenadas[i]] = paleta[i % paleta.length];
    }

    for (String area in areasOrdenadas) {
      final color = coloresArea[area] ?? Colors.grey;
      for (var tarea in tareasPorArea[area]!) {
        final node = Node.Id(tarea.titulo);
        nodos[tarea.titulo] = node;
        graph.addNode(node);
      }
    }

    for (var tarea in tareas) {
      for (var previa in tarea.tareasPrevias) {
        final source = nodos[previa];
        final target = nodos[tarea.titulo];
        if (source != null && target != null) {
          graph.addEdge(source, target);
        }
      }
    }

    for (String area in tareasPorArea.keys) {
      final tareasOrdenadas = tareasPorArea[area]!;
      for (int i = 0; i < tareasOrdenadas.length - 1; i++) {
        final source = nodos[tareasOrdenadas[i].titulo];
        final target = nodos[tareasOrdenadas[i + 1].titulo];
        if (source != null && target != null) {
          graph.addEdge(source, target);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Flujo de Tareas por Área', style: TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(200),
        minScale: 0.05,
        maxScale: 5.0,
        child: GraphView(
          graph: graph,
          algorithm: SugiyamaAlgorithm(builder),
          builder: (Node node) {
            final titulo = (node.key as ValueKey).value;
            final tarea = tareas.firstWhere((t) => t.titulo == titulo);
            final color = coloresArea[tarea.area] ?? Colors.grey;
            return _buildTareaNode(tarea, color);
          },
        ),
      ),
    );
  }

  Widget _buildTareaNode(Tarea tarea, Color color) {
    final responsables = tarea.responsables
    .map((uid) => nombreResponsables[uid] ?? "Desconocido")
    .join(", ");
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(tarea.area, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.black.withOpacity(0.3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              if (tarea.dificultad != null)
                Chip(
                  label: Text("🎯 ${tarea.dificultad}", style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.deepPurple.shade400,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              Chip(
                avatar: const Icon(Icons.schedule, size: 16, color: Colors.white),
                label: Text("${tarea.duracion} min", style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.indigo,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            
            ],
          ),
          if (tarea.responsables.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text("Responsables:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Text(
            responsables,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
