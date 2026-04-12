import Testing
import Foundation
@testable import SundeeFundeeKit

struct ContentClientTests {
    @Test("MockContentClient returns bundled benchmarks")
    func testBundledBenchmarks() async throws {
        let client = MockContentClient()
        let benchmarks = try await client.fetchBenchmarks()
        #expect(!benchmarks.isEmpty)
        #expect(benchmarks.allSatisfy { $0.source == .bundled })
    }

    @Test("MockContentClient returns bundled programs")
    func testBundledPrograms() async throws {
        let client = MockContentClient()
        let programs = try await client.fetchPrograms()
        #expect(!programs.isEmpty)
        #expect(programs.allSatisfy { $0.source == .bundled })
    }

    @Test("MockContentClient returns bundled exercises")
    func testBundledExercises() async throws {
        let client = MockContentClient()
        let exercises = try await client.fetchExercises()
        #expect(!exercises.isEmpty)
        #expect(exercises.allSatisfy { $0.source == .bundled })
    }

    @Test("ContentSource enum has bundled case")
    func testContentSourceCases() {
        #expect(ContentSource.bundled.rawValue == "bundled")
    }

    @Test("ContentExercise model is properly initialized")
    func testContentExerciseModel() {
        let exercise = ContentExercise(
            id: "test-exercise",
            name: "Test Exercise",
            category: "Squat",
            bodyweight: false,
            equipment: ["barbell"],
            movementTags: ["Lower Body"],
            sortOrder: 0,
            source: .bundled
        )
        #expect(exercise.id == "test-exercise")
        #expect(exercise.name == "Test Exercise")
        #expect(exercise.category == "Squat")
        #expect(exercise.bodyweight == false)
        #expect(exercise.equipment == ["barbell"])
        #expect(exercise.movementTags == ["Lower Body"])
        #expect(exercise.sortOrder == 0)
        #expect(exercise.source == .bundled)
    }

    @Test("ContentProgram model is properly initialized")
    func testContentProgramModel() {
        let program = ContentProgram(
            id: "test-program",
            name: "Test Program",
            category: "custom",
            description: "A test program",
            durationWeeks: 4,
            sessionsPerWeek: 3,
            difficulty: "intermediate",
            phases: nil,
            sortOrder: 0,
            source: .bundled
        )
        #expect(program.id == "test-program")
        #expect(program.name == "Test Program")
        #expect(program.category == "custom")
        #expect(program.description == "A test program")
        #expect(program.durationWeeks == 4)
        #expect(program.sessionsPerWeek == 3)
        #expect(program.difficulty == "intermediate")
        #expect(program.phases == nil)
        #expect(program.sortOrder == 0)
        #expect(program.source == .bundled)
    }

    @Test("ContentBenchmark model is properly initialized")
    func testContentBenchmarkModel() {
        let benchmark = ContentBenchmark(
            id: "test-benchmark",
            name: "Test Benchmark",
            category: "Strength",
            workoutDescription: "Test description",
            scoringType: "load",
            intensity: 5,
            movementTags: ["Maximal Strength"],
            equipment: ["barbell"],
            timeDomain: "20-30 min",
            coachNotes: "Test notes",
            sortOrder: 0,
            source: .bundled
        )
        #expect(benchmark.id == "test-benchmark")
        #expect(benchmark.name == "Test Benchmark")
        #expect(benchmark.category == "Strength")
        #expect(benchmark.workoutDescription == "Test description")
        #expect(benchmark.scoringType == "load")
        #expect(benchmark.intensity == 5)
        #expect(benchmark.movementTags == ["Maximal Strength"])
        #expect(benchmark.equipment == ["barbell"])
        #expect(benchmark.timeDomain == "20-30 min")
        #expect(benchmark.coachNotes == "Test notes")
        #expect(benchmark.sortOrder == 0)
        #expect(benchmark.source == .bundled)
    }
}

struct BundledContentProviderTests {
    @Test("Bundled benchmarks match BenchmarkCatalog count")
    func testBundledBenchmarkCount() {
        let bundled = BundledContentProvider.benchmarks
        #expect(bundled.count == BenchmarkCatalog.allBenchmarks.count)
    }

    @Test("Bundled benchmarks preserve IDs")
    func testBundledBenchmarkIDs() {
        let bundled = BundledContentProvider.benchmarks
        let catalogIDs = Set(BenchmarkCatalog.allBenchmarks.map(\.id))
        let bundledIDs = Set(bundled.map(\.id))
        #expect(bundledIDs == catalogIDs)
    }

    @Test("Bundled benchmarks preserve essential fields")
    func testBundledBenchmarkFields() {
        let bundled = BundledContentProvider.benchmarks
        for (index, benchmark) in bundled.enumerated() {
            let catalog = BenchmarkCatalog.allBenchmarks[index]
            #expect(benchmark.id == catalog.id)
            #expect(benchmark.name == catalog.name)
            #expect(benchmark.category == catalog.category)
            #expect(benchmark.workoutDescription == catalog.workoutDescription)
            #expect(benchmark.scoringType == catalog.scoringType.rawValue)
            #expect(benchmark.intensity == catalog.intensity?.rawValue)
            #expect(benchmark.source == .bundled)
        }
    }

    @Test("Bundled programs match template count")
    func testBundledProgramCount() {
        let bundled = BundledContentProvider.programs
        #expect(bundled.count == ProgramTemplate.allCases.count)
    }

    @Test("Bundled programs have correct sort order")
    func testBundledProgramSortOrder() {
        let bundled = BundledContentProvider.programs
        for (index, program) in bundled.enumerated() {
            #expect(program.sortOrder == index)
        }
    }

    @Test("Bundled programs are all bundled source")
    func testBundledProgramSource() {
        let bundled = BundledContentProvider.programs
        #expect(bundled.allSatisfy { $0.source == .bundled })
    }

    @Test("Bundled exercises include weightlifting entries")
    func testBundledExercisesNotEmpty() {
        let bundled = BundledContentProvider.exercises
        #expect(bundled.count > 50)
    }

    @Test("Bundled exercises include all weightlifting exercises")
    func testBundledExercisesIncludeWeightlifting() {
        let bundled = BundledContentProvider.exercises
        let weightliftingIDs = Set(weightliftingExercises.map(\.id))
        let bundledIDs = Set(bundled.map(\.id))
        #expect(weightliftingIDs.isSubset(of: bundledIDs))
    }

    @Test("Bundled exercises include all conditioning exercises")
    func testBundledExercisesIncludeConditioning() {
        let bundled = BundledContentProvider.exercises
        let conditioningIDs = Set(conditioningExercises.map(\.id))
        let bundledIDs = Set(bundled.map(\.id))
        #expect(conditioningIDs.isSubset(of: bundledIDs))
    }

    @Test("Bundled exercises have unique IDs")
    func testBundledExerciseUniqueIDs() {
        let bundled = BundledContentProvider.exercises
        let ids = bundled.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test("Bundled exercises are all bundled source")
    func testBundledExerciseSource() {
        let bundled = BundledContentProvider.exercises
        #expect(bundled.allSatisfy { $0.source == .bundled })
    }
}
