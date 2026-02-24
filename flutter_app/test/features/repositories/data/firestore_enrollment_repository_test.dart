import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  group('FirestoreEnrolledProgramRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreEnrolledProgramRepository repository;
    const String userId = 'user-1';
    const String enrollmentId = 'enrollment-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreEnrolledProgramRepository(firestore: firestore);
    });

    Future<void> seedEnrollment() async {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: enrollmentId,
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 2,
        currentDay: 3,
      );

      await repository.enrollUser(userId: userId, enrollment: enrollment);
    }

    test('markWeekComplete stores completion and advances to next week',
        () async {
      await seedEnrollment();

      await repository.markWeekComplete(
        userId: userId,
        enrollmentId: enrollmentId,
        completedWeek: 2,
        nextWeek: 3,
      );

      final EnrolledProgramModel? updated =
          await repository.watchActiveEnrollment(userId: userId).first;

      expect(updated, isNotNull);
      expect(updated!.completedWeeks, contains(2));
      expect(updated.currentWeek, 3);
      expect(updated.currentDay, 1);
      expect(updated.lastSyncedAt, isNotNull);
    });

    test('jumpToWeek updates currentWeek/currentDay and keeps isActive',
        () async {
      await seedEnrollment();

      await repository.jumpToWeek(
        userId: userId,
        enrollmentId: enrollmentId,
        week: 5,
      );

      final EnrolledProgramModel? updated =
          await repository.watchActiveEnrollment(userId: userId).first;

      expect(updated, isNotNull);
      expect(updated!.currentWeek, 5);
      expect(updated.currentDay, 1);
      expect(updated.isActive, isTrue);
    });

    test('cancelEnrollment deactivates enrollment and writes canceled event',
        () async {
      await seedEnrollment();

      await repository.cancelEnrollment(
        userId: userId,
        enrollmentId: enrollmentId,
      );

      final EnrolledProgramModel? active =
          await repository.watchActiveEnrollment(userId: userId).first;
      expect(active, isNull);

      final Map<String, dynamic>? enrollmentData = (await firestore
              .collection('users')
              .doc(userId)
              .collection('enrollments')
              .doc(enrollmentId)
              .get())
          .data();
      expect(enrollmentData, isNotNull);
      expect(enrollmentData!['status'], 'canceled');
      expect(enrollmentData['isActive'], isFalse);
      expect(enrollmentData['canceledAt'], isNotNull);

      final EnrollmentEventModel? latestEvent =
          await repository.watchLatestEnrollmentEvent(userId: userId).first;
      expect(latestEvent, isNotNull);
      expect(latestEvent!.eventType, EnrollmentEventType.canceled);
      expect(latestEvent.enrollmentId, enrollmentId);
    });

    test('watchActiveEnrollment returns most recently synced active enrollment',
        () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc('older')
          .set(
            EnrolledProgramModel(
              id: 'older',
              programId: 'program-1',
              startDate: DateTime.utc(2026, 1, 1),
              currentWeek: 2,
              currentDay: 1,
              status: EnrollmentStatus.active,
              lastSyncedAt: DateTime.utc(2026, 2, 20, 10, 0, 0),
            ).toJson(),
          );
      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc('newer')
          .set(
            EnrolledProgramModel(
              id: 'newer',
              programId: 'program-2',
              startDate: DateTime.utc(2026, 1, 10),
              currentWeek: 1,
              currentDay: 1,
              status: EnrollmentStatus.active,
              lastSyncedAt: DateTime.utc(2026, 2, 23, 10, 0, 0),
            ).toJson(),
          );

      final EnrolledProgramModel? active =
          await repository.watchActiveEnrollment(userId: userId).first;

      expect(active, isNotNull);
      expect(active!.id, 'newer');
      expect(active.status, EnrollmentStatus.active);
    });

    test('healDuplicateActiveEnrollments keeps newest and auto-heals others',
        () async {
      Future<void> seed({
        required String id,
        required DateTime syncedAt,
      }) async {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .doc(id)
            .set(
              EnrolledProgramModel(
                id: id,
                programId: 'program-1',
                startDate: DateTime.utc(2026, 1, 1),
                currentWeek: 1,
                currentDay: 1,
                status: EnrollmentStatus.active,
                lastSyncedAt: syncedAt,
              ).toJson(),
            );
      }

      await seed(id: 'active-1', syncedAt: DateTime.utc(2026, 2, 21, 10));
      await seed(id: 'active-2', syncedAt: DateTime.utc(2026, 2, 22, 10));
      await seed(id: 'active-3', syncedAt: DateTime.utc(2026, 2, 23, 10));

      final int healedCount =
          await repository.healDuplicateActiveEnrollments(userId: userId);

      expect(healedCount, 2);

      final EnrolledProgramModel? active =
          await repository.watchActiveEnrollment(userId: userId).first;
      expect(active, isNotNull);
      expect(active!.id, 'active-3');

      final enrollmentSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .where('status', isEqualTo: 'canceled')
          .get();
      expect(enrollmentSnapshot.docs.length, 2);

      final eventSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollmentEvents')
          .where('eventType', isEqualTo: 'auto_healed')
          .get();
      expect(eventSnapshot.docs.length, 2);
    });

    test('findLatestCanceledEnrollmentForProgram returns newest canceled row',
        () async {
      Future<void> seedCanceled({
        required String id,
        required DateTime canceledAt,
      }) async {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .doc(id)
            .set(
              EnrolledProgramModel(
                id: id,
                programId: 'program-1',
                startDate: DateTime.utc(2026, 1, 1),
                currentWeek: 1,
                currentDay: 1,
                status: EnrollmentStatus.canceled,
                canceledAt: canceledAt,
                lastSyncedAt: canceledAt,
              ).toJson(),
            );
      }

      await seedCanceled(
        id: 'canceled-older',
        canceledAt: DateTime.utc(2026, 2, 20, 10),
      );
      await seedCanceled(
        id: 'canceled-newer',
        canceledAt: DateTime.utc(2026, 2, 21, 10),
      );

      final EnrolledProgramModel? latest =
          await repository.findLatestCanceledEnrollmentForProgram(
        userId: userId,
        programId: 'program-1',
      );
      expect(latest, isNotNull);
      expect(latest!.id, 'canceled-newer');
      expect(latest.status, EnrollmentStatus.canceled);
    });

    test('recordEnrollmentRestored appends restored event', () async {
      await repository.recordEnrollmentRestored(
        userId: userId,
        enrollmentId: enrollmentId,
        programId: 'program-1',
      );

      final EnrollmentEventModel? latestEvent = await repository
          .watchLatestEnrollmentEvent(
            userId: userId,
            enrollmentId: enrollmentId,
          )
          .first;
      expect(latestEvent, isNotNull);
      expect(latestEvent!.eventType, EnrollmentEventType.restored);
      expect(latestEvent.programId, 'program-1');
    });

    test('watchActiveEnrollment reads canonical status-only active rows',
        () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc('status-only')
          .set(<String, dynamic>{
        'id': 'status-only',
        'programId': 'program-2',
        'startDate': DateTime.utc(2026, 2, 1).toIso8601String(),
        'currentWeek': 2,
        'currentDay': 1,
        'status': 'active',
        'lastSyncedAt': DateTime.utc(2026, 2, 24, 12, 0, 0).toIso8601String(),
      });

      final EnrolledProgramModel? active =
          await repository.watchActiveEnrollment(userId: userId).first;

      expect(active, isNotNull);
      expect(active!.id, 'status-only');
      expect(active.status, EnrollmentStatus.active);
    });

    test('updateEnrollmentProgress normalizes legacy contract fields',
        () async {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc(enrollmentId)
          .set(<String, dynamic>{
        'programId': 'program-legacy',
        'startDate': DateTime.utc(2026, 1, 1).toIso8601String(),
        'currentWeek': 1,
        'currentDay': 1,
      });

      await repository.updateEnrollmentProgress(
        userId: userId,
        enrollmentId: enrollmentId,
        week: 2,
        day: 3,
      );

      final Map<String, dynamic>? doc = (await firestore
              .collection('users')
              .doc(userId)
              .collection('enrollments')
              .doc(enrollmentId)
              .get())
          .data();

      expect(doc, isNotNull);
      expect(doc!['id'], enrollmentId);
      expect(doc['status'], 'active');
      expect(doc['isActive'], isTrue);
      expect(doc['lastSyncedAt'], isNotNull);
      expect(doc['currentWeek'], 2);
      expect(doc['currentDay'], 3);
    });
  });
}
