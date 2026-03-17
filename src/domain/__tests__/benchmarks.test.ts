/**
 * Domain-level tests for benchmark-catalog.ts.
 * Tests encodeRoundsAndReps, decodeRoundsAndReps, getBenchmarkCategoryGroups,
 * and BENCHMARK_CATALOG structure.
 */

import {
  encodeRoundsAndReps,
  decodeRoundsAndReps,
  getBenchmarkCategoryGroups,
  BENCHMARK_CATALOG,
  BENCHMARK_CATEGORY_CROSSFIT_WOD,
  BENCHMARK_CATEGORY_STRENGTH,
  BENCHMARK_CATEGORY_ENDURANCE,
  BENCHMARK_CATEGORY_GYMNASTICS,
  BENCHMARK_CATEGORY_GENERAL_FITNESS,
} from '../benchmarks/benchmark-catalog';

describe('encodeRoundsAndReps', () => {
  it('encodes 5 rounds + 3 reps as 50003', () => {
    expect(encodeRoundsAndReps(5, 3)).toBe(50003);
  });

  it('encodes 0 rounds + 0 reps as 0', () => {
    expect(encodeRoundsAndReps(0, 0)).toBe(0);
  });

  it('encodes 10 rounds + 9999 reps correctly', () => {
    expect(encodeRoundsAndReps(10, 9999)).toBe(109999);
  });
});

describe('decodeRoundsAndReps', () => {
  it('decodes 50003 back to 5 rounds + 3 reps', () => {
    expect(decodeRoundsAndReps(50003)).toEqual({ rounds: 5, reps: 3 });
  });

  it('decodes 0 as 0 rounds + 0 reps', () => {
    expect(decodeRoundsAndReps(0)).toEqual({ rounds: 0, reps: 0 });
  });

  it('roundtrip: encode then decode returns original values', () => {
    const encoded = encodeRoundsAndReps(12, 7);
    expect(decodeRoundsAndReps(encoded)).toEqual({ rounds: 12, reps: 7 });
  });
});

describe('getBenchmarkCategoryGroups', () => {
  it('returns a non-empty array', () => {
    const groups = getBenchmarkCategoryGroups();
    expect(groups.length).toBeGreaterThan(0);
  });

  it('contains all known categories', () => {
    const groups = getBenchmarkCategoryGroups();
    const categories = groups.map((g) => g.category);
    expect(categories).toContain(BENCHMARK_CATEGORY_CROSSFIT_WOD);
    expect(categories).toContain(BENCHMARK_CATEGORY_STRENGTH);
    expect(categories).toContain(BENCHMARK_CATEGORY_ENDURANCE);
    expect(categories).toContain(BENCHMARK_CATEGORY_GYMNASTICS);
    expect(categories).toContain(BENCHMARK_CATEGORY_GENERAL_FITNESS);
  });

  it('each group has at least one entry', () => {
    const groups = getBenchmarkCategoryGroups();
    for (const group of groups) {
      expect(group.entries.length).toBeGreaterThan(0);
    }
  });

  it('returns categories in the defined display order', () => {
    const groups = getBenchmarkCategoryGroups();
    expect(groups[0]?.category).toBe(BENCHMARK_CATEGORY_CROSSFIT_WOD);
    expect(groups[1]?.category).toBe(BENCHMARK_CATEGORY_STRENGTH);
    expect(groups[2]?.category).toBe(BENCHMARK_CATEGORY_ENDURANCE);
    expect(groups[3]?.category).toBe(BENCHMARK_CATEGORY_GYMNASTICS);
    expect(groups[4]?.category).toBe(BENCHMARK_CATEGORY_GENERAL_FITNESS);
  });
});

describe('BENCHMARK_CATALOG', () => {
  it('is non-empty', () => {
    expect(BENCHMARK_CATALOG.length).toBeGreaterThan(0);
  });

  it('contains Fran', () => {
    const fran = BENCHMARK_CATALOG.find((b) => b.name === 'Fran');
    expect(fran).toBeDefined();
    expect(fran?.scoringType).toBe('time');
    expect(fran?.category).toBe(BENCHMARK_CATEGORY_CROSSFIT_WOD);
  });

  it('contains Murph', () => {
    const murph = BENCHMARK_CATALOG.find((b) => b.name === 'Murph');
    expect(murph).toBeDefined();
    expect(murph?.scoringType).toBe('time');
  });

  it('contains strength benchmarks with weight scoring', () => {
    const squat = BENCHMARK_CATALOG.find((b) => b.name === '1RM Back Squat');
    expect(squat).toBeDefined();
    expect(squat?.scoringType).toBe('weight');
    expect(squat?.category).toBe(BENCHMARK_CATEGORY_STRENGTH);
  });

  it('contains endurance benchmarks with distance scoring', () => {
    const run = BENCHMARK_CATALOG.find((b) => b.name === '1-Mile Run');
    expect(run).toBeDefined();
    expect(run?.scoringType).toBe('distance');
    expect(run?.category).toBe(BENCHMARK_CATEGORY_ENDURANCE);
  });

  it('all entries have required fields', () => {
    for (const benchmark of BENCHMARK_CATALOG) {
      expect(benchmark.id).toBeTruthy();
      expect(benchmark.name).toBeTruthy();
      expect(benchmark.category).toBeTruthy();
      expect(benchmark.scoringType).toBeTruthy();
    }
  });
});
