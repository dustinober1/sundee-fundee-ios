import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/set_data.dart';

class WorkoutRepository {
  final AppDatabase _db;

  WorkoutRepository(this._db);

  /// Save workout + all sets atomically.
  /// Returns the inserted workout ID.
  Future<int> saveWorkout({
    required int userId,
    required int activeCycleId,
    required String programId,
    required int week,
    String? sessionId,
    int? day,
    required List<SetData> sets,
    required DateTime completedAt,
    int? duration,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      // 1. Insert workout
      final workoutId = await _db.into(_db.completedWorkouts).insert(
        CompletedWorkoutsCompanion.insert(
          userId: userId,
          activeCycleId: activeCycleId,
          programId: programId,
          week: week,
          day: Value(day),
          sessionId: Value(sessionId),
          completedAt: completedAt,
          duration: Value(duration),
          notes: Value(notes),
        ),
      );

      // 2. Insert all sets
      for (final set in sets) {
        await _db.into(_db.completedSets).insert(
          CompletedSetsCompanion.insert(
            workoutId: workoutId,
            exerciseId: set.exerciseId,
            setNumber: set.setNumber,
            prescribedWeight: Value(set.prescribedWeight),
            actualWeight: set.actualWeight,
            prescribedReps: set.prescribedReps,
            actualReps: set.actualReps,
            rpe: Value(set.rpe),
            restSeconds: Value(set.restSeconds),
            overrideReason: Value(set.overrideReason),
            createdAt: completedAt,
          ),
        );
      }

      return workoutId;
    });
  }

  /// Get all workouts for a user, ordered by completedAt descending.
  Future<List<CompletedWorkout>> getWorkoutHistory(int userId) async {
    return await (_db.select(_db.completedWorkouts)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Get all sets for a specific workout, ordered by set number.
  Future<List<CompletedSet>> getSetsForWorkout(int workoutId) async {
    return await (_db.select(_db.completedSets)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }

  /// Get workouts for a specific active cycle, ordered by completedAt ascending.
  Future<List<CompletedWorkout>> getWorkoutsForCycle(int activeCycleId) async {
    return await (_db.select(_db.completedWorkouts)
          ..where((t) => t.activeCycleId.equals(activeCycleId))
          ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]))
        .get();
  }

  // ── Chart query methods ────────────────────────────────────────────────────

  /// Get all sets for a specific exercise across all workouts.
  /// Returns sets paired with their workout's completedAt date.
  Future<List<({CompletedSet set, DateTime completedAt})>> getSetsForExercise(
    String exerciseId,
  ) async {
    final sets = await (_db.select(_db.completedSets)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();

    if (sets.isEmpty) return [];

    final workoutIds = sets.map((s) => s.workoutId).toSet().toList();
    final workouts = await (_db.select(_db.completedWorkouts)
          ..where((t) => t.id.isIn(workoutIds)))
        .get();

    final workoutDateMap = {for (var w in workouts) w.id: w.completedAt};

    return sets
        .where((s) => workoutDateMap.containsKey(s.workoutId))
        .map((s) => (set: s, completedAt: workoutDateMap[s.workoutId]!))
        .toList();
  }

  /// Get all sets with their workout date for volume calculations.
  Future<List<({CompletedSet set, DateTime completedAt})>>
  getAllSetsWithWorkoutDate() async {
    final workouts = await _db.select(_db.completedWorkouts).get();
    final workoutDateMap = {for (var w in workouts) w.id: w.completedAt};

    final sets = await _db.select(_db.completedSets).get();

    return sets
        .where((s) => workoutDateMap.containsKey(s.workoutId))
        .map((s) => (set: s, completedAt: workoutDateMap[s.workoutId]!))
        .toList();
  }

  /// Get all unique exercise IDs from completed sets.
  Future<List<String>> getTrackedExerciseIds() async {
    final sets = await _db.select(_db.completedSets).get();
    return sets.map((s) => s.exerciseId).toSet().toList();
  }

  /// Get workout count by date (yyyy-MM-dd) for the last year.
  /// Used to build the activity heatmap.
  Future<Map<String, int>> getWorkoutCountByDate() async {
    final workouts = await _db.select(_db.completedWorkouts).get();
    final countByDate = <String, int>{};

    for (final w in workouts) {
      final dateKey =
          '${w.completedAt.year}-'
          '${w.completedAt.month.toString().padLeft(2, '0')}-'
          '${w.completedAt.day.toString().padLeft(2, '0')}';
      countByDate[dateKey] = (countByDate[dateKey] ?? 0) + 1;
    }

    return countByDate;
  }

  // ── PR detection and 1RM save methods ─────────────────────────────────────

  /// Save estimated 1RM for an exercise.
  Future<int> saveOneRepMax({
    required int userId,
    required String exerciseId,
    required double weight,
    required DateTime date,
  }) async {
    return await _db.into(_db.oneRepMaxes).insert(
      OneRepMaxesCompanion.insert(
        userId: userId,
        exerciseId: exerciseId,
        weight: weight,
        date: date,
      ),
    );
  }

  /// Get historical max weight for an exercise from 1RM records.
  Future<double> getHistoricalMax(int userId, String exerciseId) async {
    final records = await (_db.select(_db.oneRepMaxes)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();

    if (records.isEmpty) return 0;
    return records.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
  }

  /// Check if weight is a PR and save if so.
  /// Returns true if PR was detected and saved.
  ///
  /// CRITICAL: Only triggers PR if historicalMax > 0 (no PR on first-ever lift).
  Future<bool> checkAndSaveWeightPR({
    required int userId,
    required String exerciseId,
    required double newWeight,
    required int workoutId,
    required DateTime date,
  }) async {
    final historicalMax = await getHistoricalMax(userId, exerciseId);

    // No PR on first-ever lift (historicalMax = 0)
    if (historicalMax <= 0) return false;

    if (newWeight > historicalMax) {
      await _db.into(_db.personalRecords).insert(
        PersonalRecordsCompanion.insert(
          userId: userId,
          exerciseId: exerciseId,
          type: 'weight',
          value: newWeight,
          workoutId: workoutId,
          date: date,
        ),
      );
      return true;
    }
    return false;
  }

  /// Get best historical single-session volume for an exercise.
  /// Excludes the specified workout ID from comparison.
  Future<double> getBestSessionVolume({
    required int userId,
    required String exerciseId,
    required int excludeWorkoutId,
  }) async {
    // Get all workouts for user
    final workouts = await (_db.select(_db.completedWorkouts)
          ..where((t) => t.userId.equals(userId)))
        .get();

    final workoutIds = workouts
        .where((w) => w.id != excludeWorkoutId)
        .map((w) => w.id)
        .toList();

    if (workoutIds.isEmpty) return 0;

    // Get sets for this exercise from those workouts
    final sets = await (_db.select(_db.completedSets)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..where((t) => t.workoutId.isIn(workoutIds)))
        .get();

    // Group by workout and calculate volume per session
    final volumeByWorkout = <int, double>{};
    for (final s in sets) {
      volumeByWorkout[s.workoutId] =
          (volumeByWorkout[s.workoutId] ?? 0) + (s.actualWeight * s.actualReps);
    }

    if (volumeByWorkout.isEmpty) return 0;
    return volumeByWorkout.values.reduce((a, b) => a > b ? a : b);
  }

  /// Check if session volume is a PR and save if so.
  /// Returns true if PR was detected and saved.
  ///
  /// CRITICAL: Only triggers PR if prior sessions exist (no PR on first session).
  Future<bool> checkAndSaveVolumePR({
    required int userId,
    required String exerciseId,
    required double currentVolume,
    required int workoutId,
    required DateTime date,
  }) async {
    if (currentVolume <= 0) return false;

    final bestHistorical = await getBestSessionVolume(
      userId: userId,
      exerciseId: exerciseId,
      excludeWorkoutId: workoutId,
    );

    // No PR on first session (bestHistorical = 0)
    if (bestHistorical <= 0) return false;

    if (currentVolume > bestHistorical) {
      await _db.into(_db.personalRecords).insert(
        PersonalRecordsCompanion.insert(
          userId: userId,
          exerciseId: exerciseId,
          type: 'volume',
          value: currentVolume,
          workoutId: workoutId,
          date: date,
        ),
      );
      return true;
    }
    return false;
  }
}
