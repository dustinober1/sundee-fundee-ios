/**
 * useExerciseSelection — lightweight event bridge between exercise-picker and workout-session.
 *
 * Expo Router doesn't reliably pass params back when navigating "backwards" via
 * router.back(), router.navigate(), or router.replace(). This module provides a
 * simple callback-based approach: workout-session registers a listener,
 * exercise-picker fires the selection, then calls router.back().
 */

import type { Exercise } from '../domain/exercises/exercise-types';

type Listener = (exercise: Exercise) => void;

let listener: Listener | null = null;

/** Called by workout-session to register for the next selection. */
export function onExerciseSelected(cb: Listener): () => void {
  listener = cb;
  return () => {
    if (listener === cb) listener = null;
  };
}

/** Called by exercise-picker when user taps an exercise. */
export function emitExerciseSelected(exercise: Exercise): void {
  if (listener) {
    listener(exercise);
    listener = null; // one-shot
  }
}
