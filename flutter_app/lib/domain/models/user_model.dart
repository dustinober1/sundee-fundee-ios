import '../enums.dart';
import 'json_utils.dart';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.experienceLevel,
    required this.primaryGoal,
    required this.gender,
    required this.createdAt,
    required this.appleUserId,
  });

  final String id;
  final String name;
  final ExperienceLevel experienceLevel;
  final PrimaryGoal primaryGoal;
  final Gender gender;
  final DateTime createdAt;
  final String appleUserId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      experienceLevel: enumFromString<ExperienceLevel>(
        ExperienceLevel.values,
        json['experienceLevelRaw'] as String? ??
            json['experienceLevel'] as String?,
        ExperienceLevel.beginner,
      ),
      primaryGoal: enumFromString<PrimaryGoal>(
        PrimaryGoal.values,
        json['primaryGoalRaw'] as String? ?? json['primaryGoal'] as String?,
        PrimaryGoal.strength,
      ),
      gender: enumFromString<Gender>(
        Gender.values,
        json['genderRaw'] as String? ?? json['gender'] as String?,
        Gender.preferNotToSay,
      ),
      createdAt: parseDateTime(json['createdAt'], fieldName: 'createdAt'),
      appleUserId: json['appleUserID'] as String? ??
          json['appleUserId'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'experienceLevelRaw': experienceLevel.name,
      'primaryGoalRaw': primaryGoal.name,
      'genderRaw': gender.name,
      'createdAt': createdAt.toIso8601String(),
      'appleUserID': appleUserId,
    };
  }
}
