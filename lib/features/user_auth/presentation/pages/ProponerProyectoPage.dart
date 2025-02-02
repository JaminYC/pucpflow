import 'package:flutter/material.dart';

class ProponerProyectoPage extends StatefulWidget {
  const ProponerProyectoPage({super.key});

  @override
  State<ProponerProyectoPage> createState() => _ProponerProyectoPageState();
}

class _ProponerProyectoPageState extends State<ProponerProyectoPage> {
  final _formKey = GlobalKey<FormState>();

  String? _projectName;
  String? _description;
  String? _category;

  final List<String> _categories = [
    'Educación',
    'Salud',
    'Medio Ambiente',
    'Tecnología',
    'Cultura',
    'Otro'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proponer Proyecto Social',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre del Proyecto:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Ingresa el nombre del proyecto',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  _projectName = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe brevemente el proyecto',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  _description = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Categoría:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                items: _categories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  _category = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[700],
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                  ),
                  child: const Text(
                    'Enviar Proyecto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Aquí puedes guardar los datos o enviarlos a un backend
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Proyecto Enviado'),
          content: Text(
              '¡Gracias por proponer el proyecto: $_projectName!\n\nDescripción: $_description\nCategoría: $_category'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Vuelve a la página anterior
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}
