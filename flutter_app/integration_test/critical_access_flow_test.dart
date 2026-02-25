import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/app/app.dart';
import 'package:sundee_fundee_flutter/app/router.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/enrollment_lifecycle_provider.dart';

import 'support/firebase_emulator_test_harness.dart';

const bool _seedVerificationAccount = bool.fromEnvironment(
  'SEED_VERIFICATION_ACCOUNT',
  defaultValue: false,
);

ProgramV2 _program() {
  return ProgramV2(
    id: 'program-1',
    name: 'Canonical Verification Program',
    category: 'Strength',
    description: 'Used for login -> dashboard -> programs -> workout start.',
    durationWeeks: 8,
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
            sessionName: 'Session 1',
            sessionType: 'Lift',
            focus: 'Strength',
            exercises: <ProgramExercise>[
              ProgramExercise(
                exercise: 'Back Squat',
                variant: null,
                sets: ExerciseValue.fixed(1),
                reps: ExerciseValue.fixed(5),
                percent1Rm: 0.8,
                restMinutes: 3,
                notes: null,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

EnrolledProgramModel _activeEnrollment() {
  return EnrolledProgramModel(
    id: 'enrollment-1',
    programId: 'program-1',
    startDate: DateTime.utc(2026, 2, 1),
    currentWeek: 1,
    currentDay: 1,
    status: EnrollmentStatus.active,
  );
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('critical access flow checkpoints', () {
    testWidgets(
        'unauthenticated guard blocks home, programs, and workout routes',
        (WidgetTester tester) async {
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/',
        ),
        '/auth',
      );
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/workout',
        ),
        '/auth',
      );
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/onboarding',
        ),
        '/auth',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStreamProvider.overrideWith(
              (Ref ref) => Stream<AuthSession>.value(
                const AuthSession(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
          child: const SundeeFundeeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Programs'), findsNothing);
      expect(find.text('Workout'), findsNothing);
      expect(find.textContaining('permission-denied'), findsNothing);
    });

    testWidgets(
        'login -> dashboard -> programs -> workout start remains stable for canonical account',
        (WidgetTester tester) async {
      await FirebaseEmulatorTestHarness.initializeHarness();
      if (_seedVerificationAccount) {
        await FirebaseEmulatorTestHarness.seedVerificationAccount();
      }

      final StreamController<AuthSession> authController =
          StreamController<AuthSession>.broadcast();
      addTearDown(authController.close);

      final ProgramV2 program = _program();
      final EnrolledProgramModel enrollment = _activeEnrollment();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStreamProvider.overrideWith((Ref ref) {
              return authController.stream;
            }),
            programsProvider.overrideWith(
              (Ref ref) async => <ProgramV2>[program],
            ),
            enrollmentLifecycleStateProvider.overrideWith(
              (Ref ref) => Stream<EnrollmentLifecycleState>.value(
                EnrollmentLifecycleState.active(enrollment: enrollment),
              ),
            ),
            activeEnrollmentProvider.overrideWith(
              (Ref ref) => Stream<EnrolledProgramModel?>.value(enrollment),
            ),
            injuryAdaptedActiveProgramProvider.overrideWith(
              (Ref ref) => AsyncData<ProgramV2?>(program),
            ),
          ],
          child: const SundeeFundeeApp(),
        ),
      );

      authController.add(
        const AuthSession(status: AuthStatus.unauthenticated),
      );
      await tester.pumpAndSettle();
      await FirebaseEmulatorTestHarness.checkpoint(
        name: 'login screen',
        condition: find.text('Sign In').evaluate().isNotEmpty,
      );

      authController.add(
        const AuthSession(status: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();
      await FirebaseEmulatorTestHarness.checkpoint(
        name: 'dashboard loaded',
        condition: find.text('Next Workout').evaluate().isNotEmpty,
      );

      await tester.tap(_navigationLabel('Programs'));
      await tester.pumpAndSettle();
      await FirebaseEmulatorTestHarness.checkpoint(
        name: 'programs loaded',
        condition: find.text(program.name).evaluate().isNotEmpty,
      );

      await tester.tap(_navigationLabel('Workout'));
      await tester.pumpAndSettle();
      await FirebaseEmulatorTestHarness.checkpoint(
        name: 'workout landing loaded',
        condition: find.text('START SESSION').evaluate().isNotEmpty,
      );

      await tester.tap(find.text('START SESSION'));
      await tester.pumpAndSettle();

      expect(find.textContaining('(W1:D1)'), findsOneWidget);
      expect(find.text('Resume onboarding'), findsNothing);
      expect(find.textContaining('permission-denied'), findsNothing);
    });
  });
}
