import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../domain/models/active_cycle_model.dart';
import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/custom_program_model.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../../domain/models/one_rep_max_model.dart';
import '../../../domain/models/personal_record_model.dart';
import '../../repositories/domain/repository_interfaces.dart';
import 'legacy_migration_service.dart';

class LegacyMigrationResult {
  const LegacyMigrationResult({
    required this.status,
    required this.expectedRecords,
    required this.migratedRecords,
  });

  final String status;
  final int expectedRecords;
  final int migratedRecords;
}

class LegacyMigrationOrchestrator {
  LegacyMigrationOrchestrator({
    required LegacyMigrationService legacyMigrationService,
    required WorkoutRepository workoutRepository,
    required CycleRepository cycleRepository,
    required LiftRepository liftRepository,
    required RecordRepository recordRepository,
    required CustomProgramRepository customProgramRepository,
    FirebaseFirestore? firestore,
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  })  : _legacyMigrationService = legacyMigrationService,
        _workoutRepository = workoutRepository,
        _cycleRepository = cycleRepository,
        _liftRepository = liftRepository,
        _recordRepository = recordRepository,
        _customProgramRepository = customProgramRepository,
        _firestore = firestore,
        _analytics = analytics,
        _crashlytics = crashlytics;

  final LegacyMigrationService _legacyMigrationService;
  final WorkoutRepository _workoutRepository;
  final CycleRepository _cycleRepository;
  final LiftRepository _liftRepository;
  final RecordRepository _recordRepository;
  final CustomProgramRepository _customProgramRepository;
  final FirebaseFirestore? _firestore;
  final FirebaseAnalytics? _analytics;
  final FirebaseCrashlytics? _crashlytics;

  Future<LegacyMigrationResult> migrateIfNeeded({
    required String userId,
  }) async {
    if (!_legacyMigrationService.supportsLegacyMigration) {
      return const LegacyMigrationResult(
        status: 'unsupported_platform',
        expectedRecords: 0,
        migratedRecords: 0,
      );
    }

    final bool completed = await _legacyMigrationService.isMigrationComplete(
      userId: userId,
    );
    if (completed) {
      return const LegacyMigrationResult(
        status: 'already_complete',
        expectedRecords: 0,
        migratedRecords: 0,
      );
    }

    final Map<String, dynamic> payload =
        await _legacyMigrationService.readLegacySnapshot(userId: userId);

    final int expectedRecords = _countExpectedRecords(payload);
    await _writeMigrationState(
      userId: userId,
      state: 'in_progress',
      expectedRecords: expectedRecords,
      migratedRecords: 0,
    );

    final List<String> failures = <String>[];
    int migratedRecords = 0;

    try {
      migratedRecords += await _migrateWorkouts(
        userId: userId,
        payload: payload,
        failures: failures,
      );
      migratedRecords += await _migrateCycles(
        userId: userId,
        payload: payload,
        failures: failures,
      );
      migratedRecords += await _migrateLifts(
        userId: userId,
        payload: payload,
        failures: failures,
      );
      migratedRecords += await _migrateRecords(
        userId: userId,
        payload: payload,
        failures: failures,
      );
      migratedRecords += await _migrateCustomPrograms(
        userId: userId,
        payload: payload,
        failures: failures,
      );

      if (failures.isNotEmpty) {
        throw StateError('Migration had ${failures.length} failed records.');
      }

      if (migratedRecords != expectedRecords) {
        throw StateError(
          'Migration verification failed. expected=$expectedRecords migrated=$migratedRecords',
        );
      }

      await _legacyMigrationService.markMigrationComplete(userId: userId);
      await _writeMigrationState(
        userId: userId,
        state: 'completed',
        expectedRecords: expectedRecords,
        migratedRecords: migratedRecords,
      );

      await _analytics?.logEvent(
        name: 'legacy_migration_completed',
        parameters: <String, Object>{
          'expected_records': expectedRecords,
          'migrated_records': migratedRecords,
        },
      );

      return LegacyMigrationResult(
        status: 'completed',
        expectedRecords: expectedRecords,
        migratedRecords: migratedRecords,
      );
    } catch (error, stackTrace) {
      final String errorMessage = failures.isEmpty
          ? error.toString()
          : '${error.toString()} | ${failures.join(' | ')}';

      await _writeMigrationState(
        userId: userId,
        state: 'failed',
        expectedRecords: expectedRecords,
        migratedRecords: migratedRecords,
        error: errorMessage,
      );

      await _analytics?.logEvent(
        name: 'legacy_migration_failed',
        parameters: <String, Object>{
          'expected_records': expectedRecords,
          'migrated_records': migratedRecords,
        },
      );

      _crashlytics?.recordError(
        error,
        stackTrace,
        reason: 'Legacy migration failed for user $userId',
      );

      rethrow;
    }
  }

  Future<int> _migrateWorkouts({
    required String userId,
    required Map<String, dynamic> payload,
    required List<String> failures,
  }) async {
    final List<Map<String, dynamic>> workouts = _parseMapList(
      payload['workouts'],
      key: 'workouts',
    );

    final int migratedWorkouts = await _migrateList<CompletedWorkoutModel>(
      userId: userId,
      records: workouts,
      label: 'workouts',
      failures: failures,
      decode: CompletedWorkoutModel.fromJson,
      persist: (CompletedWorkoutModel workout) {
        return _workoutRepository.saveWorkout(userId: userId, workout: workout);
      },
    );

    final List<Map<String, dynamic>> completedSets = _parseMapList(
      payload['completedSets'],
      key: 'completedSets',
    );

    final int migratedSets = await _migrateList<CompletedSetModel>(
      userId: userId,
      records: completedSets,
      label: 'completedSets',
      failures: failures,
      decode: CompletedSetModel.fromJson,
      persist: (CompletedSetModel completedSet) {
        return _workoutRepository.saveCompletedSet(
          userId: userId,
          completedSet: completedSet,
        );
      },
    );

    return migratedWorkouts + migratedSets;
  }

  Future<int> _migrateCycles({
    required String userId,
    required Map<String, dynamic> payload,
    required List<String> failures,
  }) {
    return _migrateList<ActiveCycleModel>(
      userId: userId,
      records: _parseMapList(payload['cycles'], key: 'cycles'),
      label: 'cycles',
      failures: failures,
      decode: ActiveCycleModel.fromJson,
      persist: (ActiveCycleModel cycle) {
        return _cycleRepository.saveActiveCycle(userId: userId, cycle: cycle);
      },
    );
  }

  Future<int> _migrateLifts({
    required String userId,
    required Map<String, dynamic> payload,
    required List<String> failures,
  }) async {
    final int migratedLiftMaxes = await _migrateList<LiftMaxModel>(
      userId: userId,
      records: _parseMapList(payload['maxLifts'], key: 'maxLifts'),
      label: 'maxLifts',
      failures: failures,
      decode: LiftMaxModel.fromJson,
      persist: (LiftMaxModel liftMax) {
        return _liftRepository.saveLiftMax(userId: userId, liftMax: liftMax);
      },
    );

    final int migratedOneRepMaxes = await _migrateList<OneRepMaxModel>(
      userId: userId,
      records: _parseMapList(payload['oneRepMaxes'], key: 'oneRepMaxes'),
      label: 'oneRepMaxes',
      failures: failures,
      decode: OneRepMaxModel.fromJson,
      persist: (OneRepMaxModel oneRepMax) {
        return _liftRepository.saveOneRepMax(
          userId: userId,
          oneRepMax: oneRepMax,
        );
      },
    );

    return migratedLiftMaxes + migratedOneRepMaxes;
  }

  Future<int> _migrateRecords({
    required String userId,
    required Map<String, dynamic> payload,
    required List<String> failures,
  }) {
    return _migrateList<PersonalRecordModel>(
      userId: userId,
      records: _parseMapList(payload['records'], key: 'records'),
      label: 'records',
      failures: failures,
      decode: PersonalRecordModel.fromJson,
      persist: (PersonalRecordModel record) {
        return _recordRepository.saveRecord(userId: userId, record: record);
      },
    );
  }

  Future<int> _migrateCustomPrograms({
    required String userId,
    required Map<String, dynamic> payload,
    required List<String> failures,
  }) {
    return _migrateList<CustomProgramModel>(
      userId: userId,
      records: _parseMapList(payload['customPrograms'], key: 'customPrograms'),
      label: 'customPrograms',
      failures: failures,
      decode: CustomProgramModel.fromJson,
      persist: (CustomProgramModel program) {
        return _customProgramRepository.saveCustomProgram(
          userId: userId,
          program: program,
        );
      },
    );
  }

  Future<int> _migrateList<T>({
    required String userId,
    required List<Map<String, dynamic>> records,
    required String label,
    required List<String> failures,
    required T Function(Map<String, dynamic>) decode,
    required Future<void> Function(T model) persist,
  }) async {
    int migrated = 0;

    for (int index = 0; index < records.length; index++) {
      final Map<String, dynamic> record = records[index];
      final String recordId = record['id']?.toString() ?? '$label-index-$index';

      try {
        final T model = decode(record);
        await _withRetry(() => persist(model), label: '$label/$recordId');
        migrated += 1;
      } catch (error, stackTrace) {
        final String message = '$label/$recordId: $error';
        failures.add(message);
        _crashlytics?.recordError(
          error,
          stackTrace,
          reason: 'Failed to migrate $label record for user $userId',
        );
      }
    }

    return migrated;
  }

  Future<void> _withRetry(
    Future<void> Function() action, {
    required String label,
    int maxAttempts = 3,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await action();
        return;
      } catch (error) {
        lastError = error;
        if (attempt == maxAttempts) {
          break;
        }

        await Future<void>.delayed(Duration(milliseconds: attempt * 250));
      }
    }

    throw StateError(
      'Failed to persist $label after $maxAttempts attempts: $lastError',
    );
  }

  int _countExpectedRecords(Map<String, dynamic> payload) {
    return _parseMapList(payload['workouts'], key: 'workouts').length +
        _parseMapList(payload['completedSets'], key: 'completedSets').length +
        _parseMapList(payload['cycles'], key: 'cycles').length +
        _parseMapList(payload['maxLifts'], key: 'maxLifts').length +
        _parseMapList(payload['oneRepMaxes'], key: 'oneRepMaxes').length +
        _parseMapList(payload['records'], key: 'records').length +
        _parseMapList(payload['customPrograms'], key: 'customPrograms').length;
  }

  Future<void> _writeMigrationState({
    required String userId,
    required String state,
    required int expectedRecords,
    required int migratedRecords,
    String? error,
  }) async {
    final FirebaseFirestore? firestore = _firestore;
    if (firestore == null) {
      return;
    }

    await firestore
        .collection('users')
        .doc(userId)
        .collection('migrations')
        .doc('apple_to_firebase')
        .set(<String, dynamic>{
      'state': state,
      'expectedRecords': expectedRecords,
      'migratedRecords': migratedRecords,
      'error': error,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> _parseMapList(
    dynamic value, {
    required String key,
  }) {
    if (value == null) {
      return const <Map<String, dynamic>>[];
    }

    if (value is! List<dynamic>) {
      throw StateError('Migration payload key "$key" must be a list.');
    }

    return value.map((dynamic item) {
      if (item is! Map) {
        throw StateError(
          'Migration payload key "$key" contains a non-map item.',
        );
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
