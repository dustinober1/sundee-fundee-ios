import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/active_cycle_model.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_workout_model.dart';
import 'package:sundee_fundee_flutter/domain/models/custom_program_model.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/domain/models/lift_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/one_rep_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/personal_record_model.dart';
import 'package:sundee_fundee_flutter/features/migration/data/legacy_migration_orchestrator.dart';
import 'package:sundee_fundee_flutter/features/migration/data/legacy_migration_service.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/repository_interfaces.dart';

void main() {
  group('LegacyMigrationOrchestrator', () {
    test('returns already_complete when migration flag is set', () async {
      final FakeLegacyMigrationService migrationService =
          FakeLegacyMigrationService(
        supports: true,
        completed: true,
        payload: _emptyPayload(),
      );
      final _RepoBundle repos = _RepoBundle();
      final LegacyMigrationOrchestrator orchestrator =
          LegacyMigrationOrchestrator(
        legacyMigrationService: migrationService,
        workoutRepository: repos.workout,
        cycleRepository: repos.cycle,
        liftRepository: repos.lift,
        recordRepository: repos.record,
        customProgramRepository: repos.customProgram,
      );

      final LegacyMigrationResult result = await orchestrator.migrateIfNeeded(
        userId: 'user-1',
      );

      expect(result.status, 'already_complete');
      expect(migrationService.readSnapshotCalls, 0);
      expect(migrationService.markCompleteCalls, 0);
    });

    test('migrates payload and marks migration complete', () async {
      final FakeLegacyMigrationService migrationService =
          FakeLegacyMigrationService(
        supports: true,
        completed: false,
        payload: _payloadWithWorkout(),
      );
      final _RepoBundle repos = _RepoBundle();
      final LegacyMigrationOrchestrator orchestrator =
          LegacyMigrationOrchestrator(
        legacyMigrationService: migrationService,
        workoutRepository: repos.workout,
        cycleRepository: repos.cycle,
        liftRepository: repos.lift,
        recordRepository: repos.record,
        customProgramRepository: repos.customProgram,
      );

      final LegacyMigrationResult result = await orchestrator.migrateIfNeeded(
        userId: 'user-1',
      );

      expect(result.status, 'completed');
      expect(result.expectedRecords, 2);
      expect(result.migratedRecords, 2);
      expect(migrationService.markCompleteCalls, 1);
      expect(repos.workout.savedWorkouts.length, 1);
      expect(repos.workout.savedWorkouts.first.enrollmentId, isNull);
      expect(repos.workout.savedSets.length, 1);
    });

    test('retries transient save errors before succeeding', () async {
      final FakeLegacyMigrationService migrationService =
          FakeLegacyMigrationService(
        supports: true,
        completed: false,
        payload: _payloadWithWorkout(),
      );
      final _RepoBundle repos = _RepoBundle();
      repos.workout.failWorkoutSaveAttemptsRemaining = 2;

      final LegacyMigrationOrchestrator orchestrator =
          LegacyMigrationOrchestrator(
        legacyMigrationService: migrationService,
        workoutRepository: repos.workout,
        cycleRepository: repos.cycle,
        liftRepository: repos.lift,
        recordRepository: repos.record,
        customProgramRepository: repos.customProgram,
      );

      final LegacyMigrationResult result = await orchestrator.migrateIfNeeded(
        userId: 'user-1',
      );

      expect(result.status, 'completed');
      expect(repos.workout.workoutSaveAttempts, 3);
      expect(migrationService.markCompleteCalls, 1);
    });

    test('throws and does not mark complete on persistent failures', () async {
      final FakeLegacyMigrationService migrationService =
          FakeLegacyMigrationService(
        supports: true,
        completed: false,
        payload: _payloadWithWorkout(),
      );
      final _RepoBundle repos = _RepoBundle();
      repos.workout.failWorkoutSaveAttemptsRemaining = 3;

      final LegacyMigrationOrchestrator orchestrator =
          LegacyMigrationOrchestrator(
        legacyMigrationService: migrationService,
        workoutRepository: repos.workout,
        cycleRepository: repos.cycle,
        liftRepository: repos.lift,
        recordRepository: repos.record,
        customProgramRepository: repos.customProgram,
      );

      await expectLater(
        orchestrator.migrateIfNeeded(userId: 'user-1'),
        throwsA(isA<StateError>()),
      );

      expect(migrationService.markCompleteCalls, 0);
    });
  });
}

Map<String, dynamic> _emptyPayload() {
  return <String, dynamic>{
    'workouts': <Map<String, dynamic>>[],
    'completedSets': <Map<String, dynamic>>[],
    'cycles': <Map<String, dynamic>>[],
    'maxLifts': <Map<String, dynamic>>[],
    'oneRepMaxes': <Map<String, dynamic>>[],
    'records': <Map<String, dynamic>>[],
    'customPrograms': <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _payloadWithWorkout() {
  final Map<String, dynamic> payload = _emptyPayload();
  payload['workouts'] = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'workout-1',
      'userId': 'user-1',
      'activeCycleId': 'cycle-1',
      'programId': 'program-1',
      'week': 1,
      'day': 1,
      'sessionId': 'session-1',
      'completedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'duration': 1200,
      'notes': 'great session',
    },
  ];

  payload['completedSets'] = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'set-1',
      'workoutId': 'workout-1',
      'exerciseId': 'back-squat',
      'setNumber': 1,
      'prescribedWeight': 135.0,
      'actualWeight': 135.0,
      'prescribedReps': 5,
      'actualReps': 5,
    },
  ];

  return payload;
}

class FakeLegacyMigrationService extends LegacyMigrationService {
  FakeLegacyMigrationService({
    required this.supports,
    required this.completed,
    required this.payload,
  });

  final bool supports;
  bool completed;
  final Map<String, dynamic> payload;

  int readSnapshotCalls = 0;
  int markCompleteCalls = 0;

  @override
  bool get supportsLegacyMigration => supports;

  @override
  Future<bool> isMigrationComplete({required String userId}) async {
    return completed;
  }

  @override
  Future<Map<String, dynamic>> readLegacySnapshot({
    required String userId,
  }) async {
    readSnapshotCalls += 1;
    return payload;
  }

  @override
  Future<void> markMigrationComplete({required String userId}) async {
    markCompleteCalls += 1;
    completed = true;
  }
}

class _RepoBundle {
  final FakeWorkoutRepository workout = FakeWorkoutRepository();
  final FakeCycleRepository cycle = FakeCycleRepository();
  final FakeLiftRepository lift = FakeLiftRepository();
  final FakeRecordRepository record = FakeRecordRepository();
  final FakeCustomProgramRepository customProgram =
      FakeCustomProgramRepository();
}

class FakeWorkoutRepository implements WorkoutRepository {
  final List<CompletedWorkoutModel> savedWorkouts = <CompletedWorkoutModel>[];
  final List<CompletedSetModel> savedSets = <CompletedSetModel>[];

  int workoutSaveAttempts = 0;
  int failWorkoutSaveAttemptsRemaining = 0;

  @override
  Future<void> saveWorkout({
    required String userId,
    required CompletedWorkoutModel workout,
  }) async {
    workoutSaveAttempts += 1;
    if (failWorkoutSaveAttemptsRemaining > 0) {
      failWorkoutSaveAttemptsRemaining -= 1;
      throw StateError('simulated workout save failure');
    }
    savedWorkouts.add(workout);
  }

  @override
  Future<void> saveCompletedSet({
    required String userId,
    required CompletedSetModel completedSet,
  }) async {
    savedSets.add(completedSet);
  }

  @override
  Stream<List<CompletedSetModel>> watchCompletedSets({
    required String userId,
    required String workoutId,
  }) {
    return Stream<List<CompletedSetModel>>.value(savedSets);
  }

  @override
  Stream<List<CompletedWorkoutModel>> watchWorkouts({required String userId}) {
    return Stream<List<CompletedWorkoutModel>>.value(savedWorkouts);
  }

  @override
  Stream<CompletedWorkoutModel?> watchWorkout({
    required String userId,
    required String workoutId,
  }) {
    final workout = savedWorkouts.firstWhere(
      (w) => w.id == workoutId,
      orElse: () => throw StateError('Workout not found'),
    );
    return Stream.value(workout);
  }

  @override
  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    savedWorkouts.removeWhere((w) => w.id == workoutId);
    savedSets.removeWhere((s) => s.workoutId == workoutId);
  }
}

class FakeCycleRepository implements CycleRepository {
  final List<ActiveCycleModel> cycles = <ActiveCycleModel>[];

  @override
  Future<void> saveActiveCycle({
    required String userId,
    required ActiveCycleModel cycle,
  }) async {
    cycles.add(cycle);
  }

  @override
  Stream<List<ActiveCycleModel>> watchActiveCycles({required String userId}) {
    return Stream<List<ActiveCycleModel>>.value(cycles);
  }

  @override
  Future<void> savePeriodLog({
    required String userId,
    required PeriodLogModel log,
  }) async {}

  @override
  Future<void> deletePeriodLog({
    required String userId,
    required String logId,
  }) async {}

  @override
  Stream<List<PeriodLogModel>> watchPeriodLogs({required String userId}) {
    return Stream.value([]);
  }

  @override
  Future<void> saveSymptomLog({
    required String userId,
    required SymptomLogModel log,
  }) async {}

  @override
  Stream<List<SymptomLogModel>> watchSymptomLogs({required String userId}) {
    return Stream.value([]);
  }

  @override
  Future<void> saveCycleSettings({
    required String userId,
    required CycleSettingsModel settings,
  }) async {}

  @override
  Stream<CycleSettingsModel?> watchCycleSettings({required String userId}) {
    return Stream.value(null);
  }

  @override
  Future<void> saveCycleAdaptationPreferences({
    required String userId,
    required CycleAdaptationPreferencesModel preferences,
  }) async {}

  @override
  Stream<CycleAdaptationPreferencesModel?> watchCycleAdaptationPreferences({
    required String userId,
  }) {
    return Stream.value(null);
  }
}

class FakeLiftRepository implements LiftRepository {
  final List<LiftMaxModel> liftMaxes = <LiftMaxModel>[];
  final List<OneRepMaxModel> oneRepMaxes = <OneRepMaxModel>[];

  @override
  Future<void> saveLiftMax({
    required String userId,
    required LiftMaxModel liftMax,
  }) async {
    liftMaxes.add(liftMax);
  }

  @override
  Future<void> saveOneRepMax({
    required String userId,
    required OneRepMaxModel oneRepMax,
  }) async {
    oneRepMaxes.add(oneRepMax);
  }

  @override
  Stream<List<LiftMaxModel>> watchLiftMaxes({required String userId}) {
    return Stream<List<LiftMaxModel>>.value(liftMaxes);
  }

  @override
  Stream<List<OneRepMaxModel>> watchOneRepMaxes({required String userId}) {
    return Stream<List<OneRepMaxModel>>.value(oneRepMaxes);
  }
}

class FakeRecordRepository implements RecordRepository {
  final List<PersonalRecordModel> records = <PersonalRecordModel>[];

  @override
  Future<void> saveRecord({
    required String userId,
    required PersonalRecordModel record,
  }) async {
    records.add(record);
  }

  @override
  Stream<List<PersonalRecordModel>> watchRecords({required String userId}) {
    return Stream<List<PersonalRecordModel>>.value(records);
  }
}

class FakeCustomProgramRepository implements CustomProgramRepository {
  final List<CustomProgramModel> programs = <CustomProgramModel>[];

  @override
  Future<void> saveCustomProgram({
    required String userId,
    required CustomProgramModel program,
  }) async {
    programs.add(program);
  }

  @override
  Stream<List<CustomProgramModel>> watchCustomPrograms({
    required String userId,
  }) {
    return Stream<List<CustomProgramModel>>.value(programs);
  }
}
