import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart';

class UserModel {
  // 1. Datos de Identificación y Contacto
  String id;
  String nombre;
  String correoElectronico;
  String? fotoPerfil;
  DateTime? fechaNacimiento;

  // 2. Datos Físicos (Bienestar Físico)
  String periodoEjercicio;
  TimeOfDay horaEjercicio;
  TimeOfDay horaDormir;
  double nivelActividad;
  String habitoHidratacion;
  List<String> preferenciasFitness;
  double calidadSueno;
  int horasSueno;
  bool usaWearables;

  // 3. Datos Sociales (Bienestar Social)
  String frecuenciaInteracciones;
  String hobbyPrincipal;
  TimeOfDay horaSalida;
  TimeOfDay horaRegreso;
  String actividadSocialFavorita;
  String usoRedesSociales;
  String tipoEventosPreferidos;
  int interaccionesSignificativas;
  List<String> canalesComunicacion;

  // 4. Datos Emocionales (Bienestar Emocional)
  double nivelEstres;
  String estadoAnimo;
  String estrategiasManejoEstres;
  double frecuenciaAbrumamiento;

  // 5. Datos Intelectuales (Bienestar Intelectual)
  String metodoEstudio;
  double habilidadTecnologica;
  List<String> appsFavoritas;
  int horasEstudio;
  String objetivoAprendizaje;
  String formatoContenidoPreferido;
  String metasPersonales;
  String entornoEstudio;

  // 6. Datos de Uso y Preferencias
  DateTime fechaCreacion;
  DateTime fechaActualizacion;
  List<dynamic> historialInteracciones;
  Map<String, dynamic> preferenciasNotificaciones;

  // Gestión de tareas para el programa de proyectos
  List<String> tareasHechas;
  List<String> tareasAsignadas;
  List<String> tareasPorHacer;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correoElectronico,
    this.fotoPerfil,
    this.fechaNacimiento,
    required this.periodoEjercicio,
    required this.horaEjercicio,
    required this.horaDormir,
    required this.nivelActividad,
    required this.habitoHidratacion,
    required this.preferenciasFitness,
    required this.calidadSueno,
    required this.horasSueno,
    required this.usaWearables,
    required this.frecuenciaInteracciones,
    required this.hobbyPrincipal,
    required this.horaSalida,
    required this.horaRegreso,
    required this.actividadSocialFavorita,
    required this.usoRedesSociales,
    required this.tipoEventosPreferidos,
    required this.interaccionesSignificativas,
    required this.canalesComunicacion,
    required this.nivelEstres,
    required this.estadoAnimo,
    required this.estrategiasManejoEstres,
    required this.frecuenciaAbrumamiento,
    required this.metodoEstudio,
    required this.habilidadTecnologica,
    required this.appsFavoritas,
    required this.horasEstudio,
    required this.objetivoAprendizaje,
    required this.formatoContenidoPreferido,
    required this.metasPersonales,
    required this.entornoEstudio,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.historialInteracciones,
    required this.preferenciasNotificaciones,
    required this.tareasHechas,
    required this.tareasAsignadas,
    required this.tareasPorHacer,
  });

  // 🔹 Convertir un documento Firestore en un UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      nombre: map['nombre'] ?? '',
      correoElectronico: map['correoElectronico'] ?? '',
      fotoPerfil: map['fotoPerfil'],
      fechaNacimiento: map['fechaNacimiento'] != null ? (map['fechaNacimiento'] as Timestamp).toDate() : null,
      periodoEjercicio: map['periodoEjercicio'] ?? '',
      horaEjercicio: _timeOfDayFromString(map['horaEjercicio'] ?? "00:00"),
      horaDormir: _timeOfDayFromString(map['horaDormir'] ?? "00:00"),
      nivelActividad: (map['nivelActividad'] ?? 0).toDouble(),
      habitoHidratacion: map['habitoHidratacion'] ?? '',
      preferenciasFitness: List<String>.from(map['preferenciasFitness'] ?? []),
      calidadSueno: (map['calidadSueno'] ?? 0).toDouble(),
      horasSueno: map['horasSueno'] ?? 0,
      usaWearables: map['usaWearables'] ?? false,
      frecuenciaInteracciones: map['frecuenciaInteracciones'] ?? '',
      hobbyPrincipal: map['hobbyPrincipal'] ?? '',
      horaSalida: _timeOfDayFromString(map['horaSalida'] ?? "00:00"),
      horaRegreso: _timeOfDayFromString(map['horaRegreso'] ?? "00:00"),
      actividadSocialFavorita: map['actividadSocialFavorita'] ?? '',
      usoRedesSociales: map['usoRedesSociales'] ?? '',
      tipoEventosPreferidos: map['tipoEventosPreferidos'] ?? '',
      interaccionesSignificativas: map['interaccionesSignificativas'] ?? 0,
      canalesComunicacion: List<String>.from(map['canalesComunicacion'] ?? []),
      nivelEstres: (map['nivelEstres'] ?? 0).toDouble(),
      estadoAnimo: map['estadoAnimo'] ?? '',
      estrategiasManejoEstres: map['estrategiasManejoEstres'] ?? '',
      frecuenciaAbrumamiento: (map['frecuenciaAbrumamiento'] ?? 0).toDouble(),
      metodoEstudio: map['metodoEstudio'] ?? '',
      habilidadTecnologica: (map['habilidadTecnologica'] ?? 0).toDouble(),
      appsFavoritas: List<String>.from(map['appsFavoritas'] ?? []),
      horasEstudio: map['horasEstudio'] ?? 0,
      objetivoAprendizaje: map['objetivoAprendizaje'] ?? '',
      formatoContenidoPreferido: map['formatoContenidoPreferido'] ?? '',
      metasPersonales: map['metasPersonales'] ?? '',
      entornoEstudio: map['entornoEstudio'] ?? '',
      fechaCreacion: map['fechaCreacion'] != null 
      ? (map['fechaCreacion'] as Timestamp).toDate() 
      : DateTime.now(),
      // ✅ Usa un valor por defecto si es null
      fechaActualizacion: map['fechaActualizacion'] != null 
        ? (map['fechaCreacion'] as Timestamp).toDate() 
        : DateTime.now(),
      historialInteracciones: List<dynamic>.from(map['historialInteracciones'] ?? []),
      preferenciasNotificaciones: Map<String, dynamic>.from(map['preferenciasNotificaciones'] ?? {}),
      tareasHechas: List<String>.from(map['tareasHechas'] ?? []),
      tareasAsignadas: List<String>.from(map['tareasAsignadas'] ?? []),
      tareasPorHacer: List<String>.from(map['tareasPorHacer'] ?? []),
    );
  }

  // 🔹 Convertir UserModel a un Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correoElectronico': correoElectronico,
      'fotoPerfil': fotoPerfil,
      'fechaNacimiento': fechaNacimiento != null ? Timestamp.fromDate(fechaNacimiento!) : null,
      'periodoEjercicio': periodoEjercicio,
      'horaEjercicio': _timeOfDayToString(horaEjercicio),
      'horaDormir': _timeOfDayToString(horaDormir),
      'nivelActividad': nivelActividad,
      'habitoHidratacion': habitoHidratacion,
      'preferenciasFitness': preferenciasFitness,
      'calidadSueno': calidadSueno,
      'horasSueno': horasSueno,
      'usaWearables': usaWearables,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'tareasHechas': tareasHechas,
      'tareasAsignadas': tareasAsignadas,
      'tareasPorHacer': tareasPorHacer,
    };
  }

  // 🔹 Métodos auxiliares para manejar TimeOfDay
  static TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(":");
    return TimeOfDay(hours: int.parse(parts[0]), minutes: int.parse(parts[1]));
  }

  static String _timeOfDayToString(TimeOfDay time) {
    return "${time.hours}:${time.minutes}";
  }
}
