import Foundation

// MARK: - Benchmark Catalog

/// Catalog of predefined benchmarks
public struct BenchmarkCatalog {

    /// All predefined benchmarks
    public static let allBenchmarks: [BenchmarkDefinition] = [
        // MARK: - Sundee Fundee Exclusives

        BenchmarkDefinition(
            id: "sundee-vanessa",
            name: "Vanessa",
            category: BenchmarkCategory.sundeeFundee.rawValue,
            workoutDescription: "Buy-in: 5 Triple Unders. 5 rounds for time: 5 Heavy Cleans (205/155 lb), 25 Double-Unders, 25 Toes-to-Bar. Cash-out: 5 Triple Unders.",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0,
            intensity: .five,
            movementTags: ["Heavy Pull", "High Skill", "Gymnastics"],
            equipment: ["barbell", "jump rope", "pull-up bar"],
            timeDomain: "15-25 min",
            coachNotes: "Scale cleans to 185/135 lb if heavy cleans aren't in your wheelhouse. Triple unders are the buy-in/cash-out — if you can't do them, sub 15 double-unders each. Focus on smooth transitions between cleans and the jump rope. Break toes-to-bar early (7-8s) to save grip for the cleans."
        ),

        BenchmarkDefinition(
            id: "sundee-eliz",
            name: "Eliz",
            category: BenchmarkCategory.sundeeFundee.rawValue,
            workoutDescription: "5 rounds for time (25 min cap): 500m Row, 30 Crossovers (each side = 1), 100ft Farmers Carry (70/50 lb), 5 Overhead Squats (115/85 lb)",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 1,
            intensity: .four,
            movementTags: ["High Cardio", "Grip Strength"],
            equipment: ["rower", "jump rope", "dumbbells", "barbell"],
            timeDomain: "20-30 min",
            coachNotes: "Pacing is key on the row — don't redline here. Crossovers take practice; if you're still learning, scale to double-unders. Farmers carry distance is total (50ft out and back). Keep overhead squats light and focus on depth and position."
        ),

        // MARK: - Classic WODs

        BenchmarkDefinition(
            id: "classic-fg",
            name: "Fran",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 10,
            intensity: .four,
            movementTags: ["High Volume", "Glycolytic"],
            equipment: ["barbell", "pull-up bar"],
            timeDomain: "3-8 min",
            coachNotes: "The classic test of work capacity across broad time. Don't go out too hot on the first round — unbroken thrusters will burn you out fast. Break up pull-ups early if needed. The goal is consistent movement patterns throughout."
        ),

        BenchmarkDefinition(
            id: "classic-grace",
            name: "Grace",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "30 Clean and Jerks (135/95 lb) for time",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 11,
            intensity: .four,
            movementTags: ["Heavy Lift", "Olympic Lifting"],
            equipment: ["barbell"],
            timeDomain: "2-6 min",
            coachNotes: "Pure power output test. Drop and reset as needed — no touch-and-go required. Focus on solid mechanics over speed. A good rep is a safe rep."
        ),

        BenchmarkDefinition(
            id: "classic-helen",
            name: "Helen",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "3 rounds for time: 400m Run, 21 Kettlebell Swings (53/35 lb), 12 Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 12,
            intensity: .three,
            movementTags: ["Cardio", "Glycolytic"],
            equipment: ["kettlebell", "pull-up bar"],
            timeDomain: "8-15 min",
            coachNotes: "The run sets the pace — push but don't sprint. Kettlebell swings should be unbroken or 1 break max. Pull-ups are your recovery from the swings. Consistency beats intensity here."
        ),

        // MARK: - Strength

        BenchmarkDefinition(
            id: "strength-1rm",
            name: "1RM Rep Max",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Establish a 1-rep max in: Back Squat, Deadlift, Bench Press, Clean, Snatch",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 20,
            intensity: .five,
            movementTags: ["Max Effort", "Heavy"],
            equipment: ["barbell", "rack", "bench"],
            timeDomain: "30-45 min",
            coachNotes: "Take 15-20 min to build up to your max. Focus on perfect form — a PR with bad form doesn't count. Have a spotter for bench and squat. Rest 3-5 min between heavy attempts."
        ),

        BenchmarkDefinition(
            id: "strength-5rm",
            name: "5RM Rep Max",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Establish a 5-rep max in: Back Squat, Deadlift, Press, Power Clean",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 21,
            intensity: .four,
            movementTags: ["Strength", "Heavy"],
            equipment: ["barbell", "rack"],
            timeDomain: "25-35 min",
            coachNotes: "Build to a heavy 5 in 15-20 min. All 5 reps should look identical — first rep same as last. Rest 3-4 min between sets. This is about building strength, not testing it."
        ),

        // MARK: - Endurance

        BenchmarkDefinition(
            id: "endurance-5k",
            name: "5K Run",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Run 5 kilometers for time",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 30,
            intensity: .three,
            movementTags: ["Stamina", "Cardio"],
            equipment: ["running shoes"],
            timeDomain: "20-40 min",
            coachNotes: "Classic endurance test. Pacing is everything — start conservative and negative split if possible. Focus on consistent breathing and cadence. This is about testing your aerobic capacity, not sprinting."
        ),

        BenchmarkDefinition(
            id: "endurance-2k",
            name: "2K Row",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Row 2000 meters for time",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 31,
            intensity: .four,
            movementTags: ["High Cardio", "Stamina"],
            equipment: ["rower"],
            timeDomain: "7-10 min",
            coachNotes: "The classic rowing test. First 500m should feel easy — negative split your splits. Focus on leg drive and clean finish. Sprint the last 250m — leave it all on the erg."
        ),

        // MARK: - Gymnastics

        BenchmarkDefinition(
            id: "gymnastics-muscleup",
            name: "Muscle-up Max Reps",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Complete as many unbroken muscle-ups as possible",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 40,
            intensity: .four,
            movementTags: ["High Skill", "Gymnastics"],
            equipment: ["rings"],
            timeDomain: "2-5 min",
            coachNotes: "Test of skill and strength. Warm up thoroughly — false grip work, transitions, dips. Once you start, you cannot come off the rings. Rest in support if needed. Quality reps only — sloppy reps don't count."
        ),

        BenchmarkDefinition(
            id: "gymnastics-handstand",
            name: "Handstand Hold",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Hold a freestanding handstand for max time",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 41,
            intensity: .three,
            movementTags: ["Skill", "Balance"],
            equipment: ["wall", "floor"],
            timeDomain: "30-60 sec",
            coachNotes: "Test of balance and control. You may kick up against a wall, but aim for freestanding. Time stops when feet touch the ground or you lose control. Focus on tight body position — hollow body, toes pointed."
        ),

        // MARK: - General Fitness

        BenchmarkDefinition(
            id: "fitness-murph",
            name: "Murph",
            category: BenchmarkCategory.generalFitness.rawValue,
            workoutDescription: "For time: 1 Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1 Mile Run (partition pull-ups, push-ups, and squats as needed)",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 50,
            intensity: .five,
            movementTags: ["High Volume", "Endurance", "Grit"],
            equipment: ["pull-up bar", "running shoes"],
            timeDomain: "35-60 min",
            coachNotes: "The Memorial Day classic. Wear a 20/14 lb vest if you're hardcore. Partition the middle however you want — Cindy style (20 rounds of 5-10-15) is popular. This is a mental test as much as physical."
        ),

        BenchmarkDefinition(
            id: "fitness-cindy",
            name: "Cindy",
            category: BenchmarkCategory.generalFitness.rawValue,
            workoutDescription: "As many rounds as possible in 20 minutes: 5 Pull-ups, 10 Push-ups, 15 Air Squats",
            scoringType: .roundsAndReps,
            isPredefined: true,
            sortOrder: 51,
            intensity: .three,
            movementTags: ["Bodyweight", "Endurance"],
            equipment: ["pull-up bar"],
            timeDomain: "20 min",
            coachNotes: "Classic endurance test. Unbroken is the goal — scale to make it happen. This tests your ability to sustain moderate intensity over time. Consistent pace beats sprinting and resting."
        ),
    ]

    /// Get benchmarks by category
    public static func benchmarks(in category: String) -> [BenchmarkDefinition] {
        return allBenchmarks.filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get benchmark by ID
    public static func benchmark(id: String) -> BenchmarkDefinition? {
        return allBenchmarks.first { $0.id == id }
    }

    /// Get all categories
    public static let categories: [String] = [
        BenchmarkCategory.sundeeFundee.rawValue,
        BenchmarkCategory.classicWODs.rawValue,
        BenchmarkCategory.strength.rawValue,
        BenchmarkCategory.endurance.rawValue,
        BenchmarkCategory.gymnastics.rawValue,
        BenchmarkCategory.generalFitness.rawValue,
    ]
}
