import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/repository_interfaces.dart';

class _NoopEnrolledProgramRepository implements EnrolledProgramRepository {
  @override
  Future<void> completeEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {}

  @override
  Future<void> enrollUser({
    required String userId,
    required EnrolledProgramModel enrollment,
  }) async {}

  @override
  Future<void> cancelEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {}

  @override
  Future<void> jumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) async {}

  @override
  Future<void> markWeekComplete({
    required String userId,
    required String enrollmentId,
    required int completedWeek,
    required int nextWeek,
  }) async {}

  @override
  Future<void> stopEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {}

  @override
  Future<void> updateEnrollmentProgress({
    required String userId,
    required String enrollmentId,
    required int week,
    required int day,
  }) async {}

  @override
  Stream<EnrolledProgramModel?> watchActiveEnrollment(
      {required String userId}) {
    return const Stream<EnrolledProgramModel?>.empty();
  }

  @override
  Stream<EnrollmentEventModel?> watchLatestEnrollmentEvent({
    required String userId,
    String? enrollmentId,
  }) {
    return const Stream<EnrollmentEventModel?>.empty();
  }

  @override
  Future<EnrolledProgramModel?> findLatestCanceledEnrollmentForProgram({
    required String userId,
    required String programId,
  }) async {
    return null;
  }

  @override
  Future<int> healDuplicateActiveEnrollments({required String userId}) async {
    return 0;
  }

  @override
  Future<void> recordEnrollmentRestored({
    required String userId,
    required String enrollmentId,
    required String programId,
  }) async {}
}

void main() {
  group('Phase 1 Firestore smoke tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreCycleRepository cycleRepository;
    late FirestoreEnrolledProgramRepository enrolledRepository;
    const String userId = 'user-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      cycleRepository = FirestoreCycleRepository(firestore: firestore);
      enrolledRepository =
          FirestoreEnrolledProgramRepository(firestore: firestore);
    });

    test('cycle period logs and settings read/write paths work', () async {
      final PeriodLogModel log = PeriodLogModel(
        id: 'period-1',
        userId: userId,
        startDate: DateTime.utc(2026, 2, 20),
        endDate: DateTime.utc(2026, 2, 24),
        flowLevel: FlowLevel.medium,
        notes: 'smoke',
      );
      final CycleSettingsModel settings = CycleSettingsModel(
        id: 'settings',
        userId: userId,
        averageCycleLength: 28,
        averagePeriodLength: 5,
        lutealPhaseLength: 14,
        enabledSymptomIds: const <String>['cramps'],
        notificationsEnabled: true,
      );

      await cycleRepository.savePeriodLog(userId: userId, log: log);
      await cycleRepository.saveCycleSettings(
          userId: userId, settings: settings);

      final List<PeriodLogModel> logs =
          await cycleRepository.watchPeriodLogs(userId: userId).first;
      final CycleSettingsModel? savedSettings =
          await cycleRepository.watchCycleSettings(userId: userId).first;

      expect(logs, hasLength(1));
      expect(logs.first.id, 'period-1');
      expect(savedSettings, isNotNull);
      expect(savedSettings!.notificationsEnabled, isTrue);
    });

    test('enrollment create/watch/update/cancel/heal flow works', () async {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: 'enrollment-1',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 1,
        currentDay: 1,
      );

      await enrolledRepository.enrollUser(
          userId: userId, enrollment: enrollment);
      await enrolledRepository.updateEnrollmentProgress(
        userId: userId,
        enrollmentId: enrollment.id,
        week: 1,
        day: 2,
      );
      await enrolledRepository.markWeekComplete(
        userId: userId,
        enrollmentId: enrollment.id,
        completedWeek: 1,
        nextWeek: 2,
      );
      await enrolledRepository.jumpToWeek(
        userId: userId,
        enrollmentId: enrollment.id,
        week: 3,
      );

      EnrolledProgramModel? active =
          await enrolledRepository.watchActiveEnrollment(userId: userId).first;
      expect(active, isNotNull);
      expect(active!.currentWeek, 3);
      expect(active.currentDay, 1);
      expect(active.completedWeeks, contains(1));

      await enrolledRepository.cancelEnrollment(
        userId: userId,
        enrollmentId: enrollment.id,
      );
      active =
          await enrolledRepository.watchActiveEnrollment(userId: userId).first;
      expect(active, isNull);

      final EnrollmentEventModel? latestEvent = await enrolledRepository
          .watchLatestEnrollmentEvent(userId: userId)
          .first;
      expect(latestEvent, isNotNull);
      expect(latestEvent!.eventType, EnrollmentEventType.canceled);

      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc('enrollment-2')
          .set(
            EnrolledProgramModel(
              id: 'enrollment-2',
              programId: 'program-2',
              startDate: DateTime.utc(2026, 2, 1),
              currentWeek: 1,
              currentDay: 1,
              status: EnrollmentStatus.active,
              lastSyncedAt: DateTime.utc(2026, 2, 10, 8),
            ).toJson(),
          );
      await firestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .doc('enrollment-3')
          .set(
            EnrolledProgramModel(
              id: 'enrollment-3',
              programId: 'program-2',
              startDate: DateTime.utc(2026, 2, 1),
              currentWeek: 1,
              currentDay: 1,
              status: EnrollmentStatus.active,
              lastSyncedAt: DateTime.utc(2026, 2, 11, 8),
            ).toJson(),
          );

      final int healed = await enrolledRepository
          .healDuplicateActiveEnrollments(userId: userId);
      expect(healed, 1);
      final EnrolledProgramModel? healedActive =
          await enrolledRepository.watchActiveEnrollment(userId: userId).first;
      expect(healedActive, isNotNull);
      expect(healedActive!.id, 'enrollment-3');
    });

    test(
        'program repository falls back to bundled program when firestore is empty',
        () async {
      final ProgramRepository repository = ProgramRepository(
        firestore: firestore,
        enrolledProgramRepository: _NoopEnrolledProgramRepository(),
      );

      final List<ProgramV2> programs = await repository.getPrograms();
      expect(programs, isNotEmpty);
      expect(programs.first.id, isNotEmpty);
    });
  });
}
