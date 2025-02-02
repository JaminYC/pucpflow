import 'package:flutter/material.dart';
import 'dart:async';

class MeditationPage extends StatefulWidget {
  const MeditationPage({Key? key}) : super(key: key);

  @override
  _MeditationPageState createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  int _selectedDuration = 5; // Duración de la meditación en minutos
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isMeditating = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMeditation() {
    setState(() {
      _remainingSeconds = _selectedDuration * 60;
      _isMeditating = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isMeditating = false;
        });
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¡Meditación Completa!"),
        content: const Text("¡Buen trabajo! Te has tomado un tiempo para ti."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Text(
      "$minutes:$seconds",
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meditación"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Elige la duración de tu meditación:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<int>(
              value: _selectedDuration,
              items: const [
                DropdownMenuItem(value: 5, child: Text("5 minutos")),
                DropdownMenuItem(value: 10, child: Text("10 minutos")),
                DropdownMenuItem(value: 15, child: Text("15 minutos")),
                DropdownMenuItem(value: 20, child: Text("20 minutos")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDuration = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            if (_isMeditating)
              Column(
                children: [
                  _buildTimerDisplay(),
                  const SizedBox(height: 20),
                  const Text(
                    "Concéntrate en tu respiración. Relájate y déjate llevar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _startMeditation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Comenzar Meditación"),
              ),
            const SizedBox(height: 20),
            const Text(
              "Sonidos Relajantes:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSoundTile("Lluvia Suave", Icons.water_drop),
            _buildSoundTile("Sonidos del Bosque", Icons.park),
            _buildSoundTile("Olas del Mar", Icons.beach_access),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title),
      trailing: const Icon(Icons.play_arrow, color: Colors.purple),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reproduciendo: $title")),
        );
      },
    );
  }
}
