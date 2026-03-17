import { filterExercises } from '../exercises/exercise-filter';
import type { Exercise, MuscleGroup } from '../exercises/exercise-types';
import { MUSCLE_GROUPS } from '../exercises/exercise-types';
import exercisesJson from '../../resources/exercises.json';

const SAMPLE_EXERCISES: Exercise[] = [
  { id: 'ex-001', name: 'Barbell Bench Press', muscleGroup: 'Chest', isCustom: false, equipmentType: 'barbell' },
  { id: 'ex-002', name: 'Dumbbell Bench Press', muscleGroup: 'Chest', isCustom: false, equipmentType: 'dumbbell' },
  { id: 'ex-003', name: 'Barbell Squat', muscleGroup: 'Legs', isCustom: false, equipmentType: 'barbell' },
  { id: 'ex-004', name: 'Pull-Up', muscleGroup: 'Back', isCustom: false, equipmentType: 'bodyweight' },
  { id: 'ex-005', name: 'Plank', muscleGroup: 'Core', isCustom: false, equipmentType: 'bodyweight' },
  { id: 'ex-006', name: 'Bench Dip', muscleGroup: 'Arms', isCustom: false, equipmentType: 'bodyweight' },
];

describe('filterExercises', () => {
  it('returns exercises matching name substring (case-insensitive)', () => {
    const result = filterExercises(SAMPLE_EXERCISES, 'bench', undefined);
    expect(result.map((e) => e.id)).toEqual(['ex-001', 'ex-002', 'ex-006']);
  });

  it('returns only exercises matching muscle group when query is empty', () => {
    const result = filterExercises(SAMPLE_EXERCISES, '', 'Chest');
    expect(result.map((e) => e.id)).toEqual(['ex-001', 'ex-002']);
  });

  it('filters by both name AND muscle group', () => {
    const result = filterExercises(SAMPLE_EXERCISES, 'squat', 'Legs');
    expect(result.map((e) => e.id)).toEqual(['ex-003']);
  });

  it('returns all exercises when query is empty and no muscle group', () => {
    const result = filterExercises(SAMPLE_EXERCISES, '', undefined);
    expect(result).toHaveLength(SAMPLE_EXERCISES.length);
  });

  it('trims and lowercases the query', () => {
    const result = filterExercises(SAMPLE_EXERCISES, '  BENCH  ', undefined);
    expect(result.map((e) => e.id)).toEqual(['ex-001', 'ex-002', 'ex-006']);
  });

  it('returns empty array when no exercises match', () => {
    const result = filterExercises(SAMPLE_EXERCISES, 'zzz_nomatch', undefined);
    expect(result).toHaveLength(0);
  });

  it('handles empty exercises array', () => {
    const result = filterExercises([], 'bench', undefined);
    expect(result).toHaveLength(0);
  });

  it('returns no results when muscle group filter does not match', () => {
    const result = filterExercises(SAMPLE_EXERCISES, '', 'Full Body');
    expect(result).toHaveLength(0);
  });

  it('name filter does not cross muscle group boundary (bench in Arms only)', () => {
    const result = filterExercises(SAMPLE_EXERCISES, 'dip', 'Arms');
    expect(result.map((e) => e.id)).toEqual(['ex-006']);
  });
});

describe('MUSCLE_GROUPS constant', () => {
  it('contains exactly 7 groups', () => {
    expect(MUSCLE_GROUPS).toHaveLength(7);
  });

  it('contains all expected groups', () => {
    expect(MUSCLE_GROUPS).toContain('Chest');
    expect(MUSCLE_GROUPS).toContain('Back');
    expect(MUSCLE_GROUPS).toContain('Legs');
    expect(MUSCLE_GROUPS).toContain('Shoulders');
    expect(MUSCLE_GROUPS).toContain('Arms');
    expect(MUSCLE_GROUPS).toContain('Core');
    expect(MUSCLE_GROUPS).toContain('Full Body');
  });
});

describe('exercises.json catalog', () => {
  it('contains at least 200 entries', () => {
    expect(exercisesJson.length).toBeGreaterThanOrEqual(200);
  });

  it('covers all 7 muscle groups', () => {
    const groups = new Set(exercisesJson.map((e: Exercise) => e.muscleGroup));
    MUSCLE_GROUPS.forEach((g) => expect(groups.has(g)).toBe(true));
  });

  it('every entry has required fields', () => {
    exercisesJson.forEach((e: Exercise) => {
      expect(e).toHaveProperty('id');
      expect(e).toHaveProperty('name');
      expect(e).toHaveProperty('muscleGroup');
      expect(e).toHaveProperty('isCustom', false);
      expect(typeof e.id).toBe('string');
      expect(typeof e.name).toBe('string');
    });
  });

  it('all ids are unique', () => {
    const ids = exercisesJson.map((e: Exercise) => e.id);
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(ids.length);
  });

  it('all muscleGroups are valid MuscleGroup values', () => {
    exercisesJson.forEach((e: Exercise) => {
      expect(MUSCLE_GROUPS).toContain(e.muscleGroup);
    });
  });
});
