import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/presentation/programs_screen.dart';

import 'package:sundee_fundee_flutter/features/programs/data/squad_squat_program.dart';
import 'package:sundee_fundee_flutter/features/programs/data/program_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';

void main() {
  testWidgets('ProgramsScreen renders list of programs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider.overrideWith((ref) async => [squadSquatProgram]),
          activeEnrollmentProvider.overrideWith((ref) => Stream.value(null)),
          authSessionStreamProvider.overrideWith((ref) => Stream.value(
                const AuthSession(status: AuthStatus.unauthenticated),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgramsScreen()),
        ),
      ),
    );

    // Wait for FutureProvider to resolve
    await tester.pumpAndSettle();

    // Verify list is shown
    expect(find.text('12-Week Squad Squat Peak'), findsOneWidget);
    expect(find.text('A 12-week three-phase squat program focused on building a volume foundation, transitioning to heavy triples, and peaking for a true 1RM.'), findsOneWidget);

    // Button should be disabled since userId is null
    final enrollButton = find.text('Enroll in Program');
    expect(enrollButton, findsOneWidget);
  });
}
