/**
 * Tests for notification-copy domain module.
 *
 * Pure TypeScript — no mocking needed.
 */

import {
  getCycleAwareCopy,
  getGenericCopy,
  CYCLE_COPY,
  GENERIC_COPY,
} from '../../domain/notifications/notification-copy';

describe('CYCLE_COPY', () => {
  it('has an entry for each CyclePhase', () => {
    expect(CYCLE_COPY.menstrual).toBeTruthy();
    expect(CYCLE_COPY.follicular).toBeTruthy();
    expect(CYCLE_COPY.ovulation).toBeTruthy();
    expect(CYCLE_COPY.luteal).toBeTruthy();
  });
});

describe('GENERIC_COPY', () => {
  it('has 4 or more variations', () => {
    expect(GENERIC_COPY.length).toBeGreaterThanOrEqual(4);
  });

  it('contains only non-empty strings', () => {
    GENERIC_COPY.forEach((copy) => {
      expect(typeof copy).toBe('string');
      expect(copy.length).toBeGreaterThan(0);
    });
  });
});

describe('getCycleAwareCopy', () => {
  it('menstrual phase copy contains "Menstrual"', () => {
    expect(getCycleAwareCopy('menstrual')).toContain('Menstrual');
  });

  it('follicular phase copy references follicular (case insensitive)', () => {
    expect(getCycleAwareCopy('follicular').toLowerCase()).toContain('follicular');
  });

  it('ovulation phase copy references peak or energy', () => {
    const copy = getCycleAwareCopy('ovulation').toLowerCase();
    expect(copy.includes('peak') || copy.includes('energy')).toBe(true);
  });

  it('luteal phase copy references body listening or consistent', () => {
    const copy = getCycleAwareCopy('luteal').toLowerCase();
    expect(copy.includes('listen') || copy.includes('body') || copy.includes('consistent')).toBe(
      true,
    );
  });

  it('returns the same string as CYCLE_COPY[phase]', () => {
    expect(getCycleAwareCopy('menstrual')).toBe(CYCLE_COPY.menstrual);
    expect(getCycleAwareCopy('follicular')).toBe(CYCLE_COPY.follicular);
    expect(getCycleAwareCopy('ovulation')).toBe(CYCLE_COPY.ovulation);
    expect(getCycleAwareCopy('luteal')).toBe(CYCLE_COPY.luteal);
  });
});

describe('getGenericCopy', () => {
  it('returns a non-empty string', () => {
    const copy = getGenericCopy();
    expect(typeof copy).toBe('string');
    expect(copy.length).toBeGreaterThan(0);
  });

  it('returns a value from GENERIC_COPY array', () => {
    const copy = getGenericCopy();
    expect(GENERIC_COPY).toContain(copy);
  });
});
