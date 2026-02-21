/// Exercise metadata for name lookups and coaching context.
/// Exact port of src/data/exercises.ts from v1.1.

class ExerciseMetadata {
  final String id;
  final String name;
  final String category;
  final List<String> muscleGroups;
  final String description;

  const ExerciseMetadata({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroups,
    required this.description,
  });
}

const List<ExerciseMetadata> EXERCISES = [
  ExerciseMetadata(
    id: 'back-squat',
    name: 'Back Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Barbell squat with bar on upper back',
  ),
  ExerciseMetadata(
    id: 'front-squat',
    name: 'Front Squat',
    category: 'front-squat',
    muscleGroups: ['quadriceps', 'core', 'upper-back'],
    description: 'Barbell squat with front rack position',
  ),
  ExerciseMetadata(
    id: 'pause-squat',
    name: 'Pause Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Back squat with a 2-3 second pause at the bottom',
  ),
  ExerciseMetadata(
    id: 'zombie-squat',
    name: 'Zombie Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'core', 'upper-back'],
    description: 'Front squat with arms extended forward, teaches upright torso',
  ),
  ExerciseMetadata(
    id: 'zercher-squat',
    name: 'Zercher Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core', 'biceps'],
    description: 'Squat with bar held in crook of elbows',
  ),
  ExerciseMetadata(
    id: 'bulgarian-split-squat',
    name: 'Bulgarian Split Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Single-leg squat with rear foot elevated on bench',
  ),
  ExerciseMetadata(
    id: 'front-rack-hold',
    name: 'Front Rack Hold',
    category: 'back-squat',
    muscleGroups: ['core', 'upper-back', 'shoulders'],
    description: 'Isometric hold in front rack position, time-based',
  ),
];

/// Look up an exercise by its ID. Returns null if not found.
ExerciseMetadata? getExerciseByName(String id) {
  try {
    return EXERCISES.firstWhere((exercise) => exercise.id == id);
  } catch (_) {
    return null;
  }
}
