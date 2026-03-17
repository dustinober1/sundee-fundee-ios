/**
 * Calculations subdomain barrel export.
 * Re-exports all public functions and constants from the calculations subdomain.
 */

export { estimated1RM, isPR } from './epley-formula';

export {
  AVAILABLE_DUMBBELL_WEIGHTS_LB,
  AVAILABLE_KETTLEBELL_WEIGHTS_LB,
  roundToNearestFive,
  snapBarbellWeightLb,
  snapBarbellWeightKg,
  snapDumbbellWeightLb,
  snapKettlebellWeightLb,
  calculateTargetWeight,
  isPersonalRecord,
  calculateVolumeLoad,
  detectPlateau,
} from './weight-calculations';

export {
  POUNDS_PER_KG,
  lbToKg,
  kgToLb,
  valueFromKilograms,
  kilogramsFrom,
} from './weight-unit-conversion';

export {
  STANDARD_BAR_LB,
  WOMEN_BAR_LB,
  STANDARD_BAR_KG,
  WOMEN_BAR_KG,
  AVAILABLE_PLATES_LB,
  AVAILABLE_PLATES_KG,
  platesPerSideLb,
  platesPerSideKg,
} from './plate-calculation';

export type { PlateCount } from './plate-calculation';

export { barbellPresets, suggestedPresetName } from './barbell-defaults';

export type { BarbellPreset } from './barbell-defaults';
