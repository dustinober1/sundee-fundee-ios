/**
 * Weight Unit Conversion
 * Ported from SundeeFundee/Domain/Calculations/WeightUnitConversion.swift
 *
 * NOTE: Locale-dependent formatting is intentionally NOT ported here — that belongs
 * in the UI layer (per domain port research pitfall #5).
 */

import type { WeightUnit } from '../types';

/** Exact pounds-per-kilogram conversion constant, matching Swift source */
export const POUNDS_PER_KG = 2.2046226218;

/**
 * Convert pounds to kilograms.
 */
export function lbToKg(lb: number): number {
  return lb / POUNDS_PER_KG;
}

/**
 * Convert kilograms to pounds.
 */
export function kgToLb(kg: number): number {
  return kg * POUNDS_PER_KG;
}

/**
 * Convert a value in kilograms to the given unit.
 */
export function valueFromKilograms(kilograms: number, unit: WeightUnit): number {
  return unit === 'kg' ? kilograms : kgToLb(kilograms);
}

/**
 * Convert a value in the given unit to kilograms.
 */
export function kilogramsFrom(value: number, unit: WeightUnit): number {
  return unit === 'kg' ? value : lbToKg(value);
}
