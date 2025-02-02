import 'package:flutter/material.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView( // ✅ Aquí va la lista de alertas
        children: const [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text('Alerta de seguridad'),
            subtitle: Text('Revise la configuración de seguridad de su cuenta.'),
          ),
          ListTile(
            leading: Icon(Icons.update, color: Colors.orange),
            title: Text('Actualización disponible'),
            subtitle: Text('Hay una nueva versión de la aplicación disponible.'),
          ),
          ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('Información importante'),
            subtitle: Text('No olvide verificar su correo electrónico.'),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
