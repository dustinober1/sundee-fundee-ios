import Foundation

/// Provider of bundled hardcoded content as a fallback when remote content is unavailable
public struct BundledContentProvider: Sendable, ContentClientProtocol {

    public init() {}

    public func fetchExercises() async throws -> [ContentExercise] {
        Self.exercises
    }

    public func fetchPrograms() async throws -> [ContentProgram] {
        Self.programs
    }

    public func fetchBenchmarks() async throws -> [ContentBenchmark] {
        Self.benchmarks
    }

    // MARK: - Benchmarks

    /// All bundled benchmarks mapped from BenchmarkCatalog
    public static var benchmarks: [ContentBenchmark] {
        BenchmarkCatalog.allBenchmarks.map { def in
            ContentBenchmark(
                id: def.id,
                name: def.name,
                category: def.category,
                workoutDescription: def.workoutDescription,
                scoringType: def.scoringType.rawValue,
                intensity: def.intensity?.rawValue,
                movementTags: def.movementTags,
                equipment: def.equipment,
                timeDomain: def.timeDomain,
                coachNotes: def.coachNotes,
                sortOrder: def.sortOrder,
                source: .bundled
            )
        }
    }

    // MARK: - Programs

    /// Display names for program templates
    private static let templateDisplayNames: [ProgramTemplate: String] = [
        .strength: "Strength Basics",
        .hypertrophy: "Hypertrophy Phase",
        .fullBody: "Full Body Split",
        .linear: "Linear Progression",
        .dup: "Daily Undulating Periodization",
        .block: "Block Periodization"
    ]

    /// All bundled programs generated from ProgramTemplate templates
    public static var programs: [ContentProgram] {
        ProgramTemplate.allCases.enumerated().map { index, template in
            let displayName = templateDisplayNames[template] ?? template.rawValue.capitalized
            let generated = generateProgram(template: template, name: displayName)

            // Note: phases are not encoded to JSON since GeneratedProgramPhase is not Codable
            // The full program data can be regenerated using generateProgram() when needed
            return ContentProgram(
                id: generated.id,
                name: generated.name,
                category: generated.category,
                description: generated.description,
                durationWeeks: generated.durationWeeks,
                sessionsPerWeek: generated.sessionsPerWeek,
                difficulty: generated.difficulty,
                phases: nil,
                sortOrder: index,
                source: .bundled
            )
        }
    }

    // MARK: - Exercises

    /// All bundled exercises combining weightlifting and conditioning catalogs
    public static var exercises: [ContentExercise] {
        let weightlifting = weightliftingExercises.enumerated().map { index, entry in
            ContentExercise(
                id: entry.id,
                name: entry.id,
                category: entry.category.rawValue,
                bodyweight: false,
                equipment: ["barbell"], // Most weightlifting exercises use barbells
                movementTags: nil,
                sortOrder: index,
                source: .bundled
            )
        }

        let conditioning = conditioningExercises.enumerated().map { index, entry in
            ContentExercise(
                id: entry.id,
                name: entry.id,
                category: "Conditioning",
                bodyweight: entry.defaultScoringType == .reps, // Rep-based exercises are often bodyweight
                equipment: nil,
                movementTags: nil,
                sortOrder: weightlifting.count + index,
                source: .bundled
            )
        }

        return weightlifting + conditioning
    }
}
