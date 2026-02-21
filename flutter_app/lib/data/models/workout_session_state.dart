import 'set_data.dart';

/// Immutable state for an active workout session.
/// Null when no workout is in progress.
class WorkoutSessionState {
  final String programId;
  final int week;
  final String sessionId;
  final String? sessionName;
  final Map<String, SetData> setDataMap; // Key: "$exerciseId-$setNumber"
  final Set<String> completedSets; // Completed set keys
  final DateTime startTime;

  const WorkoutSessionState({
    required this.programId,
    required this.week,
    required this.sessionId,
    this.sessionName,
    required this.setDataMap,
    required this.completedSets,
    required this.startTime,
  });

  WorkoutSessionState copyWith({
    String? programId,
    int? week,
    String? sessionId,
    String? sessionName,
    Map<String, SetData>? setDataMap,
    Set<String>? completedSets,
    DateTime? startTime,
  }) =>
      WorkoutSessionState(
        programId: programId ?? this.programId,
        week: week ?? this.week,
        sessionId: sessionId ?? this.sessionId,
        sessionName: sessionName ?? this.sessionName,
        setDataMap: setDataMap ?? this.setDataMap,
        completedSets: completedSets ?? this.completedSets,
        startTime: startTime ?? this.startTime,
      );

  SetData? getSet(String exerciseId, int setNumber) =>
      setDataMap['$exerciseId-$setNumber'];

  bool isSetCompleted(String exerciseId, int setNumber) =>
      completedSets.contains('$exerciseId-$setNumber');

  int get completedSetCount => completedSets.length;
}
