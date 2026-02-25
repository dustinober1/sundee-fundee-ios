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

UserModel _profile() {
  return UserModel(
    id: 'u1',
    name: 'Dustin',
    experienceLevel: ExperienceLevel.beginner,
    primaryGoal: PrimaryGoal.strength,
    gender: Gender.male,
    createdAt: DateTime.utc(2026, 1, 1),
    appleUserId: 'apple',
  );
}

Future<void> _pumpOnboardingScreen(
  WidgetTester tester, {
  required _FakeAuthRepository repository,
  required AuthStatus status,
  UserModel? profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionStreamProvider.overrideWith(
          (Ref ref) => Stream<AuthSession>.value(AuthSession(status: status)),
        ),
        userProfileStreamProvider.overrideWith(
          (Ref ref) => Stream<UserModel?>.value(profile),
        ),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'shows resume/restart decision when auth status is resumeOnboarding', (
    WidgetTester tester,
  ) async {
    final _FakeAuthRepository fakeRepository = _FakeAuthRepository();

    await _pumpOnboardingScreen(
      tester,
      repository: fakeRepository,
      status: AuthStatus.resumeOnboarding,
      profile: _profile(),
    );

    expect(find.text('Resume onboarding'), findsOneWidget);
    expect(find.text('Restart onboarding'), findsOneWidget);
  });

  testWidgets(
      'restart onboarding action calls repository and exits decision gate',
      (WidgetTester tester) async {
    final _FakeAuthRepository fakeRepository = _FakeAuthRepository();

    await _pumpOnboardingScreen(
      tester,
      repository: fakeRepository,
      status: AuthStatus.resumeOnboarding,
      profile: _profile(),
    );

    await tester.tap(find.text('Restart onboarding'));
    await tester.pumpAndSettle();

    expect(fakeRepository.restartCalls, 1);
    expect(find.text('Resume onboarding'), findsNothing);
    expect(find.text('Complete Onboarding'), findsOneWidget);
  });

  testWidgets(
      'needsInjuryProfile shows injury guidance and does not show resume decision',
      (WidgetTester tester) async {
    final _FakeAuthRepository fakeRepository = _FakeAuthRepository();

    await _pumpOnboardingScreen(
      tester,
      repository: fakeRepository,
      status: AuthStatus.needsInjuryProfile,
      profile: _profile(),
    );

    expect(
      find.textContaining('injury profile needs a few more details'),
      findsOneWidget,
    );
    expect(find.text('Resume onboarding'), findsNothing);
    expect(find.text('Restart onboarding'), findsNothing);
  });
}
