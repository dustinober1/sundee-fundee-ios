enum ExperienceLevel { beginner, intermediate, advanced }

enum PrimaryGoal { strength, hypertrophy, explosiveness }

enum CycleStatus { active, completed, paused }

enum RecordType { weight, volume }

enum FlowLevel { light, medium, heavy }

enum SymptomCategory { physical, emotional, energy }

enum CyclePhase { menstrual, follicular, ovulation, luteal }

enum TimerStatus { idle, running, paused, complete }

enum NotificationType { sound, vibrate, both, none }

enum Gender { male, female, preferNotToSay }

extension GenderDisplayName on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

enum WeightUnit { lbs, kg }

T enumFromString<T extends Enum>(List<T> values, String? rawValue, T fallback) {
  if (rawValue == null) {
    return fallback;
  }

  for (final value in values) {
    if (value.name == rawValue) {
      return value;
    }
  }

  return fallback;
}
