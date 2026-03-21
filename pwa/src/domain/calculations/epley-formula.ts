/**
 * Epley 1RM Formula
 * Ported from SundeeFundee/Domain/Calculations/WeightCalculations.swift (EpleyFormula enum)
 *
 * Formula: weight × (1 + reps / 30)
 * Only valid for reps > 1. For reps == 1, the lift itself is the 1RM.
 */

/**
 * Estimates 1-rep max from a submaximal lift.
 *
 * @param weight - Weight lifted in any unit
 * @param reps   - Number of repetitions performed
 * @returns      - Estimated 1RM in the same unit as weight
 */
export function estimated1RM(weight: number, reps: number): number {
  if (reps <= 1) return weight;
  return weight * (1.0 + reps / 30.0);
}

/**
 * Returns true if the new estimated 1RM is a personal record vs the stored max.
 *
 * @param newEstimate - Newly computed estimated 1RM
 * @param currentMax  - Previously stored maximum (undefined = no prior record)
 * @returns           - true if this is a PR
 */
export function isPR(newEstimate: number, currentMax: number | undefined): boolean {
  if (currentMax === undefined) return true;
  return newEstimate > currentMax;
}
