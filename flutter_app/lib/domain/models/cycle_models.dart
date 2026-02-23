import '../enums.dart';
import 'json_utils.dart';

class PeriodLogModel {
  PeriodLogModel({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.flowLevel,
    required this.notes,
  });

  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowLevel flowLevel;
  final String? notes;

  factory PeriodLogModel.fromJson(Map<String, dynamic> json) {
    return PeriodLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      startDate: parseDateTime(json['startDate'], fieldName: 'startDate'),
      endDate: parseNullableDateTime(json['endDate']),
      flowLevel: enumFromString<FlowLevel>(
        FlowLevel.values,
        json['flowLevelRaw'] as String? ?? json['flowLevel'] as String?,
        FlowLevel.medium,
      ),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'flowLevelRaw': flowLevel.name,
      'notes': notes,
    };
  }
}

class SymptomLogModel {
  SymptomLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.symptomId,
    required this.severity,
    required this.notes,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String symptomId;
  final int severity;
  final String? notes;

  factory SymptomLogModel.fromJson(Map<String, dynamic> json) {
    return SymptomLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: parseDateTime(json['date'], fieldName: 'date'),
      symptomId: json['symptomId'] as String? ?? '',
      severity: parseInt(json['severity'], fallback: 1).clamp(1, 5),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'symptomId': symptomId,
      'severity': severity,
      'notes': notes,
    };
  }
}

class BbtLogModel {
  BbtLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.temperature,
    required this.time,
    required this.notes,
  });

  final String id;
  final String userId;
  final DateTime date;
  final double temperature;
  final DateTime? time;
  final String? notes;

  factory BbtLogModel.fromJson(Map<String, dynamic> json) {
    return BbtLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: parseDateTime(json['date'], fieldName: 'date'),
      temperature: parseDouble(json['temperature'], fallback: 0),
      time: parseNullableDateTime(json['time']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'time': time?.toIso8601String(),
      'notes': notes,
    };
  }
}

class SymptomDefinitionModel {
  SymptomDefinitionModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isDefault,
    required this.userId,
  });

  final String id;
  final String name;
  final SymptomCategory category;
  final bool isDefault;
  final String? userId;

  factory SymptomDefinitionModel.fromJson(Map<String, dynamic> json) {
    return SymptomDefinitionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: enumFromString<SymptomCategory>(
        SymptomCategory.values,
        json['categoryRaw'] as String? ?? json['category'] as String?,
        SymptomCategory.physical,
      ),
      isDefault: json['isDefault'] as bool? ?? true,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'categoryRaw': category.name,
      'isDefault': isDefault,
      'userId': userId,
    };
  }
}

class CycleSettingsModel {
  CycleSettingsModel({
    required this.id,
    required this.userId,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.lutealPhaseLength,
    required this.enabledSymptomIds,
    required this.notificationsEnabled,
  });

  final String id;
  final String userId;
  final int averageCycleLength;
  final int averagePeriodLength;
  final int lutealPhaseLength;
  final List<String> enabledSymptomIds;
  final bool notificationsEnabled;

  factory CycleSettingsModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> symptomIds =
        json['enabledSymptomIds'] as List<dynamic>? ?? <dynamic>[];

    return CycleSettingsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      averageCycleLength: parseInt(json['averageCycleLength'], fallback: 28),
      averagePeriodLength: parseInt(json['averagePeriodLength'], fallback: 5),
      lutealPhaseLength: parseInt(json['lutealPhaseLength'], fallback: 14),
      enabledSymptomIds:
          symptomIds.map((dynamic item) => item.toString()).toList(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'lutealPhaseLength': lutealPhaseLength,
      'enabledSymptomIds': enabledSymptomIds,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}

class CycleAdaptationPreferencesModel {
  const CycleAdaptationPreferencesModel({
    required this.id,
    required this.userId,
    this.enabled = true,
    this.readinessScore,
    this.autoApplyDuringWorkout = false,
    this.showAdjustmentDetails = true,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final bool enabled;
  final double? readinessScore;
  final bool autoApplyDuringWorkout;
  final bool showAdjustmentDetails;
  final DateTime? updatedAt;

  factory CycleAdaptationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return CycleAdaptationPreferencesModel(
      id: json['id'] as String? ?? 'programAdaptation',
      userId: json['userId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      readinessScore: json['readinessScore'] == null
          ? null
          : parseDouble(json['readinessScore'], fallback: 0),
      autoApplyDuringWorkout: json['autoApplyDuringWorkout'] as bool? ?? false,
      showAdjustmentDetails: json['showAdjustmentDetails'] as bool? ?? true,
      updatedAt: parseNullableDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'enabled': enabled,
      'readinessScore': readinessScore,
      'autoApplyDuringWorkout': autoApplyDuringWorkout,
      'showAdjustmentDetails': showAdjustmentDetails,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
