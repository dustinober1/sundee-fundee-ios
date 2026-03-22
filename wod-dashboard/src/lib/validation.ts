import { WOD, Program } from "./types";

export interface ValidationError {
  field: string;
  message: string;
}

export function validateWOD(wod: WOD): ValidationError[] {
  const errors: ValidationError[] = [];
  if (!wod.id.trim()) errors.push({ field: "id", message: "ID is required" });
  if (!wod.title.trim()) errors.push({ field: "title", message: "Title is required" });
  if (!wod.date.trim()) {
    errors.push({ field: "date", message: "Date is required" });
  } else if (!/^\d{4}-\d{2}-\d{2}$/.test(wod.date)) {
    errors.push({ field: "date", message: "Date must be yyyy-MM-dd format" });
  }
  if (wod.exercises.length === 0) {
    errors.push({ field: "exercises", message: "At least one exercise is required" });
  }
  wod.exercises.forEach((ex, i) => {
    if (!ex.exercise.trim()) {
      errors.push({ field: `exercises[${i}]`, message: "Exercise name is empty" });
    }
  });
  return errors;
}

export function validateProgram(program: Program): ValidationError[] {
  const errors: ValidationError[] = [];
  if (!program.name.trim()) errors.push({ field: "name", message: "Name is required" });
  if (!program.id.trim()) {
    errors.push({ field: "id", message: "ID is required" });
  } else if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(program.id)) {
    errors.push({ field: "id", message: "ID must be a valid slug (lowercase, hyphens only)" });
  }
  if (program.durationWeeks !== program.weeks.length) {
    errors.push({ field: "durationWeeks", message: `Duration (${program.durationWeeks}) doesn't match week count (${program.weeks.length})` });
  }
  const phaseIDs = new Set(program.phases.map((p) => p.id));
  program.weeks.forEach((week, i) => {
    if (week.sessions.length === 0) {
      errors.push({ field: `weeks[${i}]`, message: `Week ${week.week} has no sessions` });
    }
    if (week.phaseId && !phaseIDs.has(week.phaseId)) {
      errors.push({ field: `weeks[${i}].phaseId`, message: `Week ${week.week} references unknown phase '${week.phaseId}'` });
    }
    week.sessions.forEach((session, j) => {
      if (session.exercises.length === 0) {
        errors.push({ field: `weeks[${i}].sessions[${j}]`, message: `Session '${session.sessionName}' has no exercises` });
      }
      session.exercises.forEach((ex, k) => {
        if (!ex.exercise.trim()) {
          errors.push({ field: `weeks[${i}].sessions[${j}].exercises[${k}]`, message: "Exercise name is empty" });
        }
        if (ex.percent1RM != null && (ex.percent1RM < 0.0 || ex.percent1RM > 1.5)) {
          errors.push({ field: `weeks[${i}].sessions[${j}].exercises[${k}].percent1RM`, message: `percent1RM ${ex.percent1RM} must be between 0.0 and 1.5` });
        }
      });
    });
  });
  return errors;
}
