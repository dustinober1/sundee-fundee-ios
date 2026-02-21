import { describe, expect, it } from 'vitest';
import {
  calculateTargetWeight,
  detectPlateau,
  getNextRecommendedWeight,
  isPersonalRecord,
  wasSessionSuccessful,
  wasSetSuccessful,
} from '../src/lib/calculations';

describe('calculateTargetWeight', () => {
  it('calculates 65% of 1RM and rounds to nearest 5', () => {
    expect(calculateTargetWeight(300, 0.65)).toBe(195);
    expect(calculateTargetWeight(317, 0.65)).toBe(205);
  });
});

describe('getNextRecommendedWeight', () => {
  it('uses 70% for first session', () => {
    expect(getNextRecommendedWeight(0, 'first', 315)).toBe(220);
  });

  it('adds weight after success and respects rounding', () => {
    expect(getNextRecommendedWeight(203, 'success', 300)).toBe(210);
  });

  it('uses floor after failure', () => {
    expect(getNextRecommendedWeight(155, 'failure', 300)).toBe(150);
  });
});

describe('set/session outcomes', () => {
  it('evaluates set success', () => {
    expect(
      wasSetSuccessful({
        actualReps: 5,
        prescribedReps: 5,
        actualWeight: 200,
        prescribedWeight: 195,
      })
    ).toBe(true);
  });

  it('evaluates session success', () => {
    expect(
      wasSessionSuccessful([
        { actualReps: 5, prescribedReps: 5, actualWeight: 200, prescribedWeight: 195 },
        { actualReps: 6, prescribedReps: 5, actualWeight: 205, prescribedWeight: 200 },
      ])
    ).toBe(true);
  });
});

describe('record and plateau helpers', () => {
  it('detects PR correctly', () => {
    expect(isPersonalRecord(230, 225)).toBe(true);
    expect(isPersonalRecord(225, 225)).toBe(false);
  });

  it('detects plateau for near-static loads', () => {
    expect(detectPlateau([225, 227, 224])).toBe(true);
    expect(detectPlateau([225, 230, 235])).toBe(false);
  });
});
