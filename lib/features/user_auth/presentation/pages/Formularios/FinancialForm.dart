import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialForm extends StatefulWidget {
  final String userId;

  const FinancialForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<FinancialForm> createState() => _FinancialFormState();
}

class _FinancialFormState extends State<FinancialForm> {
  final _formKey = GlobalKey<FormState>();
  double _nivelEducacionFinanciera = 5.0;
  String _situacionActual = "Estable";
  String _objetivoFinanciero = "Ahorrar para estudios";

  Future<void> _guardarDatosFinancieros() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'nivelEducacionFinanciera': _nivelEducacionFinanciera,
        'situacionFinancieraActual': _situacionActual,
        'objetivoFinanciero': _objetivoFinanciero,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Datos financieros guardados correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al guardar datos: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💼 Bienestar Financiero"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarDatosFinancieros,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📊 Nivel de educación financiera (1-10):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _nivelEducacionFinanciera,
                min: 1,
                max: 10,
                divisions: 9,
                label: _nivelEducacionFinanciera.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _nivelEducacionFinanciera = value;
                  });
                },
                activeColor: Colors.black,
                inactiveColor: Colors.black26,
              ),
              const SizedBox(height: 20),

              const Text(
                "💰 Situación financiera actual:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _situacionActual,
                items: const [
                  DropdownMenuItem(value: "Estable", child: Text("Estable")),
                  DropdownMenuItem(value: "Endeudado", child: Text("Endeudado")),
                  DropdownMenuItem(value: "Ahorrando", child: Text("Ahorrando")),
                  DropdownMenuItem(value: "Invirtiendo", child: Text("Invirtiendo")),
                ],
                onChanged: (value) {
                  setState(() {
                    _situacionActual = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "🎯 Objetivo financiero principal:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _objetivoFinanciero,
                items: const [
                  DropdownMenuItem(value: "Ahorrar para estudios", child: Text("Ahorrar para estudios")),
                  DropdownMenuItem(value: "Crear fondo de emergencia", child: Text("Crear fondo de emergencia")),
                  DropdownMenuItem(value: "Inversión a largo plazo", child: Text("Inversión a largo plazo")),
                  DropdownMenuItem(value: "Salir de deudas", child: Text("Salir de deudas")),
                ],
                onChanged: (value) {
                  setState(() {
                    _objetivoFinanciero = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
