import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/TareaFormWidget.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ReunionPresencialPage.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/grafo_tareas_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/grafo_tareas_pmi_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/asignacion_inteligente_service.dart';

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
  final AsignacionInteligenteService _asignacionService = AsignacionInteligenteService();

  List<Tarea> tareas = [];
  Map<String, String> nombreResponsables = {};
  List<Map<String, String>> participantes = [];
  bool loading = true;
  bool participantesExpandido = true;
  bool mostrarPendientes = true;
  Map<String, List<String>> areas = {};
  String? areaSeleccionada; // null = ver todas

  // ========================================
  //  Variables para Proyectos PMI
  // ========================================
  String? faseSeleccionada; // null = ver todas las fases
  Map<String, List<String>> recursos = {}; // Recursos del proyecto (reemplazo de areas para PMI)


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
    setState(() {
      loading = false;
      areas = _mergeAreasWithTaskAreas(areas);
    });
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
      areas = _mergeAreasWithTaskAreas(fetchedAreas);
    });
  }
}

  Map<String, List<String>> _mergeAreasWithTaskAreas(Map<String, List<String>> base) {
    final updated = Map<String, List<String>>.from(base);
    final derived = <String>{};
    for (final tarea in tareas) {
      final nombre = tarea.area.isNotEmpty ? tarea.area : "General";
      derived.add(nombre);
    }
    if (derived.isEmpty) derived.add("General");
    for (final area in derived) {
      updated.putIfAbsent(area, () => []);
    }
    return updated;
  }

  List<String> _obtenerAreasDisponibles() {
    final set = <String>{};
    set.addAll(areas.keys);
    for (final tarea in tareas) {
      final nombre = tarea.area.isNotEmpty ? tarea.area : "General";
      set.add(nombre);
    }
    if (set.isEmpty) set.add("General");
    final list = set.toList();
    list.sort();
    return list;
  }

  List<String> _extractStringList(dynamic source) {
    if (source is List) {
      return source
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (source is String && source.isNotEmpty) {
      return [source];
    }
    return [];
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
                                    const SnackBar(content: Text("a Tarea agregada")),
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
  final List<String> nombresAreas = _obtenerAreasDisponibles();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Text("Filtrar por Area:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          dropdownColor: Colors.black,
          value: areaSeleccionada ?? "Todas",  // a si es null, usa "Todas"
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          items: [
            const DropdownMenuItem<String>(
              value: "Todas",
              child: Text("Todas las Areas", style: TextStyle(color: Colors.white)),
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
              debugPrint("  Area seleccionada: $areaSeleccionada");
            });
          },
        ),
      ],
    ),
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

  Widget _buildBlueprintSummary(Proyecto proyecto) {
    final blueprint = proyecto.blueprintIA;
    if (blueprint == null || blueprint.isEmpty) return const SizedBox.shrink();

    final resumen = blueprint['resumenEjecutivo'] ?? proyecto.descripcion;
    final objetivos = _extractStringList(blueprint['objetivosSMART']);
    final backlog = (blueprint['backlogInicial'] as List?) ?? [];
    final hitos = (blueprint['hitosPrincipales'] as List?) ?? [];
    final previewTareas = backlog
        .whereType<Map>()
        .map((e) => (e['nombre'] ?? e['titulo'] ?? '') as String)
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blueprint IA',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (resumen != null && resumen.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                resumen,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildBlueprintStat('Objetivos', objetivos.length),
                _buildBlueprintStat('Backlog', backlog.length),
                _buildBlueprintStat('Hitos', hitos.length),
              ],
            ),
            if (objetivos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Objetivos SMART', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 4),
              ...objetivos.take(3).map(
                (o) => Text('a $o', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
            if (previewTareas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Primeras tareas sugeridas', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: previewTareas
                    .map((t) => Chip(
                          label: Text(t),
                          labelStyle: const TextStyle(fontSize: 12),
                          backgroundColor: Colors.blueGrey.shade700,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
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
        titulo: "Crear Nueva Area",
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
        titulo: "Editar Area: $nombreArea",
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
  Function()? onEliminar, // nuevo parAmetro opcional
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
                decoration: const InputDecoration(labelText: "Nombre del Area"),
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

// ========================================
//  SECCIAN: FASES PMI
// ========================================
Widget _buildFasesPMISection() {
  // Contar tareas por fase
  final Map<String, int> tareasPorFase = {};
  final Map<String, int> completadasPorFase = {};

  for (var tarea in tareas) {
    final fase = tarea.fasePMI ?? 'Sin fase';
    tareasPorFase[fase] = (tareasPorFase[fase] ?? 0) + 1;
    if (tarea.completado) {
      completadasPorFase[fase] = (completadasPorFase[fase] ?? 0) + 1;
    }
  }

  final fases = ['IniciaciA3n', 'PlanificaciA3n', 'EjecuciA3n', 'Monitoreo y Control', 'Cierre'];
  final coloresFases = {
    'IniciaciA3n': const Color(0xFF4CAF50),
    'PlanificaciA3n': const Color(0xFF2196F3),
    'EjecuciA3n': const Color(0xFFFF9800),
    'Monitoreo y Control': const Color(0xFF9C27B0),
    'Cierre': const Color(0xFF607D8B),
  };

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_tree, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "Fases PMI del Proyecto",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fases.map((fase) {
            final totalTareas = tareasPorFase[fase] ?? 0;
            final completadas = completadasPorFase[fase] ?? 0;
            final color = coloresFases[fase] ?? Colors.grey;
            final isSelected = faseSeleccionada == fase;

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fase,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (totalTareas > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$completadas/$totalTareas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.grey.shade900,
              selectedColor: color,
              checkmarkColor: Colors.white,
              side: BorderSide(color: color, width: 1),
              onSelected: (selected) {
                setState(() {
                  faseSeleccionada = selected ? fase : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ========================================
//  CONTENIDO PRINCIPAL PMI
// ========================================
Widget _buildContenidoPMI() {
  // Agrupar tareas por Fase a Entregable a Paquete
  final Map<String, Map<String, Map<String, List<Tarea>>>> jerarquia = {};

  for (var tarea in tareas) {
    // Aplicar filtro por fase si estA seleccionada
    if (faseSeleccionada != null && tarea.fasePMI != faseSeleccionada) {
      continue;
    }

    final fase = tarea.fasePMI ?? 'Sin fase';
    final entregable = tarea.entregable ?? 'Sin entregable';
    final paquete = tarea.paqueteTrabajo ?? 'Sin paquete';

    jerarquia.putIfAbsent(fase, () => {});
    jerarquia[fase]!.putIfAbsent(entregable, () => {});
    jerarquia[fase]![entregable]!.putIfAbsent(paquete, () => []);
    jerarquia[fase]![entregable]![paquete]!.add(tarea);
  }

  // Ordenar fases segAon orden PMI
  final fasesOrdenadas = _ordenarFasesPMI(jerarquia.keys.toList());

  if (fasesOrdenadas.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay tareas para mostrar',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
    children: fasesOrdenadas.map((fase) {
      final colorFase = _obtenerColorFasePMI(fase);
      final entregables = jerarquia[fase]!;

      return _buildFaseCardPMI(fase, entregables, colorFase);
    }).toList(),
  );
}

Widget _buildFaseCardPMI(
  String nombreFase,
  Map<String, Map<String, List<Tarea>>> entregables,
  Color colorFase,
) {
  int totalTareas = 0;
  int tareasCompletadas = 0;

  entregables.forEach((_, paquetes) {
    paquetes.forEach((_, tareas) {
      totalTareas += tareas.length;
      tareasCompletadas += tareas.where((t) => t.completado).length;
    });
  });

  final progreso = totalTareas > 0 ? tareasCompletadas / totalTareas : 0.0;

  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.grey.shade900,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colorFase, width: 2),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.all(16),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorFase.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorFase, width: 2),
        ),
        child: Icon(_obtenerIconoFasePMI(nombreFase), color: colorFase),
      ),
      title: Text(
        nombreFase,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '$tareasCompletadas/$totalTareas tareas completadas',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(colorFase),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
      children: entregables.entries.map((entregableEntry) {
        return _buildEntregableSectionPMI(
          entregableEntry.key,
          entregableEntry.value,
          colorFase,
        );
      }).toList(),
    ),
  );
}

Widget _buildEntregableSectionPMI(
  String nombreEntregable,
  Map<String, List<Tarea>> paquetes,
  Color colorFase,
) {
  return Container(
    margin: const EdgeInsets.only(top: 12, bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorFase.withValues(alpha: 0.3), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: colorFase, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ' $nombreEntregable',
                style: TextStyle(
                  color: colorFase,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...paquetes.entries.map((paqueteEntry) {
          return _buildPaqueteTrabajoSectionPMI(
            paqueteEntry.key,
            paqueteEntry.value,
            colorFase,
          );
        }),
      ],
    ),
  );
}

Widget _buildPaqueteTrabajoSectionPMI(
  String nombrePaquete,
  List<Tarea> tareas,
  Color colorFase,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade800.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_open, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nombrePaquete,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorFase.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tareas.length} tareas',
                style: TextStyle(
                  color: colorFase,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tareas.map((tarea) => _buildTareaItemPMI(tarea, colorFase)),
      ],
    ),
  );
}

Widget _buildTareaItemPMI(Tarea tarea, Color colorFase) {
  final tieneResponsables = tarea.responsables.isNotEmpty;
  final tieneHabilidades = tarea.habilidadesRequeridas.isNotEmpty;

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: tarea.completado
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : Colors.grey.shade900,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: tarea.completado ? Colors.green : Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                // Marcar como completada/pendiente
                await _firestore
                    .collection('proyectos')
                    .doc(widget.proyectoId)
                    .update({
                  'tareas': tareas.map((t) {
                    if (t.titulo == tarea.titulo) {
                      t.completado = !t.completado;
                    }
                    return t.toJson();
                  }).toList(),
                });
                setState(() {
                  tarea.completado = !tarea.completado;
                });
              },
              child: Icon(
                tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: tarea.completado ? Colors.green : Colors.white54,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _mostrarDialogoDetalleTareaPMI(tarea),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.titulo,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: tarea.completado
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (tarea.area != 'Sin asignar' && tarea.area != 'General')
                          _buildChipPMI(' ${tarea.area}', Colors.blue.shade700),
                        if (tarea.dificultad != null)
                          _buildChipPMI('  ${tarea.dificultad}', Colors.purple.shade700),
                        _buildChipPMI('ai  ${tarea.duracion} min', Colors.indigo.shade700),
                        if (tarea.prioridad >= 4)
                          _buildChipPMI(' Alta prioridad', Colors.red.shade700),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botones de acciA3n
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BotA3n de editar
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                  tooltip: 'Editar tarea',
                  onPressed: () => _mostrarDialogoEditarTareaNueva(tarea),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // BotA3n de asignaciA3n inteligente (solo si no tiene responsables)
                if (!tieneResponsables && tieneHabilidades)
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 18),
                    tooltip: 'Asignar inteligentemente',
                    onPressed: () => _mostrarDialogoAsignacionInteligente(tarea),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
        // Mostrar responsables asignados con justificaciA3n
        if (tieneResponsables) ...[
          const SizedBox(height: 8),
          ...tarea.responsables.map((uid) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _obtenerJustificacionAsignacion(tarea, uid),
              builder: (context, snapshot) {
                final justificacion = snapshot.data;
                final nombre = nombreResponsables[uid] ?? 'Usuario';

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (justificacion != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getScoreColor(justificacion['matchScore']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${justificacion['matchScore']}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (justificacion != null && justificacion['habilidadesCoincidentes'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (justificacion['habilidadesCoincidentes'] as List<String>)
                              .map((hab) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'a $hab',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ],
    ),
  );
}

Color _getScoreColor(int score) {
  if (score >= 80) return Colors.green;
  if (score >= 60) return Colors.orange;
  return Colors.red;
}

Future<Map<String, dynamic>?> _obtenerJustificacionAsignacion(Tarea tarea, String uid) async {
  if (tarea.habilidadesRequeridas.isEmpty) return null;

  try {
    // Obtener habilidades del usuario
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final habilidadesUsuario = Map<String, int>.from(userDoc.data()!['habilidades'] ?? {});

    // Calcular compatibilidad
    List<String> habilidadesCoincidentes = [];
    int sumaNiveles = 0;
    int coincidencias = 0;

    for (String habilidadRequerida in tarea.habilidadesRequeridas) {
      final habilidadKey = habilidadesUsuario.keys.firstWhere(
        (key) => key.toLowerCase().trim() == habilidadRequerida.toLowerCase().trim() ||
                 key.toLowerCase().contains(habilidadRequerida.toLowerCase()) ||
                 habilidadRequerida.toLowerCase().contains(key.toLowerCase()),
        orElse: () => '',
      );

      if (habilidadKey.isNotEmpty) {
        final nivel = habilidadesUsuario[habilidadKey]!;
        habilidadesCoincidentes.add(habilidadKey);
        sumaNiveles += nivel;
        coincidencias++;
      }
    }

    if (coincidencias == 0) return null;

    final nivelPromedio = sumaNiveles / coincidencias;
    final porcentajeCoincidencia = (coincidencias / tarea.habilidadesRequeridas.length) * 100;
    final matchScore = (porcentajeCoincidencia * 0.7 + (nivelPromedio / 5 * 100) * 0.3).round();

    return {
      'matchScore': matchScore,
      'habilidadesCoincidentes': habilidadesCoincidentes,
      'nivelPromedio': nivelPromedio,
    };
  } catch (e) {
    return null;
  }
}

Widget _buildChipPMI(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ========================================
//  UTILIDADES PMI
// ========================================

List<String> _ordenarFasesPMI(List<String> fases) {
  final orden = {
    'IniciaciA3n': 1,
    'PlanificaciA3n': 2,
    'EjecuciA3n': 3,
    'Monitoreo y Control': 4,
    'Monitoreo': 4,
    'Cierre': 5,
  };

  fases.sort((a, b) {
    final ordenA = orden[a] ?? 999;
    final ordenB = orden[b] ?? 999;
    return ordenA.compareTo(ordenB);
  });

  return fases;
}

Color _obtenerColorFasePMI(String fase) {
  switch (fase) {
    case 'IniciaciA3n':
      return const Color(0xFF4CAF50);
    case 'PlanificaciA3n':
      return const Color(0xFF2196F3);
    case 'EjecuciA3n':
      return const Color(0xFFFF9800);
    case 'Monitoreo y Control':
    case 'Monitoreo':
      return const Color(0xFF9C27B0);
    case 'Cierre':
      return const Color(0xFF607D8B);
    default:
      return const Color(0xFF757575);
  }
}

IconData _obtenerIconoFasePMI(String fase) {
  switch (fase) {
    case 'IniciaciA3n':
      return Icons.flag;
    case 'PlanificaciA3n':
      return Icons.edit_calendar;
    case 'EjecuciA3n':
      return Icons.build;
    case 'Monitoreo y Control':
    case 'Monitoreo':
      return Icons.monitor_heart;
    case 'Cierre':
      return Icons.check_circle;
    default:
      return Icons.work;
  }
}

Color _colorPorTipoContextual(String? tipo) {
  switch ((tipo ?? '').toLowerCase()) {
    case 'descubrimiento':
      return Colors.lightBlueAccent.shade200;
    case 'ejecucion':
    case 'ejecuciA3n':
      return Colors.tealAccent.shade200;
    case 'seguimiento':
      return Colors.amberAccent.shade200;
    default:
      return Colors.blueGrey.shade200;
  }
}

// ========================================
//  SECCIAN: RECURSOS (reemplaza Areas para PMI)
// ========================================
Widget _buildRecursosSection() {
  // Construir mapa de recursos desde las tareas
  final Map<String, List<String>> recursosPorArea = {};

  for (var tarea in tareas) {
    final recurso = tarea.area;
    if (recurso != 'General' && recurso != 'Sin asignar') {
      if (!recursosPorArea.containsKey(recurso)) {
        recursosPorArea[recurso] = [];
      }
    }
  }

  return ExpansionTile(
    title: const Row(
      children: [
        Icon(Icons.group, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          "Recursos del Proyecto",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    ),
    backgroundColor: Colors.white10,
    collapsedIconColor: Colors.white,
    iconColor: Colors.white,
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    children: [
      SizedBox(
        height: 300,
        child: recursosPorArea.isEmpty
            ? const Center(
                child: Text(
                  'No hay recursos asignados aAon',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: recursosPorArea.length,
                itemBuilder: (context, index) {
                  final recurso = recursosPorArea.keys.elementAt(index);
                  final tareasRecurso = tareas.where((t) => t.area == recurso).length;
                  final completadas = tareas
                      .where((t) => t.area == recurso && t.completado)
                      .length;

                  return Card(
                    color: Colors.blueGrey.shade800,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        recurso,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        ' $completadas/$tareasRecurso tareas completadas',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: CircularProgressIndicator(
                        value: tareasRecurso > 0 ? completadas / tareasRecurso : 0,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  );
                },
              ),
      ),
    ],
  );
}


Widget _buildAreasSection() {
  return ExpansionTile(
    title: const Text(
      "Areas del Proyecto",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    backgroundColor: Colors.white10,
    collapsedIconColor: Colors.white,
    iconColor: Colors.white,
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    children: [
      SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: _obtenerAreasDisponibles().length,
          itemBuilder: (context, index) {
            final area = _obtenerAreasDisponibles()[index];
            final miembrosUID = areas[area] ?? [];
            final miembros = miembrosUID.map((uid) {
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
                subtitle: Text(
                  miembros.isEmpty ? "Sin integrantes asignados" : "Participantes: " + miembros,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _mostrarDialogoEditarArea(area, miembrosUID),
                      tooltip: "Editar Area",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarEliminarArea(area),
                      tooltip: "Eliminar Area",
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
        label: const Text("Agregar Area"),
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
      title: const Text("AEliminar Area?"),
      content: Text("AEstAs seguro de que deseas eliminar el Area \"$nombreArea\"? Esta acciA3n no se puede deshacer."),
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

Widget _buildGrupoHorizontal(String area) {
  final tareasDelArea = tareas.where((t) => t.area == area).toList();
  final pendientes = tareasDelArea.where((t) => !t.completado).toList();
  final completadas = tareasDelArea.where((t) => t.completado).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          area,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      if (pendientes.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Pendientes', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            ...pendientes.map(_buildTareaCardContextual).toList(),
          ],
        ),
      if (completadas.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 16),
              child: Text('Completadas', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            ...completadas.map(_buildTareaCardContextual).toList(),
          ],
        ),
    ],
  );
}


Future<void> _actualizarHabilidades(String uid, Map<String, int> requisitos, String tituloTarea) async {
  final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
  final doc = await userRef.get();
  if (!doc.exists) return;

  final data = doc.data()!;
  Map<String, int> habilidades = Map<String, int>.from(data["habilidades"] ?? {});
  int puntosTotales = data["puntosTotales"] ?? 0;

  requisitos.forEach((clave, valor) {
    habilidades[clave] = (habilidades[clave] ?? 0) + valor;
    puntosTotales += valor;
  });

  await userRef.update({
    "habilidades": habilidades,
    "puntosTotales": puntosTotales,
    "tareasHechas": FieldValue.arrayUnion([tituloTarea]),
  });
}


Future<void> _actualizarEstadoTarea(Tarea tarea) async {
  final docRef = FirebaseFirestore.instance.collection("proyectos").doc(widget.proyectoId);
  final doc = await docRef.get();

  if (!doc.exists) return;
  final data = doc.data()!;
  final tareasJson = List<Map<String, dynamic>>.from(data["tareas"] ?? []);

  // Encuentra y actualiza la tarea
  for (var t in tareasJson) {
    if (t["titulo"] == tarea.titulo) {
      t["completado"] = tarea.completado;
      break;
    }
  }

  await docRef.update({"tareas": tareasJson});

  // a Si fue completada, actualiza habilidades
  if (tarea.completado) {
    for (final uid in tarea.responsables) {
      await _actualizarHabilidades(uid, tarea.requisitos, tarea.titulo);

    }
  }
}

Widget _buildTareaCardContextual(Tarea tarea) {
  final bool tieneResponsables = tarea.responsables.isNotEmpty;
  final bool tieneHabilidades = tarea.habilidadesRequeridas.isNotEmpty;
  final Color color = _colorPorTipoContextual(tarea.tipoTarea);

  final responsablesNombres = tarea.responsables
      .map((id) => nombreResponsables[id] ?? '-usuario-')
      .take(2)
      .join(', ') + (tarea.responsables.length > 2 ? '...' : '');

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tarea.completado
          ? Colors.green.shade900.withValues(alpha: 0.25)
          : Colors.grey.shade900.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: tarea.completado ? Colors.green : color.withValues(alpha: 0.4),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                tarea.completado = !tarea.completado;
                setState(() {});
                await _actualizarEstadoTarea(tarea);
              },
              child: Icon(
                tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: tarea.completado ? Colors.greenAccent : Colors.white54,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _mostrarDialogoDetalleTarea(tarea),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.titulo,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: tarea.completado
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChipPMI(tarea.tipoTarea, color),
                        if (tarea.dificultad != null)
                          _buildChipPMI('Nivel ${tarea.dificultad}', Colors.purple.shade600),
                        if (tarea.area.isNotEmpty)
                          _buildChipPMI(tarea.area, Colors.blueGrey.shade700),
                        _buildChipPMI('${tarea.duracion} min', Colors.deepOrange.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                  tooltip: 'Editar tarea',
                  onPressed: () => _mostrarDialogoEditarTareaNueva(tarea),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                if (!tieneResponsables && tieneHabilidades)
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 18),
                    tooltip: 'Asignar inteligentemente',
                    onPressed: () => _mostrarDialogoAsignacionInteligente(tarea),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tieneResponsables
              ? 'Responsables: $responsablesNombres'
              : 'Sin responsables asignados',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (tarea.descripcion?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            tarea.descripcion!,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ],
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
                    label: Text(tarea.completado ? "a Completada" : "a3 Pendiente"),
                    backgroundColor: tarea.completado ? Colors.green : Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(" Responsables:\n$responsablesNombres", style: const TextStyle(color: Colors.white70)),
              if (tarea.requisitos.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("  Habilidades requeridas:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ...tarea.requisitos.entries.map((e) =>
                    Text("a ${e.key}: ${e.value}", style: const TextStyle(color: Colors.white70))),
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
              _mostrarDialogoEditarTareaNueva(tarea); //  tu funciA3n existente
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Eliminar",
            onPressed: () {
              Navigator.pop(context);
              _confirmarEliminarTareaDesdeDialogo(tarea); //  nueva funciA3n abajo
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
                                  const SnackBar(content: Text("a Tarea actualizada")),
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
      title: const Text("AEliminar tarea?"),
      content: const Text("Esta acciA3n no se puede deshacer."),
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
            await _eliminarTarea(tarea); // a ya la tienes
            Navigator.of(loaderContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("a Tarea eliminada")),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );
}

// ========================================
//  DIALOGO DE DETALLE PARA TAREAS PMI
// ========================================

void _mostrarDialogoDetalleTareaPMI(Tarea tarea) {
  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerJustificacionesTodosResponsables(tarea),
        builder: (context, snapshot) {
          final justificaciones = snapshot.data ?? [];

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _obtenerColorFasePMI(tarea.fasePMI ?? ''),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Detalle de Tarea PMI',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TAtulo de la tarea
                  Text(
                    tarea.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // JerarquAa PMI
                  _buildDetalleSeccion(
                    'JerarquAa PMI',
                    Icons.account_tree,
                    Colors.blue,
                    [
                      if (tarea.fasePMI != null)
                        _buildDetalleItem('Fase', tarea.fasePMI!),
                      if (tarea.entregable != null)
                        _buildDetalleItem('Entregable', tarea.entregable!),
                      if (tarea.paqueteTrabajo != null)
                        _buildDetalleItem('Paquete de Trabajo', tarea.paqueteTrabajo!),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),

                  // DescripciA3n
                  if (tarea.descripcion?.isNotEmpty == true) ...[
                    _buildDetalleSeccion(
                      'DescripciA3n',
                      Icons.description,
                      Colors.purple,
                      [
                        Text(
                          tarea.descripcion!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                  ],

                  // InformaciA3n general
                  _buildDetalleSeccion(
                    'InformaciA3n General',
                    Icons.info,
                    Colors.orange,
                    [
                      _buildDetalleItem('DuraciA3n', '${tarea.duracion} minutos'),
                      _buildDetalleItem('Prioridad', '${tarea.prioridad}/5'),
                      if (tarea.dificultad != null)
                        _buildDetalleItem('Dificultad', tarea.dificultad!),
                      _buildDetalleItem('Estado', tarea.completado ? 'Completada' : 'Pendiente'),
                      _buildDetalleItem('Recurso recomendado', tarea.area),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),

                  // Habilidades requeridas
                  if (tarea.habilidadesRequeridas.isNotEmpty) ...[
                    _buildDetalleSeccion(
                      'Habilidades Requeridas',
                      Icons.psychology,
                      Colors.indigo,
                      [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tarea.habilidadesRequeridas.map((hab) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hab,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                  ],

                  // Responsables con justificaciA3n
                  if (tarea.responsables.isNotEmpty) ...[
                    _buildDetalleSeccion(
                      'Responsables Asignados',
                      Icons.people,
                      Colors.green,
                      [
                        ...justificaciones.map((just) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade900.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        just['nombre'] ?? 'Usuario',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (just['matchScore'] != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getScoreColor(just['matchScore']),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.stars,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${just['matchScore']}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (just['habilidadesCoincidentes'] != null &&
                                    (just['habilidadesCoincidentes'] as List).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Habilidades que coinciden:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: (just['habilidadesCoincidentes'] as List<String>)
                                        .map((hab) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade700,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'a $hab',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (just['nivelPromedio'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'a Nivel promedio: ${(just['nivelPromedio'] as double).toStringAsFixed(1)}/5',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mostrarDialogoEditarTareaNueva(tarea);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildDetalleSeccion(String titulo, IconData icon, Color color, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...children,
    ],
  );
}

Widget _buildDetalleItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<List<Map<String, dynamic>>> _obtenerJustificacionesTodosResponsables(Tarea tarea) async {
  List<Map<String, dynamic>> resultados = [];

  for (String uid in tarea.responsables) {
    final justificacion = await _obtenerJustificacionAsignacion(tarea, uid);
    resultados.add({
      'uid': uid,
      'nombre': nombreResponsables[uid] ?? 'Usuario',
      ...?justificacion,
    });
  }

  return resultados;
}

// ========================================
//  ASIGNACIAN INTELIGENTE
// ========================================

Future<void> _mostrarDialogoAsignacionInteligente(Tarea tarea) async {
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Image.asset(
        'assets/animation.gif',
        width: 120,
        height: 120,
      ),
    ),
  );

  try {
    // Obtener sugerencias
    final participantesIds = participantes.map((p) => p['uid']!).toList();
    final sugerencias = await _asignacionService.sugerirAsignaciones(
      tarea: tarea,
      participantesIds: participantesIds,
    );

    // Cerrar loading
    if (mounted) Navigator.pop(context);

    if (sugerencias.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('a No se encontraron candidatos con las habilidades requeridas'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Mostrar dialog con sugerencias
    if (mounted) {
      // Variable para rastrear selecciones
      final Set<String> seleccionados = {};

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'AsignaciA3n Inteligente',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarea: ${tarea.titulo}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Habilidades requeridas: ${tarea.habilidadesRequeridas.join(", ")}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Divider(color: Colors.white24, height: 24),
                const Text(
                  'Candidatos sugeridos:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sugerencias.length,
                    itemBuilder: (context, index) {
                      final sugerencia = sugerencias[index];
                      final matchScore = sugerencia['matchScore'] as int;
                      final nombre = sugerencia['nombre'] as String;
                      final habilidadesCoincidentes =
                          sugerencia['habilidadesCoincidentes'] as List<String>;
                      final nivelPromedio = sugerencia['nivelPromedio'] as double;

                      // Color segAon el score
                      Color scoreColor;
                      if (matchScore >= 80) {
                        scoreColor = Colors.green;
                      } else if (matchScore >= 60) {
                        scoreColor = Colors.orange;
                      } else {
                        scoreColor = Colors.red;
                      }

                      return Card(
                        color: Colors.grey.shade800,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scoreColor,
                            child: Text(
                              '$matchScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'a ${habilidadesCoincidentes.length} de ${tarea.habilidadesRequeridas.length} habilidades',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                'a Nivel promedio: ${nivelPromedio.toStringAsFixed(1)}/5',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              if (habilidadesCoincidentes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: habilidadesCoincidentes.take(3).map((hab) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        hab,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _asignarTareaAUsuario(tarea, sugerencia['uid']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scoreColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Asignar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            if (sugerencias.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _asignarTareaAUsuario(tarea, sugerencias.first['uid']);
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-asignar Mejor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
          ),
        );
    }
  } catch (e) {
    // Cerrar loading si estA abierto
    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('a Error al obtener sugerencias: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _asignarTareaAUsuario(Tarea tarea, String uid) async {
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Image.asset(
        'assets/animation.gif',
        width: 120,
        height: 120,
      ),
    ),
  );

  try {
    // Actualizar tarea con el responsable
    final tareaActualizada = Tarea(
      titulo: tarea.titulo,
      fecha: tarea.fecha,
      duracion: tarea.duracion,
      prioridad: tarea.prioridad,
      completado: tarea.completado,
      colorId: tarea.colorId,
      responsables: [uid],
      tipoTarea: 'Asignada',
      requisitos: tarea.requisitos,
      dificultad: tarea.dificultad,
      descripcion: tarea.descripcion,
      tareasPrevias: tarea.tareasPrevias,
      area: tarea.area,
      habilidadesRequeridas: tarea.habilidadesRequeridas,
      fasePMI: tarea.fasePMI,
      entregable: tarea.entregable,
      paqueteTrabajo: tarea.paqueteTrabajo,
    );

    // Actualizar en Firestore
    final tareasActualizadas = tareas.map((t) {
      if (t.titulo == tarea.titulo) {
        return tareaActualizada;
      }
      return t;
    }).toList();

    await _firestore.collection('proyectos').doc(widget.proyectoId).update({
      'tareas': tareasActualizadas.map((t) => t.toJson()).toList(),
    });

    // Recargar tareas
    await _cargarTareas();

    // Cerrar loading
    if (mounted) Navigator.pop(context);

    // Mostrar Axito
    if (mounted) {
      final nombreUsuario = nombreResponsables[uid] ?? 'Usuario';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('a Tarea asignada a $nombreUsuario'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // Cerrar loading
    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('a Error al asignar tarea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _asignarTodasAutomaticamente() async {
  // ConfirmaciA3n
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'AsignaciA3n AutomAtica',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: const Text(
        'ADeseas asignar automAticamente todas las tareas sin responsables basAndose en las habilidades de los participantes?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Asignar Todas'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/animation.gif',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            'Asignando tareas...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  );

  try {
    final participantesIds = participantes.map((p) => p['uid']!).toList();

    // Obtener el propietario del proyecto
    final proyectoDoc = await _firestore.collection('proyectos').doc(widget.proyectoId).get();
    final propietarioId = proyectoDoc.exists ? proyectoDoc.data()!['propietario'] as String? : null;

    final resultado = await _asignacionService.asignarTodasAutomaticamente(
      proyectoId: widget.proyectoId,
      tareas: tareas,
      participantesIds: participantesIds,
      propietarioId: propietarioId, // a Pasar el ID del creador
    );

    // Recargar tareas
    await _cargarTareas();

    // Cerrar loading
    if (mounted) Navigator.pop(context);

    // Mostrar resultados
    if (mounted) {
      final asignadas = resultado['asignadas'] as int;
      final sinCandidatos = resultado['sinCandidatos'] as int;
      final resultados = resultado['resultados'] as List<Map<String, dynamic>>;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'AsignaciA3n Completada',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'a Tareas asignadas: $asignadas',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                if (sinCandidatos > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'a i  Sin candidatos: $sinCandidatos',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
                if (resultados.isNotEmpty) ...[
                  const Divider(color: Colors.white24, height: 24),
                  const Text(
                    'Resumen de asignaciones:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...resultados.take(10).map((r) {
                    final totalAsignados = r['totalAsignados'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'a ${r['tarea']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '  a ${r['asignado']}',
                            style: const TextStyle(color: Colors.green, fontSize: 11),
                          ),
                          Text(
                            '   Score promedio: ${r['matchScore']}% |  $totalAsignados persona${totalAsignados > 1 ? "s" : ""} asignada${totalAsignados > 1 ? "s" : ""}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (resultados.length > 10)
                    Text(
                      '\n... y ${resultados.length - 10} mAs',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Cerrar loading
    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('a Error en asignaciA3n automAtica: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

@override
Widget build(BuildContext context) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection("proyectos").doc(widget.proyectoId).get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final data = snapshot.data!.data() as Map<String, dynamic>;
      final proyecto = Proyecto.fromJson(data);

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color.fromARGB(255, 18, 88, 153),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proyecto.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Inicio: ${DateFormat('dd/MM/yyyy').format(proyecto.fechaInicio)}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (proyecto.fechaFin != null)
                Text(
                  "Fin: ${DateFormat('dd/MM/yyyy').format(proyecto.fechaFin!)}",
                  style: TextStyle(
                    color: proyecto.fechaFin!.isBefore(DateTime.now())
                        ? Colors.redAccent
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_tree, color: Colors.white, size: 28),
              tooltip: "Visualizar flujo de tareas del proyecto",
              onPressed: () {
                // Detectar si es proyecto PMI
                final esPMI = proyecto.esPMI;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => esPMI
                        ? GrafoTareasPMIPage(
                            tareas: tareas,
                            nombreResponsables: nombreResponsables,
                          )
                        : GrafoTareasPage(
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
            Container(color: Colors.black),
            loading
                ? Center(child: Image.asset('assets/animation.gif', width: 150))
                : Column(
                    children: [
                      const SizedBox(height: 80),
                      _buildParticipantesSection(),
                      if (!proyecto.esPMI) _buildBlueprintSummary(proyecto),

                      // ========================================
                      //  CONDICIONAL: PMI vs Normal
                      // ========================================
                      if (proyecto.esPMI) ...[
                        // Vista PMI
                        _buildFasesPMISection(),
                        _buildRecursosSection(),
                        Expanded(child: _buildContenidoPMI()),
                      ] else ...[
                        // Vista Normal
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
                    ],
                  ),
          ],
        ),
        floatingActionButton: _buildFloatingButtons(proyecto),
      );
    },
  );
}
Widget _buildFloatingButtons(Proyecto proyecto) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      FloatingActionButton.extended(
        heroTag: "autoAsignarBtn",
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("Auto-asignar", style: TextStyle(color: Colors.white)),
        onPressed: _asignarTodasAutomaticamente,
      ),
      const SizedBox(height: 10),
      FloatingActionButton.extended(
        heroTag: "reunionBtn",
        backgroundColor: Colors.black,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text("ReuniA3n", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReunionPresencialPage(proyecto: proyecto),
            ),
          );
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
  );
}

}
