import 'package:cloud_firestore/cloud_firestore.dart';

class SignalModel {
  final String weatherSummary;
  final List<String> alerts;
  final Timestamp? updatedAt;

  const SignalModel({
    required this.weatherSummary,
    required this.alerts,
    required this.updatedAt,
  });

  factory SignalModel.fromMap(Map<String, dynamic> data) {
    return SignalModel(
      weatherSummary: (data['weatherSummary'] ?? 'Sin datos').toString(),
      alerts: List<String>.from(data['alerts'] ?? const <String>[]),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static SignalModel placeholder() {
    return const SignalModel(
      weatherSummary: 'Sin datos',
      alerts: [],
      updatedAt: null,
    );
  }
}
