import 'package:flutter/material.dart';

class DepartmentDetailsPage extends StatelessWidget {
  final String departmentName;
  final String sectors;
  final List<String> companies;
  final List<String> students;

  const DepartmentDetailsPage({
    Key? key,
    required this.departmentName,
    required this.sectors,
    required List<String>? companies, // Cambiamos a nullable
    required List<String>? students, // Cambiamos a nullable
  })  : companies = companies ?? const [], // Valor predeterminado
        students = students ?? const [], // Valor predeterminado
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de $departmentName'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sectores: $sectors',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Empresas:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...companies.map((company) => Text('- $company')).toList(),
            const SizedBox(height: 16),
            const Text(
              'Estudiantes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...students.map((student) => Text('- $student')).toList(),
          ],
        ),
      ),
    );
  }
}
