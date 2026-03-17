import Foundation

/// Hardcoded catalog of predefined benchmark workouts shipped with the app.
///
/// Predefined entries have `userID = ""` and `isPredefined = true`.
/// User-created definitions are stored in SwiftData and merged at runtime by `BenchmarksViewModel`.
enum BenchmarkCatalog {

    // MARK: - Category Constants

    static let crossfitWOD    = "Classic WODs"
    static let strength       = "Strength"
    static let endurance      = "Endurance"
    static let gymnastics     = "Gymnastics"
    static let generalFitness = "General Fitness"

    // MARK: - Predefined Definitions

    nonisolated(unsafe) static let predefined: [BenchmarkDefinition] = {
        var entries: [BenchmarkDefinition] = []
        var order = 0

        func add(_ name: String, _ category: String, _ description: String, _ scoring: BenchmarkScoringType) {
            entries.append(BenchmarkDefinition(
                id: "predefined-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
                userID: "",
                name: name,
                category: category,
                workoutDescription: description,
                scoringType: scoring,
                isPredefined: true,
                sortOrder: order
            ))
            order += 1
        }

        // Classic WODs — Time
        add("Fran",   crossfitWOD, "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups", .time)
        add("Helen",  crossfitWOD, "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups", .time)
        add("Grace",  crossfitWOD, "For time: 30 Clean & Jerks (135/95 lb)", .time)
        add("Karen",  crossfitWOD, "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)", .time)
        add("DT",     crossfitWOD, "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)", .time)
        add("Murph",  crossfitWOD, "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.", .time)
        add("Annie",  crossfitWOD, "50-40-30-20-10 reps for time: Double-Unders, Sit-ups", .time)

        // Classic WODs — Reps/Rounds
        add("Cindy",          crossfitWOD, "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.", .reps)
        add("Fight Gone Bad", crossfitWOD, "3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20\"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.", .reps)

        // Strength — Weight (1RM)
        add("1RM Back Squat",     strength, "Find your 1-rep max back squat.", .weight)
        add("1RM Conventional Deadlift (No Straps)", strength, "Find your 1-rep max conventional deadlift without straps.", .weight)
        add("1RM Bench Press",    strength, "Find your 1-rep max flat barbell bench press.", .weight)
        add("1RM Overhead Press", strength, "Find your 1-rep max strict barbell overhead press.", .weight)
        add("1RM Clean and Jerk",   strength, "Find your 1-rep max clean and jerk.", .weight)
        add("1RM Snatch",         strength, "Find your 1-rep max snatch.", .weight)

        // Endurance — Time/Distance
        add("1-Mile Run",    endurance, "Run 1 mile (1.6 km) as fast as possible.", .distance)
        add("5K Run",        endurance, "Run 5 kilometers (3.1 miles) as fast as possible.", .distance)
        add("1.5-Mile Run",  endurance, "Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).", .distance)
        add("2K Row",        endurance, "Row 2000 meters on an ergometer as fast as possible.", .distance)

        // Gymnastics — Reps
        add("Max Pull-ups",           gymnastics, "Maximum strict pull-ups in one unbroken set.", .reps)
        add("Max Push-ups (2 min)",   gymnastics, "Maximum push-ups completed in 2 minutes.", .reps)
        add("Max Handstand Push-ups", gymnastics, "Maximum strict handstand push-ups in one unbroken set.", .reps)
        add("Max Muscle-ups",         gymnastics, "Maximum ring or bar muscle-ups in one unbroken set.", .reps)

        // General Fitness
        add("100 Push-ups for Time", generalFitness, "Complete 100 push-ups as fast as possible. Rest as needed.", .time)
        add("100 Sit-ups for Time",  generalFitness, "Complete 100 sit-ups as fast as possible. Rest as needed.", .time)
        add("L-Sit Hold",            generalFitness, "Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.", .time)

        return entries
    }()

    // MARK: - Helpers

    /// All category names in display order.
    static let categoryOrder: [String] = [crossfitWOD, strength, endurance, gymnastics, generalFitness]

    struct CategoryGroup {
        let category: String
        let entries: [BenchmarkDefinition]
    }

    /// Predefined entries grouped by category, in display order.
    static var groupedByCategory: [CategoryGroup] {
        categoryOrder.compactMap { cat in
            let entries = predefined.filter { $0.category == cat }
            guard !entries.isEmpty else { return nil }
            return CategoryGroup(category: cat, entries: entries)
        }
    }
}
