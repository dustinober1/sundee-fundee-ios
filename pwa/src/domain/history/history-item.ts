/**
 * HistoryItem
 * Ported from SundeeFundee/Domain/History/HistoryItem.swift
 *
 * Unified type for displaying AI-generated and program-based workout records
 * in a single chronological history list.
 * Pure types + pure helper functions — no storage access.
 */

// ---------------------------------------------------------------------------
// HistoryItemSource — discriminated union matching Swift enum
// ---------------------------------------------------------------------------

export type HistoryItemSource =
  | { kind: 'aiWorkout' }
  | { kind: 'program'; name: string }
  | { kind: 'custom' };

// ---------------------------------------------------------------------------
// HistoryItem
// ---------------------------------------------------------------------------

export interface HistoryItem {
  id: string;
  title: string;
  source: HistoryItemSource;
  completedAt: Date;
  exerciseCount: number;
  durationSeconds: number;
  /** Original ID for deletion (not prefixed). */
  originalID: string;
  isAIWorkout: boolean;
  /** Total volume (sum of weight * reps across all sets) for this workout. */
  totalVolume?: number;
  /** Custom workout name, if user-named. */
  workoutName?: string;
}

// ---------------------------------------------------------------------------
// Pure helper functions
// ---------------------------------------------------------------------------

/**
 * Returns a human-readable source label.
 * Matches Swift HistoryItem.sourceLabel computed property.
 */
export function getSourceLabel(source: HistoryItemSource): string {
  switch (source.kind) {
    case 'aiWorkout':
      return 'AI Workout';
    case 'program':
      return source.name;
    case 'custom':
      return 'Custom Workout';
  }
}
