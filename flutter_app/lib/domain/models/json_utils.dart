import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseDateTime(dynamic value, {required String fieldName}) {
  if (value is DateTime) {
    return value;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    return DateTime.parse(value);
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  throw FormatException('Invalid date value for $fieldName: $value');
}

DateTime? parseNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return parseDateTime(value, fieldName: 'nullableDate');
}

int parseInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return fallback;
}

double parseDouble(dynamic value, {required double fallback}) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return fallback;
}
