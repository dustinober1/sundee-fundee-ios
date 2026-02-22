import 'json_utils.dart';

class CompletedSetModel {
  CompletedSetModel({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.prescribedWeight,
    required this.actualWeight,
    required this.prescribedReps,
    required this.actualReps,
    required this.rpe,
    required this.restSeconds,
    required this.overrideReason,
  });

  final String id;
  final String workoutId;
  final String exerciseId;
  final int setNumber;
  final double? prescribedWeight;
  final double? actualWeight;
  final int? prescribedReps;
  final int? actualReps;
  final double? rpe;
  final int? restSeconds;
  final String? overrideReason;

  factory CompletedSetModel.fromJson(Map<String, dynamic> json) {
    return CompletedSetModel(
      id: json['id'] as String? ?? '',
      workoutId: json['workoutId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      setNumber: parseInt(json['setNumber'], fallback: 1),
      prescribedWeight: (json['prescribedWeight'] as num?)?.toDouble(),
      actualWeight: (json['actualWeight'] as num?)?.toDouble(),
      prescribedReps: (json['prescribedReps'] as num?)?.toInt(),
      actualReps: (json['actualReps'] as num?)?.toInt(),
      rpe: (json['rpe'] as num?)?.toDouble(),
      restSeconds: (json['restSeconds'] as num?)?.toInt(),
      overrideReason: json['overrideReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'prescribedWeight': prescribedWeight,
      'actualWeight': actualWeight,
      'prescribedReps': prescribedReps,
      'actualReps': actualReps,
      'rpe': rpe,
      'restSeconds': restSeconds,
      'overrideReason': overrideReason,
    };
  }
}
