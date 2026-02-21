import { describe, expect, it } from 'vitest';
import { getProgramById } from '../src/data/programs';
import { normalizeProgram } from '../src/lib/programs';

describe('normalizeProgram', () => {
  it('normalizes v1 program structure', () => {
    const source = getProgramById('bench-press-strength');
    expect(source).toBeTruthy();
    const normalized = normalizeProgram(source!);
    expect(normalized.sessionsPerWeek).toBe(3);
    expect(normalized.weeks[0].sessions[0].sessionName).toContain('Week 1');
  });

  it('normalizes v2 program structure', () => {
    const source = getProgramById('back-squat-complete-cycle');
    expect(source).toBeTruthy();
    const normalized = normalizeProgram(source!);
    expect(normalized.weeks[0].sessions[0].sessionType).toBe('support');
    expect(normalized.weeks[0].sessions[0].exercises.length).toBeGreaterThan(0);
  });
});
