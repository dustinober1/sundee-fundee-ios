import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('Benchmark: watchCompletedSets performance with large dataset', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'benchmark_user';
    const workoutId = 'benchmark_workout';

    // Populate with 2000 sets (simulating a very large workout or data accumulation)
    print('Seeding 2000 sets...');
    for (int i = 0; i < 2000; i++) {
      final set = CompletedSetModel(
        id: 'set_$i',
        workoutId: workoutId,
        exerciseId: 'exercise1',
        setNumber: i,
        prescribedWeight: 100,
        actualWeight: 100,
        prescribedReps: 10,
        actualReps: 10,
        rpe: 8,
        restSeconds: 60,
        overrideReason: null,
      );
      await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .doc(set.id)
          .set(set.toJson());
    }

    // Warmup JIT
    print('Warming up...');
    await repository.watchCompletedSets(userId: userId, workoutId: workoutId).first;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('completedSets')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('setNumber')
        .snapshots()
        .first;

    // 1. Measure Bounded Query (Current Implementation)
    final stopwatch = Stopwatch()..start();
    final boundedStream = repository.watchCompletedSets(
      userId: userId,
      workoutId: workoutId,
    );
    final boundedResult = await boundedStream.first;
    stopwatch.stop();
    final boundedTime = stopwatch.elapsedMilliseconds;

    expect(boundedResult.length, 500);
    print('Bounded Query (limit 500): ${boundedResult.length} items in ${boundedTime}ms');

    // 2. Measure Unbounded Query (Simulated)
    stopwatch.reset();
    stopwatch.start();
    final unboundedStream = firestore
        .collection('users')
        .doc(userId)
        .collection('completedSets')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('setNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompletedSetModel.fromJson(doc.data()))
            .toList());

    final unboundedResult = await unboundedStream.first;
    stopwatch.stop();
    final unboundedTime = stopwatch.elapsedMilliseconds;

    expect(unboundedResult.length, 2000);
    print('Unbounded Query (no limit): ${unboundedResult.length} items in ${unboundedTime}ms');

    // Analyze results
    print('Performance Improvement:');
    print('  Unbounded Time: ${unboundedTime}ms');
    print('  Bounded Time:   ${boundedTime}ms');
    print('  Diff:           ${unboundedTime - boundedTime}ms');

    // In a real environment, bounded should be faster.
    // However, fake_cloud_firestore might have different characteristics.
    // We only assert correctness here.
  });
}
