import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Navigation (PLAT-01)', () {
    testWidgets('app launches and shows onboarding screen', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);
    });

    testWidgets('can navigate from onboarding to dashboard', (tester) async {
      await pumpApp(tester);
      // Step 1: Enter name
      await tester.enterText(
        find.byKey(const Key('onboarding-name-input')),
        'Test User',
      );
      await tester.tap(find.byKey(const Key('onboarding-next-button')));
      await tester.pumpAndSettle();
      // Step 2: Select experience
      await tester.tap(find.byKey(const Key('experience-beginner')));
      await tester.tap(find.byKey(const Key('onboarding-next-button')));
      await tester.pumpAndSettle();
      // Step 3: Start training
      await tester.tap(find.byKey(const Key('onboarding-start-button')));
      await tester.pumpAndSettle();
      // Verify dashboard
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    });

    testWidgets('can navigate to programs from dashboard', (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      // Now on dashboard — navigate to programs
      await tester.tap(find.byKey(const Key('nav-programs')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('programs-screen')), findsOneWidget);
    });
  });
}
