import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'proyecto_model.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:pucpflow/features/user_auth/presentation/pages/create_event_page.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';


class ProyectoDetallePage extends StatefulWidget {
  final Proyecto proyecto;

  const ProyectoDetallePage({super.key, required this.proyecto});

  @override
  _ProyectoDetallePageState createState() => _ProyectoDetallePageState();
}

class _ProyectoDetallePageState extends State<ProyectoDetallePage> {
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  Map<String, bool> tareaCompletada = {};
  List<Tarea> tareas = [];

  @override
  void initState() {
    super.initState();
    tareas = widget.proyecto.tareas;
    loadCheckboxStates();
  }

  Future<void> loadCheckboxStates() async {
    final prefs = await SharedPreferences.getInstance();
    for (var tarea in tareas) {
      final key = '${widget.proyecto.id}_${tarea.titulo}';
      tareaCompletada[tarea.titulo] = prefs.getBool(key) ?? false;
    }
    setState(() {});
  }
Future<void> _addEventToCalendar(Tarea tarea) async {
  try {
    final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();
    if (calendarApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo conectar a Google Calendar")),
      );
      return;
    }

    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));
    final busyTimes = await _googleCalendarService.getBusyTimes(calendarApi, now, oneWeekLater);
    final freeSlot = _googleCalendarService.findFreeSlot(busyTimes, 60);

    if (freeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontraron horarios disponibles.")),
      );
      return;
    }

    final event = calendar.Event(
      summary: tarea.titulo,
      description: 'Tarea del Proyecto: ${widget.proyecto.nombre}',
      start: calendar.EventDateTime(
        dateTime: freeSlot,
        timeZone: "America/Lima",
      ),
      end: calendar.EventDateTime(
        dateTime: freeSlot.add(const Duration(hours: 1)),
        timeZone: "America/Lima",
      ),
      colorId: tarea.colorId.toString(), // ✅ Asignar el color seleccionado
    );

    await calendarApi.events.insert(event, "primary");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Evento '${tarea.titulo}' añadido al calendario")),
    );
  } catch (e) {
    print("Error al añadir evento al calendario: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al añadir evento: $e")),
    );
  }
}

  void _addNewTarea(String titulo, int colorId) {
    setState(() {
      tareas.add(Tarea(
        titulo: titulo,
        fecha: DateTime.now(),
        colorId: colorId, // ✅ Guardar el color seleccionado
      ));
    });
  }


  void _deleteTarea(Tarea tarea) {
    setState(() {
      tareas.remove(tarea);
    });
  }
void _showAddTareaDialog() {
  TextEditingController titleController = TextEditingController();
  int selectedColorId = 1; // Color por defecto

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder( // ✅ Agregado para actualizar el estado del color seleccionado
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Nueva Tarea"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "Título de la tarea"),
                ),
                const SizedBox(height: 10),
                const Text("Selecciona un color:"),
                Wrap(
                  spacing: 10,
                  children: List.generate(11, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() { // ✅ Esto permite que el color se actualice dinámicamente
                          selectedColorId = index + 1;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: _getColorFromId(index + 1),
                        child: selectedColorId == index + 1
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
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
                  _addNewTarea(titleController.text, selectedColorId);
                  Navigator.of(context).pop();
                },
                child: const Text("Agregar"),
              ),
            ],
          );
        },
      );
    },
  );
}


  Color _getColorFromId(int colorId) {
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.grey,
      Colors.black,
    ];
    return colors[(colorId - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proyecto.nombre),
        backgroundColor: const Color.fromARGB(255, 41, 128, 191),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTareaDialog,
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
                    subtitle: Text('Fecha: ${tarea.fecha.toLocal()}',
                        style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: tareaCompletada[tarea.titulo] ?? false,
                          onChanged: (bool? value) async {
                            final prefs = await SharedPreferences.getInstance();
                            final key = '${widget.proyecto.id}_${tarea.titulo}';

                            setState(() {
                              tareaCompletada[tarea.titulo] = value ?? false;
                            });

                            await prefs.setBool(key, value ?? false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          onPressed: () => _addEventToCalendar(tarea),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteTarea(tarea),
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
