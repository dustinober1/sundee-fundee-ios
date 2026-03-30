import type { BenchmarkScoringType } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface BenchmarkDefinition {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringType: BenchmarkScoringType;
  isPredefined: boolean;
  sortOrder: number;
}

// ---------------------------------------------------------------------------
// Category constants
// ---------------------------------------------------------------------------

export const BENCHMARK_CATEGORY_CLASSIC_WODS    = "Classic WODs";
export const BENCHMARK_CATEGORY_STRENGTH        = "Strength";
export const BENCHMARK_CATEGORY_ENDURANCE       = "Endurance";
export const BENCHMARK_CATEGORY_GYMNASTICS      = "Gymnastics";
export const BENCHMARK_CATEGORY_GENERAL_FITNESS = "General Fitness";
export const BENCHMARK_CATEGORY_SUNDEE_FUNDEE   = "Sundee Fundee";

export const BENCHMARK_CATEGORY_ORDER: string[] = [
  BENCHMARK_CATEGORY_SUNDEE_FUNDEE,
  BENCHMARK_CATEGORY_CLASSIC_WODS,
  BENCHMARK_CATEGORY_STRENGTH,
  BENCHMARK_CATEGORY_ENDURANCE,
  BENCHMARK_CATEGORY_GYMNASTICS,
  BENCHMARK_CATEGORY_GENERAL_FITNESS,
];

// ---------------------------------------------------------------------------
// Predefined benchmarks
// ---------------------------------------------------------------------------

function makeBenchmark(
  name: string,
  category: string,
  description: string,
  scoringType: BenchmarkScoringType,
  order: number
): BenchmarkDefinition {
  return {
    id: `predefined-${name.toLowerCase().replace(/\s+/g, "-")}`,
    name,
    category,
    workoutDescription: description,
    scoringType,
    isPredefined: true,
    sortOrder: order,
  };
}

export const PREDEFINED_BENCHMARKS: BenchmarkDefinition[] = (() => {
  const entries: BenchmarkDefinition[] = [];
  let order = 0;

  function add(name: string, category: string, description: string, scoringType: BenchmarkScoringType): void {
    entries.push(makeBenchmark(name, category, description, scoringType, order++));
  }

  // Sundee Fundee Exclusives
  add("Vanessa",  BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "Buy-in: 5 Triple Unders. 5 rounds for time: 5 Heavy Cleans (205/155 lb), 25 Double-Unders, 25 Toes-to-Bar. Cash-out: 5 Triple Unders.", "time");
  add("Eliz",     BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "5 rounds for time (25 min cap): 500m Row, 30 Crossovers (each side = 1), 100ft Farmers Carry (70/50 lb), 5 Overhead Squats (115/85 lb)", "time");
  add("Adria",    BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "For time (15 min cap): 3 rounds of 10 Sandbag Cleans (100/75 lb), 15 Sandbag Squats (100/75 lb). Then max distance Farmers Carry (70/50 lb).", "time");
  add("Kelsey",   BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "3 rounds for time (20 min cap): 50 Double-Unders, 10 Handstand Push-ups, 15 Hang Power Cleans (135/95 lb), 10 Chest-to-Bar Pull-ups", "time");
  add("Margarita", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "20-min benchmark: Part 1 AMRAP 5 min (10 Burpees, 15 KB Swings), Part 2 1RM Squat Clean, Part 3 AMRAP 5 min (10 Burpees, 15 Russian KB Swings), Part 4 1RM Snatch", "time");

  // Classic WODs — Time
  add("Fran",   BENCHMARK_CATEGORY_CLASSIC_WODS, "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups", "time");
  add("Helen",  BENCHMARK_CATEGORY_CLASSIC_WODS, "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups", "time");
  add("Grace",  BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 30 Clean & Jerks (135/95 lb)", "time");
  add("Karen",  BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)", "time");
  add("DT",     BENCHMARK_CATEGORY_CLASSIC_WODS, "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)", "time");
  add("Murph",  BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.", "time");
  add("Annie",  BENCHMARK_CATEGORY_CLASSIC_WODS, "50-40-30-20-10 reps for time: Double-Unders, Sit-ups", "time");

  // Classic WODs — Rounds/Reps
  add("Cindy",          BENCHMARK_CATEGORY_CLASSIC_WODS, "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.", "roundsAndReps");
  add("Fight Gone Bad", BENCHMARK_CATEGORY_CLASSIC_WODS, "3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20\"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.", "reps");

  // Strength — Weight (1RM)
  add("1RM Back Squat",     BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max back squat.", "weight");
  add("1RM Conventional Deadlift (No Straps)", BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max conventional deadlift without straps.", "weight");
  add("1RM Bench Press",    BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max flat barbell bench press.", "weight");
  add("1RM Overhead Press", BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max strict barbell overhead press.", "weight");
  add("1RM Clean and Jerk", BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max clean and jerk.", "weight");
  add("1RM Snatch",         BENCHMARK_CATEGORY_STRENGTH, "Find your 1-rep max snatch.", "weight");

  // Endurance — Distance/Time
  add("1-Mile Run",   BENCHMARK_CATEGORY_ENDURANCE, "Run 1 mile (1.6 km) as fast as possible.", "distance");
  add("5K Run",       BENCHMARK_CATEGORY_ENDURANCE, "Run 5 kilometers (3.1 miles) as fast as possible.", "distance");
  add("1.5-Mile Run", BENCHMARK_CATEGORY_ENDURANCE, "Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).", "distance");
  add("2K Row",       BENCHMARK_CATEGORY_ENDURANCE, "Row 2000 meters on an ergometer as fast as possible.", "distance");

  // Gymnastics — Reps
  add("Max Pull-ups",           BENCHMARK_CATEGORY_GYMNASTICS, "Maximum strict pull-ups in one unbroken set.", "reps");
  add("Max Push-ups (2 min)",   BENCHMARK_CATEGORY_GYMNASTICS, "Maximum push-ups completed in 2 minutes.", "reps");
  add("Max Handstand Push-ups", BENCHMARK_CATEGORY_GYMNASTICS, "Maximum strict handstand push-ups in one unbroken set.", "reps");
  add("Max Muscle-ups",         BENCHMARK_CATEGORY_GYMNASTICS, "Maximum ring or bar muscle-ups in one unbroken set.", "reps");

  // General Fitness
  add("100 Push-ups for Time", BENCHMARK_CATEGORY_GENERAL_FITNESS, "Complete 100 push-ups as fast as possible. Rest as needed.", "time");
  add("100 Sit-ups for Time",  BENCHMARK_CATEGORY_GENERAL_FITNESS, "Complete 100 sit-ups as fast as possible. Rest as needed.", "time");
  add("L-Sit Hold",            BENCHMARK_CATEGORY_GENERAL_FITNESS, "Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.", "time");

  return entries;
})();

// ---------------------------------------------------------------------------
// groupedByCategory
// ---------------------------------------------------------------------------

export function groupedByCategory(): Map<string, BenchmarkDefinition[]> {
  const map = new Map<string, BenchmarkDefinition[]>();
  for (const cat of BENCHMARK_CATEGORY_ORDER) {
    const entries = PREDEFINED_BENCHMARKS.filter((b) => b.category === cat);
    if (entries.length > 0) {
      map.set(cat, entries);
    }
  }
  return map;
}
