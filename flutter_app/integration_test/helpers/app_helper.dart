import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee/app.dart';

/// Pumps the full app under test.
///
/// Every parity gate test starts with [pumpApp] to ensure identical
/// app bootstrap across all platforms. Connectivity overrides are applied
/// via [ConnectivityPlatform.instance] before calling this (see offline tests).
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: SundeeFundeeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Completes the full 3-step onboarding flow so tests that need the
/// dashboard can skip the onboarding setup boilerplate.
///
/// Step 1: Enter name "Test User" → tap Next
/// Step 2: Tap Beginner → tap Next
/// Step 3: Tap Start Training
Future<void> completeOnboarding(WidgetTester tester) async {
  // Step 1 — name
  await tester.enterText(
    find.byKey(const Key('onboarding-name-input')),
    'Test User',
  );
  await tester.tap(find.byKey(const Key('onboarding-next-button')));
  await tester.pumpAndSettle();

  // Step 2 — experience
  await tester.tap(find.byKey(const Key('experience-beginner')));
  await tester.tap(find.byKey(const Key('onboarding-next-button')));
  await tester.pumpAndSettle();

  // Step 3 — start
  await tester.tap(find.byKey(const Key('onboarding-start-button')));
  await tester.pumpAndSettle();
}

/// Starts a training cycle for the test user and navigates back to dashboard.
///
/// Prerequisites: [completeOnboarding] must have been called.
/// After this, the dashboard will show the active cycle with Start Workout button.
Future<void> startCycleFromPrograms(
  WidgetTester tester, {
  String programCardKey = 'program-card-back-squat-complete-cycle',
}) async {
  // Navigate to programs
  await tester.tap(find.byKey(const Key('nav-programs')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('programs-screen')), findsOneWidget);

  // Tap the program card to go to detail screen
  await tester.tap(find.byKey(Key(programCardKey)));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('program-detail-screen')), findsOneWidget);

  // Start the cycle
  final startButton = find.byKey(const Key('start-cycle-button'));
  if (startButton.evaluate().isNotEmpty) {
    await tester.tap(startButton);
    await tester.pumpAndSettle();
  }

  // Should be back on dashboard
  expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
}

/// Navigate to workout screen from dashboard (assumes active cycle exists).
Future<void> navigateToWorkoutFromDashboard(WidgetTester tester) async {
  expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
  // Tap Start Workout button
  await tester.tap(find.byKey(const Key('start-workout-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('workout-screen')), findsOneWidget);
}

/// Full flow: start cycle from programs → navigate to workout screen.
///
/// Prerequisites: [completeOnboarding] must have been called.
Future<void> setupAndNavigateToWorkout(WidgetTester tester) async {
  await startCycleFromPrograms(tester);
  await navigateToWorkoutFromDashboard(tester);
}

/// Log a set with given weight and reps.
///
/// Requires being on the workout screen with the exercise accordion visible
/// and expanded to show the target set row.
Future<void> logSet(
  WidgetTester tester, {
  required int setNumber,
  required String weight,
  required String reps,
}) async {
  await tester.enterText(
      find.byKey(Key('set-$setNumber-weight-input')), weight);
  await tester.enterText(find.byKey(Key('set-$setNumber-reps-input')), reps);
  await tester.tap(find.byKey(Key('set-$setNumber-log-button')));
  await tester.pumpAndSettle();
}

/// Dismiss rest timer sheet if visible (tap skip button).
Future<void> dismissRestTimer(WidgetTester tester) async {
  final skipButton = find.byKey(const Key('rest-timer-skip-button'));
  if (skipButton.evaluate().isNotEmpty) {
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }
}
