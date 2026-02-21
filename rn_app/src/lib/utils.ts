/**
 * Round to nearest 5 (e.g., 123 -> 125)
 */
export function roundToNearestFive(n: number): number {
  return Math.round(n / 5) * 5;
}
