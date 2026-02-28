import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarksViewModel")
@MainActor
struct BenchmarksViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV6.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    @Test
    func loadsGroupsFromCatalog() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        #expect(!vm.categoryGroups.isEmpty)
        let names = vm.categoryGroups.map(\.category)
        #expect(names.contains("Classic WODs"))
        #expect(names.contains("Strength"))
    }

    @Test
    func addCustomDefinitionAppearsInGroups() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        vm.addCustomDefinition(name: "My Workout", category: "General Fitness",
                               description: "Run 1 mile", scoringType: .time)
        let generalGroup = vm.categoryGroups.first { $0.category == "General Fitness" }
        #expect(generalGroup?.definitions.contains { $0.name == "My Workout" } == true)
    }

    @Test
    func deleteCustomDefinitionRemovesIt() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        vm.addCustomDefinition(name: "Temp WOD", category: "General Fitness",
                               description: "Burpees", scoringType: .reps)
        let def = vm.categoryGroups.first { $0.category == "General Fitness" }?.definitions.first { $0.name == "Temp WOD" }
        #expect(def != nil)
        vm.deleteCustomDefinition(def!)
        let stillThere = vm.categoryGroups.first { $0.category == "General Fitness" }?.definitions.contains { $0.name == "Temp WOD" }
        #expect(stillThere != true)
    }

    @Test
    func cannotDeletePredefinedDefinition() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        let countBefore = vm.categoryGroups.flatMap(\.definitions).count
        let predefined = vm.categoryGroups.flatMap(\.definitions).first { $0.isPredefined }!
        vm.deleteCustomDefinition(predefined)
        let countAfter = vm.categoryGroups.flatMap(\.definitions).count
        #expect(countBefore == countAfter)
    }
}
