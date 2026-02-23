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

    test('markWeekComplete stores completion and advances to next week', () async {
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

    test('jumpToWeek updates currentWeek/currentDay and keeps isActive', () async {
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
  });
}
