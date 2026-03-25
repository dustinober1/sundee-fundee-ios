import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarksViewModel", .serialized)
struct BenchmarksViewModelTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV9.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test
    @MainActor
    func loadsGroupsFromCatalog() async throws {
        let container = try makeContainer()
        let vm = BenchmarksViewModel(remoteRepo: nil)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        #expect(!vm.categoryGroups.isEmpty)
        let names = vm.categoryGroups.map(\.category)
        #expect(names.contains("Classic WODs"))
        #expect(names.contains("Strength"))
    }

    @Test
    @MainActor
    func addCustomDefinitionAppearsInGroups() async throws {
        let container = try makeContainer()
        let vm = BenchmarksViewModel(remoteRepo: nil)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.addCustomDefinition(name: "My Workout", category: "General Fitness",
                               description: "Run 1 mile", scoringType: .time)
        let generalGroup = vm.categoryGroups.first { $0.category == "General Fitness" }
        #expect(generalGroup?.definitions.contains { $0.name == "My Workout" } == true)
    }

    @Test
    @MainActor
    func deleteCustomDefinitionRemovesIt() async throws {
        let container = try makeContainer()
        let vm = BenchmarksViewModel(remoteRepo: nil)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.addCustomDefinition(name: "Temp WOD", category: "General Fitness",
                               description: "Burpees", scoringType: .reps)
        let def = vm.categoryGroups.first { $0.category == "General Fitness" }?.definitions.first { $0.name == "Temp WOD" }
        #expect(def != nil)
        vm.deleteCustomDefinition(def!)
        let stillThere = vm.categoryGroups.first { $0.category == "General Fitness" }?.definitions.contains { $0.name == "Temp WOD" }
        #expect(stillThere != true)
    }

    @Test
    @MainActor
    func cannotDeletePredefinedDefinition() async throws {
        let container = try makeContainer()
        let vm = BenchmarksViewModel(remoteRepo: nil)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        let countBefore = vm.categoryGroups.flatMap(\.definitions).count
        let predefined = vm.categoryGroups.flatMap(\.definitions).first { $0.isPredefined }!
        vm.deleteCustomDefinition(predefined)
        let countAfter = vm.categoryGroups.flatMap(\.definitions).count
        #expect(countBefore == countAfter)
    }

    @Test
    @MainActor
    func loadsRemoteBenchmarks() async throws {
        let container = try makeContainer()
        let remoteDefs = [
            BenchmarkDefinition(
                id: "sf-1", userID: "", name: "Eliz",
                category: "Sundee Fundee", workoutDescription: "5 rounds",
                scoringType: .time, isPredefined: true, sortOrder: 1
            )
        ]
        let vm = BenchmarksViewModel(remoteRepo: MockRemoteBenchmarkRepo(defs: remoteDefs))
        await vm.load(modelContext: container.mainContext, userID: "u1")
        let sfGroup = vm.categoryGroups.first { $0.category == "Sundee Fundee" }
        #expect(sfGroup != nil)
        #expect(sfGroup?.definitions.first?.name == "Eliz")
    }

    @Test
    @MainActor
    func remoteBenchmarkFailureStillLoadsOthers() async throws {
        let container = try makeContainer()
        let vm = BenchmarksViewModel(remoteRepo: MockRemoteBenchmarkRepo(shouldFail: true))
        await vm.load(modelContext: container.mainContext, userID: "u1")
        #expect(!vm.categoryGroups.isEmpty)
        #expect(vm.categoryGroups.contains { $0.category == "Classic WODs" })
    }
}

private final class MockRemoteBenchmarkRepo: RemoteBenchmarkDefinitionRepository, @unchecked Sendable {
    let defs: [BenchmarkDefinition]
    let shouldFail: Bool

    init(defs: [BenchmarkDefinition] = [], shouldFail: Bool = false) {
        self.defs = defs
        self.shouldFail = shouldFail
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        if shouldFail { throw NSError(domain: "test", code: 1) }
        return defs
    }
}
