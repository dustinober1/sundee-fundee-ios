import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/enrollment_lifecycle_provider.dart';
import 'package:sundee_fundee_flutter/features/workouts/presentation/workout_landing_screen.dart';

ProgramV2 _buildProgram() {
  return ProgramV2(
    id: 'program-1',
    name: '12-Week Squad Squat Peak',
    category: 'Squat',
    description: 'desc',
    durationWeeks: 12,
    sessionsPerWeek: 1,
    difficulty: 'Intermediate',
    phases: const <ProgramPhase>[],
    weeks: <ProgramWeek>[
      ProgramWeek(
        week: 1,
        phaseId: 'phase-1',
        isTestWeek: false,
        sessions: <ProgramSession>[
          ProgramSession(
            sessionId: 'session-1',
            sessionName: 'Session A',
            sessionType: 'Lift',
            focus: 'Strength',
            exercises: const <ProgramExercise>[],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('shows canceled-state messaging and hides start actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enrollmentLifecycleStateProvider.overrideWith(
            (Ref ref) => Stream<EnrollmentLifecycleState>.value(
              EnrollmentLifecycleState.canceled(
                latestEvent: EnrollmentEventModel(
                  id: 'event-1',
                  enrollmentId: 'enrollment-1',
                  eventType: EnrollmentEventType.canceled,
                  occurredAt: DateTime.utc(2026, 2, 24, 12, 0, 0),
                ),
              ),
            ),
          ),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.guest),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorkoutLandingScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No active plan'), findsWidgets);
    expect(find.text('START SESSION'), findsNothing);
    expect(find.text('RESUME WORKOUT'), findsNothing);
  });

  testWidgets('renders start action when lifecycle state is active',
      (WidgetTester tester) async {
    final EnrolledProgramModel enrollment = EnrolledProgramModel(
      id: 'enrollment-1',
      programId: 'program-1',
      startDate: DateTime.utc(2026, 1, 1),
      currentWeek: 1,
      currentDay: 1,
      status: EnrollmentStatus.active,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enrollmentLifecycleStateProvider.overrideWith(
            (Ref ref) => Stream<EnrollmentLifecycleState>.value(
              EnrollmentLifecycleState.active(enrollment: enrollment),
            ),
          ),
          injuryAdaptedActiveProgramProvider.overrideWith(
            (Ref ref) => AsyncData<ProgramV2?>(_buildProgram()),
          ),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.guest),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorkoutLandingScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('START SESSION'), findsOneWidget);
    expect(find.text('No active plan'), findsNothing);
  });

  testWidgets('shows recoverable banner while preserving landing content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enrollmentLifecycleStateProvider.overrideWith(
            (Ref ref) => Stream<EnrollmentLifecycleState>.value(
              const EnrollmentLifecycleState.recoverableFailure(
                errorMessage: 'Temporary access issue.',
                retryAttempt: 1,
                maxRetries: 3,
              ),
            ),
          ),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.guest),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorkoutLandingScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connection issue'), findsOneWidget);
    expect(find.text('No active plan'), findsWidgets);
    expect(find.textContaining('Error loading enrollment'), findsNothing);
  });
}
