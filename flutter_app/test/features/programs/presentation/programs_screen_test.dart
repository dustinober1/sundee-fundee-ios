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
    expect(find.text('Deadlift 1 Cycle'), findsOneWidget);
    expect(find.text('The complete 12-week baseline program designed for maximum deadlift strength.'), findsOneWidget);

    // Verify interaction (shows SnackBar)
    await tester.tap(find.text('Enroll in Program').first);
    await tester.pump();
    expect(find.text('Enrollment coming soon!'), findsOneWidget);
  });
}
