import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'proyecto_model.dart';
import 'ProyectoDetallePage.dart';

class ProyectosPage extends StatefulWidget {
  const ProyectosPage({super.key});

  @override
  State<ProyectosPage> createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage> {
  List<Proyecto> proyectos = [];

  @override
  void initState() {
    super.initState();
    _loadProyectos();
  }

  Future<void> _loadProyectos() async {
    final prefs = await SharedPreferences.getInstance();
    final proyectosData = prefs.getStringList('proyectos') ?? [];

    setState(() {
      proyectos = List<Proyecto>.from(proyectosData
          .map((proyectoJson) => Proyecto.fromJson(jsonDecode(proyectoJson))));
    });
  }

  Future<void> _addProyecto(Proyecto proyecto) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proyectos.add(proyecto);
    });

    // 🔹 Guardar proyectos sin importar si tienen tareas o no
    final proyectosData = proyectos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('proyectos', proyectosData);
  }


  Future<void> _deleteProyecto(Proyecto proyecto) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proyectos = List<Proyecto>.from(proyectos)..remove(proyecto);
    });

    final proyectosData = proyectos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('proyectos', proyectosData);
  }

  Future<void> _clearAllProyectos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('proyectos'); // Elimina todos los proyectos almacenados

    setState(() {
      proyectos = [];
    });
  }

  void _showAddProyectoDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del Proyecto'),
            ),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoProyecto = Proyecto(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nombre: nombreController.text,
                descripcion: descripcionController.text,
                fechaInicio: DateTime.now(),
              );
              _addProyecto(nuevoProyecto);
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              _clearAllProyectos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todos los proyectos han sido eliminados.')),
              );
            },
          ),
        ],
      ),
      body: proyectos.isEmpty
          ? const Center(child: Text('No hay proyectos registrados.'))
          : ListView.builder(
              itemCount: proyectos.length,
              itemBuilder: (context, index) {
                final proyecto = proyectos[index];
                return Dismissible(
                  key: Key(proyecto.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteProyecto(proyecto);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${proyecto.nombre} eliminado.')),
                    );
                  },
                  child: ListTile(
                    title: Text(proyecto.nombre),
                    subtitle: Text(proyecto.descripcion),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProyectoDetallePage(proyecto: proyecto),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProyectoDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
} 
