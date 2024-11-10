import 'package:flutter/material.dart';
import 'google_sheets_service.dart';

class CursosPage extends StatefulWidget {
  @override
  _CursosPageState createState() => _CursosPageState();
}

class _CursosPageState extends State<CursosPage> {
  List<String> cursos = [];
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
                      // Acción al seleccionar un curso
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(cursos[index]),
                  ),
                );
              },
            ),
    );
  }
}
