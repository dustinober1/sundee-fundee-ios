import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('benchmark watchCompletedSets', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'user1';
    const workoutId = 'workout1';

    // Populate with 2000 sets
    print('Generating 2000 sets...');
    final sets = List.generate(2000, (i) => CompletedSetModel(
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
      ));

    // Using Future.wait for parallel insertion might be faster or more reliable
    // But FakeFirestore handles sync calls too.
    // Let's use simple loop with await for simplicity and reliability in fake environment
    for (var set in sets) {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('completedSets')
          .doc(set.id)
          .set(set.toJson());
    }
    print('Sets generated.');

    final stopwatch = Stopwatch()..start();
    final stream = repository.watchCompletedSets(
      userId: userId,
      workoutId: workoutId,
    );

    final resultSets = await stream.first;
    stopwatch.stop();

    print('Result count: ${resultSets.length}');
    print('Execution time: ${stopwatch.elapsedMilliseconds}ms');

    // Assert something to verify the test logic works
    expect(resultSets.length, 500);
  });
}
