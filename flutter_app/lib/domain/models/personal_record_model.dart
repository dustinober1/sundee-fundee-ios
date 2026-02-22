import '../enums.dart';
import 'json_utils.dart';

class PersonalRecordModel {
  PersonalRecordModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.recordType,
    required this.value,
    required this.workoutId,
    required this.date,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final RecordType recordType;
  final double value;
  final String? workoutId;
  final DateTime date;

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      recordType: enumFromString<RecordType>(
        RecordType.values,
        json['recordTypeRaw'] as String? ?? json['recordType'] as String?,
        RecordType.weight,
      ),
      value: parseDouble(json['value'], fallback: 0),
      workoutId: json['workoutId'] as String?,
      date: parseDateTime(json['date'], fieldName: 'date'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'recordTypeRaw': recordType.name,
      'value': value,
      'workoutId': workoutId,
      'date': date.toIso8601String(),
    };
  }
}
