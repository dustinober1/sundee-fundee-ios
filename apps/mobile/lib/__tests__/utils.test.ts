import { describe, it, expect } from '@jest/globals';
import { cn, roundToNearestFive, generateId } from '../utils';

describe('cn utility', () => {
  it('merges tailwind classes', () => {
    const result = cn('px-2', 'py-1');
    expect(result).toBe('px-2 py-1');
  });

  it('removes conflicting classes', () => {
    const result = cn('px-2', 'px-4');
    expect(result).toBe('px-4');
  });

  it('handles conditional classes', () => {
    const result = cn('base-class', false && 'remove-me', true && 'keep-me');
    expect(result).toBe('base-class keep-me');
  });
});

describe('roundToNearestFive', () => {
  it('rounds to nearest 5', () => {
    expect(roundToNearestFive(197)).toBe(195);
    expect(roundToNearestFive(198)).toBe(200);
    expect(roundToNearestFive(200)).toBe(200);
  });

  it('handles edge cases', () => {
    expect(roundToNearestFive(0)).toBe(0);
    expect(roundToNearestFive(2.5)).toBe(0);
    expect(roundToNearestFive(3)).toBe(5);
  });
});

describe('generateId', () => {
  it('generates unique IDs', () => {
    const id1 = generateId();
    const id2 = generateId();
    expect(id1).not.toBe(id2);
  });

  it('generates valid UUID format', () => {
    const id = generateId();
    expect(id).toMatch(/^[0-9a-f-]{36}$/);
  });
});
