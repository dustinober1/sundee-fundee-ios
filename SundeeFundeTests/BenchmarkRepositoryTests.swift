import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDefinition Repository")
struct BenchmarkDefinitionRepositoryTests {

    @MainActor
    private func makeRepo() throws -> SwiftDataBenchmarkDefinitionRepository {
        let schema = Schema([BenchmarkDefinition.self, BenchmarkResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)
    }

    @Test @MainActor
    func saveAndFetch() throws {
        let repo = try makeRepo()
        let def = BenchmarkDefinition(userID: "u1", name: "My WOD", category: "General Fitness",
                                      workoutDescription: "Run + burpees", scoringType: .time,
                                      isPredefined: false, sortOrder: 0)
        try repo.save(def)
        let fetched = try repo.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "My WOD")
    }

    @Test @MainActor
    func fetchUserCreated() throws {
        let repo = try makeRepo()
        let custom = BenchmarkDefinition(userID: "u1", name: "Custom", category: "General Fitness",
                                         workoutDescription: "desc", scoringType: .reps,
                                         isPredefined: false, sortOrder: 0)
        try repo.save(custom)
        let results = try repo.fetchUserCreated(userID: "u1")
        #expect(results.count == 1)
        #expect(results[0].name == "Custom")
    }

    @Test @MainActor
    func deleteDef() throws {
        let repo = try makeRepo()
        let def = BenchmarkDefinition(userID: "u1", name: "Delete Me", category: "Strength",
                                       workoutDescription: "1RM squat", scoringType: .weight,
                                       isPredefined: false, sortOrder: 0)
        try repo.save(def)
        try repo.delete(def)
        let fetched = try repo.fetchAll()
        #expect(fetched.isEmpty)
    }
}

@Suite("BenchmarkResult Repository")
struct BenchmarkResultRepositoryTests {

    @MainActor
    private func makeRepo() throws -> SwiftDataBenchmarkResultRepository {
        let schema = Schema([BenchmarkDefinition.self, BenchmarkResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return SwiftDataBenchmarkResultRepository(context: container.mainContext)
    }

    @Test @MainActor
    func saveAndFetchForDefinition() throws {
        let repo = try makeRepo()
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 210.0,
                                     notes: "PR!", performedAt: .now)
        try repo.save(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.count == 1)
        #expect(fetched[0].scoreValue == 210.0)
    }

    @Test @MainActor
    func fetchOnlyMatchingDefinitionID() throws {
        let repo = try makeRepo()
        try repo.save(BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 100.0))
        try repo.save(BenchmarkResult(userID: "u1", definitionID: "def-2", scoreValue: 200.0))
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.count == 1)
        #expect(fetched[0].scoreValue == 100.0)
    }

    @Test @MainActor
    func deleteResult() throws {
        let repo = try makeRepo()
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 180.0)
        try repo.save(result)
        try repo.delete(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.isEmpty)
    }
}
