import 'package:flutter/material.dart';

class BotonValvula extends StatefulWidget {
  const BotonValvula({Key? key}) : super(key: key);

  @override
  State<BotonValvula> createState() => _BotonValvulaState();
}

class _BotonValvulaState extends State<BotonValvula> {
  bool valvulaAbierta = false;

  void _toggleValvula() {
    setState(() {
      valvulaAbierta = !valvulaAbierta;
    });

    // Aquí podrías llamar al controlador real
    // VitakuaController().toggleValvula(valvulaAbierta);

    final mensaje = valvulaAbierta ? 'Válvula abierta' : 'Válvula cerrada';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: valvulaAbierta ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _toggleValvula,
      icon: Icon(valvulaAbierta ? Icons.lock_open : Icons.lock),
      label: Text(valvulaAbierta ? 'Cerrar Válvula' : 'Abrir Válvula'),
    );
  }
}
