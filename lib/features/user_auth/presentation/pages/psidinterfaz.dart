import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'psidrecursos.dart';
import 'curso_model.dart';


// Importa las clases Curso, Modulo y Tema
class Psidinterfaz extends StatelessWidget {
  final Curso curso;

  // Recibe un curso como parámetro en el constructor
  Psidinterfaz({required this.curso});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Módulos de ${curso.nombre}',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Módulos de ${curso.nombre}'),
        ),
        body: ModuleList(modulos: curso.modulos),
      ),
    );
  }
}

class ModuleList extends StatelessWidget {
  final List<Modulo> modulos;

  // Recibe la lista de módulos en el constructor
  ModuleList({required this.modulos});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        ...modulos.map((modulo) => ModuleTile(modulo: modulo)).toList(),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PSIDRecursosPage()),
            );
          },
          child: const Text('Ir a PSID Recursos'),
        ),
      ],
    );
  }
}

class ModuleTile extends StatelessWidget {
  final Modulo modulo;

  ModuleTile({required this.modulo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ExpansionTile(
        title: Text(modulo.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_drop_down),
        children: modulo.temas.map((tema) {
          return ExpansionTile(
            title: Text(tema.nombre),
            children: [
              ListTile(
                title: Text("Teoría"),
                trailing: Icon(Icons.info_outline),
                onTap: () {
                  // Acción para mostrar teoría
                },
              ),
              ListTile(
                title: Text("Recurso"),
                trailing: Icon(Icons.book),
                onTap: () {
                  // Acción para mostrar recurso
                },
              ),
              ListTile(
                title: Text("Práctica"),
                trailing: Icon(Icons.build),
                onTap: () {
                  // Acción para mostrar práctica
                },
              ),
              ListTile(
                title: Text("Ayuda"),
                trailing: Icon(Icons.help_outline),
                onTap: () {
                  // Acción para mostrar ayuda
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
