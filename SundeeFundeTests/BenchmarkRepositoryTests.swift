import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDefinitionRepository", .serialized)
struct BenchmarkDefinitionRepositoryTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test
    @MainActor
    func saveAndFetch() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)
        let def = BenchmarkDefinition(userID: "u1", name: "Fran", category: "Classic WODs",
                                      workoutDescription: "21-15-9", scoringType: .time,
                                      isPredefined: false, sortOrder: 0)
        try repo.save(def)
        let results = try repo.fetchAll()
        #expect(results.count == 1)
        #expect(results[0].name == "Fran")
    }

    @Test
    @MainActor
    func fetchUserCreated() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)
        let custom = BenchmarkDefinition(userID: "u1", name: "Custom", category: "General Fitness",
                                         workoutDescription: "desc", scoringType: .reps,
                                         isPredefined: false, sortOrder: 0)
        try repo.save(custom)
        let results = try repo.fetchUserCreated(userID: "u1")
        #expect(results.count == 1)
        #expect(results[0].name == "Custom")
    }

    @Test
    @MainActor
    func deleteDef() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)
        let def = BenchmarkDefinition(userID: "u1", name: "Delete Me", category: "Strength",
                                       workoutDescription: "1RM squat", scoringType: .weight,
                                       isPredefined: false, sortOrder: 0)
        try repo.save(def)
        try repo.delete(def)
        let fetched = try repo.fetchAll()
        #expect(fetched.isEmpty)
    }
}

@Suite("BenchmarkResultRepository", .serialized)
struct BenchmarkResultRepositoryTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test
    @MainActor
    func saveAndFetchForDefinition() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkResultRepository(context: container.mainContext)
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 210.0,
                                     notes: "PR!", performedAt: .now)
        try repo.save(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.count == 1)
        #expect(fetched[0].scoreValue == 210.0)
    }

    @Test
    @MainActor
    func fetchOnlyMatchingDefinitionID() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkResultRepository(context: container.mainContext)
        try repo.save(BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 100.0))
        try repo.save(BenchmarkResult(userID: "u1", definitionID: "def-2", scoreValue: 200.0))
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.count == 1)
        #expect(fetched[0].scoreValue == 100.0)
    }

    @Test
    @MainActor
    func deleteResult() throws {
        let container = try makeContainer()
        let repo = SwiftDataBenchmarkResultRepository(context: container.mainContext)
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 180.0)
        try repo.save(result)
        try repo.delete(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.isEmpty)
    }
}
