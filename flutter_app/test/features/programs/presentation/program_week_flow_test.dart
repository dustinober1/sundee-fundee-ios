import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_calculations.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/cycle/providers.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';
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

class _TrackingProgramRepository extends ProgramRepository {
  _TrackingProgramRepository()
      : super(
          firestore: null,
          enrolledProgramRepository: _NoopEnrolledProgramRepository(),
        );

  int? jumpedToWeek;
  bool markedWeekComplete = false;

  @override
  Future<void> jumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) async {
    jumpedToWeek = week;
  }

  @override
  Future<void> markWeekComplete({
    required String userId,
    required EnrolledProgramModel enrollment,
    required int programDurationWeeks,
  }) async {
    markedWeekComplete = true;
  }
}

ProgramV2 _program() {
  ProgramWeek week(int weekNumber) {
    return ProgramWeek(
      week: weekNumber,
      phaseId: 'phase',
      isTestWeek: false,
      sessions: <ProgramSession>[
        ProgramSession(
          sessionId: 's-$weekNumber-1',
          sessionName: 'Session A',
          sessionType: 'Lift',
          focus: 'Focus',
          exercises: <ProgramExercise>[
            ProgramExercise(
              exercise: 'Back Squat',
              variant: null,
              sets: ExerciseValue.fixed(3),
              reps: ExerciseValue.fixed(5),
              percent1Rm: 0.75,
              restMinutes: 3,
              notes: null,
            ),
          ],
        ),
      ],
    );
  }

  return ProgramV2(
    id: 'program-1',
    name: 'Program 1',
    category: 'Strength',
    description: 'desc',
    durationWeeks: 12,
    sessionsPerWeek: 1,
    difficulty: 'Intermediate',
    phases: const <ProgramPhase>[],
    weeks: <ProgramWeek>[week(1), week(2)],
  );
}

CycleStatusResult _cycleStatus() {
  return CycleStatusResult(
    currentPhase: CyclePhase.follicular,
    cycleDay: 7,
    daysUntilNextPhase: 5,
    predictedNextPeriod: DateTime.utc(2026, 3, 1),
    phaseStartDate: DateTime.utc(2026, 2, 20),
    phaseEndDate: DateTime.utc(2026, 2, 24),
  );
}

void main() {
  testWidgets('week flow supports jump-to-week and manual week completion', (
    WidgetTester tester,
  ) async {
    final _TrackingProgramRepository repository = _TrackingProgramRepository();
    final EnrolledProgramModel enrollment = EnrolledProgramModel(
      id: 'enrollment-1',
      programId: 'program-1',
      startDate: DateTime.utc(2026, 1, 1),
      currentWeek: 1,
      currentDay: 1,
      completedWeeks: const <int>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider
              .overrideWith((Ref ref) async => <ProgramV2>[_program()]),
          activeEnrollmentProvider.overrideWith(
            (Ref ref) => Stream<EnrolledProgramModel?>.value(enrollment),
          ),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.guest),
            ),
          ),
          cycleStatusProvider.overrideWith((Ref ref) => _cycleStatus()),
          programRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: ProgramsScreen())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final Finder jumpButton =
        find.widgetWithText(OutlinedButton, 'Jump to Week').first;
    await tester.ensureVisible(jumpButton);
    await tester.tap(jumpButton);
    await tester.pumpAndSettle();
    expect(repository.jumpedToWeek, isNotNull);

    final Finder completeButton =
        find.widgetWithText(ElevatedButton, 'Mark Week Complete');
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pumpAndSettle();
    expect(repository.markedWeekComplete, isTrue);
  });
}
