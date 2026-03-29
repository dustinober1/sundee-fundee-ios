import { WeightUnit } from "./types";

export const LB_PER_KG = 2.2046226218;

/**
 * Converts a value from kilograms to the given unit.
 */
export function fromKilograms(kg: number, unit: (typeof WeightUnit)[keyof typeof WeightUnit]): number {
  return unit === WeightUnit.pounds ? kg * LB_PER_KG : kg;
}

/**
 * Converts a value to kilograms from the given unit.
 */
export function toKilograms(value: number, unit: (typeof WeightUnit)[keyof typeof WeightUnit]): number {
  return unit === WeightUnit.pounds ? value / LB_PER_KG : value;
}

/**
 * Parses a string input and converts it to kilograms.
 * Returns null if the input is not a valid number.
 */
export function parseInputToKilograms(
  input: string,
  unit: (typeof WeightUnit)[keyof typeof WeightUnit]
): number | null {
  const trimmed = input.trim();
  const n = parseFloat(trimmed);
  if (isNaN(n)) return null;
  return toKilograms(n, unit);
}

/**
 * Formats a weight value with up to 1 decimal place.
 * Trims trailing ".0" for whole numbers.
 */
export function formatWeight(value: number): string {
  const rounded = Math.round(value * 10) / 10;
  return rounded % 1 === 0 ? String(rounded) : rounded.toFixed(1);
}

/**
 * Converts a kg value to the target unit and returns a formatted string with unit symbol.
 */
export function formatWeightWithUnit(
  kg: number,
  unit: (typeof WeightUnit)[keyof typeof WeightUnit]
): string {
  const converted = fromKilograms(kg, unit);
  return `${formatWeight(converted)} ${unit}`;
}
