export type TemplateType = 'strength' | 'amrap' | 'emom' | 'forTime' | 'circuit';
export type WODStatus = 'draft' | 'published';

export interface ProgramExercise {
  exercise: string;
  variant?: string | null;
  sets: number;
  reps: number | string;
  percent1RM?: number | null;
  restMinutes?: number | null;
  notes?: string | null;
  bodyweightOnly: boolean;
}

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  templateType: TemplateType;
  publishDate: string;
  status: WODStatus;
  exercises: ProgramExercise[];
}

export interface WODFormData {
  date: string;
  title: string;
  description: string;
  templateType: TemplateType;
  publishDate: string;
  status: WODStatus;
  exercises: ProgramExercise[];
  timeCap?: number;
  interval?: number;
  rounds?: number;
}
