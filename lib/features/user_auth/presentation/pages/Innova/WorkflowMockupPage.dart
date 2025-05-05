import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

void main() {
  runApp(MaterialApp(home: FlowProcessMap()));
}

class FlowProcessMap extends StatelessWidget {
  final Graph graph = Graph()..isTree = false;
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  FlowProcessMap() {
    // Nodos principales
    final crearProyecto = Node.Id('Crear Proyecto');
    final agregarParticipantes = Node.Id('Agregar Participantes');
    final registrarReunion = Node.Id('Registrar Reunión');
    final resumenIA = Node.Id('Resumen IA');
    final generarTareas = Node.Id('Generar Tareas');
    final asignar = Node.Id('Asignar Responsables');
    final completar = Node.Id('Completar Tarea');

    // Subprocesos paralelos
    final validacionIA = Node.Id('Validación de Resumen');
    final agregarRequisitos = Node.Id('Agregar Requisitos');
    final asignacionInteligente = Node.Id('Match por Habilidad');
    final feedback = Node.Id('Evaluación de Desempeño');
    final actualizarPerfil = Node.Id('Actualizar Perfil de Usuario');

    // Estructura principal
    graph.addEdge(crearProyecto, agregarParticipantes);
    graph.addEdge(agregarParticipantes, registrarReunion);
    graph.addEdge(registrarReunion, resumenIA);
    graph.addEdge(resumenIA, generarTareas);
    graph.addEdge(generarTareas, asignar);
    graph.addEdge(asignar, completar);

    // Subprocesos / ramas
    graph.addEdge(resumenIA, validacionIA);
    graph.addEdge(generarTareas, agregarRequisitos);
    graph.addEdge(asignar, asignacionInteligente);
    graph.addEdge(completar, feedback);
    graph.addEdge(feedback, actualizarPerfil);

    builder
      ..siblingSeparation = 60
      ..levelSeparation = 100
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FLOW - Mapa Visual de Proceso con Subprocesos')),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 5,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
          builder: (Node node) => customNode(node.key!.value.toString()),
        ),
      ),
    );
  }

  Widget customNode(String label) {
    IconData icon;
    Color color;

    switch (label) {
      case 'Crear Proyecto':
        icon = Icons.folder_open;
        color = Colors.indigo;
        break;
      case 'Agregar Participantes':
        icon = Icons.group_add;
        color = Colors.teal;
        break;
      case 'Registrar Reunión':
        icon = Icons.mic;
        color = Colors.deepPurple;
        break;
      case 'Resumen IA':
        icon = Icons.memory;
        color = Colors.orange;
        break;
      case 'Validación de Resumen':
        icon = Icons.check;
        color = Colors.orange.shade300;
        break;
      case 'Generar Tareas':
        icon = Icons.task;
        color = Colors.blue;
        break;
      case 'Agregar Requisitos':
        icon = Icons.list_alt;
        color = Colors.blue.shade300;
        break;
      case 'Asignar Responsables':
        icon = Icons.assignment_ind;
        color = Colors.green;
        break;
      case 'Match por Habilidad':
        icon = Icons.auto_fix_high;
        color = Colors.green.shade300;
        break;
      case 'Completar Tarea':
        icon = Icons.check_circle;
        color = Colors.lightBlue;
        break;
      case 'Evaluación de Desempeño':
        icon = Icons.star_rate;
        color = Colors.pink;
        break;
      case 'Actualizar Perfil de Usuario':
        icon = Icons.person;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.device_unknown;
        color = Colors.grey;
    }

    return Container(
      width: 180,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
