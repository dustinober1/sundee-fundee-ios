import backSquatComplete from './back-squat-complete-cycle.json';
import benchPressStrength from './bench-press-strength.json';
import boxJumpPower from './box-jump-power.json';
import burpeesConditioning from './burpees-conditioning.json';
import deadlift5x5 from './deadlift-5x5.json';
import frontSquatVolume from './front-squat-volume.json';
import type { Program } from '../../types/program';
import type { ProgramV2 } from '../../types/programV2';

export type ProgramDefinition = Program | ProgramV2;

const programs: ProgramDefinition[] = [
  backSquatComplete as ProgramV2,
  benchPressStrength as Program,
  boxJumpPower as Program,
  burpeesConditioning as Program,
  deadlift5x5 as Program,
  frontSquatVolume as Program,
];

export function getAllPrograms(): ProgramDefinition[] {
  return programs;
}

export function getProgramById(id: string): ProgramDefinition | undefined {
  return programs.find(p => p.id === id);
}

export function getProgramsByCategory(category: string): ProgramDefinition[] {
  return programs.filter(p => p.category === category);
}
