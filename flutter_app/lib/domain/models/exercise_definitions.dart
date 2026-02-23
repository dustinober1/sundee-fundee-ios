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
    // Squat Variations
    ExerciseDefinition(id: 'back-squat', name: 'Back Squat', category: 'Squat Variations', muscleGroups: ['quads', 'glutes', 'hamstrings', 'core']),
    ExerciseDefinition(id: 'front-squat', name: 'Front Squat', category: 'Squat Variations', muscleGroups: ['quads', 'core']),
    ExerciseDefinition(id: 'overhead-squat', name: 'Overhead Squat', category: 'Squat Variations', muscleGroups: ['quads', 'shoulders', 'core']),
    ExerciseDefinition(id: 'box-squat', name: 'Box Squat', category: 'Squat Variations', muscleGroups: ['glutes', 'hamstrings']),
    ExerciseDefinition(id: 'zercher-squat', name: 'Zercher Squat', category: 'Squat Variations', muscleGroups: ['quads', 'core']),
    ExerciseDefinition(id: 'bulgarian-split-squat', name: 'Bulgarian Split Squat', category: 'Squat Variations', muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(id: 'goblet-squat', name: 'Goblet Squat', category: 'Squat Variations', muscleGroups: ['quads', 'core']),
    ExerciseDefinition(id: 'pause-squat', name: 'Pause Squat', category: 'Squat Variations', muscleGroups: ['quads', 'glutes']),

    // Olympic Lifts - Cleans
    ExerciseDefinition(id: 'squat-clean-front-squat-complex', name: 'Squat Clean + Front Squat Complex', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'squat-clean', name: 'Squat Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'power-clean', name: 'Power Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'hang-squat-clean', name: 'Hang Squat Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'hang-power-clean', name: 'Hang Power Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'block-squat-clean', name: 'Block Squat Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'block-power-clean', name: 'Block Power Clean', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'muscle-clean', name: 'Muscle Clean', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'back']),
    ExerciseDefinition(id: 'clean-pull', name: 'Clean Pull', category: 'Olympic Lifts', muscleGroups: ['full-body']),

    // Olympic Lifts - Jerks
    ExerciseDefinition(id: 'split-jerk', name: 'Split Jerk', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'triceps', 'legs']),
    ExerciseDefinition(id: 'push-jerk', name: 'Push Jerk', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'triceps']),
    ExerciseDefinition(id: 'squat-jerk', name: 'Squat Jerk', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'legs']),

    // Olympic Lifts - Snatches
    ExerciseDefinition(id: 'squat-snatch', name: 'Squat Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'power-snatch', name: 'Power Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'hang-squat-snatch', name: 'Hang Squat Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'hang-power-snatch', name: 'Hang Power Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'block-squat-snatch', name: 'Block Squat Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'block-power-snatch', name: 'Block Power Snatch', category: 'Olympic Lifts', muscleGroups: ['full-body']),
    ExerciseDefinition(id: 'muscle-snatch', name: 'Muscle Snatch', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'back']),

    // Bench Press Variations
    ExerciseDefinition(id: 'flat-barbell-bench-press', name: 'Flat Barbell Bench Press', category: 'Bench Press Variations', muscleGroups: ['chest', 'triceps', 'shoulders']),
    ExerciseDefinition(id: 'incline-bench-press', name: 'Incline Bench Press', category: 'Bench Press Variations', muscleGroups: ['upper-chest', 'shoulders']),
    ExerciseDefinition(id: 'decline-bench-press', name: 'Decline Bench Press', category: 'Bench Press Variations', muscleGroups: ['lower-chest', 'triceps']),
    ExerciseDefinition(id: 'close-grip-bench-press', name: 'Close-Grip Bench Press', category: 'Bench Press Variations', muscleGroups: ['triceps', 'chest']),
    ExerciseDefinition(id: 'wide-grip-bench-press', name: 'Wide-Grip Bench Press', category: 'Bench Press Variations', muscleGroups: ['chest']),
    ExerciseDefinition(id: 'floor-press', name: 'Floor Press', category: 'Bench Press Variations', muscleGroups: ['triceps', 'chest']),
    ExerciseDefinition(id: 'spoto-press', name: 'Spoto Press', category: 'Bench Press Variations', muscleGroups: ['chest', 'triceps']),
    ExerciseDefinition(id: 'board-press', name: 'Board Press', category: 'Bench Press Variations', muscleGroups: ['triceps', 'chest']),

    // Deadlift Variations
    ExerciseDefinition(id: 'conventional-deadlift-no-straps', name: 'Conventional Deadlift (No Straps)', category: 'Deadlift Variations', muscleGroups: ['posterior-chain', 'grip']),
    ExerciseDefinition(id: 'conventional-deadlift-with-straps', name: 'Conventional Deadlift (With Straps)', category: 'Deadlift Variations', muscleGroups: ['posterior-chain']),
    ExerciseDefinition(id: 'sumo-deadlift-no-straps', name: 'Sumo Deadlift (No Straps)', category: 'Deadlift Variations', muscleGroups: ['posterior-chain', 'quads', 'grip']),
    ExerciseDefinition(id: 'sumo-deadlift-with-straps', name: 'Sumo Deadlift (With Straps)', category: 'Deadlift Variations', muscleGroups: ['posterior-chain', 'quads']),
    ExerciseDefinition(id: 'speed-deadlift', name: 'Speed Deadlift', category: 'Deadlift Variations', muscleGroups: ['posterior-chain', 'grip']),

    // Hinge Variations
    ExerciseDefinition(id: 'romanian-deadlift-no-straps', name: 'Romanian Deadlift (No Straps)', category: 'Hinge Variations', muscleGroups: ['hamstrings', 'glutes', 'grip']),
    ExerciseDefinition(id: 'romanian-deadlift-with-straps', name: 'Romanian Deadlift (With Straps)', category: 'Hinge Variations', muscleGroups: ['hamstrings', 'glutes']),
    ExerciseDefinition(id: 'stiff-legged-deadlift-no-straps', name: 'Stiff-Legged Deadlift (No Straps)', category: 'Hinge Variations', muscleGroups: ['hamstrings', 'lower-back', 'grip']),
    ExerciseDefinition(id: 'stiff-legged-deadlift-with-straps', name: 'Stiff-Legged Deadlift (With Straps)', category: 'Hinge Variations', muscleGroups: ['hamstrings', 'lower-back']),
    ExerciseDefinition(id: 'deficit-deadlift-no-straps', name: 'Deficit Deadlift (No Straps)', category: 'Hinge Variations', muscleGroups: ['posterior-chain', 'grip']),
    ExerciseDefinition(id: 'deficit-deadlift-with-straps', name: 'Deficit Deadlift (With Straps)', category: 'Hinge Variations', muscleGroups: ['posterior-chain']),
    ExerciseDefinition(id: 'trap-bar-deadlift-no-straps', name: 'Trap Bar / Hex Bar Deadlift (No Straps)', category: 'Hinge Variations', muscleGroups: ['posterior-chain', 'quads', 'grip']),
    ExerciseDefinition(id: 'trap-bar-deadlift-with-straps', name: 'Trap Bar / Hex Bar Deadlift (With Straps)', category: 'Hinge Variations', muscleGroups: ['posterior-chain', 'quads']),
    ExerciseDefinition(id: 'rack-pull', name: 'Rack Pull / Block Pull', category: 'Hinge Variations', muscleGroups: ['back', 'glutes', 'grip']),

    // Overhead Pressing
    ExerciseDefinition(id: 'strict-press', name: 'Strict Press / Military Press', category: 'Overhead Pressing', muscleGroups: ['shoulders', 'triceps']),
    ExerciseDefinition(id: 'push-press', name: 'Push Press', category: 'Overhead Pressing', muscleGroups: ['shoulders', 'triceps', 'legs']),
    ExerciseDefinition(id: 'z-press', name: 'Z-Press', category: 'Overhead Pressing', muscleGroups: ['shoulders', 'core']),

    // Back Exercises
    ExerciseDefinition(id: 'pendlay-row', name: 'Pendlay Row', category: 'Back Exercises', muscleGroups: ['back', 'biceps', 'core']),
    ExerciseDefinition(id: 'pull-up', name: 'Pull-up', category: 'Back Exercises', muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(id: 'lat-pulldown', name: 'Lat Pulldown', category: 'Back Exercises', muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(id: 't-bar-row', name: 'T-Bar Row', category: 'Back Exercises', muscleGroups: ['back', 'biceps']),

    // Accessories & Core
    ExerciseDefinition(id: 'walking-lunges', name: 'Walking Lunges', category: 'Accessories', muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(id: 'bodyweight-lunges', name: 'Bodyweight Lunges', category: 'Accessories', muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(id: 'weighted-planks', name: 'Weighted Planks', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'unweighted-planks', name: 'Unweighted Planks', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'box-jumps', name: 'Box Jumps', category: 'Plyometrics', muscleGroups: ['legs', 'explosiveness']),
    ExerciseDefinition(id: 'pallof-press', name: 'Pallof Press', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'leg-curls', name: 'Leg Curls', category: 'Accessories', muscleGroups: ['hamstrings']),
    ExerciseDefinition(id: 'glute-ham-raises', name: 'Glute Ham Raises', category: 'Accessories', muscleGroups: ['hamstrings', 'glutes', 'lower-back']),
    ExerciseDefinition(id: 'light-core', name: 'Light Core Work', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'ab-wheel-rollouts', name: 'Ab Wheel Rollouts', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'broad-jumps', name: 'Broad Jumps', category: 'Plyometrics', muscleGroups: ['legs', 'explosiveness']),
    ExerciseDefinition(id: 'barbell-shrug', name: 'Barbell Shrug', category: 'Accessories', muscleGroups: ['traps']),
    ExerciseDefinition(id: 'mobility', name: 'Mobility Work', category: 'Accessories', muscleGroups: ['full-body']),

    // New Bench Press Accessories
    ExerciseDefinition(id: 'incline-dumbbell-bench-press', name: 'Incline Dumbbell Bench Press', category: 'Bench Press Variations', muscleGroups: ['upper-chest', 'shoulders']),
    ExerciseDefinition(id: 'dumbbell-bench-press', name: 'Dumbbell Bench Press', category: 'Bench Press Variations', muscleGroups: ['chest', 'shoulders', 'triceps']),
    ExerciseDefinition(id: 'chest-flys', name: 'Chest Flys', category: 'Accessories', muscleGroups: ['chest']),
    ExerciseDefinition(id: 'face-pulls', name: 'Face Pulls', category: 'Accessories', muscleGroups: ['rear-delts', 'upper-back']),
    ExerciseDefinition(id: 'skullcrushers', name: 'Skullcrushers', category: 'Accessories', muscleGroups: ['triceps']),
    ExerciseDefinition(id: 'barbell-rows', name: 'Barbell Rows', category: 'Accessories', muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(id: 'triceps-pushdowns', name: 'Triceps Pushdowns', category: 'Accessories', muscleGroups: ['triceps']),
    ExerciseDefinition(id: 'dumbbell-pullovers', name: 'Dumbbell Pullovers', category: 'Accessories', muscleGroups: ['chest', 'lats']),
    ExerciseDefinition(id: 'lateral-raises', name: 'Lateral Raises', category: 'Accessories', muscleGroups: ['shoulders']),
    ExerciseDefinition(id: 'weighted-dips', name: 'Weighted Dips', category: 'Accessories', muscleGroups: ['chest', 'triceps', 'shoulders']),
    ExerciseDefinition(id: 'pendlay-rows', name: 'Pendlay Rows', category: 'Accessories', muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(id: 'overhead-dumbbell-triceps-extensions', name: 'Overhead Dumbbell Triceps Extensions', category: 'Accessories', muscleGroups: ['triceps']),
    ExerciseDefinition(id: 'pull-ups', name: 'Pull-ups', category: 'Accessories', muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(id: 'triceps-extensions', name: 'Triceps Extensions', category: 'Accessories', muscleGroups: ['triceps']),

    // Squat Cycle 2 Accessories
    ExerciseDefinition(id: 'good-mornings', name: 'Good Mornings', category: 'Hinge Variations', muscleGroups: ['hamstrings', 'lower-back']),
    ExerciseDefinition(id: 'front-rack-reverse-lunges', name: 'Front-Rack Reverse Lunges', category: 'Accessories', muscleGroups: ['quads', 'glutes', 'core']),
    ExerciseDefinition(id: 'kettlebell-swings', name: 'Kettlebell Swings', category: 'Hinge Variations', muscleGroups: ['posterior-chain', 'glutes']),
    ExerciseDefinition(id: 'snatch-balance', name: 'Snatch Balance', category: 'Olympic Lifts', muscleGroups: ['shoulders', 'legs', 'core']),
    ExerciseDefinition(id: 'hanging-leg-raises', name: 'Hanging Leg Raises', category: 'Core', muscleGroups: ['core']),
    ExerciseDefinition(id: 'barbell-hip-thrusts', name: 'Barbell Hip Thrusts', category: 'Hinge Variations', muscleGroups: ['glutes', 'hamstrings']),
    ExerciseDefinition(id: 'farmers-carries', name: "Farmer's Carries", category: 'Accessories', muscleGroups: ['grip', 'core', 'traps']),
    ExerciseDefinition(id: 'speed-squat', name: 'Speed Squat', category: 'Squat Variations', muscleGroups: ['quads', 'glutes', 'explosiveness']),
    ExerciseDefinition(id: 'tempo-back-squat', name: 'Tempo Back Squat', category: 'Squat Variations', muscleGroups: ['quads', 'glutes', 'core']),
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
