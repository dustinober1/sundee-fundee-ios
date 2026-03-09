/**
 * Port of SundeeFundeeShared/Validation/ProgramValidator.swift
 */

import { ProgramFormData, ProgramExercise, ExerciseValue } from '@/types/program';

export interface ProgramValidationError {
  field: string;
  message: string;
}

const SLUG_REGEX = /^[a-z0-9]+(-[a-z0-9]+)*$/;

function getPercent1RM(exercise: ProgramExercise): number | null {
  return exercise.percent1RM ?? null;
}

export function validateProgram(program: ProgramFormData): ProgramValidationError[] {
  const errors: ProgramValidationError[] = [];

  if (!program.name.trim()) {
    errors.push({ field: 'name', message: 'Name is required' });
  }

  if (!program.id.trim()) {
    errors.push({ field: 'id', message: 'ID is required' });
  } else if (!SLUG_REGEX.test(program.id)) {
    errors.push({ field: 'id', message: 'ID must be a valid slug (lowercase, hyphens only)' });
  }

  if (program.durationWeeks !== program.weeks.length) {
    errors.push({
      field: 'durationWeeks',
      message: `Duration (${program.durationWeeks}) doesn't match week count (${program.weeks.length})`,
    });
  }

  const phaseIDs = new Set(program.phases.map((p) => p.id));

  for (let i = 0; i < program.weeks.length; i++) {
    const week = program.weeks[i];

    if (week.sessions.length === 0) {
      errors.push({ field: `weeks[${i}]`, message: `Week ${week.week} has no sessions` });
    }

    if (week.phaseId && !phaseIDs.has(week.phaseId)) {
      errors.push({
        field: `weeks[${i}].phaseId`,
        message: `Week ${week.week} references unknown phase '${week.phaseId}'`,
      });
    }

    for (let j = 0; j < week.sessions.length; j++) {
      const session = week.sessions[j];

      if (session.exercises.length === 0) {
        errors.push({
          field: `weeks[${i}].sessions[${j}]`,
          message: `Session '${session.sessionName}' has no exercises`,
        });
      }

      for (let k = 0; k < session.exercises.length; k++) {
        const exercise = session.exercises[k];

        if (!exercise.exercise.trim()) {
          errors.push({
            field: `weeks[${i}].sessions[${j}].exercises[${k}]`,
            message: 'Exercise name is empty',
          });
        }

        const pct = getPercent1RM(exercise);
        if (pct !== null && (pct < 0.0 || pct > 1.5)) {
          errors.push({
            field: `weeks[${i}].sessions[${j}].exercises[${k}].percent1RM`,
            message: `percent1RM ${pct} must be between 0.0 and 1.5`,
          });
        }
      }
    }
  }

  return errors;
}
