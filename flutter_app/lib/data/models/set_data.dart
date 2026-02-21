/// Ephemeral set data collected during workout session.
/// Used by WorkoutSessionProvider before persistence.
class SetData {
  final String exerciseId;
  final int setNumber;
  final double? prescribedWeight;
  final double actualWeight;
  final int prescribedReps;
  final int actualReps;
  final int? rpe;
  final int? restSeconds;
  final String? overrideReason;

  const SetData({
    required this.exerciseId,
    required this.setNumber,
    this.prescribedWeight,
    required this.actualWeight,
    required this.prescribedReps,
    required this.actualReps,
    this.rpe,
    this.restSeconds,
    this.overrideReason,
  });

  SetData copyWith({
    String? exerciseId,
    int? setNumber,
    double? prescribedWeight,
    double? actualWeight,
    int? prescribedReps,
    int? actualReps,
    int? rpe,
    int? restSeconds,
    String? overrideReason,
  }) =>
      SetData(
        exerciseId: exerciseId ?? this.exerciseId,
        setNumber: setNumber ?? this.setNumber,
        prescribedWeight: prescribedWeight ?? this.prescribedWeight,
        actualWeight: actualWeight ?? this.actualWeight,
        prescribedReps: prescribedReps ?? this.prescribedReps,
        actualReps: actualReps ?? this.actualReps,
        rpe: rpe ?? this.rpe,
        restSeconds: restSeconds ?? this.restSeconds,
        overrideReason: overrideReason ?? this.overrideReason,
      );

  @override
  String toString() => 'SetData('
      'exerciseId: $exerciseId, '
      'setNumber: $setNumber, '
      'actualWeight: $actualWeight, '
      'actualReps: $actualReps'
      ')';
}
