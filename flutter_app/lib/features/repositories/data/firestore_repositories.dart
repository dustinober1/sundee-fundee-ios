import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/active_cycle_model.dart';
import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/custom_program_model.dart';
import '../../../domain/models/cycle_models.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../../domain/models/one_rep_max_model.dart';
import '../../../domain/models/personal_record_model.dart';
import '../../../domain/models/program_models.dart';
import '../domain/repository_interfaces.dart';

const int kCompletedSetsLimit = 500;

class FirestoreWorkoutRepository implements WorkoutRepository {
  FirestoreWorkoutRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

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
  Stream<CompletedWorkoutModel?> watchWorkout({
    required String userId,
    required String workoutId,
  }) {
    return _workoutsCollection(userId).doc(workoutId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> doc) {
        if (!doc.exists) return null;
        return CompletedWorkoutModel.fromJson(doc.data()!);
      },
    );
  }

  @override
  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    final WriteBatch batch = _firestore.batch();

    // Delete the workout document
    batch.delete(_workoutsCollection(userId).doc(workoutId));

    // Find and delete all completed sets for this workout
    final QuerySnapshot<Map<String, dynamic>> setsSnapshot =
        await _completedSetsCollection(userId)
            .where('workoutId', isEqualTo: workoutId)
            .get();

    for (final DocumentSnapshot<Map<String, dynamic>> doc
        in setsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    return batch.commit();
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
        .limit(kCompletedSetsLimit)
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

  @override
  Future<void> savePeriodLog({
    required String userId,
    required PeriodLogModel log,
  }) {
    return _periodLogsCollection(userId).doc(log.id).set(
          log.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deletePeriodLog({
    required String userId,
    required String logId,
  }) {
    return _periodLogsCollection(userId).doc(logId).delete();
  }

  @override
  Stream<List<PeriodLogModel>> watchPeriodLogs({required String userId}) {
    return _periodLogsCollection(userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PeriodLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveSymptomLog({
    required String userId,
    required SymptomLogModel log,
  }) {
    return _symptomLogsCollection(userId).doc(log.id).set(
          log.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<SymptomLogModel>> watchSymptomLogs({required String userId}) {
    return _symptomLogsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SymptomLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveCycleSettings({
    required String userId,
    required CycleSettingsModel settings,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('cycle')
        .set(settings.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<CycleSettingsModel?> watchCycleSettings({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('cycle')
        .snapshots()
        .map(
          (doc) => doc.exists ? CycleSettingsModel.fromJson(doc.data()!) : null,
        );
  }

  @override
  Future<void> saveCycleAdaptationPreferences({
    required String userId,
    required CycleAdaptationPreferencesModel preferences,
  }) {
    return _adaptationSettingsDocument(userId).set(
      preferences.toJson(),
      SetOptions(merge: true),
    );
  }

  @override
  Stream<CycleAdaptationPreferencesModel?> watchCycleAdaptationPreferences({
    required String userId,
  }) {
    return _adaptationSettingsDocument(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return CycleAdaptationPreferencesModel.fromJson(doc.data()!);
    });
  }

  CollectionReference<Map<String, dynamic>> _cyclesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('cycles');
  }

  CollectionReference<Map<String, dynamic>> _periodLogsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('periodLogs');
  }

  CollectionReference<Map<String, dynamic>> _symptomLogsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('symptomLogs');
  }

  DocumentReference<Map<String, dynamic>> _adaptationSettingsDocument(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('programAdaptation');
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

class FirestoreEnrolledProgramRepository implements EnrolledProgramRepository {
  FirestoreEnrolledProgramRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> enrollUser({
    required String userId,
    required EnrolledProgramModel enrollment,
  }) async {
    final DateTime now = DateTime.now();
    final EnrolledProgramModel normalizedEnrollment = enrollment.copyWith(
      status: EnrollmentStatus.active,
      lastSyncedAt: now,
      completedAt: null,
      canceledAt: null,
    );
    final DocumentReference<Map<String, dynamic>> enrollmentRef =
        _enrollmentsCollection(userId).doc(normalizedEnrollment.id);
    final WriteBatch batch = _firestore.batch();
    batch.set(
      enrollmentRef,
      normalizedEnrollment.toJson(),
      SetOptions(merge: true),
    );
    _appendEnrollmentEventToBatch(
      batch: batch,
      userId: userId,
      enrollmentId: normalizedEnrollment.id,
      programId: normalizedEnrollment.programId,
      eventType: EnrollmentEventType.enrolled,
      occurredAt: now,
      metadata: const <String, dynamic>{'source': 'enroll'},
    );
    await batch.commit();
  }

  @override
  Stream<EnrolledProgramModel?> watchActiveEnrollment(
      {required String userId}) {
    return _enrollmentsCollection(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastSyncedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<EnrolledProgramModel> activeEnrollments = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = <String, dynamic>{
              ...doc.data(),
              if (!(doc.data().containsKey('id'))) 'id': doc.id,
            };
            return EnrolledProgramModel.fromJson(data);
          })
          .where(
            (EnrolledProgramModel model) =>
                model.status == EnrollmentStatus.active,
          )
          .toList();

      if (activeEnrollments.isEmpty) {
        return null;
      }

      activeEnrollments.sort(
        (EnrolledProgramModel a, EnrolledProgramModel b) =>
            _effectiveSyncTime(b).compareTo(_effectiveSyncTime(a)),
      );
      return activeEnrollments.first;
    });
  }

  @override
  Future<void> cancelEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {
    final DocumentReference<Map<String, dynamic>> enrollmentRef =
        _enrollmentsCollection(userId).doc(enrollmentId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await enrollmentRef.get();
    if (!snapshot.exists) {
      throw StateError('Enrollment "$enrollmentId" not found.');
    }

    final Map<String, dynamic> enrollmentData = snapshot.data()!;
    final String? programId = enrollmentData['programId'] as String?;
    final DateTime now = DateTime.now();
    final WriteBatch batch = _firestore.batch();
    batch.update(enrollmentRef, <String, dynamic>{
      'isActive': false,
      'status': enrollmentStatusToJson(EnrollmentStatus.canceled),
      'canceledAt': now.toIso8601String(),
      'lastSyncedAt': now.toIso8601String(),
    });
    _appendEnrollmentEventToBatch(
      batch: batch,
      userId: userId,
      enrollmentId: enrollmentId,
      programId: programId,
      eventType: EnrollmentEventType.canceled,
      occurredAt: now,
    );
    await batch.commit();
  }

  @override
  Stream<EnrollmentEventModel?> watchLatestEnrollmentEvent({
    required String userId,
    String? enrollmentId,
  }) {
    Query<Map<String, dynamic>> query = _enrollmentEventsCollection(userId)
        .orderBy('occurredAt', descending: true);
    if (enrollmentId != null && enrollmentId.isNotEmpty) {
      query = query.where('enrollmentId', isEqualTo: enrollmentId);
    }

    return query
        .limit(1)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final QueryDocumentSnapshot<Map<String, dynamic>> doc =
          snapshot.docs.first;
      final Map<String, dynamic> data = <String, dynamic>{
        ...doc.data(),
        if (!(doc.data().containsKey('id'))) 'id': doc.id,
      };
      return EnrollmentEventModel.fromJson(data);
    });
  }

  @override
  Future<EnrolledProgramModel?> findLatestCanceledEnrollmentForProgram({
    required String userId,
    required String programId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _enrollmentsCollection(userId)
            .where('programId', isEqualTo: programId)
            .where(
              'status',
              isEqualTo: enrollmentStatusToJson(EnrollmentStatus.canceled),
            )
            .orderBy('canceledAt', descending: true)
            .limit(1)
            .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
    final Map<String, dynamic> data = <String, dynamic>{
      ...doc.data(),
      if (!(doc.data().containsKey('id'))) 'id': doc.id,
    };
    return EnrolledProgramModel.fromJson(data);
  }

  @override
  Future<int> healDuplicateActiveEnrollments({required String userId}) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _enrollmentsCollection(userId)
            .where('isActive', isEqualTo: true)
            .orderBy('lastSyncedAt', descending: true)
            .get();

    if (snapshot.docs.length <= 1) {
      return 0;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        snapshot.docs.toList(growable: false);
    final QueryDocumentSnapshot<Map<String, dynamic>> canonicalDoc = docs.first;
    final String canonicalEnrollmentId = canonicalDoc.id;
    final DateTime now = DateTime.now();
    final WriteBatch batch = _firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in docs.skip(1)) {
      final Map<String, dynamic> data = doc.data();
      final String enrollmentId = doc.id;
      batch.update(doc.reference, <String, dynamic>{
        'isActive': false,
        'status': enrollmentStatusToJson(EnrollmentStatus.canceled),
        'canceledAt': now.toIso8601String(),
        'lastSyncedAt': now.toIso8601String(),
      });
      _appendEnrollmentEventToBatch(
        batch: batch,
        userId: userId,
        enrollmentId: enrollmentId,
        programId: data['programId'] as String?,
        eventType: EnrollmentEventType.autoHealed,
        occurredAt: now,
        metadata: <String, dynamic>{
          'keptEnrollmentId': canonicalEnrollmentId,
        },
      );
    }

    await batch.commit();
    return docs.length - 1;
  }

  @override
  Future<void> recordEnrollmentRestored({
    required String userId,
    required String enrollmentId,
    required String programId,
  }) {
    return _writeEnrollmentEvent(
      userId: userId,
      enrollmentId: enrollmentId,
      programId: programId,
      eventType: EnrollmentEventType.restored,
      metadata: const <String, dynamic>{'source': 'restore'},
    );
  }

  @override
  Future<void> updateEnrollmentProgress({
    required String userId,
    required String enrollmentId,
    required int week,
    required int day,
  }) {
    return _enrollmentsCollection(userId).doc(enrollmentId).update({
      'currentWeek': week,
      'currentDay': day,
      'lastSyncedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> markWeekComplete({
    required String userId,
    required String enrollmentId,
    required int completedWeek,
    required int nextWeek,
  }) {
    return _enrollmentsCollection(userId).doc(enrollmentId).update({
      'completedWeeks': FieldValue.arrayUnion(<int>[completedWeek]),
      'currentWeek': nextWeek,
      'currentDay': 1,
      'lastSyncedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> jumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) {
    return _enrollmentsCollection(userId).doc(enrollmentId).update({
      'currentWeek': week,
      'currentDay': 1,
      'lastSyncedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> completeEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {
    final DocumentReference<Map<String, dynamic>> enrollmentRef =
        _enrollmentsCollection(userId).doc(enrollmentId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await enrollmentRef.get();
    if (!snapshot.exists) {
      throw StateError('Enrollment "$enrollmentId" not found.');
    }
    final String? programId = snapshot.data()!['programId'] as String?;
    final DateTime now = DateTime.now();
    final WriteBatch batch = _firestore.batch();
    batch.update(enrollmentRef, <String, dynamic>{
      'isActive': false,
      'status': enrollmentStatusToJson(EnrollmentStatus.completed),
      'completedAt': DateTime.now().toIso8601String(),
      'lastSyncedAt': now.toIso8601String(),
    });
    _appendEnrollmentEventToBatch(
      batch: batch,
      userId: userId,
      enrollmentId: enrollmentId,
      programId: programId,
      eventType: EnrollmentEventType.completed,
      occurredAt: now,
    );
    await batch.commit();
  }

  @override
  Future<void> stopEnrollment({
    required String userId,
    required String enrollmentId,
  }) {
    return cancelEnrollment(userId: userId, enrollmentId: enrollmentId);
  }

  CollectionReference<Map<String, dynamic>> _enrollmentsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('enrollments');
  }

  CollectionReference<Map<String, dynamic>> _enrollmentEventsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollmentEvents');
  }

  DateTime _effectiveSyncTime(EnrolledProgramModel model) {
    return model.lastSyncedAt ??
        model.canceledAt ??
        model.completedAt ??
        model.startDate;
  }

  void _appendEnrollmentEventToBatch({
    required WriteBatch batch,
    required String userId,
    required String enrollmentId,
    required EnrollmentEventType eventType,
    required DateTime occurredAt,
    String? programId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final DocumentReference<Map<String, dynamic>> eventRef =
        _enrollmentEventsCollection(userId).doc();
    final EnrollmentEventModel event = EnrollmentEventModel(
      id: eventRef.id,
      enrollmentId: enrollmentId,
      programId: programId,
      eventType: eventType,
      occurredAt: occurredAt,
      metadata: metadata,
    );
    batch.set(eventRef, event.toJson(), SetOptions(merge: true));
  }

  Future<void> _writeEnrollmentEvent({
    required String userId,
    required String enrollmentId,
    required EnrollmentEventType eventType,
    String? programId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> eventRef =
        _enrollmentEventsCollection(userId).doc();
    final EnrollmentEventModel event = EnrollmentEventModel(
      id: eventRef.id,
      enrollmentId: enrollmentId,
      programId: programId,
      eventType: eventType,
      occurredAt: now,
      metadata: metadata,
    );
    return eventRef.set(event.toJson(), SetOptions(merge: true));
  }
}
