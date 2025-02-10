
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/comando_service.dart' show ComandoService;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'proyecto_model.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';

class ProyectoDetallePage extends StatefulWidget {
  final Proyecto proyecto;

  const ProyectoDetallePage({super.key, required this.proyecto});

  @override
  _ProyectoDetallePageState createState() => _ProyectoDetallePageState();
}

class _ProyectoDetallePageState extends State<ProyectoDetallePage> {
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  List<Tarea> tareas = [];

  @override
  void initState() {
    super.initState();
    tareas = widget.proyecto.tareas;
    loadTareas();
  }

Future<void> loadTareas() async {
  final prefs = await SharedPreferences.getInstance();
  final tareasData = prefs.getStringList('tareas_${widget.proyecto.id}') ?? [];

  if (tareasData.isEmpty && widget.proyecto.tareas.isEmpty) {
    print("🔹 Generando tareas automáticas para ${widget.proyecto.nombre}");
    widget.proyecto.tareas = ComandoService().generarTareasPorDefecto(widget.proyecto);
    
    // ✅ Solo guardar tareas si se generaron nuevas
    await saveTareas();
  }

  setState(() {
    tareas = widget.proyecto.tareas;
  });
}


  Future<void> saveTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final tareasData = tareas.map((tarea) => jsonEncode(tarea.toJson())).toList();
    await prefs.setStringList('tareas_${widget.proyecto.id}', tareasData);
  }

  void _addOrUpdateTarea(Tarea tarea) {
    setState(() {
      final index = tareas.indexWhere((t) => t.titulo == tarea.titulo);
      if (index != -1) {
        tareas[index] = tarea;
      } else {
        tareas.add(tarea);
      }
    });
    saveTareas();
  }

  void _deleteTarea(Tarea tarea) {
    setState(() {
      tareas.remove(tarea);
    });
    saveTareas();
  }

  Future<void> _addEventToCalendar(Tarea tarea, {bool automatico = false}) async {
    final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();
    if (calendarApi != null) {
      final busyTimes = await _googleCalendarService.getBusyTimes(
        calendarApi, tarea.fecha, tarea.fecha.add(Duration(days: 1)));

      if (!automatico && busyTimes.any((bt) => tarea.fecha.isAfter(bt.start!) && tarea.fecha.isBefore(bt.end!))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este horario ya está ocupado.")),
        );
        return;
      }

      final event = calendar.Event(
        summary: tarea.titulo,
        start: calendar.EventDateTime(
          dateTime: tarea.fecha,
          timeZone: "America/Lima",
        ),
        end: calendar.EventDateTime(
          dateTime: tarea.fecha.add(Duration(minutes: tarea.duracion)),
          timeZone: "America/Lima",
        ),
        colorId: tarea.colorId.toString(),
      );

      await calendarApi.events.insert(event, "primary");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarea añadida al calendario")),
      );
    }
  }

  void _showAddOrEditTareaDialog({Tarea? tarea}) async {
    final titleController = TextEditingController(text: tarea?.titulo ?? '');
    final durationController = TextEditingController(text: tarea?.duracion.toString() ?? '');
    DateTime selectedDate = tarea?.fecha ?? DateTime.now();
    int selectedColorId = tarea?.colorId ?? 1;

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final availableTimes = await _googleCalendarService.getAvailableTimes(date);
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(availableTimes.first),
      );

      if (time != null) {
        selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tarea == null ? "Nueva Tarea" : "Editar Tarea"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "Título de la tarea"),
                ),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Duración en minutos"),
                ),
                Wrap(
                  spacing: 10,
                  children: List.generate(4, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorId = index + 1;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: _getColorFromId(index + 1),
                        child: selectedColorId == index + 1 ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text;
                  final duration = int.tryParse(durationController.text) ?? 0;

                  if (title.isNotEmpty) {
                    _addOrUpdateTarea(Tarea(
                      titulo: title,
                      colorId: selectedColorId,
                      fecha: selectedDate,
                      duracion: duration,
                    ));
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
        );
      }
    }
  }

  Color _getColorFromId(int colorId) {
    const colors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green
    ];
    return colors[(colorId - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proyecto.nombre),
        backgroundColor: const Color(0xFF2980BF),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrEditTareaDialog(),
          ),
        ],
      ),
      body: tareas.isEmpty
          ? const Center(child: Text("No hay tareas disponibles."))
          : ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                return Card(
                  color: _getColorFromId(tarea.colorId),
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      tarea.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      'Fecha: ${tarea.fecha.toLocal()} - Duración: ${tarea.duracion} minutos',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _showAddOrEditTareaDialog(tarea: tarea),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteTarea(tarea),
                        ),
                        IconButton(
                          icon: const Icon(Icons.event_available, color: Colors.white),
                          onPressed: () => _addEventToCalendar(tarea, automatico: true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.event, color: Colors.white),
                          onPressed: () => _addEventToCalendar(tarea, automatico: false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
