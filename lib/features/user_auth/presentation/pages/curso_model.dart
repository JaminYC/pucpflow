// lib/models/curso_model.dart

// Define la estructura para un Tema dentro de un módulo.
class Tema {
  final String nombre;
  final String teoria;
  final String recurso;
  final String practica;
  final String ayuda;

  Tema({
    required this.nombre,
    required this.teoria,
    required this.recurso,
    required this.practica,
    required this.ayuda,
  });
}

// Define la estructura para un Módulo, que contiene varios Temas.
class Modulo {
  final String nombre;
  final List<Tema> temas;

  Modulo({required this.nombre, required this.temas});
}

// Define la estructura para un Curso, que contiene varios Módulos.
class Curso {
  final String nombre;
  final List<Modulo> modulos;

  Curso({required this.nombre, required this.modulos});
}
