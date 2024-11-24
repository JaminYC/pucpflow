// lib/models/curso_model.dart

// Define la estructura para un Módulo, que contiene varios Temas.
class Modulo {
  final String nombre;
  final List<Tema> temas;

  Modulo({required this.nombre, required this.temas});
}

// Define la estructura para un Curso, que contiene varios Módulos.
class Curso {
  final String nombre;
  final String spreadsheetId;

  Curso({required this.nombre, required this.spreadsheetId});
}

// Define la estructura para una Unidad, que contiene varios Capítulos.
class Unidad {
  final String nombre;
  final String descripcion; // Descripción de la unidad
  final List<Capitulo> capitulos;

  Unidad({required this.nombre, required this.descripcion, required this.capitulos});
}

// Define la estructura para un Capítulo, que contiene varios Temas.
class Capitulo {
  final String nombre;
  final String descripcion; // Descripción del capítulo
  final List<Tema> temas;

  Capitulo({required this.nombre, required this.descripcion, required this.temas});
}

// Define la estructura para un Tema, con propiedades para teoría, recurso, práctica y ayuda.
class Tema {
  final String nombre;
  final String descripcion; // Descripción del tema
  final String recurso;
  final String practica;
  final String ayuda;

  Tema({
    required this.nombre,
    required this.descripcion, // Nueva propiedad para la descripción de cada tema
    required this.recurso,
    required this.practica,
    required this.ayuda,
  });
}
