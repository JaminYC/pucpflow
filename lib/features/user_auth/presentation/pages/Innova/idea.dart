// 📄 idea.dart

class Idea {
  final String contexto;
  final String proceso;
  final String problema;
  final String causas;
  final String herramientas;
  final String solucion;
  final String ataque;
  final String materiales;

  Idea({
    required this.contexto,
    required this.proceso,
    required this.problema,
    required this.causas,
    required this.herramientas,
    required this.solucion,
    required this.ataque,
    required this.materiales,
  });

  // 🔄 Conversión a JSON para enviar a Firestore o Firebase Functions
  Map<String, dynamic> toJson() {
    return {
      'contexto': contexto,
      'proceso': proceso,
      'problema': problema,
      'causas': causas,
      'herramientas': herramientas,
      'solucion': solucion,
      'ataque': ataque,
      'materiales': materiales,
    };
  }

  // 🔁 Conversión desde JSON
  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      contexto: json['contexto'] ?? '',
      proceso: json['proceso'] ?? '',
      problema: json['problema'] ?? '',
      causas: json['causas'] ?? '',
      herramientas: json['herramientas'] ?? '',
      solucion: json['solucion'] ?? '',
      ataque: json['ataque'] ?? '',
      materiales: json['materiales'] ?? '',
    );
  }
}
