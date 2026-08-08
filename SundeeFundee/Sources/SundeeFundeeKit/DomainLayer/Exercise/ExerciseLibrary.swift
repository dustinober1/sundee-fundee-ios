import Foundation

// MARK: - Generated-Workout Exercise Library
//
// The candidate pools every generated workout draws from, keyed by equipment
// and focus. These pools are the single source of truth for three things:
//
//   1. What a generated workout may contain (`workoutExercisePool`).
//   2. What counts as equipment-legal (`isExerciseAllowed`, derived from the
//      `all*Candidates()` roll-ups below).
//   3. Which movement pattern a name maps to during validation.
//
// Because of (3), a given exercise name MUST carry the same
// `WorkoutMovementPattern` everywhere it appears. `movementPattern(for:)` in
// AIWorkout.swift resolves a name by first match across the roll-up, so an
// inconsistent pattern would make validation disagree with selection.
//
// Pools are sized so a long session has somewhere to go: a 60–90 minute
// request needs 8+ distinct movements before it has to start stacking sets.

// MARK: - Bodyweight

func bodyweightExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody:
        return [
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Incline Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Decline Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Diamond Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pike Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Dips", bodyweightOnly: true, pattern: .push),
            .init(name: "Bench Dip", bodyweightOnly: true, pattern: .push),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Chin-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull),
            .init(name: "Scapular Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone Y Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone W Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .push:
        return [
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Incline Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Decline Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Wide Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Diamond Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pike Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pseudo Planche Push-Up", bodyweightOnly: true, pattern: .push, isHighSkill: true),
            .init(name: "Dips", bodyweightOnly: true, pattern: .push),
            .init(name: "Bench Dip", bodyweightOnly: true, pattern: .push),
            .init(name: "Handstand Hold", bodyweightOnly: true, pattern: .push, isHighSkill: true),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Hollow Body Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Chin-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Negative Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull),
            .init(name: "Towel Inverted Row", bodyweightOnly: true, pattern: .pull),
            .init(name: "Scapular Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone Y Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone W Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Superman Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Bird Dog", bodyweightOnly: true, pattern: .core)
        ]
    case .lowerBody:
        return [
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Split Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Bulgarian Split Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Reverse Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Walking Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Lateral Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Step-Up", bodyweightOnly: true, pattern: .squat),
            .init(name: "Cossack Squat", bodyweightOnly: true, pattern: .squat, isHighSkill: true),
            .init(name: "Wall Sit", bodyweightOnly: true, pattern: .squat),
            .init(name: "Calf Raise", bodyweightOnly: true, pattern: .squat),
            .init(name: "Glute Bridge", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Single-Leg Glute Bridge", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Single-Leg Deadlift", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Good Morning (Bodyweight)", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Nordic Curl Negative", bodyweightOnly: true, pattern: .hinge, isHighSkill: true)
        ]
    case .fullBody:
        return [
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Reverse Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Bulgarian Split Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Glute Bridge", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Single-Leg Deadlift", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Good Morning (Bodyweight)", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pike Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Dips", bodyweightOnly: true, pattern: .push),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone W Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Dead Bug", bodyweightOnly: true, pattern: .core),
            .init(name: "Bear Crawl", bodyweightOnly: true, pattern: .carry),
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning)
        ]
    case .core:
        return [
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Side Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Hollow Body Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "V-up", bodyweightOnly: true, pattern: .core),
            .init(name: "Dead Bug", bodyweightOnly: true, pattern: .core),
            .init(name: "Sit-Up", bodyweightOnly: true, pattern: .core),
            .init(name: "Bicycle Crunch", bodyweightOnly: true, pattern: .core),
            .init(name: "Flutter Kick", bodyweightOnly: true, pattern: .core),
            .init(name: "Leg Raise", bodyweightOnly: true, pattern: .core),
            .init(name: "Bird Dog", bodyweightOnly: true, pattern: .core),
            .init(name: "Superman Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core),
            .init(name: "L-Sit Hold", bodyweightOnly: true, pattern: .core, isHighSkill: true),
            .init(name: "Bear Crawl", bodyweightOnly: true, pattern: .carry)
        ]
    case .conditioning:
        return [
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Jumping Jack", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "High Knees", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Skater Jump", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Shuttle Run", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Broad Jump", bodyweightOnly: true, pattern: .conditioning, isHighSkill: true),
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Squat Jump", bodyweightOnly: true, pattern: .squat),
            .init(name: "Jump Lunge", bodyweightOnly: true, pattern: .squat, isHighSkill: true),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core),
            .init(name: "Bear Crawl", bodyweightOnly: true, pattern: .carry)
        ]
    }
}

// MARK: - Dumbbells

func dumbbellExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody:
        return [
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Arnold Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Skull Crusher", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Triceps Kickback", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Pullover", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Dumbbell)", bodyweightOnly: false, pattern: .pull),
            .init(name: "Hammer Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Rear Delt Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Shrug", bodyweightOnly: false, pattern: .pull)
        ]
    case .push:
        return [
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Squeeze Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Arnold Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Front Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Skull Crusher", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Triceps Kickback", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Renegade Row", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Dumbbell Pullover", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Dumbbell)", bodyweightOnly: false, pattern: .pull),
            .init(name: "Hammer Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Concentration Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Shrug", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Rear Delt Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Bulgarian Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Lateral Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Calf Raise", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Single-Leg Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Good Morning", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Glute Bridge", bodyweightOnly: true, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Single-Leg Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Dumbbell Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .core:
        return [
            .init(name: "Dumbbell Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Dumbbell Russian Twist", bodyweightOnly: false, pattern: .core),
            .init(name: "Dumbbell Side Bend", bodyweightOnly: false, pattern: .core),
            .init(name: "Dumbbell Weighted Sit-Up", bodyweightOnly: false, pattern: .core),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Dead Bug", bodyweightOnly: true, pattern: .core),
            .init(name: "Hollow Body Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Side Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .conditioning:
        return [
            .init(name: "Dumbbell Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Dumbbell Clean", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Snatch", bodyweightOnly: false, pattern: .conditioning, isHighSkill: true),
            .init(name: "Dumbbell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Jumping Jack", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core)
        ]
    }
}

// MARK: - Kettlebell
//
// Deliberately free of bodyweight-only entries: the kettlebell allowlist is
// derived from these pools alone, so adding bodyweight names here would widen
// what counts as a legal kettlebell-only workout.

func kettlebellExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody:
        return [
            .init(name: "Kettlebell Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Z Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell See-Saw Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Half-Kneeling Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Kettlebell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Gorilla Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Upright Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Halo", bodyweightOnly: false, pattern: .core)
        ]
    case .push:
        return [
            .init(name: "Kettlebell Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Z Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell See-Saw Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Half-Kneeling Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Tall-Kneeling Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Kettlebell Bottoms-Up Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Overhead Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Halo", bodyweightOnly: false, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Kettlebell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Gorilla Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Upright Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Shrug", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Renegade Row", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Kettlebell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Farmer Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core)
        ]
    case .lowerBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Reverse Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Lateral Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Calf Raise", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Single-Leg Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Good Morning", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Reverse Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Single-Leg Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell Gorilla Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Farmer Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Turkish Get-Up", bodyweightOnly: false, pattern: .core, isHighSkill: true)
        ]
    case .core:
        return [
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Overhead Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Russian Twist", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Halo", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Side Bend", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Plank Pull-Through", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Windmill", bodyweightOnly: false, pattern: .core, isHighSkill: true),
            .init(name: "Turkish Get-Up", bodyweightOnly: false, pattern: .core, isHighSkill: true),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Farmer Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .conditioning:
        return [
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Single-Arm Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Halo", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Clean", bodyweightOnly: false, pattern: .hinge, isHighSkill: true),
            .init(name: "Kettlebell Snatch", bodyweightOnly: false, pattern: .conditioning, isHighSkill: true),
            .init(name: "Kettlebell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Kettlebell Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Farmer Carry", bodyweightOnly: false, pattern: .carry)
        ]
    }
}

// MARK: - Resistance Bands

func resistanceBandExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody:
        return [
            .init(name: "Band Chest Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Chest Fly", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Triceps Pressdown", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Band Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Pull-Apart", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Reverse Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Biceps Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Hammer Curl", bodyweightOnly: false, pattern: .pull)
        ]
    case .push:
        return [
            .init(name: "Band Chest Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Chest Fly", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Push-Up", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Front Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Triceps Pressdown", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Overhead Triceps Extension", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Triceps Kickback", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pallof Press", bodyweightOnly: false, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Band Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Pull-Apart", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Reverse Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Upright Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Shrug", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Biceps Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Hammer Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Straight-Arm Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Band Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Bulgarian Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Reverse Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Lateral Walk", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Monster Walk", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Hip Abduction", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Calf Raise", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Good Morning", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Pull-Through", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Glute Bridge", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Hamstring Curl", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Reverse Lunge", bodyweightOnly: true, pattern: .squat)
        ]
    case .fullBody:
        return [
            .init(name: "Band Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Split Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Reverse Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Band Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Good Morning", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Band Chest Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Band Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Pull-Apart", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pallof Press", bodyweightOnly: false, pattern: .core),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .core:
        return [
            .init(name: "Pallof Press", bodyweightOnly: false, pattern: .core),
            .init(name: "Band Wood Chop", bodyweightOnly: false, pattern: .core),
            .init(name: "Band Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Band Russian Twist", bodyweightOnly: false, pattern: .core),
            .init(name: "Band Anti-Rotation Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Side Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Dead Bug", bodyweightOnly: true, pattern: .core),
            .init(name: "Hollow Body Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "Bird Dog", bodyweightOnly: true, pattern: .core)
        ]
    case .conditioning:
        return [
            .init(name: "Band Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Band Squat to Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Band High Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Band Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Jumping Jack", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "High Knees", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core)
        ]
    }
}

// MARK: - Full Gym

func fullGymExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody:
        return [
            .init(name: "Flat Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Incline Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Machine Chest Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Cable Chest Fly", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Cable Triceps Pressdown", bodyweightOnly: false, pattern: .push),
            .init(name: "Overhead Triceps Extension", bodyweightOnly: false, pattern: .push),
            .init(name: "Dips (Weighted)", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Barbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Cable Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Rear Delt Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Barbell)", bodyweightOnly: false, pattern: .pull),
            .init(name: "Hammer Curl", bodyweightOnly: false, pattern: .pull)
        ]
    case .push:
        return [
            .init(name: "Flat Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Incline Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Close Grip Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Machine Chest Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Machine Shoulder Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Cable Chest Fly", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Lateral Raise", bodyweightOnly: false, pattern: .push),
            .init(name: "Cable Triceps Pressdown", bodyweightOnly: false, pattern: .push),
            .init(name: "Overhead Triceps Extension", bodyweightOnly: false, pattern: .push),
            .init(name: "Skull Crusher", bodyweightOnly: false, pattern: .push),
            .init(name: "Dips (Weighted)", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Barbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pendlay Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Chin-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Cable Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Chest-Supported Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Straight-Arm Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Rear Delt Fly", bodyweightOnly: false, pattern: .pull),
            .init(name: "Barbell Shrug", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Barbell)", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Dumbbell)", bodyweightOnly: false, pattern: .pull),
            .init(name: "Hammer Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Cable Curl", bodyweightOnly: false, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Back Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Leg Press", bodyweightOnly: false, pattern: .squat),
            .init(name: "Hack Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Bulgarian Split Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Walking Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Leg Extension", bodyweightOnly: false, pattern: .squat),
            .init(name: "Standing Calf Raise", bodyweightOnly: false, pattern: .squat),
            .init(name: "Romanian Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Conventional Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Trap Bar Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Good Morning", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Leg Curl (Lying)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Glute Ham Raise", bodyweightOnly: true, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Back Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Front Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Leg Press", bodyweightOnly: false, pattern: .squat),
            .init(name: "Walking Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Romanian Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Trap Bar Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Flat Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Overhead Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Barbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Cable Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Cable Crunch", bodyweightOnly: false, pattern: .core),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .core:
        return bodyweightExercisePool(for: .core) + [
            .init(name: "Cable Crunch", bodyweightOnly: false, pattern: .core),
            .init(name: "Cable Wood Chop", bodyweightOnly: false, pattern: .core),
            .init(name: "Pallof Press", bodyweightOnly: false, pattern: .core),
            .init(name: "Weighted Sit-Up", bodyweightOnly: false, pattern: .core),
            .init(name: "Hanging Leg Raise", bodyweightOnly: true, pattern: .core),
            .init(name: "Ab Wheel Rollout", bodyweightOnly: true, pattern: .core),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .conditioning:
        return [
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Wall Ball", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Box Jump", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Rowing Machine Interval", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Assault Bike Interval", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "SkiErg Interval", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Sled Push", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Battle Rope Wave", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Double Under", bodyweightOnly: true, pattern: .conditioning, isHighSkill: true),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core),
            .init(name: "Farmers Carry", bodyweightOnly: false, pattern: .carry)
        ]
    }
}

// MARK: - Equipment Roll-Ups
//
// These drive `isExerciseAllowed`. Anything reachable from an equipment's
// pools is legal for that equipment — and nothing else is.

func allWorkoutCandidates() -> [WorkoutExerciseCandidate] {
    allBodyweightCandidates() + allDumbbellCandidates() + allKettlebellCandidates() +
        allResistanceBandCandidates() +
        WorkoutFocus.allRuleCases.flatMap { fullGymExercisePool(for: $0) }
}

func allBodyweightCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { bodyweightExercisePool(for: $0) }
}

func allDumbbellCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { dumbbellExercisePool(for: $0) } + allBodyweightCandidates()
}

func allKettlebellCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { kettlebellExercisePool(for: $0) }
}

func allResistanceBandCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { resistanceBandExercisePool(for: $0) } + allBodyweightCandidates()
}

extension WorkoutFocus {
    static let allRuleCases: [WorkoutFocus] = [
        .upperBody, .lowerBody, .fullBody, .push, .pull, .core, .conditioning
    ]
}
