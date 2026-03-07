import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiPromptBuilder")
struct GeminiPromptBuilderTests {

    // MARK: - Helpers

    private func makeContext(
        timeMinutes: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energyLevel: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym,
        maxes: [ExerciseMax] = [],
        recentWorkouts: [RecentWorkoutSummary] = [],
        cyclePhase: String? = nil,
        readinessTier: String? = nil,
        injuries: [InjurySummary] = [],
        experienceLevel: String = "intermediate",
        primaryGoal: String = "strength",
        gender: String = "female",
        weightUnit: String = "kg"
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: recentWorkouts,
            cyclePhase: cyclePhase,
            readinessTier: readinessTier,
            activeInjuries: injuries,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            gender: gender,
            weightUnit: weightUnit,
            desiredSkills: [],
            benchmarkSummaries: [],
            bodyWeightKg: nil,
            recentPainActivity: [],
            workoutCompletionRate: nil
        )
    }

    // MARK: - System Prompt

    @Test func systemPromptIsNotEmpty() {
        #expect(!GeminiPromptBuilder.systemPrompt.isEmpty)
    }

    @Test func systemPromptContainsCoachingGuidance() {
        let prompt = GeminiPromptBuilder.systemPrompt
        #expect(prompt.contains("compound movements"))
        #expect(prompt.contains("injury restrictions"))
        #expect(prompt.contains("menstrual cycle phase"))
        #expect(prompt.contains("energy level"))
        #expect(prompt.contains("recent workouts"))
        #expect(prompt.contains("working weights"))
        #expect(prompt.contains("reasoning"))
        #expect(prompt.contains("coaching summary"))
    }

    // MARK: - User Prompt Basics

    @Test func userPromptContainsFocusAndDuration() {
        let context = makeContext(timeMinutes: 60, focus: .upperBody)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Upper Body"))
        #expect(prompt.contains("60"))
    }

    @Test func userPromptContainsEnergyLevel() {
        let context = makeContext(energyLevel: .high)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("high"))
    }

    @Test func userPromptContainsEquipment() {
        let context = makeContext(equipment: .homeDumbbells)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Home Dumbbells"))
    }

    @Test func userPromptContainsExperienceAndGoal() {
        let context = makeContext(experienceLevel: "beginner", primaryGoal: "hypertrophy")
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("beginner"))
        #expect(prompt.contains("hypertrophy"))
    }

    @Test func userPromptContainsWeightUnit() {
        let context = makeContext(weightUnit: "lbs")
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("lbs"))
    }

    // MARK: - Maxes

    @Test func userPromptIncludesMaxes() {
        let maxes = [
            ExerciseMax(name: "Back Squat", weightLb: 100),
            ExerciseMax(name: "Bench Press", weightLb: 80)
        ]
        let context = makeContext(maxes: maxes)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Back Squat"))
        #expect(prompt.contains("100"))
        #expect(prompt.contains("Bench Press"))
        #expect(prompt.contains("80"))
        #expect(prompt.contains("Prefer programming exercises the athlete has maxes for"))
    }

    @Test func userPromptOmitsMaxesSectionWhenEmpty() {
        let context = makeContext(maxes: [])
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(!prompt.contains("Known Maxes"))
    }

    // MARK: - Cycle Phase

    @Test func userPromptIncludesCyclePhaseWhenPresent() {
        let context = makeContext(cyclePhase: "follicular", readinessTier: "high")
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("follicular"))
        #expect(prompt.contains("high"))
    }

    @Test func userPromptOmitsCycleSectionWhenNil() {
        let context = makeContext(cyclePhase: nil, readinessTier: nil)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(!prompt.contains("Cycle Phase"))
    }

    @Test func userPromptIncludesCyclePhaseWithNilReadiness() {
        let context = makeContext(cyclePhase: "luteal", readinessTier: nil)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("luteal"))
        #expect(!prompt.contains("Readiness"))
    }

    // MARK: - Injuries

    @Test func userPromptIncludesInjuries() {
        let injuries = [
            InjurySummary(location: "knee", phase: "rehab", restrictions: ["squat", "lunge"])
        ]
        let context = makeContext(injuries: injuries)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("knee"))
        #expect(prompt.contains("rehab"))
        #expect(prompt.contains("squat"))
        #expect(prompt.contains("lunge"))
    }

    @Test func userPromptOmitsInjurySectionWhenEmpty() {
        let context = makeContext(injuries: [])
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(!prompt.contains("Active Injuries"))
    }

    // MARK: - Recent Workouts

    @Test func userPromptIncludesRecentWorkouts() {
        let workouts = [
            RecentWorkoutSummary(
                date: Date(timeIntervalSince1970: 1_000_000),
                focus: "upper_body",
                exercises: ["Bench Press", "Pull-Up"],
                durationMinutes: 50
            )
        ]
        let context = makeContext(recentWorkouts: workouts)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Bench Press"))
        #expect(prompt.contains("Pull-Up"))
        #expect(prompt.contains("upper_body"))
    }

    @Test func userPromptOmitsRecentWorkoutsSectionWhenEmpty() {
        let context = makeContext(recentWorkouts: [])
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(!prompt.contains("Recent Workouts"))
    }

    @Test func userPromptLimitsRecentWorkoutsToFive() {
        let workouts = (1...8).map { i in
            RecentWorkoutSummary(
                date: Date(timeIntervalSince1970: Double(i) * 100_000),
                focus: "full_body",
                exercises: ["Exercise\(i)"],
                durationMinutes: 45
            )
        }
        let context = makeContext(recentWorkouts: workouts)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Exercise1"))
        #expect(prompt.contains("Exercise5"))
        #expect(!prompt.contains("Exercise6"))
    }

    // MARK: - Response Schema

    @Test func responseSchemaContainsRequiredTopLevelKeys() {
        let schema = GeminiPromptBuilder.responseSchema
        #expect(schema["type"] as? String == "object")

        let properties = schema["properties"] as? [String: Any]
        #expect(properties != nil)
        #expect(properties?["coachingSummary"] != nil)
        #expect(properties?["exercises"] != nil)

        let required = schema["required"] as? [String]
        #expect(required?.contains("coachingSummary") == true)
        #expect(required?.contains("exercises") == true)
    }

    @Test func responseSchemaExercisesIsArray() {
        let schema = GeminiPromptBuilder.responseSchema
        let properties = schema["properties"] as? [String: Any]
        let exercises = properties?["exercises"] as? [String: Any]
        #expect(exercises?["type"] as? String == "array")

        let items = exercises?["items"] as? [String: Any]
        #expect(items?["type"] as? String == "object")

        let itemProps = items?["properties"] as? [String: Any]
        #expect(itemProps?["name"] != nil)
        #expect(itemProps?["sets"] != nil)
        #expect(itemProps?["reps"] != nil)
        #expect(itemProps?["weightLb"] != nil)
        #expect(itemProps?["restMinutes"] != nil)
        #expect(itemProps?["notes"] != nil)
        #expect(itemProps?["reasoning"] != nil)
        #expect(itemProps?["bodyweightOnly"] != nil)
    }

    @Test func responseSchemaExerciseRequiredFields() {
        let schema = GeminiPromptBuilder.responseSchema
        let properties = schema["properties"] as? [String: Any]
        let exercises = properties?["exercises"] as? [String: Any]
        let items = exercises?["items"] as? [String: Any]
        let required = items?["required"] as? [String]

        #expect(required?.contains("name") == true)
        #expect(required?.contains("sets") == true)
        #expect(required?.contains("reps") == true)
        #expect(required?.contains("bodyweightOnly") == true)
    }

    // MARK: - Gender in prompt

    @Test func userPromptIncludesGender() {
        let context = makeContext(gender: "male")
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("male"))
    }

    // MARK: - All focus types produce valid prompts

    @Test func allFocusTypesIncluded() {
        for focus in WorkoutFocus.allCases {
            let context = makeContext(focus: focus)
            let prompt = GeminiPromptBuilder.userPrompt(from: context)
            #expect(prompt.contains(focus.displayName))
        }
    }

    // MARK: - All equipment types produce valid prompts

    @Test func allEquipmentTypesIncluded() {
        for equipment in EquipmentAccess.allCases {
            let context = makeContext(equipment: equipment)
            let prompt = GeminiPromptBuilder.userPrompt(from: context)
            #expect(prompt.contains(equipment.displayName))
        }
    }

    // MARK: - All energy levels produce valid prompts

    @Test func allEnergyLevelsIncluded() {
        for energy in EnergyLevel.allCases {
            let context = makeContext(energyLevel: energy)
            let prompt = GeminiPromptBuilder.userPrompt(from: context)
            #expect(prompt.contains(energy.rawValue))
        }
    }

    // MARK: - Multiple injuries

    @Test func userPromptIncludesMultipleInjuries() {
        let injuries = [
            InjurySummary(location: "knee", phase: "rehab", restrictions: ["squat"]),
            InjurySummary(location: "shoulder", phase: "acute", restrictions: ["press", "overhead"])
        ]
        let context = makeContext(injuries: injuries)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("knee"))
        #expect(prompt.contains("shoulder"))
        #expect(prompt.contains("press"))
        #expect(prompt.contains("overhead"))
    }
}
