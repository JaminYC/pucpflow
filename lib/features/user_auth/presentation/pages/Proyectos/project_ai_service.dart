import 'package:cloud_functions/cloud_functions.dart';
import 'package:pucpflow/features/skills/models/skill_model.dart';
import 'project_ai_config.dart';

class ProjectAIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Genera un blueprint general/híbrido que no depende 100% de PMI.
  Future<Map<String, dynamic>?> generarBlueprint({
    required List<String> documentosBase64,
    required String nombreProyecto,
    required ProjectBlueprintConfig config,
    String? descripcionBreve,
    List<UserSkillModel>? habilidadesEquipo,
    Map<String, dynamic>? workflowContext,
  }) async {
    final payload = {
      'documentosBase64': documentosBase64,
      'nombreProyecto': nombreProyecto,
      'descripcionBreve': descripcionBreve ?? '',
      'methodology': config.methodology.apiName,
      'config': config.toPayload(),
      'skillMatrix': habilidadesEquipo?.map(_mapUserSkill).toList(),
      'workflowContext': workflowContext,
    };

    try {
      final callable = _functions.httpsCallable(
        'generarBlueprintProyecto',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 480),
        ),
      );
      final result = await callable.call(payload);
      final data = result.data;
      if (data['error'] != null) throw Exception(data['error']);
      return data['blueprint'];
    } catch (e) {
      print('Error generando blueprint contextual: $e');
      return null;
    }
  }

  /// Genera un workflow con IA contextual cruzando skills técnicas/blandas.
  Future<Map<String, dynamic>?> generarWorkflow({
    required String nombreProyecto,
    required ProjectBlueprintConfig config,
    required List<UserSkillModel> habilidadesEquipo,
    WorkflowContextInput? contexto,
    String? objetivo,
    List<String>? macroEntregables,
  }) async {
    final payload = {
      'nombreProyecto': nombreProyecto,
      'objective': objetivo,
      'macroEntregables': macroEntregables,
      'methodology': config.methodology.apiName,
      'skillMatrix': habilidadesEquipo.map(_mapUserSkill).toList(),
      'contexto': contexto?.toMap(),
      'config': config.toPayload(),
    };

    try {
      final callable = _functions.httpsCallable(
        'generarWorkflowContextual',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 240),
        ),
      );
      final result = await callable.call(payload);
      final data = result.data;
      if (data['error'] != null) throw Exception(data['error']);
      return data['workflow'];
    } catch (e) {
      print('Error generando workflow contextual: $e');
      return null;
    }
  }

  Map<String, dynamic> _mapUserSkill(UserSkillModel skill) {
    return {
      'skillId': skill.skillId,
      'name': skill.skillName,
      'sector': skill.sector,
      'level': skill.level,
      'nature': skill.nature.name,
    };
  }
}
