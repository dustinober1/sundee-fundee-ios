import backSquat5x5Linear from './back-squat-5x5-linear.json';
import type { Program } from '@/types';

const programs: Program[] = [
  backSquat5x5Linear as Program,
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
