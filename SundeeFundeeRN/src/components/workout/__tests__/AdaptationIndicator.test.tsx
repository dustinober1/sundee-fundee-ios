/**
 * AdaptationIndicator.test.tsx
 *
 * Tests for the AdaptationIndicator component and its static formatDelta helper.
 */

import { formatDelta } from '../AdaptationIndicator';

describe('formatDelta', () => {
  it('returns empty string for multiplier 1.0 (no adaptation)', () => {
    expect(formatDelta(1.0)).toBe('');
  });

  it('returns "down 10%" for multiplier 0.9', () => {
    expect(formatDelta(0.9)).toBe('down 10%');
  });

  it('returns "up 5%" for multiplier 1.05', () => {
    expect(formatDelta(1.05)).toBe('up 5%');
  });

  it('returns "down 25%" for multiplier 0.75', () => {
    expect(formatDelta(0.75)).toBe('down 25%');
  });

  it('returns "up 12%" for multiplier 1.12', () => {
    expect(formatDelta(1.12)).toBe('up 12%');
  });

  it('returns "down 3%" for multiplier 0.97', () => {
    expect(formatDelta(0.97)).toBe('down 3%');
  });

  it('returns empty string for multiplier 1.001 (rounds to 0%)', () => {
    expect(formatDelta(1.001)).toBe('');
  });

  it('returns "up 25%" for multiplier 1.25', () => {
    expect(formatDelta(1.25)).toBe('up 25%');
  });

  it('returns "down 8%" for multiplier 0.92', () => {
    expect(formatDelta(0.92)).toBe('down 8%');
  });
});
