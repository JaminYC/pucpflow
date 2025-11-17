/// Modelo para el perfil profesional extraído del CV
class CVProfileModel {
  final String name;
  final String email;
  final String phone;
  final String summary;
  final List<ExperienceModel> experience;
  final List<EducationModel> education;

  CVProfileModel({
    required this.name,
    required this.email,
    this.phone = '',
    this.summary = '',
    this.experience = const [],
    this.education = const [],
  });

  factory CVProfileModel.fromMap(Map<String, dynamic> map) {
    return CVProfileModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      summary: map['summary'] ?? '',
      experience: (map['experience'] as List<dynamic>?)
              ?.map((e) => ExperienceModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (map['education'] as List<dynamic>?)
              ?.map((e) => EducationModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'summary': summary,
      'experience': experience.map((e) => e.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
    };
  }
}

/// Modelo de experiencia laboral
class ExperienceModel {
  final String title;
  final String company;
  final String duration;
  final String description;

  ExperienceModel({
    required this.title,
    required this.company,
    this.duration = '',
    this.description = '',
  });

  factory ExperienceModel.fromMap(Map<String, dynamic> map) {
    return ExperienceModel(
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      duration: map['duration'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'duration': duration,
      'description': description,
    };
  }
}

/// Modelo de educación
class EducationModel {
  final String degree;
  final String institution;
  final String year;

  EducationModel({
    required this.degree,
    required this.institution,
    this.year = '',
  });

  factory EducationModel.fromMap(Map<String, dynamic> map) {
    return EducationModel(
      degree: map['degree'] ?? '',
      institution: map['institution'] ?? '',
      year: map['year'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'degree': degree,
      'institution': institution,
      'year': year,
    };
  }
}
