import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';

void main() {
  testWidgets('ProgramsScreen renders list of programs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    // Wait for FutureProvider to resolve
    await tester.pumpAndSettle();

    // Verify list is shown
    expect(find.text('Squat 1 Cycle'), findsOneWidget);
    expect(
      find.text(
        'The complete 12-week baseline program designed for maximum squat strength.',
      ),
      findsOneWidget,
    );

    // Tap on enrollment button
    await tester.tap(find.text('Enroll in Program').first);
    await tester.pumpAndSettle();

    // Verify snackbar appears (current implementation)
    expect(find.text('Enrollment coming soon!'), findsOneWidget);
  });
}
