import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('normalizes legacy injuryProfile object into injuryProfiles list', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'displayName': 'Dustin',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'male',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
        'injuryProfile': <String, dynamic>{
          'id': 'legacy-1',
          'location': 'Knee',
          'movementLimitations': 'No jumping',
          'recoveryGoal': 'Pain free squat',
          'status': 'active',
        },
      });

      expect(user.injuryProfiles, hasLength(1));
      expect(user.injuryProfiles.first.id, 'legacy-1');
      expect(user.injuryProfiles.first.status, InjuryStatus.active);
    });

    test('uses computed onboarding completeness when flag is false', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'name': 'Dustin',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'female',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
        'onboardingComplete': false,
      });

      expect(user.onboardingComplete, isFalse);
      expect(user.hasRequiredOnboardingAnswers, isTrue);
      expect(user.onboardingCompleteComputed, isTrue);
    });

    test('requires injury completion when active injury is incomplete', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'name': 'Dustin',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'female',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
        'injuryProfiles': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'inj-1',
            'location': 'Shoulder',
            'movementLimitations': '',
            'recoveryGoal': 'Regain overhead strength',
            'status': 'active',
            'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
            'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          },
        ],
      });

      expect(user.activeInjuries, hasLength(1));
      expect(user.requiresInjuryProfileCompletion, isTrue);
    });

    test('treats only male and female as explicit onboarding gender answers',
        () {
      final UserModel female = UserModel.fromJson(<String, dynamic>{
        'id': 'female',
        'name': 'Ada',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'female',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
      });
      final UserModel male = UserModel.fromJson(<String, dynamic>{
        'id': 'male',
        'name': 'Ben',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'male',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
      });
      final UserModel preferNotToSay = UserModel.fromJson(<String, dynamic>{
        'id': 'pnts',
        'name': 'Casey',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'preferNotToSay',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'appleUserID': 'apple',
      });

      expect(female.hasExplicitOnboardingGenderAnswer, isTrue);
      expect(male.hasExplicitOnboardingGenderAnswer, isTrue);
      expect(preferNotToSay.hasExplicitOnboardingGenderAnswer, isFalse);
    });
  });
}
