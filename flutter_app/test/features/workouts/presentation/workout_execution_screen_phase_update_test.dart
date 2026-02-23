import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/lift_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/maxes/providers.dart';
import 'package:sundee_fundee_flutter/features/workouts/presentation/workout_execution_providers.dart';

ProgramSession _session({required double load}) {
  return ProgramSession(
    sessionId: 'session-1',
    sessionName: 'Session 1',
    sessionType: 'Lift',
    focus: 'Sundee-Fundee - Volume',
    exercises: <ProgramExercise>[
      ProgramExercise(
        exercise: 'Back Squat',
        variant: null,
        sets: ExerciseValue.fixed(2),
        reps: ExerciseValue.fixed(5),
        percent1Rm: load,
        restMinutes: 3,
        notes: null,
      ),
    ],
  );
}

LiftMaxModel _squatMax() {
  return LiftMaxModel(
    id: 'max-1',
    userId: 'user-1',
    exerciseId: 'Back Squat',
    repCount: 1,
    weight: 200,
    withStraps: false,
    updatedAt: DateTime.utc(2026, 2, 23, 12),
  );
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      liftMaxesProvider.overrideWithValue(
        AsyncData<List<LiftMaxModel>>(<LiftMaxModel>[_squatMax()]),
      ),
    ],
  );
}

void main() {
  test('applySessionPrescription updates remaining sets to new prescription',
      () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);

    final WorkoutExecutionNotifier notifier =
        container.read(workoutExecutionNotifierProvider.notifier);

    await notifier.initialize(_session(load: 0.8));
    await notifier.applySessionPrescription(_session(load: 0.9));

    final WorkoutExecutionState? state =
        container.read(workoutExecutionNotifierProvider);
    expect(state, isNotNull);

    final List<SetExecutionState> sets = state!.exerciseSets['Back Squat']!;
    expect(sets, hasLength(2));
    expect(sets.first.prescribedWeight, 180);
    expect(sets.last.prescribedWeight, 180);
  });

  test(
      'applySessionPrescription preserves completed sets and updates only remaining',
      () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);

    final WorkoutExecutionNotifier notifier =
        container.read(workoutExecutionNotifierProvider.notifier);

    await notifier.initialize(_session(load: 0.8));
    notifier.updateSet('Back Squat', 0,
        isCompleted: true, weight: 160, reps: 5);
    await notifier.applySessionPrescription(_session(load: 0.9));

    final WorkoutExecutionState? state =
        container.read(workoutExecutionNotifierProvider);
    expect(state, isNotNull);

    final List<SetExecutionState> sets = state!.exerciseSets['Back Squat']!;
    expect(sets.first.isCompleted, isTrue);
    expect(sets.first.prescribedWeight, 160);
    expect(sets.last.isCompleted, isFalse);
    expect(sets.last.prescribedWeight, 180);
  });
}
