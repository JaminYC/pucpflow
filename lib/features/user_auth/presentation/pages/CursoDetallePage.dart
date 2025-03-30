import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sheets_service.dart';
import 'curso_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';

import 'package:googleapis/calendar/v3.dart' as calendar;

import 'create_event_page.dart';

class CursoDetallePage extends StatefulWidget {
  final Curso curso;  
  final String userId;

  const CursoDetallePage({super.key, required this.curso, required this.userId});

  @override
  _CursoDetallePageState createState() => _CursoDetallePageState();
}

class _CursoDetallePageState extends State<CursoDetallePage> {
  List<Unidad> unidades = [];
  final googleSheetsService = GoogleSheetsService();
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();

  Map<String, bool> recursoChecked = {};
  Map<String, bool> practicaChecked = {};

  int totalRecursos = 0;
  int totalPracticas = 0;
  int recursosMarcados = 0;
  int practicasMarcadas = 0;

  @override
  void initState() {
    super.initState();
    fetchUnidades();
  }
  Future<void> addEventAutomatically(
    GoogleCalendarService calendarService, String calendarId) async {
  try {
    final calendarApi = await calendarService.signInAndGetCalendarApi();

    if (calendarApi == null) {
      print("Error: No se pudo autenticar con Google Calendar");
      return;
    }

    // Define el rango de tiempo para buscar disponibilidad
    final now = DateTime.now();
    final oneWeekLater = now.add(Duration(days: 7));

    // Consulta las horas ocupadas
    final busyTimes = await calendarService.getBusyTimes(calendarApi, now, oneWeekLater);

    // Encuentra un espacio libre
    final freeSlot = calendarService.findFreeSlot(busyTimes, 60); // Duración en minutos

    if (freeSlot == null) {
      print("No hay espacios libres disponibles.");
      return;
    }

    // Define las propiedades del evento
    final newEvent = calendar.Event(
      summary: "Evento automático",
      description: "Este evento fue creado automáticamente.",
      start: calendar.EventDateTime(
        dateTime: freeSlot,
        timeZone: "GMT-5:00", // Cambia según tu zona horaria
      ),
      end: calendar.EventDateTime(
        dateTime: freeSlot.add(Duration(minutes: 60)), // Duración del evento
        timeZone: "GMT-5:00",
      ),
      colorId: "5", // Personaliza el color del evento
      reminders: calendar.EventReminders(
        useDefault: false,
        overrides: [
          calendar.EventReminder(
            method: "popup",
            minutes: 10,
          ),
        ],
      ),
    );

    // Inserta el evento en el calendario
    final insertedEvent = await calendarApi.events.insert(newEvent, calendarId);
    print("Evento creado: ${insertedEvent.htmlLink}");
  } catch (e) {
    print("Error al añadir el evento: $e");
  }
}


  Future<void> _addEventToCalendar(Tema tema) async {
      try {
        final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();
        if (calendarApi == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo conectar a Google Calendar")),
          );
          return;
        }

        final event = calendar.Event(
          summary: tema.nombre,
          description: tema.descripcion,
          start: calendar.EventDateTime(
            dateTime: DateTime.now().add(const Duration(days: 1)),
            timeZone: "GMT-5:00",
          ),
          end: calendar.EventDateTime(
            dateTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
            timeZone: "GMT-5:00",
          ),
        );

        await calendarApi.events.insert(event, "primary");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Evento '${tema.nombre}' añadido al calendario")),
        );
      } catch (e) {
        print("Error al añadir evento al calendario: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al añadir evento: $e")),
        );
      }
    }

  Future<void> fetchUnidades() async {
    final fetchedUnidades = await googleSheetsService.fetchUnidades(widget.curso.spreadsheetId, "UNIDAD1");
    print("Datos de unidades cargados: $fetchedUnidades"); // Depuración de datos cargados
    if (fetchedUnidades.isNotEmpty) {
      setState(() {
        unidades = fetchedUnidades;
        calculateTotals(); // Calcula los totales al cargar unidades
        loadCheckboxStates();
      });
    } else {
      print("Error: No se cargaron unidades.");
    }
  }

  void calculateTotals() {
    totalRecursos = 0;
    totalPracticas = 0;

    for (var unidad in unidades) {
      print("Unidad: ${unidad.nombre}, Capítulos: ${unidad.capitulos.length}");
      for (var capitulo in unidad.capitulos) {
        print("  Capítulo: ${capitulo.nombre}, Temas: ${capitulo.temas.length}");
        for (var tema in capitulo.temas) {
          print("    Tema: ${tema.nombre}");
          // Cada tema tiene una casilla de recurso y una de práctica
          totalRecursos++;
          totalPracticas++;
        }
      }
    }
    print("Total recursos: $totalRecursos, Total prácticas: $totalPracticas"); // Depuración de totales
  }

  Future<void> loadCheckboxStates() async {
    final prefs = await SharedPreferences.getInstance();

    for (var unidad in unidades) {
      for (var capitulo in unidad.capitulos) {
        for (var tema in capitulo.temas) {
          final recursoKey = '${widget.userId}_${tema.nombre}_recurso';
          final practicaKey = '${widget.userId}_${tema.nombre}_practica';

          recursoChecked[tema.nombre] = prefs.getBool(recursoKey) ?? false;
          practicaChecked[tema.nombre] = prefs.getBool(practicaKey) ?? false;
        }
      }
    }

    updateCounters();
  }

  Future<void> updateCounters() async {
    recursosMarcados = recursoChecked.values.where((v) => v).length;
    practicasMarcadas = practicaChecked.values.where((v) => v).length;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.curso.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 3.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blue[900]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Recursos completados: $recursosMarcados / $totalRecursos\n'
                    'Prácticas completadas: $practicasMarcadas / $totalPracticas',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: unidades.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: unidades.length,
                        itemBuilder: (context, index) {
                          final unidad = unidades[index];
                          return ExpansionTile(
                            title: Text(
                              unidad.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              unidad.descripcion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            backgroundColor: Colors.black.withOpacity(0.7),
                            children: unidad.capitulos.map((capitulo) {
                              return ExpansionTile(
                                title: Text(
                                  capitulo.nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  capitulo.descripcion,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                backgroundColor: Colors.black.withOpacity(0.6),
                                children: capitulo.temas.map((tema) {
                                  return ListTile(
                                    title: Text(
                                      tema.nombre,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Descripción: ${tema.descripcion}",
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: recursoChecked[tema.nombre] ?? false,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  recursoChecked[tema.nombre] = value ?? false;
                                                  updateCounters();
                                                });
                                              },
                                            ),
                                            const Text(
                                              "Recurso",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Checkbox(
                                                  value: practicaChecked[tema.nombre] ?? false,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      practicaChecked[tema.nombre] = value ?? false;
                                                      updateCounters();
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  "Práctica",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                         const SizedBox(height: 8),
                                         ElevatedButton(
                                            onPressed: () async {
                                              final calendarApi = await GoogleCalendarService().signInAndGetCalendarApi();
                                              if (calendarApi == null) {
                                                // Mostrar un mensaje si el inicio de sesión falla
                                                print("No se pudo autenticar al usuario.");
                                                return;
                                              }

                                              // Define las fechas de inicio y fin para buscar espacios libres
                                              final now = DateTime.now();
                                              final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

                                              // Obtiene los tiempos ocupados
                                              final busyTimes = await GoogleCalendarService().getBusyTimes(calendarApi, now, endOfDay);

                                              // Define la duración del evento en minutos (puedes ajustar esto)
                                              const durationMinutes = 60;

                                              // Encuentra un espacio libre
                                              final freeSlot = GoogleCalendarService().findFreeSlot(busyTimes, durationMinutes);

                                              if (freeSlot != null) {
                                                // Crea el evento automáticamente
                                                final event = calendar.Event(
                                                  summary: tema.nombre,
                                                  description: tema.descripcion,
                                                  start: calendar.EventDateTime(
                                                    dateTime: freeSlot,
                                                    timeZone: "America/Lima", // Cambia según la zona horaria
                                                  ),
                                                  end: calendar.EventDateTime(
                                                    dateTime: freeSlot.add(Duration(minutes: durationMinutes)),
                                                    timeZone: "America/Lima",
                                                  ),
                                                );

                                                try {
                                                  // Inserta el evento en el calendario principal
                                                  await calendarApi.events.insert(event, "primary");
                                                  print("Evento añadido al calendario con éxito.");
                                                } catch (e) {
                                                  print("Error al añadir el evento: $e");
                                                }
                                              } else {
                                                print("No se encontró un espacio libre para añadir el evento.");
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.blue, // Color de fondo del botón
                                            ),
                                            child: const Text("Añadir al Calendario"),
                                          ),
                                        // Nuevo botón para agregar eventos manualmente
                                      ElevatedButton(
                                        onPressed: () {
                                          // Navegar a la página `CreateEventPage`
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const CreateEventPage()),

                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.green, // Color de fondo del botón
                                        ),
                                        child: const Text("Agregar Manualmente"),
                                         ),
                                      ],
                                      
                                    ),
                                    tileColor: Colors.black.withOpacity(0.5),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



