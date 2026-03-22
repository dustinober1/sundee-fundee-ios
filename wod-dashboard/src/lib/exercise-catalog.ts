export interface WeightliftingExercise {
  name: string;
  category:
    | "Squat"
    | "Hip Hinge"
    | "Press"
    | "Pull"
    | "Carry"
    | "Olympic Weightlifting";
}

export interface ConditioningExercise {
  name: string;
  scoring: "Reps" | "Time";
}

export const weightliftingExercises: WeightliftingExercise[] = [
  // Squat (6)
  { name: "Back Squat", category: "Squat" },
  { name: "Front Squat", category: "Squat" },
  { name: "Safety Bar Squat", category: "Squat" },
  { name: "Box Squat", category: "Squat" },
  { name: "Pause Squat", category: "Squat" },
  { name: "Goblet Squat", category: "Squat" },

  // Hip Hinge (10)
  { name: "Conventional Deadlift (No Straps)", category: "Hip Hinge" },
  { name: "Conventional Deadlift (With Straps)", category: "Hip Hinge" },
  { name: "Romanian Deadlift (No Straps)", category: "Hip Hinge" },
  { name: "Romanian Deadlift (With Straps)", category: "Hip Hinge" },
  { name: "Sumo Deadlift (No Straps)", category: "Hip Hinge" },
  { name: "Sumo Deadlift (With Straps)", category: "Hip Hinge" },
  { name: "Trap Bar Deadlift (No Straps)", category: "Hip Hinge" },
  { name: "Trap Bar Deadlift (With Straps)", category: "Hip Hinge" },
  { name: "Good Morning", category: "Hip Hinge" },
  { name: "Hip Thrust", category: "Hip Hinge" },

  // Press (6)
  { name: "Flat Barbell Bench Press", category: "Press" },
  { name: "Incline Barbell Bench Press", category: "Press" },
  { name: "Strict Press", category: "Press" },
  { name: "Push Press", category: "Press" },
  { name: "Dumbbell Bench Press", category: "Press" },
  { name: "Dumbbell Overhead Press", category: "Press" },

  // Pull (6)
  { name: "Barbell Row", category: "Pull" },
  { name: "Pendlay Row", category: "Pull" },
  { name: "Pull-Up", category: "Pull" },
  { name: "Weighted Pull-Up", category: "Pull" },
  { name: "Lat Pulldown", category: "Pull" },
  { name: "Cable Row", category: "Pull" },

  // Carry (2)
  { name: "Farmers Carry", category: "Carry" },
  { name: "Suitcase Carry", category: "Carry" },

  // Olympic Weightlifting (9)
  { name: "Squat Snatch", category: "Olympic Weightlifting" },
  { name: "Squat Clean", category: "Olympic Weightlifting" },
  { name: "Power Clean", category: "Olympic Weightlifting" },
  { name: "Power Snatch", category: "Olympic Weightlifting" },
  { name: "Hang Clean", category: "Olympic Weightlifting" },
  { name: "Hang Snatch", category: "Olympic Weightlifting" },
  { name: "Split Jerk", category: "Olympic Weightlifting" },
  { name: "Push Jerk", category: "Olympic Weightlifting" },
  { name: "Clean and Jerk", category: "Olympic Weightlifting" },
];

export const conditioningExercises: ConditioningExercise[] = [
  // Reps (14)
  { name: "Wall Ball", scoring: "Reps" },
  { name: "Box Jump", scoring: "Reps" },
  { name: "Burpee", scoring: "Reps" },
  { name: "Kettlebell Swing", scoring: "Reps" },
  { name: "Double Under", scoring: "Reps" },
  { name: "Pull-Up (Kipping)", scoring: "Reps" },
  { name: "Toes-to-Bar", scoring: "Reps" },
  { name: "Muscle-Up", scoring: "Reps" },
  { name: "Push-Up", scoring: "Reps" },
  { name: "Sit-Up", scoring: "Reps" },
  { name: "Air Squat", scoring: "Reps" },
  { name: "Thruster", scoring: "Reps" },
  { name: "Rowing (Calories)", scoring: "Reps" },
  { name: "Assault Bike (Calories)", scoring: "Reps" },

  // Time (7)
  { name: "400m Run", scoring: "Time" },
  { name: "800m Run", scoring: "Time" },
  { name: "1-Mile Run", scoring: "Time" },
  { name: "5K Run", scoring: "Time" },
  { name: "500m Row", scoring: "Time" },
  { name: "2K Row", scoring: "Time" },
  { name: "1K Assault Bike", scoring: "Time" },
];

export const allExerciseNames: string[] = [
  ...weightliftingExercises.map((e) => e.name),
  ...conditioningExercises.map((e) => e.name),
];
