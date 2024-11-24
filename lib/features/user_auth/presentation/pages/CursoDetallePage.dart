import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sheets_service.dart';
import 'curso_model.dart';

class CursoDetallePage extends StatefulWidget {
  final Curso curso;
  final String userId; // Identificador único del usuario

  CursoDetallePage({required this.curso, required this.userId});

  @override
  _CursoDetallePageState createState() => _CursoDetallePageState();
}

class _CursoDetallePageState extends State<CursoDetallePage> {
  List<Unidad> unidades = [];
  final googleSheetsService = GoogleSheetsService();

  // Mapas para almacenar el estado de los checkboxes
  Map<String, bool> recursoChecked = {};
  Map<String, bool> practicaChecked = {};

  // Contadores locales y globales
  int totalRecursos = 0;
  int totalPracticas = 0;
  int recursosMarcados = 0;
  int practicasMarcadas = 0;
  int recursosGlobales = 0;
  int practicasGlobales = 0;

  @override
  void initState() {
    super.initState();
    fetchUnidades();
  }

  Future<void> fetchUnidades() async {
    print("Spreadsheet ID del curso actual: ${widget.curso.spreadsheetId}");
    
    final fetchedUnidades = await googleSheetsService.fetchUnidades(widget.curso.spreadsheetId, "UNIDAD1");
    setState(() {
      unidades = fetchedUnidades;
      calculateTotals();
      loadCheckboxStates(); // Cargar el estado de los checkboxes
      loadGlobalProgress(); // Cargar el progreso global
    });
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

  void calculateTotals() {
    totalRecursos = 0;
    totalPracticas = 0;

    for (var unidad in unidades) {
      for (var capitulo in unidad.capitulos) {
        for (var tema in capitulo.temas) {
          if (tema.recurso.isNotEmpty) totalRecursos++;
          if (tema.practica.isNotEmpty) totalPracticas++;
        }
      }
    }
  }

  Future<void> updateCounters() async {
    recursosMarcados = recursoChecked.values.where((v) => v).length;
    practicasMarcadas = practicaChecked.values.where((v) => v).length;

    // Guardar el progreso local de los checkboxes en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    recursoChecked.forEach((key, value) async {
      await prefs.setBool('${widget.userId}_${key}_recurso', value);
    });
    practicaChecked.forEach((key, value) async {
      await prefs.setBool('${widget.userId}_${key}_practica', value);
    });

    // Actualizar el progreso global
    await prefs.setInt('${widget.userId}_recursosGlobales', recursosMarcados);
    await prefs.setInt('${widget.userId}_practicasGlobales', practicasMarcadas);

    // Cargar el progreso global actualizado
    loadGlobalProgress();
    setState(() {});
  }

  Future<void> loadGlobalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    recursosGlobales = prefs.getInt('${widget.userId}_recursosGlobales') ?? 0;
    practicasGlobales = prefs.getInt('${widget.userId}_practicasGlobales') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.curso.nombre),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recursos completados: $recursosMarcados / $totalRecursos\n'
              'Prácticas completadas: $practicasMarcadas / $totalPracticas\n\n'
              'Progreso Global:\n'
              'Recursos globales completados: $recursosGlobales\n'
              'Prácticas globales completadas: $practicasGlobales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: unidades.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(20.0),
                    itemCount: unidades.length,
                    itemBuilder: (context, index) {
                      final unidad = unidades[index];
                      return ExpansionTile(
                        title: Text(unidad.nombre),
                        subtitle: Text(unidad.descripcion),
                        children: unidad.capitulos.map((capitulo) {
                          return ExpansionTile(
                            title: Text(capitulo.nombre),
                            subtitle: Text(capitulo.descripcion),
                            children: capitulo.temas.map((tema) {
                              return ListTile(
                                title: Text(tema.nombre),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Descripción: ${tema.descripcion}"),
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
                                        Text("Recurso: ${tema.recurso}"),
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
                                        Text("Práctica: ${tema.practica}"),
                                      ],
                                    ),
                                    if (tema.ayuda.isNotEmpty) Text("Ayuda: ${tema.ayuda}"),
                                  ],
                                ),
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
    );
  }
}
