class Department {
  final String id;
  final String name;
  final String region;
  final List<String> tags;

  const Department({
    required this.id,
    required this.name,
    required this.region,
    required this.tags,
  });

  factory Department.fromMap(String id, Map<String, dynamic> data) {
    return Department(
      id: id,
      name: (data['name'] ?? id).toString(),
      region: (data['region'] ?? 'sierra').toString(),
      tags: List<String>.from(data['tags'] ?? const <String>[]),
    );
  }

  static Department placeholder(String id) {
    return Department(
      id: id,
      name: _titleCase(id.replaceAll('_', ' ').replaceAll('-', ' ')),
      region: 'sierra',
      tags: const [],
    );
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final parts = value.split(' ');
    final words = parts.map((part) {
      if (part.isEmpty) return part;
      final lower = part.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    });
    return words.join(' ');
  }
}
