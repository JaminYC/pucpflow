import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sheets_service.dart';
import 'curso_model.dart';

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
