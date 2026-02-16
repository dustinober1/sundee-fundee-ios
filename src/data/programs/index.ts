import backSquat5x5Linear from './back-squat-5x5-linear.json';
import frontSquatVolume from './front-squat-volume.json';
import benchPressStrength from './bench-press-strength.json';
import deadlift5x5 from './deadlift-5x5.json';
import boxJumpPower from './box-jump-power.json';
import burpeesConditioning from './burpees-conditioning.json';
import type { Program } from '@/types';

const programs: Program[] = [
  backSquat5x5Linear as Program,
  frontSquatVolume as Program,
  benchPressStrength as Program,
  deadlift5x5 as Program,
  boxJumpPower as Program,
  burpeesConditioning as Program,
];

export function getAllPrograms(): Program[] {
  return programs;
}

export function getProgramById(id: string): Program | undefined {
  return programs.find(p => p.id === id);
}

export function getProgramsByCategory(category: string): Program[] {
  return programs.filter(p => p.category === category);
}
