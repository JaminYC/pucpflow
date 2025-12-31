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
  bool mostrarRequisitos = false; // Oculto por defecto
  late String areaSeleccionada;
  DateTime? fechaLimite; // ✅ Fecha límite/deadline
  DateTime? fechaProgramada; // ✅ Hora/fecha programada para hacer la tarea

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

      // ✅ Preservar el tipoTarea original (puede ser metadata de la IA como "descubrimiento", "ejecucion", etc.)
      // Ya no lo validamos ni mostramos en el form - solo lo preservamos
      tipoTarea = widget.tareaInicial!.tipoTarea;

      dificultad = widget.tareaInicial!.dificultad ?? "media";
      duracion = widget.tareaInicial!.duracion;
      requisitos = Map<String, int>.from(widget.tareaInicial!.requisitos ?? {});
      responsables = List<String>.from(widget.tareaInicial!.responsables);
      fechaLimite = widget.tareaInicial!.fechaLimite ?? widget.tareaInicial!.fecha; // ✅ Cargar fecha límite
      fechaProgramada = widget.tareaInicial!.fechaProgramada; // ✅ Cargar hora programada

      // Normalizar el área seleccionada (eliminar saltos de línea y espacios extra)
      String areaTemporal = widget.tareaInicial?.area ?? (widget.areas.keys.isNotEmpty ? _normalizarArea(widget.areas.keys.first) : "General");
      areaSeleccionada = _normalizarArea(areaTemporal);
    } else {
      // Nueva tarea creada manualmente
      tipoTarea = "Libre"; // Por defecto
      for (var h in habilidades) {
        requisitos[h] = 2;
      }
      areaSeleccionada = widget.areas.keys.isNotEmpty ? _normalizarArea(widget.areas.keys.first) : "General";
      fechaLimite = DateTime.now().add(const Duration(days: 7)); // ✅ Por defecto: 7 días desde hoy
    }
  }

  // Normalizar nombres de áreas (eliminar saltos de línea y espacios extra)
  String _normalizarArea(String area) {
    return area.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Obtener lista de áreas normalizadas sin duplicados
  List<String> _obtenerAreasNormalizadas() {
    final areasOriginales = widget.areas.keys.toList();
    final areasNormalizadas = areasOriginales.map((area) => _normalizarArea(area)).toList();
    final areasSinDuplicados = areasNormalizadas.toSet().toList();

    print("🔍 DEBUG TareaFormWidget:");
    print("  - Áreas originales: $areasOriginales");
    print("  - Áreas normalizadas: $areasNormalizadas");
    print("  - Áreas sin duplicados: $areasSinDuplicados");
    print("  - Área seleccionada actual: $areaSeleccionada");

    return areasSinDuplicados;
  }

  // Validar que el área seleccionada existe en la lista normalizada
  String _validarAreaSeleccionada() {
    final areasNormalizadas = _obtenerAreasNormalizadas();
    final areaActual = _normalizarArea(areaSeleccionada);

    // Si el área actual existe en la lista, usarla; si no, usar "General" o la primera disponible
    if (areasNormalizadas.contains(areaActual)) {
      return areaActual;
    } else if (areasNormalizadas.contains("General")) {
      areaSeleccionada = "General";
      return "General";
    } else if (areasNormalizadas.isNotEmpty) {
      areaSeleccionada = areasNormalizadas.first;
      return areasNormalizadas.first;
    } else {
      areaSeleccionada = "General";
      return "General";
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
                // ✅ Dropdown de "Tipo de Tarea" eliminado - se infiere automáticamente según responsables

                Builder(
                  builder: (context) {
                    final areasDisponibles = _obtenerAreasNormalizadas();
                    final areaValida = _validarAreaSeleccionada();
                    return DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.black,
                      value: areaValida,
                      decoration: _inputDecoration("Área"),
                      items: areasDisponibles
                          .asMap()
                          .entries
                          .map((entry) => DropdownMenuItem<String>(
                                key: ValueKey('area_${entry.key}_${entry.value}'),
                                value: entry.value,
                                child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => areaSeleccionada = value!),
                    );
                  },
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

                // ✅ NUEVO: Selector de Fecha Límite / Deadline
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📅 Fecha Límite / Deadline",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fechaLimite != null
                                ? "${fechaLimite!.day}/${fechaLimite!.month}/${fechaLimite!.year}"
                                : "No establecida",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaLimite ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.deepPurple,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF1E1E1E),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => fechaLimite = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ NUEVO: Selector de Hora/Fecha Programada
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🕐 Hora Programada (Opcional)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Cuándo se HARÁ la tarea",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fechaProgramada != null
                                  ? "${fechaProgramada!.day}/${fechaProgramada!.month}/${fechaProgramada!.year} ${fechaProgramada!.hour.toString().padLeft(2, '0')}:${fechaProgramada!.minute.toString().padLeft(2, '0')}"
                                  : "No establecida",
                              style: TextStyle(
                                color: fechaProgramada != null ? Colors.green : Colors.grey[400],
                                fontSize: 16,
                                fontWeight: fechaProgramada != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (fechaProgramada != null)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() => fechaProgramada = null);
                              },
                              tooltip: "Quitar hora programada",
                            ),
                          IconButton(
                            icon: const Icon(Icons.access_time, color: Colors.green),
                            onPressed: () async {
                              // Primero seleccionar fecha
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: fechaProgramada ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.green,
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF1E1E1E),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedDate != null) {
                                // Luego seleccionar hora
                                final TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: fechaProgramada != null
                                      ? TimeOfDay.fromDateTime(fechaProgramada!)
                                      : TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Colors.green,
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF1E1E1E),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedTime != null) {
                                  setState(() {
                                    fechaProgramada = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                            tooltip: "Seleccionar hora programada",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ MEJORADO: Sección de Asignación de Responsables (siempre visible)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "👤 Asignar Responsables",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.participantes.isEmpty)
                        Text(
                          "No hay participantes en este proyecto",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.participantes.map((p) {
                            final uid = p["uid"]!;
                            final seleccionado = responsables.contains(uid);

                            return FilterChip(
                              label: Text(p["nombre"] ?? "Sin nombre"),
                              selected: seleccionado,
                              selectedColor: Colors.blue,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey[700],
                              labelStyle: TextStyle(
                                color: seleccionado ? Colors.white : Colors.grey[300],
                              ),
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
                      if (responsables.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "⚠️ Sin responsables asignados",
                            style: TextStyle(color: Colors.orange[300], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                // ❌ OCULTO: Requisitos de habilidades (mantenido en backend para matching futuro)
                // Los requisitos se guardan automáticamente pero no se muestran en la UI
                // Esto permite hacer matching de personas en el futuro sin molestar al usuario
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Validación: si no hay responsables, mostrar advertencia (no bloquear)
                        if (responsables.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("⚠️ Recomendado: Asigna al menos un responsable"),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        // ✅ Inferir tipoTarea según responsables asignados
                        String tipoTareaFinal;
                        if (widget.tareaInicial != null) {
                          // Al editar: preservar el tipo original (puede tener metadata de IA)
                          tipoTareaFinal = tipoTarea;
                        } else {
                          // Al crear nueva tarea: inferir según responsables
                          tipoTareaFinal = responsables.isNotEmpty ? "Asignada" : "Libre";
                        }

                        final tarea = Tarea(
                          titulo: titulo,
                          descripcion: descripcion,
                          duracion: duracion,
                          dificultad: dificultad,
                          tipoTarea: tipoTareaFinal,
                          requisitos: requisitos,
                          responsables: responsables,
                          completado: widget.tareaInicial?.completado ?? false,
                          prioridad: widget.tareaInicial?.prioridad ?? 2,
                          colorId: widget.tareaInicial?.colorId ?? 0,
                          area: areaSeleccionada,
                          // ✅ ACTUALIZADO: Usar nuevos campos de fecha
                          fecha: fechaLimite, // Mantener por compatibilidad
                          fechaLimite: fechaLimite, // ✅ Deadline - fecha límite de entrega
                          fechaProgramada: fechaProgramada, // ✅ Hora programada (si fue establecida)
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
