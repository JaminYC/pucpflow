import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'proyecto_model.dart';
import 'ProyectoDetallePage.dart';

class ProyectosPage extends StatefulWidget {
  @override
  _ProyectosPageState createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Obtiene la lista de proyectos en los que el usuario participa
  Stream<List<Proyecto>> obtenerProyectos() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection("proyectos")
        .where("participantes", arrayContains: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Proyecto> proyectos = [];
      for (var doc in snapshot.docs) {
        Proyecto proyecto = Proyecto.fromJson(doc.data() as Map<String, dynamic>);

        // 🔹 Obtener el nombre del propietario desde Firestore
        final propietarioDoc = await _firestore.collection("users").doc(proyecto.propietario).get();
        String propietarioNombre = propietarioDoc.exists ? propietarioDoc["full_name"] ?? "Desconocido" : "Desconocido";

        // 🔹 Actualizar el proyecto con el nombre del propietario
        proyectos.add(proyecto.copyWith(propietario: propietarioNombre));

      }
      return proyectos;
    });
  }

  /// ✅ **Crear un nuevo proyecto**
  Future<void> crearProyecto(String nombreProyecto, bool esColaborativo) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ Error: Usuario no autenticado.");
      return;
    }

    final nuevoProyecto = Proyecto(
      id: _firestore.collection('proyectos').doc().id,
      nombre: nombreProyecto,
      descripcion: "Descripción del proyecto...",
      fechaInicio: DateTime.now(),
      propietario: user.uid,
      participantes: [user.uid], // ✅ Siempre incluir al creador
    );

    await _firestore
        .collection("proyectos")
        .doc(nuevoProyecto.id)
        .set(nuevoProyecto.toJson());

    print("✅ Proyecto creado: ${nuevoProyecto.nombre}");
  }


  /// ✅ **Editar nombre del proyecto**
  void _editarProyecto(Proyecto proyecto) {
  TextEditingController nombreController =
      TextEditingController(text: proyecto.nombre); // ✅ Inicializa con el nombre actual

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Editar Proyecto"),
        content: TextField(
          controller: nombreController, // ✅ Usamos el controlador
          decoration: const InputDecoration(hintText: "Nuevo nombre del proyecto"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                _firestore.collection("proyectos").doc(proyecto.id).update({
                  "nombre": nombreController.text,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      );
    },
  );
}


  /// ✅ **Eliminar un proyecto con confirmación**
  void _confirmarEliminarProyecto(Proyecto proyecto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Proyecto"),
        content: const Text("¿Estás seguro de que deseas eliminar este proyecto? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _eliminarProyecto(proyecto);
              Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  /// ✅ **Elimina un proyecto de Firestore**
  Future<void> _eliminarProyecto(Proyecto proyecto) async {
    await _firestore.collection("proyectos").doc(proyecto.id).delete();
    print("❌ Proyecto eliminado: ${proyecto.nombre}");
  }

  /// ✅ **Muestra un diálogo para crear un proyecto**
  void _mostrarDialogoNuevoProyecto() {
    String nombreProyecto = "";
    bool esColaborativo = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nuevo Proyecto"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: "Nombre del proyecto"),
                    onChanged: (value) => nombreProyecto = value,
                  ),
                  CheckboxListTile(
                    title: const Text("¿Es un proyecto colaborativo?"),
                    value: esColaborativo,
                    onChanged: (value) {
                      setStateDialog(() { // ✅ Corrige el problema del Checkbox
                        esColaborativo = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreProyecto.isNotEmpty) {
                      crearProyecto(nombreProyecto, esColaborativo);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ Ingresa un nombre para el proyecto"))
                      );
                    }
                  },
                  child: const Text("Crear"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("Mis Proyectos", style: TextStyle(color: Colors.white)),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
     ),
      body: Stack(
      children: [
        /// 🔹 **Fondo con degradado azul**
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        /// 🔹 **Lista de Proyectos con Tarjetas de Contorno Blanco**
        StreamBuilder<List<Proyecto>>(
          stream: obtenerProyectos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No tienes proyectos aún.", style: TextStyle(color: Colors.white)));
            }

            final proyectos = snapshot.data!;

            return ListView.builder(
              itemCount: proyectos.length,
              itemBuilder: (context, index) {
                final proyecto = proyectos[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2), // ✅ Contorno blanco
                  ),
                  child: Card(
                    color: Colors.transparent, // ✅ Hace que el Card siga el degradado del fondo
                    elevation: 0, // ✅ Evita sombras adicionales
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Colors.white),
                      title: Text(
                        proyecto.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        "Creador: ${proyecto.propietario}",
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProyectoDetallePage(proyecto: proyecto),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _editarProyecto(proyecto),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarEliminarProyecto(proyecto),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _mostrarDialogoNuevoProyecto,
      backgroundColor: const Color.fromARGB(255, 32, 32, 32), // ✅ Color del botón
      child: const Icon(Icons.add, color: Colors.blue),
    ),
    );
  }
}
