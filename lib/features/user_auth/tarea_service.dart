import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

class TareaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> marcarTareaComoCompletada(Tarea tarea, bool completado, String userId) async {
    final proyectosSnapshot = await _firestore.collection("proyectos").get();

    for (var doc in proyectosSnapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];

      for (int i = 0; i < tareas.length; i++) {
        if (tareas[i]["titulo"] == tarea.titulo &&
            (tareas[i]["responsables"] as List).contains(userId)) {
          tareas[i]["completado"] = completado;
        }
      }

      await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
    }

    if (completado) {
      await _firestore.collection("users").doc(userId).update({
        "puntosTotales": FieldValue.increment(1),
      });
    }
  }

  Future<void> asignarTareaAUsuario(Tarea tarea, String userId) async {
    final proyectosSnapshot = await _firestore.collection("proyectos").get();

    for (var doc in proyectosSnapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];
      bool updated = false;

      for (int i = 0; i < tareas.length; i++) {
        if (tareas[i]["titulo"] == tarea.titulo) {
          List<dynamic> responsables = tareas[i]["responsables"] ?? [];
          if (!responsables.contains(userId)) {
            responsables.add(userId);
            tareas[i]["responsables"] = responsables;
            updated = true;
          }
        }
      }

      if (updated) {
        await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
      }
    }
  }

  Future<void> agregarTareaAProyecto(String proyectoId, Tarea tarea) async {
    await _firestore.collection("proyectos").doc(proyectoId).update({
      "tareas": FieldValue.arrayUnion([tarea.toJson()])
    });
  }

  Future<void> eliminarTareaDeProyecto(String proyectoId, Tarea tarea) async {
    await _firestore.collection("proyectos").doc(proyectoId).update({
      "tareas": FieldValue.arrayRemove([tarea.toJson()])
    });
  }

  Future<void> actualizarTareaEnProyecto(String proyectoId, Tarea original, Tarea editada) async {
    final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
    if (!doc.exists) return;

    List<dynamic> tareas = doc.data()?["tareas"] ?? [];

    // Encuentra y reemplaza
    for (int i = 0; i < tareas.length; i++) {
      if (Tarea.fromJson(tareas[i]).titulo == original.titulo) {
        tareas[i] = editada.toJson();
        break;
      }
    }

    await _firestore.collection("proyectos").doc(proyectoId).update({"tareas": tareas});
  }

  Future<List<Tarea>> obtenerTareasDelProyecto(String proyectoId) async {
    final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
    if (!doc.exists) return [];
    final data = doc.data();
    final tareasRaw = data?["tareas"] ?? [];
    return (tareasRaw as List).map((e) => Tarea.fromJson(e)).toList();
  }

  Future<void> agregarResponsable(String proyectoId, Tarea tarea, String nuevoResponsable) async {
    final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> tareas = data["tareas"] ?? [];

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo) {
        List<dynamic> actuales = tareas[i]["responsables"] ?? [];
        if (!actuales.contains(nuevoResponsable)) {
          actuales.add(nuevoResponsable);
          tareas[i]["responsables"] = actuales;
        }
      }
    }

    await _firestore.collection("proyectos").doc(proyectoId).update({"tareas": tareas});
  }

  Future<void> eliminarResponsable(String proyectoId, Tarea tarea, String uid) async {
    final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> tareas = data["tareas"] ?? [];

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo) {
        List<dynamic> actuales = tareas[i]["responsables"] ?? [];
        actuales.remove(uid);
        tareas[i]["responsables"] = actuales;
      }
    }

    await _firestore.collection("proyectos").doc(proyectoId).update({"tareas": tareas});
  }

  Future<void> cambiarResponsable(String proyectoId, Tarea tarea, String nuevoResponsable) async {
    final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> tareas = data["tareas"] ?? [];

    for (int i = 0; i < tareas.length; i++) {
      if (tareas[i]["titulo"] == tarea.titulo) {
        tareas[i]["responsables"] = [nuevoResponsable];
      }
    }

    await _firestore.collection("proyectos").doc(proyectoId).update({"tareas": tareas});
  }

  bool verificarMatchHabilidad(Tarea tarea, UserModel user) {
    if (tarea.requisitos == null) return true;
    final requisitos = tarea.requisitos;
    final habilidades = user.habilidades;

    for (final entry in requisitos.entries) {
      final nivelUsuario = habilidades[entry.key] ?? 0;
      if (nivelUsuario < entry.value) return false;
    }
    return true;
  }

  int calcularPuntosPorTarea(Tarea tarea) {
    if (tarea.dificultad == "alta") return 3;
    if (tarea.dificultad == "media") return 2;
    return 1;
  }
}
