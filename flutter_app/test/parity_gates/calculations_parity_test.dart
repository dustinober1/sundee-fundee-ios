// Parity gate: calculations.dart vs v1.1 calculations.ts
//
// PLAT-02 requirement: Flutter calculations produce identical outputs to v1.1.
// All expected values are derived directly from the v1.1 TypeScript implementation.
// See: src/lib/calculations.ts (v1.1 baseline)

import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee/core/recommendations/calculations.dart';

void main() {
  group('PARITY: roundToNearestFive — matches v1.1 Math.round(value / 5) * 5', () {
    test('72.0 rounds down to 70.0', () {
      expect(roundToNearestFive(72.0), closeTo(70.0, 0.01));
    });

    test('73.0 rounds up to 75.0', () {
      expect(roundToNearestFive(73.0), closeTo(75.0, 0.01));
    });

    test('72.5 rounds up to 75.0 (half-up)', () {
      expect(roundToNearestFive(72.5), closeTo(75.0, 0.01));
    });

    test('100.0 stays 100.0 (already on boundary)', () {
      expect(roundToNearestFive(100.0), closeTo(100.0, 0.01));
    });

    test('2.5 rounds up to 5.0', () {
      expect(roundToNearestFive(2.5), closeTo(5.0, 0.01));
    });
  });

  group('PARITY: epley — matches v1.1 weight * (1 + Math.min(reps,10) / 30)', () {
    test('(200, 1) => 200.0 — reps=1 returns weight unchanged', () {
      expect(epley(200, 1), closeTo(200.0, 0.01));
    });

    test('(200, 5) => 233.33 — 200 * (1 + 5/30)', () {
      expect(epley(200, 5), closeTo(233.33, 0.01));
    });

    test('(200, 10) => 266.67 — 200 * (1 + 10/30)', () {
      expect(epley(200, 10), closeTo(266.67, 0.01));
    });

    test('(200, 15) => 266.67 — reps capped at 10', () {
      expect(epley(200, 15), closeTo(266.67, 0.01));
    });

    test('(100, 8) => 126.67 — 100 * (1 + 8/30)', () {
      expect(epley(100, 8), closeTo(126.67, 0.01));
    });
  });

  group('PARITY: getNextRecommendedWeight — matches v1.1 recommendation engine', () {
    test('first session: 70% of 1RM rounded → (100, first, 200) = 140.0', () {
      expect(
        getNextRecommendedWeight(100, SessionResult.first, 200),
        closeTo(140.0, 0.01),
      );
    });

    test('success: +5 lbs rounded → (100, success, 200) = 105.0', () {
      expect(
        getNextRecommendedWeight(100, SessionResult.success, 200),
        closeTo(105.0, 0.01),
      );
    });

    test('failure: -5 lbs, floor at 50% of 1RM → (100, failure, 200) = 100.0', () {
      // floor = roundToNearestFive(200 * 0.5) = 100.0
      // candidate = roundToNearestFive(100 - 5) = 95.0
      // clamp(100, ∞) → 100.0
      expect(
        getNextRecommendedWeight(100, SessionResult.failure, 200),
        closeTo(100.0, 0.01),
      );
    });

    test('failure at floor: cannot drop below 50% 1RM → (95, failure, 200) = 100.0', () {
      // floor = 100.0; candidate = roundToNearestFive(90) = 90.0 → clamped to 100.0
      expect(
        getNextRecommendedWeight(95, SessionResult.failure, 200),
        closeTo(100.0, 0.01),
      );
    });
  });

  group('PARITY: wasSetSuccessful — matches v1.1 set completion logic', () {
    test('reps met, no prescribedWeight → true', () {
      expect(
        wasSetSuccessful(
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 100,
        ),
        isTrue,
      );
    });

    test('reps not met → false', () {
      expect(
        wasSetSuccessful(
          actualReps: 4,
          prescribedReps: 5,
          actualWeight: 100,
        ),
        isFalse,
      );
    });

    test('reps met and weight met → true', () {
      expect(
        wasSetSuccessful(
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 100,
          prescribedWeight: 100,
        ),
        isTrue,
      );
    });

    test('reps met but weight not met → false', () {
      expect(
        wasSetSuccessful(
          actualReps: 5,
          prescribedReps: 5,
          actualWeight: 90,
          prescribedWeight: 100,
        ),
        isFalse,
      );
    });
  });

  group('PARITY: wasSessionSuccessful — matches v1.1 session evaluation', () {
    test('empty list → true (vacuous success — matches v1.1)', () {
      expect(wasSessionSuccessful([]), isTrue);
    });

    test('all sets successful → true', () {
      expect(
        wasSessionSuccessful([
          {
            'actualReps': 5,
            'prescribedReps': 5,
            'actualWeight': 100.0,
            'prescribedWeight': null,
          },
          {
            'actualReps': 6,
            'prescribedReps': 5,
            'actualWeight': 100.0,
            'prescribedWeight': 100.0,
          },
        ]),
        isTrue,
      );
    });

    test('one set failed → false', () {
      expect(
        wasSessionSuccessful([
          {
            'actualReps': 5,
            'prescribedReps': 5,
            'actualWeight': 100.0,
            'prescribedWeight': null,
          },
          {
            'actualReps': 3,
            'prescribedReps': 5,
            'actualWeight': 100.0,
            'prescribedWeight': null,
          },
        ]),
        isFalse,
      );
    });
  });

  group('PARITY: isPersonalRecord — matches v1.1 PR detection', () {
    test('weight > previousMax → true', () {
      expect(isPersonalRecord(205, 200), isTrue);
    });

    test('weight == previousMax → false (must strictly exceed)', () {
      expect(isPersonalRecord(200, 200), isFalse);
    });

    test('weight < previousMax → false', () {
      expect(isPersonalRecord(195, 200), isFalse);
    });
  });

  group('PARITY: detectPlateau — matches v1.1 variance threshold logic', () {
    test('fewer than 3 weights → false', () {
      expect(detectPlateau([100.0, 100.0]), isFalse);
    });

    test('exactly 3 weights with variance < 5 → true (plateau)', () {
      // max=102, min=100 → range=2 < 5
      expect(detectPlateau([100.0, 101.0, 102.0]), isTrue);
    });

    test('exactly 3 weights with variance >= 5 → false (progress)', () {
      // max=110, min=100 → range=10 >= 5
      expect(detectPlateau([100.0, 105.0, 110.0]), isFalse);
    });

    test('more than 3 weights: only last 3 matter — plateau in tail', () {
      // last 3: [102, 101, 102] → range=1 < 5 → true
      expect(detectPlateau([80.0, 90.0, 100.0, 102.0, 101.0, 102.0]), isTrue);
    });

    test('more than 3 weights: only last 3 matter — progress in tail', () {
      // last 3: [100, 105, 110] → range=10 >= 5 → false
      expect(detectPlateau([80.0, 82.0, 81.0, 100.0, 105.0, 110.0]), isFalse);
    });
  });
}
