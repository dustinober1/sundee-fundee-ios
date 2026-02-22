class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroups,
  });

  final String id;
  final String name;
  final String category;
  final List<String> muscleGroups;
}

class Exercises {
  static const List<ExerciseDefinition> all = <ExerciseDefinition>[
    ExerciseDefinition(
      id: 'back-squat',
      name: 'Back Squat',
      category: 'legs',
      muscleGroups: <String>['quads', 'glutes', 'core'],
    ),
    ExerciseDefinition(
      id: 'deadlift',
      name: 'Deadlift',
      category: 'posterior-chain',
      muscleGroups: <String>['hamstrings', 'glutes', 'back'],
    ),
    ExerciseDefinition(
      id: 'bench-press',
      name: 'Bench Press',
      category: 'upper-body',
      muscleGroups: <String>['chest', 'triceps', 'shoulders'],
    ),
  ];

  static ExerciseDefinition? findById(String id) {
    for (final ExerciseDefinition exercise in all) {
      if (exercise.id == id) {
        return exercise;
      }
    }

    return null;
  }
}
