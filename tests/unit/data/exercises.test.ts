import { describe, expect, it } from 'vitest';
import { getExerciseByName } from '@/data/exercises';

describe('Exercise Database', () => {
  it('should find pause-squat variant', () => {
    const exercise = getExerciseByName('pause-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Pause Squat');
  });

  it('should find zombie-squat variant', () => {
    const exercise = getExerciseByName('zombie-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Zombie Squat');
  });

  it('should find zercher-squat variant', () => {
    const exercise = getExerciseByName('zercher-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Zercher Squat');
  });

  it('should find bulgarian-split-squat', () => {
    const exercise = getExerciseByName('bulgarian-split-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Bulgarian Split Squat');
  });

  it('should find front-rack-hold', () => {
    const exercise = getExerciseByName('front-rack-hold');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Front Rack Hold');
  });
});
