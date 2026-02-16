import { describe, it, expect } from 'vitest';
import { getAllPrograms, getProgramById, getProgramsByCategory } from '@/data/programs';

describe('Program Loader', () => {
  it('loads all programs', () => {
    const programs = getAllPrograms();
    expect(programs.length).toBeGreaterThan(0);
  });

  it('finds program by ID', () => {
    const program = getProgramById('back-squat-5x5-linear');
    expect(program).toBeDefined();
    expect(program?.name).toBe('Back Squat: 5x5 Linear Progression');
  });

  it('returns undefined for unknown program', () => {
    const program = getProgramById('unknown-program');
    expect(program).toBeUndefined();
  });

  it('filters programs by category', () => {
    const programs = getProgramsByCategory('back-squat');
    expect(programs.length).toBeGreaterThan(0);
    expect(programs.every(p => p.category === 'back-squat')).toBe(true);
  });
});
