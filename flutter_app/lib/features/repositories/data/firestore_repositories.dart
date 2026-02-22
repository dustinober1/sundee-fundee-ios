import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/active_cycle_model.dart';
import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/custom_program_model.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../../domain/models/one_rep_max_model.dart';
import '../../../domain/models/personal_record_model.dart';
import '../domain/repository_interfaces.dart';

class FirestoreWorkoutRepository implements WorkoutRepository {
  FirestoreWorkoutRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const int _maxCompletedSetsLimit = 500;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveWorkout({
    required String userId,
    required CompletedWorkoutModel workout,
  }) {
    return _workoutsCollection(
      userId,
    ).doc(workout.id).set(workout.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<CompletedWorkoutModel>> watchWorkouts({required String userId}) {
    return _workoutsCollection(userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    CompletedWorkoutModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  @override
  Future<void> saveCompletedSet({
    required String userId,
    required CompletedSetModel completedSet,
  }) {
    return _completedSetsCollection(
      userId,
    ).doc(completedSet.id).set(completedSet.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<CompletedSetModel>> watchCompletedSets({
    required String userId,
    required String workoutId,
  }) {
    return _completedSetsCollection(userId)
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('setNumber')
        .limit(_maxCompletedSetsLimit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    CompletedSetModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _workoutsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('workouts');
  }

  CollectionReference<Map<String, dynamic>> _completedSetsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('completedSets');
  }
}

class FirestoreCycleRepository implements CycleRepository {
  FirestoreCycleRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveActiveCycle({
    required String userId,
    required ActiveCycleModel cycle,
  }) {
    return _cyclesCollection(
      userId,
    ).doc(cycle.id).set(cycle.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<ActiveCycleModel>> watchActiveCycles({required String userId}) {
    return _cyclesCollection(userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    ActiveCycleModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _cyclesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('cycles');
  }
}

class FirestoreLiftRepository implements LiftRepository {
  FirestoreLiftRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveLiftMax({
    required String userId,
    required LiftMaxModel liftMax,
  }) {
    return _maxLiftsCollection(
      userId,
    ).doc(liftMax.id).set(liftMax.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<LiftMaxModel>> watchLiftMaxes({required String userId}) {
    return _maxLiftsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    LiftMaxModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  @override
  Future<void> saveOneRepMax({
    required String userId,
    required OneRepMaxModel oneRepMax,
  }) {
    return _oneRepMaxCollection(
      userId,
    ).doc(oneRepMax.id).set(oneRepMax.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<OneRepMaxModel>> watchOneRepMaxes({required String userId}) {
    return _oneRepMaxCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    OneRepMaxModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _maxLiftsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('maxLifts');
  }

  CollectionReference<Map<String, dynamic>> _oneRepMaxCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('oneRepMaxes');
  }
}

class FirestoreRecordRepository implements RecordRepository {
  FirestoreRecordRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveRecord({
    required String userId,
    required PersonalRecordModel record,
  }) {
    return _recordsCollection(
      userId,
    ).doc(record.id).set(record.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<PersonalRecordModel>> watchRecords({required String userId}) {
    return _recordsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    PersonalRecordModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _recordsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('records');
  }
}

class FirestoreCustomProgramRepository implements CustomProgramRepository {
  FirestoreCustomProgramRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveCustomProgram({
    required String userId,
    required CustomProgramModel program,
  }) {
    return _programsCollection(
      userId,
    ).doc(program.id).set(program.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<List<CustomProgramModel>> watchCustomPrograms({
    required String userId,
  }) {
    return _programsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    CustomProgramModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _programsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customPrograms');
  }
}
