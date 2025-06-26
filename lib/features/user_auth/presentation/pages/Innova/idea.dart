class Idea {
  final String? titulo;
  final String? contexto;
  final String? proceso;
  final String? problema;
  final String? causas;
  final String? herramientas;
  final String? solucion;
  final String? ataque;
  final String? materiales;

  Idea({
    this.titulo,
    this.contexto,
    this.proceso,
    this.problema,
    this.causas,
    this.herramientas,
    this.solucion,
    this.ataque,
    this.materiales,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo?.trim() ?? '',
      'contexto': contexto?.trim() ?? '',
      'proceso': proceso?.trim() ?? '',
      'problema': problema?.trim() ?? '',
      'causas': causas?.trim() ?? '',
      'herramientas': herramientas?.trim() ?? '',
      'solucion': solucion?.trim() ?? '',
      'ataque': ataque?.trim() ?? '',
      'materiales': materiales?.trim() ?? '',
    };
  }

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      titulo: json['titulo'],
      contexto: json['contexto'],
      proceso: json['proceso'],
      problema: json['problema'],
      causas: json['causas'],
      herramientas: json['herramientas'],
      solucion: json['solucion'],
      ataque: json['ataque'],
      materiales: json['materiales'],
    );
  }
}
