class RouteModel {
  final String id;
  final String deptId;
  final String name;
  final int durationDays;
  final String difficulty;
  final String summary;
  final List<String> tags;

  const RouteModel({
    required this.id,
    required this.deptId,
    required this.name,
    required this.durationDays,
    required this.difficulty,
    required this.summary,
    required this.tags,
  });

  factory RouteModel.fromMap(String id, Map<String, dynamic> data) {
    return RouteModel(
      id: id,
      deptId: (data['deptId'] ?? '').toString(),
      name: (data['name'] ?? id).toString(),
      durationDays: (data['durationDays'] ?? 0) as int,
      difficulty: (data['difficulty'] ?? 'media').toString(),
      summary: (data['summary'] ?? '').toString(),
      tags: List<String>.from(data['tags'] ?? const <String>[]),
    );
  }
}
