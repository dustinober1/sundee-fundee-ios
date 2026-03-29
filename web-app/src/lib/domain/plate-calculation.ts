export const STANDARD_BARBELL_KG = 20;
export const WOMENS_BARBELL_KG = 15;
export const AVAILABLE_PLATES = [25, 20, 15, 10, 5, 2.5, 1.25];

export interface PlateCount {
  weight: number;
  count: number;
}

/**
 * Returns the plates needed per side to reach the target total weight.
 * Uses a greedy algorithm with the standard plate sizes.
 *
 * @param totalWeightKg  The desired total barbell weight in kg.
 * @param barbellWeightKg  The weight of the barbell itself.
 * @returns Array of { weight, count } for each plate denomination used (per side).
 */
export function platesPerSide(totalWeightKg: number, barbellWeightKg: number): PlateCount[] {
  const perSide = (totalWeightKg - barbellWeightKg) / 2;
  if (perSide <= 0) return [];

  const result: PlateCount[] = [];
  let remaining = perSide;

  for (const plate of AVAILABLE_PLATES) {
    if (remaining <= 0) break;
    const count = Math.floor(remaining / plate);
    if (count > 0) {
      result.push({ weight: plate, count });
      remaining -= count * plate;
      // Prevent floating point drift
      remaining = Math.round(remaining * 1000) / 1000;
    }
  }

  return result;
}

/**
 * Returns a human-readable description of the plates needed per side.
 * Example: "2×20 + 1×5 + 1×2.5 per side"
 */
export function plateDescription(totalWeightKg: number, barbellWeightKg: number): string {
  const plates = platesPerSide(totalWeightKg, barbellWeightKg);
  if (plates.length === 0) return "Barbell only";
  const parts = plates.map((p) => `${p.count}\u00d7${p.weight}`);
  return `${parts.join(" + ")} per side`;
}
