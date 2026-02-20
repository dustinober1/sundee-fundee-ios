import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Onboarding (QUAL-01)', () {
    testWidgets(
      'completes full onboarding flow: name → experience → goal → dashboard',
      (tester) async {
        await pumpApp(tester);
        // Step 1: Name input
        expect(find.text('Enter your name'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('onboarding-name-input')),
          'Parity Test User',
        );
        await tester.tap(find.byKey(const Key('onboarding-next-button')));
        await tester.pumpAndSettle();
        // Step 2: Experience selection
        expect(find.text('Select experience level'), findsOneWidget);
        await tester.tap(find.byKey(const Key('experience-beginner')));
        await tester.tap(find.byKey(const Key('onboarding-next-button')));
        await tester.pumpAndSettle();
        // Step 3: Goal + start
        expect(find.text('Select your goal'), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding-start-button')));
        await tester.pumpAndSettle();
        // Verify arrival at dashboard
        expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
        expect(find.text('Welcome to Sundee Fundee'), findsOneWidget);
      },
    );

    testWidgets('back button returns to previous step', (tester) async {
      await pumpApp(tester);
      // Go to step 2
      await tester.enterText(
        find.byKey(const Key('onboarding-name-input')),
        'Back Test',
      );
      await tester.tap(find.byKey(const Key('onboarding-next-button')));
      await tester.pumpAndSettle();
      // Go back
      await tester.tap(find.byKey(const Key('onboarding-back-button')));
      await tester.pumpAndSettle();
      // Should be on step 1 again
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets(
      'name field is required (Next disabled when empty)',
      (tester) async {
        await pumpApp(tester);
        // Next button should be disabled without name entered
        final nextButton = find.byKey(const Key('onboarding-next-button'));
        expect(nextButton, findsOneWidget);
        // Attempt tap — should NOT advance (stay on step 0, button is null onPressed)
        await tester.tap(nextButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Enter your name'), findsOneWidget);
      },
    );
  });
}
