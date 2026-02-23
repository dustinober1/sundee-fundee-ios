import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';
import 'package:sundee_fundee_flutter/features/settings/presentation/injury_profile_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(guestModeStore: GuestModeStore(), firebaseEnabled: false);

  int saveCalls = 0;

  @override
  Future<void> saveInjuryProfile({
    required String id,
    required String location,
    required String movementLimitations,
    required String recoveryGoal,
    InjuryStatus status = InjuryStatus.active,
  }) async {
    saveCalls++;
  }

  @override
  int get pendingProfileWriteCount => 1;
}

void main() {
  testWidgets('renders pending retry messaging and allows save action', (
    WidgetTester tester,
  ) async {
    final _FakeAuthRepository fakeRepository = _FakeAuthRepository();
    final UserModel profile = UserModel(
      id: 'u1',
      name: 'Dustin',
      experienceLevel: ExperienceLevel.beginner,
      primaryGoal: PrimaryGoal.strength,
      gender: Gender.female,
      createdAt: DateTime.utc(2026, 1, 1),
      appleUserId: 'apple',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          userProfileStreamProvider.overrideWith(
            (Ref ref) => Stream<UserModel?>.value(profile),
          ),
        ],
        child: const MaterialApp(home: InjuryProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('pending profile save'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Knee');
    await tester.enterText(find.byType(TextField).at(1), 'No jumping');
    await tester.enterText(find.byType(TextField).at(2), 'Pain free squat');
    await tester
        .tap(find.widgetWithText(ElevatedButton, 'Save injury profile'));
    await tester.pumpAndSettle();
    expect(fakeRepository.saveCalls, 1);
  });
}
