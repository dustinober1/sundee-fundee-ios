import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';

void main() {
  testWidgets('ProgramsScreen renders list of programs including Deadlift Cycle 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    // Wait for FutureProvider to resolve
    await tester.pumpAndSettle();

    // Scroll to find the program if it's off-screen
    final Finder programFinder = find.text('Deadlift Cycle 2 (Overload & Tension)');
    await tester.scrollUntilVisible(
      programFinder,
      500.0,
      scrollable: find.byType(Scrollable).first,
    );

    // Verify Deadlift Cycle 2 is shown
    expect(programFinder, findsOneWidget);
    expect(find.text('A 12-week deadlift program focusing on upper back overload, time under tension with clusters, and speed work.'), findsOneWidget);

    // Verify Enroll button exists (at least one)
    expect(find.text('Enroll in Program'), findsWidgets);

    // Tap the first enroll button
    await tester.tap(find.text('Enroll in Program').first);
    await tester.pump(); // Pump for SnackBar animation

    // Verify SnackBar appears
    expect(find.text('Enrollment coming soon!'), findsOneWidget);
  });
}
