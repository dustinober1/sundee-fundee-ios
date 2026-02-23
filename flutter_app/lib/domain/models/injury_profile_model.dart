import 'json_utils.dart';

enum InjuryStatus { active, resolved }

class InjuryProfileModel {
  InjuryProfileModel({
    required this.id,
    required this.location,
    required this.movementLimitations,
    required this.recoveryGoal,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  final String id;
  final String location;
  final String movementLimitations;
  final String recoveryGoal;
  final InjuryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  bool get isActive => status == InjuryStatus.active;

  bool get isComplete =>
      location.trim().isNotEmpty &&
      movementLimitations.trim().isNotEmpty &&
      recoveryGoal.trim().isNotEmpty;

  factory InjuryProfileModel.fromJson(Map<String, dynamic> json) {
    return InjuryProfileModel(
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      movementLimitations: json['movementLimitations'] as String? ?? '',
      recoveryGoal: json['recoveryGoal'] as String? ?? '',
      status: _statusFromRaw(json['status'] as String?),
      createdAt: parseDateTime(
        json['createdAt'],
        fieldName: 'injuryProfile.createdAt',
      ),
      updatedAt: parseDateTime(
        json['updatedAt'],
        fieldName: 'injuryProfile.updatedAt',
      ),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : parseDateTime(
              json['resolvedAt'],
              fieldName: 'injuryProfile.resolvedAt',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'location': location,
      'movementLimitations': movementLimitations,
      'recoveryGoal': recoveryGoal,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  InjuryProfileModel copyWith({
    String? id,
    String? location,
    String? movementLimitations,
    String? recoveryGoal,
    InjuryStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
  }) {
    return InjuryProfileModel(
      id: id ?? this.id,
      location: location ?? this.location,
      movementLimitations: movementLimitations ?? this.movementLimitations,
      recoveryGoal: recoveryGoal ?? this.recoveryGoal,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: clearResolvedAt ? null : resolvedAt ?? this.resolvedAt,
    );
  }

  static InjuryStatus _statusFromRaw(String? raw) {
    switch (raw) {
      case 'resolved':
        return InjuryStatus.resolved;
      case 'active':
      default:
        return InjuryStatus.active;
    }
  }
}
