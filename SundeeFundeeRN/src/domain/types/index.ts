// =============================================================================
// Shared Domain Types
// Pure TypeScript interfaces and unions — no framework dependencies.
// All types match Swift domain function signatures exactly.
// =============================================================================

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

/** Weight unit system */
export type WeightUnit = 'lb' | 'kg';

/** Cycle phase per menstrual cycle model */
export type CyclePhase = 'menstrual' | 'follicular' | 'ovulation' | 'luteal';

/** Five-phase recovery arc for injury adaptation */
export type RecoveryPhase = 'acute' | 'rehab' | 'lightLoad' | 'returnToPlay' | 'resolved';

/** Ordered recovery phases (acute → resolved) */
export const RECOVERY_PHASE_ORDER: RecoveryPhase[] = [
  'acute',
  'rehab',
  'lightLoad',
  'returnToPlay',
  'resolved',
];

/** Body region for injury location */
export type BodyLocation =
  | 'head'
  | 'neck'
  | 'leftShoulder'
  | 'rightShoulder'
  | 'chest'
  | 'upperBack'
  | 'lowerBack'
  | 'leftElbow'
  | 'rightElbow'
  | 'leftWrist'
  | 'rightWrist'
  | 'leftHip'
  | 'rightHip'
  | 'leftKnee'
  | 'rightKnee'
  | 'leftAnkle'
  | 'rightAnkle';

/** Engine contraindication key derived from body location */
export type BodyLocationEngineKey = 'back' | 'shoulder' | 'wrist' | 'hip' | 'knee' | 'ankle';

/** Map a BodyLocation to its engine contraindication key */
export function bodyLocationEngineKey(location: BodyLocation): BodyLocationEngineKey {
  switch (location) {
    case 'head':
    case 'neck':
    case 'upperBack':
    case 'lowerBack':
      return 'back';
    case 'leftShoulder':
    case 'rightShoulder':
    case 'chest':
      return 'shoulder';
    case 'leftElbow':
    case 'rightElbow':
    case 'leftWrist':
    case 'rightWrist':
      return 'wrist';
    case 'leftHip':
    case 'rightHip':
      return 'hip';
    case 'leftKnee':
    case 'rightKnee':
      return 'knee';
    case 'leftAnkle':
    case 'rightAnkle':
      return 'ankle';
  }
}

/** User biological sex (for bar weight defaults and cycle features) */
export type Gender = 'female' | 'male' | 'other';

/** Workout focus category */
export type WorkoutFocus = 'strength' | 'hypertrophy' | 'endurance' | 'power' | 'mobility';

/** Subjective energy level */
export type EnergyLevel = 'low' | 'moderate' | 'high';

/** Available gym equipment */
export type EquipmentAccess = 'full' | 'limited' | 'home' | 'none';

/** Adaptation readiness tier derived from readiness survey */
export type ReadinessTier = 'low' | 'neutral' | 'high';

// ---------------------------------------------------------------------------
// Benchmark types
// ---------------------------------------------------------------------------

export type BenchmarkScoringType = 'forTime' | 'amrap' | 'maxLoad' | 'roundsAndReps';

export interface BenchmarkDefinition {
  id: string;
  name: string;
  description: string;
  scoringType: BenchmarkScoringType;
  category?: string;
}

// ---------------------------------------------------------------------------
// Exercise value — discriminated union matching Swift ExerciseValue
// ---------------------------------------------------------------------------

export type ExerciseValue =
  | { kind: 'fixed'; value: number }
  | { kind: 'range'; lo: number; hi: number }
  | { kind: 'amrap' }
  | { kind: 'text'; value: string };

/**
 * Scale an ExerciseValue by a multiplier (used by cycle and injury engines).
 * Text and amrap values pass through unchanged.
 */
export function scaleExerciseValue(ev: ExerciseValue, factor: number): ExerciseValue {
  switch (ev.kind) {
    case 'fixed':
      return { kind: 'fixed', value: swiftRound(ev.value * factor) };
    case 'range':
      return {
        kind: 'range',
        lo: swiftRound(ev.lo * factor),
        hi: swiftRound(ev.hi * factor),
      };
    case 'amrap':
      return ev;
    case 'text':
      return ev;
  }
}

// ---------------------------------------------------------------------------
// Period / Cycle
// ---------------------------------------------------------------------------

export interface PeriodLog {
  startDate: Date;
  endDate?: Date;
}

export interface CycleSettings {
  averageCycleLengthDays: number;
  averagePeriodLengthDays: number;
  lutealPhaseLengthDays: number;
}

// ---------------------------------------------------------------------------
// Injury / Pain
// ---------------------------------------------------------------------------

export interface InjuryProfile {
  id: string;
  bodyLocation: BodyLocation;
  recoveryPhase: RecoveryPhase;
  injuryDate: Date;
  notes?: string;
}

export interface PainLog {
  date: Date;
  painLevel: number;
  injuryId: string;
}

// ---------------------------------------------------------------------------
// Program / Session / Exercise
// ---------------------------------------------------------------------------

export interface ProgramExercise {
  id: string;
  name: string;
  sets: number;
  reps: ExerciseValue;
  weight?: ExerciseValue;
  restSeconds?: number;
  contrindicatedFor?: BodyLocationEngineKey[];
}

export interface ProgramSession {
  id: string;
  name: string;
  exercises: ProgramExercise[];
  focusArea?: WorkoutFocus;
}

export interface Program {
  id: string;
  name: string;
  sessions: ProgramSession[];
}

// ---------------------------------------------------------------------------
// Workout template types (OfflineWorkoutGenerator)
// ---------------------------------------------------------------------------

export interface WorkoutTemplate {
  id: string;
  name: string;
  exercises: ProgramExercise[];
  estimatedDurationMinutes?: number;
}

// ---------------------------------------------------------------------------
// Utility functions (parity-critical, shared across domain)
// ---------------------------------------------------------------------------

/**
 * Clamp a value to [min, max].
 */
export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/**
 * Swift-parity rounding: rounds to nearest integer using "round half away from zero"
 * (same behaviour as Swift's `.rounded()` / Foundation `round()`).
 * JavaScript `Math.round` rounds half up (toward +∞), which differs for negative halves.
 * For all positive values used in weight calculations both are equivalent.
 */
export function swiftRound(value: number): number {
  return Math.sign(value) * Math.round(Math.abs(value));
}
