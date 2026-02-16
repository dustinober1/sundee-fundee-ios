'use client';

import React, { createContext, useContext, useMemo } from 'react';
import { getAllPrograms, getProgramById } from '@/data/programs';
import { calculateTargetWeight } from '@/lib/calculations';
import type { Day } from '@/types/program';
import type { ExerciseV2, Phase, ProgramV2, Session, WeekV2 } from '@/types/programV2';

interface ExerciseContextValue {
  programs: ProgramV2[];
  getProgram: (id: string) => ProgramV2 | undefined;
  getWeek: (programId: string, weekNumber: number) => WeekV2 | undefined;
  getDay: (programId: string, weekNumber: number, dayNumber: number) => Day | undefined;
  calculatePrescribedWeight: (exercise: Pick<ExerciseV2, 'percent1RM'>, oneRepMax: number) => number;
  getSession: (programId: string, weekNumber: number, sessionId: string) => Session | undefined;
  getPhaseForWeek: (programId: string, weekNumber: number) => Phase | undefined;
  getPhaseProgress: (programId: string, currentWeek: number, phaseId: string) => number;
}

const ExerciseContext = createContext<ExerciseContextValue | undefined>(undefined);

export function ExerciseProvider({ children }: { children: React.ReactNode }) {
  const programs = useMemo(() => getAllPrograms(), []);

  function getProgram(id: string): ProgramV2 | undefined {
    return getProgramById(id);
  }

  function getWeek(programId: string, weekNumber: number): WeekV2 | undefined {
    const program = getProgram(programId);
    return program?.weeks.find(w => w.week === weekNumber);
  }

  function getDay(programId: string, weekNumber: number, dayNumber: number): Day | undefined {
    const week = getWeek(programId, weekNumber);
    const legacyDays = (week as unknown as { days?: Day[] } | undefined)?.days;
    return legacyDays?.find(day => day.day === dayNumber);
  }

  function getSession(programId: string, weekNumber: number, sessionId: string): Session | undefined {
    const week = getWeek(programId, weekNumber);
    return week?.sessions.find(session => session.sessionId === sessionId);
  }

  function getPhaseForWeek(programId: string, weekNumber: number): Phase | undefined {
    const program = getProgram(programId);
    return program?.phases.find(phase => {
      const [start, end] = phase.weekRange;
      return weekNumber >= start && weekNumber <= end;
    });
  }

  function getPhaseProgress(programId: string, currentWeek: number, phaseId: string): number {
    const program = getProgram(programId);
    if (!program || !phaseId) {
      return 0;
    }

    const phase = program.phases.find(value => value.id === phaseId);
    if (!phase) {
      return 0;
    }

    const [startWeek, endWeek] = phase.weekRange;
    const totalWeeks = endWeek - startWeek + 1;

    if (currentWeek < startWeek) {
      return 0;
    }
    if (currentWeek > endWeek) {
      return 100;
    }

    const weeksCompleted = currentWeek - startWeek + 1;
    return Math.round((weeksCompleted / totalWeeks) * 100);
  }

  function calculatePrescribedWeight(exercise: Pick<ExerciseV2, 'percent1RM'>, oneRepMax: number): number {
    return calculateTargetWeight(oneRepMax, exercise.percent1RM);
  }

  return (
    <ExerciseContext.Provider value={{
      programs,
      getProgram,
      getWeek,
      getDay,
      calculatePrescribedWeight,
      getSession,
      getPhaseForWeek,
      getPhaseProgress
    }}>
      {children}
    </ExerciseContext.Provider>
  );
}

export function useExercise() {
  const context = useContext(ExerciseContext);
  if (!context) {
    throw new Error('useExercise must be used within ExerciseProvider');
  }
  return context;
}
