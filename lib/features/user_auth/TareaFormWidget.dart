import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

class TareaFormWidget extends StatefulWidget {
  final Tarea? tareaInicial;
  final void Function(Tarea) onSubmit;
  final List<Map<String, String>> participantes;
  final Map<String, List<String>> areas;

  const TareaFormWidget({
    super.key,
    this.tareaInicial,
    required this.onSubmit,
    this.participantes = const [],
    required this.areas,
  });

  @override
  State<TareaFormWidget> createState() => _TareaFormWidgetState();
}

class _TareaFormWidgetState extends State<TareaFormWidget> {
  final _formKey = GlobalKey<FormState>();
  String titulo = "";
  String descripcion = "";
  String tipoTarea = "Libre";
  String dificultad = "media";
  int duracion = 60;
  Map<String, int> requisitos = {};
  List<String> responsables = [];
  bool mostrarRequisitos = false;
  late String areaSeleccionada;

  final List<String> habilidades = [
    "Planificación",
    "Liderazgo",
    "Comunicación efectiva",
    "Propuesta de ideas",
    "Toma de decisiones",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tareaInicial != null) {
      titulo = widget.tareaInicial!.titulo;
      descripcion = widget.tareaInicial!.descripcion ?? "";
      tipoTarea = widget.tareaInicial!.tipoTarea;
      dificultad = widget.tareaInicial!.dificultad ?? "media";
      duracion = widget.tareaInicial!.duracion;
      requisitos = Map<String, int>.from(widget.tareaInicial!.requisitos ?? {});
      responsables = List<String>.from(widget.tareaInicial!.responsables);
      areaSeleccionada = widget.tareaInicial?.area ?? (widget.areas.keys.isNotEmpty ? widget.areas.keys.first : "General");
    } else {
      for (var h in habilidades) {
        requisitos[h] = 2;
      }
      areaSeleccionada = widget.areas.keys.isNotEmpty ? widget.areas.keys.first : "General";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tareaInicial != null ? "Editar Tarea" : "Crear Nueva Tarea",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  initialValue: titulo,
                  decoration: _inputDecoration("Título"),
                  onChanged: (value) => titulo = value,
                  validator: (value) => value == null || value.isEmpty ? "Ingrese un título" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  initialValue: descripcion,
                  maxLines: 3,
                  decoration: _inputDecoration("Descripción"),
                  onChanged: (value) => descripcion = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black,

                  decoration: _inputDecoration("Dificultad"),
                  value: dificultad,
                  items: ["baja", "media", "alta"]
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white)),))
                      .toList(),
                  onChanged: (value) => setState(() => dificultad = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black,

                  decoration: _inputDecoration("Tipo de Tarea"),
                  value: tipoTarea,
                  items: ["Libre", "Asignada", "Automática"]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)),))
                      .toList(),
                  onChanged: (value) => setState(() => tipoTarea = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black,
                  value: areaSeleccionada,
                  decoration: _inputDecoration("Área"),
                  items: widget.areas.keys
                      .map((area) => DropdownMenuItem(value: area, child: Text(area, style: const TextStyle(color: Colors.white)),))
                      .toList(),
                  onChanged: (value) => setState(() => areaSeleccionada = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  initialValue: duracion.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Duración estimada (minutos)"),
                  onChanged: (value) => duracion = int.tryParse(value) ?? 60,
                ),
                const SizedBox(height: 16),
                if (tipoTarea == "Asignada")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Asignar a participantes:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.participantes.map((p) {
                          final uid = p["uid"]!;
                          final seleccionado = responsables.contains(uid);

                          return FilterChip(
                            label: Text(p["nombre"] ?? ""),
                            selected: seleccionado,
                            selectedColor: Colors.deepPurple,
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.grey[300],
                            onSelected: (bool value) {
                              setState(() {
                                if (value) {
                                  responsables.add(uid);
                                } else {
                                  responsables.remove(uid);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() => mostrarRequisitos = !mostrarRequisitos),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Requisitos de habilidades (0 a 5):",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Icon(
                        mostrarRequisitos ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white,
                      )
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: mostrarRequisitos
                      ? Column(
                          children: habilidades.map((h) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h, style: const TextStyle(color: Colors.white)),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                  ),
                                  child: Slider(
                                    value: (requisitos[h] ?? 2).toDouble(),
                                    min: 0,
                                    max: 5,
                                    divisions: 5,
                                    label: "${requisitos[h] ?? 2}",
                                    activeColor: Colors.deepPurple,
                                    onChanged: (val) => setState(() => requisitos[h] = val.toInt()),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (tipoTarea == "Asignada" && responsables.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Debe asignar al menos un responsable.")),
                          );
                          return;
                        }
                        final tarea = Tarea(
                          titulo: titulo,
                          descripcion: descripcion,
                          duracion: duracion,
                          dificultad: dificultad,
                          tipoTarea: tipoTarea,
                          requisitos: requisitos,
                          responsables: responsables,
                          completado: widget.tareaInicial?.completado ?? false,
                          prioridad: widget.tareaInicial?.prioridad ?? 2,
                          colorId: widget.tareaInicial?.colorId ?? 0,
                          area: areaSeleccionada,
                        );
                        widget.onSubmit(tarea);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(widget.tareaInicial != null ? "Guardar Cambios" : "Crear Tarea", style: const TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
    hintStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}

}
