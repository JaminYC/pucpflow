import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/global/common/toast.dart';

class ProfilePreferencesPage extends StatefulWidget {
  final String userId;

  const ProfilePreferencesPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePreferencesPageState createState() => _ProfilePreferencesPageState();
}

class _ProfilePreferencesPageState extends State<ProfilePreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false; // Variable para controlar el estado de guardado
  // Variables para almacenar las preferencias seleccionadas
  String _selectedOccupation = 'Estudiante';
  String _selectedSleepHours = '6-7 horas';
  String _selectedExerciseFrequency = '3-4 veces por semana';
  String _selectedRecreationalTime = '30-60 minutos';
  String _selectedShortTermGoal = 'Mejorar salud física';
  String _selectedLongTermGoal = 'Estabilidad financiera';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

 Future<void> _loadUserPreferences() async {
  try {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception("El documento del usuario no existe en Firestore.");
    }

    final data = docSnapshot.data()!;

    setState(() {
      _selectedOccupation = data['occupation'] ?? _selectedOccupation;
      _selectedSleepHours = data['daily_routines']?['sleep_hours'] ?? _selectedSleepHours;
      _selectedExerciseFrequency =
          data['daily_routines']?['exercise_frequency'] ?? _selectedExerciseFrequency;
      _selectedRecreationalTime =
          data['daily_routines']?['recreational_time'] ?? _selectedRecreationalTime;
      _selectedShortTermGoal = data['goals']?['short_term'] ?? _selectedShortTermGoal;
      _selectedLongTermGoal = data['goals']?['long_term'] ?? _selectedLongTermGoal;
    });
  } catch (e) {
    showToast(message: "Error al cargar las preferencias: $e");
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



Future<void> _saveUserPreferences() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    // Verifica si el documento existe
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      // Si no existe, crea un nuevo documento
      await docRef.set({
        'occupation': _selectedOccupation,
        'daily_routines': {
          'sleep_hours': _selectedSleepHours,
          'exercise_frequency': _selectedExerciseFrequency,
          'recreational_time': _selectedRecreationalTime,
        },
        'goals': {
          'short_term': _selectedShortTermGoal,
          'long_term': _selectedLongTermGoal,
        },
      });
    } else {
      // Si existe, actualiza los datos
      await docRef.update({
        'occupation': _selectedOccupation,
        'daily_routines': {
          'sleep_hours': _selectedSleepHours,
          'exercise_frequency': _selectedExerciseFrequency,
          'recreational_time': _selectedRecreationalTime,
        },
        'goals': {
          'short_term': _selectedShortTermGoal,
          'long_term': _selectedLongTermGoal,
        },
      });
    }

    showToast(message: "Preferencias guardadas exitosamente");
    Navigator.pop(context); // Regresa a la pantalla anterior
  } catch (e) {
    showToast(message: "Error al guardar las preferencias: $e");
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preferencias de Perfil"),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownField(
                      label: "Ocupación",
                      value: _selectedOccupation,
                      items: const ["Estudiante", "Empleado", "Independiente", "Desempleado"],
                      onChanged: (value) {
                        setState(() {
                          _selectedOccupation = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: "Horas de Sueño",
                      value: _selectedSleepHours,
                      items: const ["Menos de 5 horas", "6-7 horas", "8 horas o más"],
                      onChanged: (value) {
                        setState(() {
                          _selectedSleepHours = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: "Frecuencia de Ejercicio",
                      value: _selectedExerciseFrequency,
                      items: const [
                        "Nunca",
                        "1-2 veces por semana",
                        "3-4 veces por semana",
                        "5 o más veces por semana"
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedExerciseFrequency = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: "Tiempo Recreativo Diario",
                      value: _selectedRecreationalTime,
                      items: const ["Menos de 30 minutos", "30-60 minutos", "Más de 1 hora"],
                      onChanged: (value) {
                        setState(() {
                          _selectedRecreationalTime = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: "Meta a Corto Plazo",
                      value: _selectedShortTermGoal,
                      items: const [
                        "Mejorar salud física",
                        "Aprender una nueva habilidad",
                        "Ahorrar dinero"
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedShortTermGoal = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: "Meta a Largo Plazo",
                      value: _selectedLongTermGoal,
                      items: const [
                        "Estabilidad financiera",
                        "Viajar por el mundo",
                        "Lograr equilibrio personal"
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLongTermGoal = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserPreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Guardar Preferencias",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.grey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
