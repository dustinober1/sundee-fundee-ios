/**
 * BenchmarkCatalog
 * Ported from SundeeFundee/Domain/BenchmarkCatalog.swift
 *
 * Predefined catalog of benchmark workouts shipped with the app.
 * Sort order and entry data match Swift exactly.
 *
 * roundsAndReps encoding: rounds * 10000 + reps (as Double in Swift, number here).
 * Higher is better. Decode: rounds = Math.floor(value / 10000), reps = value % 10000.
 */

import type { BenchmarkDefinition } from '../types';

// ---------------------------------------------------------------------------
// Category constants — match Swift BenchmarkCatalog
// ---------------------------------------------------------------------------

export const BENCHMARK_CATEGORY_CROSSFIT_WOD = 'Classic WODs';
export const BENCHMARK_CATEGORY_STRENGTH = 'Strength';
export const BENCHMARK_CATEGORY_ENDURANCE = 'Endurance';
export const BENCHMARK_CATEGORY_GYMNASTICS = 'Gymnastics';
export const BENCHMARK_CATEGORY_GENERAL_FITNESS = 'General Fitness';

/** All category names in display order — matches Swift categoryOrder */
export const BENCHMARK_CATEGORY_ORDER: readonly string[] = [
  BENCHMARK_CATEGORY_CROSSFIT_WOD,
  BENCHMARK_CATEGORY_STRENGTH,
  BENCHMARK_CATEGORY_ENDURANCE,
  BENCHMARK_CATEGORY_GYMNASTICS,
  BENCHMARK_CATEGORY_GENERAL_FITNESS,
];

// ---------------------------------------------------------------------------
// roundsAndReps encoding / decoding
// ---------------------------------------------------------------------------

/**
 * Encode rounds and reps into a single number for AMRAP-style benchmark scores.
 * Matches Swift BenchmarkScoringType.roundsAndReps encoding: rounds * 10000 + reps.
 * Higher is better.
 */
export function encodeRoundsAndReps(rounds: number, reps: number): number {
  return rounds * 10000 + reps;
}

/**
 * Decode an AMRAP-style encoded score back to rounds and reps.
 * Matches CLAUDE.md: rounds = Int(value) / 10000, reps = Int(value) % 10000.
 */
export function decodeRoundsAndReps(encoded: number): { rounds: number; reps: number } {
  const rounds = Math.floor(encoded / 10000);
  const reps = encoded % 10000;
  return { rounds, reps };
}

// ---------------------------------------------------------------------------
// Predefined catalog — matches Swift BenchmarkCatalog.predefined
// Sort order matches Swift insertion order exactly.
// ---------------------------------------------------------------------------

function makeDef(
  name: string,
  category: string,
  workoutDescription: string,
  scoringType: BenchmarkDefinition['scoringType'],
  sortOrder: number,
): BenchmarkDefinition {
  return {
    id: `predefined-${name.toLowerCase().replace(/ /g, '-')}`,
    userID: '',
    name,
    category,
    workoutDescription,
    scoringType,
    isPredefined: true,
    sortOrder,
  };
}

export const BENCHMARK_CATALOG: BenchmarkDefinition[] = (() => {
  const entries: BenchmarkDefinition[] = [];
  let order = 0;

  function add(
    name: string,
    category: string,
    description: string,
    scoring: BenchmarkDefinition['scoringType'],
  ): void {
    entries.push(makeDef(name, category, description, scoring, order));
    order += 1;
  }

  // Classic WODs — Time
  add('Fran', BENCHMARK_CATEGORY_CROSSFIT_WOD, '21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups', 'time');
  add('Helen', BENCHMARK_CATEGORY_CROSSFIT_WOD, '3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups', 'time');
  add('Grace', BENCHMARK_CATEGORY_CROSSFIT_WOD, 'For time: 30 Clean & Jerks (135/95 lb)', 'time');
  add('Karen', BENCHMARK_CATEGORY_CROSSFIT_WOD, 'For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)', 'time');
  add('DT', BENCHMARK_CATEGORY_CROSSFIT_WOD, '5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)', 'time');
  add('Murph', BENCHMARK_CATEGORY_CROSSFIT_WOD, 'For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.', 'time');
  add('Annie', BENCHMARK_CATEGORY_CROSSFIT_WOD, '50-40-30-20-10 reps for time: Double-Unders, Sit-ups', 'time');

  // Classic WODs — Reps/Rounds
  add('Cindy', BENCHMARK_CATEGORY_CROSSFIT_WOD, 'AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.', 'reps');
  add('Fight Gone Bad', BENCHMARK_CATEGORY_CROSSFIT_WOD, '3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.', 'reps');

  // Strength — Weight (1RM)
  add('1RM Back Squat', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max back squat.', 'weight');
  add('1RM Conventional Deadlift (No Straps)', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max conventional deadlift without straps.', 'weight');
  add('1RM Bench Press', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max flat barbell bench press.', 'weight');
  add('1RM Overhead Press', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max strict barbell overhead press.', 'weight');
  add('1RM Clean and Jerk', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max clean and jerk.', 'weight');
  add('1RM Snatch', BENCHMARK_CATEGORY_STRENGTH, 'Find your 1-rep max snatch.', 'weight');

  // Endurance — Time/Distance
  add('1-Mile Run', BENCHMARK_CATEGORY_ENDURANCE, 'Run 1 mile (1.6 km) as fast as possible.', 'distance');
  add('5K Run', BENCHMARK_CATEGORY_ENDURANCE, 'Run 5 kilometers (3.1 miles) as fast as possible.', 'distance');
  add('1.5-Mile Run', BENCHMARK_CATEGORY_ENDURANCE, 'Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).', 'distance');
  add('2K Row', BENCHMARK_CATEGORY_ENDURANCE, 'Row 2000 meters on an ergometer as fast as possible.', 'distance');

  // Gymnastics — Reps
  add('Max Pull-ups', BENCHMARK_CATEGORY_GYMNASTICS, 'Maximum strict pull-ups in one unbroken set.', 'reps');
  add('Max Push-ups (2 min)', BENCHMARK_CATEGORY_GYMNASTICS, 'Maximum push-ups completed in 2 minutes.', 'reps');
  add('Max Handstand Push-ups', BENCHMARK_CATEGORY_GYMNASTICS, 'Maximum strict handstand push-ups in one unbroken set.', 'reps');
  add('Max Muscle-ups', BENCHMARK_CATEGORY_GYMNASTICS, 'Maximum ring or bar muscle-ups in one unbroken set.', 'reps');

  // General Fitness
  add('100 Push-ups for Time', BENCHMARK_CATEGORY_GENERAL_FITNESS, 'Complete 100 push-ups as fast as possible. Rest as needed.', 'time');
  add('100 Sit-ups for Time', BENCHMARK_CATEGORY_GENERAL_FITNESS, 'Complete 100 sit-ups as fast as possible. Rest as needed.', 'time');
  add('L-Sit Hold', BENCHMARK_CATEGORY_GENERAL_FITNESS, 'Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.', 'time');

  return entries;
})();

// ---------------------------------------------------------------------------
// Grouped catalog by category
// ---------------------------------------------------------------------------

export interface BenchmarkCategoryGroup {
  category: string;
  entries: BenchmarkDefinition[];
}

/**
 * Predefined entries grouped by category, in display order.
 * Matches Swift BenchmarkCatalog.groupedByCategory.
 */
export function getBenchmarkCategoryGroups(): BenchmarkCategoryGroup[] {
  return BENCHMARK_CATEGORY_ORDER.reduce<BenchmarkCategoryGroup[]>((acc, cat) => {
    const entries = BENCHMARK_CATALOG.filter((b) => b.category === cat);
    if (entries.length > 0) {
      acc.push({ category: cat, entries });
    }
    return acc;
  }, []);
}
