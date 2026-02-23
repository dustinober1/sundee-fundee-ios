import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';

import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/domain/data/predefined_programs.dart';

void main() {
  testWidgets('ProgramsScreen renders list of programs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider.overrideWith((ref) async => [PredefinedPrograms.baseline12Week]),
          activeEnrollmentProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    // Wait for FutureProvider to resolve
    await tester.pumpAndSettle();

    // Verify list is shown
    expect(find.text('Squat 1 Cycle'), findsOneWidget);
    expect(find.text('The complete 12-week baseline program designed for maximum squat strength.'), findsOneWidget);

    // We don't need to test actual enrollment in this simple widget test because userId is null in unit tests lacking auth seeding,
    // so we just verify the button exists.
    expect(find.text('Enroll in Program'), findsOneWidget);
  });
}
