import 'json_utils.dart';

class LiftMaxModel {
  LiftMaxModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.repCount,
    required this.weight,
    required this.withStraps,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final int repCount;
  final double weight;
  final bool withStraps;
  final DateTime updatedAt;

  factory LiftMaxModel.fromJson(Map<String, dynamic> json) {
    return LiftMaxModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      repCount: parseInt(json['repCount'], fallback: 1),
      weight: parseDouble(json['weight'], fallback: 0),
      withStraps: json['withStraps'] as bool? ?? false,
      updatedAt: parseDateTime(json['updatedAt'], fieldName: 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'repCount': repCount,
      'weight': weight,
      'withStraps': withStraps,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
