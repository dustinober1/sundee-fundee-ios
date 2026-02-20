import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Workout Flow (QUAL-01)', () {
    testWidgets('navigates to workout screen via programs', (tester) async {
      await pumpApp(tester);
      // Complete onboarding to reach dashboard
      await completeOnboarding(tester);
      // Navigate to programs
      await tester.tap(find.byKey(const Key('nav-programs')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('programs-screen')), findsOneWidget);
      // Tap a program to enter workout
      await tester.tap(
        find.byKey(const Key('program-back-squat-complete-cycle')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workout-screen')), findsOneWidget);
    });

    testWidgets('completes workout and returns to dashboard', (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      // Navigate to workout
      await tester.tap(find.byKey(const Key('nav-programs')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('program-back-squat-complete-cycle')),
      );
      await tester.pumpAndSettle();
      // Complete workout
      await tester.tap(find.byKey(const Key('complete-workout-button')));
      await tester.pumpAndSettle();
      // Should return to dashboard
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    });
  });
}
