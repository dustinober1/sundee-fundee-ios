import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/onboarding_screen.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(guestModeStore: GuestModeStore(), firebaseEnabled: false);

  int restartCalls = 0;

  @override
  Future<void> restartOnboarding() async {
    restartCalls++;
  }
}

void main() {
  testWidgets(
      'shows resume/restart decision when auth status is resumeOnboarding', (
    WidgetTester tester,
  ) async {
    final _FakeAuthRepository fakeRepository = _FakeAuthRepository();
    final UserModel profile = UserModel(
      id: 'u1',
      name: 'Dustin',
      experienceLevel: ExperienceLevel.beginner,
      primaryGoal: PrimaryGoal.strength,
      gender: Gender.male,
      createdAt: DateTime.utc(2026, 1, 1),
      appleUserId: 'apple',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.resumeOnboarding),
            ),
          ),
          userProfileStreamProvider.overrideWith(
            (Ref ref) => Stream<UserModel?>.value(profile),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume onboarding'), findsOneWidget);
    expect(find.text('Restart onboarding'), findsOneWidget);
  });
}
