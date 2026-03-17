/**
 * Weight Calculations
 * Ported from SundeeFundee/Domain/Calculations/WeightCalculations.swift
 *
 * All functions are pure (no mutation of inputs).
 * Uses undefined (not null) for absent values.
 */

import type { WeightUnit } from '../types';

// ---------------------------------------------------------------------------
// Equipment inventories
// ---------------------------------------------------------------------------

/** Available dumbbell weights in pounds (standard gym inventory) */
export const AVAILABLE_DUMBBELL_WEIGHTS_LB: readonly number[] = [10, 15, 20, 25, 35, 40, 50, 70];

/** Available kettlebell weights in pounds */
export const AVAILABLE_KETTLEBELL_WEIGHTS_LB: readonly number[] = [15, 25, 32, 53, 70];

// ---------------------------------------------------------------------------
// Rounding helpers
// ---------------------------------------------------------------------------

/**
 * Round a value to the nearest multiple of 5.
 * Uses Swift-parity rounding (round half away from zero).
 */
export function roundToNearestFive(value: number): number {
  return Math.round(value / 5.0) * 5.0;
}

// ---------------------------------------------------------------------------
// Barbell weight snapping
// ---------------------------------------------------------------------------

/**
 * Snap a barbell total to the nearest loadable weight in pounds.
 * Plate load moves in 2.5 lb increments per side (5 lb total steps).
 *
 * @param lb    - Target weight in pounds
 * @param barLb - Bar weight in pounds (default: 45 for men's bar)
 */
export function snapBarbellWeightLb(lb: number, barLb = 45.0): number {
  const plateLoadLb = Math.max(0, lb - barLb);
  const snappedPlateLoad = Math.round(plateLoadLb / 5.0) * 5.0;
  return barLb + snappedPlateLoad;
}

/**
 * Snap a barbell total to the nearest loadable weight in kilograms.
 * Plate load moves in 2.5 kg increments per side (5 kg total steps).
 *
 * @param kg    - Target weight in kilograms
 * @param barKg - Bar weight in kilograms (default: ~20.41 kg, 45 lb standard bar)
 */
export function snapBarbellWeightKg(kg: number, barKg = 45.0 / 2.2046226218): number {
  const plateLoadKg = Math.max(0, kg - barKg);
  const snappedPlateLoad = Math.round(plateLoadKg / 5.0) * 5.0;
  return barKg + snappedPlateLoad;
}

// ---------------------------------------------------------------------------
// Dumbbell / Kettlebell snapping
// ---------------------------------------------------------------------------

/**
 * Snap a weight in lb to the nearest available dumbbell weight.
 */
export function snapDumbbellWeightLb(lb: number): number {
  return (
    AVAILABLE_DUMBBELL_WEIGHTS_LB.reduce((best, w) =>
      Math.abs(w - lb) < Math.abs(best - lb) ? w : best
    ) ?? lb
  );
}

/**
 * Snap a weight in lb to the nearest available kettlebell weight.
 */
export function snapKettlebellWeightLb(lb: number): number {
  return (
    AVAILABLE_KETTLEBELL_WEIGHTS_LB.reduce((best, w) =>
      Math.abs(w - lb) < Math.abs(best - lb) ? w : best
    ) ?? lb
  );
}

// ---------------------------------------------------------------------------
// Target weight calculation
// ---------------------------------------------------------------------------

/**
 * Calculate target weight as a percentage of 1RM, rounded to nearest 5.
 */
export function calculateTargetWeight(oneRepMax: number, percentage: number): number {
  return roundToNearestFive(oneRepMax * percentage);
}

// ---------------------------------------------------------------------------
// Progress utilities
// ---------------------------------------------------------------------------

/**
 * Returns true if the given weight exceeds the previous max.
 * Note: named isPersonalRecord (not isPR) to avoid conflict with epley-formula export.
 */
export function isPersonalRecord(weight: number, previousMax: number): boolean {
  return weight > previousMax;
}

/**
 * Calculate total volume load for a set/rep/weight combination.
 */
export function calculateVolumeLoad(weight: number, reps: number, sets: number): number {
  return weight * reps * sets;
}

/**
 * Returns true if the last 3 weights in the array differ by less than 5 (plateau signal).
 */
export function detectPlateau(weights: number[]): boolean {
  if (weights.length < 3) return false;
  const last3 = weights.slice(-3);
  const maxVal = Math.max(...last3);
  const minVal = Math.min(...last3);
  return maxVal - minVal < 5;
}

// Re-export WeightUnit for convenience
export type { WeightUnit };
