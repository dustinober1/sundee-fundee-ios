import '../enums.dart';
import 'injury_profile_model.dart';
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
    this.cycleTrackingEnabled = false,
    this.onboardingComplete = false,
    this.profileUpdatedAt,
    this.injuryProfiles = const <InjuryProfileModel>[],
    this.acknowledgedInjuryDisclaimerIds = const <String, DateTime>{},
  });

  final String id;
  final String name;
  final ExperienceLevel experienceLevel;
  final PrimaryGoal primaryGoal;
  final Gender gender;
  final DateTime createdAt;
  final String appleUserId;
  final bool cycleTrackingEnabled;
  final bool onboardingComplete;
  final DateTime? profileUpdatedAt;
  final List<InjuryProfileModel> injuryProfiles;
  final Map<String, DateTime> acknowledgedInjuryDisclaimerIds;

  bool get hasRequiredOnboardingAnswers => name.trim().isNotEmpty;

  bool get onboardingCompleteComputed =>
      onboardingComplete || hasRequiredOnboardingAnswers;

  /// Returns true only if every active injury's ID exists as a key in
  /// [acknowledgedInjuryDisclaimerIds].
  bool hasAcknowledgedDisclaimerForAllActive(
    List<InjuryProfileModel> activeInjuries,
  ) {
    if (activeInjuries.isEmpty) return true;
    return activeInjuries.every(
      (InjuryProfileModel injury) =>
          acknowledgedInjuryDisclaimerIds.containsKey(injury.id),
    );
  }

  List<InjuryProfileModel> get activeInjuries => injuryProfiles
      .where((InjuryProfileModel injury) => injury.isActive)
      .toList();

  bool get hasIncompleteActiveInjuryProfiles =>
      activeInjuries.any((InjuryProfileModel injury) => !injury.isComplete);

  bool get requiresInjuryProfileCompletion =>
      activeInjuries.isNotEmpty && hasIncompleteActiveInjuryProfiles;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
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
      cycleTrackingEnabled: json['cycleTrackingEnabled'] as bool? ?? false,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      profileUpdatedAt: json['profileUpdatedAt'] == null
          ? null
          : parseDateTime(
              json['profileUpdatedAt'],
              fieldName: 'profileUpdatedAt',
            ),
      injuryProfiles: _parseInjuryProfiles(json),
      acknowledgedInjuryDisclaimerIds:
          _parseAcknowledgedInjuryDisclaimerIds(json),
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
      'cycleTrackingEnabled': cycleTrackingEnabled,
      'onboardingComplete': onboardingComplete,
      if (profileUpdatedAt != null)
        'profileUpdatedAt': profileUpdatedAt!.toIso8601String(),
      'injuryProfiles': injuryProfiles
          .map((InjuryProfileModel injury) => injury.toJson())
          .toList(),
      if (acknowledgedInjuryDisclaimerIds.isNotEmpty)
        'acknowledgedInjuryDisclaimerIds': acknowledgedInjuryDisclaimerIds.map(
          (String key, DateTime value) =>
              MapEntry<String, String>(key, value.toIso8601String()),
        ),
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
    bool? cycleTrackingEnabled,
    bool? onboardingComplete,
    DateTime? profileUpdatedAt,
    List<InjuryProfileModel>? injuryProfiles,
    Map<String, DateTime>? acknowledgedInjuryDisclaimerIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      appleUserId: appleUserId ?? this.appleUserId,
      cycleTrackingEnabled: cycleTrackingEnabled ?? this.cycleTrackingEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      profileUpdatedAt: profileUpdatedAt ?? this.profileUpdatedAt,
      injuryProfiles: injuryProfiles ?? this.injuryProfiles,
      acknowledgedInjuryDisclaimerIds:
          acknowledgedInjuryDisclaimerIds ?? this.acknowledgedInjuryDisclaimerIds,
    );
  }

  static List<InjuryProfileModel> _parseInjuryProfiles(
      Map<String, dynamic> json) {
    final dynamic rawProfiles = json['injuryProfiles'];
    if (rawProfiles is List) {
      return rawProfiles
          .whereType<Map>()
          .map(
            (Map injury) =>
                InjuryProfileModel.fromJson(Map<String, dynamic>.from(injury)),
          )
          .toList();
    }

    // Legacy schema support: single injury object.
    final dynamic legacyInjury = json['injuryProfile'];
    if (legacyInjury is Map) {
      return <InjuryProfileModel>[
        InjuryProfileModel.fromJson(
          <String, dynamic>{
            'id': legacyInjury['id'] ?? 'legacy-injury',
            'location': legacyInjury['location'] ?? '',
            'movementLimitations': legacyInjury['movementLimitations'] ?? '',
            'recoveryGoal': legacyInjury['recoveryGoal'] ?? '',
            'status': legacyInjury['status'] ?? 'active',
            'createdAt':
                legacyInjury['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt':
                legacyInjury['updatedAt'] ?? DateTime.now().toIso8601String(),
            'resolvedAt': legacyInjury['resolvedAt'],
          },
        ),
      ];
    }

    return const <InjuryProfileModel>[];
  }

  static Map<String, DateTime> _parseAcknowledgedInjuryDisclaimerIds(
      Map<String, dynamic> json) {
    final dynamic raw = json['acknowledgedInjuryDisclaimerIds'];
    if (raw is Map) {
      final Map<String, DateTime> result = <String, DateTime>{};
      for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
        final String key = entry.key as String;
        final dynamic value = entry.value;
        if (value is String) {
          try {
            result[key] = DateTime.parse(value);
          } catch (_) {
            // skip malformed timestamps
          }
        } else if (value is DateTime) {
          result[key] = value;
        }
      }
      return result;
    }
    return const <String, DateTime>{};
  }
}
