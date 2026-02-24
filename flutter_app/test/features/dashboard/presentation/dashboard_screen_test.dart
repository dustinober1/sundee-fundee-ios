import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/enrollment_lifecycle_provider.dart';

ProviderScope _wrap({
  required Stream<EnrollmentLifecycleState> lifecycleStream,
}) {
  return ProviderScope(
    overrides: [
      authSessionStreamProvider.overrideWith(
        (Ref ref) => Stream<AuthSession>.value(
          const AuthSession(status: AuthStatus.guest),
        ),
      ),
      enrollmentLifecycleStateProvider.overrideWith(
        (Ref ref) => lifecycleStream,
      ),
      injuryAdaptedActiveProgramProvider.overrideWith(
        (Ref ref) => const AsyncData(null),
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
    ],
    child: const MaterialApp(
      home: Scaffold(body: DashboardScreen()),
    ),
  );
}

void main() {
  testWidgets('shows recoverable banner while preserving next-workout content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        lifecycleStream: Stream<EnrollmentLifecycleState>.value(
          const EnrollmentLifecycleState.recoverableFailure(
            errorMessage: 'Temporary read issue.',
            retryAttempt: 1,
            maxRetries: 3,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connection issue'), findsOneWidget);
    expect(find.text('No active plan'), findsOneWidget);
    expect(find.textContaining('Error loading next workout'), findsNothing);
  });

  testWidgets('shows blocking card with retry action after retry exhaustion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        lifecycleStream: Stream<EnrollmentLifecycleState>.value(
          const EnrollmentLifecycleState.blockingFailure(
            errorMessage: 'Persistent access error.',
            recoverable: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manual retry required'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
