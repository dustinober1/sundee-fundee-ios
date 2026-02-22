import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('Benchmark watchCompletedSets performance', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'user1';
    const workoutId = 'workout1';

    // Populate with 2000 sets
    print('Populating 2000 sets...');
    final stopwatch = Stopwatch()..start();
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
    stopwatch.stop();
    print('Population took: ${stopwatch.elapsedMilliseconds}ms');

    // Benchmark fetch
    print('Fetching completed sets...');
    stopwatch.reset();
    stopwatch.start();

    final stream = repository.watchCompletedSets(
      userId: userId,
      workoutId: workoutId,
    );

    final sets = await stream.first;
    stopwatch.stop();

    print('Fetch took: ${stopwatch.elapsedMilliseconds}ms');
    print('Sets retrieved: ${sets.length}');

    // Simple assertion to verify it returned *something*
    expect(sets.isNotEmpty, true);
  });
}
