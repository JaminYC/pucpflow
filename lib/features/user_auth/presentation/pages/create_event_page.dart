import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_calendar_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();

  // Campos del formulario
  String _title = "";
  String _description = "";
  DateTime? _startDate;
  DateTime? _endDate;
  String _location = "";
  String _colorId = "1"; // ID por defecto
  List<String> _attendees = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Evento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo: Título
              TextFormField(
                decoration: const InputDecoration(labelText: "Título"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor, ingresa un título";
                  }
                  return null;
                },
                onSaved: (value) => _title = value!,
              ),
              // Campo: Descripción
              TextFormField(
                decoration: const InputDecoration(labelText: "Descripción"),
                onSaved: (value) => _description = value!,
              ),
              // Campo: Fecha de Inicio
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
                child: Text(_startDate == null
                    ? "Seleccionar Fecha de Inicio"
                    : "Inicio: ${_startDate!.toLocal()}"),
              ),
              // Campo: Fecha de Fin
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: Text(_endDate == null
                    ? "Seleccionar Fecha de Fin"
                    : "Fin: ${_endDate!.toLocal()}"),
              ),
              // Campo: Ubicación
              TextFormField(
                decoration: const InputDecoration(labelText: "Ubicación"),
                onSaved: (value) => _location = value ?? "",
              ),
              // Campo: Color del Evento
              DropdownButtonFormField<String>(
                value: _colorId,
                items: [
                  DropdownMenuItem(value: "1", child: Text("Azul")),
                  DropdownMenuItem(value: "2", child: Text("Verde")),
                  DropdownMenuItem(value: "3", child: Text("Morado")),
                  DropdownMenuItem(value: "4", child: Text("Naranja")),
                ],
                onChanged: (value) {
                  setState(() {
                    _colorId = value ?? "1";
                  });
                },
                decoration: const InputDecoration(labelText: "Color"),
              ),
              // Botón para Crear Evento
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Añadir al Calendario"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona fechas válidas")),
      );
      return;
    }

    final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();
    if (calendarApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo conectar a Google Calendar")),
      );
      return;
    }

    final event = calendar.Event(
      summary: _title,
      description: _description,
      location: _location,
      colorId: _colorId,
      start: calendar.EventDateTime(
        dateTime: _startDate,
        timeZone: "GMT-5:00",
      ),
      end: calendar.EventDateTime(
        dateTime: _endDate,
        timeZone: "GMT-5:00",
      ),
    );

    try {
      await calendarApi.events.insert(event, "primary");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Evento añadido al calendario")),
      );
      Navigator.pop(context); // Vuelve a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al añadir evento: $e")),
      );
    }
  }
}
