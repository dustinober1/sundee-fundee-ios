'use client';

import React, { createContext, useContext, useMemo } from 'react';
import { getAllPrograms, getProgramById } from '@/data/programs';
import { calculateTargetWeight } from '@/lib/calculations';
import type { Program, Week, Day, Exercise as ProgramExercise } from '@/types';

interface ExerciseContextValue {
  programs: Program[];
  getProgram: (id: string) => Program | undefined;
  getWeek: (programId: string, weekNumber: number) => Week | undefined;
  getDay: (programId: string, weekNumber: number, dayNumber: number) => Day | undefined;
  calculatePrescribedWeight: (exercise: ProgramExercise, oneRepMax: number) => number;
}

const ExerciseContext = createContext<ExerciseContextValue | undefined>(undefined);

export function ExerciseProvider({ children }: { children: React.ReactNode }) {
  const programs = useMemo(() => getAllPrograms(), []);

  function getProgram(id: string): Program | undefined {
    return getProgramById(id);
  }

  function getWeek(programId: string, weekNumber: number): Week | undefined {
    const program = getProgram(programId);
    return program?.weeks.find(w => w.week === weekNumber);
  }

  function getDay(programId: string, weekNumber: number, dayNumber: number): Day | undefined {
    const week = getWeek(programId, weekNumber);
    return week?.days.find(d => d.day === dayNumber);
  }

  function calculatePrescribedWeight(exercise: ProgramExercise, oneRepMax: number): number {
    return calculateTargetWeight(oneRepMax, exercise.percent1RM);
  }

  return (
    <ExerciseContext.Provider value={{
      programs,
      getProgram,
      getWeek,
      getDay,
      calculatePrescribedWeight
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
