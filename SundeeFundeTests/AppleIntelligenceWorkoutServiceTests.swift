import XCTest
import SwiftData
@testable import SundeeFundee

@MainActor
final class AppleIntelligenceWorkoutServiceTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV9.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeContext(
        focus: WorkoutFocus = .fullBody,
        timeMinutes: Int = 45,
        activeInjuries: [InjurySummary] = []
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "test-user",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [],
            recentWorkouts: [],
            cyclePhase: nil,
            readinessTier: nil,
            activeInjuries: activeInjuries,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )
    }

    // MARK: - Generation (uses OfflineWorkoutGenerator fallback on simulator)

    func testGenerateWorkoutReturnsWorkout() async throws {
        let container = try makeContainer()
        let modelContext = ModelContext(container)
        let service = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let context = makeContext()
        let workout = try await service.generateWorkout(context: context)
        XCTAssertFalse(workout.exercises.isEmpty)
        XCTAssertEqual(workout.questionnaire.focus, .fullBody)
    }

    func testGenerateWorkoutPersistsToSwiftData() async throws {
        let container = try makeContainer()
        let modelContext = ModelContext(container)
        let service = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let context = makeContext()
        _ = try await service.generateWorkout(context: context)
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>()
        let records = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(records.count, 1)
    }

    // MARK: - History & Favorites

    func testFetchHistoryReturnsGeneratedWorkouts() async throws {
        let container = try makeContainer()
        let modelContext = ModelContext(container)
        let service = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let context = makeContext()
        _ = try await service.generateWorkout(context: context)
        let history = try await service.fetchHistory(userID: "test-user")
        XCTAssertEqual(history.count, 1)
    }

    func testToggleFavoritePersists() async throws {
        let container = try makeContainer()
        let modelContext = ModelContext(container)
        let service = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let context = makeContext()
        let workout = try await service.generateWorkout(context: context)
        try await service.toggleFavorite(workoutID: workout.id, isFavorite: true)
        let favorites = try await service.fetchFavorites(userID: "test-user")
        XCTAssertEqual(favorites.count, 1)
    }

    // MARK: - Prompt Builder

    func testBuildPromptIncludesBasicParams() {
        let context = makeContext(focus: .upperBody, timeMinutes: 30)
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertTrue(prompt.contains("30-minute"))
        XCTAssertTrue(prompt.contains("Upper Body"))
        XCTAssertTrue(prompt.contains("Medium"))
        XCTAssertTrue(prompt.contains("Full Gym"))
    }

    func testBuildPromptIncludesInjuries() {
        let injury = InjurySummary(location: "Left Knee", phase: "acute", restrictions: ["No squats", "No lunges"])
        let context = makeContext(activeInjuries: [injury])
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertTrue(prompt.contains("Left Knee"))
        XCTAssertTrue(prompt.contains("No squats"))
        XCTAssertTrue(prompt.contains("IMPORTANT"))
    }

    func testBuildPromptOmitsInjurySectionWhenEmpty() {
        let context = makeContext(activeInjuries: [])
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertFalse(prompt.contains("IMPORTANT"))
    }
}
