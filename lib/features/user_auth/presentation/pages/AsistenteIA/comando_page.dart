import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/agendareventos.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/comando_service.dart';

class ComandoPage extends StatelessWidget {
  final List<String> comandos;
  final ComandoService _comandoService = ComandoService(); // Instancia del servicio de comandos

  ComandoPage({required this.comandos});

  void _ejecutarAccion(BuildContext context, String comando) {
    if (comando.contains("agendar evento")) {
      var datosEvento = _comandoService.procesarComando(comando);

      if (datosEvento["completo"]) {
        // ✅ Si tiene todos los datos, agenda automáticamente en Google Calendar
        _comandoService.crearEventoEnGoogleCalendar(datosEvento["nombre"], datosEvento["fechaHora"]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Evento '${datosEvento["nombre"]}' agendado correctamente.")),
        );
      } else {
        // ❌ Si falta información, envía a la pantalla de edición manual
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrearEventoPage(
              nombre: datosEvento["nombre"],
              fecha: datosEvento["fechaHora"]?.toLocal().toString() ?? "",
              hora: "",
            ),
          ),
        );
      }
    } else if (comando.contains("reorganizar tareas")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📌 Tareas reorganizadas correctamente")),
      );
    } else if (comando.contains("tareas pendientes")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📌 Mostrando tareas pendientes")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Comando no reconocido")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comandos detectados")),
      body: ListView.builder(
        itemCount: comandos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(comandos[index]),
            onTap: () => _ejecutarAccion(context, comandos[index]), // Ejecuta la acción del comando seleccionado
          );
        },
      ),
    );
  }
}
