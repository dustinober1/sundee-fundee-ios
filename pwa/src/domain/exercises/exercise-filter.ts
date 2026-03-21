import type { Exercise, MuscleGroup } from './exercise-types';

/**
 * Pure function to filter an exercise catalog by name query and/or muscle group.
 *
 * @param exercises - Source exercise array to filter
 * @param query - Name substring to match (case-insensitive, trimmed). Empty string matches all.
 * @param muscleGroup - Optional exact muscle group to filter by.
 * @returns Filtered array of exercises.
 */
export function filterExercises(
  exercises: Exercise[],
  query: string,
  muscleGroup: MuscleGroup | undefined,
): Exercise[] {
  const trimmedQuery = query.trim().toLowerCase();

  return exercises.filter((exercise) => {
    if (muscleGroup !== undefined && exercise.muscleGroup !== muscleGroup) {
      return false;
    }
    if (trimmedQuery.length > 0 && !exercise.name.toLowerCase().includes(trimmedQuery)) {
      return false;
    }
    return true;
  });
}
