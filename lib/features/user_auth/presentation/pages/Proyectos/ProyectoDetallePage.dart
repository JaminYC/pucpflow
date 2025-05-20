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

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/grafo_tareas_page.dart';

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
  Map<String, List<String>> areas = {};
  String? areaSeleccionada; // null = ver todas


  @override
  void initState() {
    super.initState();
    _cargarTareas();
    _cargarParticipantes();
    _cargarAreas(); 
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

  Future<void> _cargarAreas() async {
  final doc = await _firestore.collection("proyectos").doc(widget.proyectoId).get();
  if (doc.exists) {
    final data = doc.data()!;
    final fetchedAreas = Map<String, List<String>>.from(
      (data["areas"] ?? {}).map((k, v) => MapEntry(k, List<String>.from(v)))
    );
    setState(() {
      areas = fetchedAreas;
    });
  }
}

void _mostrarDialogoNuevaTarea() {
  showDialog(
    context: context,
    builder: (context) {
      bool cargando = false;

      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    cargando
                        ? Center(
                            child: Image.asset(
                              "assets/animations/animation.gif",
                              width: 120,
                              height: 120,
                            ),
                          )
                        : SingleChildScrollView(
                            child: TareaFormWidget(
                              participantes: participantes,
                              areas: areas,
                              onSubmit: (nuevaTarea) async {
                                setStateDialog(() => cargando = true);
                                await _agregarTarea(nuevaTarea);
                                if (context.mounted) {
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
            ),
          );
        },
      );
    },
  );
}




 Widget _buildFiltroAreas() {
  final List<String> nombresAreas = areas.keys.toList();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Text("Filtrar por área:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          dropdownColor: Colors.black,
          value: areaSeleccionada ?? "Todas",  // ✅ si es null, usa "Todas"
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          items: [
            const DropdownMenuItem<String>(
              value: "Todas",
              child: Text("Todas las áreas", style: TextStyle(color: Colors.white)),
            ),
            ...nombresAreas.map(
              (area) => DropdownMenuItem<String>(
                value: area,
                child: Text(area, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              areaSeleccionada = value == "Todas" ? null : value;
              debugPrint("🎯 Área seleccionada: $areaSeleccionada");
            });
          },
        ),
      ],
    ),
  );
}


 Widget _buildTareaCard(Tarea tarea) {
  final esResponsable = tarea.responsables.contains(_auth.currentUser!.uid);
  final responsablesNombres = tarea.responsables
      .map((id) => nombreResponsables[id] ?? "-usuario-")
      .join(", ");

  final Color colorIndicador = tarea.responsables.isNotEmpty
      ? _colorDesdeUID(tarea.responsables.first)
      : Colors.grey;

  return SizedBox(
    width: 260,
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: tarea.completado ? Colors.green[50] : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔘 Título + checkbox
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
                             builder: (_) => Center(child: Image.asset('assets/animation.gif')),
                          );
                          await _marcarTareaCompletada(tarea, value!);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),

            /// 🧩 Chips de tipo + dificultad
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  backgroundColor: Colors.black,
                  avatar: const Icon(Icons.category, color: Colors.white, size: 18),
                  label: Text(tarea.tipoTarea, style: const TextStyle(color: Colors.white)),
                ),
                if (tarea.dificultad != null)
                  Chip(
                    backgroundColor: Colors.black,
                    avatar: const Icon(Icons.trending_up, color: Colors.white, size: 18),
                    label: Text("Dificultad: ${tarea.dificultad}", style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),

            /// 📋 Descripción
            if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("📋 ${tarea.descripcion}"),
              ),

            /// 👤 Responsables
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("👤 Responsables: $responsablesNombres"),
            ),

            /// ⚙️ Acciones
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              alignment: WrapAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.blue),
                  tooltip: "Asignar participantes",
                  onPressed: () => _mostrarDialogoAsignarParticipantes(tarea),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: "Editar tarea",
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        bool cargando = false;
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return Dialog(
                              insetPadding: const EdgeInsets.all(12),
                              backgroundColor: Colors.black,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Stack(
                                    children: [
                                      cargando
                                        ? Center(
                                            child: Image.asset('assets/animation.gif', width: 150),
                                          )
                                          : TareaFormWidget(
                                              tareaInicial: tarea,
                                              areas: areas,
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
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Eliminar tarea",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("¿Eliminar tarea?"),
                        content: const Text("Esta acción no se puede deshacer."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Future.delayed(const Duration(milliseconds: 100));
                              late BuildContext loaderContext;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) {
                                  loaderContext = ctx;
                                  return Center(
                                    child: Image.asset(
                                      'assets/animation.gif',
                                      width: 150,
                                      fit: BoxFit.contain,
                                    ),
                                  );
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
                ),
              ],
            ),
          ],
        ),
      ),
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
                children: [
                  CheckboxListTile(
                    value: seleccionados.length == participantes.length,
                    title: const Text("Todos"),
                    controlAffinity: ListTileControlAffinity.trailing,
                    onChanged: (checked) {
                      setStateDialog(() {
                        if (checked == true) {
                          seleccionados = participantes.map((p) => p["uid"]!).toList();
                        } else {
                          seleccionados.clear();
                        }
                      });
                    },
                  ),
                  ...participantes.map((p) {
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
                ],

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
        if (participantesExpandido)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: participantes.map((p) {
              final uid = p["uid"]!;
              final nombre = p["nombre"] ?? "-";
              final colorUsuario = _colorDesdeUID(uid);
              return GestureDetector(
                  onTap: () => _mostrarTareasDelParticipante(uid, nombre),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: colorUsuario,
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    label: Text(
                      nombre,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.white,
                    deleteIcon: const Icon(Icons.close, color: Colors.red),
                    onDeleted: () => _eliminarParticipante(uid),
                  ),
                );

            }).toList(),
          ),
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

 void _mostrarDialogoNuevaArea() {
  String nombreArea = "";
  List<String> seleccionados = [];

  showDialog(
    context: context,
    builder: (_) {
      return _dialogoArea(
        titulo: "Crear Nueva Área",
        nombreInicial: "",
        seleccionInicial: [],
        onGuardar: (nombre, uids) => _guardarArea(nombre, uids),
      );
    },
  );
}

 void _mostrarDialogoEditarArea(String nombreArea, List<String> actuales) {
  showDialog(
    context: context,
    builder: (_) {
      return _dialogoArea(
        titulo: "Editar Área: $nombreArea",
        nombreInicial: nombreArea,
        seleccionInicial: actuales,
        onGuardar: (nuevoNombre, uids) async {
          // Si cambia de nombre, primero elimina la antigua
          if (nuevoNombre != nombreArea) {
            final ref = _firestore.collection("proyectos").doc(widget.proyectoId);
            await ref.update({"areas.$nombreArea": FieldValue.delete()});
          }
          await _guardarArea(nuevoNombre, uids);
        },
        onEliminar: () async {
          final ref = _firestore.collection("proyectos").doc(widget.proyectoId);
          await ref.update({"areas.$nombreArea": FieldValue.delete()});
          await _cargarAreas();
          
          Navigator.pop(context);
        },
      );
    },
  );
}

 Widget _dialogoArea({
  required String titulo,
  required String nombreInicial,
  required List<String> seleccionInicial,
  required Function(String, List<String>) onGuardar,
  Function()? onEliminar, // nuevo parámetro opcional
}) {
  String nombreArea = nombreInicial;
  List<String> seleccionados = List<String>.from(seleccionInicial);

  return StatefulBuilder(
    builder: (context, setStateDialog) {
      return AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nombre del área"),
                controller: TextEditingController(text: nombreArea),
                onChanged: (v) => nombreArea = v,
              ),
              const SizedBox(height: 10),
              const Text("Participantes:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...participantes.map((p) {
                final uid = p["uid"]!;
                return CheckboxListTile(
                  title: Text(p["nombre"] ?? ""),
                  value: seleccionados.contains(uid),
                  onChanged: (checked) {
                    setStateDialog(() {
                      if (checked == true) {
                        seleccionados.add(uid);
                      } else {
                        seleccionados.remove(uid);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              onGuardar(nombreArea, seleccionados);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      );
    },
  );
}

 Future<void> _guardarArea(String nombre, List<String> participantesArea) async {
  final safeNombre = _sanitizarNombreArea(nombre);
  final docRef = _firestore.collection("proyectos").doc(widget.proyectoId);
  await docRef.set({
    "areas": {safeNombre: participantesArea}
  }, SetOptions(merge: true));
  await _cargarAreas();
}

 String _sanitizarNombreArea(String nombre) {
  return nombre.replaceAll('.', '-').replaceAll('[', '').replaceAll(']', '');
}

Widget _buildAreasSection() {
  return ExpansionTile(
    title: const Text(
      "Áreas del Proyecto",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    backgroundColor: Colors.white10,
    collapsedIconColor: Colors.white,
    iconColor: Colors.white,
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    children: [
      /// 🧭 Sección scrollable limitada en altura
      SizedBox(
        height: 300, // Puedes ajustar esta altura
        child: ListView.builder(
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final entry = areas.entries.elementAt(index);
            final area = entry.key;
            final miembros = entry.value.map((uid) {
              final p = participantes.firstWhere(
                (e) => e["uid"] == uid,
                orElse: () => {"nombre": "?"}
              );
              return p["nombre"];
            }).join(", ");

            return Card(
              color: Colors.blueGrey.shade800,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("👥 $miembros", style: const TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _mostrarDialogoEditarArea(area, entry.value),
                      tooltip: "Editar área",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarEliminarArea(area),
                      tooltip: "Eliminar área",
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text("Agregar Área"),
        onPressed: _mostrarDialogoNuevaArea,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
      ),
    ],
  );
}


 void _confirmarEliminarArea(String nombreArea) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("¿Eliminar área?"),
      content: Text("¿Estás seguro de que deseas eliminar el área \"$nombreArea\"? Esta acción no se puede deshacer."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final docRef = FirebaseFirestore.instance.collection("proyectos").doc(widget.proyectoId);
            await docRef.update({"areas.$nombreArea": FieldValue.delete()});
            setState(() {
              areas.remove(nombreArea);
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );
}

 List<Widget> _buildCarruselesDeTareas() {
  final List<Widget> carruseles = [];

  final areasOrdenadas = areas.keys.toList()..sort();

  for (final area in areasOrdenadas) {
    if (areaSeleccionada == null || areaSeleccionada == area) {
      final tareasDelArea = tareas.where((t) => !t.completado && t.area == area).toList();
      if (tareasDelArea.isEmpty) continue;

      carruseles.addAll([
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12),
          child: Text("Área: $area", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: tareasDelArea.map((t) => SizedBox(width: 240, child: _buildTareaCard(t))).toList(),
          ),
        ),
      ]);
    }
  }

  // Tareas sin área o en área "General"
  final tareasGenerales = tareas.where((t) =>
    !t.completado &&
    (t.area == "General" || !areas.keys.contains(t.area))
  ).toList();

  if ((areaSeleccionada == null || areaSeleccionada == "General") && tareasGenerales.isNotEmpty) {
    carruseles.addAll([
      const Padding(
        padding: EdgeInsets.only(left: 16, top: 12),
        child: Text("Área: General", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 180,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: tareasGenerales.map((t) => SizedBox(width: 240, child: _buildTareaCard(t))).toList(),
        ),
      ),
    ]);
  }

  return carruseles;
}

 Widget _buildGrupoHorizontal(String nombreArea) {
  final tareasFiltradas = tareas
      .where((t) => !t.completado && t.area.trim() == nombreArea.trim())
      .toList();

  // 🧠 Debug temporal: puedes eliminar esto luego
  for (var t in tareasFiltradas) {
    debugPrint("✅ Mostrando tarea '${t.titulo}' en área: '${t.area}'");
  }

  if (tareasFiltradas.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 12),
        child: Text(
          "Área: $nombreArea",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 220, // 🔧 Altura corregida para evitar desbordes
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tareasFiltradas.length,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            return SizedBox(
          width: 260,
          child: GestureDetector(
            onTap: () => _mostrarDialogoDetalleTarea(tareasFiltradas[index]),
            child: _buildTareaCardCompacta(tareasFiltradas[index]),
          ),
        );
          },
        ),
      ),
    ],
  );
}

Widget _buildTareaCardCompacta(Tarea tarea) {
  final responsablesNombres = tarea.responsables
      .map((id) => nombreResponsables[id] ?? "-usuario-")
      .take(2)
      .join(", ") +
      (tarea.responsables.length > 2 ? "..." : "");

  final Color colorIndicador = tarea.responsables.isNotEmpty
      ? _colorDesdeUID(tarea.responsables.first)
      : Colors.grey;

  return GestureDetector(
    onTap: () => _mostrarDialogoDetalleTarea(tarea),
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: tarea.completado ? Colors.green[50] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tarea.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Chip(
                  label: Text(tarea.tipoTarea),
                  backgroundColor: Colors.black,
                  labelStyle: const TextStyle(color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 6),
                if (tarea.dificultad != null)
                  Chip(
                    label: Text("Dif: ${tarea.dificultad}"),
                    backgroundColor: Colors.black54,
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                  )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "👤 $responsablesNombres",
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

void _mostrarDialogoDetalleTarea(Tarea tarea) {
  final responsablesNombres = tarea.responsables
      .map((id) => nombreResponsables[id] ?? "-usuario-")
      .join(", ");

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        title: Text(tarea.titulo, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tarea.descripcion?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(tarea.descripcion!, style: const TextStyle(color: Colors.white70)),
                ),
              Wrap(
                spacing: 6,
                children: [
                  Chip(
                    label: Text("Tipo: ${tarea.tipoTarea}"),
                    backgroundColor: Colors.deepPurple,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  if (tarea.dificultad != null)
                    Chip(
                      label: Text("Dificultad: ${tarea.dificultad}"),
                      backgroundColor: Colors.blueGrey,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  Chip(
                    label: Text(tarea.completado ? "✅ Completada" : "⏳ Pendiente"),
                    backgroundColor: tarea.completado ? Colors.green : Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("👥 Responsables:\n$responsablesNombres", style: const TextStyle(color: Colors.white70)),
              if (tarea.requisitos.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("🎯 Habilidades requeridas:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ...tarea.requisitos.entries.map((e) =>
                    Text("• ${e.key}: ${e.value}", style: const TextStyle(color: Colors.white70))),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar", style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            tooltip: "Editar",
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoEditarTareaNueva(tarea); // 👈 tu función existente
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Eliminar",
            onPressed: () {
              Navigator.pop(context);
              _confirmarEliminarTareaDesdeDialogo(tarea); // 👈 nueva función abajo
            },
          ),
        ],
      );
    },
  );
}
void _mostrarDialogoEditarTareaNueva(Tarea tarea) {
  showDialog(
    context: context,
    builder: (context) {
      bool cargando = false;

      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                      cargando
                        ? Center(
                            child: Image.asset(
                              'assets/animation.gif',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          )
                        : TareaFormWidget(
                            tareaInicial: tarea,
                            areas: areas,
                            participantes: participantes,
                            onSubmit: (tareaEditada) async {
                              setStateDialog(() => cargando = true);
                              await _editarTarea(tarea, tareaEditada);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ Tarea actualizada")),
                                );
                              }
                            },
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
            ),
          );
        },
      );
    },
  );
}


void _confirmarEliminarTareaDesdeDialogo(Tarea tarea) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
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
            await Future.delayed(const Duration(milliseconds: 100));
            late BuildContext loaderContext;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                loaderContext = ctx;
                return Center(
                  child: Image.asset(
                    'assets/animation.gif',
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                );
              },
            );
            await _eliminarTarea(tarea); // ✅ ya la tienes
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
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Color.fromARGB(255, 26, 21, 21)),
          title: const Text(
            "Detalle del Proyecto",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 18, 88, 153),
          elevation: 0,
          actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.account_tree,
                      color: Colors.white, // Color blanco asegurado
                      size: 28, // Aumenta el tamaño si quieres mayor visibilidad
                    ),
                    tooltip: "Visualizar flujo de tareas del proyecto",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GrafoTareasPage(
                      tareas: tareas,
                      nombreResponsables: nombreResponsables,
                    ),
                  ),
                );
              },

                  ),
        ],

        ),

      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),

          loading
            ? Center(
                child: Image.asset('assets/animation.gif', width: 150),
              )
              : Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildParticipantesSection(),
                    _buildAreasSection(),
                    _buildFiltroAreas(), 
                    Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        for (final area in (areas.keys.toList()..sort()))
                          if (areaSeleccionada == null || areaSeleccionada == area)
                            _buildGrupoHorizontal(area),

                        if ((areaSeleccionada == null || areaSeleccionada == "General") &&
                            !areas.keys.contains("General"))
                          _buildGrupoHorizontal("General"),
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
