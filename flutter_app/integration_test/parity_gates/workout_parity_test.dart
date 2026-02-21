import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sundee_fundee/shared/providers/database_provider.dart';
import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Workout Flow (WORK-01, WORK-02)', () {
    testWidgets('navigates to workout screen via programs and dashboard',
        (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);

      // Navigate to programs, start a cycle, then go to workout
      await startCycleFromPrograms(tester);
      await navigateToWorkoutFromDashboard(tester);

      expect(find.byKey(const Key('workout-screen')), findsOneWidget);
    });

    testWidgets(
        'logs sets and completes workout with Drift persistence (WORK-01)',
        (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      await setupAndNavigateToWorkout(tester);

      // Log first set
      await logSet(tester, setNumber: 1, weight: '135', reps: '5');

      // Dismiss rest timer if it appeared
      await dismissRestTimer(tester);

      // Verify set 1 is visually completed (check icon in row)
      expect(
        find.descendant(
          of: find.byKey(const Key('set-1-row')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
        reason: 'Set 1 should show check icon after logging',
      );

      // Log second set
      await logSet(tester, setNumber: 2, weight: '145', reps: '5');
      await dismissRestTimer(tester);

      // Complete workout
      await tester.tap(find.byKey(const Key('complete-workout-button')));
      await tester.pumpAndSettle();

      // Should navigate to dashboard
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);

      // Verify Drift persistence
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('dashboard-screen'))),
      );
      final db = container.read(databaseProvider);

      final workouts = await db.select(db.completedWorkouts).get();
      expect(workouts, hasLength(1), reason: 'Workout should be persisted');
      expect(workouts.first.programId, 'back-squat-complete-cycle');

      final sets = await (db.select(db.completedSets)
            ..where((t) => t.workoutId.equals(workouts.first.id)))
          .get();
      expect(sets, hasLength(2), reason: 'Two sets should be persisted');
    });

    testWidgets('rest timer appears after logging a set (WORK-02)',
        (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      await setupAndNavigateToWorkout(tester);

      // Log a set
      await logSet(tester, setNumber: 1, weight: '135', reps: '5');

      // Rest timer sheet should appear
      expect(
        find.byKey(const Key('rest-timer-sheet')),
        findsOneWidget,
        reason: 'Rest timer sheet should appear after logging set',
      );

      // Countdown display visible
      expect(find.byKey(const Key('rest-timer-display')), findsOneWidget);

      // Pause the timer
      await tester
          .tap(find.byKey(const Key('rest-timer-pause-resume-button')));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // Resume the timer
      await tester
          .tap(find.byKey(const Key('rest-timer-pause-resume-button')));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);

      // Skip rest
      await tester.tap(find.byKey(const Key('rest-timer-skip-button')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byKey(const Key('rest-timer-sheet')), findsNothing);
    });

    testWidgets(
        'shows discard confirmation when leaving workout with logged sets',
        (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      await setupAndNavigateToWorkout(tester);

      // Log a set
      await logSet(tester, setNumber: 1, weight: '135', reps: '5');
      await dismissRestTimer(tester);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Discard Workout?'), findsOneWidget);

      // Choose Keep
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      // Should still be on workout screen
      expect(find.byKey(const Key('workout-screen')), findsOneWidget);
    });

    testWidgets('completes workout and returns to dashboard', (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      await setupAndNavigateToWorkout(tester);

      // Log one set
      await logSet(tester, setNumber: 1, weight: '100', reps: '5');
      await dismissRestTimer(tester);

      // Complete workout
      await tester.tap(find.byKey(const Key('complete-workout-button')));
      await tester.pumpAndSettle();

      // Should be on dashboard
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    });
  });
}
