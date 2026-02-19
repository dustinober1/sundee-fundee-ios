const QUEUE_KEY = 'sync_pending_workout_ids';

/**
 * Adds a workout ID to the offline sync queue.
 * Deduplicates — a workout ID is only queued once.
 */
export function enqueueWorkout(workoutId: string): void {
  const existing = getQueue();
  if (!existing.includes(workoutId)) {
    localStorage.setItem(QUEUE_KEY, JSON.stringify([...existing, workoutId]));
  }
}

/**
 * Removes a workout ID from the offline sync queue after successful upload.
 */
export function dequeueWorkout(workoutId: string): void {
  const updated = getQueue().filter(id => id !== workoutId);
  localStorage.setItem(QUEUE_KEY, JSON.stringify(updated));
}

/**
 * Returns the current list of pending workout IDs.
 * Safe to call server-side (returns empty array).
 */
export function getQueue(): string[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(localStorage.getItem(QUEUE_KEY) ?? '[]');
  } catch {
    return [];
  }
}

/**
 * Clears all pending workout IDs from the queue.
 * Used after a full uploadAllLocalData run.
 */
export function clearQueue(): void {
  localStorage.removeItem(QUEUE_KEY);
}
