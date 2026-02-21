import backSquatComplete from './back-squat-complete-cycle.json';
import type { ProgramV2 } from '@/types/programV2';

const programs: ProgramV2[] = [
  backSquatComplete as ProgramV2,
];

export function getAllPrograms(): ProgramV2[] {
  return programs;
}

export function getProgramById(id: string): ProgramV2 | undefined {
  return programs.find(p => p.id === id);
}

export function getProgramsByCategory(category: string): ProgramV2[] {
  return programs.filter(p => p.category === category);
}
