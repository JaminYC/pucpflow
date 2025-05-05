class Idea {
  final String? contexto;
  final String? proceso;
  final String? problema;
  final String? causas;
  final String? herramientas;
  final String? solucion;
  final String? ataque;
  final String? materiales;

  Idea({
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
      if (contexto != null && contexto!.trim().isNotEmpty) 'contexto': contexto,
      if (proceso != null && proceso!.trim().isNotEmpty) 'proceso': proceso,
      if (problema != null && problema!.trim().isNotEmpty) 'problema': problema,
      if (causas != null && causas!.trim().isNotEmpty) 'causas': causas,
      if (herramientas != null && herramientas!.trim().isNotEmpty) 'herramientas': herramientas,
      if (solucion != null && solucion!.trim().isNotEmpty) 'solucion': solucion,
      if (ataque != null && ataque!.trim().isNotEmpty) 'ataque': ataque,
      if (materiales != null && materiales!.trim().isNotEmpty) 'materiales': materiales,
    };
  }

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
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
