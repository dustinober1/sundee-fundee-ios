import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/completed_set_model.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  test('watchCompletedSets returns bounded number of sets', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreWorkoutRepository(firestore: firestore);
    const userId = 'user1';
    const workoutId = 'workout1';

    // Populate with 1000 sets
    // Firestore batch limit is 500, so we need multiple batches or simple loops
    for (int i = 0; i < 1000; i++) {
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

    final stream = repository.watchCompletedSets(
      userId: userId,
      workoutId: workoutId,
    );

    final sets = await stream.first;

    // Expect 500 (bounded).
    expect(sets.length, 500);
  });
}
