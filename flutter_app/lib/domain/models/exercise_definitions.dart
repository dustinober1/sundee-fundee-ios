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
    ExerciseDefinition(
        id: 'Back Squat',
        name: 'Back Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'glutes', 'hamstrings', 'core']),
    ExerciseDefinition(
        id: 'Front Squat',
        name: 'Front Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'core']),
    ExerciseDefinition(
        id: 'Overhead Squat',
        name: 'Overhead Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'shoulders', 'core']),
    ExerciseDefinition(
        id: 'Box Squat',
        name: 'Box Squat',
        category: 'Squat Variations',
        muscleGroups: ['glutes', 'hamstrings']),
    ExerciseDefinition(
        id: 'Zercher Squat',
        name: 'Zercher Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'core']),
    ExerciseDefinition(
        id: 'Bulgarian Split Squat',
        name: 'Bulgarian Split Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Goblet Squat',
        name: 'Goblet Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'core']),
    ExerciseDefinition(
        id: 'Pause Squat',
        name: 'Pause Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'glutes']),

    // Olympic Lifts - Cleans
    ExerciseDefinition(
        id: 'Squat Clean',
        name: 'Squat Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Power Clean',
        name: 'Power Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Hang Squat Clean',
        name: 'Hang Squat Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Hang Power Clean',
        name: 'Hang Power Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),

    ExerciseDefinition(
        id: 'Block Power Clean',
        name: 'Block Power Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Muscle Clean',
        name: 'Muscle Clean',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'back']),
    ExerciseDefinition(
        id: 'Clean Pull',
        name: 'Clean Pull',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),

    // Olympic Lifts - Jerks
    ExerciseDefinition(
        id: 'Split Jerk',
        name: 'Split Jerk',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'triceps', 'legs']),
    ExerciseDefinition(
        id: 'Push Jerk',
        name: 'Push Jerk',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'triceps']),
    ExerciseDefinition(
        id: 'Squat Jerk',
        name: 'Squat Jerk',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'legs']),

    // Olympic Lifts - Snatches
    ExerciseDefinition(
        id: 'Squat Snatch',
        name: 'Squat Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Power Snatch',
        name: 'Power Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Hang Squat Snatch',
        name: 'Hang Squat Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Hang Power Snatch',
        name: 'Hang Power Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),

    ExerciseDefinition(
        id: 'Block Power Snatch',
        name: 'Block Power Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['full-body']),
    ExerciseDefinition(
        id: 'Muscle Snatch',
        name: 'Muscle Snatch',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'back']),

    // Bench Press Variations
    ExerciseDefinition(
        id: 'Flat Barbell Bench Press',
        name: 'Flat Barbell Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['chest', 'triceps', 'shoulders']),
    ExerciseDefinition(
        id: 'Incline Bench Press',
        name: 'Incline Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['upper-chest', 'shoulders']),
    ExerciseDefinition(
        id: 'Decline Bench Press',
        name: 'Decline Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['lower-chest', 'triceps']),
    ExerciseDefinition(
        id: 'Close-Grip Bench Press',
        name: 'Close-Grip Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['triceps', 'chest']),
    ExerciseDefinition(
        id: 'Wide-Grip Bench Press',
        name: 'Wide-Grip Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['chest']),
    ExerciseDefinition(
        id: 'Floor Press',
        name: 'Floor Press',
        category: 'Bench Press Variations',
        muscleGroups: ['triceps', 'chest']),

    ExerciseDefinition(
        id: 'Board Press',
        name: 'Board Press',
        category: 'Bench Press Variations',
        muscleGroups: ['triceps', 'chest']),

    // Deadlift Variations
    ExerciseDefinition(
        id: 'Conventional Deadlift (No Straps)',
        name: 'Conventional Deadlift (No Straps)',
        category: 'Deadlift Variations',
        muscleGroups: ['posterior-chain', 'grip']),
    ExerciseDefinition(
        id: 'Conventional Deadlift (With Straps)',
        name: 'Conventional Deadlift (With Straps)',
        category: 'Deadlift Variations',
        muscleGroups: ['posterior-chain']),
    ExerciseDefinition(
        id: 'Sumo Deadlift (No Straps)',
        name: 'Sumo Deadlift (No Straps)',
        category: 'Deadlift Variations',
        muscleGroups: ['posterior-chain', 'quads', 'grip']),
    ExerciseDefinition(
        id: 'Sumo Deadlift (With Straps)',
        name: 'Sumo Deadlift (With Straps)',
        category: 'Deadlift Variations',
        muscleGroups: ['posterior-chain', 'quads']),


    // Hinge Variations
    ExerciseDefinition(
        id: 'Romanian Deadlift / RDL (No Straps)',
        name: 'Romanian Deadlift / RDL (No Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'glutes', 'grip']),
    ExerciseDefinition(
        id: 'Romanian Deadlift / RDL (With Straps)',
        name: 'Romanian Deadlift / RDL (With Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'glutes']),
    ExerciseDefinition(
        id: 'Stiff-Legged Deadlift (No Straps)',
        name: 'Stiff-Legged Deadlift (No Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'lower-back', 'grip']),
    ExerciseDefinition(
        id: 'Stiff-Legged Deadlift (With Straps)',
        name: 'Stiff-Legged Deadlift (With Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'lower-back']),
    ExerciseDefinition(
        id: 'Deficit Deadlift (No Straps)',
        name: 'Deficit Deadlift (No Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['posterior-chain', 'grip']),
    ExerciseDefinition(
        id: 'Deficit Deadlift (With Straps)',
        name: 'Deficit Deadlift (With Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['posterior-chain']),
    ExerciseDefinition(
        id: 'Trap Bar / Hex Bar Deadlift (No Straps)',
        name: 'Trap Bar / Hex Bar Deadlift (No Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['posterior-chain', 'quads', 'grip']),
    ExerciseDefinition(
        id: 'Trap Bar / Hex Bar Deadlift (With Straps)',
        name: 'Trap Bar / Hex Bar Deadlift (With Straps)',
        category: 'Hinge Variations',
        muscleGroups: ['posterior-chain', 'quads']),
    ExerciseDefinition(
        id: 'Rack Pull / Block Pull',
        name: 'Rack Pull / Block Pull',
        category: 'Hinge Variations',
        muscleGroups: ['back', 'glutes', 'grip']),

    // Overhead Pressing
    ExerciseDefinition(
        id: 'Strict Press / Military Press',
        name: 'Strict Press / Military Press',
        category: 'Overhead Pressing',
        muscleGroups: ['shoulders', 'triceps']),
    ExerciseDefinition(
        id: 'Push Press',
        name: 'Push Press',
        category: 'Overhead Pressing',
        muscleGroups: ['shoulders', 'triceps', 'legs']),
    ExerciseDefinition(
        id: 'Z-Press',
        name: 'Z-Press',
        category: 'Overhead Pressing',
        muscleGroups: ['shoulders', 'core']),

    // Back Exercises

    ExerciseDefinition(
        id: 'Pull-up',
        name: 'Pull-up',
        category: 'Back Exercises',
        muscleGroups: ['back', 'biceps']),



    // Accessories & Core
    ExerciseDefinition(
        id: 'Walking Lunges',
        name: 'Walking Lunges',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),

    ExerciseDefinition(
        id: 'Weighted Planks',
        name: 'Weighted Planks',
        category: 'Core',
        muscleGroups: ['core']),

    ExerciseDefinition(
        id: 'Box Jumps',
        name: 'Box Jumps',
        category: 'Plyometrics',
        muscleGroups: ['legs', 'explosiveness']),


    ExerciseDefinition(
        id: 'Glute Ham Raises',
        name: 'Glute Ham Raises',
        category: 'Accessories',
        muscleGroups: ['hamstrings', 'glutes', 'lower-back']),


    ExerciseDefinition(
        id: 'Broad Jumps',
        name: 'Broad Jumps',
        category: 'Plyometrics',
        muscleGroups: ['legs', 'explosiveness']),
    ExerciseDefinition(
        id: 'Barbell Shrug',
        name: 'Barbell Shrug',
        category: 'Accessories',
        muscleGroups: ['traps']),


    // New Bench Press Accessories
    ExerciseDefinition(
        id: 'Incline Dumbbell Bench Press',
        name: 'Incline Dumbbell Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['upper-chest', 'shoulders']),
    ExerciseDefinition(
        id: 'Dumbbell Bench Press',
        name: 'Dumbbell Bench Press',
        category: 'Bench Press Variations',
        muscleGroups: ['chest', 'shoulders', 'triceps']),
    ExerciseDefinition(
        id: 'Chest Flys',
        name: 'Chest Flys',
        category: 'Accessories',
        muscleGroups: ['chest']),

    ExerciseDefinition(
        id: 'Skullcrushers',
        name: 'Skullcrushers',
        category: 'Accessories',
        muscleGroups: ['triceps']),
    ExerciseDefinition(
        id: 'Barbell Rows',
        name: 'Barbell Rows',
        category: 'Accessories',
        muscleGroups: ['back', 'biceps']),

    ExerciseDefinition(
        id: 'Dumbbell Pullovers',
        name: 'Dumbbell Pullovers',
        category: 'Accessories',
        muscleGroups: ['chest', 'lats']),
    ExerciseDefinition(
        id: 'Lateral Raises',
        name: 'Lateral Raises',
        category: 'Accessories',
        muscleGroups: ['shoulders']),


    ExerciseDefinition(
        id: 'Overhead Dumbbell Triceps Extensions',
        name: 'Overhead Dumbbell Triceps Extensions',
        category: 'Accessories',
        muscleGroups: ['triceps']),
    ExerciseDefinition(
        id: 'Pull-ups',
        name: 'Pull-ups',
        category: 'Accessories',
        muscleGroups: ['back', 'biceps']),
    ExerciseDefinition(
        id: 'Triceps Extensions',
        name: 'Triceps Extensions',
        category: 'Accessories',
        muscleGroups: ['triceps']),

    // Squat Cycle 2 Accessories
    ExerciseDefinition(
        id: 'Good Mornings',
        name: 'Good Mornings',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'lower-back']),
    ExerciseDefinition(
        id: 'Front-Rack Reverse Lunges',
        name: 'Front-Rack Reverse Lunges',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes', 'core']),

    ExerciseDefinition(
        id: 'Snatch Balance',
        name: 'Snatch Balance',
        category: 'Olympic Lifts',
        muscleGroups: ['shoulders', 'legs', 'core']),

    ExerciseDefinition(
        id: 'Barbell Hip Thrusts',
        name: 'Barbell Hip Thrusts',
        category: 'Hinge Variations',
        muscleGroups: ['glutes', 'hamstrings']),
    ExerciseDefinition(
        id: 'Farmer\'s Carries',
        name: "Farmer's Carries",
        category: 'Accessories',
        muscleGroups: ['grip', 'core', 'traps']),

    // Back Squat Program Accessories
    ExerciseDefinition(
        id: 'Leg Raises',
        name: 'Leg Raises',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Face Pulls',
        name: 'Face Pulls',
        category: 'Accessories',
        muscleGroups: ['shoulders', 'upper-back']),
    ExerciseDefinition(
        id: 'Step-ups',
        name: 'Step-ups',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Russian Twists',
        name: 'Russian Twists',
        category: 'Core',
        muscleGroups: ['core', 'obliques']),
    ExerciseDefinition(
        id: 'Lat Pulldowns',
        name: 'Lat Pulldowns',
        category: 'Back Exercises',
        muscleGroups: ['back', 'lats', 'biceps']),
    ExerciseDefinition(
        id: 'Hollow Body Hold',
        name: 'Hollow Body Hold',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Single-Leg Press',
        name: 'Single-Leg Press',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Knees-to-Chest',
        name: 'Knees-to-Chest',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Heels-Elevated Goblet Squat',
        name: 'Heels-Elevated Goblet Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'core']),
    ExerciseDefinition(
        id: 'Curtsy Lunges',
        name: 'Curtsy Lunges',
        category: 'Accessories',
        muscleGroups: ['glutes', 'quads']),
    ExerciseDefinition(
        id: 'Side Plank',
        name: 'Side Plank',
        category: 'Core',
        muscleGroups: ['core', 'obliques']),
    ExerciseDefinition(
        id: 'Bodyweight Lunges',
        name: 'Bodyweight Lunges',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Bird-Dogs',
        name: 'Bird-Dogs',
        category: 'Core',
        muscleGroups: ['core', 'lower-back']),
    ExerciseDefinition(
        id: 'Air Squats',
        name: 'Air Squats',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Weighted Dead Bug',
        name: 'Weighted Dead Bug',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Leg Press',
        name: 'Leg Press',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Banded Pull-Aparts',
        name: 'Banded Pull-Aparts',
        category: 'Accessories',
        muscleGroups: ['shoulders', 'upper-back']),
    ExerciseDefinition(
        id: 'Hanging Leg Raises',
        name: 'Hanging Leg Raises',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Hack Squat',
        name: 'Hack Squat',
        category: 'Squat Variations',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'Snatch-Grip RDL',
        name: 'Snatch-Grip RDL',
        category: 'Hinge Variations',
        muscleGroups: ['hamstrings', 'glutes', 'upper-back']),
    ExerciseDefinition(
        id: 'Weighted Lunges',
        name: 'Weighted Lunges',
        category: 'Accessories',
        muscleGroups: ['quads', 'glutes']),
    ExerciseDefinition(
        id: 'L-Sit Hold',
        name: 'L-Sit Hold',
        category: 'Core',
        muscleGroups: ['core', 'abs']),
    ExerciseDefinition(
        id: 'Vertical Jumps',
        name: 'Vertical Jumps',
        category: 'Plyometrics',
        muscleGroups: ['legs', 'explosiveness']),
    ExerciseDefinition(
        id: 'Depth Jumps',
        name: 'Depth Jumps',
        category: 'Plyometrics',
        muscleGroups: ['legs', 'explosiveness']),
  ];

  static ExerciseDefinition? findById(String id) {
    for (final ExerciseDefinition exercise in all) {
      if (exercise.id == id) {
        return exercise;
      }
    }

    return null;
  }

  static String nameById(String id) {
    return findById(id)?.name ??
        id
            .split('-')
            .map((word) =>
                word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');
  }
}
