import Foundation

// MARK: - Benchmark Catalog

/// Catalog of predefined benchmarks aligned with the current app benchmark catalog.
public struct BenchmarkCatalog {

    /// All predefined benchmarks.
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
            movementTags: ["Cardio", "Core", "Overhead Stability"],
            equipment: ["rower", "dumbbells", "barbell"],
            timeDomain: "20-25 min",
            coachNotes: "Pace the row at 85% — don't sprint it. Crossovers are sneaky grip-intensive; stay smooth. Farmers carry is active recovery, use it to breathe. OHS should be unbroken for 2-3 rounds; if you're breaking, consider scaling weight. Core fatigue is real by round 4."
        ),
        BenchmarkDefinition(
            id: "sundee-adria",
            name: "Adria",
            category: BenchmarkCategory.sundeeFundee.rawValue,
            workoutDescription: "For time (15 min cap): 3 rounds of 10 Sandbag Cleans (100/75 lb), 15 Sandbag Squats (100/75 lb). Then max distance Farmers Carry (70/50 lb).",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 2,
            intensity: .four,
            movementTags: ["Sandbag", "Grip", "Posterior Chain"],
            equipment: ["sandbag", "dumbbells"],
            timeDomain: "10-15 min",
            coachNotes: "Sandbag cleans are squat cleans — catch in the bottom and stand. Keep your chest up on squats; the bag will try to pull you forward. The farmers carry is for max distance, so don't rush the drop. Go until the grip fails, not until it gets uncomfortable."
        ),
        BenchmarkDefinition(
            id: "sundee-kelsey",
            name: "Kelsey",
            category: BenchmarkCategory.sundeeFundee.rawValue,
            workoutDescription: "3 rounds for time (20 min cap): 50 Double-Unders, 10 Handstand Push-ups, 15 Hang Power Cleans (135/95 lb), 10 Chest-to-Bar Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 3,
            intensity: .five,
            movementTags: ["High Volume", "Push/Pull", "Cardio"],
            equipment: ["jump rope", "wall", "barbell", "pull-up bar"],
            timeDomain: "15-20 min",
            coachNotes: "50 DUs is a lot — if you're not efficient, consider scaling to 35. HSPU should be unbroken round 1, then small sets. Hang power cleans at 135/95 get heavy fast; consider quick singles from round 2 onward. C2B pull-ups: break early if your cleans are slow."
        ),
        BenchmarkDefinition(
            id: "sundee-margarita",
            name: "Margarita",
            category: BenchmarkCategory.sundeeFundee.rawValue,
            workoutDescription: "20-min benchmark: Part 1 AMRAP 5 min (10 Burpees, 15 KB Swings), Part 2 1RM Squat Clean, Part 3 AMRAP 5 min (10 Burpees, 15 Russian KB Swings), Part 4 1RM Snatch",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 4,
            intensity: .five,
            movementTags: ["Hybrid", "Max Effort", "Cardio"],
            equipment: ["kettlebell", "barbell", "plates"],
            timeDomain: "20 min fixed",
            coachNotes: "This is a unique hybrid benchmark — cardio AND max strength. Part 1: push the pace but leave 1-2 reps in the tank for the clean. Part 2: You have 5 min to find a 1RM squat clean — take 2-3 attempts max. Part 3: Russian swings are easier than American, so move fast. Part 4: Snatch under fatigue is dangerous — only attempt weights you're confident in. Score each part separately."
        ),

        // MARK: - Classic WODs
        BenchmarkDefinition(
            id: "classic-fran",
            name: "Fran",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 5,
            intensity: .five,
            movementTags: ["Sprint", "Push/Pull"],
            equipment: ["barbell", "pull-up bar"],
            timeDomain: "2-8 min",
            coachNotes: "The original sprint benchmark. Go unbroken if possible. If you break the thrusters, you've gone too heavy. Pull-ups should be fast — kip hard. This should hurt from minute 1."
        ),
        BenchmarkDefinition(
            id: "classic-helen",
            name: "Helen",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 6,
            intensity: .four,
            movementTags: ["Cardio", "Posterior Chain"],
            equipment: ["kettlebell", "pull-up bar", "running space"],
            timeDomain: "8-14 min",
            coachNotes: "Pace the run at 80% — you need energy for the swings and pull-ups. KB swings should be unbroken all rounds. Break pull-ups 6-6 or 5-4-3 if needed."
        ),
        BenchmarkDefinition(
            id: "classic-grace",
            name: "Grace",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "For time: 30 Clean & Jerks (135/95 lb)",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 7,
            intensity: .four,
            movementTags: ["Heavy Push", "Barbell Cycling"],
            equipment: ["barbell"],
            timeDomain: "2-8 min",
            coachNotes: "Sprint pace. If you can go unbroken, do it. Otherwise, quick singles with no rest between reps. Power clean + push jerk is the standard. Full squat clean + split jerk is fine if that's your preference."
        ),
        BenchmarkDefinition(
            id: "classic-karen",
            name: "Karen",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 8,
            intensity: .three,
            movementTags: ["High Volume", "Squat", "Cardio"],
            equipment: ["wall ball"],
            timeDomain: "8-15 min",
            coachNotes: "Pacing is key. Start with sets of 25-30 and hold on. If you break, rest no more than 5-10 seconds. Keep the ball moving — catching and throwing should be one fluid motion."
        ),
        BenchmarkDefinition(
            id: "classic-dt",
            name: "DT",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 9,
            intensity: .five,
            movementTags: ["Heavy Pull", "Barbell Complex"],
            equipment: ["barbell"],
            timeDomain: "8-15 min",
            coachNotes: "Touch-and-go on deadlifts is huge. Hang cleans should be quick — if you're struggling, drop to singles. Push jerks: keep the bar moving. This is a grip and shoulder endurance test."
        ),
        BenchmarkDefinition(
            id: "classic-murph",
            name: "Murph",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 10,
            intensity: .five,
            movementTags: ["Endurance", "High Volume", "Hero WOD"],
            equipment: ["pull-up bar", "vest (optional)"],
            timeDomain: "35-60+ min",
            coachNotes: "Partition as 20 rounds of 5-10-15 (Cindy style) for better pacing. Without vest is still a legit attempt. The first run sets the tone — don't sprint it. Break push-ups early and often."
        ),
        BenchmarkDefinition(
            id: "classic-annie",
            name: "Annie",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "50-40-30-20-10 reps for time: Double-Unders, Sit-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 11,
            intensity: .three,
            movementTags: ["Skill", "Core"],
            equipment: ["jump rope"],
            timeDomain: "6-12 min",
            coachNotes: "If double-unders are inconsistent, this becomes a 15+ minute workout. Sub triple-unders for a challenge or tuck jumps if you don't have a rope. Sit-ups should be fast — anchor your feet if you can."
        ),
        BenchmarkDefinition(
            id: "classic-cindy",
            name: "Cindy",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.",
            scoringType: .roundsAndReps,
            isPredefined: true,
            sortOrder: 12
        ),
        BenchmarkDefinition(
            id: "classic-fight-gone-bad",
            name: "Fight Gone Bad",
            category: BenchmarkCategory.classicWODs.rawValue,
            workoutDescription: "3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20\"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 13
        ),

        // MARK: - Strength
        BenchmarkDefinition(
            id: "strength-back-squat-1rm",
            name: "1RM Back Squat",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max back squat.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 14
        ),
        BenchmarkDefinition(
            id: "strength-conventional-deadlift-1rm",
            name: "1RM Conventional Deadlift (No Straps)",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max conventional deadlift without straps.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 15
        ),
        BenchmarkDefinition(
            id: "strength-bench-press-1rm",
            name: "1RM Bench Press",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max flat barbell bench press.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 16
        ),
        BenchmarkDefinition(
            id: "strength-overhead-press-1rm",
            name: "1RM Overhead Press",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max strict barbell overhead press.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 17
        ),
        BenchmarkDefinition(
            id: "strength-clean-and-jerk-1rm",
            name: "1RM Clean and Jerk",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max clean and jerk.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 18
        ),
        BenchmarkDefinition(
            id: "strength-snatch-1rm",
            name: "1RM Snatch",
            category: BenchmarkCategory.strength.rawValue,
            workoutDescription: "Find your 1-rep max snatch.",
            scoringType: .load,
            isPredefined: true,
            sortOrder: 19
        ),

        // MARK: - Endurance
        BenchmarkDefinition(
            id: "endurance-1-mile-run",
            name: "1-Mile Run",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Run 1 mile (1.6 km) as fast as possible.",
            scoringType: .distance,
            isPredefined: true,
            sortOrder: 20
        ),
        BenchmarkDefinition(
            id: "endurance-5k-run",
            name: "5K Run",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Run 5 kilometers (3.1 miles) as fast as possible.",
            scoringType: .distance,
            isPredefined: true,
            sortOrder: 21
        ),
        BenchmarkDefinition(
            id: "endurance-1.5-mile-run",
            name: "1.5-Mile Run",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).",
            scoringType: .distance,
            isPredefined: true,
            sortOrder: 22
        ),
        BenchmarkDefinition(
            id: "endurance-2k-row",
            name: "2K Row",
            category: BenchmarkCategory.endurance.rawValue,
            workoutDescription: "Row 2000 meters on an ergometer as fast as possible.",
            scoringType: .distance,
            isPredefined: true,
            sortOrder: 23
        ),

        // MARK: - Gymnastics
        BenchmarkDefinition(
            id: "gymnastics-max-pull-ups",
            name: "Max Pull-ups",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Maximum strict pull-ups in one unbroken set.",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 24
        ),
        BenchmarkDefinition(
            id: "gymnastics-max-push-ups-2-min",
            name: "Max Push-ups (2 min)",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Maximum push-ups completed in 2 minutes.",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 25
        ),
        BenchmarkDefinition(
            id: "gymnastics-max-handstand-push-ups",
            name: "Max Handstand Push-ups",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Maximum strict handstand push-ups in one unbroken set.",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 26
        ),
        BenchmarkDefinition(
            id: "gymnastics-max-muscle-ups",
            name: "Max Muscle-ups",
            category: BenchmarkCategory.gymnastics.rawValue,
            workoutDescription: "Maximum ring or bar muscle-ups in one unbroken set.",
            scoringType: .reps,
            isPredefined: true,
            sortOrder: 27
        ),

        // MARK: - General Fitness
        BenchmarkDefinition(
            id: "fitness-100-push-ups-for-time",
            name: "100 Push-ups for Time",
            category: BenchmarkCategory.generalFitness.rawValue,
            workoutDescription: "Complete 100 push-ups as fast as possible. Rest as needed.",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 28
        ),
        BenchmarkDefinition(
            id: "fitness-100-sit-ups-for-time",
            name: "100 Sit-ups for Time",
            category: BenchmarkCategory.generalFitness.rawValue,
            workoutDescription: "Complete 100 sit-ups as fast as possible. Rest as needed.",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 29
        ),
        BenchmarkDefinition(
            id: "fitness-l-sit-hold",
            name: "L-Sit Hold",
            category: BenchmarkCategory.generalFitness.rawValue,
            workoutDescription: "Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 30
        ),
    ]

    /// Get benchmarks by category.
    public static func benchmarks(in category: String) -> [BenchmarkDefinition] {
        allBenchmarks
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get benchmark by ID.
    public static func benchmark(id: String) -> BenchmarkDefinition? {
        return allBenchmarks.first { $0.id == id }
    }

    /// Get all categories.
    public static let categories: [String] = [
        BenchmarkCategory.sundeeFundee.rawValue,
        BenchmarkCategory.classicWODs.rawValue,
        BenchmarkCategory.strength.rawValue,
        BenchmarkCategory.endurance.rawValue,
        BenchmarkCategory.gymnastics.rawValue,
        BenchmarkCategory.generalFitness.rawValue,
    ]
}
