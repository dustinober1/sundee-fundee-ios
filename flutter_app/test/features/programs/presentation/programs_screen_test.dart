import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/cycle/providers.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/enrollment_lifecycle_provider.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/sync_status_model.dart';

ProgramV2 _program() {
  return ProgramV2(
    id: 'program-1',
    name: 'Test Program',
    category: 'Strength',
    description: 'desc',
    durationWeeks: 8,
    sessionsPerWeek: 1,
    difficulty: 'Beginner',
    phases: const <ProgramPhase>[],
    weeks: <ProgramWeek>[
      ProgramWeek(
        week: 1,
        phaseId: null,
        isTestWeek: false,
        sessions: <ProgramSession>[
          ProgramSession(
            sessionId: 's-1',
            sessionName: 'Session 1',
            sessionType: 'Lift',
            focus: 'Strength',
            exercises: const <ProgramExercise>[],
          ),
        ],
      ),
    ],
  );
}

ProviderScope _wrapWithOverrides({
  required Widget child,
  required Stream<EnrollmentLifecycleState> lifecycleStream,
}) {
  return ProviderScope(
    overrides: [
      authSessionStreamProvider.overrideWith(
        (Ref ref) => Stream<AuthSession>.value(
          const AuthSession(status: AuthStatus.guest),
        ),
      ),
      programsProvider.overrideWith(
        (Ref ref) async => <ProgramV2>[_program()],
      ),
      enrollmentLifecycleStateProvider.overrideWith(
        (Ref ref) => lifecycleStream,
      ),
      injuryAdaptedActiveProgramProvider.overrideWith(
        (Ref ref) => const AsyncData<ProgramV2?>(null),
      ),
      programAdaptationContextProvider.overrideWith(
        (Ref ref) => const ProgramAdaptationContext(
          isAdapted: false,
          phase: null,
          confidence: AdaptationConfidence.high,
          showAdjustmentDetails: true,
          autoApplyDuringWorkout: false,
        ),
      ),
      injuryAdaptationContextProvider.overrideWith(
        (Ref ref) => const InjuryAdaptationContext(
          hasActiveInjuries: false,
          activeInjuries: <InjuryProfileModel>[],
          disclaimerAcknowledgedForAll: true,
        ),
      ),
      cycleStatusProvider.overrideWith((Ref ref) => null),
      cycleSyncStatusProvider.overrideWith(
        (Ref ref) => SyncStatusModel.fromLastSynced(
          fromCache: false,
          pendingWrites: false,
          lastSyncedAt: null,
          now: DateTime.utc(2026, 2, 24, 12),
        ),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('renders recoverable banner while keeping catalog visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        lifecycleStream: Stream<EnrollmentLifecycleState>.value(
          const EnrollmentLifecycleState.recoverableFailure(
            errorMessage: 'Temporary access issue.',
            retryAttempt: 1,
            maxRetries: 3,
          ),
        ),
        child: const MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connection issue'), findsOneWidget);
    expect(find.text('Test Program'), findsOneWidget);
    expect(find.textContaining('Error:'), findsNothing);
  });

  testWidgets('renders blocking access state with retry action',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        lifecycleStream: Stream<EnrollmentLifecycleState>.value(
          const EnrollmentLifecycleState.blockingFailure(
            errorMessage: 'Persistent access error.',
            recoverable: true,
          ),
        ),
        child: const MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Access unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
