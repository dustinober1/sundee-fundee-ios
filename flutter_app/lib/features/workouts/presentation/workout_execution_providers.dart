import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../maxes/providers.dart';
import '../../programs/data/program_repository.dart';
import '../../programs/providers/adapted_program_provider.dart';
import '../../repositories/providers.dart';
import '../data/workout_sync_queue_store.dart';
import '../providers/workout_sync_recovery_provider.dart';
import 'rest_timer_provider.dart';

class SetExecutionState {
  SetExecutionState({
    required this.prescribedReps,
    required this.prescribedWeight,
    required this.actualReps,
    required this.actualWeight,
    this.isCompleted = false,
    this.rpe,
  });

  final int prescribedReps;
  final double prescribedWeight;
  final int actualReps;
  final double actualWeight;
  final bool isCompleted;
  final double? rpe;

  SetExecutionState copyWith({
    int? prescribedReps,
    double? prescribedWeight,
    int? actualReps,
    double? actualWeight,
    bool? isCompleted,
    double? rpe,
  }) {
    return SetExecutionState(
      prescribedReps: prescribedReps ?? this.prescribedReps,
      prescribedWeight: prescribedWeight ?? this.prescribedWeight,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      isCompleted: isCompleted ?? this.isCompleted,
      rpe: rpe ?? this.rpe,
    );
  }
}

class WorkoutExecutionState {
  static const Object _keepValue = Object();

  WorkoutExecutionState({
    required this.startTime,
    required this.exerciseSets,
    this.isSaving = false,
    this.requiresSyncRecovery = false,
    this.syncRecoveryMessage,
    this.pendingSyncWrites = 0,
  });

  final DateTime startTime;
  // Key: exercise.exercise (name/id) -> List of SetExecutionState
  final Map<String, List<SetExecutionState>> exerciseSets;
  final bool isSaving;
  final bool requiresSyncRecovery;
  final String? syncRecoveryMessage;
  final int pendingSyncWrites;

  WorkoutExecutionState copyWith({
    DateTime? startTime,
    Map<String, List<SetExecutionState>>? exerciseSets,
    bool? isSaving,
    bool? requiresSyncRecovery,
    Object? syncRecoveryMessage = _keepValue,
    int? pendingSyncWrites,
  }) {
    return WorkoutExecutionState(
      startTime: startTime ?? this.startTime,
      exerciseSets: exerciseSets ?? this.exerciseSets,
      isSaving: isSaving ?? this.isSaving,
      requiresSyncRecovery: requiresSyncRecovery ?? this.requiresSyncRecovery,
      syncRecoveryMessage: syncRecoveryMessage == _keepValue
          ? this.syncRecoveryMessage
          : syncRecoveryMessage as String?,
      pendingSyncWrites: pendingSyncWrites ?? this.pendingSyncWrites,
    );
  }
}

class EnrollmentProgress {
  const EnrollmentProgress({
    required this.week,
    required this.day,
  });

  final int week;
  final int day;
}

class WorkoutSyncBlockingException implements Exception {
  const WorkoutSyncBlockingException(this.message);

  final String message;

  @override
  String toString() => message;
}

EnrollmentProgress recommendNextEnrollmentProgress({
  required EnrolledProgramModel enrollment,
  required ProgramV2 program,
}) {
  final ProgramWeek currentProgramWeek = program.weeks.firstWhere(
    (ProgramWeek week) => week.week == enrollment.currentWeek,
    orElse: () => program.weeks.last,
  );
  final int maxDay = currentProgramWeek.sessions.length;

  // Day progression stays automatic, but week progression requires
  // explicit manual completion from the enrollment controls.
  if (enrollment.currentDay < maxDay) {
    return EnrollmentProgress(
      week: enrollment.currentWeek,
      day: enrollment.currentDay + 1,
    );
  }

  return EnrollmentProgress(
    week: enrollment.currentWeek,
    day: maxDay,
  );
}

class WorkoutExecutionNotifier extends Notifier<WorkoutExecutionState?> {
  @override
  WorkoutExecutionState? build() {
    return null;
  }

  Future<void> initialize(ProgramSession session) async {
    if (state != null) return;

    final List<LiftMaxModel> liftMaxes = _currentLiftMaxes();

    final Map<String, List<SetExecutionState>> initialSets =
        <String, List<SetExecutionState>>{};
    for (final ProgramExercise exercise in session.exercises) {
      final int numSets = _resolveSetCount(exercise);
      final int numReps = _resolveRepTarget(exercise);
      final double prescribedWeight = _resolvePrescribedWeight(
        exercise: exercise,
        liftMaxes: liftMaxes,
      );

      initialSets[exercise.exercise] = List.generate(
        numSets,
        (_) => SetExecutionState(
          prescribedReps: numReps,
          prescribedWeight: prescribedWeight,
          actualReps: numReps,
          actualWeight: prescribedWeight,
        ),
      );
    }

    state = WorkoutExecutionState(
      startTime: DateTime.now(),
      exerciseSets: initialSets,
    );
  }

  Future<void> applySessionPrescription(ProgramSession session) async {
    if (state == null) return;
    final WorkoutExecutionState currentState = state!;
    final List<LiftMaxModel> liftMaxes = _currentLiftMaxes();
    final Map<String, List<SetExecutionState>> updated =
        Map<String, List<SetExecutionState>>.from(currentState.exerciseSets);

    for (final ProgramExercise exercise in session.exercises) {
      final int targetSets = _resolveSetCount(exercise);
      final int targetReps = _resolveRepTarget(exercise);
      final double targetWeight = _resolvePrescribedWeight(
        exercise: exercise,
        liftMaxes: liftMaxes,
      );
      final List<SetExecutionState> current = List<SetExecutionState>.from(
          updated[exercise.exercise] ?? <SetExecutionState>[]);
      if (current.isEmpty) {
        updated[exercise.exercise] = List<SetExecutionState>.generate(
          targetSets,
          (_) => SetExecutionState(
            prescribedReps: targetReps,
            prescribedWeight: targetWeight,
            actualReps: targetReps,
            actualWeight: targetWeight,
          ),
        );
        continue;
      }

      final int desiredLength =
          targetSets > current.length ? targetSets : current.length;
      final List<SetExecutionState> next = List<SetExecutionState>.generate(
        desiredLength,
        (int index) {
          if (index >= current.length) {
            return SetExecutionState(
              prescribedReps: targetReps,
              prescribedWeight: targetWeight,
              actualReps: targetReps,
              actualWeight: targetWeight,
            );
          }

          final SetExecutionState existing = current[index];
          if (existing.isCompleted) {
            return existing;
          }

          final bool actualWeightMatchesPreviousPrescription =
              (existing.actualWeight - existing.prescribedWeight).abs() < 0.01;
          final bool actualRepsMatchesPreviousPrescription =
              existing.actualReps == existing.prescribedReps;

          return existing.copyWith(
            prescribedReps: targetReps,
            prescribedWeight: targetWeight,
            actualReps: actualRepsMatchesPreviousPrescription
                ? targetReps
                : existing.actualReps,
            actualWeight: actualWeightMatchesPreviousPrescription
                ? targetWeight
                : existing.actualWeight,
          );
        },
      );

      updated[exercise.exercise] = next;
    }

    state = currentState.copyWith(exerciseSets: updated);
  }

  int _resolveSetCount(ProgramExercise exercise) {
    return exercise.sets.fixedValue ?? exercise.sets.minValue ?? 1;
  }

  int _resolveRepTarget(ProgramExercise exercise) {
    return exercise.reps.fixedValue ?? exercise.reps.minValue ?? 1;
  }

  double _resolvePrescribedWeight({
    required ProgramExercise exercise,
    required List<LiftMaxModel> liftMaxes,
  }) {
    if (exercise.percent1Rm == null) {
      return 0.0;
    }

    final List<LiftMaxModel> maxes = liftMaxes.where((LiftMaxModel liftMax) {
      return liftMax.exerciseId == exercise.exercise && liftMax.repCount == 1;
    }).toList();
    if (maxes.isEmpty) {
      return 0.0;
    }

    maxes.sort((LiftMaxModel a, LiftMaxModel b) {
      return b.updatedAt.compareTo(a.updatedAt);
    });
    final double prescribed = maxes.first.weight * exercise.percent1Rm!;
    return (prescribed / 5).round() * 5.0;
  }

  List<LiftMaxModel> _currentLiftMaxes() {
    final AsyncValue<List<LiftMaxModel>> asyncValue =
        ref.read(liftMaxesProvider);
    return asyncValue.asData?.value ?? const <LiftMaxModel>[];
  }

  void updateSet(String exerciseId, int setIndex,
      {int? reps,
      double? weight,
      bool? isCompleted,
      int? restSeconds,
      double? rpe}) {
    if (state == null) return;

    final sets = Map<String, List<SetExecutionState>>.from(state!.exerciseSets);
    final exerciseList = List<SetExecutionState>.from(sets[exerciseId] ?? []);

    if (setIndex >= 0 && setIndex < exerciseList.length) {
      exerciseList[setIndex] = exerciseList[setIndex].copyWith(
        actualReps: reps,
        actualWeight: weight,
        isCompleted: isCompleted,
        rpe: rpe,
      );
      sets[exerciseId] = exerciseList;
      state = state!.copyWith(exerciseSets: sets);

      if (isCompleted == true) {
        ref.read(restTimerProvider.notifier).startTimer(restSeconds ?? 90);
      }
    }
  }

  Future<void> finishWorkout(
      ProgramSession session, int week, int day, String programId) async {
    if (state == null) return;
    final currentState = state!;

    state = currentState.copyWith(
      isSaving: true,
      requiresSyncRecovery: false,
      syncRecoveryMessage: null,
      pendingSyncWrites: 0,
    );

    final AuthSession? authSession =
        ref.read(authSessionStreamProvider).asData?.value;
    final String? userId = authSession?.user?.uid ??
        (authSession?.status == AuthStatus.guest || authSession == null
            ? 'guest'
            : null);
    if (userId == null) {
      state = currentState.copyWith(isSaving: false);
      throw Exception('User not authenticated.');
    }

    final List<PendingWorkoutWriteIntent> intents = await _buildWriteIntents(
      session: session,
      week: week,
      day: day,
      programId: programId,
      userId: userId,
      currentState: currentState,
    );

    final List<PendingWorkoutWriteIntent> failedIntents =
        <PendingWorkoutWriteIntent>[];
    final DateTime attemptAt = DateTime.now();
    for (final PendingWorkoutWriteIntent intent in intents) {
      try {
        await _executeWriteIntent(intent);
      } catch (error) {
        if (_isRecoverableWriteError(error)) {
          failedIntents.add(
            intent.copyWith(
              retryCount: intent.retryCount + 1,
              lastAttemptAt: attemptAt,
            ),
          );
          continue;
        }
        state = currentState.copyWith(isSaving: false);
        rethrow;
      }
    }

    if (failedIntents.isEmpty) {
      ref.read(workoutSyncRecoveryProvider.notifier).clearBlocking();
      await ref.read(workoutSyncRecoveryProvider.notifier).refreshFromQueue();
      state = null;
      return;
    }

    const String blockingMessage =
        'Failed to save workout to cloud. Retry to complete sync.';
    await ref.read(workoutSyncRecoveryProvider.notifier).queuePendingWrites(
          failedIntents,
          message: blockingMessage,
        );
    state = currentState.copyWith(
      isSaving: false,
      requiresSyncRecovery: true,
      syncRecoveryMessage: blockingMessage,
      pendingSyncWrites: failedIntents.length,
    );
    throw const WorkoutSyncBlockingException(blockingMessage);
  }

  Future<bool> retryPendingWrites() async {
    final WorkoutExecutionState? currentState = state;
    final WorkoutSyncRecoveryController controller =
        ref.read(workoutSyncRecoveryProvider.notifier);
    final WorkoutSyncQueueStore store = ref.read(workoutSyncQueueStoreProvider);

    controller.markSyncing();
    final List<PendingWorkoutWriteIntent> pending =
        await store.readPendingWrites();
    if (pending.isEmpty) {
      controller.clearBlocking();
      state = null;
      return true;
    }

    final DateTime attemptAt = DateTime.now();
    final List<PendingWorkoutWriteIntent> remaining =
        <PendingWorkoutWriteIntent>[];
    for (final PendingWorkoutWriteIntent intent in pending) {
      try {
        await _executeWriteIntent(intent);
      } catch (error) {
        remaining.add(
          intent.copyWith(
            retryCount: intent.retryCount + 1,
            lastAttemptAt: attemptAt,
          ),
        );
      }
    }

    await store.writePendingWrites(remaining);
    await controller.refreshFromQueue();
    if (remaining.isEmpty) {
      controller.clearBlocking();
      state = null;
      return true;
    }

    const String blockingMessage =
        'Failed to save workout to cloud. Retry to complete sync.';
    controller.markBlocking(message: blockingMessage);
    if (currentState != null) {
      state = currentState.copyWith(
        isSaving: false,
        requiresSyncRecovery: true,
        syncRecoveryMessage: blockingMessage,
        pendingSyncWrites: remaining.length,
      );
    }
    return false;
  }

  Future<List<PendingWorkoutWriteIntent>> _buildWriteIntents({
    required ProgramSession session,
    required int week,
    required int day,
    required String programId,
    required String userId,
    required WorkoutExecutionState currentState,
  }) async {
    final List<PendingWorkoutWriteIntent> intents =
        <PendingWorkoutWriteIntent>[];
    final String workoutId = const Uuid().v4();
    final DateTime now = DateTime.now();
    final int durationMinutes =
        now.difference(currentState.startTime).inMinutes;
    final EnrolledProgramModel? activeEnrollment =
        ref.read(activeEnrollmentProvider).asData?.value;

    int globalSetNumber = 1;
    for (final ProgramExercise exercise in session.exercises) {
      final List<SetExecutionState> sets =
          currentState.exerciseSets[exercise.exercise] ?? <SetExecutionState>[];
      for (final SetExecutionState setState in sets) {
        if (!setState.isCompleted) {
          continue;
        }
        final CompletedSetModel completedSet = CompletedSetModel(
          id: const Uuid().v4(),
          workoutId: workoutId,
          exerciseId: exercise.exercise,
          setNumber: globalSetNumber++,
          prescribedWeight: setState.prescribedWeight,
          actualWeight: setState.actualWeight,
          prescribedReps: setState.prescribedReps,
          actualReps: setState.actualReps,
          rpe: setState.rpe,
          restSeconds: null,
          overrideReason: null,
        );
        intents.add(
          PendingWorkoutWriteIntent(
            id: const Uuid().v4(),
            type: WorkoutSyncOperationType.completedSet,
            userId: userId,
            payload: completedSet.toJson(),
            createdAt: now,
          ),
        );
      }
    }

    final CompletedWorkoutModel workout = CompletedWorkoutModel(
      id: workoutId,
      userId: userId,
      activeCycleId: '',
      programId: programId,
      enrollmentId: activeEnrollment?.id,
      week: week,
      day: day,
      sessionId: session.id,
      completedAt: now,
      duration: durationMinutes,
      notes: null,
    );
    intents.add(
      PendingWorkoutWriteIntent(
        id: const Uuid().v4(),
        type: WorkoutSyncOperationType.workoutSummary,
        userId: userId,
        payload: workout.toJson(),
        createdAt: now,
      ),
    );

    final List<LiftMaxModel> currentMaxes =
        await ref.read(liftMaxesProvider.future);
    final Map<String, double> newPotentialMaxes = <String, double>{};

    for (final ProgramExercise exercise in session.exercises) {
      final List<SetExecutionState> sets =
          currentState.exerciseSets[exercise.exercise] ?? <SetExecutionState>[];
      for (final SetExecutionState setState in sets) {
        if (!setState.isCompleted) {
          continue;
        }

        final String exerciseId = exercise.exercise;
        final int actualReps = setState.actualReps;
        final double actualWeight = setState.actualWeight;
        final int repsForCalc = actualReps > 10 ? 10 : actualReps;
        double estimated1RM = actualWeight;
        if (repsForCalc > 1) {
          estimated1RM = actualWeight * (1 + (repsForCalc / 30.0));
        }
        estimated1RM = (estimated1RM / 5).round() * 5.0;

        for (final int targetReps in <int>[1, 3, 5, 10]) {
          if (actualReps < targetReps && targetReps != 1) {
            continue;
          }
          double compareWeight = actualWeight;
          if (targetReps == 1) {
            compareWeight = estimated1RM;
          }
          final String key = '${exerciseId}_$targetReps';
          final double currentMax = currentMaxes.where((LiftMaxModel max) {
            return max.exerciseId == exerciseId && max.repCount == targetReps;
          }).fold<double>(
            0,
            (double previous, LiftMaxModel max) {
              return max.weight > previous ? max.weight : previous;
            },
          );
          if (compareWeight > currentMax &&
              compareWeight > (newPotentialMaxes[key] ?? 0)) {
            newPotentialMaxes[key] = compareWeight;
          }
        }
      }
    }

    for (final MapEntry<String, double> entry in newPotentialMaxes.entries) {
      final List<String> parts = entry.key.split('_');
      final LiftMaxModel newMax = LiftMaxModel(
        id: const Uuid().v4(),
        userId: userId,
        exerciseId: parts[0],
        repCount: int.parse(parts[1]),
        weight: entry.value,
        withStraps: false,
        updatedAt: now,
      );
      intents.add(
        PendingWorkoutWriteIntent(
          id: const Uuid().v4(),
          type: WorkoutSyncOperationType.liftMax,
          userId: userId,
          payload: newMax.toJson(),
          createdAt: now,
        ),
      );
    }

    if (activeEnrollment != null) {
      final ProgramV2? activeProgram =
          ref.read(injuryAdaptedActiveProgramProvider).asData?.value;
      if (activeProgram != null) {
        final EnrollmentProgress recommendation =
            recommendNextEnrollmentProgress(
          enrollment: activeEnrollment,
          program: activeProgram,
        );
        intents.add(
          PendingWorkoutWriteIntent(
            id: const Uuid().v4(),
            type: WorkoutSyncOperationType.enrollmentProgress,
            userId: userId,
            payload: <String, dynamic>{
              'enrollmentId': activeEnrollment.id,
              'week': recommendation.week,
              'day': recommendation.day,
            },
            createdAt: now,
          ),
        );
      }
    }

    return intents;
  }

  Future<void> _executeWriteIntent(PendingWorkoutWriteIntent intent) async {
    switch (intent.type) {
      case WorkoutSyncOperationType.completedSet:
        await ref.read(workoutRepositoryProvider).saveCompletedSet(
              userId: intent.userId,
              completedSet: CompletedSetModel.fromJson(intent.payload),
            );
        return;
      case WorkoutSyncOperationType.workoutSummary:
        await ref.read(workoutRepositoryProvider).saveWorkout(
              userId: intent.userId,
              workout: CompletedWorkoutModel.fromJson(intent.payload),
            );
        return;
      case WorkoutSyncOperationType.liftMax:
        await ref.read(liftRepositoryProvider).saveLiftMax(
              userId: intent.userId,
              liftMax: LiftMaxModel.fromJson(intent.payload),
            );
        return;
      case WorkoutSyncOperationType.enrollmentProgress:
        await ref
            .read(enrolledProgramRepositoryProvider)
            .updateEnrollmentProgress(
              userId: intent.userId,
              enrollmentId: intent.payload['enrollmentId'] as String,
              week: (intent.payload['week'] as num).toInt(),
              day: (intent.payload['day'] as num).toInt(),
            );
        return;
    }
  }

  bool _isRecoverableWriteError(Object error) {
    if (error is TimeoutException) {
      return true;
    }
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'unauthenticated' ||
          error.code == 'unavailable' ||
          error.code == 'deadline-exceeded';
    }
    return false;
  }
}

final workoutExecutionNotifierProvider =
    NotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState?>(
        WorkoutExecutionNotifier.new);
