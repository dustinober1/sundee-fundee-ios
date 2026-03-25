import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiWorkoutPrompt")
struct GeminiWorkoutPromptTests {

    private func makeContext(
        timeMinutes: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energyLevel: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym,
        maxes: [ExerciseMax] = [],
        recentWorkouts: [RecentWorkoutSummary] = [],
        cyclePhase: String? = nil,
        activeInjuries: [InjurySummary] = [],
        experienceLevel: String = "intermediate",
        primaryGoal: String = "strength",
        gender: String = "female",
        weightUnit: String = "kg"
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "test",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: recentWorkouts,
            cyclePhase: cyclePhase,
            readinessTier: nil,
            activeInjuries: activeInjuries,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            gender: gender,
            weightUnit: weightUnit
        )
    }

    @Test func includesBasicParameters() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(prompt.contains("45 minutes"))
        #expect(prompt.contains("Full Body"))
        #expect(prompt.contains("medium"))
        #expect(prompt.contains("Full Gym"))
        #expect(prompt.contains("intermediate"))
        #expect(prompt.contains("strength"))
    }

    @Test func includesMaxesWhenPresent() {
        let ctx = makeContext(maxes: [ExerciseMax(name: "Back Squat", weightKg: 100)])
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("Back Squat"))
        #expect(prompt.contains("100"))
    }

    @Test func omitsMaxesSectionWhenEmpty() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(!prompt.contains("1RM Maxes"))
    }

    @Test func includesCyclePhaseWhenPresent() {
        let ctx = makeContext(cyclePhase: "luteal")
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("luteal"))
    }

    @Test func includesInjuriesWhenPresent() {
        let ctx = makeContext(activeInjuries: [InjurySummary(location: "left knee", phase: "rehab", restrictions: ["squat"])])
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("left knee"))
        #expect(prompt.contains("rehab"))
    }

    @Test func includesJSONSchemaInstruction() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(prompt.contains("coachingSummary"))
        #expect(prompt.contains("exercises"))
        #expect(prompt.contains("JSON"))
    }

    @Test func systemInstructionIsStatic() {
        let system = GeminiWorkoutPrompt.systemInstruction
        #expect(system.contains("strength and conditioning"))
        #expect(system.contains("JSON"))
    }
}
