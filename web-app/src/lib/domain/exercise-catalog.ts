import type { ConditioningScoringType } from "./types";

// ---------------------------------------------------------------------------
// Weightlifting Exercise Catalog
// ---------------------------------------------------------------------------

export type WeightliftingCategory =
  | "Squat"
  | "Hip Hinge"
  | "Press"
  | "Pull"
  | "Carry"
  | "Olympic Weightlifting";

export interface WeightliftingEntry {
  id: string;
  category: WeightliftingCategory;
}

export const WEIGHTLIFTING_EXERCISES: WeightliftingEntry[] = [
  // Squat
  { id: "Back Squat",            category: "Squat" },
  { id: "Front Squat",           category: "Squat" },
  { id: "Safety Bar Squat",      category: "Squat" },
  { id: "Box Squat",             category: "Squat" },
  { id: "Pause Squat",           category: "Squat" },
  { id: "Goblet Squat",          category: "Squat" },
  // Hip Hinge
  { id: "Conventional Deadlift (No Straps)",   category: "Hip Hinge" },
  { id: "Conventional Deadlift (With Straps)", category: "Hip Hinge" },
  { id: "Romanian Deadlift (No Straps)",       category: "Hip Hinge" },
  { id: "Romanian Deadlift (With Straps)",     category: "Hip Hinge" },
  { id: "Sumo Deadlift (No Straps)",           category: "Hip Hinge" },
  { id: "Sumo Deadlift (With Straps)",         category: "Hip Hinge" },
  { id: "Trap Bar Deadlift (No Straps)",       category: "Hip Hinge" },
  { id: "Trap Bar Deadlift (With Straps)",     category: "Hip Hinge" },
  { id: "Good Morning",          category: "Hip Hinge" },
  { id: "Hip Thrust",            category: "Hip Hinge" },
  // Press
  { id: "Flat Barbell Bench Press",    category: "Press" },
  { id: "Incline Barbell Bench Press", category: "Press" },
  { id: "Strict Press",                category: "Press" },
  { id: "Push Press",                  category: "Press" },
  { id: "Dumbbell Bench Press",        category: "Press" },
  { id: "Dumbbell Overhead Press",     category: "Press" },
  // Pull
  { id: "Barbell Row",       category: "Pull" },
  { id: "Pendlay Row",       category: "Pull" },
  { id: "Pull-Up",           category: "Pull" },
  { id: "Weighted Pull-Up",  category: "Pull" },
  { id: "Lat Pulldown",      category: "Pull" },
  { id: "Cable Row",         category: "Pull" },
  // Carry
  { id: "Farmers Carry",   category: "Carry" },
  { id: "Suitcase Carry",  category: "Carry" },
  // Olympic Weightlifting
  { id: "Squat Snatch",    category: "Olympic Weightlifting" },
  { id: "Squat Clean",     category: "Olympic Weightlifting" },
  { id: "Power Clean",     category: "Olympic Weightlifting" },
  { id: "Power Snatch",    category: "Olympic Weightlifting" },
  { id: "Hang Clean",      category: "Olympic Weightlifting" },
  { id: "Hang Snatch",     category: "Olympic Weightlifting" },
  { id: "Split Jerk",      category: "Olympic Weightlifting" },
  { id: "Push Jerk",       category: "Olympic Weightlifting" },
  { id: "Clean and Jerk",  category: "Olympic Weightlifting" },
];

const _weightliftingIDs = new Set(WEIGHTLIFTING_EXERCISES.map((e) => e.id));

export function isWeightliftingExercise(id: string): boolean {
  return _weightliftingIDs.has(id);
}

// ---------------------------------------------------------------------------
// Conditioning Exercise Catalog
// ---------------------------------------------------------------------------

export interface ConditioningEntry {
  id: string;
  defaultScoringType: ConditioningScoringType;
}

export const CONDITIONING_EXERCISES: ConditioningEntry[] = [
  // Reps-based
  { id: "Wall Ball",               defaultScoringType: "reps" },
  { id: "Box Jump",                defaultScoringType: "reps" },
  { id: "Burpee",                  defaultScoringType: "reps" },
  { id: "Kettlebell Swing",        defaultScoringType: "reps" },
  { id: "Double Under",            defaultScoringType: "reps" },
  { id: "Pull-Up (Kipping)",       defaultScoringType: "reps" },
  { id: "Toes-to-Bar",             defaultScoringType: "reps" },
  { id: "Muscle-Up",               defaultScoringType: "reps" },
  { id: "Push-Up",                 defaultScoringType: "reps" },
  { id: "Sit-Up",                  defaultScoringType: "reps" },
  { id: "Air Squat",               defaultScoringType: "reps" },
  { id: "Thruster",                defaultScoringType: "reps" },
  { id: "Rowing (Calories)",       defaultScoringType: "reps" },
  { id: "Assault Bike (Calories)", defaultScoringType: "reps" },
  // Time-based
  { id: "400m Run",        defaultScoringType: "time" },
  { id: "800m Run",        defaultScoringType: "time" },
  { id: "1-Mile Run",      defaultScoringType: "time" },
  { id: "5K Run",          defaultScoringType: "time" },
  { id: "500m Row",        defaultScoringType: "time" },
  { id: "2K Row",          defaultScoringType: "time" },
  { id: "1K Assault Bike", defaultScoringType: "time" },
];

const _conditioningMap = new Map(
  CONDITIONING_EXERCISES.map((e) => [e.id, e.defaultScoringType])
);

export function isConditioningExercise(id: string): boolean {
  return _conditioningMap.has(id);
}

export function conditioningScoringType(
  id: string
): ConditioningScoringType | undefined {
  return _conditioningMap.get(id);
}

/**
 * Formats a conditioning value for display.
 * - time:  value in seconds → "M:SS"
 * - reps:  count → "N reps" (singular: "1 rep")
 */
export function formatConditioningValue(
  value: number,
  type: ConditioningScoringType
): string {
  if (type === "time") {
    const totalSeconds = Math.floor(value);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${String(seconds).padStart(2, "0")}`;
  }
  const count = Math.floor(value);
  return count === 1 ? "1 rep" : `${count} reps`;
}

/**
 * Returns true when `newValue` is a better score than `existingValue`.
 * If `existingValue` is undefined the new score is always better.
 * - time: lower is better
 * - reps: higher is better
 */
export function isBetterConditioningScore(
  newValue: number,
  existingValue: number | undefined,
  type: ConditioningScoringType
): boolean {
  if (existingValue === undefined) return true;
  return type === "time" ? newValue < existingValue : newValue > existingValue;
}
