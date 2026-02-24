import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_calculations.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/cycle/providers.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/enrollment_lifecycle_provider.dart';
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
    return Stream<EnrolledProgramModel?>.value(null);
  }

  @override
  Stream<EnrollmentEventModel?> watchLatestEnrollmentEvent({
    required String userId,
    String? enrollmentId,
  }) {
    return Stream<EnrollmentEventModel?>.value(null);
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

class _FakeProgramRepository extends ProgramRepository {
  _FakeProgramRepository({
    this.throwOnCancel = false,
  }) : super(
          firestore: null,
          enrolledProgramRepository: _NoopEnrolledProgramRepository(),
        );

  final bool throwOnCancel;
  bool markWeekCompleteCalled = false;
  bool jumpToWeekCalled = false;
  bool cancelEnrollmentCalled = false;
  String? cancelEnrollmentId;
  bool enrollUserCalled = false;

  @override
  Future<void> markWeekComplete({
    required String userId,
    required EnrolledProgramModel enrollment,
    required int programDurationWeeks,
  }) async {
    markWeekCompleteCalled = true;
  }

  @override
  Future<void> jumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) async {
    jumpToWeekCalled = true;
  }

  @override
  Future<void> cancelEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {
    if (throwOnCancel) {
      throw Exception('cancel failed');
    }
    cancelEnrollmentCalled = true;
    cancelEnrollmentId = enrollmentId;
  }

  @override
  Future<void> enrollUser({
    required String userId,
    required String programId,
  }) async {
    enrollUserCalled = true;
  }
}

ProgramV2 _buildProgram() {
  ProgramWeek week({
    required int number,
    required String focus,
  }) {
    return ProgramWeek(
      week: number,
      phaseId: 'phase',
      isTestWeek: false,
      sessions: <ProgramSession>[
        ProgramSession(
          sessionId: 'w${number}a',
          sessionName: 'Session A',
          sessionType: 'Lift',
          focus: focus,
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
        ProgramSession(
          sessionId: 'w${number}b',
          sessionName: 'Session B',
          sessionType: 'Lift',
          focus: focus,
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
    name: '12-Week Squad Squat Peak',
    category: 'Squat',
    description: 'desc',
    durationWeeks: 12,
    sessionsPerWeek: 2,
    difficulty: 'Intermediate',
    phases: <ProgramPhase>[],
    weeks: <ProgramWeek>[
      week(number: 1, focus: 'Foundation'),
      week(number: 2, focus: 'Strength'),
    ],
  );
}

CycleStatusResult _menstrualStatus() {
  return CycleStatusResult(
    currentPhase: CyclePhase.menstrual,
    cycleDay: 2,
    daysUntilNextPhase: 3,
    predictedNextPeriod: DateTime.utc(2026, 3, 1),
    phaseStartDate: DateTime.utc(2026, 2, 20),
    phaseEndDate: DateTime.utc(2026, 2, 24),
  );
}

const Object _defaultEnrollmentSentinel = Object();

Future<void> _pumpScreen({
  required WidgetTester tester,
  required _FakeProgramRepository repository,
  required CycleStatusResult? cycleStatus,
  Object? enrollment = _defaultEnrollmentSentinel,
  EnrollmentEventModel? latestEvent,
}) async {
  final EnrolledProgramModel? resolvedEnrollment =
      identical(enrollment, _defaultEnrollmentSentinel)
          ? EnrolledProgramModel(
              id: 'enrollment-1',
              programId: 'program-1',
              startDate: DateTime.utc(2026, 1, 1),
              currentWeek: 2,
              currentDay: 1,
              completedWeeks: const <int>[1],
              lastSyncedAt: DateTime.utc(2026, 2, 23, 11, 0, 0),
            )
          : enrollment as EnrolledProgramModel?;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        programsProvider
            .overrideWith((Ref ref) async => <ProgramV2>[_buildProgram()]),
        activeEnrollmentProvider.overrideWith(
          (Ref ref) => Stream<EnrolledProgramModel?>.value(resolvedEnrollment),
        ),
        latestEnrollmentEventProvider.overrideWith(
          (Ref ref) => Stream<EnrollmentEventModel?>.value(latestEvent),
        ),
        authSessionStreamProvider.overrideWith(
          (Ref ref) => Stream<AuthSession>.value(
            const AuthSession(status: AuthStatus.guest),
          ),
        ),
        cycleStatusProvider.overrideWith((Ref ref) => cycleStatus),
        programRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: ProgramsScreen())),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders week cards with metadata, progress, and manual controls',
      (
    WidgetTester tester,
  ) async {
    final _FakeProgramRepository repository = _FakeProgramRepository();
    await _pumpScreen(
      tester: tester,
      repository: repository,
      cycleStatus: _menstrualStatus(),
    );

    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('Week 2'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('2 workouts'), findsNWidgets(2));
    expect(find.text('Mark Week Complete'), findsOneWidget);
    expect(find.textContaining('Sharkweek active'), findsOneWidget);
  });

  testWidgets(
      'shows neutral cycle unavailable message when cycle data is missing', (
    WidgetTester tester,
  ) async {
    final _FakeProgramRepository repository = _FakeProgramRepository();
    await _pumpScreen(
      tester: tester,
      repository: repository,
      cycleStatus: null,
    );

    expect(find.textContaining('Cycle data unavailable'), findsOneWidget);
  });

  testWidgets('shows inline write error banner when cancel action fails', (
    WidgetTester tester,
  ) async {
    final _FakeProgramRepository repository =
        _FakeProgramRepository(throwOnCancel: true);
    await _pumpScreen(
      tester: tester,
      repository: repository,
      cycleStatus: _menstrualStatus(),
    );

    await tester.ensureVisible(find.text('Cancel plan'));
    await tester.tap(find.text('Cancel plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CANCEL PLAN'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not cancel plan'), findsOneWidget);
  });

  testWidgets('cancel flow uses two-step confirmation and cancels enrollment',
      (WidgetTester tester) async {
    final _FakeProgramRepository repository = _FakeProgramRepository();
    await _pumpScreen(
      tester: tester,
      repository: repository,
      cycleStatus: _menstrualStatus(),
    );

    await tester.ensureVisible(find.text('Cancel plan'));
    await tester.tap(find.text('Cancel plan'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel your plan?'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('This cannot be undone'), findsOneWidget);
    await tester.tap(find.text('CANCEL PLAN'));
    await tester.pumpAndSettle();

    expect(repository.cancelEnrollmentCalled, isTrue);
    expect(repository.cancelEnrollmentId, 'enrollment-1');
  });

  testWidgets('renders explicit canceled replacement state with both CTAs',
      (WidgetTester tester) async {
    final _FakeProgramRepository repository = _FakeProgramRepository();
    await _pumpScreen(
      tester: tester,
      repository: repository,
      cycleStatus: _menstrualStatus(),
      enrollment: null,
      latestEvent: EnrollmentEventModel(
        id: 'event-1',
        enrollmentId: 'enrollment-1',
        eventType: EnrollmentEventType.canceled,
        occurredAt: DateTime.utc(2026, 2, 24, 11, 0, 0),
      ),
    );

    expect(find.text('No active plan'), findsOneWidget);
    expect(find.text('Browse plans'), findsOneWidget);
    expect(find.text('Enroll in new plan'), findsOneWidget);
    expect(find.textContaining('Canceled on'), findsOneWidget);
    expect(find.text('Mark Week Complete'), findsNothing);
  });

  testWidgets('shows cycle adjustment explainer with hide/show controls', (
    WidgetTester tester,
  ) async {
    final _FakeProgramRepository repository = _FakeProgramRepository();
    final EnrolledProgramModel enrollment = EnrolledProgramModel(
      id: 'enrollment-1',
      programId: 'program-1',
      startDate: DateTime.utc(2026, 1, 1),
      currentWeek: 2,
      currentDay: 1,
      completedWeeks: const <int>[1],
      lastSyncedAt: DateTime.utc(2026, 2, 23, 11, 0, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider
              .overrideWith((Ref ref) async => <ProgramV2>[_buildProgram()]),
          activeEnrollmentProvider.overrideWith(
            (Ref ref) => Stream<EnrolledProgramModel?>.value(enrollment),
          ),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.guest),
            ),
          ),
          cycleStatusProvider.overrideWith((Ref ref) => _menstrualStatus()),
          adaptedActiveProgramProvider.overrideWith(
            (Ref ref) => AsyncData<ProgramV2?>(_buildProgram()),
          ),
          programAdaptationContextProvider.overrideWith(
            (Ref ref) => const ProgramAdaptationContext(
              isAdapted: true,
              phase: CyclePhase.menstrual,
              confidence: AdaptationConfidence.medium,
              showAdjustmentDetails: true,
              autoApplyDuringWorkout: false,
            ),
          ),
          cycleAdjustmentDetailsVisibleProvider.overrideWith((Ref ref) => true),
          programRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: ProgramsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Cycle-adjusted:'), findsOneWidget);
    expect(find.text('Hide details'), findsOneWidget);
    expect(find.text('Cycle-adjusted'), findsOneWidget);
  });
}
