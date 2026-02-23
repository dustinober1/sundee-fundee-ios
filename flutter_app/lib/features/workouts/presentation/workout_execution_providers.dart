import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../../maxes/providers.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../programs/data/program_repository.dart';
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

class WorkoutExecutionNotifier extends Notifier<WorkoutExecutionState?> {
  @override
  WorkoutExecutionState? build() {
    return null;
  }

  void initialize(ProgramSession session) {
    if (state != null) return;

    final liftMaxes = ref.read(liftMaxesProvider).asData?.value ?? [];

    final Map<String, List<SetExecutionState>> initialSets = {};
    for (final exercise in session.exercises) {
      final int numSets = exercise.sets.fixedValue ?? 1;
      final int numReps =
          exercise.reps.fixedValue ?? exercise.reps.minValue ?? 1;

      double prescribedWeight = 0.0;
      if (exercise.percent1Rm != null) {
        // Find 1RM
        final maxes = liftMaxes
            .where((l) => l.exerciseId == exercise.exercise && l.repCount == 1)
            .toList();
        if (maxes.isNotEmpty) {
          maxes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          prescribedWeight = maxes.first.weight * exercise.percent1Rm!;
          // Round to nearest 5
          prescribedWeight = (prescribedWeight / 5).round() * 5.0;
        }
      }

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

        // We track 1, 3, 5, 10 RM
        for (final targetReps in [1, 3, 5, 10]) {
          if (actualReps >= targetReps) {
            final key = '${exerciseId}_$targetReps';
            final currentMax = currentMaxesAsync.where((m) => m.exerciseId == exerciseId && m.repCount == targetReps).fold<double>(0, (prev, m) => m.weight > prev ? m.weight : prev);
            
            if (actualWeight > currentMax && actualWeight > (newPotentialMaxes[key] ?? 0)) {
              newPotentialMaxes[key] = actualWeight;
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
        withStraps: false, // Defaulting to false, could be tracked per set if added to UI
        updatedAt: now,
      );
      await liftRepository.saveLiftMax(userId: userId, liftMax: newMax);
    }

    // Update Enrollment Progress
    final enrollment = ref.read(activeEnrollmentProvider).asData?.value;
    if (enrollment != null) {
      final enrolledRepo = ref.read(enrolledProgramRepositoryProvider);
      final programAsync = ref.read(activeProgramProvider).asData?.value;

      if (programAsync != null) {
        int nextDay = day + 1;
        int nextWeek = week;

        // Check if we need to advance the week
        final currentProgramWeek = programAsync.weeks.firstWhere(
            (w) => w.week == week,
            orElse: () => programAsync.weeks.last);
        if (nextDay > currentProgramWeek.sessions.length) {
          nextDay = 1;
          nextWeek++;
        }

        if (nextWeek > programAsync.durationWeeks) {
          // Program completed
          await enrolledRepo.completeEnrollment(
              userId: userId, enrollmentId: enrollment.id);
        } else {
          // Advance progress
          await enrolledRepo.updateEnrollmentProgress(
            userId: userId,
            enrollmentId: enrollment.id,
            week: nextWeek,
            day: nextDay,
          );
        }
      }
    }

    state = null;
  }
}

final workoutExecutionNotifierProvider =
    NotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState?>(
        WorkoutExecutionNotifier.new);
