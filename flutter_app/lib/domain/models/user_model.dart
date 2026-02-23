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
    required this.weightUnit,
    required this.roundingValue,
  });

  final String id;
  final String name;
  final ExperienceLevel experienceLevel;
  final PrimaryGoal primaryGoal;
  final Gender gender;
  final DateTime createdAt;
  final String appleUserId;
  final WeightUnit weightUnit;
  final double roundingValue;

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
      appleUserId:
          json['appleUserID'] as String? ??
          json['appleUserId'] as String? ??
          '',
      weightUnit: enumFromString<WeightUnit>(
        WeightUnit.values,
        json['weightUnitRaw'] as String?,
        WeightUnit.lbs,
      ),
      roundingValue: parseDouble(json['roundingValue'], fallback: 2.5),
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
      'weightUnitRaw': weightUnit.name,
      'roundingValue': roundingValue,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    ExperienceLevel? experienceLevel,
    PrimaryGoal? primaryGoal,
    Gender? gender,
    DateTime? createdAt,
    String? appleUserId,
    WeightUnit? weightUnit,
    double? roundingValue,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      appleUserId: appleUserId ?? this.appleUserId,
      weightUnit: weightUnit ?? this.weightUnit,
      roundingValue: roundingValue ?? this.roundingValue,
    );
  }
}
