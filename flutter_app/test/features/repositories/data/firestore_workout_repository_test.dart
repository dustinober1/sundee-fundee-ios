import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_workout_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  group('FirestoreWorkoutRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreWorkoutRepository repository;
    const userId = 'user1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreWorkoutRepository(firestore: firestore);
    });

    test('saveWorkout round-trips optional enrollment linkage', () async {
      final workout = CompletedWorkoutModel(
        id: 'workout-linked',
        userId: userId,
        activeCycleId: 'cycle1',
        programId: 'program1',
        enrollmentId: 'enrollment-99',
        week: 2,
        day: 1,
        sessionId: 'session1',
        completedAt: DateTime.now(),
        duration: 3600,
        notes: null,
      );

      await repository.saveWorkout(userId: userId, workout: workout);

      final loaded = await repository
          .watchWorkout(
            userId: userId,
            workoutId: workout.id,
          )
          .first;

      expect(loaded, isNotNull);
      expect(loaded!.enrollmentId, 'enrollment-99');
    });

    test('legacy workout rows without enrollmentId still decode', () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc('legacy-workout')
          .set(
        <String, dynamic>{
          'id': 'legacy-workout',
          'userId': userId,
          'activeCycleId': 'cycle1',
          'programId': 'program1',
          'week': 1,
          'day': 1,
          'sessionId': 'session1',
          'completedAt': DateTime.now().toIso8601String(),
          'duration': 1200,
          'notes': null,
        },
      );

      final loaded = await repository
          .watchWorkout(
            userId: userId,
            workoutId: 'legacy-workout',
          )
          .first;
      expect(loaded, isNotNull);
      expect(loaded!.enrollmentId, isNull);
    });

    test('deleteWorkout removes workout and associated sets', () async {
      const workoutId = 'workout1';
      final workout = CompletedWorkoutModel(
        id: workoutId,
        userId: userId,
        activeCycleId: 'cycle1',
        programId: 'program1',
        week: 1,
        day: 1,
        sessionId: 'session1',
        completedAt: DateTime.now(),
        duration: 3600,
        notes: 'Great workout',
      );

      final set1 = CompletedSetModel(
        id: 'set1',
        workoutId: workoutId,
        exerciseId: 'exercise1',
        setNumber: 1,
        prescribedWeight: 100,
        actualWeight: 100,
        prescribedReps: 10,
        actualReps: 10,
        rpe: 8,
        restSeconds: 60,
        overrideReason: null,
      );

      final set2 = CompletedSetModel(
        id: 'set2',
        workoutId: 'other_workout',
        exerciseId: 'exercise1',
        setNumber: 1,
        prescribedWeight: 100,
        actualWeight: 100,
        prescribedReps: 10,
        actualReps: 10,
        rpe: 8,
        restSeconds: 60,
        overrideReason: null,
      );

      // Save workout
      await firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .set(workout.toJson());

      // Save sets
      await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .doc(set1.id)
          .set(set1.toJson());
      await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .doc(set2.id)
          .set(set2.toJson());

      // Verify they exist
      var workouts = await repository.watchWorkouts(userId: userId).first;
      expect(workouts.length, 1);

      // Delete workout
      await repository.deleteWorkout(userId: userId, workoutId: workoutId);

      // Verify workout is gone
      workouts = await repository.watchWorkouts(userId: userId).first;
      expect(workouts.isEmpty, true);

      // Verify set1 is gone
      final setsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .where('workoutId', isEqualTo: workoutId)
          .get();
      expect(setsSnapshot.docs.isEmpty, true);

      // Verify set2 still exists
      final otherSetsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .where('workoutId', isEqualTo: 'other_workout')
          .get();
      expect(otherSetsSnapshot.docs.length, 1);
    });
  });
}
