import { TemplateType, ProgramExercise } from '@/types/wod';
import { ALL_EXERCISES } from '@/data/exercise-catalog';

export interface ParsedWorkout {
  templateType: TemplateType;
  timeCap?: number;
  exercises: ParsedExercise[];
}

export interface ParsedExercise {
  exercise: string;
  variant?: string | null;
  sets: number;
  reps: number | string;
  percent1RM?: number | null;
  restMinutes?: number | null;
  notes?: string | null;
  bodyweightOnly: boolean;
}

// Common abbreviations mapped to full exercise names
const ABBREVIATIONS: Record<string, string> = {
  'rdl': 'Romanian Deadlift',
  'ohp': 'Overhead Press',
  'kb swing': 'Kettlebell Swing',
  'kb swings': 'Kettlebell Swing',
  'kb deadlift': 'Kettlebell Deadlift',
  'dl': 'Deadlift',
  'bp': 'Bench Press',
  'bs': 'Back Squat',
  'fs': 'Front Squat',
  'ohs': 'Overhead Squat',
  'hspu': 'Handstand Push-Up',
  'mu': 'Muscle-Up',
  'ttb': 'Toes-to-Bar',
  't2b': 'Toes-to-Bar',
  'c&j': 'Clean & Jerk',
  'du': 'Double Under',
  'dus': 'Double Under',
  'wb': 'Wall Ball',
  'pc': 'Power Clean',
  'ps': 'Power Snatch',
  'bj': 'Box Jump',
  'box jumps': 'Box Jump',
  'pull-ups': 'Pull-Up',
  'pullups': 'Pull-Up',
  'pull ups': 'Pull-Up',
  'push-ups': 'Push-Up',
  'pushups': 'Push-Up',
  'push ups': 'Push-Up',
  'burpees': 'Burpee',
  'sit-ups': 'Sit-Up',
  'situps': 'Sit-Up',
  'thrusters': 'Thruster',
  'cleans': 'Clean',
  'snatches': 'Snatch',
  'run': '400m Run',
};

const BODYWEIGHT_EXERCISES = new Set([
  'Push-Up', 'Burpee', 'Box Jump', 'Plank', 'Dip', 'Air Squat',
  'Sit-Up', 'Handstand Push-Up', 'Muscle-Up', 'Toes-to-Bar',
  'Pull-Up (Kipping)', 'Pull-Up', 'Bird-Dogs', 'Dead Bug', 'Cat-Cow',
  'Bodyweight Lunges', 'Clamshells', 'McGill Curl-Up', 'Double Under',
]);

/**
 * Detect the workout template type from the input text.
 */
function detectTemplateType(text: string): TemplateType {
  const upper = text.toUpperCase();
  if (/\bAMRAP\b/i.test(text)) return 'amrap';
  if (/\bEMOM\b/i.test(text)) return 'emom';
  if (/\bfor\s+time\b/i.test(text) || /\bft\b/i.test(upper)) return 'forTime';
  if (/\bcircuit\b/i.test(text) || /\bsuperset\b/i.test(text)) return 'circuit';
  return 'strength';
}

/**
 * Extract time cap in minutes from the text.
 */
function extractTimeCap(text: string): number | undefined {
  // "AMRAP 12 min", "AMRAP 12", "EMOM 20"
  const amrapEmom = text.match(/(?:AMRAP|EMOM)\s+(\d+)\s*(?:min(?:utes?)?)?/i);
  if (amrapEmom) return parseInt(amrapEmom[1], 10);

  // "12 min cap", "12 minute cap"
  const capMatch = text.match(/(\d+)\s*min(?:ute)?s?\s*cap/i);
  if (capMatch) return parseInt(capMatch[1], 10);

  return undefined;
}

/**
 * Fuzzy match an exercise name against the catalog.
 * Returns the best match or the original text if no match found.
 */
function matchExercise(raw: string): string {
  const trimmed = raw.trim();
  const lower = trimmed.toLowerCase();

  // Check abbreviations first
  for (const [abbr, full] of Object.entries(ABBREVIATIONS)) {
    if (lower === abbr) return full;
  }

  // Expand KB -> Kettlebell in the input for matching
  const expanded = trimmed.replace(/\bKB\b/gi, 'Kettlebell');

  // Exact match (case-insensitive)
  const exact = ALL_EXERCISES.find(e => e.toLowerCase() === expanded.toLowerCase());
  if (exact) return exact;

  // Partial match: catalog name contains the input or input contains the catalog name
  const partial = ALL_EXERCISES.find(e => e.toLowerCase().includes(expanded.toLowerCase()));
  if (partial) return partial;

  const reversePartial = ALL_EXERCISES.find(e => expanded.toLowerCase().includes(e.toLowerCase()));
  if (reversePartial) return reversePartial;

  // Return with title case if no match
  return trimmed.replace(/\b\w/g, c => c.toUpperCase());
}

/**
 * Parse a single exercise segment into a structured exercise.
 */
function parseExerciseSegment(segment: string): ParsedExercise | null {
  const trimmed = segment.trim();
  if (!trimmed) return null;

  let sets = 1;
  let reps: number | string = 1;
  let percent1RM: number | null = null;
  let exerciseText = trimmed;

  // Extract percent1RM: "75%", "60%"
  const percentMatch = exerciseText.match(/(\d+(?:\.\d+)?)\s*%/);
  if (percentMatch) {
    percent1RM = parseFloat(percentMatch[1]) / 100;
    exerciseText = exerciseText.replace(percentMatch[0], '').trim();
  }

  // Extract sets x reps: "5x5", "3x10", "3X12"
  const setsRepsMatch = exerciseText.match(/^(\d+)\s*[xX]\s*(\d+)\s*/);
  if (setsRepsMatch) {
    sets = parseInt(setsRepsMatch[1], 10);
    reps = parseInt(setsRepsMatch[2], 10);
    exerciseText = exerciseText.replace(setsRepsMatch[0], '').trim();
  } else {
    // Extract time-based reps: "3x60s", "3x30s"
    const setsTimeMatch = exerciseText.match(/^(\d+)\s*[xX]\s*(\d+s)\s*/);
    if (setsTimeMatch) {
      sets = parseInt(setsTimeMatch[1], 10);
      reps = setsTimeMatch[2];
      exerciseText = exerciseText.replace(setsTimeMatch[0], '').trim();
    } else {
      // Extract standalone reps: "10 KB swings"
      const repsMatch = exerciseText.match(/^(\d+)\s+/);
      if (repsMatch) {
        reps = parseInt(repsMatch[1], 10);
        exerciseText = exerciseText.replace(repsMatch[0], '').trim();
      }

      // Extract distance-based: "200m run"
      const distanceMatch = exerciseText.match(/^(\d+m)\s+/);
      if (distanceMatch) {
        reps = distanceMatch[1];
        exerciseText = exerciseText.replace(distanceMatch[0], '').trim();
      }
    }
  }

  if (!exerciseText) return null;

  const exercise = matchExercise(exerciseText);
  const bodyweightOnly = BODYWEIGHT_EXERCISES.has(exercise);

  return {
    exercise,
    sets,
    reps,
    percent1RM,
    bodyweightOnly,
  };
}

/**
 * Parse coach-speak workout text into structured WOD data.
 */
export function parseWorkoutText(text: string): ParsedWorkout {
  const templateType = detectTemplateType(text);
  const timeCap = extractTimeCap(text);

  // Remove the template prefix (e.g., "AMRAP 12 min:", "For time:", "EMOM 20:")
  let exerciseText = text
    .replace(/^AMRAP\s+\d+\s*(?:min(?:utes?)?)?\s*:?\s*/i, '')
    .replace(/^EMOM\s+\d+\s*(?:min(?:utes?)?)?\s*:?\s*/i, '')
    .replace(/^For\s+time\s*:?\s*/i, '')
    .replace(/^Circuit\s*:?\s*/i, '')
    .replace(/^Superset\s*:?\s*/i, '')
    .trim();

  // Split by comma, newline, or semicolon
  const segments = exerciseText.split(/[,;\n]+/);
  const exercises: ParsedExercise[] = [];

  for (const segment of segments) {
    const parsed = parseExerciseSegment(segment);
    if (parsed) {
      exercises.push(parsed);
    }
  }

  return {
    templateType,
    timeCap,
    exercises,
  };
}
