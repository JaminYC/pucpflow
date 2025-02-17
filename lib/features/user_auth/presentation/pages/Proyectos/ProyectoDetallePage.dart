import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';
import 'proyecto_model.dart';
import 'tarea_model.dart';

class ProyectoDetallePage extends StatefulWidget {
  final Proyecto proyecto;

  const ProyectoDetallePage({super.key, required this.proyecto});

  @override
  _ProyectoDetallePageState createState() => _ProyectoDetallePageState();
}

class _ProyectoDetallePageState extends State<ProyectoDetallePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  List<Tarea> tareas = [];

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  /// ✅ **Carga las tareas desde Firebase Firestore**
  Future<void> _cargarTareas() async {
    final proyectoDoc = await _firestore.collection("proyectos").doc(widget.proyecto.id).get();

    if (proyectoDoc.exists) {
      final data = proyectoDoc.data();
      if (data != null && data.containsKey("tareas")) {
        setState(() {
          tareas = (data["tareas"] as List<dynamic>)
              .map((tareaJson) => Tarea.fromJson(tareaJson))
              .toList();
        });
      }
    }
  }
    /// ✅ **Elimina una tarea del proyecto**
  Future<void> _eliminarTarea(Tarea tarea) async {
    await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
      "tareas": FieldValue.arrayRemove([tarea.toJson()])
    });

    setState(() {
      tareas.remove(tarea);
    });

    print("❌ Tarea eliminada");
  }
  /// ✅ **Agrega un participante al proyecto**
  void _mostrarDialogoAgregarParticipante() {
  String email = "";

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.blue[900], // ✅ Fondo azul oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
      ),
      title: const Text(
        "Agregar Participante",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        style: const TextStyle(color: Colors.white), // ✅ Texto blanco
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: "Ingrese el email del participante",
          hintStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3), // ✅ Caja de entrada oscura
        ),
        onChanged: (value) => email = value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () {
            if (email.isNotEmpty) {
              _agregarParticipante(email);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Agregar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}


  Future<void> _agregarParticipante(String email) async {
    final userQuery = await _firestore.collection("users").where("email", isEqualTo: email).get();

    if (userQuery.docs.isEmpty) {
      print("⚠️ Usuario no encontrado");
      return;
    }

    final nuevoParticipanteId = userQuery.docs.first.id;

    await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
      "participantes": FieldValue.arrayUnion([nuevoParticipanteId])
    });

    print("✅ Usuario agregado al proyecto");
  }

  /// ✅ Mostrar lista de participantes con nombres en la UI en tiempo real
/// ✅ Mostrar lista de participantes con nombres en la UI en tiempo real
Widget _mostrarParticipantes() {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.7), // ✅ Fondo oscuro semitransparente
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white, width: 2), // ✅ Contorno blanco
    ),
    child: StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection("proyectos").doc(widget.proyecto.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final proyectoData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> participantes = proyectoData["participantes"] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👥 Integrantes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            if (participantes.isNotEmpty)
              FutureBuilder<List<Map<String, String>>>(
                future: _obtenerParticipantesConNombres(participantes),
                builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final listaParticipantes = snapshot.data!;
                  return Column(
                    children: listaParticipantes.map((usuario) {
                      return Card(
                        color: Colors.blue[900], // ✅ Fondo azul para cada participante
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.white),
                          title: Text(
                            usuario["nombre"]!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            usuario["email"]!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmarEliminarParticipante(usuario["uid"]!),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            else
              const Text("⚠️ No hay participantes aún", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),

            /// 🔹 **Botón para agregar participante**
            Center(
              child: ElevatedButton(
                onPressed: _mostrarDialogoAgregarParticipante,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900], // ✅ Fondo azul oscuro
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
                  ),
                  elevation: 5, // ✅ Sutil sombra para destacar
                ),
                child: const Text(
                  "Agregar Participante",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}





/// ✅ Obtiene los nombres y correos de los participantes desde Firestore
  Future<List<Map<String, String>>> _obtenerParticipantesConNombres(List<dynamic> idsParticipantes) async {
    List<Map<String, String>> participantes = [];

    for (String id in idsParticipantes) {
      final usuarioDoc = await _firestore.collection("users").doc(id).get();
      if (usuarioDoc.exists) {
        participantes.add({
          "uid": id,
          "nombre": usuarioDoc["full_name"] ?? "Usuario Desconocido",
          "email": usuarioDoc["email"] ?? "No Email",
        });
      }
    }

    return participantes;
  }



/// ✅ Diálogo de confirmación antes de eliminar un participante
void _confirmarEliminarParticipante(String participanteId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Eliminar Participante"),
      content: const Text("¿Estás seguro de que quieres eliminar a este participante del proyecto?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () {
            _eliminarParticipante(participanteId);
            Navigator.pop(context);
          },
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );
}



Future<void> _eliminarParticipante(String participanteId) async {
  final proyectoDoc = await _firestore.collection("proyectos").doc(widget.proyecto.id).get();
  if (!proyectoDoc.exists) {
    print("⚠️ Proyecto no encontrado.");
    return;
  }

  List<dynamic> participantes = proyectoDoc.data()?["participantes"] ?? [];

  if (!participantes.contains(participanteId)) {
    print("⚠️ El participante no existe en este proyecto.");
    return;
  }

  await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
    "participantes": FieldValue.arrayRemove([participanteId])
  });

  setState(() {}); // ✅ Refresca la pantalla
  print("✅ Participante eliminado del proyecto.");
}

/// ✅ **Agrega una tarea con fecha, hora y responsable**
void _mostrarDialogoNuevaTarea() {
  String titulo = "";
  int duracion = 60;
  String? responsableSeleccionado;
  DateTime? fechaSeleccionada;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.8), // ✅ Fondo oscuro semitransparente
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // ✅ Bordes redondeados
        side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
      ),
      title: const Text(
        "Nueva Tarea",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔹 **Campo para título**
          TextField(
            style: const TextStyle(color: Colors.white), // ✅ Texto en blanco
            decoration: InputDecoration(
              hintText: "Título de la tarea",
              hintStyle: TextStyle(color: Colors.white70), // ✅ Texto de ayuda tenue
              filled: true,
              fillColor: Colors.blue[900], // ✅ Fondo azul oscuro
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
              ),
            ),
            onChanged: (value) => titulo = value,
          ),
          const SizedBox(height: 10),

          /// 🔹 **Campo para duración**
          TextField(
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Duración en minutos",
              hintStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.blue[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            onChanged: (value) => duracion = int.tryParse(value) ?? 60,
          ),
          const SizedBox(height: 10),

          /// 🔹 **Botón para seleccionar fecha y hora**
          ElevatedButton(
            onPressed: () async {
              DateTime now = DateTime.now();

              // ✅ Seleccionar Fecha
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
              );

              if (pickedDate != null) {
                // ✅ Seleccionar Hora
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null) {
                  fechaSeleccionada = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
              ),
              elevation: 5,
            ),
            child: const Text(
              "📅 Seleccionar Fecha y Hora",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          /// 🔹 **Dropdown para seleccionar responsable**
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection("proyectos").doc(widget.proyecto.id).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              List<String> participantes = List<String>.from(data["participantes"] ?? []);

              return FutureBuilder<List<Map<String, String>>>(
                future: _obtenerParticipantesConNombres(participantes),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  List<Map<String, String>> participantesInfo = snapshot.data!;

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Asignar a Participante",
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.blue[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    dropdownColor: Colors.blue[900], // ✅ Fondo del dropdown azul oscuro
                    style: const TextStyle(color: Colors.white),
                    items: participantesInfo.map((usuario) {
                      return DropdownMenuItem<String>(
                        value: usuario["uid"],
                        child: Text(usuario["nombre"]!, style: const TextStyle(color: Colors.white)), // ✅ Texto blanco
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        responsableSeleccionado = value;
                      });
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () {
            if (titulo.isNotEmpty && fechaSeleccionada != null && responsableSeleccionado != null) {
              _agregarTarea(titulo, duracion, responsableSeleccionado!, fechaSeleccionada!);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("⚠️ Debes ingresar todos los datos"))
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            elevation: 5,
          ),
          child: const Text(
            "Agregar",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}



    /// ✅ **Marca una tarea como completada**
  Future<void> _marcarTareaCompletada(Tarea tarea, bool completado) async {
    final userId = _auth.currentUser!.uid;

    // ✅ Verificamos que el usuario sea el responsable
    if (userId != tarea.responsable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Solo el responsable de la tarea puede marcarla como completada.")),
      );
      return;
    }

    tarea.completado = completado;

    await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
      "tareas": tareas.map((t) => t.toJson()).toList()
    });

    setState(() {});

    print("✅ Tarea marcada como ${completado ? 'completada' : 'pendiente'}");
  }
  

 Future<void> _agregarTarea(String titulo, int duracion, String responsableUid, DateTime fecha) async {
  final nuevaTarea = Tarea(
    titulo: titulo,
    fecha: fecha,
    duracion: duracion,
    colorId: 1,
    responsable: responsableUid,
  );

  await _firestore.collection("proyectos").doc(widget.proyecto.id).update({
    "tareas": FieldValue.arrayUnion([nuevaTarea.toJson()])
  });

  setState(() {
    tareas.add(nuevaTarea);
  });

  print("✅ Tarea agregada en Firestore para el usuario $responsableUid");

  // 🔹 Si el creador de la tarea también es el responsable, la agenda inmediatamente
  final userId = _auth.currentUser!.uid;
  if (responsableUid == userId) {
    final calendarApi = await _calendarService.signInAndGetCalendarApi();
    if (calendarApi != null) {
      bool existeEnCalendario = await _calendarService.verificarTareaEnCalendario(calendarApi, nuevaTarea);
      if (!existeEnCalendario) {
        await _calendarService.agendarEventoEnCalendario(calendarApi, nuevaTarea);
        print("✅ Tarea '${nuevaTarea.titulo}' agregada inmediatamente al Google Calendar del creador.");
      }
    }
  }
}
Future<String> _obtenerNombreUsuario(String uid) async {
  final usuarioDoc = await _firestore.collection("users").doc(uid).get();
  if (usuarioDoc.exists) {
    return usuarioDoc["full_name"] ?? "Desconocido";
  }
  return "Desconocido";
}
 /// ✅ **Mostrar lista de tareas con diseño mejorado**
  Widget _mostrarListaTareas() {
    return Expanded(
      child: tareas.isEmpty
          ? const Center(child: Text("No hay tareas en este proyecto"))
          : ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tarea.completado ? Colors.green[100] : Colors.white,
                    border: Border.all(color: Colors.white, width: 2), // ✅ Contorno blanco
                    borderRadius: BorderRadius.circular(10), // 🔹 Bordes redondeados
                  ),
                  child: ListTile(
                    title: Text(
                      tarea.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tarea.completado ? Colors.green : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 Fecha: ${tarea.fecha}"),
                        FutureBuilder<String>(
                          future: _obtenerNombreUsuario(tarea.responsable), // ✅ Obtiene el nombre en tiempo real
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Text("Cargando...");
                            return Text("👤 Responsable: ${snapshot.data}");
                          },
                        ),
                        Text("⏳ Estado: ${tarea.completado ? '✅ Completado' : '❌ Pendiente'}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: tarea.completado,
                          onChanged: (tarea.responsable == _auth.currentUser!.uid)
                              ? (bool? newValue) {
                                  _marcarTareaCompletada(tarea, newValue ?? false);
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarTarea(tarea),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        /// 🔹 **Fondo con degradado**
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Column(
          children: [
            /// 🔹 **AppBar con título del proyecto**
            AppBar(
              title: Text(widget.proyecto.nombre),
              backgroundColor: Colors.blue[800],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            const SizedBox(height: 10),

            /// 🔹 **Sección de participantes**
            _mostrarParticipantes(),

            /// 🔹 **Lista de tareas con diseño mejorado**
            Expanded(child: _mostrarListaTareas()), 
          ],
        ),
      ],
    ),

    /// ✅ **Botón para agregar nueva tarea con diseño mejorado**
    floatingActionButton: FloatingActionButton(
      onPressed: _mostrarDialogoNuevaTarea,
      backgroundColor: Colors.blue[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white, width: 2), // ✅ Contorno blanco
      ),
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}


}
