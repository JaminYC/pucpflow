enum ProjectMethodology {
  general,
  pmi,
  agile,
  discovery,
}

extension ProjectMethodologyX on ProjectMethodology {
  String get apiName {
    switch (this) {
      case ProjectMethodology.pmi:
        return 'pmi';
      case ProjectMethodology.agile:
        return 'agile';
      case ProjectMethodology.discovery:
        return 'discovery';
      case ProjectMethodology.general:
      default:
        return 'general';
    }
  }

  String get label {
    switch (this) {
      case ProjectMethodology.pmi:
        return 'PMI / PMBOK';
      case ProjectMethodology.agile:
        return 'Agile / Sprint';
      case ProjectMethodology.discovery:
        return 'Discovery / Innovation';
      case ProjectMethodology.general:
      default:
        return 'Blueprint General';
    }
  }

  bool get supportsPMILayers => this == ProjectMethodology.pmi;
}

class ProjectBlueprintConfig {
  final ProjectMethodology methodology;
  final bool includePMIHints;
  final bool includeSkillMatrix;
  final bool includeWorkflowDraft;
  final List<String> focusAreas;
  final List<String> softSkillFocus;
  final List<String> businessDrivers;
  final Map<String, dynamic>? customContext;

  const ProjectBlueprintConfig({
    this.methodology = ProjectMethodology.general,
    this.includePMIHints = false,
    this.includeSkillMatrix = true,
    this.includeWorkflowDraft = true,
    this.focusAreas = const [],
    this.softSkillFocus = const [],
    this.businessDrivers = const [],
    this.customContext,
  });

  Map<String, dynamic> toPayload() {
    return {
      'methodology': methodology.apiName,
      'includePMIHints': includePMIHints,
      'includeSkillMatrix': includeSkillMatrix,
      'includeWorkflowDraft': includeWorkflowDraft,
      'focusAreas': focusAreas,
      'softSkillFocus': softSkillFocus,
      'businessDrivers': businessDrivers,
      'customContext': customContext,
    };
  }

  ProjectBlueprintConfig copyWith({
    ProjectMethodology? methodology,
    bool? includePMIHints,
    bool? includeSkillMatrix,
    bool? includeWorkflowDraft,
    List<String>? focusAreas,
    List<String>? softSkillFocus,
    List<String>? businessDrivers,
    Map<String, dynamic>? customContext,
  }) {
    return ProjectBlueprintConfig(
      methodology: methodology ?? this.methodology,
      includePMIHints: includePMIHints ?? this.includePMIHints,
      includeSkillMatrix: includeSkillMatrix ?? this.includeSkillMatrix,
      includeWorkflowDraft: includeWorkflowDraft ?? this.includeWorkflowDraft,
      focusAreas: focusAreas ?? this.focusAreas,
      softSkillFocus: softSkillFocus ?? this.softSkillFocus,
      businessDrivers: businessDrivers ?? this.businessDrivers,
      customContext: customContext ?? this.customContext,
    );
  }
}

class WorkflowContextInput {
  final List<String> macroTareas;
  final List<Map<String, dynamic>> historialTareas;
  final List<String> riesgosHumanos;
  final Map<String, dynamic>? blueprint;

  const WorkflowContextInput({
    this.macroTareas = const [],
    this.historialTareas = const [],
    this.riesgosHumanos = const [],
    this.blueprint,
  });

  Map<String, dynamic> toMap() {
    return {
      'macroTareas': macroTareas,
      'historialTareas': historialTareas,
      'riesgosHumanos': riesgosHumanos,
      'blueprint': blueprint,
    };
  }
}
