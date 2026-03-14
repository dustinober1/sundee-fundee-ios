/**
 * WODTemplateType
 * Ported from SundeeFundee/Domain/WODTemplateType.swift
 *
 * Workout-of-the-day template categories.
 * Pure type + pure helper functions.
 */

// ---------------------------------------------------------------------------
// WODTemplateType — string union matching Swift enum
// ---------------------------------------------------------------------------

export type WODTemplateType = 'strength' | 'amrap' | 'emom' | 'forTime' | 'circuit';

// ---------------------------------------------------------------------------
// Pure functions
// ---------------------------------------------------------------------------

/**
 * Parse a raw string value to a WODTemplateType.
 * Defaults to 'strength' for unknown values.
 * Matches Swift WODTemplateType.from(_:).
 */
export function wodTemplateTypeFrom(rawValue: string): WODTemplateType {
  switch (rawValue) {
    case 'strength': return 'strength';
    case 'amrap': return 'amrap';
    case 'emom': return 'emom';
    case 'forTime': return 'forTime';
    case 'circuit': return 'circuit';
    default: return 'strength';
  }
}

/**
 * Human-readable display name.
 * Matches Swift WODTemplateType.displayName computed property.
 */
export function wodTemplateTypeDisplayName(type: WODTemplateType): string {
  switch (type) {
    case 'strength': return 'Strength';
    case 'amrap': return 'AMRAP';
    case 'emom': return 'EMOM';
    case 'forTime': return 'For Time';
    case 'circuit': return 'Circuit';
  }
}

/**
 * Whether this template type requires an active timer during the workout.
 * Matches Swift WODTemplateType.requiresTimer computed property.
 */
export function wodTemplateTypeRequiresTimer(type: WODTemplateType): boolean {
  switch (type) {
    case 'amrap':
    case 'emom':
    case 'forTime':
      return true;
    case 'strength':
    case 'circuit':
      return false;
  }
}
