import { describe, it, expect } from 'vitest';
import { formatWeight, formatWeightNumeric, parseWeightInput } from './formatWeight';

describe('formatWeight', () => {
  it('formats lbs with suffix', () => {
    expect(formatWeight(135, 'lb')).toBe('135.0 lbs');
  });

  it('formats kg with conversion and rounding', () => {
    const result = formatWeight(135, 'kg');
    expect(result).toMatch(/\d+\.\d kg/);
    // 135 lbs ≈ 61.2 kg, rounds to 61.0 or 61.5
    expect(result).toMatch(/^6[01]\.\d kg$/);
  });

  it('handles zero', () => {
    expect(formatWeight(0, 'lb')).toBe('0.0 lbs');
    expect(formatWeight(0, 'kg')).toBe('0.0 kg');
  });
});

describe('formatWeightNumeric', () => {
  it('returns numeric lbs rounded to 1 decimal', () => {
    expect(formatWeightNumeric(135.67, 'lb')).toBe(135.7);
  });

  it('returns numeric kg rounded to half kg', () => {
    const kg = formatWeightNumeric(135, 'kg');
    expect(kg % 0.5).toBe(0); // should be a multiple of 0.5
  });
});

describe('parseWeightInput', () => {
  it('parses lbs as-is', () => {
    expect(parseWeightInput('135', 'lb')).toBe(135);
  });

  it('converts kg to lbs', () => {
    const lbs = parseWeightInput('60', 'kg');
    expect(lbs).toBeGreaterThan(130);
    expect(lbs).toBeLessThan(135);
  });

  it('returns 0 for empty string', () => {
    expect(parseWeightInput('', 'lb')).toBe(0);
  });

  it('returns NaN for non-numeric', () => {
    expect(parseWeightInput('abc', 'lb')).toBeNaN();
  });
});
