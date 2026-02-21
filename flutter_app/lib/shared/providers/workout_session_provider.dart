import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/set_data.dart';
import '../../data/models/workout_session_state.dart';
import '../../core/recommendations/calculations.dart';
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

  /// Complete workout and process 1RMs + PRs.
  /// Returns record with workoutId and any detected PRs.
  Future<({int? workoutId, List<String> weightPRs, List<String> volumePRs})?> completeWorkout({
    required int userId,
    required int activeCycleId,
  }) async {
    if (state == null) return null;
    final repo = ref.read(workoutRepositoryProvider);
    final now = DateTime.now();

    // 1. Save workout
    final workoutId = await repo.saveWorkout(
      userId: userId,
      activeCycleId: activeCycleId,
      programId: state!.programId,
      week: state!.week,
      sessionId: state!.sessionId,
      sets: state!.setDataMap.values.toList(),
      completedAt: now,
      duration: now.difference(state!.startTime).inSeconds,
    );

    // 2. Group sets by exercise
    final setsByExercise = <String, List<SetData>>{};
    for (final set in state!.setDataMap.values) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []);
      setsByExercise[set.exerciseId]!.add(set);
    }

    final weightPRs = <String>[];
    final volumePRs = <String>[];

    // 3. For each exercise: check PRs FIRST (before 1RM save), then save 1RM
    // CRITICAL ORDER: PR detection queries OneRepMaxes BEFORE saving current session's 1RM.
    // This preserves the pre-session baseline for accurate PR comparison.
    for (final entry in setsByExercise.entries) {
      final exerciseId = entry.key;
      final sets = entry.value;

      // Get max weight lifted this session (used for weight PR check)
      final maxWeight =
          sets.map((s) => s.actualWeight).reduce((a, b) => a > b ? a : b);

      // Calculate session volume (used for volume PR check)
      final sessionVolume =
          sets.fold<double>(0, (sum, s) => sum + s.actualWeight * s.actualReps);

      // ===== STEP A: Check PRs BEFORE saving 1RM =====
      // Weight PR - compare against historical max (pre-session)
      final isWeightPR = await repo.checkAndSaveWeightPR(
        userId: userId,
        exerciseId: exerciseId,
        newWeight: maxWeight,
        workoutId: workoutId,
        date: now,
      );
      if (isWeightPR) weightPRs.add(exerciseId);

      // Volume PR - compare against historical best (pre-session)
      final isVolumePR = await repo.checkAndSaveVolumePR(
        userId: userId,
        exerciseId: exerciseId,
        currentVolume: sessionVolume,
        workoutId: workoutId,
        date: now,
      );
      if (isVolumePR) volumePRs.add(exerciseId);

      // ===== STEP B: Save 1RM AFTER PR checks =====
      // Calculate max estimated 1RM from this session
      final max1RM = sets
          .map((s) => epley(s.actualWeight, s.actualReps))
          .reduce((a, b) => a > b ? a : b);

      // Save 1RM record (now safe - PR checks already completed)
      await repo.saveOneRepMax(
        userId: userId,
        exerciseId: exerciseId,
        weight: max1RM,
        date: now,
      );
    }

    state = null;
    return (workoutId: workoutId, weightPRs: weightPRs, volumePRs: volumePRs);
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
