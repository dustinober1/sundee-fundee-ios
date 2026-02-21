import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/set_data.dart';
import '../../data/models/workout_session_state.dart';
import 'workout_repository_provider.dart';

class WorkoutSessionNotifier extends Notifier<WorkoutSessionState?> {
  @override
  WorkoutSessionState? build() => null;

  void startSession({
    required String programId,
    required int week,
    required String sessionId,
    String? sessionName,
  }) {
    state = WorkoutSessionState(
      programId: programId,
      week: week,
      sessionId: sessionId,
      sessionName: sessionName,
      setDataMap: {},
      completedSets: {},
      startTime: DateTime.now(),
    );
  }

  void logSet({
    required String exerciseId,
    required int setNumber,
    required double actualWeight,
    required int prescribedReps,
    required int actualReps,
    double? prescribedWeight,
    String? overrideReason,
  }) {
    if (state == null) return;
    final key = '$exerciseId-$setNumber';
    final setData = SetData(
      exerciseId: exerciseId,
      setNumber: setNumber,
      prescribedWeight: prescribedWeight,
      actualWeight: actualWeight,
      prescribedReps: prescribedReps,
      actualReps: actualReps,
      overrideReason: overrideReason,
    );
    state = state!.copyWith(
      setDataMap: {...state!.setDataMap, key: setData},
      completedSets: {...state!.completedSets, key},
    );
  }

  Future<int?> completeWorkout({
    required int userId,
    required int activeCycleId,
  }) async {
    if (state == null) return null;
    final repo = ref.read(workoutRepositoryProvider);
    final workoutId = await repo.saveWorkout(
      userId: userId,
      activeCycleId: activeCycleId,
      programId: state!.programId,
      week: state!.week,
      sessionId: state!.sessionId,
      sets: state!.setDataMap.values.toList(),
      completedAt: DateTime.now(),
      duration: DateTime.now().difference(state!.startTime).inSeconds,
    );
    state = null;
    return workoutId;
  }

  void cancelWorkout() {
    state = null;
  }

  bool get hasActiveSession => state != null;
}

final workoutSessionProvider =
    NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>(
  WorkoutSessionNotifier.new,
);
