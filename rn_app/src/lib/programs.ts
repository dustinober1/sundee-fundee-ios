import type { Program } from '../types/program';
import type {
  ExerciseV2,
  ProgramV2,
  Session as SessionV2,
  WeekV2,
} from '../types/programV2';
import type { ProgramDefinition } from '../data/programs';

export interface NormalizedExercise {
  exercise: string;
  sets: number;
  reps: number;
  percent1RM: number;
  restMinutes: number;
}

export interface NormalizedSession {
  sessionId: string;
  sessionName: string;
  sessionType: 'support' | 'anchor' | 'testing';
  focus: string;
  exercises: NormalizedExercise[];
}

export interface NormalizedWeek {
  week: number;
  sessions: NormalizedSession[];
}

export interface NormalizedProgram {
  id: string;
  name: string;
  category: Program['category'];
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: Program['difficulty'];
  weeks: NormalizedWeek[];
}

function normalizeReps(reps: ExerciseV2['reps']): number {
  if (typeof reps === 'number') return reps;
  if (reps === 'AMRAP') return 1;
  if (Array.isArray(reps) && reps.length > 0) return reps[0];
  return 1;
}

function normalizeSets(sets: ExerciseV2['sets']): number {
  if (typeof sets === 'number') return sets;
  return 1;
}

function normalizeExerciseV2(exercise: ExerciseV2): NormalizedExercise {
  return {
    exercise: exercise.exercise,
    sets: normalizeSets(exercise.sets),
    reps: normalizeReps(exercise.reps),
    percent1RM: exercise.percent1RM,
    restMinutes: exercise.restMinutes ?? 3,
  };
}

function normalizeSessionV2(session: SessionV2): NormalizedSession {
  return {
    sessionId: session.sessionId,
    sessionName: session.sessionName,
    sessionType: session.sessionType,
    focus: session.focus,
    exercises: session.exercises.map(normalizeExerciseV2),
  };
}

function normalizeWeekV2(week: WeekV2): NormalizedWeek {
  return {
    week: week.week,
    sessions: week.sessions.map(normalizeSessionV2),
  };
}

function isProgramV2(program: ProgramDefinition): program is ProgramV2 {
  return 'sessionsPerWeek' in program && 'phases' in program;
}

function normalizeProgramV1(program: Program): NormalizedProgram {
  return {
    id: program.id,
    name: program.name,
    category: program.category,
    description: program.description,
    durationWeeks: program.durationWeeks,
    sessionsPerWeek: program.daysPerWeek,
    difficulty: program.difficulty,
    weeks: program.weeks.map(week => ({
      week: week.week,
      sessions: week.days.map(day => ({
        sessionId: `w${week.week}-d${day.day}`,
        sessionName: `Week ${week.week} · Day ${day.day}`,
        sessionType: 'support',
        focus: 'Standard training session',
        exercises: day.exercises.map(exercise => ({
          exercise: exercise.exercise,
          sets: exercise.sets,
          reps: exercise.reps,
          percent1RM: exercise.percent1RM,
          restMinutes: exercise.restMinutes ?? 3,
        })),
      })),
    })),
  };
}

function normalizeProgramV2(program: ProgramV2): NormalizedProgram {
  return {
    id: program.id,
    name: program.name,
    category: program.category,
    description: program.description,
    durationWeeks: program.durationWeeks,
    sessionsPerWeek: program.sessionsPerWeek,
    difficulty: program.difficulty,
    weeks: program.weeks.map(normalizeWeekV2),
  };
}

export function normalizeProgram(program: ProgramDefinition): NormalizedProgram {
  if (isProgramV2(program)) {
    return normalizeProgramV2(program);
  }
  return normalizeProgramV1(program);
}
