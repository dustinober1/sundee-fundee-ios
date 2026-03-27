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
        XCTAssertTrue(prompt.contains("4-6 exercises"))
        XCTAssertTrue(prompt.contains("strength"))
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

    // MARK: - Equipment Constraints

    func testBuildPromptBodyweightOnlyIncludesCriticalConstraint() {
        let context = WorkoutGenerationContext(
            userID: "test-user", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
            equipment: .bodyweightOnly, maxes: [], recentWorkouts: [], cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "intermediate",
            primaryGoal: "strength", gender: "female", weightUnit: "kg"
        )
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertTrue(prompt.contains("CRITICAL"))
        XCTAssertTrue(prompt.contains("NO barbells"))
        XCTAssertTrue(prompt.contains("NO dumbbells"))
    }

    func testEquipmentConstraintFullGymNotCritical() {
        let constraint = AppleIntelligenceWorkoutService.equipmentConstraint(for: .fullGym)
        XCTAssertFalse(constraint.contains("CRITICAL"))
    }

    func testEquipmentConstraintOutdoorExcludesAllEquipment() {
        let constraint = AppleIntelligenceWorkoutService.equipmentConstraint(for: .outdoor)
        XCTAssertTrue(constraint.contains("CRITICAL"))
        XCTAssertTrue(prompt(for: .outdoor).contains("NO barbells"))
        XCTAssertTrue(prompt(for: .outdoor).contains("NO dumbbells"))
    }

    // MARK: - Focus Constraints

    func testFocusConstraintUpperBodyExcludesLegs() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .upperBody)
        XCTAssertTrue(constraint.contains("NO squats"))
        XCTAssertTrue(constraint.contains("NO deadlifts"))
    }

    func testFocusConstraintLowerBodyExcludesUpperBody() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .lowerBody)
        XCTAssertTrue(constraint.contains("NO bench press"))
        XCTAssertTrue(constraint.contains("NO shoulder press"))
    }

    func testFocusConstraintFullBodyIsMixed() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .fullBody)
        XCTAssertTrue(constraint.lowercased().contains("mix"))
    }

    func testFocusConstraintCoreExcludesHeavyLifts() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .core)
        XCTAssertTrue(constraint.contains("ONLY core"))
    }

    func testFocusConstraintPushExcludesPulling() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .push)
        XCTAssertTrue(constraint.contains("NO pulling"))
    }

    func testFocusConstraintPullExcludesPressing() {
        let constraint = AppleIntelligenceWorkoutService.focusConstraint(for: .pull)
        XCTAssertTrue(constraint.contains("NO pressing"))
    }

    // MARK: - Experience Constraints

    func testExperienceConstraintBeginnerExcludesAdvanced() {
        let constraint = AppleIntelligenceWorkoutService.experienceConstraint(for: "beginner")
        XCTAssertTrue(constraint.contains("no Olympic lifts"))
        XCTAssertTrue(constraint.contains("no muscle-ups"))
    }

    func testExperienceConstraintAdvancedAllowsComplex() {
        let constraint = AppleIntelligenceWorkoutService.experienceConstraint(for: "advanced")
        XCTAssertTrue(constraint.contains("Olympic lifts"))
    }

    // MARK: - Energy Constraints

    func testEnergyConstraintLowReducesIntensity() {
        let constraint = AppleIntelligenceWorkoutService.energyConstraint(for: .low)
        XCTAssertTrue(constraint.contains("fewer sets"))
        XCTAssertTrue(constraint.contains("Avoid heavy"))
    }

    func testEnergyConstraintHighPushesIntensity() {
        let constraint = AppleIntelligenceWorkoutService.energyConstraint(for: .high)
        XCTAssertTrue(constraint.contains("heavy compounds"))
    }

    // MARK: - Exercise Count

    func testExerciseCountRangeFor30Minutes() {
        XCTAssertEqual(AppleIntelligenceWorkoutService.exerciseCountRange(for: 30), "4-6")
    }

    func testExerciseCountRangeFor45Minutes() {
        XCTAssertEqual(AppleIntelligenceWorkoutService.exerciseCountRange(for: 45), "5-8")
    }

    func testExerciseCountRangeFor60Minutes() {
        XCTAssertEqual(AppleIntelligenceWorkoutService.exerciseCountRange(for: 60), "6-9")
    }

    func testExerciseCountRangeFor75Minutes() {
        XCTAssertEqual(AppleIntelligenceWorkoutService.exerciseCountRange(for: 75), "8-12")
    }

    // MARK: - Cycle Phase Guidance

    func testCyclePhaseGuidanceMenstrual() {
        let guidance = AppleIntelligenceWorkoutService.cyclePhaseGuidance(for: "menstrual")
        XCTAssertTrue(guidance.contains("reduce intensity"))
    }

    func testCyclePhaseGuidanceOvulation() {
        let guidance = AppleIntelligenceWorkoutService.cyclePhaseGuidance(for: "ovulation")
        XCTAssertTrue(guidance.contains("peak strength"))
    }

    func testCyclePhaseGuidanceIncludedInPrompt() {
        let context = WorkoutGenerationContext(
            userID: "test-user", timeMinutes: 45, focus: .fullBody, energyLevel: .medium,
            equipment: .fullGym, maxes: [], recentWorkouts: [], cyclePhase: "menstrual",
            readinessTier: nil, activeInjuries: [], experienceLevel: "intermediate",
            primaryGoal: "strength", gender: "female", weightUnit: "kg"
        )
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertTrue(prompt.contains("Menstrual phase"))
    }

    func testNoCyclePhaseOmitsGuidance() {
        let context = makeContext()
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertFalse(prompt.contains("phase:"))
    }

    // MARK: - Recent Workouts

    func testRecentWorkoutsIncludedInPrompt() {
        let recent = [RecentWorkoutSummary(date: .now, focus: "upper_body", exercises: [], durationMinutes: 45)]
        let context = WorkoutGenerationContext(
            userID: "test-user", timeMinutes: 45, focus: .lowerBody, energyLevel: .medium,
            equipment: .fullGym, maxes: [], recentWorkouts: recent, cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "intermediate",
            primaryGoal: "strength", gender: "female", weightUnit: "kg"
        )
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        XCTAssertTrue(prompt.contains("Recent workouts"))
        XCTAssertTrue(prompt.contains("avoid repetition"))
    }

    // MARK: - Helpers

    private func prompt(for equipment: EquipmentAccess) -> String {
        let context = WorkoutGenerationContext(
            userID: "test-user", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
            equipment: equipment, maxes: [], recentWorkouts: [], cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "intermediate",
            primaryGoal: "strength", gender: "female", weightUnit: "kg"
        )
        return AppleIntelligenceWorkoutService.buildPrompt(context: context)
    }
}
