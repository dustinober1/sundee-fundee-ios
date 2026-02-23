import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/weight_calculations.dart';

void main() {
  group('WeightCalculations', () {
    test('roundToNearestFive rounds to expected values', () {
      expect(WeightCalculations.roundToNearestFive(132), 130);
      expect(WeightCalculations.roundToNearestFive(133), 135);
      expect(WeightCalculations.roundToNearestFive(135), 135);
    });

    test('calculateTargetWeight uses percentage and rounding', () {
      final double result = WeightCalculations.calculateTargetWeight(
        oneRepMax: 200,
        percentage: 0.65,
      );
      expect(result, 130);
    });

    test('getNextRecommendedWeight for first/success/failure', () {
      expect(
        WeightCalculations.getNextRecommendedWeight(
          currentWeight: 0,
          result: SessionResult.first,
          oneRepMax: 200,
        ),
        140,
      );
      expect(
        WeightCalculations.getNextRecommendedWeight(
          currentWeight: 130,
          result: SessionResult.success,
          oneRepMax: 200,
        ),
        135,
      );
      expect(
        WeightCalculations.getNextRecommendedWeight(
          currentWeight: 130,
          result: SessionResult.failure,
          oneRepMax: 200,
        ),
        125,
      );
      expect(
        WeightCalculations.getNextRecommendedWeight(
          currentWeight: 100,
          result: SessionResult.failure,
          oneRepMax: 200,
        ),
        100,
      );
    });

    test('wasSetSuccessful applies reps and weight checks', () {
      expect(
        WeightCalculations.wasSetSuccessful(
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
        isTrue,
      );
      expect(
        WeightCalculations.wasSetSuccessful(
          actualReps: 3,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
        isFalse,
      );
      expect(
        WeightCalculations.wasSetSuccessful(
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 100,
          prescribedWeight: null,
        ),
        isTrue,
      );
    });

    test('wasSessionSuccessful checks all sets', () {
      final List<
          ({
            int actualReps,
            int prescribedReps,
            double actualWeight,
            double? prescribedWeight,
          })> passingSets = <({
        int actualReps,
        int prescribedReps,
        double actualWeight,
        double? prescribedWeight,
      })>[
        (
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
        (
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
      ];

      final List<
          ({
            int actualReps,
            int prescribedReps,
            double actualWeight,
            double? prescribedWeight,
          })> failingSets = <({
        int actualReps,
        int prescribedReps,
        double actualWeight,
        double? prescribedWeight,
      })>[
        (
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
        (
          actualReps: 3,
          prescribedReps: 5,
          actualWeight: 135,
          prescribedWeight: 135,
        ),
      ];

      expect(
        WeightCalculations.wasSessionSuccessful(sets: passingSets),
        isTrue,
      );
      expect(
        WeightCalculations.wasSessionSuccessful(sets: failingSets),
        isFalse,
      );
      expect(
        WeightCalculations.wasSessionSuccessful(
          sets: <({
            int actualReps,
            int prescribedReps,
            double actualWeight,
            double? prescribedWeight,
          })>[],
        ),
        isTrue,
      );
    });

    test('PR, volume, and plateau helpers match behavior', () {
      expect(
        WeightCalculations.isPersonalRecord(weight: 140, previousMax: 135),
        isTrue,
      );
      expect(
        WeightCalculations.calculateVolumeLoad(weight: 135, reps: 5, sets: 3),
        2025,
      );
      expect(
        WeightCalculations.detectPlateau(weights: <double>[135, 135, 135]),
        isTrue,
      );
      expect(
        WeightCalculations.detectPlateau(weights: <double>[130, 135, 140]),
        isFalse,
      );
    });
  });
}
