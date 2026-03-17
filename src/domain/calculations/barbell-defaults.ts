/**
 * Barbell Defaults
 * Ported from SundeeFundee/Domain/Calculations/BarbellDefaults.swift
 *
 * Provides standard barbell preset definitions and exercise-based preset suggestion logic.
 */

import type { Gender } from '../types';
import { POUNDS_PER_KG } from './weight-unit-conversion';

// ---------------------------------------------------------------------------
// Preset definition
// ---------------------------------------------------------------------------

export interface BarbellPreset {
  name: string;
  weightKg: number;
  sortOrder: number;
}

/** Built-in barbell presets matching Swift BarbellDefaults.builtInPresets */
export const barbellPresets: readonly BarbellPreset[] = [
  { name: 'Standard', weightKg: 45.0 / POUNDS_PER_KG, sortOrder: 0 },
  { name: "Women's", weightKg: 35.0 / POUNDS_PER_KG, sortOrder: 1 },
  { name: 'Training', weightKg: 33.0 / POUNDS_PER_KG, sortOrder: 2 },
  { name: 'EZ Curl', weightKg: 15.0 / POUNDS_PER_KG, sortOrder: 3 },
];

// ---------------------------------------------------------------------------
// Exercise-based preset suggestion
// ---------------------------------------------------------------------------

const EZ_CURL_KEYWORDS = ['curl', 'tricep extension', 'skull crush'];
const COMPOUND_KEYWORDS = [
  'squat',
  'bench press',
  'deadlift',
  'overhead press',
  'ohp',
  'barbell row',
  'bent over row',
  'front squat',
  'incline press',
];

/**
 * Suggest the appropriate barbell preset for a given exercise and optional gender.
 * Matches Swift BarbellDefaults.suggestedPresetName.
 *
 * @param exerciseName - Name of the exercise (case-insensitive)
 * @param gender       - User's gender (undefined = unknown)
 * @returns            - Preset name string
 */
export function suggestedPresetName(exerciseName: string, gender: Gender | undefined): string {
  const lower = exerciseName.toLowerCase();

  if (EZ_CURL_KEYWORDS.some((kw) => lower.includes(kw))) {
    return 'EZ Curl';
  }

  if (COMPOUND_KEYWORDS.some((kw) => lower.includes(kw))) {
    return gender === 'female' ? "Women's" : 'Standard';
  }

  return 'Standard';
}
