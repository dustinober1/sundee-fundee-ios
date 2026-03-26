# Apple Intelligence Workout Generation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Gemini-based AI workout generation with Apple Foundation Models (on-device), remove server dependency and usage tracking from the iOS app.

**Architecture:** On-device LLM generates exercise selections via `@Generable` structured output. A new `WorkoutPostProcessor` applies deterministic personalization (weights, cycle phase, energy). `OfflineWorkoutGenerator` serves as fallback when Apple Intelligence is unavailable. Cloudflare Worker remains for WOD Dashboard only.

**Tech Stack:** Swift 6, SwiftUI, Foundation Models framework (iOS 26), SwiftData

**Spec:** `docs/superpowers/specs/2026-03-25-apple-intelligence-workout-generation-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `SundeeFundee/Domain/AIWorkout/AIWorkoutOutput.swift` | `@Generable` types for Foundation Models structured output |
| `SundeeFundee/Domain/AIWorkout/WorkoutPostProcessor.swift` | Deterministic post-processing: weights, rest, energy, cycle phase, coaching summary |
| `SundeeFundee/Repositories/AIWorkout/AppleIntelligenceWorkoutService.swift` | `AIWorkoutServiceProtocol` implementation using Foundation Models + fallback. Also hosts `AIWorkoutServiceError` enum (moved from deleted file). |
| `SundeeFundeTests/WorkoutPostProcessorTests.swift` | Tests for all post-processing logic |
| `SundeeFundeTests/AppleIntelligenceWorkoutServiceTests.swift` | Tests for new service (fallback path + prompt builder + persistence) |

### Deleted Files
| File | Reason |
|------|--------|
| `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` | Contains `SwiftDataAIWorkoutService` + `GeminiResponseParser` + `AIWorkoutServiceError`, all replaced |
| `SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift` | Replaced by simplified prompt in new service |
| `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift` | Replaced by `@Generable` types |
| `SundeeFundee/Domain/Subscription/AIUsageTracker.swift` | No usage limits |
| `SundeeFundeTests/GeminiWorkoutPromptTests.swift` | Tests for deleted code |
| `SundeeFundeTests/AIWorkoutServiceRemoteTests.swift` | Tests for deleted code |
| `SundeeFundeTests/RemoteWorkoutResponseTests.swift` | Tests for deleted code |

### Modified Files
| File | What Changes |
|------|-------------|
| `project.yml:4-5,12,27,73` | Deployment target 17.0 -> 26.0 (four places) |
| `SundeeFundee/Packages/SundeeFundeeShared/Package.swift:7` | `.iOS(.v17)` -> `.iOS(.v26)` |
| `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift:28-57` | Remove usage tracking, remove `tier` param, simplify `generateWorkout()` |
| `SundeeFundee/Features/AIWorkout/QuestionnaireView.swift:38-40,137-148,152` | Remove paywall sheet, upgrade button, update `generateWorkout` call site |
| `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift:24` | Switch to `AppleIntelligenceWorkoutService` |
| `SundeeFundee/Features/Dashboard/DashboardView.swift:736-784` | Remove usage display from AI CTA card |
| `SundeeFundee/Features/Subscription/ManageSubscriptionView.swift:50-64` | Remove AI usage section and its reference from `body` |
| `SundeeFundee/Domain/Subscription/FeatureEntitlement.swift:50-68` | Remove `aiWorkoutLimit`, `aiWorkoutsRemaining`, `canGenerateAIWorkout` |
| `SundeeFundeTests/SubscriptionTests.swift:79-120,174-253,482-490` | Remove AIUsageTracker tests, AI entitlement tests, CTA card static tests |
| `SundeeFundeTests/AIWorkoutTests.swift` | Remove Gemini-specific assertions |
| `SundeeFundeTests/AIWorkoutViewModelTests.swift` | Remove usage tracking tests |
| `SundeeFundeTests/DashboardViewCoverageTests.swift` | Update AIWorkoutCTACard rendering test after usage display removal |

---

### Task 1: Bump Deployment Target to iOS 26

**Files:**
- Modify: `project.yml:4-5,12,27,73`
- Modify: `SundeeFundee/Packages/SundeeFundeeShared/Package.swift:7`

- [ ] **Step 1: Update project.yml deployment targets**

Change all four locations from `"17.0"` to `"26.0"`:

```yaml
# Line 4-5
deploymentTarget:
  iOS: "26.0"

# Line 12
IPHONEOS_DEPLOYMENT_TARGET: "26.0"

# Line 27 (SundeeFundee target)
deploymentTarget: "26.0"

# Line 73 (SundeeFundeTests target)
deploymentTarget: "26.0"
```

- [ ] **Step 2: Update SundeeFundeeShared Package.swift**

```swift
// Line 7: change .v17 to .v26
platforms: [.iOS(.v26), .macOS(.v14)],
```

- [ ] **Step 3: Regenerate Xcode project**

Run: `xcodegen generate`
Expected: `Created project at .../SundeeFundee.xcodeproj`

- [ ] **Step 4: Commit**

```bash
git add project.yml SundeeFundee/Packages/SundeeFundeeShared/Package.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "chore: bump deployment target to iOS 26 for Foundation Models"
```

---

### Task 2: Create AIWorkoutOutput @Generable Types

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/AIWorkoutOutput.swift`

- [ ] **Step 1: Create the @Generable types**

```swift
import FoundationModels

@Generable
struct AIWorkoutOutput: Sendable {
    @Guide(description: "Short motivational coaching note for the workout")
    var coachingSummary: String

    @Guide(description: "List of exercises for the workout")
    var exercises: [AIExerciseOutput]
}

@Generable
struct AIExerciseOutput: Sendable {
    @Guide(description: "Exercise name, e.g. Barbell Back Squat")
    var name: String

    @Guide(description: "Number of sets, typically 3-5")
    var sets: Int

    @Guide(description: "Rep scheme: a number like '5', a range like '8-10', or 'AMRAP'")
    var reps: String

    @Guide(description: "True if this exercise uses no equipment")
    var bodyweightOnly: Bool

    @Guide(description: "Optional coaching note for form or technique")
    var notes: String?
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run: `xcodegen generate`

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/AIWorkoutOutput.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add @Generable types for Foundation Models workout output"
```

---

### Task 3: Create WorkoutPostProcessor with Tests (TDD)

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/WorkoutPostProcessor.swift`
- Create: `SundeeFundeTests/WorkoutPostProcessorTests.swift`
- Reference: `SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift:177-359` (logic to extract)

- [ ] **Step 1: Write failing tests**

Create `SundeeFundeTests/WorkoutPostProcessorTests.swift`:

```swift
import XCTest
@testable import SundeeFundee

final class WorkoutPostProcessorTests: XCTestCase {

    // MARK: - Helpers

    private func makeRawOutput(exercises: [AIExerciseOutput] = [
        AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil),
        AIExerciseOutput(name: "Push-Up", sets: 3, reps: "12-15", bodyweightOnly: true, notes: nil)
    ], coachingSummary: String = "Great workout ahead!") -> AIWorkoutOutput {
        AIWorkoutOutput(coachingSummary: coachingSummary, exercises: exercises)
    }

    private func makeContext(
        maxes: [ExerciseMax] = [],
        energyLevel: EnergyLevel = .medium,
        cyclePhase: String? = nil,
        readinessTier: String? = nil,
        focus: WorkoutFocus = .fullBody,
        timeMinutes: Int = 45,
        equipment: EquipmentAccess = .fullGym,
        activeInjuries: [InjurySummary] = []
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "test-user",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: [],
            cyclePhase: cyclePhase,
            readinessTier: readinessTier,
            activeInjuries: activeInjuries,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )
    }

    // MARK: - Weight Calculation

    func testWeightAppliedFromMaxes() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Barbell Back Squat", weightKg: 100)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        // 5 reps -> 0.80 percentage -> 80kg -> rounded to nearest 5 = 80
        XCTAssertEqual(result.exercises.first?.weightKg, 80.0)
    }

    func testNoMaxesMeansNilWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertNil(result.exercises.first?.weightKg)
    }

    func testBodyweightExerciseGetsNilWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: "12-15", bodyweightOnly: true, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Push-Up", weightKg: 50)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertNil(result.exercises.first?.weightKg)
    }

    func testFuzzyNameMatching() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Bench Press", sets: 4, reps: "8-10", bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Flat Barbell Bench Press", weightKg: 100)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        // "Bench Press" contained in "Flat Barbell Bench Press" (case-insensitive)
        // 8-10 reps -> 0.70 percentage -> 70kg
        XCTAssertEqual(result.exercises.first?.weightKg, 70.0)
    }

    func testDefaultPercentageForVariousRepRanges() {
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "3"), 0.85)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "5"), 0.80)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "8-10"), 0.70)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "12-15"), 0.65)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "AMRAP"), 0.60)
    }

    // MARK: - Rest Periods

    func testRestPeriodsAssignedByRepRange() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Curl", sets: 3, reps: "12-15", bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises[0].restMinutes, 2.5)
        XCTAssertEqual(result.exercises[1].restMinutes, 1.5)
    }

    func testBodyweightRestPeriod() {
        XCTAssertEqual(WorkoutPostProcessor.assignRestMinutes(reps: "10", bodyweight: true), 1.0)
    }

    // MARK: - Energy Level

    func testLowEnergyReducesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let mediumContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .medium)
        let lowContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .low)
        let mediumResult = WorkoutPostProcessor.process(raw: raw, context: mediumContext)
        let lowResult = WorkoutPostProcessor.process(raw: raw, context: lowContext)
        XCTAssertLessThan(lowResult.exercises.first!.weightKg!, mediumResult.exercises.first!.weightKg!)
    }

    func testHighEnergyIncreasesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let mediumContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .medium)
        let highContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .high)
        let mediumResult = WorkoutPostProcessor.process(raw: raw, context: mediumContext)
        let highResult = WorkoutPostProcessor.process(raw: raw, context: highContext)
        XCTAssertGreaterThan(highResult.exercises.first!.weightKg!, mediumResult.exercises.first!.weightKg!)
    }

    func testEnergyMultiplierValues() {
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .low), 85.0)
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .medium), 100.0)
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .high), 105.0)
    }

    // MARK: - Cycle Phase

    func testMenstrualPhaseReducesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let menstrual = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "menstrual")
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let menstrualResult = WorkoutPostProcessor.process(raw: raw, context: menstrual)
        XCTAssertLessThan(menstrualResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testOvulationPhaseIncreasesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let ovulation = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "ovulation")
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let ovulationResult = WorkoutPostProcessor.process(raw: raw, context: ovulation)
        XCTAssertGreaterThan(ovulationResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testNilCyclePhaseAppliesNoAdjustment() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: "5", bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let noCycle = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: nil)
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let noCycleResult = WorkoutPostProcessor.process(raw: raw, context: noCycle)
        XCTAssertEqual(noCycleResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testCyclePhaseMultiplierValues() {
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "menstrual", readiness: nil), 90.0)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: nil), 100.0)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "ovulation", readiness: nil), 112.0)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "luteal", readiness: nil), 97.0)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: nil, readiness: nil), 100.0)
    }

    func testReadinessMultiplier() {
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: "low"), 85.0)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: "high"), 110.0)
    }

    // MARK: - Coaching Summary

    func testCoachingSummaryEnrichedWithMenstrualPhase() {
        let raw = makeRawOutput()
        let context = makeContext(cyclePhase: "menstrual")
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.lowercased().contains("menstrual"))
    }

    func testCoachingSummaryIncludesLowEnergyNote() {
        let raw = makeRawOutput()
        let context = makeContext(energyLevel: .low)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.contains("low energy"))
    }

    func testCoachingSummaryIncludesHighEnergyNote() {
        let raw = makeRawOutput()
        let context = makeContext(energyLevel: .high)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.contains("high energy"))
    }

    func testCoachingSummaryMediumEnergyNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    func testCoachingSummaryFollicularPhaseNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium, cyclePhase: "follicular")
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    func testCoachingSummaryNilPhaseNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium, cyclePhase: nil)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    // MARK: - Output Mapping

    func testOutputMapsToGeneratedWorkout() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.count, 2)
        XCTAssertFalse(result.id.isEmpty)
        XCTAssertEqual(result.questionnaire.focus, .fullBody)
        XCTAssertEqual(result.questionnaire.timeMinutes, 45)
        XCTAssertEqual(result.isFavorite, false)
    }

    func testEachExerciseGetsUniqueID() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        let ids = result.exercises.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testExerciseNotesPassedThrough() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 3, reps: "5", bodyweightOnly: false, notes: "Keep chest up")
        ])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.first?.notes, "Keep chest up")
    }

    func testReasoningIsAlwaysNil() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.exercises.allSatisfy { $0.reasoning == nil })
    }

    // MARK: - Edge Cases

    func testEmptyExercisesArrayProducesEmptyWorkout() {
        let raw = makeRawOutput(exercises: [])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.exercises.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/WorkoutPostProcessorTests 2>&1 | tail -10`
Expected: Compilation failure -- `WorkoutPostProcessor` not found

- [ ] **Step 3: Implement WorkoutPostProcessor**

Create `SundeeFundee/Domain/AIWorkout/WorkoutPostProcessor.swift`:

```swift
import Foundation

enum WorkoutPostProcessor {

    static func process(
        raw: AIWorkoutOutput,
        context: WorkoutGenerationContext
    ) -> GeneratedWorkout {
        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        let exercises = raw.exercises.map { aiExercise in
            var weightKg = calculateWeight(
                exerciseName: aiExercise.name,
                reps: aiExercise.reps,
                bodyweightOnly: aiExercise.bodyweightOnly,
                maxes: context.maxes
            )

            if let w = weightKg {
                weightKg = applyEnergyMultiplier(w, energy: context.energyLevel)
                weightKg = applyCyclePhaseMultiplier(weightKg!, phase: context.cyclePhase, readiness: context.readinessTier)
                weightKg = WeightCalculations.roundToNearestFive(weightKg!)
            }

            let restMinutes = assignRestMinutes(reps: aiExercise.reps, bodyweight: aiExercise.bodyweightOnly)

            return GeneratedExercise(
                name: aiExercise.name,
                sets: aiExercise.sets,
                reps: aiExercise.reps,
                weightKg: weightKg,
                restMinutes: restMinutes,
                notes: aiExercise.notes,
                reasoning: nil,
                bodyweightOnly: aiExercise.bodyweightOnly
            )
        }

        let enrichedSummary = enrichCoachingSummary(
            base: raw.coachingSummary,
            energy: context.energyLevel,
            cyclePhase: context.cyclePhase
        )

        return GeneratedWorkout(
            createdAt: Date(),
            coachingSummary: enrichedSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )
    }

    // MARK: - Weight Calculation

    private static func calculateWeight(
        exerciseName: String,
        reps: String,
        bodyweightOnly: Bool,
        maxes: [ExerciseMax]
    ) -> Double? {
        guard !bodyweightOnly else { return nil }
        guard let matched = findMatchingMax(exerciseName: exerciseName, maxes: maxes) else { return nil }
        let percentage = defaultPercentage(for: reps)
        return matched.weightKg * percentage
    }

    static func findMatchingMax(exerciseName: String, maxes: [ExerciseMax]) -> ExerciseMax? {
        let lower = exerciseName.lowercased()
        if let exact = maxes.first(where: { $0.name.lowercased() == lower }) {
            return exact
        }
        return maxes.first(where: {
            $0.name.lowercased().contains(lower) || lower.contains($0.name.lowercased())
        })
    }

    static func defaultPercentage(for reps: String) -> Double {
        let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
        switch repCount {
        case 1...3: return 0.85
        case 4...5: return 0.80
        case 6...8: return 0.70
        case 9...12: return 0.65
        default: return 0.60
        }
    }

    // MARK: - Rest Periods

    static func assignRestMinutes(reps: String, bodyweight: Bool) -> Double {
        if bodyweight { return 1.0 }
        let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
        switch repCount {
        case 1...5: return 2.5
        case 6...8: return 2.0
        case 9...12: return 1.5
        default: return 1.0
        }
    }

    // MARK: - Energy Multiplier

    static func applyEnergyMultiplier(_ weight: Double, energy: EnergyLevel) -> Double {
        let multiplier: Double = switch energy {
        case .low: 0.85
        case .medium: 1.0
        case .high: 1.05
        }
        return weight * multiplier
    }

    // MARK: - Cycle Phase Multiplier

    static func applyCyclePhaseMultiplier(_ weight: Double, phase: String?, readiness: String?) -> Double {
        guard let phase else { return weight }
        let phaseMultiplier: Double = switch phase.lowercased() {
        case "menstrual": 0.90
        case "follicular": 1.00
        case "ovulation": 1.12
        case "luteal": 0.97
        default: 1.00
        }
        let readinessMultiplier: Double = switch readiness?.lowercased() {
        case "low": 0.85
        case "high": 1.10
        default: 1.0
        }
        return weight * phaseMultiplier * readinessMultiplier
    }

    // MARK: - Coaching Summary

    static func enrichCoachingSummary(base: String, energy: EnergyLevel, cyclePhase: String?) -> String {
        var parts = [base]
        switch energy {
        case .low:
            parts.append("Weights adjusted for low energy today.")
        case .high:
            parts.append("Weights pushed slightly for high energy.")
        case .medium:
            break
        }
        if let phase = cyclePhase, phase.lowercased() != "follicular" {
            parts.append("Adjusted for \(phase.lowercased()) phase.")
        }
        return parts.joined(separator: " ")
    }
}
```

- [ ] **Step 4: Regenerate Xcode project**

Run: `xcodegen generate`

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/WorkoutPostProcessorTests 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/WorkoutPostProcessor.swift SundeeFundeTests/WorkoutPostProcessorTests.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add WorkoutPostProcessor with deterministic personalization logic"
```

---

### Task 4: Create AppleIntelligenceWorkoutService

**Files:**
- Create: `SundeeFundee/Repositories/AIWorkout/AppleIntelligenceWorkoutService.swift`
- Create: `SundeeFundeTests/AppleIntelligenceWorkoutServiceTests.swift`
- Reference: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` (history/favorites logic to port, `AIWorkoutServiceError` enum to move here)
- Reference: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift:158-163`

**Note:** The `AIWorkoutServiceError` enum currently lives in `FirebaseAIWorkoutService.swift` (lines 6-12). It must be included in this new file since Task 5 deletes the old file.

- [ ] **Step 1: Write failing tests**

Create `SundeeFundeTests/AppleIntelligenceWorkoutServiceTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation failure -- `AppleIntelligenceWorkoutService` not found

- [ ] **Step 3: Create `Repositories/AIWorkout/` directory and implement the service**

Create `SundeeFundee/Repositories/AIWorkout/AppleIntelligenceWorkoutService.swift`:

```swift
import Foundation
import SwiftData
import FoundationModels

// MARK: - AIWorkoutServiceError (moved from FirebaseAIWorkoutService.swift)

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case networkError(Int)
    case noContent
}

// MARK: - AppleIntelligenceWorkoutService

final class AppleIntelligenceWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout: GeneratedWorkout

        if await supportsOnDeviceGeneration() {
            do {
                workout = try await generateWithFoundationModels(context: context)
            } catch {
                print("Foundation Models generation failed: \(error). Using offline generator.")
                workout = OfflineWorkoutGenerator.generate(from: context)
            }
        } else {
            workout = OfflineWorkoutGenerator.generate(from: context)
        }

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    // MARK: - Foundation Models

    private func supportsOnDeviceGeneration() async -> Bool {
        let availability = LanguageModelSession.Availability()
        return availability.isAvailable
    }

    private func generateWithFoundationModels(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let prompt = Self.buildPrompt(context: context)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: AIWorkoutOutput.self)

        guard !response.exercises.isEmpty else {
            return OfflineWorkoutGenerator.generate(from: context)
        }

        return WorkoutPostProcessor.process(raw: response, context: context)
    }

    static func buildPrompt(context: WorkoutGenerationContext) -> String {
        var parts: [String] = [
            "Design a \(context.timeMinutes)-minute \(context.focus.displayName) workout.",
            "Energy level: \(context.energyLevel.displayName).",
            "Equipment: \(context.equipment.displayName).",
            "Experience: \(context.experienceLevel). Goal: \(context.primaryGoal)."
        ]
        if !context.activeInjuries.isEmpty {
            let injuryNotes = context.activeInjuries.map {
                "\($0.location) (\($0.phase)): \($0.restrictions.joined(separator: ", "))"
            }
            parts.append("IMPORTANT — Active injuries, do NOT prescribe exercises that aggravate these: \(injuryNotes.joined(separator: "; "))")
        }
        return parts.joined(separator: " ")
    }

    // MARK: - History & Favorites

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.id == workoutID }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isFavorite = isFavorite
        try? modelContext.save()
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID && $0.isFavorite == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }
}
```

- [ ] **Step 4: Regenerate Xcode project**

Run: `xcodegen generate`

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AppleIntelligenceWorkoutServiceTests 2>&1 | tail -20`
Expected: All tests PASS (on simulator, Foundation Models unavailable, uses OfflineWorkoutGenerator fallback)

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Repositories/AIWorkout/ SundeeFundeTests/AppleIntelligenceWorkoutServiceTests.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add AppleIntelligenceWorkoutService with Foundation Models + offline fallback"
```

---

### Task 5: Remove Gemini Files, AIUsageTracker, and Clean All References (Atomic)

This task merges deletion of old files with cleanup of all references so no commit has broken code.

**Files:**
- Delete: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`
- Delete: `SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift`
- Delete: `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift`
- Delete: `SundeeFundee/Domain/Subscription/AIUsageTracker.swift`
- Delete: `SundeeFundeTests/GeminiWorkoutPromptTests.swift`
- Delete: `SundeeFundeTests/AIWorkoutServiceRemoteTests.swift`
- Delete: `SundeeFundeTests/RemoteWorkoutResponseTests.swift`
- Modify: `SundeeFundee/Domain/Subscription/FeatureEntitlement.swift:50-68`
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift:28-57`
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireView.swift:38-40,137-148,152`
- Modify: `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift:24`
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift:736-784`
- Modify: `SundeeFundee/Features/Subscription/ManageSubscriptionView.swift:50-64`
- Modify: `SundeeFundeTests/SubscriptionTests.swift:79-120,174-253,482-490`
- Modify: `SundeeFundeTests/DashboardViewCoverageTests.swift` (AIWorkoutCTACard rendering)

- [ ] **Step 1: Delete Gemini source files**

```bash
rm SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift
rm SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift
rm SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift
```

- [ ] **Step 2: Delete AIUsageTracker**

```bash
rm SundeeFundee/Domain/Subscription/AIUsageTracker.swift
```

- [ ] **Step 3: Delete Gemini test files**

```bash
rm SundeeFundeTests/GeminiWorkoutPromptTests.swift
rm SundeeFundeTests/AIWorkoutServiceRemoteTests.swift
rm SundeeFundeTests/RemoteWorkoutResponseTests.swift
```

- [ ] **Step 4: Remove AI methods from FeatureEntitlement.swift**

Remove `aiWorkoutLimit(for:)`, `aiWorkoutsRemaining(tier:usedThisMonth:)`, and `canGenerateAIWorkout(tier:usedThisMonth:)` (lines 50-68).

- [ ] **Step 5: Simplify QuestionnaireViewModel.swift**

Remove:
- `isAtUsageLimit` property (line 28)
- `checkUsageLimit(tier:)` method (lines 30-33)
- Usage tracking from `generateWorkout()`: remove `tier` parameter, remove `AIUsageTracker.usageThisMonth()` call, remove `FeatureEntitlement.canGenerateAIWorkout()` check, remove `AIUsageTracker.incrementUsage()` call
- The simplified `generateWorkout()` should just call `aiService.generateWorkout(context:)` and set the result

- [ ] **Step 6: Clean up QuestionnaireView.swift**

Remove:
- `showPaywall` state variable
- `PaywallView` sheet (lines 38-40)
- `PremiumBadge` / "Upgrade for More AI Workouts" button block (lines 137-148)
- Update `generateWorkout` call site (line 152) to match simplified signature (remove `tier:` argument)
- Keep the "Generate Workout" button as the only footer option

- [ ] **Step 7: Update AIWorkoutFlowView.swift**

Change line 24 from:
```swift
let aiService = SwiftDataAIWorkoutService(modelContext: modelContext)
```
to:
```swift
let aiService = AppleIntelligenceWorkoutService(modelContext: modelContext)
```

- [ ] **Step 8: Clean up DashboardView.swift**

Remove `AIUsageTracker.usageThisMonth()`, `FeatureEntitlement.aiWorkoutsRemaining()`, and `FeatureEntitlement.aiWorkoutLimit()` references from the AIWorkoutCTACard (lines 736-784). Simplify to show the CTA without usage counts.

- [ ] **Step 9: Clean up ManageSubscriptionView.swift**

Remove the AI workout usage section (lines 50-64) that references `AIUsageTracker` and `FeatureEntitlement` AI limit methods. Also remove the reference to `usageSection` from the view's `body`.

- [ ] **Step 10: Clean up SubscriptionTests.swift**

Remove:
- `aiWorkoutLimit` tests (lines 79-83)
- `canGenerateAIWorkout` tests (lines 85-102)
- `aiWorkoutsRemaining` tests (lines 104-120)
- Entire `AIUsageTrackerTests` class (lines 174-253)
- `AIWorkoutCTACard` static tests referencing usage (lines 482-490)

- [ ] **Step 11: Update DashboardViewCoverageTests.swift**

Update the `AIWorkoutCTACard` rendering test to match the simplified card (no usage display).

- [ ] **Step 12: Verify no stale references**

```bash
grep -rn "GeminiWorkoutPrompt\|GeminiResponseParser\|RemoteWorkoutResponse\|AIUsageTracker\|SwiftDataAIWorkoutService\|checkUsageLimit\|isAtUsageLimit" SundeeFundee/ SundeeFundeTests/ --include="*.swift"
```
Expected: No results

- [ ] **Step 13: Regenerate Xcode project**

Run: `xcodegen generate`

- [ ] **Step 14: Verify it compiles**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 15: Commit**

```bash
git add -A
git commit -m "refactor: remove Gemini, AIUsageTracker, and wire AppleIntelligenceWorkoutService"
```

---

### Task 6: Adapt Remaining Tests

**Files:**
- Modify: `SundeeFundeTests/AIWorkoutTests.swift`
- Modify: `SundeeFundeTests/AIWorkoutViewModelTests.swift`

- [ ] **Step 1: Update AIWorkoutTests.swift**

Remove any test methods that reference `GeminiWorkoutPrompt`, `RemoteWorkoutResponse`, or `SwiftDataAIWorkoutService`. Keep all `OfflineWorkoutGenerator`, `WorkoutGenerationContext`, `GeneratedWorkout`, `GeneratedExercise`, and enum tests.

- [ ] **Step 2: Update AIWorkoutViewModelTests.swift**

Remove any test methods referencing `AIUsageTracker`, `checkUsageLimit`, `isAtUsageLimit`, or paywall behavior. Update `OfflineAIWorkoutService` stub if it referenced the old service. Keep `WorkoutPreviewViewModel` tests, `QuestionnaireView` static tests, and `WorkoutHistoryView` tests.

- [ ] **Step 3: Run the full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: adapt test suite for Apple Intelligence workout generation"
```

---

### Task 7: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the AI Workout Generation section**

Replace the current Gemini/Cloudflare Worker description with:

```markdown
### AI Workout Generation

Personalized workouts are generated on-device via Apple's Foundation Models framework (iOS 26+). The app sends a simplified prompt (time, focus, energy, equipment, injuries) and receives structured output via `@Generable` types (`AIWorkoutOutput`). `WorkoutPostProcessor` then applies deterministic personalization: weight calculations from 1RM maxes, cycle phase multipliers, energy adjustments, and rest period assignment. Falls back to `OfflineWorkoutGenerator` when Apple Intelligence is unavailable on the device. The Cloudflare Worker (`workout-proxy.sundeefundee.workers.dev/generate-workout`) is retained for the WOD Dashboard only.
```

- [ ] **Step 2: Update deployment target references**

Change any mentions of `iOS 17.0+` to `iOS 26.0+`.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for Apple Intelligence workout generation"
```

---

### Task 8: Final Verification

- [ ] **Step 1: Clean build**

```bash
xcodebuild clean build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Run full test suite**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -30
```
Expected: All tests PASS

- [ ] **Step 3: Verify no stale references**

```bash
grep -rn "Gemini\|GeminiWorkoutPrompt\|GeminiResponseParser\|RemoteWorkoutResponse\|AIUsageTracker\|SwiftDataAIWorkoutService\|workout-proxy" SundeeFundee/ SundeeFundeTests/ --include="*.swift"
```
Expected: No results

- [ ] **Step 4: Verify coverage**

Check that all new code (`WorkoutPostProcessor`, `AppleIntelligenceWorkoutService`, `AIWorkoutOutput`) has test coverage. The CI enforces 100% line coverage.

**Note on Foundation Models coverage:** On CI simulators, Apple Intelligence is unavailable, so the `generateWithFoundationModels` code path will not be covered. The `supportsOnDeviceGeneration` method returns `false`, routing to `OfflineWorkoutGenerator`. To achieve 100% coverage, consider extracting the Foundation Models interaction behind a protocol for mock injection in a future iteration -- or exclude those specific lines from coverage with a `// swiftcov:ignore` annotation if the CI tool supports it.

- [ ] **Step 5: Final commit if any fixups needed**

```bash
git add -A
git commit -m "chore: final cleanup for Apple Intelligence migration"
```
