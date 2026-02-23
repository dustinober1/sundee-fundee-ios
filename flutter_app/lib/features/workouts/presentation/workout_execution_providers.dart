import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../../maxes/providers.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../programs/data/program_repository.dart';
import '../../programs/providers/adapted_program_provider.dart';
import '../../repositories/providers.dart';
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
  WorkoutExecutionState({
    required this.startTime,
    required this.exerciseSets,
    this.isSaving = false,
  });

  final DateTime startTime;
  // Key: exercise.exercise (name/id) -> List of SetExecutionState
  final Map<String, List<SetExecutionState>> exerciseSets;
  final bool isSaving;

  WorkoutExecutionState copyWith({
    DateTime? startTime,
    Map<String, List<SetExecutionState>>? exerciseSets,
    bool? isSaving,
  }) {
    return WorkoutExecutionState(
      startTime: startTime ?? this.startTime,
      exerciseSets: exerciseSets ?? this.exerciseSets,
      isSaving: isSaving ?? this.isSaving,
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

    state = currentState.copyWith(isSaving: true);

    final String? userId =
        ref.read(authSessionStreamProvider).asData?.value.user?.uid;
    if (userId == null) {
      state = currentState.copyWith(isSaving: false);
      throw Exception('User not authenticated.');
    }

    final String workoutId = const Uuid().v4();
    final DateTime now = DateTime.now();
    final int durationMinutes =
        now.difference(currentState.startTime).inMinutes;

    final workoutRepository = ref.read(workoutRepositoryProvider);

    // Save each completed set
    int globalSetNumber = 1;
    for (final exercise in session.exercises) {
      final sets = currentState.exerciseSets[exercise.exercise] ?? [];
      for (final s in sets) {
        if (!s.isCompleted) continue;

        final completedSet = CompletedSetModel(
          id: const Uuid().v4(),
          workoutId: workoutId,
          exerciseId: exercise.exercise,
          setNumber: globalSetNumber++,
          prescribedWeight: s.prescribedWeight,
          actualWeight: s.actualWeight,
          prescribedReps: s.prescribedReps,
          actualReps: s.actualReps,
          rpe: s.rpe,
          restSeconds: null,
          overrideReason: null,
        );

        await workoutRepository.saveCompletedSet(
            userId: userId, completedSet: completedSet);
      }
    }

    // Save Workout
    final workout = CompletedWorkoutModel(
      id: workoutId,
      userId: userId,
      activeCycleId: '', // TODO: Get active cycle if available
      programId: programId,
      week: week,
      day: day,
      sessionId: session.id,
      completedAt: now,
      duration: durationMinutes,
      notes: null,
    );

    await workoutRepository.saveWorkout(userId: userId, workout: workout);

    // Update Lift Records (Maxes)
    final liftRepository = ref.read(liftRepositoryProvider);
    final currentMaxesAsync = await ref.read(liftMaxesProvider.future);

    // Track unique (exercise, reps) updates to avoid redundant writes
    final Map<String, double> newPotentialMaxes = {};

    for (final exercise in session.exercises) {
      final sets = currentState.exerciseSets[exercise.exercise] ?? [];
      for (final s in sets) {
        if (!s.isCompleted) continue;

        final exerciseId = exercise.exercise;
        final actualReps = s.actualReps;
        final actualWeight = s.actualWeight;

        // Calculate estimated 1RM using Epley formula: w * (1 + r/30)
        // Cap the multiplier at 10 reps for reasonable strength estimation
        int repsForCalc = actualReps > 10 ? 10 : actualReps;
        double estimated1RM = actualWeight;
        if (repsForCalc > 1) {
          estimated1RM = actualWeight * (1 + (repsForCalc / 30.0));
        }
        // Round to nearest 5 lbs/kgs for cleaner numbers
        estimated1RM = (estimated1RM / 5).round() * 5.0;

        // We track 1, 3, 5, 10 RM
        for (final targetReps in [1, 3, 5, 10]) {
          // Always calculate 1RM, otherwise demand actualReps >= targetReps
          if (actualReps >= targetReps || targetReps == 1) {
            double compareWeight = actualWeight;
            if (targetReps == 1) {
              compareWeight = estimated1RM;
            }

            final key = '${exerciseId}_$targetReps';
            final currentMax = currentMaxesAsync
                .where((m) =>
                    m.exerciseId == exerciseId && m.repCount == targetReps)
                .fold<double>(
                    0, (prev, m) => m.weight > prev ? m.weight : prev);

            if (compareWeight > currentMax &&
                compareWeight > (newPotentialMaxes[key] ?? 0)) {
              newPotentialMaxes[key] = compareWeight;
            }
          }
        }
      }
    }

    // Save the new maxes
    for (final entry in newPotentialMaxes.entries) {
      final parts = entry.key.split('_');
      final exerciseId = parts[0];
      final targetReps = int.parse(parts[1]);
      final weight = entry.value;

      final newMax = LiftMaxModel(
        id: const Uuid().v4(),
        userId: userId,
        exerciseId: exerciseId,
        repCount: targetReps,
        weight: weight,
        withStraps:
            false, // Defaulting to false, could be tracked per set if added to UI
        updatedAt: now,
      );
      await liftRepository.saveLiftMax(userId: userId, liftMax: newMax);
    }

    // Update Enrollment Progress
    final enrollment = ref.read(activeEnrollmentProvider).asData?.value;
    if (enrollment != null) {
      final enrolledRepo = ref.read(enrolledProgramRepositoryProvider);
      final programAsync = ref.read(adaptedActiveProgramProvider).asData?.value;

      if (programAsync != null) {
        final EnrollmentProgress recommendation =
            recommendNextEnrollmentProgress(
          enrollment: enrollment,
          program: programAsync,
        );

        await enrolledRepo.updateEnrollmentProgress(
          userId: userId,
          enrollmentId: enrollment.id,
          week: recommendation.week,
          day: recommendation.day,
        );
      }
    }

    state = null;
  }
}

final workoutExecutionNotifierProvider =
    NotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState?>(
        WorkoutExecutionNotifier.new);
