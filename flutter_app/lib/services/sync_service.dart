import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';

/// Sync engine that mirrors v1.1 sync-engine.ts behaviour, adapted for Drift + Supabase.
///
/// Push/pull order respects FK constraints: cycles → workouts → sets/PRs/1RMs.
/// syncId is always written to Drift BEFORE any Supabase call (safe retries / idempotency).
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  static const _queueKey = 'sync_pending_workout_ids';

  SyncService({required AppDatabase db, required SupabaseClient supabase})
      : _db = db,
        _supabase = supabase;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Push a single workout (plus its sets, related PRs, and parent cycle) to
  /// Supabase.  syncIds are generated and persisted to Drift before any cloud
  /// write, so retries are safe and idempotent.
  Future<void> pushWorkout(int localWorkoutId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Fetch workout from Drift.
    final workout = await (_db.select(_db.completedWorkouts)
          ..where((t) => t.id.equals(localWorkoutId)))
        .getSingle();

    // Ensure workout syncId (write Drift first).
    final workoutSyncId =
        workout.syncId ?? await _ensureWorkoutSyncId(localWorkoutId);

    // Ensure parent cycle syncId — push cycle first if needed (FK order).
    final cycle = await (_db.select(_db.activeCycles)
          ..where((t) => t.id.equals(workout.activeCycleId)))
        .getSingle();
    if (cycle.syncId == null) {
      await pushCycle(cycle.id, userId);
    }
    // Re-fetch to get the guaranteed syncId.
    final updatedCycle = await (_db.select(_db.activeCycles)
          ..where((t) => t.id.equals(workout.activeCycleId)))
        .getSingle();
    final cycleSyncId = updatedCycle.syncId!;

    // Upsert workout row.
    await withRetry(() async {
      await _supabase.from('completed_workouts').upsert(
        _workoutToSupabaseRow(workout, userId, workoutSyncId, cycleSyncId),
      );
    });

    // Push completed sets.
    final sets = await (_db.select(_db.completedSets)
          ..where((t) => t.workoutId.equals(localWorkoutId)))
        .get();
    for (final s in sets) {
      final setSyncId = s.syncId ?? await _ensureSetSyncId(s.id);
      await withRetry(() async {
        await _supabase.from('completed_sets').upsert(
          _setToSupabaseRow(s, userId, setSyncId, workoutSyncId),
        );
      });
    }

    // Push PersonalRecords for this workout.
    final prs = await (_db.select(_db.personalRecords)
          ..where((t) => t.workoutId.equals(localWorkoutId)))
        .get();
    for (final pr in prs) {
      final prSyncId = pr.syncId ?? await _ensurePrSyncId(pr.id);
      await withRetry(() async {
        await _supabase.from('personal_records').upsert(
          _prToSupabaseRow(pr, userId, prSyncId, workoutSyncId),
        );
      });
    }

    // Push any OneRepMaxes that don't yet have a syncId (workout-related ORMs
    // are pushed lazily here; full upload uses uploadAllLocalData).
    final orms = await (_db.select(_db.oneRepMaxes)
          ..where(
            (t) =>
                t.userId.equals(workout.userId) &
                t.syncId.isNull(),
          ))
        .get();
    for (final orm in orms) {
      final ormSyncId = await _ensureOrmSyncId(orm.id);
      await withRetry(() async {
        await _supabase.from('one_rep_maxes').upsert(
          _ormToSupabaseRow(orm, userId, ormSyncId),
        );
      });
    }
  }

  /// Push a single active cycle to Supabase.  Called internally by
  /// [pushWorkout] when the parent cycle has no syncId yet.
  Future<void> pushCycle(int localCycleId, String userId) async {
    final cycle = await (_db.select(_db.activeCycles)
          ..where((t) => t.id.equals(localCycleId)))
        .getSingle();
    final syncId = cycle.syncId ?? await _ensureCycleSyncId(localCycleId);
    await withRetry(() async {
      await _supabase.from('active_cycles').upsert(
        _cycleToSupabaseRow(cycle, userId, syncId),
      );
    });
  }

  /// Pull all user data from Supabase and merge into Drift (cloud wins).
  /// Pull order: active_cycles → completed_workouts → completed_sets →
  /// one_rep_maxes → personal_records (FK constraint order).
  Future<void> pullLatest() async {
    final userId = _supabase.auth.currentUser!.id;
    final localUsers = await _db.select(_db.users).get();
    if (localUsers.isEmpty) return;
    final localUserId = localUsers.first.id;

    // --- active_cycles ---
    final cloudCycles = await _supabase
        .from('active_cycles')
        .select()
        .eq('user_id', userId) as List<dynamic>;
    for (final rawRow in cloudCycles) {
      final row = rawRow as Map<String, dynamic>;
      final cloudSyncId = row['id'] as String;
      final existing = await (_db.select(_db.activeCycles)
            ..where((t) => t.syncId.equals(cloudSyncId)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.activeCycles)
              ..where((t) => t.syncId.equals(cloudSyncId)))
            .write(ActiveCyclesCompanion(
          programId: Value(row['program_id'] as String),
          cycleName: Value(row['cycle_name'] as String),
          currentWeek: Value(row['current_week'] as int),
          status: Value(row['status'] as String),
          syncId: Value(cloudSyncId),
        ));
      } else {
        await _db.into(_db.activeCycles).insert(
          ActiveCyclesCompanion.insert(
            userId: localUserId,
            programId: row['program_id'] as String,
            cycleName: row['cycle_name'] as String,
            startDate: DateTime.parse(row['start_date'] as String),
            syncId: Value(cloudSyncId),
          ),
        );
      }
    }

    // --- completed_workouts ---
    final cloudWorkouts = await _supabase
        .from('completed_workouts')
        .select()
        .eq('user_id', userId) as List<dynamic>;
    for (final rawRow in cloudWorkouts) {
      final row = rawRow as Map<String, dynamic>;
      final cloudSyncId = row['id'] as String;
      final cycleSyncId = row['cycle_id'] as String?;
      int? localCycleId;
      if (cycleSyncId != null) {
        final localCycle = await (_db.select(_db.activeCycles)
              ..where((t) => t.syncId.equals(cycleSyncId)))
            .getSingleOrNull();
        localCycleId = localCycle?.id;
      }
      if (localCycleId == null) continue; // FK target missing locally

      final existing = await (_db.select(_db.completedWorkouts)
            ..where((t) => t.syncId.equals(cloudSyncId)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.completedWorkouts)
              ..where((t) => t.syncId.equals(cloudSyncId)))
            .write(CompletedWorkoutsCompanion(
          programId: Value(row['program_id'] as String),
          week: Value(row['week'] as int),
          day: Value(row['day'] as int?),
          sessionId: Value(row['session_id'] as String?),
          completedAt:
              Value(DateTime.parse(row['completed_at'] as String)),
          duration: Value(row['duration'] as int?),
          notes: Value(row['notes'] as String?),
        ));
      } else {
        await _db.into(_db.completedWorkouts).insert(
          CompletedWorkoutsCompanion.insert(
            userId: localUserId,
            activeCycleId: localCycleId,
            programId: row['program_id'] as String,
            week: row['week'] as int,
            completedAt:
                DateTime.parse(row['completed_at'] as String),
            syncId: Value(cloudSyncId),
          ),
        );
      }
    }

    // --- completed_sets ---
    final cloudSets = await _supabase
        .from('completed_sets')
        .select()
        .eq('user_id', userId) as List<dynamic>;
    for (final rawRow in cloudSets) {
      final row = rawRow as Map<String, dynamic>;
      final cloudSyncId = row['id'] as String;
      final workoutSyncId = row['workout_id'] as String?;
      int? localWorkoutId;
      if (workoutSyncId != null) {
        final localWorkout = await (_db.select(_db.completedWorkouts)
              ..where((t) => t.syncId.equals(workoutSyncId)))
            .getSingleOrNull();
        localWorkoutId = localWorkout?.id;
      }
      if (localWorkoutId == null) continue;

      final existing = await (_db.select(_db.completedSets)
            ..where((t) => t.syncId.equals(cloudSyncId)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.completedSets)
              ..where((t) => t.syncId.equals(cloudSyncId)))
            .write(CompletedSetsCompanion(
          exerciseId: Value(row['exercise_id'] as String),
          setNumber: Value(row['set_number'] as int),
          actualWeight:
              Value((row['actual_weight'] as num).toDouble()),
          prescribedReps: Value(row['prescribed_reps'] as int),
          actualReps: Value(row['actual_reps'] as int),
        ));
      } else {
        final createdAtRaw = row['created_at'] as String?;
        await _db.into(_db.completedSets).insert(
          CompletedSetsCompanion.insert(
            workoutId: localWorkoutId,
            exerciseId: row['exercise_id'] as String,
            setNumber: row['set_number'] as int,
            actualWeight: (row['actual_weight'] as num).toDouble(),
            prescribedReps: row['prescribed_reps'] as int,
            actualReps: row['actual_reps'] as int,
            createdAt: createdAtRaw != null
                ? DateTime.parse(createdAtRaw)
                : DateTime.now(),
            syncId: Value(cloudSyncId),
          ),
        );
      }
    }

    // --- one_rep_maxes ---
    final cloudOrms = await _supabase
        .from('one_rep_maxes')
        .select()
        .eq('user_id', userId) as List<dynamic>;
    for (final rawRow in cloudOrms) {
      final row = rawRow as Map<String, dynamic>;
      final cloudSyncId = row['id'] as String;
      final existing = await (_db.select(_db.oneRepMaxes)
            ..where((t) => t.syncId.equals(cloudSyncId)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.oneRepMaxes)
              ..where((t) => t.syncId.equals(cloudSyncId)))
            .write(OneRepMaxesCompanion(
          weight: Value((row['weight'] as num).toDouble()),
          date: Value(DateTime.parse(row['date'] as String)),
        ));
      } else {
        await _db.into(_db.oneRepMaxes).insert(
          OneRepMaxesCompanion.insert(
            userId: localUserId,
            exerciseId: row['exercise_id'] as String,
            weight: (row['weight'] as num).toDouble(),
            date: DateTime.parse(row['date'] as String),
            syncId: Value(cloudSyncId),
          ),
        );
      }
    }

    // --- personal_records ---
    final cloudPrs = await _supabase
        .from('personal_records')
        .select()
        .eq('user_id', userId) as List<dynamic>;
    for (final rawRow in cloudPrs) {
      final row = rawRow as Map<String, dynamic>;
      final cloudSyncId = row['id'] as String;
      final workoutSyncId = row['workout_id'] as String?;
      int? localWorkoutId;
      if (workoutSyncId != null) {
        final localWorkout = await (_db.select(_db.completedWorkouts)
              ..where((t) => t.syncId.equals(workoutSyncId)))
            .getSingleOrNull();
        localWorkoutId = localWorkout?.id;
      }
      if (localWorkoutId == null) continue;

      final existing = await (_db.select(_db.personalRecords)
            ..where((t) => t.syncId.equals(cloudSyncId)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.personalRecords)
              ..where((t) => t.syncId.equals(cloudSyncId)))
            .write(PersonalRecordsCompanion(
          type: Value(row['type'] as String),
          value: Value((row['value'] as num).toDouble()),
          date: Value(DateTime.parse(row['date'] as String)),
        ));
      } else {
        await _db.into(_db.personalRecords).insert(
          PersonalRecordsCompanion.insert(
            userId: localUserId,
            exerciseId: row['exercise_id'] as String,
            type: row['type'] as String,
            value: (row['value'] as num).toDouble(),
            workoutId: localWorkoutId,
            date: DateTime.parse(row['date'] as String),
            syncId: Value(cloudSyncId),
          ),
        );
      }
    }
  }

  /// Called on first sync after sign-in.  Pushes all local rows that lack a
  /// syncId to Supabase.  Push order: cycles → workouts → sets/PRs/1RMs.
  Future<void> uploadAllLocalData(String userId) async {
    // Cycles first (workouts FK to cycles).
    final cycles = await (_db.select(_db.activeCycles)
          ..where((t) => t.syncId.isNull()))
        .get();
    for (final c in cycles) {
      await pushCycle(c.id, userId);
    }

    // Workouts (also pushes their sets + PRs + lazy ORMs).
    final workouts = await (_db.select(_db.completedWorkouts)
          ..where((t) => t.syncId.isNull()))
        .get();
    for (final w in workouts) {
      await pushWorkout(w.id);
    }

    // Any remaining ORMs that weren't captured above.
    final orms = await (_db.select(_db.oneRepMaxes)
          ..where((t) => t.syncId.isNull()))
        .get();
    for (final orm in orms) {
      final ormSyncId = await _ensureOrmSyncId(orm.id);
      await withRetry(() async {
        await _supabase.from('one_rep_maxes').upsert(
          _ormToSupabaseRow(orm, userId, ormSyncId),
        );
      });
    }

    // Any remaining PRs (workoutSyncId already written above).
    final prs = await (_db.select(_db.personalRecords)
          ..where((t) => t.syncId.isNull()))
        .get();
    for (final pr in prs) {
      final workout = await (_db.select(_db.completedWorkouts)
            ..where((t) => t.id.equals(pr.workoutId)))
          .getSingle();
      final workoutSyncId =
          workout.syncId ?? await _ensureWorkoutSyncId(workout.id);
      final prSyncId = await _ensurePrSyncId(pr.id);
      await withRetry(() async {
        await _supabase.from('personal_records').upsert(
          _prToSupabaseRow(pr, userId, prSyncId, workoutSyncId),
        );
      });
    }
  }

  /// Add a workout ID to the offline retry queue (idempotent).
  Future<void> enqueue(int workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final List<dynamic> ids =
        raw != null ? jsonDecode(raw) as List : [];
    if (!ids.contains(workoutId)) {
      ids.add(workoutId);
      await prefs.setString(_queueKey, jsonEncode(ids));
    }
  }

  /// Remove a workout ID from the offline retry queue.
  Future<void> dequeue(int workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return;
    final List<dynamic> ids = jsonDecode(raw) as List;
    ids.remove(workoutId);
    await prefs.setString(_queueKey, jsonEncode(ids));
  }

  /// Read the current offline retry queue.
  Future<List<int>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    final List<dynamic> ids = jsonDecode(raw) as List;
    return ids.cast<int>();
  }

  /// Push every queued workout to Supabase, dequeuing each on success.
  /// Individual failures are swallowed so the whole drain continues.
  Future<void> drainQueue() async {
    final queue = await getQueue();
    for (final workoutId in queue) {
      try {
        await pushWorkout(workoutId);
        await dequeue(workoutId);
      } catch (_) {
        // Continue draining; leave failed ID in queue for next attempt.
      }
    }
  }

  /// Execute [fn] with up to [maxAttempts] tries using exponential back-off
  /// (1 s, 2 s, 4 s, …).  Re-throws on final failure.
  Future<T> withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private: syncId helpers
  // ---------------------------------------------------------------------------

  Future<String> _ensureWorkoutSyncId(int workoutId) async {
    final newId = const Uuid().v4();
    await (_db.update(_db.completedWorkouts)
          ..where((t) => t.id.equals(workoutId)))
        .write(CompletedWorkoutsCompanion(syncId: Value(newId)));
    return newId;
  }

  Future<String> _ensureSetSyncId(int setId) async {
    final newId = const Uuid().v4();
    await (_db.update(_db.completedSets)
          ..where((t) => t.id.equals(setId)))
        .write(CompletedSetsCompanion(syncId: Value(newId)));
    return newId;
  }

  Future<String> _ensureCycleSyncId(int cycleId) async {
    final newId = const Uuid().v4();
    await (_db.update(_db.activeCycles)
          ..where((t) => t.id.equals(cycleId)))
        .write(ActiveCyclesCompanion(syncId: Value(newId)));
    return newId;
  }

  Future<String> _ensureOrmSyncId(int ormId) async {
    final newId = const Uuid().v4();
    await (_db.update(_db.oneRepMaxes)
          ..where((t) => t.id.equals(ormId)))
        .write(OneRepMaxesCompanion(syncId: Value(newId)));
    return newId;
  }

  Future<String> _ensurePrSyncId(int prId) async {
    final newId = const Uuid().v4();
    await (_db.update(_db.personalRecords)
          ..where((t) => t.id.equals(prId)))
        .write(PersonalRecordsCompanion(syncId: Value(newId)));
    return newId;
  }

  // ---------------------------------------------------------------------------
  // Private: Supabase row transforms
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _workoutToSupabaseRow(
    CompletedWorkout w,
    String userId,
    String syncId,
    String cycleSyncId,
  ) {
    return {
      'id': syncId,
      'user_id': userId,
      'cycle_id': cycleSyncId,
      'program_id': w.programId,
      'week': w.week,
      'day': w.day,
      'session_id': w.sessionId,
      'completed_at': w.completedAt.toIso8601String(),
      'duration': w.duration,
      'notes': w.notes,
    };
  }

  Map<String, dynamic> _setToSupabaseRow(
    CompletedSet s,
    String userId,
    String syncId,
    String workoutSyncId,
  ) {
    return {
      'id': syncId,
      'user_id': userId,
      'workout_id': workoutSyncId,
      'exercise_id': s.exerciseId,
      'set_number': s.setNumber,
      'prescribed_weight': s.prescribedWeight,
      'actual_weight': s.actualWeight,
      'prescribed_reps': s.prescribedReps,
      'actual_reps': s.actualReps,
      'rpe': s.rpe,
      'rest_seconds': s.restSeconds,
      'override_reason': s.overrideReason,
      'created_at': s.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _cycleToSupabaseRow(
    ActiveCycle c,
    String userId,
    String syncId,
  ) {
    return {
      'id': syncId,
      'user_id': userId,
      'program_id': c.programId,
      'cycle_name': c.cycleName,
      'start_date': c.startDate.toIso8601String(),
      'current_week': c.currentWeek,
      'current_session_id': c.currentSessionId,
      'current_phase': c.currentPhase,
      'status': c.status,
    };
  }

  Map<String, dynamic> _ormToSupabaseRow(
    OneRepMaxe o,
    String userId,
    String syncId,
  ) {
    return {
      'id': syncId,
      'user_id': userId,
      'exercise_id': o.exerciseId,
      'weight': o.weight,
      'date': o.date.toIso8601String(),
    };
  }

  Map<String, dynamic> _prToSupabaseRow(
    PersonalRecord pr,
    String userId,
    String syncId,
    String workoutSyncId,
  ) {
    return {
      'id': syncId,
      'user_id': userId,
      'exercise_id': pr.exerciseId,
      'type': pr.type,
      'value': pr.value,
      'workout_id': workoutSyncId,
      'date': pr.date.toIso8601String(),
    };
  }
}
