/**
 * Tests for scoring-input.ts utility functions.
 *
 * Tests: formatScore, parseTimeInput, isScoreImproved.
 */

import { formatScore, parseTimeInput, isScoreImproved } from '../scoring-input';

describe('formatScore', () => {
  it('formats time score as MM:SS (300 seconds -> "5:00")', () => {
    expect(formatScore('time', 300)).toBe('5:00');
  });

  it('formats time score with leading zero seconds (65 seconds -> "1:05")', () => {
    expect(formatScore('time', 65)).toBe('1:05');
  });

  it('formats time score for 0 seconds', () => {
    expect(formatScore('time', 0)).toBe('0:00');
  });

  it('formats roundsAndReps score using decodeRoundsAndReps (50003 -> "5 rounds + 3 reps")', () => {
    expect(formatScore('reps', 50003)).toBe('5 rounds + 3 reps');
  });

  it('formats reps score as plain number when reps < 10000 (just reps, no rounds)', () => {
    // Score of 15 reps — no rounds component
    expect(formatScore('reps', 15)).toBe('15 reps');
  });

  it('formats weight score with lbs label (315 -> "315.0 lbs") — backward compat default', () => {
    expect(formatScore('weight', 315)).toBe('315.0 lbs');
  });

  it('formats weight score in kg when unit is kg (315 lbs -> "143.0 kg")', () => {
    expect(formatScore('weight', 315, 'kg')).toBe('143.0 kg');
  });

  it('formats weight score in lbs when unit is explicitly lb', () => {
    expect(formatScore('weight', 315, 'lb')).toBe('315.0 lbs');
  });

  it('ignores unit param for time scoring type', () => {
    expect(formatScore('time', 300, 'kg')).toBe('5:00');
  });

  it('ignores unit param for reps scoring type', () => {
    expect(formatScore('reps', 15, 'kg')).toBe('15 reps');
  });

  it('formats distance score as MM:SS time (same as time)', () => {
    expect(formatScore('distance', 330)).toBe('5:30');
  });

  it('formats roundsAndReps score (5 rounds 3 reps encoded)', () => {
    // encodeRoundsAndReps(5, 3) = 50003
    expect(formatScore('roundsAndReps', 50003)).toBe('5 rounds + 3 reps');
  });
});

describe('parseTimeInput', () => {
  it('parses "5:30" as 330 seconds', () => {
    expect(parseTimeInput('5:30')).toBe(330);
  });

  it('parses "0:00" as 0 seconds', () => {
    expect(parseTimeInput('0:00')).toBe(0);
  });

  it('parses "1:05" as 65 seconds', () => {
    expect(parseTimeInput('1:05')).toBe(65);
  });

  it('parses "10:00" as 600 seconds', () => {
    expect(parseTimeInput('10:00')).toBe(600);
  });

  it('returns NaN for invalid input', () => {
    expect(parseTimeInput('abc')).toBeNaN();
  });

  it('returns NaN for empty string', () => {
    expect(parseTimeInput('')).toBeNaN();
  });
});

describe('isScoreImproved', () => {
  it('time: lower is better — 290 < 300, so improved', () => {
    expect(isScoreImproved('time', 290, 300)).toBe(true);
  });

  it('time: higher is worse — 310 > 300, not improved', () => {
    expect(isScoreImproved('time', 310, 300)).toBe(false);
  });

  it('time: equal scores — not improved', () => {
    expect(isScoreImproved('time', 300, 300)).toBe(false);
  });

  it('reps: higher is better — 60004 > 50003, improved', () => {
    expect(isScoreImproved('reps', 60004, 50003)).toBe(true);
  });

  it('reps: lower is worse — 40002 < 50003, not improved', () => {
    expect(isScoreImproved('reps', 40002, 50003)).toBe(false);
  });

  it('weight: higher is better — 325 > 315, improved', () => {
    expect(isScoreImproved('weight', 325, 315)).toBe(true);
  });

  it('weight: lower is worse — 305 < 315, not improved', () => {
    expect(isScoreImproved('weight', 305, 315)).toBe(false);
  });

  it('distance: lower is better (timed distance) — 290 < 300, improved', () => {
    expect(isScoreImproved('distance', 290, 300)).toBe(true);
  });

  it('roundsAndReps: higher is better — 60004 > 50003, improved', () => {
    expect(isScoreImproved('roundsAndReps', 60004, 50003)).toBe(true);
  });
});
