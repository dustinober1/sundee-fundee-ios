import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee/data/database/app_database.dart';
import 'package:sundee_fundee/data/models/set_data.dart';
import 'package:sundee_fundee/data/repositories/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      }),
    );
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkoutRepository', () {
    test('saveWorkout persists workout and sets atomically', () async {
      // Create prerequisite user and cycle
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(
          name: 'Test',
          experienceLevel: 'beginner',
          goal: 'strength',
        ),
      );
      final cycleId = await db.into(db.activeCycles).insert(
        ActiveCyclesCompanion.insert(
          userId: userId,
          programId: 'test-program',
          cycleName: 'Test Cycle',
          startDate: DateTime.now(),
        ),
      );

      // Save workout with sets
      final sets = [
        const SetData(
          exerciseId: 'squat',
          setNumber: 1,
          actualWeight: 135,
          prescribedReps: 5,
          actualReps: 5,
        ),
        const SetData(
          exerciseId: 'squat',
          setNumber: 2,
          actualWeight: 145,
          prescribedReps: 5,
          actualReps: 4,
        ),
      ];

      final workoutId = await repo.saveWorkout(
        userId: userId,
        activeCycleId: cycleId,
        programId: 'test-program',
        week: 1,
        sessionId: 'session-1',
        sets: sets,
        completedAt: DateTime.now(),
        duration: 3600,
      );

      // Verify workout saved
      final workouts = await repo.getWorkoutHistory(userId);
      expect(workouts, hasLength(1));
      expect(workouts.first.id, workoutId);
      expect(workouts.first.programId, 'test-program');

      // Verify sets saved
      final savedSets = await repo.getSetsForWorkout(workoutId);
      expect(savedSets, hasLength(2));
      expect(savedSets[0].actualWeight, 135);
      expect(savedSets[1].actualWeight, 145);
    });

    test('getWorkoutsForCycle returns only cycle workouts', () async {
      // Setup user and two cycles
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(
          name: 'Test',
          experienceLevel: 'beginner',
          goal: 'strength',
        ),
      );
      final cycle1 = await db.into(db.activeCycles).insert(
        ActiveCyclesCompanion.insert(
          userId: userId,
          programId: 'p1',
          cycleName: 'C1',
          startDate: DateTime.now(),
        ),
      );
      final cycle2 = await db.into(db.activeCycles).insert(
        ActiveCyclesCompanion.insert(
          userId: userId,
          programId: 'p2',
          cycleName: 'C2',
          startDate: DateTime.now(),
        ),
      );

      // Save workout to each cycle
      await repo.saveWorkout(
        userId: userId,
        activeCycleId: cycle1,
        programId: 'p1',
        week: 1,
        sets: [],
        completedAt: DateTime.now(),
      );
      await repo.saveWorkout(
        userId: userId,
        activeCycleId: cycle2,
        programId: 'p2',
        week: 1,
        sets: [],
        completedAt: DateTime.now(),
      );

      // Query cycle1 workouts
      final cycle1Workouts = await repo.getWorkoutsForCycle(cycle1);
      expect(cycle1Workouts, hasLength(1));
      expect(cycle1Workouts.first.programId, 'p1');
    });

    test('cascade deletes sets when workout deleted', () async {
      // Setup
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(
          name: 'Test',
          experienceLevel: 'beginner',
          goal: 'strength',
        ),
      );
      final cycleId = await db.into(db.activeCycles).insert(
        ActiveCyclesCompanion.insert(
          userId: userId,
          programId: 'p',
          cycleName: 'C',
          startDate: DateTime.now(),
        ),
      );

      final sets = [
        const SetData(
          exerciseId: 'ex',
          setNumber: 1,
          actualWeight: 100,
          prescribedReps: 5,
          actualReps: 5,
        ),
      ];
      final workoutId = await repo.saveWorkout(
        userId: userId,
        activeCycleId: cycleId,
        programId: 'p',
        week: 1,
        sets: sets,
        completedAt: DateTime.now(),
      );

      // Verify set exists
      var savedSets = await repo.getSetsForWorkout(workoutId);
      expect(savedSets, hasLength(1));

      // Delete workout
      await (db.delete(db.completedWorkouts)
            ..where((t) => t.id.equals(workoutId)))
          .go();

      // Sets should be cascade deleted
      savedSets = await repo.getSetsForWorkout(workoutId);
      expect(savedSets, isEmpty);
    });
  });
}
