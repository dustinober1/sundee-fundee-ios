import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';

void main() {
  group('CycleSettingsModel', () {
    test('copyWith updates fields correctly', () {
      final settings = CycleSettingsModel(
        id: '123',
        userId: 'user1',
        averageCycleLength: 28,
        averagePeriodLength: 5,
        lutealPhaseLength: 14,
        enabledSymptomIds: ['sym1'],
        notificationsEnabled: true,
      );

      final updated = settings.copyWith(
        averageCycleLength: 30,
        notificationsEnabled: false,
      );

      expect(updated.averageCycleLength, 30);
      expect(updated.notificationsEnabled, false);
      expect(updated.averagePeriodLength, 5); // Unchanged
    });
  });
}
