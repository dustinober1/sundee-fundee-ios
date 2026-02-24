import 'json_utils.dart';

class CompletedWorkoutModel {
  CompletedWorkoutModel({
    required this.id,
    required this.userId,
    required this.activeCycleId,
    required this.programId,
    this.enrollmentId,
    required this.week,
    required this.day,
    required this.sessionId,
    required this.completedAt,
    required this.duration,
    required this.notes,
  });

  final String id;
  final String userId;
  final String activeCycleId;
  final String programId;
  final String? enrollmentId;
  final int week;
  final int day;
  final String sessionId;
  final DateTime completedAt;
  final int duration;
  final String? notes;

  factory CompletedWorkoutModel.fromJson(Map<String, dynamic> json) {
    return CompletedWorkoutModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      activeCycleId: json['activeCycleId'] as String? ?? '',
      programId: json['programId'] as String? ?? '',
      enrollmentId: json['enrollmentId'] as String?,
      week: parseInt(json['week'], fallback: 1),
      day: parseInt(json['day'], fallback: 1),
      sessionId: json['sessionId'] as String? ?? '',
      completedAt: parseDateTime(json['completedAt'], fieldName: 'completedAt'),
      duration: parseInt(json['duration'], fallback: 0),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'activeCycleId': activeCycleId,
      'programId': programId,
      'enrollmentId': enrollmentId,
      'week': week,
      'day': day,
      'sessionId': sessionId,
      'completedAt': completedAt.toIso8601String(),
      'duration': duration,
      'notes': notes,
    };
  }
}
