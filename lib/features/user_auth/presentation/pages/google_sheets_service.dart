import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  final String spreadsheetId = '1GXXEfVbwwhAPCMG2MKHzL_fyPjnR7vEegbETfftPhtk'; // Reemplaza con el ID de tu Google Sheets
  final String sheetName = 'Octavo Ciclo'; // Nombre de la hoja de cálculo
  final String apiKey = 'AIzaSyAIxbm_eohVKVyb5wgvIa9YI6RUAFDkDOs'; // Reemplaza con tu API Key

  Future<List<String>> fetchCourses() async {
    final range = '$sheetName!B3:B'; // Cambia el rango para comenzar desde B3
    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final values = data['values'] as List<dynamic>;

        // Extrae los nombres de los cursos de cada fila
        return values.map((row) => row[0] as String).toList();
      } else {
        print('Error al obtener los cursos: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
