/**
 * formatWeight — UI layer weight formatting utilities.
 *
 * Internal storage is always in pounds (lbs). These functions convert
 * to the user's preferred display unit for rendering and parse user
 * input back to the stored lbs value.
 *
 * Kg values are rounded to the nearest 0.5 kg for display — this matches
 * common gym plate increments in metric countries.
 *
 * All functions are pure — no React dependencies.
 */

import { lbToKg } from '@/src/domain/calculations/weight-unit-conversion';
import type { WeightUnit } from '@/src/domain/types';

/**
 * Round a kilogram value to the nearest 0.5 kg.
 * e.g. 61.235 → 61.5, 59.9 → 60.0
 */
function roundToHalfKg(kg: number): number {
  return Math.round(kg * 2) / 2;
}

/**
 * Convert stored lbs to a display string in the user's preferred unit.
 *
 * - lb: rounded to 1 decimal, suffix "lbs"
 * - kg: converted from lbs, rounded to nearest 0.5, suffix "kg"
 *
 * @param lbs - Weight stored in pounds
 * @param unit - User's preferred display unit
 * @returns Formatted string like "132.3 lbs" or "60.0 kg"
 */
export function formatWeight(lbs: number, unit: WeightUnit): string {
  if (unit === 'kg') {
    const kg = roundToHalfKg(lbToKg(lbs));
    return `${kg.toFixed(1)} kg`;
  }
  return `${lbs.toFixed(1)} lbs`;
}

/**
 * Convert stored lbs to a numeric value in the user's preferred unit.
 * Same conversion as formatWeight but returns a number instead of a string.
 * Useful for pre-populating numeric TextInput fields.
 *
 * @param lbs - Weight stored in pounds
 * @param unit - User's preferred display unit
 * @returns Numeric weight in the requested unit
 */
export function formatWeightNumeric(lbs: number, unit: WeightUnit): number {
  if (unit === 'kg') {
    return roundToHalfKg(lbToKg(lbs));
  }
  return Math.round(lbs * 10) / 10;
}

/**
 * Parse user-entered weight input in their preferred unit and return stored lbs.
 *
 * - lb: parse as-is
 * - kg: multiply by POUNDS_PER_KG to get lbs for storage
 * - Empty string: returns 0
 * - Non-numeric string: returns NaN
 *
 * @param value - Raw string from TextInput
 * @param unit - Unit the user typed in
 * @returns Weight in pounds for storage
 */
export function parseWeightInput(value: string, unit: WeightUnit): number {
  if (value.trim() === '') return 0;
  const parsed = parseFloat(value);
  if (isNaN(parsed)) return NaN;

  if (unit === 'kg') {
    // Import constant inline to avoid circular dep
    const POUNDS_PER_KG = 2.2046226218;
    return parsed * POUNDS_PER_KG;
  }
  return parsed;
}
