import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/json_utils.dart';

void main() {
  group('parseDateTime', () {
    test('returns same DateTime when input is DateTime', () {
      final now = DateTime.now();
      expect(parseDateTime(now, fieldName: 'test'), now);
    });

    test('returns correct DateTime when input is valid ISO-8601 string', () {
      const isoString = '2023-10-27T10:00:00.000Z';
      final expected = DateTime.parse(isoString);
      expect(parseDateTime(isoString, fieldName: 'test'), expected);
    });

    test('returns correct DateTime when input is milliseconds since epoch', () {
      final now = DateTime.now();
      final ms = now.millisecondsSinceEpoch;
      final expected = DateTime.fromMillisecondsSinceEpoch(ms);
      expect(parseDateTime(ms, fieldName: 'test'), expected);
    });

    test('throws FormatException when input is invalid string', () {
      expect(
        () => parseDateTime('invalid-date', fieldName: 'testField'),
        throwsFormatException,
      );
    });

    test('throws FormatException when input is unsupported type', () {
      expect(
        () => parseDateTime(true, fieldName: 'testField'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Invalid date value for testField: true'),
        )),
      );
    });
  });

  group('parseNullableDateTime', () {
    test('returns null when input is null', () {
      expect(parseNullableDateTime(null), isNull);
    });

    test('returns DateTime when input is valid', () {
      final now = DateTime.now();
      expect(parseNullableDateTime(now), now);
    });

    test('throws FormatException when input is invalid', () {
      expect(
        () => parseNullableDateTime('invalid'),
        throwsFormatException,
      );
    });
  });

  group('parseInt', () {
    test('returns int when input is int', () {
      expect(parseInt(42, fallback: 0), 42);
    });

    test('returns int when input is double', () {
      expect(parseInt(42.7, fallback: 0), 42);
    });

    test('returns fallback when input is null', () {
      expect(parseInt(null, fallback: 10), 10);
    });

    test('returns fallback when input is invalid type', () {
      expect(parseInt('not an int', fallback: 5), 5);
      expect(parseInt(true, fallback: 7), 7);
    });
  });

  group('parseDouble', () {
    test('returns double when input is double', () {
      expect(parseDouble(42.5, fallback: 0.0), 42.5);
    });

    test('returns double when input is int', () {
      expect(parseDouble(42, fallback: 0.0), 42.0);
    });

    test('returns fallback when input is null', () {
      expect(parseDouble(null, fallback: 10.5), 10.5);
    });

    test('returns fallback when input is invalid type', () {
      expect(parseDouble('not a double', fallback: 5.5), 5.5);
      expect(parseDouble(false, fallback: 7.5), 7.5);
    });
  });
}
