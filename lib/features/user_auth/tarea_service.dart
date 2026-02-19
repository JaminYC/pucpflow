import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';

class TareaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  /// Referencia a la subcolección de tareas de un proyecto
  CollectionReference _tareasRef(String proyectoId) {
    return _firestore.collection("proyectos").doc(proyectoId).collection("tareas");
  }

  Future<void> marcarTareaComoCompletada(Tarea tarea, bool completado, String userId) async {
    // Buscar la tarea en todos los proyectos donde el usuario es responsable
    final proyectosSnapshot = await _firestore.collection("proyectos").get();

    for (var doc in proyectosSnapshot.docs) {
      final tareasSnapshot = await _tareasRef(doc.id)
          .where("titulo", isEqualTo: tarea.titulo)
          .get();

      for (var tareaDoc in tareasSnapshot.docs) {
        final data = tareaDoc.data() as Map<String, dynamic>;
        final responsables = List<String>.from(data["responsables"] ?? []);
        if (responsables.contains(userId)) {
          await tareaDoc.reference.update({
            "completado": completado,
            "estado": completado ? 'completada' : 'pendiente',
            "fechaCompletada": completado ? Timestamp.now() : null,
          });
        }
      }
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
          tareasAsignadas.remove(tarea.titulo);
          tareasPorHacer.remove(tarea.titulo);
          if (!tareasHechas.contains(tarea.titulo)) {
            tareasHechas.add(tarea.titulo);
          }

          await _firestore.collection("users").doc(userId).update({
            "puntosTotales": FieldValue.increment(1),
            'tareasAsignadas': tareasAsignadas,
            'tareasHechas': tareasHechas,
            'tareasPorHacer': tareasPorHacer,
          });
        } else {
          tareasHechas.remove(tarea.titulo);
          if (!tareasAsignadas.contains(tarea.titulo)) {
            tareasAsignadas.add(tarea.titulo);
          }

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
      final tareasSnapshot = await _tareasRef(doc.id)
          .where("titulo", isEqualTo: tarea.titulo)
          .get();

      for (var tareaDoc in tareasSnapshot.docs) {
        final data = tareaDoc.data() as Map<String, dynamic>;
        List<dynamic> responsables = data["responsables"] ?? [];
        if (!responsables.contains(userId)) {
          responsables.add(userId);
          await tareaDoc.reference.update({"responsables": responsables});
        }
      }
    }

    // Agregar la tarea a la lista del usuario
    final userDoc = await _firestore.collection("users").doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        List<String> tareasAsignadas = List<String>.from(userData['tareasAsignadas'] ?? []);
        if (!tareasAsignadas.contains(tarea.titulo)) {
          tareasAsignadas.add(tarea.titulo);
          await _firestore.collection("users").doc(userId).update({
            'tareasAsignadas': tareasAsignadas,
          });
        }
      }
    }
  }

  Future<void> agregarTareaAProyecto(String proyectoId, Tarea tarea, {bool syncToCalendar = true}) async {
    // Si la tarea tiene responsables y fecha programada/límite, intentar sincronizar con Google Calendar
    if (syncToCalendar && tarea.responsables.isNotEmpty && (tarea.fechaProgramada != null || tarea.fechaLimite != null)) {
      try {
        final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
        if (calendarApi != null) {
          for (String responsableId in tarea.responsables) {
            final eventId = await _calendarService.agendarEventoEnCalendario(
              calendarApi,
              tarea,
              responsableId,
            );
            if (eventId != null && tarea.googleCalendarEventId == null) {
              tarea.googleCalendarEventId = eventId;
            }
          }
        }
      } catch (e) {
        print("⚠️ No se pudo sincronizar con Google Calendar: $e");
      }
    }

    await _tareasRef(proyectoId).add(tarea.toJson());
  }

  Future<void> eliminarTareaDeProyecto(String proyectoId, Tarea tarea, {bool syncToCalendar = true}) async {
    // Eliminar evento de Google Calendar si existe
    if (syncToCalendar && tarea.googleCalendarEventId != null) {
      try {
        final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
        if (calendarApi != null) {
          await _calendarService.eliminarEventoDeCalendario(
            calendarApi,
            tarea.googleCalendarEventId!,
          );
        }
      } catch (e) {
        print("⚠️ No se pudo eliminar el evento de Google Calendar: $e");
      }
    }

    // Buscar y eliminar la tarea de la subcolección
    final tareasSnapshot = await _tareasRef(proyectoId)
        .where("titulo", isEqualTo: tarea.titulo)
        .get();

    for (var tareaDoc in tareasSnapshot.docs) {
      await tareaDoc.reference.delete();
    }

    // Eliminar la tarea de las listas de todos los responsables
    for (String userId in tarea.responsables) {
      final userDoc = await _firestore.collection("users").doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          List<String> tareasAsignadas = List<String>.from(userData['tareasAsignadas'] ?? []);
          List<String> tareasHechas = List<String>.from(userData['tareasHechas'] ?? []);
          List<String> tareasPorHacer = List<String>.from(userData['tareasPorHacer'] ?? []);

          tareasAsignadas.remove(tarea.titulo);
          tareasHechas.remove(tarea.titulo);
          tareasPorHacer.remove(tarea.titulo);

          await _firestore.collection("users").doc(userId).update({
            'tareasAsignadas': tareasAsignadas,
            'tareasHechas': tareasHechas,
            'tareasPorHacer': tareasPorHacer,
          });
        }
      }
    }
  }

  Future<void> actualizarTareaEnProyecto(String proyectoId, Tarea original, Tarea editada, {bool syncToCalendar = true}) async {
    // Actualizar evento en Google Calendar si existe
    if (syncToCalendar && editada.googleCalendarEventId != null && editada.responsables.isNotEmpty) {
      try {
        final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
        if (calendarApi != null) {
          await _calendarService.actualizarEventoEnCalendario(
            calendarApi,
            editada.googleCalendarEventId!,
            editada,
            editada.responsables.first,
          );
        }
      } catch (e) {
        print("⚠️ No se pudo actualizar el evento de Google Calendar: $e");
      }
    }

    // Buscar la tarea original por título y reemplazarla
    final tareasSnapshot = await _tareasRef(proyectoId)
        .where("titulo", isEqualTo: original.titulo)
        .get();

    if (tareasSnapshot.docs.isNotEmpty) {
      await tareasSnapshot.docs.first.reference.update(editada.toJson());
    }
  }

  Future<List<Tarea>> obtenerTareasDelProyecto(String proyectoId) async {
    final snapshot = await _tareasRef(proyectoId).get();
    if (snapshot.docs.isEmpty) {
      // Fallback: leer del array legacy si la subcolección está vacía
      final doc = await _firestore.collection("proyectos").doc(proyectoId).get();
      if (!doc.exists) return [];
      final tareasRaw = doc.data()?["tareas"] ?? [];
      if ((tareasRaw as List).isEmpty) return [];
      // Migrar automáticamente a subcolección
      final tareas = tareasRaw.map((e) => Tarea.fromJson(e)).toList();
      await _migrarTareasASubcoleccion(proyectoId, tareas);
      return tareas;
    }
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Tarea.fromJson(data);
    }).toList();
  }

  /// Migra tareas del array legacy a la subcolección
  Future<void> _migrarTareasASubcoleccion(String proyectoId, List<Tarea> tareas) async {
    final batch = _firestore.batch();
    for (var tarea in tareas) {
      final docRef = _tareasRef(proyectoId).doc();
      batch.set(docRef, tarea.toJson());
    }
    batch.commit();
    print("✅ Migradas ${tareas.length} tareas a subcolección para proyecto $proyectoId");
  }

  Future<void> agregarResponsable(String proyectoId, Tarea tarea, String nuevoResponsable) async {
    final tareasSnapshot = await _tareasRef(proyectoId)
        .where("titulo", isEqualTo: tarea.titulo)
        .get();

    for (var tareaDoc in tareasSnapshot.docs) {
      final data = tareaDoc.data() as Map<String, dynamic>;
      List<dynamic> actuales = data["responsables"] ?? [];
      if (!actuales.contains(nuevoResponsable)) {
        actuales.add(nuevoResponsable);
        await tareaDoc.reference.update({"responsables": actuales});
      }
    }
  }

  Future<void> eliminarResponsable(String proyectoId, Tarea tarea, String uid) async {
    final tareasSnapshot = await _tareasRef(proyectoId)
        .where("titulo", isEqualTo: tarea.titulo)
        .get();

    for (var tareaDoc in tareasSnapshot.docs) {
      final data = tareaDoc.data() as Map<String, dynamic>;
      List<dynamic> actuales = data["responsables"] ?? [];
      actuales.remove(uid);
      await tareaDoc.reference.update({"responsables": actuales});
    }
  }

  Future<void> cambiarResponsable(String proyectoId, Tarea tarea, String nuevoResponsable) async {
    final tareasSnapshot = await _tareasRef(proyectoId)
        .where("titulo", isEqualTo: tarea.titulo)
        .get();

    for (var tareaDoc in tareasSnapshot.docs) {
      await tareaDoc.reference.update({"responsables": [nuevoResponsable]});
    }
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
    final proyectosSnapshot = await _firestore.collection("proyectos").get();

    List<String> tareasAsignadasReales = [];
    List<String> tareasHechasReales = [];

    for (var proyectoDoc in proyectosSnapshot.docs) {
      final tareasSnapshot = await _tareasRef(proyectoDoc.id).get();

      for (var tareaDoc in tareasSnapshot.docs) {
        final tareaData = tareaDoc.data() as Map<String, dynamic>;
        List<dynamic> responsables = tareaData["responsables"] ?? [];

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

    await _firestore.collection("users").doc(userId).update({
      'tareasAsignadas': tareasAsignadasReales,
      'tareasHechas': tareasHechasReales,
      'tareasPorHacer': [],
    });
  }
}
