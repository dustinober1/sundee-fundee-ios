/**
 * CelebrationEvent
 * Ported from SundeeFundee/Domain/CelebrationEvent.swift
 *
 * Types for PR and achievement celebration events.
 * Pure types + pure display functions — no framework dependencies.
 *
 * Note: formatWithUnit display helpers produce simplified output here
 * (locale-dependent formatting belongs in the UI layer per architecture pattern).
 */

import type { BenchmarkScoringType } from '../types';

// ---------------------------------------------------------------------------
// CelebrationEvent — discriminated union matching Swift enum
// ---------------------------------------------------------------------------

export type CelebrationEvent =
  | { kind: 'workoutCompleted'; durationSeconds: number }
  | { kind: 'newPersonalRecord'; exerciseName: string; weightKg: number }
  | { kind: 'programCompleted'; programName: string }
  | { kind: 'weightMilestone'; exerciseName: string; thresholdKg: number }
  | { kind: 'newConditioningPR'; exerciseName: string; value: number; scoringType: BenchmarkScoringType };

// ---------------------------------------------------------------------------
// Pure display functions (formerly computed properties in Swift)
// ---------------------------------------------------------------------------

/**
 * Title string for the celebration event.
 * Matches Swift CelebrationEvent.title computed property.
 */
export function getCelebrationTitle(event: CelebrationEvent): string {
  switch (event.kind) {
    case 'workoutCompleted':
      return 'Workout Complete!';
    case 'newPersonalRecord':
      return 'New Personal Record!';
    case 'programCompleted':
      return 'Program Complete!';
    case 'weightMilestone':
      return 'Weight Milestone!';
    case 'newConditioningPR':
      return 'New Conditioning PR!';
  }
}

/**
 * Format a conditioning scoring value to a display string.
 * Matches Swift ConditioningScoringType.formatValue(_:).
 */
function formatConditioningValue(value: number, scoringType: BenchmarkScoringType): string {
  switch (scoringType) {
    case 'time': {
      const totalSeconds = Math.round(value);
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    }
    case 'reps':
      return `${Math.round(value)} reps`;
    case 'weight':
      return `${value.toFixed(1)} kg`;
    case 'distance':
      return `${Math.round(value)}m`;
    case 'roundsAndReps': {
      const rounds = Math.floor(value / 10000);
      const reps = value % 10000;
      return `${rounds} rounds + ${reps} reps`;
    }
  }
}

/**
 * Subtitle string for the celebration event.
 * Matches Swift CelebrationEvent.subtitle(unit:) method.
 */
export function getCelebrationSubtitle(event: CelebrationEvent): string {
  switch (event.kind) {
    case 'workoutCompleted': {
      const minutes = Math.floor(event.durationSeconds / 60);
      return minutes > 0 ? `Completed in ${minutes} min` : 'Workout saved!';
    }
    case 'newPersonalRecord': {
      const kgStr = `${event.weightKg.toFixed(1)} kg`;
      return `${event.exerciseName} — ${kgStr} estimated 1RM`;
    }
    case 'programCompleted':
      return `You finished ${event.programName}. Time to level up!`;
    case 'weightMilestone': {
      const kgStr = `${Math.round(event.thresholdKg)} kg`;
      return `${event.exerciseName} hit ${kgStr}!`;
    }
    case 'newConditioningPR':
      return `${event.exerciseName} — ${formatConditioningValue(event.value, event.scoringType)}`;
  }
}
