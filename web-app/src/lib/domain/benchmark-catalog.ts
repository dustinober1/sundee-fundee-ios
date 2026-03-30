import type { BenchmarkScoringType } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type BenchmarkIntensity = 1 | 2 | 3 | 4 | 5;

export interface BenchmarkDefinition {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringType: BenchmarkScoringType;
  isPredefined: boolean;
  sortOrder: number;
  // Enhanced display fields
  intensity?: BenchmarkIntensity;     // 1-5 visual intensity gauge
  movementTags?: string[];            // e.g., ["Heavy Pull", "High Cardio"]
  equipment?: string[];               // e.g., ["barbell", "pull-up bar"]
  timeDomain?: string;                // e.g., "12-18 min"
  coachNotes?: string;                // Scaling, strategy, common mistakes
}

export interface BenchmarkEnhancements {
  intensity?: BenchmarkIntensity;
  movementTags?: string[];
  equipment?: string[];
  timeDomain?: string;
  coachNotes?: string;
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
  order: number,
  enhancements?: BenchmarkEnhancements
): BenchmarkDefinition {
  return {
    id: `predefined-${name.toLowerCase().replace(/\s+/g, "-")}`,
    name,
    category,
    workoutDescription: description,
    scoringType,
    isPredefined: true,
    sortOrder: order,
    ...enhancements,
  };
}

export const PREDEFINED_BENCHMARKS: BenchmarkDefinition[] = (() => {
  const entries: BenchmarkDefinition[] = [];
  let order = 0;

  function add(
    name: string,
    category: string,
    description: string,
    scoringType: BenchmarkScoringType,
    enhancements?: BenchmarkEnhancements
  ): void {
    entries.push(makeBenchmark(name, category, description, scoringType, order++, enhancements));
  }

  // Sundee Fundee Exclusives
  add("Vanessa", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "Buy-in: 5 Triple Unders. 5 rounds for time: 5 Heavy Cleans (205/155 lb), 25 Double-Unders, 25 Toes-to-Bar. Cash-out: 5 Triple Unders.", "time", {
    intensity: 5,
    movementTags: ["Heavy Pull", "High Skill", "Gymnastics"],
    equipment: ["barbell", "jump rope", "pull-up bar"],
    timeDomain: "15-25 min",
    coachNotes: "Scale cleans to 185/135 lb if heavy cleans aren't in your wheelhouse. Triple unders are the buy-in/cash-out — if you can't do them, sub 15 double-unders each. Focus on smooth transitions between cleans and the jump rope. Break toes-to-bar early (7-8s) to save grip for the cleans.",
  });
  add("Eliz", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "5 rounds for time (25 min cap): 500m Row, 30 Crossovers (each side = 1), 100ft Farmers Carry (70/50 lb), 5 Overhead Squats (115/85 lb)", "time", {
    intensity: 4,
    movementTags: ["Cardio", "Core", "Overhead Stability"],
    equipment: ["rower", "dumbbells", "barbell"],
    timeDomain: "20-25 min",
    coachNotes: "Pace the row at 85% — don't sprint it. Crossovers are sneaky grip-intensive; stay smooth. Farmers carry is active recovery, use it to breathe. OHS should be unbroken for 2-3 rounds; if you're breaking, consider scaling weight. Core fatigue is real by round 4.",
  });
  add("Adria", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "For time (15 min cap): 3 rounds of 10 Sandbag Cleans (100/75 lb), 15 Sandbag Squats (100/75 lb). Then max distance Farmers Carry (70/50 lb).", "time", {
    intensity: 4,
    movementTags: ["Sandbag", "Grip", "Posterior Chain"],
    equipment: ["sandbag", "dumbbells"],
    timeDomain: "10-15 min",
    coachNotes: "Sandbag cleans are squat cleans — catch in the bottom and stand. Keep your chest up on squats; the bag will try to pull you forward. The farmers carry is for max distance, so don't rush the drop. Go until the grip fails, not until it gets uncomfortable.",
  });
  add("Kelsey", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "3 rounds for time (20 min cap): 50 Double-Unders, 10 Handstand Push-ups, 15 Hang Power Cleans (135/95 lb), 10 Chest-to-Bar Pull-ups", "time", {
    intensity: 5,
    movementTags: ["High Volume", "Push/Pull", "Cardio"],
    equipment: ["jump rope", "wall", "barbell", "pull-up bar"],
    timeDomain: "15-20 min",
    coachNotes: "50 DUs is a lot — if you're not efficient, consider scaling to 35. HSPU should be unbroken round 1, then small sets. Hang power cleans at 135/95 get heavy fast; consider quick singles from round 2 onward. C2B pull-ups: break early if your cleans are slow.",
  });
  add("Margarita", BENCHMARK_CATEGORY_SUNDEE_FUNDEE, "20-min benchmark: Part 1 AMRAP 5 min (10 Burpees, 15 KB Swings), Part 2 1RM Squat Clean, Part 3 AMRAP 5 min (10 Burpees, 15 Russian KB Swings), Part 4 1RM Snatch", "time", {
    intensity: 5,
    movementTags: ["Hybrid", "Max Effort", "Cardio"],
    equipment: ["kettlebell", "barbell", "plates"],
    timeDomain: "20 min fixed",
    coachNotes: "This is a unique hybrid benchmark — cardio AND max strength. Part 1: push the pace but leave 1-2 reps in the tank for the clean. Part 2: You have 5 min to find a 1RM squat clean — take 2-3 attempts max. Part 3: Russian swings are easier than American, so move fast. Part 4: Snatch under fatigue is dangerous — only attempt weights you're confident in. Score each part separately.",
  });

  // Classic WODs — Time
  add("Fran", BENCHMARK_CATEGORY_CLASSIC_WODS, "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups", "time", {
    intensity: 5,
    movementTags: ["Sprint", "Push/Pull"],
    equipment: ["barbell", "pull-up bar"],
    timeDomain: "2-8 min",
    coachNotes: "The original sprint benchmark. Go unbroken if possible. If you break the thrusters, you've gone too heavy. Pull-ups should be fast — kip hard. This should hurt from minute 1.",
  });
  add("Helen", BENCHMARK_CATEGORY_CLASSIC_WODS, "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups", "time", {
    intensity: 4,
    movementTags: ["Cardio", "Posterior Chain"],
    equipment: ["kettlebell", "pull-up bar", "running space"],
    timeDomain: "8-14 min",
    coachNotes: "Pace the run at 80% — you need energy for the swings and pull-ups. KB swings should be unbroken all rounds. Break pull-ups 6-6 or 5-4-3 if needed.",
  });
  add("Grace", BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 30 Clean & Jerks (135/95 lb)", "time", {
    intensity: 4,
    movementTags: ["Heavy Push", "Barbell Cycling"],
    equipment: ["barbell"],
    timeDomain: "2-8 min",
    coachNotes: "Sprint pace. If you can go unbroken, do it. Otherwise, quick singles with no rest between reps. Power clean + push jerk is the standard. Full squat clean + split jerk is fine if that's your preference.",
  });
  add("Karen", BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)", "time", {
    intensity: 3,
    movementTags: ["High Volume", "Squat", "Cardio"],
    equipment: ["wall ball"],
    timeDomain: "8-15 min",
    coachNotes: "Pacing is key. Start with sets of 25-30 and hold on. If you break, rest no more than 5-10 seconds. Keep the ball moving — catching and throwing should be one fluid motion.",
  });
  add("DT", BENCHMARK_CATEGORY_CLASSIC_WODS, "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)", "time", {
    intensity: 5,
    movementTags: ["Heavy Pull", "Barbell Complex"],
    equipment: ["barbell"],
    timeDomain: "8-15 min",
    coachNotes: "Touch-and-go on deadlifts is huge. Hang cleans should be quick — if you're struggling, drop to singles. Push jerks: keep the bar moving. This is a grip and shoulder endurance test.",
  });
  add("Murph", BENCHMARK_CATEGORY_CLASSIC_WODS, "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.", "time", {
    intensity: 5,
    movementTags: ["Endurance", "High Volume", "Hero WOD"],
    equipment: ["pull-up bar", "vest (optional)"],
    timeDomain: "35-60+ min",
    coachNotes: "Partition as 20 rounds of 5-10-15 (Cindy style) for better pacing. Without vest is still a legit attempt. The first run sets the tone — don't sprint it. Break push-ups early and often.",
  });
  add("Annie", BENCHMARK_CATEGORY_CLASSIC_WODS, "50-40-30-20-10 reps for time: Double-Unders, Sit-ups", "time", {
    intensity: 3,
    movementTags: ["Skill", "Core"],
    equipment: ["jump rope"],
    timeDomain: "6-12 min",
    coachNotes: "If double-unders are inconsistent, this becomes a 15+ minute workout. Sub triple-unders for a challenge or tuck jumps if you don't have a rope. Sit-ups should be fast — anchor your feet if you can.",
  });

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
