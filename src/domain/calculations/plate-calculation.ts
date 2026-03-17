/**
 * Plate Calculation
 * Ported from SundeeFundee/Domain/Calculations/PlateCalculation.swift
 *
 * Calculates plates needed per side for a given total barbell weight.
 * Supports both lb and kg unit systems.
 */

import { POUNDS_PER_KG } from './weight-unit-conversion';

// ---------------------------------------------------------------------------
// Bar weight constants
// ---------------------------------------------------------------------------

/** Men's standard barbell: 45 lb */
export const STANDARD_BAR_LB = 45.0;
/** Women's barbell: 35 lb */
export const WOMEN_BAR_LB = 35.0;

/** Men's standard barbell in kg (~20.41 kg) */
export const STANDARD_BAR_KG = STANDARD_BAR_LB / POUNDS_PER_KG;
/** Women's barbell in kg (~15.88 kg) */
export const WOMEN_BAR_KG = WOMEN_BAR_LB / POUNDS_PER_KG;

// ---------------------------------------------------------------------------
// Available plate denominations
// ---------------------------------------------------------------------------

/** Standard lb plate denominations used in most gyms (largest first) */
export const AVAILABLE_PLATES_LB: readonly number[] = [45, 25, 15, 10, 5, 2.5];

/** Kg equivalents of the lb plate denominations */
export const AVAILABLE_PLATES_KG: readonly number[] = AVAILABLE_PLATES_LB.map(
  (p) => p / POUNDS_PER_KG
);

// ---------------------------------------------------------------------------
// Plate breakdown type
// ---------------------------------------------------------------------------

export interface PlateCount {
  weight: number;
  count: number;
}

// ---------------------------------------------------------------------------
// Core calculation
// ---------------------------------------------------------------------------

/**
 * Returns the plates needed per side for a given total barbell weight in pounds.
 *
 * @param totalLb - Total barbell weight in pounds
 * @param barLb   - Bar weight in pounds (default: 45)
 * @returns       - Array of { weight, count } pairs per side (largest plate first)
 */
export function platesPerSideLb(totalLb: number, barLb = STANDARD_BAR_LB): PlateCount[] {
  if (totalLb <= barLb) return [];
  let remaining = (totalLb - barLb) / 2.0;
  const breakdown: PlateCount[] = [];

  for (const plate of AVAILABLE_PLATES_LB) {
    if (remaining < plate - 0.01) continue;
    const count = Math.floor(remaining / plate);
    if (count > 0) {
      breakdown.push({ weight: plate, count });
      remaining -= count * plate;
    }
  }

  return breakdown;
}

/**
 * Returns the plates needed per side for a given total barbell weight in kilograms.
 * Uses kg-equivalent plate denominations.
 *
 * @param totalKg - Total barbell weight in kilograms
 * @param barKg   - Bar weight in kilograms (default: standard 45 lb bar in kg)
 * @returns       - Array of { weight, count } pairs per side (largest plate first)
 */
export function platesPerSideKg(totalKg: number, barKg = STANDARD_BAR_KG): PlateCount[] {
  if (totalKg <= barKg) return [];
  let remaining = (totalKg - barKg) / 2.0;
  const breakdown: PlateCount[] = [];

  for (const plate of AVAILABLE_PLATES_KG) {
    if (remaining < plate - 0.01) continue;
    const count = Math.floor(remaining / plate);
    if (count > 0) {
      breakdown.push({ weight: plate, count });
      remaining -= count * plate;
    }
  }

  return breakdown;
}
