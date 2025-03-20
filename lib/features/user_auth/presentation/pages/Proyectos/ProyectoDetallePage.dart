import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/TareaFormWidget.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ReunionPresencialPage.dart';


Color _colorDesdeUID(String uid) {
  final int hash = uid.hashCode;
  final double hue = 40 + (hash % 280); // evita rojos/verdes planos
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.7).toColor();
}


class ProyectoDetallePage extends StatefulWidget {
  final String proyectoId;

  const ProyectoDetallePage({super.key, required this.proyectoId});

  @override
  State<ProyectoDetallePage> createState() => _ProyectoDetallePageState();
}

class _ProyectoDetallePageState extends State<ProyectoDetallePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TareaService _tareaService = TareaService();

  List<Tarea> tareas = [];
  Map<String, String> nombreResponsables = {};
  List<Map<String, String>> participantes = [];
  bool loading = true;
  bool participantesExpandido = true;
  bool mostrarPendientes = true;

  @override
  void initState() {
    super.initState();
    _cargarTareas();
    _cargarParticipantes();
  }

  Future<void> _cargarTareas() async {
    tareas = await _tareaService.obtenerTareasDelProyecto(widget.proyectoId);
    await _cargarNombresResponsables();
    setState(() => loading = false);
  }

  Future<void> _cargarNombresResponsables() async {
    final uids = tareas.expand((t) => t.responsables).toSet();
    for (String uid in uids) {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        nombreResponsables[uid] = doc.data()!["full_name"] ?? "Usuario";
      }
    }
  }

  Future<void> _cargarParticipantes() async {
    final doc = await _firestore.collection("proyectos").doc(widget.proyectoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> uids = data["participantes"] ?? [];
      final List<Map<String, String>> temp = [];

      for (String uid in uids) {
        final userDoc = await _firestore.collection("users").doc(uid).get();
        if (userDoc.exists) {
          temp.add({
            "uid": uid,
            "nombre": userDoc["full_name"] ?? "Usuario",
            "email": userDoc["email"] ?? "",
          });
        }
      }

      setState(() {
        participantes = temp;
      });
    }
  }

  Future<void> _agregarParticipantePorEmail(String email) async {
    final snapshot = await _firestore.collection("users").where("email", isEqualTo: email).get();
    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no encontrado")),
      );
      return;
    }
    final uid = snapshot.docs.first.id;
    await _firestore.collection("proyectos").doc(widget.proyectoId).update({
      "participantes": FieldValue.arrayUnion([uid])
    });
    await _cargarParticipantes();
  }

  Future<void> _eliminarParticipante(String uid) async {
    await _firestore.collection("proyectos").doc(widget.proyectoId).update({
      "participantes": FieldValue.arrayRemove([uid])
    });
    await _cargarParticipantes();
  }

  Future<void> _agregarTarea(Tarea tarea) async {
    if (tarea.tipoTarea == "Libre" && tarea.responsables.isNotEmpty) {
      tarea.tipoTarea = "Asignada";
    }
    await _tareaService.agregarTareaAProyecto(widget.proyectoId, tarea);
    await _cargarTareas();
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    await _tareaService.eliminarTareaDeProyecto(widget.proyectoId, tarea);
    await _cargarTareas();
  }

  Future<void> _editarTarea(Tarea original, Tarea editada) async {
    if (editada.tipoTarea == "Libre" && editada.responsables.isNotEmpty) {
      editada.tipoTarea = "Asignada";
    }
    await _tareaService.actualizarTareaEnProyecto(widget.proyectoId, original, editada);
    await _cargarTareas();
  }

Future<void> _marcarTareaCompletada(Tarea tarea, bool completado) async {
    final userId = _auth.currentUser!.uid;
    if (!tarea.responsables.contains(userId)) return;

    final querySnapshot = await _firestore.collection("proyectos").get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];

      for (int i = 0; i < tareas.length; i++) {
        if (tareas[i]["titulo"] == tarea.titulo) {
          tareas[i]["completado"] = true;
        }
      }
      await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
    }

    await _actualizarPuntosUsuario(userId, tarea);
    await _cargarTareas();

  }

  Future<void> _actualizarPuntosUsuario(String userId, Tarea tarea) async {
    final userDoc = _firestore.collection("users").doc(userId);
    final userSnapshot = await userDoc.get();
    if (!userSnapshot.exists) return;

    final userData = userSnapshot.data() as Map<String, dynamic>;
    int puntosActuales = userData["puntosTotales"] ?? 0;
    Map<String, dynamic> habilidades = Map.from(userData["habilidades"] ?? {});

    int puntosGanados = 10;
    if (tarea.dificultad == "media") puntosGanados += 5;
    if (tarea.dificultad == "alta") puntosGanados += 10;

    tarea.requisitos.forEach((habilidad, impacto) {
      habilidades[habilidad] = (habilidades[habilidad] ?? 0) + impacto;
    });

    await userDoc.update({
      "puntosTotales": puntosActuales + puntosGanados,
      "habilidades": habilidades,
    });
  }

void _mostrarDialogoNuevaTarea() {
  showDialog(
    context: context,
    builder: (context) {
      bool cargando = false;

      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: cargando
                        ? const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          )
                        : TareaFormWidget(
                            participantes: participantes,
                            onSubmit: (nuevaTarea) async {
                              setStateDialog(() => cargando = true);
                              await _agregarTarea(nuevaTarea);
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ Tarea agregada")),
                                );
                              }
                            },
                          ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: "Cerrar",
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildTareaCard(Tarea tarea) {
  final esResponsable = tarea.responsables.contains(_auth.currentUser!.uid);
  final responsablesNombres = tarea.responsables
      .map((id) => nombreResponsables[id] ?? "-usuario-")
      .join(", ");

  Color colorIndicador = tarea.responsables.isNotEmpty
      ? _colorDesdeUID(tarea.responsables.first)
      : Colors.grey;

  return Card(
    margin: const EdgeInsets.all(8),
    color: tarea.completado ? Colors.green[100] : Colors.white,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        // 🎨 Indicador de color tipo “pin” o banda lateral
        Container(
          width: 8,
          height: 140,
          decoration: BoxDecoration(
            color: colorIndicador,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ Título + checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tarea.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: tarea.completado,
                      onChanged: esResponsable
                          ? (value) async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              await _marcarTareaCompletada(tarea, value!);
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                    )
                  ],
                ),

                /// ✅ Chips de tipo y dificultad
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      backgroundColor: Colors.black,
                      avatar: const Icon(Icons.category, color: Colors.white, size: 18),
                      label: Text(
                        tarea.tipoTarea,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (tarea.dificultad != null)
                      Chip(
                        backgroundColor: Colors.black,
                        avatar: const Icon(Icons.trending_up, color: Colors.white, size: 18),
                        label: Text(
                          "Dificultad: ${tarea.dificultad}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),

                /// ✅ Descripción (si existe)
                if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("📋 ${tarea.descripcion}"),
                  ),

                /// ✅ Responsables
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("👤 Responsables: $responsablesNombres"),
                ),

                /// ✅ Acciones
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.group_add, color: Colors.blue),
                        onPressed: () => _mostrarDialogoAsignarParticipantes(tarea),
                        tooltip: "Agregar participante",
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              bool cargando = false;
                              return StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.black,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Stack(
                                        children: [
                                          SizedBox(
                                            width: double.maxFinite,
                                            child: cargando
                                                ? const SizedBox(
                                                    height: 100,
                                                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                                  )
                                                : TareaFormWidget(
                                                    tareaInicial: tarea,
                                                    participantes: participantes,
                                                    onSubmit: (tareaEditada) async {
                                                      setStateDialog(() => cargando = true);
                                                      await _editarTarea(tarea, tareaEditada);
                                                      if (mounted) {
                                                        Navigator.of(context).pop();
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text("✅ Tarea actualizada")),
                                                        );
                                                      }
                                                    },
                                                  ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white),
                                              onPressed: () => Navigator.of(context).pop(),
                                              tooltip: "Cerrar",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        tooltip: "Editar tarea",
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("¿Eliminar tarea?"),
                              content: const Text("Esta acción no se puede deshacer."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await Future.delayed(Duration(milliseconds: 50));
                                    late BuildContext loaderContext;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) {
                                        loaderContext = ctx;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    );
                                    await _eliminarTarea(tarea);
                                    Navigator.of(loaderContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("✅ Tarea eliminada")),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Eliminar"),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: "Eliminar tarea",
                      ),
                    ],
                  ),
                ],
              ),

              ],
            ),
          ),
        )
      ],
    ),
  );
}

void _mostrarDialogoAsignarParticipantes(Tarea tarea) {
  List<String> seleccionados = List<String>.from(tarea.responsables);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFFF4EFFA),
            title: const Text("Asignar Participantes", style: TextStyle(fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: participantes.map((p) {
                  final uid = p["uid"]!;
                  return CheckboxListTile(
                    value: seleccionados.contains(uid),
                    title: Text(p["nombre"] ?? ""),
                    controlAffinity: ListTileControlAffinity.trailing,
                    onChanged: (checked) {
                      setStateDialog(() {
                        if (checked == true && !seleccionados.contains(uid)) {
                          seleccionados.add(uid);
                        } else {
                          seleccionados.remove(uid);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // ✅ Cierra correctamente
                child: const Text("Cancelar", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  final editada = Tarea(
                    titulo: tarea.titulo,
                    duracion: tarea.duracion,
                    colorId: tarea.colorId,
                    tipoTarea: seleccionados.isEmpty ? "Libre" : "Asignada",
                    requisitos: tarea.requisitos,
                    dificultad: tarea.dificultad,
                    descripcion: tarea.descripcion,
                    responsables: seleccionados,
                    completado: tarea.completado,
                    prioridad: tarea.prioridad,
                  );
                  await _editarTarea(tarea, editada);
                  if (context.mounted) Navigator.of(context).pop(); // ✅ Cierra sin errores
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    },
  );
}


  Widget _buildParticipantesSection() {
  String nuevoEmail = "";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => participantesExpandido = !participantesExpandido),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    participantesExpandido ? "Ocultar participantes" : "Mostrar participantes",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Agregar Participante"),
                    content: TextField(
                      decoration: const InputDecoration(hintText: "Correo del participante"),
                      onChanged: (value) => nuevoEmail = value,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _agregarParticipantePorEmail(nuevoEmail);
                        },
                        child: const Text("Agregar"),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
        const SizedBox(height: 12),

        // PARTICIPANTES
        if (participantesExpandido)
          ...participantes.map((p) {
            final uid = p["uid"]!;
            final nombre = p["nombre"] ?? "-";
            final email = p["email"] ?? "";
            final colorUsuario = _colorDesdeUID(uid);

            // Filtrar tareas por usuario
            final tareasAsignadas = tareas.where((t) => t.responsables.contains(uid)).toList();
            final tareasCompletadas = tareasAsignadas.where((t) => t.completado).toList();
            final tareasPendientes = tareasAsignadas.where((t) => !t.completado).toList();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorUsuario, width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: colorUsuario,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: GestureDetector(
                  onTap: () => _mostrarTareasDelParticipante(uid, nombre),
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _chipResumen("Asignadas: ${tareasAsignadas.length}", Colors.black),
                        const SizedBox(width: 4),
                        _chipResumen("Hechas: ${tareasCompletadas.length}", Colors.green),
                        const SizedBox(width: 4),
                        _chipResumen("Pendientes: ${tareasPendientes.length}", Colors.orange),
                      ],
                    )
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () async {
                    await _eliminarParticipante(uid);
                  },
                ),
              ),
            );
          })

      ],
    ),
  );
}
void _mostrarTareasDelParticipante(String uid, String nombre) {
  final tareasUsuario = tareas.where((t) => t.responsables.contains(uid)).toList();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Tareas de $nombre"),
        content: SizedBox(
          width: double.maxFinite,
          child: tareasUsuario.isEmpty
              ? const Text("No tiene tareas asignadas.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tareasUsuario.length,
                  itemBuilder: (context, index) {
                    final tarea = tareasUsuario[index];
                    return ListTile(
                      leading: Icon(
                        tarea.completado ? Icons.check_circle : Icons.hourglass_bottom,
                        color: tarea.completado ? Colors.green : Colors.orange,
                      ),
                      title: Text(tarea.titulo),
                      subtitle: tarea.descripcion != null && tarea.descripcion!.isNotEmpty
                          ? Text(tarea.descripcion!)
                          : null,
                      trailing: Chip(
                        backgroundColor: tarea.completado ? Colors.green[100] : Colors.orange[100],
                        label: Text(tarea.completado ? "Hecha" : "Pendiente"),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      );
    },
  );
}

Widget _chipResumen(String texto, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Detalle del Proyecto", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),

          loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildParticipantesSection(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          ExpansionTile(
                            title: const Text("Tareas Pendientes", style: TextStyle(color: Colors.white)),
                            initiallyExpanded: true,
                            backgroundColor: Colors.white10,
                            collapsedIconColor: Colors.white,
                            iconColor: Colors.white,
                            children: tareas
                                .where((t) => !t.completado)
                                .map((t) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: _buildTareaCard(t),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          ExpansionTile(
                            title: const Text("Tareas Completadas", style: TextStyle(color: Colors.white)),
                            initiallyExpanded: false,
                            backgroundColor: Colors.white10,
                            collapsedIconColor: Colors.white,
                            iconColor: Colors.white,
                            children: tareas
                                .where((t) => t.completado)
                                .map((t) => _buildTareaCard(t))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "reunionBtn",
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            icon: const Icon(Icons.mic, color: Colors.white),
            label: const Text("Reunión", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              // Cargar el proyecto desde Firestore usando el ID
              final doc = await FirebaseFirestore.instance
                  .collection("proyectos")
                  .doc(widget.proyectoId)
                  .get();

              if (doc.exists) {
                final proyecto = Proyecto.fromJson(doc.data()!);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReunionPresencialPage(proyecto: proyecto),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Proyecto no encontrado")),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "tareaBtn",
            backgroundColor: Colors.white,
            label: const Text("Nueva tarea", style: TextStyle(color: Colors.black)),
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _mostrarDialogoNuevaTarea,
          ),
        ],
      ),

    );
  }
}
