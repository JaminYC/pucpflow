import 'package:flutter/material.dart';
import '../Proyectos/tarea_model.dart';
import '../calendar_events_page.dart';

/// Modelo principal del briefing diario
class BriefingDiario {
  final DateTime fecha;
  final String saludo;
  final BriefingMetrics metrics;
  final List<TareaBriefing> tareasPrioritarias;
  final List<TareaBriefing> tareasNormales;
  final List<CalendarEvent> eventos;
  final List<String> insights;
  final List<ConflictoHorario> conflictos;

  BriefingDiario({
    required this.fecha,
    required this.saludo,
    required this.metrics,
    required this.tareasPrioritarias,
    required this.tareasNormales,
    required this.eventos,
    this.insights = const [],
    this.conflictos = const [],
  });

  /// Genera saludo contextual según la hora del día
  static String generarSaludo(String nombreUsuario, DateTime fecha) {
    final hora = fecha.hour;
    String periodo;
    String emoji;

    if (hora >= 5 && hora < 12) {
      periodo = 'Buenos días';
      emoji = '☀️';
    } else if (hora >= 12 && hora < 19) {
      periodo = 'Buenas tardes';
      emoji = '🌤️';
    } else {
      periodo = 'Buenas noches';
      emoji = '🌙';
    }

    return '$emoji $periodo, $nombreUsuario';
  }

  /// Retorna la tarea más crítica del día (por deadline y prioridad)
  TareaBriefing? get tareaMasCritica {
    if (tareasPrioritarias.isEmpty) return null;

    // Ordenar por: deadline cercano primero, luego por prioridad
    final ordenadas = List<TareaBriefing>.from(tareasPrioritarias)
      ..sort((a, b) {
        // Si una tiene hora y otra no, la que tiene hora es más crítica
        if (a.horaInicio != null && b.horaInicio == null) return -1;
        if (a.horaInicio == null && b.horaInicio != null) return 1;

        // Si ambas tienen hora, ordenar por hora
        if (a.horaInicio != null && b.horaInicio != null) {
          return a.horaInicio!.compareTo(b.horaInicio!);
        }

        // Si ninguna tiene hora, ordenar por prioridad
        return b.prioridad.compareTo(a.prioridad);
      });

    return ordenadas.first;
  }
}

/// Métricas calculadas del briefing
class BriefingMetrics {
  final int totalTareas;
  final int tareasCompletadasAyer;
  final int horasEstimadas;
  final int minutosEstimados;
  final int tareasPrioritarias;
  final int rachaActual;
  final double cargaDelDia; // 0.0 - 1.0 (basado en 8 horas laborales)

  BriefingMetrics({
    required this.totalTareas,
    required this.tareasCompletadasAyer,
    required this.horasEstimadas,
    required this.minutosEstimados,
    required this.tareasPrioritarias,
    this.rachaActual = 0,
    required this.cargaDelDia,
  });

  /// Texto descriptivo de la carga del día
  String get descripcionCarga {
    if (cargaDelDia <= 0.5) return 'Ligera';
    if (cargaDelDia <= 0.75) return 'Moderada';
    if (cargaDelDia <= 1.0) return 'Alta';
    return 'Sobrecarga';
  }

  /// Color según la carga del día
  Color get colorCarga {
    if (cargaDelDia <= 0.5) return const Color(0xFF5BE4A8); // Verde
    if (cargaDelDia <= 0.75) return const Color(0xFFFFA851); // Naranja
    if (cargaDelDia <= 1.0) return const Color(0xFFFF6B6B); // Rojo
    return const Color(0xFFB83B5E); // Rojo oscuro
  }

  /// Emoji según la carga
  String get emojiCarga {
    if (cargaDelDia <= 0.5) return '😊';
    if (cargaDelDia <= 0.75) return '💪';
    if (cargaDelDia <= 1.0) return '🔥';
    return '⚠️';
  }

  /// Formato de horas legible (ej: "6h 30min" o "45min")
  String get tiempoFormateado {
    if (horasEstimadas > 0 && minutosEstimados > 0) {
      return '${horasEstimadas}h ${minutosEstimados}min';
    } else if (horasEstimadas > 0) {
      return '${horasEstimadas}h';
    } else {
      return '${minutosEstimados}min';
    }
  }
}

/// Tarea enriquecida para el briefing
class TareaBriefing {
  final String tareaId;
  final String proyectoId;
  final String proyectoNombre;
  final String titulo;
  final DateTime? horaInicio;
  final int duracion; // en minutos
  final int prioridad; // 1=baja, 2=media, 3=alta
  final String? fasePMI;
  final String? area;
  final List<String> responsables;
  final List<String> tareasPrevias;
  final bool tieneDependenciasPendientes;
  final String motivoPrioridad;
  final String? descripcion;

  TareaBriefing({
    required this.tareaId,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.titulo,
    this.horaInicio,
    required this.duracion,
    required this.prioridad,
    this.fasePMI,
    this.area,
    this.responsables = const [],
    this.tareasPrevias = const [],
    this.tieneDependenciasPendientes = false,
    this.motivoPrioridad = '',
    this.descripcion,
  });

  /// Crea TareaBriefing desde Tarea regular
  factory TareaBriefing.fromTarea({
    required Tarea tarea,
    required String tareaId,
    required String proyectoId,
    required String proyectoNombre,
    required bool tieneDependenciasPendientes,
    String motivoPrioridad = '',
  }) {
    // Priorizar fechaProgramada para "cuándo hacer la tarea"
    // Si no hay fechaProgramada, usar fechaLimite o fecha (legacy)
    final horaInicioEfectiva = tarea.fechaProgramada ?? tarea.fechaLimite ?? tarea.fecha;

    return TareaBriefing(
      tareaId: tareaId,
      proyectoId: proyectoId,
      proyectoNombre: proyectoNombre,
      titulo: tarea.titulo,
      horaInicio: horaInicioEfectiva,
      duracion: tarea.duracion,
      prioridad: tarea.prioridad,
      fasePMI: tarea.fasePMI,
      area: tarea.area,
      responsables: tarea.responsables,
      tareasPrevias: tarea.tareasPrevias,
      tieneDependenciasPendientes: tieneDependenciasPendientes,
      motivoPrioridad: motivoPrioridad,
      descripcion: tarea.descripcion,
    );
  }

  /// Color según prioridad
  Color get colorPrioridad {
    switch (prioridad) {
      case 3:
        return const Color(0xFFFF6B6B); // Rojo - Alta
      case 2:
        return const Color(0xFFFFA851); // Naranja - Media
      default:
        return const Color(0xFF5BE4A8); // Verde - Baja
    }
  }

  /// Icono según prioridad
  IconData get iconoPrioridad {
    switch (prioridad) {
      case 3:
        return Icons.priority_high;
      case 2:
        return Icons.remove;
      default:
        return Icons.low_priority;
    }
  }

  /// Texto de prioridad
  String get textoPrioridad {
    switch (prioridad) {
      case 3:
        return 'Alta';
      case 2:
        return 'Media';
      default:
        return 'Baja';
    }
  }

  /// Formato de hora legible
  String? get horaFormateada {
    if (horaInicio == null) return null;
    final hora = horaInicio!.hour.toString().padLeft(2, '0');
    final minuto = horaInicio!.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  /// Duración formateada
  String get duracionFormateada {
    if (duracion >= 60) {
      final horas = duracion ~/ 60;
      final mins = duracion % 60;
      if (mins > 0) {
        return '${horas}h ${mins}min';
      }
      return '${horas}h';
    }
    return '${duracion}min';
  }

  /// Es una tarea crítica si tiene hora cercana o es bloqueante
  bool get esCritica {
    final ahora = DateTime.now();

    // Si tiene dependencias pendientes de otras tareas
    if (tieneDependenciasPendientes) return false;

    // Si es prioridad alta
    if (prioridad == 3) return true;

    // Si tiene hora programada en las próximas 2 horas
    if (horaInicio != null) {
      final diferencia = horaInicio!.difference(ahora);
      if (diferencia.inHours <= 2 && diferencia.inMinutes > 0) {
        return true;
      }
    }

    return false;
  }
}

/// Representa un conflicto de horario detectado
class ConflictoHorario {
  final TareaBriefing tarea1;
  final TareaBriefing tarea2;
  final String descripcion;

  ConflictoHorario({
    required this.tarea1,
    required this.tarea2,
    required this.descripcion,
  });

  /// Genera descripción automática del conflicto
  static String generarDescripcion(TareaBriefing t1, TareaBriefing t2) {
    if (t1.horaInicio != null && t2.horaInicio != null) {
      final fin1 = t1.horaInicio!.add(Duration(minutes: t1.duracion));
      final inicio2 = t2.horaInicio!;

      if (fin1.isAfter(inicio2)) {
        return 'Solapamiento: "${t1.titulo}" termina a las ${_formatearHora(fin1)} '
            'pero "${t2.titulo}" empieza a las ${_formatearHora(inicio2)}';
      }
    }

    return 'Posible conflicto entre "${t1.titulo}" y "${t2.titulo}"';
  }

  static String _formatearHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

/// Configuración del briefing (para guardar en Firestore)
class BriefingConfig {
  final bool habilitado;
  final TimeOfDay horaBriefing;
  final bool incluirEventosGoogle;
  final bool usarVozIA;
  final bool notificacionNocturna;
  final int diasAnticipacion;

  BriefingConfig({
    this.habilitado = true,
    this.horaBriefing = const TimeOfDay(hour: 7, minute: 0),
    this.incluirEventosGoogle = true,
    this.usarVozIA = false,
    this.notificacionNocturna = false,
    this.diasAnticipacion = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'habilitado': habilitado,
      'horaBriefing': '${horaBriefing.hour}:${horaBriefing.minute}',
      'incluirEventosGoogle': incluirEventosGoogle,
      'usarVozIA': usarVozIA,
      'notificacionNocturna': notificacionNocturna,
      'diasAnticipacion': diasAnticipacion,
    };
  }

  factory BriefingConfig.fromJson(Map<String, dynamic> json) {
    final horaParts = (json['horaBriefing'] as String).split(':');
    return BriefingConfig(
      habilitado: json['habilitado'] ?? true,
      horaBriefing: TimeOfDay(
        hour: int.parse(horaParts[0]),
        minute: int.parse(horaParts[1]),
      ),
      incluirEventosGoogle: json['incluirEventosGoogle'] ?? true,
      usarVozIA: json['usarVozIA'] ?? false,
      notificacionNocturna: json['notificacionNocturna'] ?? false,
      diasAnticipacion: json['diasAnticipacion'] ?? 1,
    );
  }
}
