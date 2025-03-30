import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';

class CrearEventoPage extends StatefulWidget {
  final String nombre;
  final String fecha;
  final String hora;

  const CrearEventoPage({
    Key? key,
    this.nombre = "",
    this.fecha = "",
    this.hora = "",
  }) : super(key: key);

  @override
  _CrearEventoPageState createState() => _CrearEventoPageState();
}

class _CrearEventoPageState extends State<CrearEventoPage> {
  final _formKey = GlobalKey<FormState>();
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  late TextEditingController _nombreController;
  late TextEditingController _fechaController;
  late TextEditingController _horaController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombre);
    _fechaController = TextEditingController(text: widget.fecha);
    _horaController = TextEditingController(text: widget.hora);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  /// 🗓 Muestra un `DatePicker` para seleccionar la fecha del evento
  Future<void> _seleccionarFecha() async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _fechaController.text = "${pickedDate.day} de ${_getMonthName(pickedDate.month)} ${pickedDate.year}";
      });
    }
  }

  /// ⏰ Muestra un `TimePicker` para seleccionar la hora del evento
  Future<void> _seleccionarHora() async {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _horaController.text = "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')} ${pickedTime.period == DayPeriod.am ? "AM" : "PM"}";
      });
    }
  }

  /// 🗓 Mapea el número del mes a su nombre en español
  String _getMonthName(int month) {
    const months = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return months[month - 1];
  }

Future<void> _agendarEvento() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  if (_selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Por favor, selecciona una fecha y una hora válidas.")),
    );
    return;
  }

  // 🕒 Convierte la fecha y hora seleccionadas a `DateTime`
  DateTime fechaHoraEvento = DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _selectedTime!.hour,
    _selectedTime!.minute,
  );

  // 🔹 Obtiene la API de Google Calendar
  final calendarApi = await _calendarService.signInAndGetCalendarApi();
  if (calendarApi == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No se pudo conectar a Google Calendar")),
    );
    return;
  }


  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("✅ Evento '${_nombreController.text}' agendado correctamente.")),
  );

  Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completar Evento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 Campo: Nombre del evento
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Título"),
                validator: (value) => value!.isEmpty ? "Ingrese un título" : null,
              ),

              // 🔹 Campo: Fecha del evento con `DatePicker`
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(labelText: "Fecha"),
                readOnly: true,
                onTap: _seleccionarFecha,
                validator: (value) => value!.isEmpty ? "Seleccione una fecha" : null,
              ),

              // 🔹 Campo: Hora del evento con `TimePicker`
              TextFormField(
                controller: _horaController,
                decoration: const InputDecoration(labelText: "Hora"),
                readOnly: true,
                onTap: _seleccionarHora,
                validator: (value) => value!.isEmpty ? "Seleccione una hora" : null,
              ),

              const SizedBox(height: 20),

              // 🔹 Botón para agendar el evento
              ElevatedButton(
                onPressed: _agendarEvento,
                child: const Text("Añadir al Calendario"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
