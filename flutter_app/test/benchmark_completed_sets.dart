import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('Benchmark watchCompletedSets performance', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'benchmarkUser';
    const workoutId = 'benchmarkWorkout';

    print('Populating 2000 sets...');
    final populateStopwatch = Stopwatch()..start();

    // Create 2000 sets. Batch writes to avoid overwhelming the event loop or hitting limits.
    const batchSize = 500;
    const totalSets = 2000;

    for (int i = 0; i < totalSets; i += batchSize) {
      final batch = <Future<void>>[];
      for (int j = 0; j < batchSize && (i + j) < totalSets; j++) {
        final index = i + j;
        final set = CompletedSetModel(
          id: 'set_$index',
          workoutId: workoutId,
          exerciseId: 'exercise1',
          setNumber: index,
          prescribedWeight: 100.0,
          actualWeight: 100.0,
          prescribedReps: 10,
          actualReps: 10,
          rpe: 8.0,
          restSeconds: 60,
          overrideReason: null,
        );
        batch.add(
          firestore
              .collection('users')
              .doc(userId)
              .collection('completedSets')
              .doc(set.id)
              .set(set.toJson()),
        );
      }
      await Future.wait(batch);
    }

    populateStopwatch.stop();
    print('Population took: ${populateStopwatch.elapsedMilliseconds}ms');

    print('Starting benchmark...');
    final stopwatch = Stopwatch()..start();

    final stream = repository.watchCompletedSets(
      userId: userId,
      workoutId: workoutId,
    );

    final sets = await stream.first;

    stopwatch.stop();

    print('----------------------------------------');
    print('Benchmark Results:');
    print('Sets retrieved: ${sets.length}');
    print('Time taken: ${stopwatch.elapsedMilliseconds}ms');
    print('----------------------------------------');

    // Assert that the limit is respected
    expect(sets.length, FirestoreWorkoutRepository.kCompletedSetsLimit, reason: 'Should be limited to ${FirestoreWorkoutRepository.kCompletedSetsLimit} sets');
  });
}
