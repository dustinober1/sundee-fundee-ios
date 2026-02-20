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
