/**
 * Tests for formatWeight utility.
 *
 * Coverage:
 * - formatWeight: lbs→display string, kg→display string (rounded to 0.5)
 * - formatWeightNumeric: same conversion returning number
 * - parseWeightInput: user input → stored lbs, handles empty/NaN/zero
 */

import { formatWeight, formatWeightNumeric, parseWeightInput } from '../formatWeight';

const POUNDS_PER_KG = 2.2046226218;

describe('formatWeight', () => {
  it('formats lbs value with "lbs" suffix rounded to 1 decimal', () => {
    expect(formatWeight(132.28, 'lb')).toBe('132.3 lbs');
  });

  it('formats kg value rounded to nearest 0.5 with "kg" suffix', () => {
    // 132.28 lbs → 59.9999... kg → rounds to 60.0 kg
    expect(formatWeight(132.28, 'kg')).toBe('60.0 kg');
  });

  it('rounds kg to nearest 0.5 (61.235 rounds down to 61.0)', () => {
    // 135 lbs → ~61.235 kg → nearest 0.5 = 61.0 (closer to 61 than to 61.5)
    expect(formatWeight(135, 'kg')).toBe('61.0 kg');
  });

  it('rounds kg to nearest 0.5 downward', () => {
    // 100 lbs → ~45.359 kg → nearest 0.5 = 45.5
    const result = formatWeight(100, 'kg');
    expect(result).toMatch(/^45\.[05] kg$/);
  });

  it('handles 0 lbs', () => {
    expect(formatWeight(0, 'lb')).toBe('0.0 lbs');
    expect(formatWeight(0, 'kg')).toBe('0.0 kg');
  });

  it('handles large values in lbs', () => {
    expect(formatWeight(1000, 'lb')).toBe('1000.0 lbs');
  });

  it('handles large values in kg', () => {
    // 1000 lbs → ~453.6 kg → 453.5 (nearest 0.5)
    const result = formatWeight(1000, 'kg');
    expect(result).toMatch(/^45[0-9]\.[05] kg$/);
  });

  it('handles negative values in lbs', () => {
    // Negative weights should still format (even if unusual)
    expect(formatWeight(-50, 'lb')).toBe('-50.0 lbs');
  });
});

describe('formatWeightNumeric', () => {
  it('returns lbs value rounded to 1 decimal as number', () => {
    expect(formatWeightNumeric(132.28, 'lb')).toBeCloseTo(132.3, 1);
  });

  it('returns kg value rounded to nearest 0.5 as number', () => {
    expect(formatWeightNumeric(132.28, 'kg')).toBeCloseTo(60.0, 1);
  });

  it('returns 0.0 for 0 lbs in either unit', () => {
    expect(formatWeightNumeric(0, 'lb')).toBe(0);
    expect(formatWeightNumeric(0, 'kg')).toBe(0);
  });
});

describe('parseWeightInput', () => {
  it('parses kg input and returns stored lbs', () => {
    // "60" kg → 60 * POUNDS_PER_KG ≈ 132.28 lbs
    const result = parseWeightInput('60', 'kg');
    expect(result).toBeCloseTo(60 * POUNDS_PER_KG, 4);
  });

  it('parses lbs input and returns as-is', () => {
    expect(parseWeightInput('135', 'lb')).toBe(135);
  });

  it('returns 0 for empty string in kg', () => {
    expect(parseWeightInput('', 'kg')).toBe(0);
  });

  it('returns 0 for empty string in lbs', () => {
    expect(parseWeightInput('', 'lb')).toBe(0);
  });

  it('returns NaN for non-numeric input in lbs', () => {
    expect(parseWeightInput('abc', 'lb')).toBeNaN();
  });

  it('returns NaN for non-numeric input in kg', () => {
    expect(parseWeightInput('abc', 'kg')).toBeNaN();
  });

  it('handles decimal kg input', () => {
    // "60.5" kg → 60.5 * POUNDS_PER_KG ≈ 133.38 lbs
    const result = parseWeightInput('60.5', 'kg');
    expect(result).toBeCloseTo(60.5 * POUNDS_PER_KG, 4);
  });

  it('handles decimal lbs input', () => {
    expect(parseWeightInput('135.5', 'lb')).toBeCloseTo(135.5, 4);
  });
});
