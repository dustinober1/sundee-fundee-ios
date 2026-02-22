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
    expect(find.text('12-Week Deadlift Program (Cycle Syncing)'), findsOneWidget);
    expect(find.text('A 12-week deadlift program designed to align max attempts with ovulation phases for female athletes. Includes speed pulls, heavy rows, and squat variations.'), findsOneWidget);

    // Tap on it
    await tester.tap(find.text('12-Week Deadlift Program (Cycle Syncing)'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Would you like to start this 12-week program?'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
