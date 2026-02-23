import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '123',
        'name': 'Test User',
        'experienceLevelRaw': 'advanced',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'male',
        'createdAt': '2023-01-01T00:00:00.000',
        'appleUserId': 'apple123',
        'weightUnitRaw': 'kg',
        'roundingValue': 5.0,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'Test User');
      expect(user.experienceLevel, ExperienceLevel.advanced);
      expect(user.primaryGoal, PrimaryGoal.strength);
      expect(user.gender, Gender.male);
      expect(user.createdAt, DateTime(2023, 1, 1));
      expect(user.appleUserId, 'apple123');
      expect(user.weightUnit, WeightUnit.kg);
      expect(user.roundingValue, 5.0);
    });

    test('toJson serializes correctly', () {
      final user = UserModel(
        id: '123',
        name: 'Test User',
        experienceLevel: ExperienceLevel.advanced,
        primaryGoal: PrimaryGoal.strength,
        gender: Gender.male,
        createdAt: DateTime(2023, 1, 1),
        appleUserId: 'apple123',
        weightUnit: WeightUnit.kg,
        roundingValue: 5.0,
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'Test User');
      expect(json['experienceLevelRaw'], 'advanced');
      expect(json['primaryGoalRaw'], 'strength');
      expect(json['genderRaw'], 'male');
      expect(json['createdAt'], '2023-01-01T00:00:00.000');
      expect(json['appleUserID'], 'apple123');
      expect(json['weightUnitRaw'], 'kg');
      expect(json['roundingValue'], 5.0);
    });

    test('copyWith updates fields correctly', () {
      final user = UserModel(
        id: '123',
        name: 'Test User',
        experienceLevel: ExperienceLevel.advanced,
        primaryGoal: PrimaryGoal.strength,
        gender: Gender.male,
        createdAt: DateTime(2023, 1, 1),
        appleUserId: 'apple123',
        weightUnit: WeightUnit.kg,
        roundingValue: 5.0,
      );

      final updated = user.copyWith(
        name: 'New Name',
        weightUnit: WeightUnit.lbs,
      );

      expect(updated.name, 'New Name');
      expect(updated.weightUnit, WeightUnit.lbs);
      expect(updated.id, '123'); // Unchanged
    });
  });
}
