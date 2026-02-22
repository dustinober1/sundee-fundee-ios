import 'json_utils.dart';

class OneRepMaxModel {
  OneRepMaxModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.weight,
    required this.date,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final double weight;
  final DateTime date;

  factory OneRepMaxModel.fromJson(Map<String, dynamic> json) {
    return OneRepMaxModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      weight: parseDouble(json['weight'], fallback: 0),
      date: parseDateTime(json['date'], fieldName: 'date'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}
