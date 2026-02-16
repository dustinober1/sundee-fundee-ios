import type { ProgramCategory } from '@/types/program';

export interface ExerciseMetadata {
  id: string;
  name: string;
  category: ProgramCategory;
  muscleGroups: string[];
  description: string;
}

export const EXERCISES: ExerciseMetadata[] = [
  {
    id: 'back-squat',
    name: 'Back Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Barbell squat with bar on upper back',
  },
  {
    id: 'front-squat',
    name: 'Front Squat',
    category: 'front-squat',
    muscleGroups: ['quadriceps', 'core', 'upper-back'],
    description: 'Barbell squat with front rack position',
  },
  {
    id: 'pause-squat',
    name: 'Pause Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Back squat with a 2-3 second pause at the bottom',
  },
  {
    id: 'zombie-squat',
    name: 'Zombie Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'core', 'upper-back'],
    description: 'Front squat with arms extended forward, teaches upright torso',
  },
  {
    id: 'zercher-squat',
    name: 'Zercher Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core', 'biceps'],
    description: 'Squat with bar held in crook of elbows',
  },
  {
    id: 'bulgarian-split-squat',
    name: 'Bulgarian Split Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Single-leg squat with rear foot elevated on bench',
  },
  {
    id: 'front-rack-hold',
    name: 'Front Rack Hold',
    category: 'back-squat',
    muscleGroups: ['core', 'upper-back', 'shoulders'],
    description: 'Isometric hold in front rack position, time-based',
  },
];

export function getExerciseByName(id: string): ExerciseMetadata | undefined {
  return EXERCISES.find(exercise => exercise.id === id);
}
