import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/firestore_repositories.dart';
import 'domain/repository_interfaces.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((Ref ref) {
  final FirebaseFirestore? firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'WorkoutRepository requires ENABLE_FIREBASE=true and initialized Firestore.',
    );
  }

  return FirestoreWorkoutRepository(firestore: firestore);
});

final cycleRepositoryProvider = Provider<CycleRepository>((Ref ref) {
  final FirebaseFirestore? firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'CycleRepository requires ENABLE_FIREBASE=true and initialized Firestore.',
    );
  }

  return FirestoreCycleRepository(firestore: firestore);
});

final liftRepositoryProvider = Provider<LiftRepository>((Ref ref) {
  final FirebaseFirestore? firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'LiftRepository requires ENABLE_FIREBASE=true and initialized Firestore.',
    );
  }

  return FirestoreLiftRepository(firestore: firestore);
});

final recordRepositoryProvider = Provider<RecordRepository>((Ref ref) {
  final FirebaseFirestore? firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'RecordRepository requires ENABLE_FIREBASE=true and initialized Firestore.',
    );
  }

  return FirestoreRecordRepository(firestore: firestore);
});

final customProgramRepositoryProvider = Provider<CustomProgramRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'CustomProgramRepository requires ENABLE_FIREBASE=true and initialized Firestore.',
    );
  }
  return FirestoreCustomProgramRepository(firestore: firestore);
});

final enrolledProgramRepositoryProvider = Provider<EnrolledProgramRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError(
      'EnrolledProgramRepository requires ENABLE_FIREBASE=true and initialized Firestore. '
      'Check if firebaseAuthEnabled is true.',
    );
  }
  return FirestoreEnrolledProgramRepository(firestore: firestore);
});
