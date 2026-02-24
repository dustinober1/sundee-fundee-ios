import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_workout_model.dart';
import 'package:sundee_fundee_flutter/domain/models/lift_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/one_rep_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/maxes/providers.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/repository_interfaces.dart';
import 'package:sundee_fundee_flutter/features/repositories/providers.dart';
import 'package:sundee_fundee_flutter/features/workouts/data/workout_sync_queue_store.dart';
import 'package:sundee_fundee_flutter/features/workouts/presentation/workout_execution_providers.dart';
import 'package:sundee_fundee_flutter/features/workouts/providers/workout_sync_recovery_provider.dart';

class _FlakyWorkoutRepository implements WorkoutRepository {
  _FlakyWorkoutRepository({required this.shouldFail});

  bool shouldFail;

  @override
  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {}

  @override
  Future<void> saveCompletedSet({
    required String userId,
    required CompletedSetModel completedSet,
  }) async {
    if (shouldFail) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'temporary',
      );
    }
  }

  @override
  Future<void> saveWorkout({
    required String userId,
    required CompletedWorkoutModel workout,
  }) async {
    if (shouldFail) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'temporary',
      );
    }
  }

  @override
  Stream<List<CompletedSetModel>> watchCompletedSets({
    required String userId,
    required String workoutId,
  }) {
    return Stream<List<CompletedSetModel>>.value(
      <CompletedSetModel>[],
    );
  }

  @override
  Stream<CompletedWorkoutModel?> watchWorkout({
    required String userId,
    required String workoutId,
  }) {
    return Stream<CompletedWorkoutModel?>.value(null);
  }

  @override
  Stream<List<CompletedWorkoutModel>> watchWorkouts({required String userId}) {
    return Stream<List<CompletedWorkoutModel>>.value(
      <CompletedWorkoutModel>[],
    );
  }
}

class _FlakyLiftRepository implements LiftRepository {
  _FlakyLiftRepository({required this.shouldFail});

  bool shouldFail;

  @override
  Future<void> saveLiftMax({
    required String userId,
    required LiftMaxModel liftMax,
  }) async {
    if (shouldFail) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'temporary',
      );
    }
  }

  @override
  Future<void> saveOneRepMax({
    required String userId,
    required OneRepMaxModel oneRepMax,
  }) async {}

  @override
  Stream<List<LiftMaxModel>> watchLiftMaxes({required String userId}) {
    return Stream<List<LiftMaxModel>>.value(<LiftMaxModel>[]);
  }

  @override
  Stream<List<OneRepMaxModel>> watchOneRepMaxes({required String userId}) {
    return Stream<List<OneRepMaxModel>>.value(<OneRepMaxModel>[]);
  }
}

ProgramSession _session() {
  return ProgramSession(
    sessionId: 'session-1',
    sessionName: 'Session 1',
    sessionType: 'Lift',
    focus: 'Strength',
    exercises: <ProgramExercise>[
      ProgramExercise(
        exercise: 'Back Squat',
        variant: null,
        sets: ExerciseValue.fixed(1),
        reps: ExerciseValue.fixed(5),
        percent1Rm: 0.8,
        restMinutes: 3,
        notes: null,
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('finishWorkout queues pending writes and surfaces blocking sync state',
      () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FlakyWorkoutRepository workoutRepo =
        _FlakyWorkoutRepository(shouldFail: true);
    final _FlakyLiftRepository liftRepo =
        _FlakyLiftRepository(shouldFail: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authSessionStreamProvider.overrideWith(
          (Ref ref) => Stream<AuthSession>.value(
            const AuthSession(status: AuthStatus.guest),
          ),
        ),
        workoutRepositoryProvider.overrideWith((Ref ref) => workoutRepo),
        liftRepositoryProvider.overrideWith((Ref ref) => liftRepo),
        liftMaxesProvider.overrideWithValue(
          const AsyncData<List<LiftMaxModel>>(<LiftMaxModel>[]),
        ),
        workoutSyncQueueStoreProvider.overrideWith(
          (Ref ref) => WorkoutSyncQueueStore(sharedPreferences: prefs),
        ),
      ],
    );
    addTearDown(container.dispose);

    final WorkoutExecutionNotifier notifier =
        container.read(workoutExecutionNotifierProvider.notifier);
    await notifier.initialize(_session());
    notifier.updateSet(
      'Back Squat',
      0,
      isCompleted: true,
      reps: 5,
      weight: 135,
    );

    await expectLater(
      () => notifier.finishWorkout(_session(), 1, 1, 'program-1'),
      throwsA(isA<WorkoutSyncBlockingException>()),
    );

    final WorkoutExecutionState? state =
        container.read(workoutExecutionNotifierProvider);
    expect(state, isNotNull);
    expect(state!.requiresSyncRecovery, isTrue);
    expect(state.pendingSyncWrites, greaterThan(0));

    final List<PendingWorkoutWriteIntent> pending =
        await container.read(workoutSyncQueueStoreProvider).readPendingWrites();
    expect(pending, isNotEmpty);
  });

  test('retryPendingWrites replays queue and clears blocking state on success',
      () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FlakyWorkoutRepository workoutRepo =
        _FlakyWorkoutRepository(shouldFail: true);
    final _FlakyLiftRepository liftRepo =
        _FlakyLiftRepository(shouldFail: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authSessionStreamProvider.overrideWith(
          (Ref ref) => Stream<AuthSession>.value(
            const AuthSession(status: AuthStatus.guest),
          ),
        ),
        workoutRepositoryProvider.overrideWith((Ref ref) => workoutRepo),
        liftRepositoryProvider.overrideWith((Ref ref) => liftRepo),
        liftMaxesProvider.overrideWithValue(
          const AsyncData<List<LiftMaxModel>>(<LiftMaxModel>[]),
        ),
        workoutSyncQueueStoreProvider.overrideWith(
          (Ref ref) => WorkoutSyncQueueStore(sharedPreferences: prefs),
        ),
      ],
    );
    addTearDown(container.dispose);

    final WorkoutExecutionNotifier notifier =
        container.read(workoutExecutionNotifierProvider.notifier);
    await notifier.initialize(_session());
    notifier.updateSet(
      'Back Squat',
      0,
      isCompleted: true,
      reps: 5,
      weight: 135,
    );

    await expectLater(
      () => notifier.finishWorkout(_session(), 1, 1, 'program-1'),
      throwsA(isA<WorkoutSyncBlockingException>()),
    );

    workoutRepo.shouldFail = false;
    liftRepo.shouldFail = false;

    final bool synced = await notifier.retryPendingWrites();
    expect(synced, isTrue);
    expect(container.read(workoutExecutionNotifierProvider), isNull);

    final List<PendingWorkoutWriteIntent> pending =
        await container.read(workoutSyncQueueStoreProvider).readPendingWrites();
    expect(pending, isEmpty);
    expect(
      container.read(workoutSyncRecoveryProvider).pendingWriteCount,
      0,
    );
  });
}
