import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDetailViewModel", .serialized)
struct BenchmarkDetailViewModelTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeFranDefinition() -> BenchmarkDefinition {
        BenchmarkDefinition(
            id: "predefined-fran",
            userID: "",
            name: "Fran",
            category: "Classic WODs",
            workoutDescription: "21-15-9: Thrusters + Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
    }

    @Test
    @MainActor
    func loadsEmptyResults() async throws {
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: container.mainContext, userID: "u1")
        #expect(vm.results.isEmpty)
        #expect(vm.bestResult == nil)
    }

    @Test
    @MainActor
    func logResultAppearsInResults() async throws {
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.logResult(scoreValue: 210.0, notes: "First attempt")
        #expect(vm.results.count == 1)
        #expect(vm.results[0].scoreValue == 210.0)
    }

    @Test
    @MainActor
    func bestResultForTimeScoringIsLowest() async throws {
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.logResult(scoreValue: 240.0, notes: "")
        vm.logResult(scoreValue: 195.0, notes: "PR")
        vm.logResult(scoreValue: 220.0, notes: "")
        #expect(vm.bestResult?.scoreValue == 195.0)
    }

    @Test
    @MainActor
    func bestResultForWeightScoringIsHighest() async throws {
        let squatDef = BenchmarkDefinition(
            id: "predefined-1rm-back-squat",
            userID: "",
            name: "1RM Back Squat",
            category: "Strength",
            workoutDescription: "Find your 1-rep max back squat.",
            scoringType: .weight,
            isPredefined: true,
            sortOrder: 10
        )
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: squatDef)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.logResult(scoreValue: 100.0, notes: "")
        vm.logResult(scoreValue: 120.0, notes: "PR")
        vm.logResult(scoreValue: 115.0, notes: "")
        #expect(vm.bestResult?.scoreValue == 120.0)
    }

    @Test
    @MainActor
    func deleteResultRemovesIt() async throws {
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.logResult(scoreValue: 210.0, notes: "")
        let result = vm.results[0]
        vm.deleteResult(result)
        #expect(vm.results.isEmpty)
    }

    @Test
    @MainActor
    func formattedScoreForTime() {
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        #expect(vm.formatted(score: 210, for: .time) == "3:30")
        #expect(vm.formatted(score: 65, for: .time) == "1:05")
        #expect(vm.formatted(score: 600, for: .time) == "10:00")
    }

    @Test
    @MainActor
    func formattedScoreForWeight() {
        let squatDef = BenchmarkDefinition(
            id: "s", userID: "", name: "1RM Back Squat", category: "Strength",
            workoutDescription: "", scoringType: .weight, isPredefined: true, sortOrder: 0
        )
        let vm = BenchmarkDetailViewModel(definition: squatDef)
        #expect(vm.formatted(score: 100, for: .weight) == "100.0 kg")
    }

    @Test
    @MainActor
    func formattedScoreForReps() {
        let cindyDef = BenchmarkDefinition(
            id: "c", userID: "", name: "Cindy", category: "Classic WODs",
            workoutDescription: "", scoringType: .reps, isPredefined: true, sortOrder: 0
        )
        let vm = BenchmarkDetailViewModel(definition: cindyDef)
        #expect(vm.formatted(score: 20, for: .reps) == "20 reps")
    }

    @Test
    @MainActor
    func formattedScoreForRoundsAndReps() {
        let def = BenchmarkDefinition(
            id: "r", userID: "", name: "AMRAP 20",
            category: "Classic WODs", workoutDescription: "",
            scoringType: .roundsAndReps, isPredefined: true, sortOrder: 0
        )
        let vm = BenchmarkDetailViewModel(definition: def)
        // 3 rounds + 19 reps = 3 * 10000 + 19 = 30019
        #expect(vm.formatted(score: 30019, for: .roundsAndReps) == "3 + 19")
        #expect(vm.formatted(score: 10000, for: .roundsAndReps) == "1 + 0")
        #expect(vm.formatted(score: 50, for: .roundsAndReps) == "0 + 50")
    }

    @Test
    @MainActor
    func bestResultForRoundsAndRepsIsHighest() async throws {
        let def = BenchmarkDefinition(
            id: "r", userID: "", name: "AMRAP 20",
            category: "Classic WODs", workoutDescription: "",
            scoringType: .roundsAndReps, isPredefined: true, sortOrder: 0
        )
        let container = try makeContainer()
        let vm = BenchmarkDetailViewModel(definition: def)
        await vm.load(modelContext: container.mainContext, userID: "u1")
        vm.logResult(scoreValue: 20019, notes: "") // 2 + 19
        vm.logResult(scoreValue: 30005, notes: "") // 3 + 5
        vm.logResult(scoreValue: 20050, notes: "") // 2 + 50
        #expect(vm.bestResult?.scoreValue == 30005)
    }
}
