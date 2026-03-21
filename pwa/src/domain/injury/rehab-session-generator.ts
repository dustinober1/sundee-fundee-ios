/**
 * rehab-session-generator.ts
 * Generates standalone 10-15 minute recovery sessions for rest days.
 * Ported from Swift RehabSessionGenerator.swift (75 lines).
 */

import { InjuryProfile, ProgramSession, ProgramExercise, ExerciseValue } from '../types';
import type { RecoveryPhase } from '../types';

// ---------------------------------------------------------------------------
// Recovery exercise map (matches Swift RehabSessionGenerator.recoveryMap)
// ---------------------------------------------------------------------------

const recoveryMap: Record<string, string[]> = {
  knee:     ['Bird-Dogs', 'Bodyweight Lunges', 'Terminal Knee Extension', 'Straight Leg Raises'],
  shoulder: ['Banded Pull-Aparts', 'Face Pulls', 'Wall Slides', 'Shoulder Circles'],
  back:     ['Cat-Cow', 'Bird-Dogs', 'Dead Bug', 'Pelvic Tilts'],
  spine:    ['Cat-Cow', 'Bird-Dogs', 'Dead Bug', 'McGill Curl-Up'],
  hip:      ['Hip Circles', 'Glute Bridges', 'Clamshells', '90/90 Hip Stretch'],
  ankle:    ['Ankle Circles', 'Calf Raises (Partial)', 'Towel Toe Curls'],
  wrist:    ['Wrist Circles', 'Prayer Stretch', 'Reverse Wrist Curl'],
};

// ---------------------------------------------------------------------------
// Volume per phase (matches Swift RehabSessionGenerator.volumeForPhase)
// ---------------------------------------------------------------------------

interface PhaseVolume {
  sets: number;
  reps: ExerciseValue;
  notes: string;
}

function volumeForPhase(phase: RecoveryPhase): PhaseVolume {
  if (phase === 'lightLoad') {
    return { sets: 2, reps: { kind: 'fixed', value: 15 }, notes: 'Light load — slow tempo, full ROM' };
  }
  // Default: rehab (and any other phase that passes the filter)
  return { sets: 3, reps: { kind: 'fixed', value: 12 }, notes: 'Rehab — controlled tempo, focus on form' };
}

function recoveryExercises(location: string): string[] {
  const result: string[] = [];
  for (const [key, exercises] of Object.entries(recoveryMap)) {
    if (location.includes(key)) {
      result.push(...exercises);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Generates a rehab mini-session for the given injuries.
 * Returns null if no active injuries with rehab-appropriate phases exist.
 * Matches Swift RehabSessionGenerator.generateSession(injuries:).
 */
export function generateSession(injuries: InjuryProfile[]): ProgramSession | null {
  const rehabInjuries = injuries.filter(
    i => i.recoveryPhase === 'rehab' || i.recoveryPhase === 'lightLoad',
  );
  if (rehabInjuries.length === 0) return null;

  const seen = new Set<string>();
  const exercises: ProgramExercise[] = [];

  for (const injury of rehabInjuries) {
    const loc = (injury.location ?? injury.bodyLocation).toLowerCase();
    const prepExercises = recoveryExercises(loc);

    for (const ex of prepExercises) {
      if (seen.has(ex)) continue;
      seen.add(ex);
      const { sets, reps, notes } = volumeForPhase(injury.recoveryPhase);
      exercises.push({
        id: ex,
        name: ex,
        sets,
        reps,
        restSeconds: 30,
        bodyweightOnly: true,
      } as ProgramExercise & { bodyweightOnly: boolean; notes?: string });
    }
  }

  if (exercises.length === 0) return null;

  // Generate short UUID suffix matching Swift UUID().uuidString.prefix(8)
  const uuidSuffix = generateShortId();

  return {
    id: `rehab-${uuidSuffix}`,
    name: 'Rehab Session',
    exercises,
    focusArea: 'mobility',
  };
}

function generateShortId(): string {
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}
