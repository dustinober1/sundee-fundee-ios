import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_calculations.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';

void main() {
  CycleSettingsModel makeSettings({
    int cycleLength = 28,
    int periodLength = 5,
    int lutealLength = 14,
  }) {
    return CycleSettingsModel(
      id: 'settings-1',
      userId: 'test-user',
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      lutealPhaseLength: lutealLength,
      enabledSymptomIds: const <String>[],
      notificationsEnabled: false,
    );
  }

  group('CycleCalculations', () {
    test('getPhaseBoundaries returns contiguous defaults', () {
      final Map<CyclePhase, PhaseBoundary> boundaries =
          CycleCalculations.getPhaseBoundaries(settings: makeSettings());

      expect(boundaries[CyclePhase.menstrual]?.start, 1);
      expect(boundaries[CyclePhase.menstrual]?.end, 5);
      expect(boundaries[CyclePhase.luteal]?.end, 28);

      final List<CyclePhase> phases = <CyclePhase>[
        CyclePhase.menstrual,
        CyclePhase.follicular,
        CyclePhase.ovulation,
        CyclePhase.luteal,
      ];

      for (int i = 0; i < phases.length - 1; i++) {
        final PhaseBoundary current = boundaries[phases[i]]!;
        final PhaseBoundary next = boundaries[phases[i + 1]]!;
        expect(current.end + 1, next.start);
      }
    });

    test('getPhaseRecommendation returns expected intensity', () {
      expect(
        CycleCalculations.getPhaseRecommendation(
          phase: CyclePhase.menstrual,
        ).intensityRecommendation,
        'low',
      );
      expect(
        CycleCalculations.getPhaseRecommendation(
          phase: CyclePhase.ovulation,
        ).intensityRecommendation,
        'peak',
      );
      expect(
        CycleCalculations.getPhaseRecommendation(
          phase: CyclePhase.follicular,
        ).intensityRecommendation,
        'moderate',
      );
      expect(
        CycleCalculations.getPhaseRecommendation(
          phase: CyclePhase.luteal,
        ).intensityRecommendation,
        'moderate',
      );
    });

    test('calculateCycleStatus returns null for empty logs', () {
      final CycleStatusResult? result = CycleCalculations.calculateCycleStatus(
        periodLogs: const <PeriodLogModel>[],
        settings: makeSettings(),
      );
      expect(result, isNull);
    });

    test('calculateCycleStatus detects menstrual phase during period', () {
      final DateTime today = DateTime.now();
      final DateTime periodStart = today.subtract(const Duration(days: 2));
      final PeriodLogModel log = PeriodLogModel(
        id: 'period-1',
        userId: 'test-user',
        startDate: periodStart,
        endDate: null,
        flowLevel: FlowLevel.medium,
        notes: null,
      );

      final CycleStatusResult? result = CycleCalculations.calculateCycleStatus(
        periodLogs: <PeriodLogModel>[log],
        settings: makeSettings(),
        referenceDate: today,
      );

      expect(result, isNotNull);
      expect(result?.currentPhase, CyclePhase.menstrual);
      expect(result?.cycleDay, 3);
    });

    test('all phases have complete recommendations', () {
      for (final CyclePhase phase in CyclePhase.values) {
        final PhaseRecommendation rec =
            CycleCalculations.getPhaseRecommendation(phase: phase);
        expect(rec.title, isNotEmpty);
        expect(rec.description, isNotEmpty);
        expect(rec.trainingFocus, isNotEmpty);
      }
    });
  });
}
