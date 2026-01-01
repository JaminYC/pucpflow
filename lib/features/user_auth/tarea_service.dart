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

          // Guardar la fecha y hora exacta de completado
          if (completado) {
            tareas[i]["fechaCompletada"] = Timestamp.now();
          } else {
            // Si se desmarca, remover la fecha de completado
            tareas[i]["fechaCompletada"] = null;
          }
        }
      }

      await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
    }

    // Actualizar las listas del usuario
    final userDoc = await _firestore.collection("users").doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        List<String> tareasAsignadas = List<String>.from(userData['tareasAsignadas'] ?? []);
        List<String> tareasHechas = List<String>.from(userData['tareasHechas'] ?? []);
        List<String> tareasPorHacer = List<String>.from(userData['tareasPorHacer'] ?? []);

        if (completado) {
          // Mover de asignadas/por hacer a hechas
          tareasAsignadas.remove(tarea.titulo);
          tareasPorHacer.remove(tarea.titulo);
          if (!tareasHechas.contains(tarea.titulo)) {
            tareasHechas.add(tarea.titulo);
          }

          // Incrementar puntos
          await _firestore.collection("users").doc(userId).update({
            "puntosTotales": FieldValue.increment(1),
            'tareasAsignadas': tareasAsignadas,
            'tareasHechas': tareasHechas,
            'tareasPorHacer': tareasPorHacer,
          });
        } else {
          // Mover de hechas de regreso a asignadas
          tareasHechas.remove(tarea.titulo);
          if (!tareasAsignadas.contains(tarea.titulo)) {
            tareasAsignadas.add(tarea.titulo);
          }

          // Decrementar puntos
          await _firestore.collection("users").doc(userId).update({
            "puntosTotales": FieldValue.increment(-1),
            'tareasAsignadas': tareasAsignadas,
            'tareasHechas': tareasHechas,
            'tareasPorHacer': tareasPorHacer,
          });
        }
      }
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

    // Agregar la tarea a la lista del usuario
    final userDoc = await _firestore.collection("users").doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        List<String> tareasAsignadas = List<String>.from(userData['tareasAsignadas'] ?? []);

        // Agregar a tareasAsignadas si no está ya
        if (!tareasAsignadas.contains(tarea.titulo)) {
          tareasAsignadas.add(tarea.titulo);
          await _firestore.collection("users").doc(userId).update({
            'tareasAsignadas': tareasAsignadas,
          });
        }
      }
    }
  }

  Future<void> agregarTareaAProyecto(String proyectoId, Tarea tarea) async {
    await _firestore.collection("proyectos").doc(proyectoId).update({
      "tareas": FieldValue.arrayUnion([tarea.toJson()])
    });
  }

  Future<void> eliminarTareaDeProyecto(String proyectoId, Tarea tarea) async {
    // Eliminar la tarea del proyecto
    await _firestore.collection("proyectos").doc(proyectoId).update({
      "tareas": FieldValue.arrayRemove([tarea.toJson()])
    });

    // Eliminar la tarea de las listas de todos los responsables
    for (String userId in tarea.responsables) {
      final userDoc = await _firestore.collection("users").doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          List<String> tareasAsignadas = List<String>.from(userData['tareasAsignadas'] ?? []);
          List<String> tareasHechas = List<String>.from(userData['tareasHechas'] ?? []);
          List<String> tareasPorHacer = List<String>.from(userData['tareasPorHacer'] ?? []);

          // Eliminar el título de la tarea de todas las listas
          tareasAsignadas.remove(tarea.titulo);
          tareasHechas.remove(tarea.titulo);
          tareasPorHacer.remove(tarea.titulo);

          // Actualizar el documento del usuario
          await _firestore.collection("users").doc(userId).update({
            'tareasAsignadas': tareasAsignadas,
            'tareasHechas': tareasHechas,
            'tareasPorHacer': tareasPorHacer,
          });
        }
      }
    }
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

  /// Sincroniza las listas de tareas del usuario con las tareas reales de los proyectos
  Future<void> sincronizarTareasDeUsuario(String userId) async {
    // Obtener todas las tareas de todos los proyectos donde el usuario es responsable
    final proyectosSnapshot = await _firestore.collection("proyectos").get();

    List<String> tareasAsignadasReales = [];
    List<String> tareasHechasReales = [];

    for (var proyectoDoc in proyectosSnapshot.docs) {
      final data = proyectoDoc.data();
      List<dynamic> tareas = data["tareas"] ?? [];

      for (var tareaData in tareas) {
        List<dynamic> responsables = tareaData["responsables"] ?? [];

        // Si el usuario es responsable de esta tarea
        if (responsables.contains(userId)) {
          String titulo = tareaData["titulo"] ?? "";
          bool completado = tareaData["completado"] ?? false;

          if (titulo.isNotEmpty) {
            if (completado) {
              tareasHechasReales.add(titulo);
            } else {
              tareasAsignadasReales.add(titulo);
            }
          }
        }
      }
    }

    // Actualizar el documento del usuario con las listas sincronizadas
    await _firestore.collection("users").doc(userId).update({
      'tareasAsignadas': tareasAsignadasReales,
      'tareasHechas': tareasHechasReales,
      'tareasPorHacer': [], // Limpiar tareas por hacer (no se usan actualmente)
    });
  }
}
