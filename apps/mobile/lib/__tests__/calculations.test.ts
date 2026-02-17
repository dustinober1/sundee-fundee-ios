import { describe, it, expect } from '@jest/globals';
import { calculateTargetWeight, isPersonalRecord, calculateVolumeLoad, detectPlateau } from '../calculations';

describe('Target Weight Calculator', () => {
  it('calculates 65% of 1RM correctly', () => {
    const result = calculateTargetWeight(300, 0.65);
    expect(result).toBe(195);
  });

  it('rounds to nearest 5 lbs', () => {
    const result = calculateTargetWeight(317, 0.65);
    expect(result).toBe(205);
  });

  it('handles 80% intensity', () => {
    const result = calculateTargetWeight(300, 0.80);
    expect(result).toBe(240);
  });
});

describe('Personal Record Detection', () => {
  it('detects new PR', () => {
    expect(isPersonalRecord(230, 225)).toBe(true);
  });

  it('does not detect PR when equal', () => {
    expect(isPersonalRecord(225, 225)).toBe(false);
  });

  it('does not detect PR when lower', () => {
    expect(isPersonalRecord(220, 225)).toBe(false);
  });
});

describe('Volume Load Calculator', () => {
  it('calculates 5x5 at 225 lbs', () => {
    const result = calculateVolumeLoad(225, 5, 5);
    expect(result).toBe(5625);
  });
});

describe('Plateau Detection', () => {
  it('detects plateau with same weights', () => {
    const weights = [225, 225, 225];
    expect(detectPlateau(weights)).toBe(true);
  });

  it('detects plateau with minimal variance', () => {
    const weights = [225, 227, 224];
    expect(detectPlateau(weights)).toBe(true);
  });

  it('does not detect plateau with progress', () => {
    const weights = [225, 230, 235];
    expect(detectPlateau(weights)).toBe(false);
  });

  it('returns false with insufficient data', () => {
    expect(detectPlateau([225])).toBe(false);
    expect(detectPlateau([225, 230])).toBe(false);
  });
});
