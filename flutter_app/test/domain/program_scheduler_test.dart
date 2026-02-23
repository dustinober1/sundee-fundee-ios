import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/domain/programs/program_scheduler.dart';
import 'package:sundee_fundee_flutter/features/programs/data/deadlift_program.dart';

void main() {
  group('ProgramScheduler', () {
    test(
        'getRecommendedStartDate suggests current cycle ovulation if in future',
        () {
      final CycleSettingsModel settings = CycleSettingsModel(
        id: 'test',
        userId: 'user',
        averageCycleLength: 28,
        averagePeriodLength: 5,
        lutealPhaseLength: 14,
        enabledSymptomIds: [],
        notificationsEnabled: false,
      );

      // Period started 5 days ago. Ovulation is day 14 (9 days from now).
      final DateTime lastPeriodDate =
          DateTime.now().subtract(const Duration(days: 5));

      final DateTime result = ProgramScheduler.getRecommendedStartDate(
        program: deadliftProgram,
        settings: settings,
        lastPeriodDate: lastPeriodDate,
      );

      // Expect day 14 of cycle.
      // Day 14 is lastPeriodDate + 13 days.
      // Boundaries: Ovulation start is periodLength + 2 or OvulationDay - 2.
      // OvulationDay = 28 - 14 = 14.
      // OvulationStart = max(5+2, 14-2) = 12.
      // So Ovulation starts on Day 12.
      // Ovulation Date = lastPeriodDate + 11 days.

      final int expectedStartDay = 12; // CycleCalculations logic
      final DateTime expectedDate = DateTime(
        lastPeriodDate.year,
        lastPeriodDate.month,
        lastPeriodDate.day,
      ).add(Duration(days: expectedStartDay - 1));

      expect(result.year, expectedDate.year);
      expect(result.month, expectedDate.month);
      expect(result.day, expectedDate.day);
    });

    test(
        'getRecommendedStartDate suggests next cycle ovulation if current is past',
        () {
      final CycleSettingsModel settings = CycleSettingsModel(
        id: 'test',
        userId: 'user',
        averageCycleLength: 28,
        averagePeriodLength: 5,
        lutealPhaseLength: 14,
        enabledSymptomIds: [],
        notificationsEnabled: false,
      );

      // Period started 20 days ago. Ovulation (Day 12-16) is past.
      final DateTime lastPeriodDate =
          DateTime.now().subtract(const Duration(days: 20));

      final DateTime result = ProgramScheduler.getRecommendedStartDate(
        program: deadliftProgram,
        settings: settings,
        lastPeriodDate: lastPeriodDate,
      );

      // Expect next cycle ovulation.
      // Current cycle ovulation was at ~Day 12.
      // Next cycle ovulation is current + 28 days.

      final int expectedStartDay = 12;
      final DateTime expectedDate = DateTime(
        lastPeriodDate.year,
        lastPeriodDate.month,
        lastPeriodDate.day,
      ).add(Duration(days: expectedStartDay - 1 + 28));

      expect(result.year, expectedDate.year);
      expect(result.month, expectedDate.month);
      expect(result.day, expectedDate.day);
    });
  });
}
