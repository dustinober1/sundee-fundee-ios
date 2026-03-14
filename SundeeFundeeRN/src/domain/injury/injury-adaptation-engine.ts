/**
 * injury-adaptation-engine.ts
 * Adapts a Program for active injury profiles.
 * Pure value semantics — never mutates inputs, returns new instances.
 * Ported from Swift InjuryAdaptationEngine.swift (356 lines).
 */

import { RecoveryPhase, InjuryProfile, Program, ProgramSession, ProgramExercise, ExerciseValue, RECOVERY_PHASE_ORDER } from '../types';
import { getLoadMultipliers, adjustExerciseValue, adjustLoad } from './load-adjustment-policy';

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

export interface AdaptationResult {
  program: Program;
  /** Maps replacement exercise name → original exercise name. */
  adaptedExercises: Record<string, string>;
}

// ---------------------------------------------------------------------------
// Contraindication tables (ported from Swift)
// ---------------------------------------------------------------------------

interface ContraindicationRule {
  categories: string[];
  muscleGroupKeywords: string[];
}

const contraindicationRules: Record<string, ContraindicationRule> = {
  knee:     { categories: ['Squat Variations'], muscleGroupKeywords: ['quads'] },
  shoulder: { categories: ['Overhead Pressing', 'Bench Press Variations'], muscleGroupKeywords: ['shoulders'] },
  back:     { categories: ['Hinge Variations', 'Deadlift Variations'], muscleGroupKeywords: ['back'] },
  spine:    { categories: ['Hinge Variations', 'Deadlift Variations'], muscleGroupKeywords: ['back'] },
  hip:      { categories: [], muscleGroupKeywords: ['glutes', 'hamstrings'] },
  wrist:    { categories: ['Olympic Weightlifting'], muscleGroupKeywords: [] },
};

const regressionTable: Record<string, string[]> = {
  // Squat variations
  'Back Squat':                          ['Goblet Squat', 'Box Squat', 'Wall Ball Thrusters', 'Air Squats'],
  'Front Squat':                         ['Goblet Squat', 'Safety Bar Squat', 'Air Squats'],
  'Walking Lunges':                      ['Stationary Lunges', 'Step-Ups', 'Wall Ball Thrusters'],
  // Hip hinge
  'Romanian Deadlift (No Straps)':       ['Nordic Curl', 'Glute Bridge', 'Hip Thrust', 'Cable Pull-Through'],
  'Romanian Deadlift (With Straps)':     ['Nordic Curl', 'Glute Bridge', 'Hip Thrust', 'Cable Pull-Through'],
  'Conventional Deadlift (No Straps)':   ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Conventional Deadlift (With Straps)': ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Sumo Deadlift (No Straps)':           ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Sumo Deadlift (With Straps)':         ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Trap Bar Deadlift (No Straps)':       ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Trap Bar Deadlift (With Straps)':     ['Romanian Deadlift (No Straps)', 'Trap Bar Deadlift (No Straps)', 'Kettlebell Deadlift'],
  'Good Morning':                        ['Cat-Cow', 'Bird-Dogs', 'Seated Good Morning'],
  // Machine / accessory
  'Wall Ball Thrusters':                 ['Goblet Squat', 'Air Squats', 'Step-Ups'],
  'Banded Leg Curls':                    ['Nordic Curl', 'Glute Bridge', 'Swiss Ball Leg Curl'],
  'Plated Calf Step Up':                 ['Seated Calf Raise', 'Single-Leg Calf Raise'],
  // Olympic Weightlifting
  'Squat Snatch':                        ['Power Snatch', 'Hang Snatch', 'Overhead Squat'],
  'Squat Clean':                         ['Power Clean', 'Hang Clean', 'Front Squat'],
  'Power Clean':                         ['Hang Clean', 'Kettlebell Deadlift', 'Hip Thrust'],
  'Power Snatch':                        ['Hang Snatch', 'Kettlebell Deadlift', 'Hip Thrust'],
  'Hang Clean':                          ['Kettlebell Deadlift', 'Hip Thrust', 'Cable Pull-Through'],
  'Hang Snatch':                         ['Kettlebell Deadlift', 'Hip Thrust', 'Cable Pull-Through'],
  'Split Jerk':                          ['Push Press', 'Push Jerk', 'Strict Press'],
  'Push Jerk':                           ['Push Press', 'Strict Press', 'Dumbbell Overhead Press'],
  'Clean and Jerk':                      ['Power Clean', 'Push Press', 'Front Squat'],
  // Upper body press
  'Flat Barbell Bench Press':            ['Dumbbell Bench Press', 'Floor Press', 'Push-Ups'],
  'Strict Press / Military Press':       ['Lateral Raises', 'Z-Press', 'Seated Dumbbell Press'],
  // Upper body pull
  'Pull-Up':                             ['Lat Pulldown', 'Band-Assisted Pull-Up', 'TRX Row'],
  'Barbell Row':                         ['Dumbbell Row', 'Cable Row', 'TRX Row'],
};

const recoveryPrepMap: Record<string, string[]> = {
  knee:     ['Bird-Dogs', 'Bodyweight Lunges', 'Terminal Knee Extension', 'Straight Leg Raises'],
  shoulder: ['Banded Pull-Aparts', 'Face Pulls', 'Wall Slides', 'Shoulder Circles'],
  back:     ['Cat-Cow', 'Bird-Dogs', 'Dead Bug', 'Pelvic Tilts'],
  spine:    ['Cat-Cow', 'Bird-Dogs', 'Dead Bug', 'McGill Curl-Up'],
  hip:      ['Hip Circles', 'Glute Bridges', 'Clamshells', '90/90 Hip Stretch'],
  ankle:    ['Ankle Circles', 'Calf Raises (Partial)', 'Towel Toe Curls'],
  wrist:    ['Wrist Circles', 'Prayer Stretch', 'Reverse Wrist Curl'],
};

const safeBodyweight = ['Air Squats', 'Bird-Dogs', 'Bodyweight Lunges'];

const contraindicatedExerciseKeywords: Record<string, string[]> = {
  knee:     ['squat', 'lunge', 'leg press', 'step-up'],
  shoulder: ['press', 'bench', 'overhead', 'clean', 'snatch', 'jerk'],
  back:     ['deadlift', 'good morning', 'hinge', 'row'],
  spine:    ['deadlift', 'good morning', 'hinge', 'row'],
  hip:      ['deadlift', 'hinge', 'lunge', 'hip thrust'],
  wrist:    ['clean', 'snatch', 'jerk'],
};

// Clinical synonym normalization (matches Swift clinicalSynonyms)
const clinicalSynonyms: Record<string, string> = {
  acl: 'knee', mcl: 'knee', pcl: 'knee', meniscus: 'knee',
  patella: 'knee', patellar: 'knee', quad: 'knee', quadriceps: 'knee',
  'rotator cuff': 'shoulder', labrum: 'shoulder', deltoid: 'shoulder',
  supraspinatus: 'shoulder', infraspinatus: 'shoulder', 'bicep tendon': 'shoulder',
  lumbar: 'back', 'lower back': 'back', 'upper back': 'back',
  thoracic: 'back', cervical: 'back', disc: 'back', herniated: 'back',
  sciatica: 'back', spinal: 'spine', vertebra: 'spine', vertebrae: 'spine',
  sacroiliac: 'hip', 'si joint': 'hip', groin: 'hip', labral: 'hip',
  'hip flexor': 'hip', piriformis: 'hip',
  achilles: 'ankle', plantar: 'ankle', calf: 'ankle',
  carpal: 'wrist', 'carpal tunnel': 'wrist', forearm: 'wrist',
};

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Returns the same program unchanged if no active (non-resolved) injuries exist.
 * Adapts sessions by replacing/removing contraindicated exercises.
 * Matches Swift InjuryAdaptationEngine.adaptProgram(_:activeInjuries:).
 */
export function adaptProgram(program: Program, activeInjuries: InjuryProfile[]): Program {
  const nonResolved = activeInjuries.filter(i => i.recoveryPhase !== 'resolved');
  if (nonResolved.length === 0) return program;

  const adaptedSessions = program.sessions.map(s => adaptSession(s, nonResolved));
  return { ...program, sessions: adaptedSessions };
}

/**
 * Adapts a program and returns metadata identifying which exercises were substituted.
 */
export function adaptProgramWithMetadata(
  program: Program,
  activeInjuries: InjuryProfile[],
): AdaptationResult {
  const nonResolved = activeInjuries.filter(i => i.recoveryPhase !== 'resolved');
  if (nonResolved.length === 0) {
    return { program, adaptedExercises: {} };
  }

  const metadata: Record<string, string> = {};
  const adaptedSessions = program.sessions.map(session => {
    const adapted = adaptSession(session, nonResolved);
    session.exercises.forEach((original, idx) => {
      const replacement = adapted.exercises[idx];
      if (replacement && original.name !== replacement.name) {
        metadata[replacement.name] = original.name;
      }
    });
    return adapted;
  });

  return { program: { ...program, sessions: adaptedSessions }, adaptedExercises: metadata };
}

/**
 * Returns the most restrictive (earliest) recovery phase from a list.
 * Uses RECOVERY_PHASE_ORDER.indexOf for comparison — matching Swift min(by:).
 * Returns undefined for empty input.
 */
export function mostRestrictive(phases: RecoveryPhase[]): RecoveryPhase | undefined {
  if (phases.length === 0) return undefined;
  return phases.reduce((a, b) =>
    RECOVERY_PHASE_ORDER.indexOf(a) <= RECOVERY_PHASE_ORDER.indexOf(b) ? a : b
  );
}

/**
 * Maps free-text injury locations to engine contraindication keys
 * using clinical synonym matching.
 */
export function normalizedBodyRegions(injuries: InjuryProfile[]): string[] {
  const regions = new Set<string>();
  const knownKeys = new Set(Object.keys(contraindicationRules));

  for (const injury of injuries) {
    const loc = (injury.location ?? injury.bodyLocation).toLowerCase();

    // Direct match against known engine keys
    for (const key of knownKeys) {
      if (loc.includes(key)) regions.add(key);
    }

    // Clinical synonym matching
    for (const [synonym, region] of Object.entries(clinicalSynonyms)) {
      if (loc.includes(synonym)) regions.add(region);
    }
  }

  return Array.from(regions);
}

/**
 * Returns a list of recovery prep exercises for all active injuries.
 * Matches Swift InjuryAdaptationEngine.buildRecoveryPrepBlock(injuries:).
 */
export function buildRecoveryPrepBlock(injuries: InjuryProfile[]): ProgramExercise[] {
  const seen = new Set<string>();
  const block: ProgramExercise[] = [];

  for (const injury of injuries) {
    const loc = (injury.location ?? injury.bodyLocation).toLowerCase();
    for (const [key, exercises] of Object.entries(recoveryPrepMap)) {
      if (!loc.includes(key)) continue;
      for (const ex of exercises) {
        if (seen.has(ex)) continue;
        seen.add(ex);
        block.push({
          id: ex,
          name: ex,
          sets: 2,
          reps: { kind: 'fixed', value: 10 },
          restSeconds: 60,
          bodyweightOnly: true,
        } as ProgramExercise & { bodyweightOnly: boolean });
      }
    }
  }

  return block;
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

function applyMultipliers(exercise: ProgramExercise, phase: RecoveryPhase): ProgramExercise {
  const m = getLoadMultipliers(phase);
  if (m.load >= 1.0 && m.sets >= 1.0 && m.reps >= 1.0) return exercise;
  const newReps = adjustExerciseValue(exercise.reps, m.reps);
  const newWeight = exercise.weight ? adjustExerciseValue(exercise.weight, m.load) : undefined;
  const newSets = Math.max(1, swiftRoundInt(exercise.sets * m.sets));
  return { ...exercise, sets: newSets, reps: newReps, weight: newWeight };
}

function swiftRoundInt(value: number): number {
  return Math.sign(value) * Math.round(Math.abs(value));
}

function adaptSession(session: ProgramSession, injuries: InjuryProfile[]): ProgramSession {
  const acuteInjuries = injuries.filter(i => i.recoveryPhase === 'acute');
  const rehabInjuries = injuries.filter(i => i.recoveryPhase === 'rehab');
  const lightLoadInjuries = injuries.filter(i => i.recoveryPhase === 'lightLoad');
  const returnToPlayInjuries = injuries.filter(i => i.recoveryPhase === 'returnToPlay');

  // Acute + rehab + lightLoad: replace contraindicated exercises
  const replacementInjuries = [...acuteInjuries, ...rehabInjuries, ...lightLoadInjuries];
  let adaptedExercises = session.exercises.map(ex => adaptExercise(ex, replacementInjuries));

  // Apply load/volume multipliers for the most restrictive phase
  const restrictivePhase = mostRestrictive(injuries.map(i => i.recoveryPhase));
  if (restrictivePhase && restrictivePhase !== 'resolved') {
    adaptedExercises = adaptedExercises.map(ex => applyMultipliers(ex, restrictivePhase));
  }

  let finalExercises = adaptedExercises;

  // Rehab: prepend full recovery prep block
  if (rehabInjuries.length > 0) {
    const prepBlock = buildRecoveryPrepBlock(rehabInjuries);
    finalExercises = [...prepBlock, ...finalExercises];
  }

  // returnToPlay: no replacement, but prepend recovery prep as warmup
  if (returnToPlayInjuries.length > 0) {
    const warmupBlock = buildRecoveryPrepBlock(returnToPlayInjuries);
    finalExercises = [...warmupBlock, ...finalExercises];
  }

  return { ...session, exercises: finalExercises };
}

function adaptExercise(exercise: ProgramExercise, injuries: InjuryProfile[]): ProgramExercise {
  if (!isContraindicated(exercise.name, injuries)) return exercise;
  const replacement = findReplacement(exercise.name, injuries);
  return { ...exercise, id: replacement.name, name: replacement.name };
}

function isContraindicated(exerciseName: string, injuries: InjuryProfile[]): boolean {
  const lower = exerciseName.toLowerCase();
  for (const injury of injuries) {
    const loc = (injury.location ?? injury.bodyLocation).toLowerCase();
    for (const [key, rule] of Object.entries(contraindicationRules)) {
      if (!loc.includes(key)) continue;
      for (const keyword of rule.muscleGroupKeywords) {
        if (lower.includes(keyword)) return true;
      }
      for (const cat of rule.categories) {
        if (lower.includes(cat.toLowerCase())) return true;
      }
      const keywords = contraindicatedExerciseKeywords[key];
      if (keywords) {
        for (const keyword of keywords) {
          if (lower.includes(keyword)) return true;
        }
      }
    }
  }
  return false;
}

function findReplacement(
  exerciseName: string,
  injuries: InjuryProfile[],
): { name: string; reason: string } {
  const locations = injuries.map(i => i.location ?? i.bodyLocation).join(', ');

  const regressions = regressionTable[exerciseName];
  if (regressions) {
    for (const candidate of regressions) {
      if (!isContraindicated(candidate, injuries)) {
        return {
          name: candidate,
          reason: `Replaced due to ${locations} injury. Using ${candidate}.`,
        };
      }
    }
  }

  for (const safe of safeBodyweight) {
    if (!isContraindicated(safe, injuries)) {
      return {
        name: safe,
        reason: `Replaced due to ${locations} injury. Using ${safe}.`,
      };
    }
  }

  /* istanbul ignore next — unreachable in practice: Bird-Dogs is always safe */
  return {
    name: exerciseName,
    reason: `Consult your coach — no safe automatic replacement found for ${locations} injury.`,
  };
}
