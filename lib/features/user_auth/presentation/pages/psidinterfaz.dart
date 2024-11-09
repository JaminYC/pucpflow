import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'psidrecursos.dart';

class Psidinterfaz extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Módulos',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Módulos'),
        ),
        body: ModuleList(),
      ),
    );
  }
}

class ModuleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        ModuleTile(moduleTitle: 'Módulo 1'),
        ModuleTile(moduleTitle: 'Módulo 2'),
        ModuleTile(moduleTitle: 'Módulo 3'),
        ModuleTile(moduleTitle: 'Módulo 4'),
        SizedBox(height: 20), // Espacio antes del botón
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PSIDRecursosPage()),
            );
          },
          child: Text('Ir a PSID Recursos'),
        ),
      ],
    );
  }
}

class ModuleTile extends StatelessWidget {
  final String moduleTitle;

  ModuleTile({required this.moduleTitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ExpansionTile(
        title: Text(moduleTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_drop_down),
        children: [
          ExpansionTile(
            title: Text("Tema 1"),
            children: [
              ListTile(
                title: Text("Teoría"),
                trailing: Icon(Icons.info_outline),
              ),
              ListTile(
                title: Text("Recurso"),
                trailing: Icon(Icons.book),
              ),
              ListTile(
                title: Text("Práctica"),
                trailing: Icon(Icons.build),
              ),
              ListTile(
                title: Text("Ayuda"),
                trailing: Icon(Icons.help_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
