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

    /// All bundled programs generated from ProgramTemplate templates
    public static var programs: [ContentProgram] {
        ProgramTemplate.allCases.enumerated().map { index, template in
            let generated = generateProgram(template: template, name: template.displayName)

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
                printablePDFURL: template.printablePDFURL,
                sortOrder: index,
                source: .bundled
            )
        }
    }

    // MARK: - Exercises

    /// All bundled exercises from the general training catalog.
    public static var exercises: [ContentExercise] {
        trainingExerciseCatalog.enumerated().map { index, entry in
            ContentExercise(
                id: entry.id,
                name: entry.id,
                category: entry.categoryLabel,
                bodyweight: entry.bodyweightOnly,
                equipment: entry.equipmentTags.map(\.rawValue),
                movementTags: [entry.movementPattern.rawValue],
                sortOrder: index,
                source: .bundled
            )
        }
    }
}
