import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

class ResumenYGeneracionTareasPage extends StatefulWidget {
  final String texto;
  final Proyecto proyecto;

  const ResumenYGeneracionTareasPage({super.key, required this.texto, required this.proyecto});

  @override
  State<ResumenYGeneracionTareasPage> createState() => _ResumenYGeneracionTareasPageState();
}

class _ResumenYGeneracionTareasPageState extends State<ResumenYGeneracionTareasPage> {
  late String resumen;
  late List<Map<String, dynamic>> tareasGeneradas;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _cargandoIA = true;
  bool _errorIA = false;
  List<Map<String, String>> participantes = [];
  bool _mostrarChips = true;
  bool _mostrarResumen = true;
  bool _mostrarBlueprint = true;

  @override
  void initState() {
    super.initState();
    _procesarConIA(widget.texto);
  }

  Future<void> _procesarConIA(String texto) async {
    try {
      participantes = await _obtenerParticipantes();
      final habilidadesPorUID = await _obtenerHabilidadesPorUID();

      final callable = FirebaseFunctions.instance.httpsCallable("procesarReunion");
      final result = await callable.call({
        "texto": texto,
        "participantes": participantes,
        "habilidadesPorUID": habilidadesPorUID,
      });

      if (result.data != null &&
          result.data["error"] == null &&
          result.data["resumen"] != null &&
          result.data["tareas"] != null) {
        setState(() {
          resumen = result.data["resumen"];
          tareasGeneradas = List<Map<String, dynamic>>.from(result.data["tareas"]);
          for (var tarea in tareasGeneradas) {
            tarea["responsable"] ??= null;
            DateTime fecha = DateTime.tryParse(tarea["fecha"].toString()) ?? DateTime.now();
            if (fecha.isBefore(DateTime.now())) {
              fecha = DateTime.now().add(const Duration(days: 3));
            }
            tarea["fecha"] = fecha;
          }
          _cargandoIA = false;
          _errorIA = false;
        });
      } else {
        throw Exception("Respuesta inválida de la IA");
      }
    } catch (e) {
      setState(() {
        resumen = "Ocurrió un error al procesar la reunión con la IA.";
        tareasGeneradas = [];
        _cargandoIA = false;
        _errorIA = true;
      });
    }
  }

  Future<Map<String, List<String>>> _obtenerHabilidadesPorUID() async {
    final Map<String, List<String>> habilidades = {};
    for (String uid in widget.proyecto.participantes) {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists && doc.data()?["habilidades"] != null) {
        final raw = doc.data()!["habilidades"];
        if (raw is Map) {
          habilidades[uid] = List<String>.from(raw.keys);
        } else if (raw is List) {
          habilidades[uid] = List<String>.from(raw);
        } else {
          habilidades[uid] = [];
        }
      }
    }
    return habilidades;
  }

  Future<List<Map<String, String>>> _obtenerParticipantes() async {
    List<Map<String, String>> lista = [];
    for (String uid in widget.proyecto.participantes) {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        lista.add({"uid": uid, "nombre": doc["full_name"] ?? "Usuario"});
      }
    }
    return lista;
  }

  Future<void> _guardarTareas() async {
    final List<Tarea> tareasFinales = tareasGeneradas
        .map(
          (t) => Tarea(
            titulo: t["titulo"],
            fecha: t["fecha"],
            duracion: 0,
            colorId: 1,
            responsables: t["responsable"] != null ? [t["responsable"]] : [],
            tipoTarea: "Automática",
          ),
        )
        .toList();

    await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
      "tareas": FieldValue.arrayUnion(tareasFinales.map((t) => t.toJson()).toList()),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tareas guardadas exitosamente")),
      );
      Navigator.pop(context);
    }
  }

  void _asignarAMi() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (var tarea in tareasGeneradas) {
      tarea["responsable"] = uid;
    }
    setState(() {});
  }

  void _cambiarFecha(int index, DateTime nuevaFecha) {
    setState(() {
      tareasGeneradas[index]["fecha"] = nuevaFecha;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050915),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Resumen y Tareas IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _cargandoIA
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  if (widget.proyecto.blueprintIA != null) _buildBlueprintCard(),
                  if (widget.proyecto.blueprintIA != null) const SizedBox(height: 16),
                  _headerRow(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: tareasGeneradas.isEmpty
                        ? const Center(child: Text("No se generaron tareas", style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: tareasGeneradas.length,
                            itemBuilder: (context, index) => _taskCard(index),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _actionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Resumen",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(_mostrarResumen ? Icons.unfold_less : Icons.unfold_more, color: Colors.white70),
                tooltip: _mostrarResumen ? "Ocultar resumen" : "Mostrar resumen",
                onPressed: () => setState(() => _mostrarResumen = !_mostrarResumen),
              ),
              IconButton(
                icon: Icon(_mostrarChips ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                tooltip: _mostrarChips ? "Ocultar chips" : "Mostrar chips",
                onPressed: () => setState(() => _mostrarChips = !_mostrarChips),
              ),
            ],
          ),
          if (_mostrarChips) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip("Proyecto: ${widget.proyecto.nombre}", Colors.cyanAccent),
                _chip(_errorIA ? "Error IA" : "Listo IA", _errorIA ? Colors.pinkAccent : Colors.greenAccent),
                _chip("Participantes: ${participantes.length}", Colors.amberAccent),
              ],
            ),
          ],
          if (_mostrarResumen) ...[
            const SizedBox(height: 10),
            Text(resumen, style: const TextStyle(color: Colors.white70, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        const Expanded(
          child: Text("Tareas generadas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        TextButton.icon(
          onPressed: _asignarAMi,
          icon: const Icon(Icons.person_add_alt_1, color: Colors.cyanAccent),
          label: const Text("Asignar a mí", style: TextStyle(color: Colors.cyanAccent)),
        ),
      ],
    );
  }

  Widget _taskCard(int index) {
    final tarea = tareasGeneradas[index];
    final responsablesDropdown = participantes
        .map((usuario) => DropdownMenuItem<String>(
              value: usuario["uid"],
              child: Text(usuario["nombre"]!),
            ))
        .toList();

    final uidResponsable = tarea["responsable"];
    final currentResponsable = participantes.any((p) => p["uid"] == uidResponsable) ? uidResponsable : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.task_alt, color: Colors.cyanAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: tarea["titulo"]),
                  onChanged: (val) => tarea["titulo"] = val,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Título de la tarea",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentResponsable,
                  items: responsablesDropdown,
                  onChanged: (value) => setState(() => tarea["responsable"] = value),
                  decoration: InputDecoration(
                    labelText: "Responsable",
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  dropdownColor: const Color(0xFF0E1B2D),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final fechaSeleccionada = await showDatePicker(
                    context: context,
                    initialDate: tarea["fecha"] ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fechaSeleccionada != null) _cambiarFecha(index, fechaSeleccionada);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat("dd/MM/yyyy").format(tarea["fecha"])),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          if (tarea["matchHabilidad"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text("Habilidad sugerida: ${tarea["matchHabilidad"]}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          if (tarea["asignadoPorDefecto"] == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "Asignado por IA como mejor opción disponible",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlueprintCard() {
    final blueprint = widget.proyecto.blueprintIA as Map<String, dynamic>?;
    if (blueprint == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Blueprint IA",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(_mostrarBlueprint ? Icons.unfold_less : Icons.unfold_more, color: Colors.white70),
                tooltip: _mostrarBlueprint ? "Ocultar blueprint" : "Mostrar blueprint",
                onPressed: () => setState(() => _mostrarBlueprint = !_mostrarBlueprint),
              ),
            ],
          ),
          if (_mostrarBlueprint) ...[
            const SizedBox(height: 8),
            ...blueprint.entries.map((e) {
              final value = e.value is String ? e.value : e.value.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.label_outline, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text(value, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _guardarTareas,
            icon: const Icon(Icons.save),
            label: const Text("Guardar en proyecto"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.withOpacity(0.15),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text("Cerrar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
