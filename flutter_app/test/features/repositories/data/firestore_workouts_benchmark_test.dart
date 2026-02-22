import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_workout_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('Benchmark: watchWorkouts performance with large dataset', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'benchmark_user';

    // Populate with 1000 workouts
    debugPrint('Seeding 1000 workouts...');
    for (int i = 0; i < 1000; i++) {
      final workout = CompletedWorkoutModel(
        id: 'workout_$i',
        userId: userId,
        activeCycleId: 'cycle_1',
        programId: 'program_1',
        week: 1,
        day: 1,
        sessionId: 'session_$i',
        completedAt: DateTime.now().subtract(Duration(days: i)),
        duration: 60,
        notes: null,
      );
      await firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workout.id)
          .set(workout.toJson());
    }

    // Warmup JIT
    debugPrint('Warming up...');
    await repository.watchWorkouts(userId: userId).first;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .first;

    // 1. Measure Current Implementation
    final stopwatch = Stopwatch()..start();
    final stream = repository.watchWorkouts(userId: userId);
    final result = await stream.first;
    stopwatch.stop();
    final time = stopwatch.elapsedMilliseconds;

    debugPrint('Query Result: ${result.length} items in ${time}ms');

    // Expect exactly 500 items (the limit)
    expect(result.length, 500);
  });
}
