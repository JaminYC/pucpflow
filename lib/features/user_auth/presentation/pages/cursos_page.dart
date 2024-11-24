// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'google_sheets_service.dart';
import 'CursoDetallePage.dart'; // Importa la pantalla de detalles del curso
import 'curso_model.dart';

// ignore: use_key_in_widget_constructors
class CursosPage extends StatefulWidget {
  @override
  _CursosPageState createState() => _CursosPageState();
}

class _CursosPageState extends State<CursosPage> {
  List<Curso> cursos = [];
  final googleSheetsService = GoogleSheetsService();

  @override
  void initState() {
    super.initState();
    fetchCursos();
  }

  Future<void> fetchCursos() async {
    final fetchedCursos = await googleSheetsService.fetchCourses();
    setState(() {
      cursos = fetchedCursos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos Disponibles'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: cursos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(20.0),
              itemCount: cursos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navega a CursoDetallePage y pasa el `spreadsheetId` del curso seleccionado
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CursoDetallePage(
                            curso: cursos[index], userId: '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(cursos[index].nombre),
                  ),
                );
              },
            ),
    );
  }
}
