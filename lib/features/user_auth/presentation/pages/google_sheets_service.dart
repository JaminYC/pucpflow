// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'curso_model.dart'; // Importa el modelo del curso que contiene el nombre y el spreadsheetId

class GoogleSheetsService {
  final String spreadsheetId = '1GXXEfVbwwhAPCMG2MKHzL_fyPjnR7vEegbETfftPhtk'; // ID general de la lista de cursos
  final String sheetName = 'Octavo Ciclo'; // Nombre de la hoja de cálculo de cursos
  final String apiKey = 'AIzaSyAIxbm_eohVKVyb5wgvIa9YI6RUAFDkDOs'; // Tu API Key

  // Función para obtener la lista de cursos y sus IDs de hoja de cálculo
  Future<List<Curso>> fetchCourses() async {
    final range = '$sheetName!B3:C'; // Rango que contiene el nombre del curso y el spreadsheetId
    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey',
    );

    try {
      final response = await http.get(url);
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final values = data['values'] as List<dynamic>;

        // Extrae los nombres de los cursos y sus spreadsheetId
        return values.map((row) {
          final nombre = row[0] as String;
          final cursoSpreadsheetId = row[1] as String;
          return Curso(nombre: nombre, spreadsheetId: cursoSpreadsheetId);
        }).toList();
      } else {
        print('Error al obtener los cursos: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

// Función para obtener la estructura jerárquica de un curso específico (Unidades, Capítulos, Temas)
Future<List<Unidad>> fetchUnidades(String cursoSpreadsheetId, String unidadSheetName) async {
    final range = '$unidadSheetName!A1:B'; // Ajusta el rango a las unidades y capítulos
    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$cursoSpreadsheetId/values/$range?key=$apiKey',
    );

    print("Fetching units with URL: $url"); // Mensaje de depuración

    try {
      final response = await http.get(url);
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("Usando nombre de la hoja: $unidadSheetName y rango: A2:B");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final values = data['values'] as List<dynamic>;

        List<Unidad> unidades = [];
        Unidad? currentUnidad;
        Capitulo? currentCapitulo;

        for (var row in values) {
          final cellContent = row[0] as String;
          final cellDescription = row.length > 1 ? row[1] as String : ''; // Verifica si hay descripción

          if (cellContent.startsWith('Capítulo')) {
            // Si hay un capítulo actual, añádelo a la unidad actual
            if (currentUnidad != null && currentCapitulo != null) {
              currentUnidad.capitulos.add(currentCapitulo);
            }
            currentCapitulo = Capitulo(nombre: cellContent, descripcion: cellDescription, temas: []);
          } else if (cellContent.startsWith('Tema') && currentCapitulo != null) {
            // Añade el tema al capítulo actual
            final tema = Tema(
              nombre: cellContent,
              descripcion: cellDescription,
              recurso: '',
              practica: '',
              ayuda: '',
            );
            currentCapitulo.temas.add(tema);
          } else if (cellContent.startsWith('Unidad')) {
            // Si hay una unidad actual, añádela a la lista de unidades
            if (currentUnidad != null) {
              unidades.add(currentUnidad);
            }
            currentUnidad = Unidad(nombre: cellContent, descripcion: cellDescription, capitulos: []);
          }
        }
        // Añadir la última unidad y capítulo, si existen
        if (currentUnidad != null) {
          if (currentCapitulo != null) {
            currentUnidad.capitulos.add(currentCapitulo);
          }
          unidades.add(currentUnidad);
        }

        return unidades;
      } else {
        print('Error al obtener las unidades: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

}
