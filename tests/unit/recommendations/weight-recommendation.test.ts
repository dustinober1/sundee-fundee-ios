import { describe, it, expect } from 'vitest';
import {
  getNextRecommendedWeight,
  wasSetSuccessful,
  wasSessionSuccessful,
} from '@/lib/calculations';

describe('getNextRecommendedWeight', () => {
  describe('first session (70% 1RM)', () => {
    it('returns 70% of 1RM rounded to nearest 5 — 300 1RM → 210', () => {
      // 300 * 0.7 = 210 (already divisible by 5)
      expect(getNextRecommendedWeight(0, 'first', 300)).toBe(210);
    });

    it('returns 70% of 1RM rounded to nearest 5 — 315 1RM → 220', () => {
      // 315 * 0.7 = 220.5 → round(220.5 / 5) * 5 = round(44.1) * 5 = 44 * 5 = 220
      expect(getNextRecommendedWeight(0, 'first', 315)).toBe(220);
    });
  });

  describe('success (+5 lbs, rounded)', () => {
    it('adds 5 to exact weight — 200 → 205', () => {
      expect(getNextRecommendedWeight(200, 'success', 300)).toBe(205);
    });

    it('adds 5 then rounds — 203 → 210', () => {
      // 203 + 5 = 208 → round(208 / 5) * 5 = round(41.6) * 5 = 42 * 5 = 210
      expect(getNextRecommendedWeight(203, 'success', 300)).toBe(210);
    });
  });

  describe('failure (-5 lbs, floor at 50% 1RM)', () => {
    it('subtracts 5 from current — 200, 300 1RM → 195', () => {
      // floor = round(300 * 0.5 / 5) * 5 = 150; 200 - 5 = 195 → 195 > 150, so 195
      expect(getNextRecommendedWeight(200, 'failure', 300)).toBe(195);
    });

    it('does not go below 50% 1RM floor — 155, 300 1RM → 150', () => {
      // floor = 150; 155 - 5 = 150 → equals floor → 150
      expect(getNextRecommendedWeight(155, 'failure', 300)).toBe(150);
    });
  });
});

describe('wasSetSuccessful', () => {
  it('returns true when reps met and weight met', () => {
    expect(
      wasSetSuccessful({ actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 })
    ).toBe(true);
  });

  it('returns false when reps missed', () => {
    expect(
      wasSetSuccessful({ actualReps: 4, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 })
    ).toBe(false);
  });

  it('returns false when weight missed', () => {
    expect(
      wasSetSuccessful({ actualReps: 5, prescribedReps: 5, actualWeight: 195, prescribedWeight: 200 })
    ).toBe(false);
  });

  it('returns true when no prescribed weight (only checks reps)', () => {
    expect(
      wasSetSuccessful({ actualReps: 5, prescribedReps: 5, actualWeight: 200 })
    ).toBe(true);
  });

  it('returns false when reps missed and no prescribed weight', () => {
    expect(
      wasSetSuccessful({ actualReps: 3, prescribedReps: 5, actualWeight: 200 })
    ).toBe(false);
  });
});

describe('wasSessionSuccessful', () => {
  it('returns true when all sets are successful', () => {
    const sets = [
      { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 },
      { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 },
      { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 },
    ];
    expect(wasSessionSuccessful(sets)).toBe(true);
  });

  it('returns false when one set fails', () => {
    const sets = [
      { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 },
      { actualReps: 4, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 }, // failed
      { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 200 },
    ];
    expect(wasSessionSuccessful(sets)).toBe(false);
  });

  it('returns true for empty array (vacuously successful)', () => {
    expect(wasSessionSuccessful([])).toBe(true);
  });
});
