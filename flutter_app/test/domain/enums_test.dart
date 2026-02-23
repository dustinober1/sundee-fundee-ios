import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';

void main() {
  group('enumFromString', () {
    test('returns correct ExperienceLevel for valid strings', () {
      expect(
        enumFromString(
            ExperienceLevel.values, 'beginner', ExperienceLevel.advanced),
        ExperienceLevel.beginner,
      );
      expect(
        enumFromString(
            ExperienceLevel.values, 'intermediate', ExperienceLevel.advanced),
        ExperienceLevel.intermediate,
      );
      expect(
        enumFromString(
            ExperienceLevel.values, 'advanced', ExperienceLevel.beginner),
        ExperienceLevel.advanced,
      );
    });

    test('returns correct Gender for valid strings', () {
      expect(
        enumFromString(Gender.values, 'male', Gender.preferNotToSay),
        Gender.male,
      );
      expect(
        enumFromString(Gender.values, 'female', Gender.preferNotToSay),
        Gender.female,
      );
      expect(
        enumFromString(Gender.values, 'preferNotToSay', Gender.male),
        Gender.preferNotToSay,
      );
    });

    test('returns fallback for invalid strings', () {
      expect(
        enumFromString(
            ExperienceLevel.values, 'invalid', ExperienceLevel.beginner),
        ExperienceLevel.beginner,
      );
      expect(
        enumFromString(Gender.values, 'unknown', Gender.female),
        Gender.female,
      );
    });

    test('returns fallback for null string', () {
      expect(
        enumFromString(
            ExperienceLevel.values, null, ExperienceLevel.intermediate),
        ExperienceLevel.intermediate,
      );
    });

    test('is case sensitive', () {
      // enum names in Dart are typically camelCase, and value.name returns the name as is.
      // enumFromString compares value.name == rawValue.
      expect(
        enumFromString(
            ExperienceLevel.values, 'Beginner', ExperienceLevel.advanced),
        ExperienceLevel.advanced,
      );
    });
  });
}
