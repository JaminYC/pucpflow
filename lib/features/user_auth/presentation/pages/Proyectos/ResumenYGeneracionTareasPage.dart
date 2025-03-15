import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  @override
  void initState() {
    super.initState();
    _procesarConIA(widget.texto);
  }

  Future<void> _procesarConIA(String texto) async {
    try {
      participantes = await _obtenerParticipantes();
      final callable = FirebaseFunctions.instance.httpsCallable("procesarReunion");
      final result = await callable.call({"texto": texto, "participantes": participantes});

      if (result.data != null && result.data["resumen"] != null && result.data["tareas"] != null) {
        setState(() {
          resumen = result.data["resumen"];
          tareasGeneradas = List<Map<String, dynamic>>.from(result.data["tareas"]);
          for (var tarea in tareasGeneradas) {
            tarea["responsable"] ??= null;
            tarea["fecha"] = tarea["fecha"] != null
                ? DateTime.tryParse(tarea["fecha"])
                : DateTime.now().add(const Duration(days: 3));
          }
          _cargandoIA = false;
          _errorIA = false;
        });
      } else {
        throw Exception("Respuesta inválida de la IA");
      }
    } catch (e) {
      setState(() {
        resumen = "❌ Ocurrió un error al procesar la reunión con la IA.";
        tareasGeneradas = [];
        _cargandoIA = false;
        _errorIA = true;
      });
    }
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
    final List<Tarea> tareasFinales = tareasGeneradas.map((t) => Tarea(
      titulo: t["titulo"],
      fecha: t["fecha"],
      duracion: 0,
      colorId: 1,
      responsables: t["responsable"] != null ? [t["responsable"]] : [],
      tipoTarea: "Automática",
    )).toList();

    await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
      "tareas": FieldValue.arrayUnion(tareasFinales.map((t) => t.toJson()).toList()),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Tareas guardadas exitosamente")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resumen y Tareas Generadas")),
      body: _cargandoIA
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: _errorIA ? Colors.red[50] : Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(resumen, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("📋 Tareas generadas automáticamente:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: tareasGeneradas.isEmpty
                        ? const Text("No se generaron tareas")
                        : ListView.builder(
                            itemCount: tareasGeneradas.length,
                            itemBuilder: (context, index) {
                              final tarea = tareasGeneradas[index];
                              final responsablesDropdown = participantes.map((usuario) => DropdownMenuItem<String>(
                                    value: usuario["uid"],
                                    child: Text(usuario["nombre"]!),
                                  )).toList();

                              final currentResponsable = responsablesDropdown.any((item) => item.value == tarea["responsable"])
                                  ? tarea["responsable"]
                                  : null;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: TextEditingController(text: tarea["titulo"]),
                                        onChanged: (val) => tarea["titulo"] = val,
                                        decoration: const InputDecoration(labelText: "Título de la tarea"),
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: currentResponsable,
                                        hint: const Text("Selecciona responsable"),
                                        items: responsablesDropdown,
                                        onChanged: (val) => setState(() => tarea["responsable"] = val),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text("Fecha límite:"),
                                          const SizedBox(width: 10),
                                          Text(DateFormat("dd/MM/yyyy").format(tarea["fecha"])),
                                          IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () async {
                                              DateTime? picked = await showDatePicker(
                                                context: context,
                                                initialDate: tarea["fecha"],
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                              );
                                              if (picked != null) {
                                                setState(() => tarea["fecha"] = picked);
                                              }
                                            },
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: tareasGeneradas.isEmpty ? null : _guardarTareas,
                    child: const Text("✅ Confirmar y Guardar Tareas"),
                  )
                ],
              ),
            ),
    );
  }
}
