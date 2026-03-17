/**
 * HistoryCard.test.ts — Unit tests for HistoryCard pure helper functions.
 *
 * Tests formatVolume (with WeightUnit param) and formatDuration.
 * These are exported pure functions — no React rendering required.
 */

import { formatVolume, formatDuration } from '../HistoryCard';

describe('formatDuration', () => {
  it('formats zero seconds as 00:00', () => {
    expect(formatDuration(0)).toBe('00:00');
  });

  it('formats 90 seconds as 01:30', () => {
    expect(formatDuration(90)).toBe('01:30');
  });

  it('formats 3600 seconds as 60:00', () => {
    expect(formatDuration(3600)).toBe('60:00');
  });

  it('pads single-digit minutes and seconds', () => {
    expect(formatDuration(65)).toBe('01:05');
  });
});

describe('formatVolume', () => {
  it('returns null when volume is undefined', () => {
    expect(formatVolume(undefined, 'lb')).toBeNull();
  });

  it('returns null when volume is undefined and no unit given', () => {
    expect(formatVolume(undefined)).toBeNull();
  });

  it('formats 500 lbs correctly', () => {
    expect(formatVolume(500, 'lb')).toBe('500.0 lbs');
  });

  it('defaults to lbs when no unit arg given (backward compat)', () => {
    expect(formatVolume(500)).toBe('500.0 lbs');
  });

  it('formats 1500 lbs without k abbreviation', () => {
    expect(formatVolume(1500, 'lb')).toBe('1500.0 lbs');
  });

  it('formats 500 lbs converted to kg', () => {
    // 500 lbs = 226.796... kg -> nearest 0.5 = 227.0 kg
    expect(formatVolume(500, 'kg')).toBe('227.0 kg');
  });

  it('formats 1500 lbs converted to kg', () => {
    // 1500 lbs = 680.389... kg -> nearest 0.5 = 680.5 kg
    expect(formatVolume(1500, 'kg')).toBe('680.5 kg');
  });
});
