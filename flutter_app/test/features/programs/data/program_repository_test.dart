import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/repository_interfaces.dart';

class _FakeEnrolledProgramRepository implements EnrolledProgramRepository {
  String? completeEnrollmentId;
  String? completeEnrollmentUserId;

  String? markWeekEnrollmentId;
  String? markWeekUserId;
  int? markWeekCompletedWeek;
  int? markWeekNextWeek;

  String? jumpWeekEnrollmentId;
  String? jumpWeekUserId;
  int? jumpWeek;

  @override
  Future<void> completeEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {
    completeEnrollmentId = enrollmentId;
    completeEnrollmentUserId = userId;
  }

  @override
  Future<void> enrollUser({
    required String userId,
    required EnrolledProgramModel enrollment,
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
    return Stream<EnrolledProgramModel?>.value(null);
  }

  @override
  Future<void> markWeekComplete({
    required String userId,
    required String enrollmentId,
    required int completedWeek,
    required int nextWeek,
  }) async {
    markWeekUserId = userId;
    markWeekEnrollmentId = enrollmentId;
    markWeekCompletedWeek = completedWeek;
    markWeekNextWeek = nextWeek;
  }

  @override
  Future<void> jumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) async {
    jumpWeekUserId = userId;
    jumpWeekEnrollmentId = enrollmentId;
    jumpWeek = week;
  }
}

void main() {
  group('ProgramRepository', () {
    late _FakeEnrolledProgramRepository enrolledRepository;
    late ProgramRepository repository;

    setUp(() {
      enrolledRepository = _FakeEnrolledProgramRepository();
      repository = ProgramRepository(
        firestore: null,
        enrolledProgramRepository: enrolledRepository,
      );
    });

    test('markWeekComplete delegates to repository and advances week',
        () async {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: 'enrollment-1',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 4,
        currentDay: 3,
      );

      await repository.markWeekComplete(
        userId: 'user-1',
        enrollment: enrollment,
        programDurationWeeks: 12,
      );

      expect(enrolledRepository.markWeekUserId, 'user-1');
      expect(enrolledRepository.markWeekEnrollmentId, 'enrollment-1');
      expect(enrolledRepository.markWeekCompletedWeek, 4);
      expect(enrolledRepository.markWeekNextWeek, 5);
      expect(enrolledRepository.completeEnrollmentId, isNull);
    });

    test('markWeekComplete completes enrollment when final week is complete',
        () async {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: 'enrollment-2',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 12,
        currentDay: 3,
      );

      await repository.markWeekComplete(
        userId: 'user-1',
        enrollment: enrollment,
        programDurationWeeks: 12,
      );

      expect(enrolledRepository.markWeekCompletedWeek, 12);
      expect(enrolledRepository.markWeekNextWeek, 12);
      expect(enrolledRepository.completeEnrollmentId, 'enrollment-2');
      expect(enrolledRepository.completeEnrollmentUserId, 'user-1');
    });

    test('jumpToWeek delegates to enrollment repository', () async {
      await repository.jumpToWeek(
        userId: 'user-1',
        enrollmentId: 'enrollment-9',
        week: 7,
      );

      expect(enrolledRepository.jumpWeekUserId, 'user-1');
      expect(enrolledRepository.jumpWeekEnrollmentId, 'enrollment-9');
      expect(enrolledRepository.jumpWeek, 7);
    });

    test('findProgramById returns matching program when present', () {
      final ProgramV2 program = ProgramV2(
        id: 'program-1',
        name: 'Program',
        category: 'Strength',
        description: 'desc',
        durationWeeks: 12,
        sessionsPerWeek: 3,
        difficulty: 'Intermediate',
        phases: const <ProgramPhase>[],
        weeks: const <ProgramWeek>[],
      );

      final ProgramV2? result = repository.findProgramById(
        programs: <ProgramV2>[program],
        programId: 'program-1',
      );

      expect(result, isNotNull);
      expect(result!.id, 'program-1');
    });

    test('findProgramById returns null when program is missing', () {
      final ProgramV2? result = repository.findProgramById(
        programs: const <ProgramV2>[],
        programId: 'missing-program',
      );

      expect(result, isNull);
    });
  });
}
