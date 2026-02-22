import '../enums.dart';
import 'json_utils.dart';

class ActiveCycleModel {
  ActiveCycleModel({
    required this.id,
    required this.userId,
    required this.programId,
    required this.cycleName,
    required this.startDate,
    required this.currentWeek,
    required this.currentSessionId,
    required this.currentPhase,
    required this.status,
  });

  final String id;
  final String userId;
  final String programId;
  final String cycleName;
  final DateTime startDate;
  final int currentWeek;
  final String currentSessionId;
  final String? currentPhase;
  final CycleStatus status;

  factory ActiveCycleModel.fromJson(Map<String, dynamic> json) {
    return ActiveCycleModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      programId: json['programId'] as String? ?? '',
      cycleName: json['cycleName'] as String? ?? '',
      startDate: parseDateTime(json['startDate'], fieldName: 'startDate'),
      currentWeek: parseInt(json['currentWeek'], fallback: 1),
      currentSessionId: json['currentSessionId'] as String? ?? '',
      currentPhase: json['currentPhase'] as String?,
      status: enumFromString<CycleStatus>(
        CycleStatus.values,
        json['statusRaw'] as String? ?? json['status'] as String?,
        CycleStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'programId': programId,
      'cycleName': cycleName,
      'startDate': startDate.toIso8601String(),
      'currentWeek': currentWeek,
      'currentSessionId': currentSessionId,
      'currentPhase': currentPhase,
      'statusRaw': status.name,
    };
  }
}
