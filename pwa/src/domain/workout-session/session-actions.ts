/**
 * Workout Session Actions
 * Pure reducer-style functions for managing in-progress workout session state.
 *
 * All functions are immutable — they return new session objects without mutating input.
 */

import type { LoggedSet, ActiveExercise, WorkoutSession } from './session-types';

// ---------------------------------------------------------------------------
// ID generation
// ---------------------------------------------------------------------------

function generateId(): string {
  // Use crypto.randomUUID if available (Node 14.17+, modern browsers)
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  // Fallback: timestamp + random suffix
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`;
}

// ---------------------------------------------------------------------------
// createSession
// ---------------------------------------------------------------------------

/**
 * Creates a new empty workout session.
 *
 * @param timerMode   - Optional timer mode for the session
 * @param timerConfig - Optional timer configuration
 * @returns A new WorkoutSession with unique id, startedAt, and empty exercises
 */
export function createSession(
  timerMode: WorkoutSession['timerMode'] = 'none',
  timerConfig?: WorkoutSession['timerConfig'],
): WorkoutSession {
  return {
    id: generateId(),
    startedAt: new Date().toISOString(),
    exercises: [],
    timerMode,
    ...(timerConfig !== undefined ? { timerConfig } : {}),
  };
}

// ---------------------------------------------------------------------------
// addExercise
// ---------------------------------------------------------------------------

/**
 * Appends a new exercise to the session with 3 empty sets.
 *
 * @param session  - Current workout session
 * @param exercise - Exercise details to add
 * @returns New session with the exercise appended
 */
export function addExercise(
  session: WorkoutSession,
  exercise: { exerciseId: string; exerciseName: string; muscleGroup: string },
): WorkoutSession {
  const emptySet = (): LoggedSet => ({
    id: generateId(),
    weight: 0,
    reps: 0,
    completed: false,
  });

  const newExercise: ActiveExercise = {
    id: generateId(),
    exerciseId: exercise.exerciseId,
    exerciseName: exercise.exerciseName,
    muscleGroup: exercise.muscleGroup,
    sets: [emptySet(), emptySet(), emptySet()],
    order: session.exercises.length,
  };

  return {
    ...session,
    exercises: [...session.exercises, newExercise],
  };
}

// ---------------------------------------------------------------------------
// removeExercise
// ---------------------------------------------------------------------------

/**
 * Removes an exercise from the session by its active-exercise id and re-numbers order.
 *
 * @param session          - Current workout session
 * @param activeExerciseId - The id of the ActiveExercise to remove (not exerciseId)
 * @returns New session with the exercise removed and orders renumbered
 */
export function removeExercise(session: WorkoutSession, activeExerciseId: string): WorkoutSession {
  const remaining = session.exercises
    .filter((e) => e.id !== activeExerciseId)
    .map((e, index) => ({ ...e, order: index }));

  return {
    ...session,
    exercises: remaining,
  };
}

// ---------------------------------------------------------------------------
// addSet
// ---------------------------------------------------------------------------

/**
 * Appends a new empty LoggedSet to the specified exercise.
 *
 * @param session          - Current workout session
 * @param activeExerciseId - The id of the ActiveExercise to add a set to
 * @returns New session with the set appended
 */
export function addSet(session: WorkoutSession, activeExerciseId: string): WorkoutSession {
  const newSet: LoggedSet = {
    id: generateId(),
    weight: 0,
    reps: 0,
    completed: false,
  };

  return {
    ...session,
    exercises: session.exercises.map((e) =>
      e.id === activeExerciseId
        ? { ...e, sets: [...e.sets, newSet] }
        : e,
    ),
  };
}

// ---------------------------------------------------------------------------
// removeSet
// ---------------------------------------------------------------------------

/**
 * Removes a specific set from an exercise.
 *
 * @param session          - Current workout session
 * @param activeExerciseId - The id of the ActiveExercise containing the set
 * @param setId            - The id of the LoggedSet to remove
 * @returns New session with the set removed
 */
export function removeSet(
  session: WorkoutSession,
  activeExerciseId: string,
  setId: string,
): WorkoutSession {
  return {
    ...session,
    exercises: session.exercises.map((e) =>
      e.id === activeExerciseId
        ? { ...e, sets: e.sets.filter((s) => s.id !== setId) }
        : e,
    ),
  };
}

// ---------------------------------------------------------------------------
// completeSet
// ---------------------------------------------------------------------------

/**
 * Marks a set as completed with the provided weight, reps, and a timestamp.
 *
 * @param session          - Current workout session
 * @param activeExerciseId - The id of the ActiveExercise containing the set
 * @param setId            - The id of the LoggedSet to complete
 * @param data             - Weight and reps for the completed set
 * @returns New session with the set marked as completed
 */
export function completeSet(
  session: WorkoutSession,
  activeExerciseId: string,
  setId: string,
  data: { weight: number; reps: number },
): WorkoutSession {
  return {
    ...session,
    exercises: session.exercises.map((e) =>
      e.id === activeExerciseId
        ? {
            ...e,
            sets: e.sets.map((s) =>
              s.id === setId
                ? {
                    ...s,
                    completed: true,
                    completedAt: new Date().toISOString(),
                    weight: data.weight,
                    reps: data.reps,
                  }
                : s,
            ),
          }
        : e,
    ),
  };
}

// ---------------------------------------------------------------------------
// reorderExercises
// ---------------------------------------------------------------------------

/**
 * Reorders exercises according to the provided ordered array of active-exercise ids.
 * Updates the `order` property on each exercise to match its new position.
 *
 * @param session    - Current workout session
 * @param orderedIds - Array of active-exercise ids in desired order
 * @returns New session with exercises reordered and orders updated
 */
export function reorderExercises(session: WorkoutSession, orderedIds: string[]): WorkoutSession {
  const exerciseMap = new Map(session.exercises.map((e) => [e.id, e]));

  const reordered = orderedIds
    .map((id, index) => {
      const exercise = exerciseMap.get(id);
      if (!exercise) return null;
      return { ...exercise, order: index };
    })
    .filter((e): e is ActiveExercise => e !== null);

  return {
    ...session,
    exercises: reordered,
  };
}
