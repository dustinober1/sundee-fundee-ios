import { describe, it, expect } from 'vitest';
import { getAllPrograms, getProgramById, getProgramsByCategory } from '@/data/programs';

describe('Program Loader', () => {
  it('loads all programs', () => {
    const programs = getAllPrograms();
    expect(programs.length).toBe(1);
  });

  it('finds program by ID', () => {
    const program = getProgramById('back-squat-complete-cycle');
    expect(program).toBeDefined();
    expect(program?.name).toBe('Back Squat: Complete 8-Week Cycle');
  });

  it('returns undefined for unknown program', () => {
    const program = getProgramById('unknown-program');
    expect(program).toBeUndefined();
  });

  it('filters programs by category', () => {
    const programs = getProgramsByCategory('back-squat');
    expect(programs.length).toBe(1);
    expect(programs.every(p => p.category === 'back-squat')).toBe(true);
  });
});
