import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/sign_in_screen.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('shows onboarding and injury profile entry points', (
    WidgetTester tester,
  ) async {
    final UserModel profile = UserModel(
      id: 'u1',
      name: 'Dustin',
      experienceLevel: ExperienceLevel.beginner,
      primaryGoal: PrimaryGoal.strength,
      gender: Gender.female,
      createdAt: DateTime.utc(2026, 1, 1),
      appleUserId: 'apple',
      cycleTrackingEnabled: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.authenticated),
            ),
          ),
          userProfileStreamProvider.overrideWith(
            (Ref ref) => Stream<UserModel?>.value(profile),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Onboarding Answers'), findsOneWidget);
    expect(find.text('Injury Profile'), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });
}
