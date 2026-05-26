# Sundee Fundee User Stories Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 12 user stories as a sequence of shippable product slices that make daily training decisions clearer, workouts more adaptable, progress more trustworthy, sharing safer, and privacy more transparent.

**Architecture:** Keep core decision logic in pure domain services under `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`, then expose it through existing SwiftUI view models and views. Prefer additive services over broad rewrites: `TodayGuidanceService`, `RecoveryScoreCalculator`, `ProgramSessionAdaptationService`, `PainAwareSubstitutionService`, `WeeklyPlanService`, share cards, exports, and settings already provide the main integration seams.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, XCTest and Swift Testing, CloudKit through `DataClientProtocol`, HealthKit through `HealthClientProtocol`, no external package dependencies, iOS 18+.

---

## Scope Check

The 12 stories touch multiple independent subsystems: dashboard decisions, recovery scoring, program adaptation, exercise substitution, equipment conversion, starting-weight guidance, weekly planning, cycle confidence, analytics, sharing, and privacy. Implement them as the releases below instead of one large branch.

**Recommended release order:**
1. Daily decision layer: stories 1, 4, 8.
2. Workout adaptation layer: stories 2, 5, 6.
3. Planning and calibration layer: stories 7, 10.
4. Cycle and progress insight layer: stories 3, 9.
5. Trust and growth layer: stories 11, 12.

Do not submit to App Store review as part of this plan unless the user explicitly asks for submission after implementation and verification.

## User Story Coverage

- Story 1, Today Decision: Task 1.
- Story 2, Program Auto-Adjustment: Task 3.
- Story 3, Cycle Confidence: Task 7.
- Story 4, Deload Without Guilt: Task 2.
- Story 5, Pain-Specific Swaps: Task 4.
- Story 6, One-Tap Equipment Conversion: Task 5.
- Story 7, Starting Weight Calibration: Task 6.
- Story 8, Recovery Score Explanation: Task 1.
- Story 9, Cycle-Aware Progress: Task 8.
- Story 10, Weekly Training Planner: Task 6.
- Story 11, Private Share Cards: Task 9.
- Story 12, Data Trust Center: Task 10.

## File Structure

**Create:**
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/TodayTrainingDecision.swift` - user-facing train, modify, recover decision model.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/TodayTrainingDecisionService.swift` - pure decision engine for daily guidance.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/RecoveryExplanationService.swift` - ranks the top recovery-score contributors for display.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/DeloadDetectionService.swift` - detects accumulated fatigue and recommends deload mode.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/ActiveRecoveryWorkoutBuilder.swift` - builds low-stress sessions from existing exercise vocabulary.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramAdaptationSummary.swift` - stores user-facing reasons for program-session changes.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentConversionService.swift` - converts exercises to available equipment with reasons.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/JointPainSubstitutionPolicy.swift` - maps pain regions to safer movement alternatives.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/StartingWeightCalibrationService.swift` - suggests starting loads from maxes, experience, and session intent.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleConfidenceExplainer.swift` - translates phase confidence into clear copy and action.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/CycleAwareProgressInsightService.swift` - summarizes PRs, volume, and consistency by cycle phase.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Privacy/DataInventoryService.swift` - lists app data categories, storage location, and export/delete support.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift` - settings destination for export, delete, and privacy explanation.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/StartingWeightCalibrationSheet.swift` - pre-workout load calibration UI.
- Tests under `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/`.
- View-model tests under `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/`.
- UI/share tests under `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/`.

**Modify:**
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/TodayGuidanceService.swift` - keep existing action ordering, but delegate daily decision copy to new guidance services.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScore.swift` - expose stable contributor metadata if the existing `explanations` dictionary is not enough for ranking.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramSessionAdaptationService.swift` - expand context beyond cycle/injuries to recovery, pain, equipment, and deload mode.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/ExerciseCatalog.swift` - add missing conversion metadata only where needed.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyTrainingPlan.swift` - add optional cycle-aware planning preferences using CloudKit-safe field names.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyPlanService.swift` - recommend training days from preferences, recovery, and cycle context.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` - show the decision card, deload card, and top recovery explanations.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift` - add recovery explanations and action links.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift` - show phase confidence and improvement actions.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift` - add cycle-aware progress insights.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` - explain program adaptation before enrollment or session start.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift` - surface conversions, swaps, and starting-weight calibration.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift` - show joint-specific swap reasons.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift` - add sensitive-data toggles defaulted to private.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/*.swift` - honor privacy-redaction settings.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` - add Data Trust Center navigation.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/ExportedData.swift` - include new planning/calibration records if stored.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift` - export new records after they exist.
- `SundeeFundeeApp/cloudkit-schema.json` - add new record types or fields only after domain tests pass.

## Task 1: Daily Decision and Recovery Explanation

**Stories:** 1 and 8.

**Outcome:** The Today screen shows one clear `Train`, `Modify`, or `Recover` recommendation with the top reasons from recovery, cycle, pain, energy, and training-load inputs.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/TodayTrainingDecision.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/TodayTrainingDecisionService.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance/RecoveryExplanationService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/TodayTrainingDecisionServiceTests.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/RecoveryExplanationServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/TodayGuidanceService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift`

- [ ] **Step 1: Add failing decision-service tests**

Cover these exact cases:
- Recovery score >= 70, no high pain, no deload signal returns `.train`.
- Recovery score 40...69 returns `.modify`.
- Recovery score < 40 or pain intensity >= 7 returns `.recover`.
- Missing score with low energy returns `.modify`, not `.recover`.

Run:

```bash
cd SundeeFundee && swift test --filter TodayTrainingDecisionServiceTests
```

Expected: compile failure because `TodayTrainingDecisionService` does not exist.

- [ ] **Step 2: Add the decision model and service**

Use this public surface:

```swift
public enum TodayTrainingDecisionKind: String, Codable, Sendable, Equatable {
    case train
    case modify
    case recover
}

public struct TodayTrainingDecision: Sendable, Equatable {
    public let kind: TodayTrainingDecisionKind
    public let title: String
    public let subtitle: String
    public let reasons: [String]
    public let primaryActionTitle: String
    public let systemImage: String
}
```

The service should accept `RecoveryScore?`, `CyclePhase?`, `cycleConfidence: Double?`, `painIntensity: Int?`, `energyLevel: EnergyLevel?`, `weeklyPlanProgress: WeeklyPlanProgress?`, and `deloadRecommended: Bool`.

- [ ] **Step 3: Add failing recovery-explanation tests**

Cover:
- Low sleep, high training load, and pain produce the first three explanations.
- Missing inputs produce an action-oriented explanation like "Connect sleep or HRV for a clearer score."
- Explanations never expose raw error text or HealthKit internals.

Run:

```bash
cd SundeeFundee && swift test --filter RecoveryExplanationServiceTests
```

Expected: compile failure because `RecoveryExplanationService` does not exist.

- [ ] **Step 4: Implement recovery explanations**

Use `RecoveryScore.explanations`, `subScores`, and `presentInputCount` as inputs. Keep output to a maximum of three display items.

- [ ] **Step 5: Wire Dashboard and Recovery UI**

Add a decision card above existing weekly-plan and recovery-input checklist content. Add a compact explanation block in `RecoveryOverviewView` below `RecoveryScoreCard`.

- [ ] **Step 6: Verify**

Run:

```bash
cd SundeeFundee && swift test --filter TodayTrainingDecisionServiceTests
cd SundeeFundee && swift test --filter RecoveryExplanationServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: all tests and the app build pass.

- [ ] **Step 7: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Guidance SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/TodayTrainingDecisionServiceTests.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/RecoveryExplanationServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/TodayGuidanceService.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift
git commit -m "feat(guidance): add daily training decision"
```

## Task 2: Deload Detection and Active-Recovery Programming

**Story:** 4.

**Outcome:** When recent recovery and training-load signals suggest accumulated fatigue, the app offers an active-recovery version of the day instead of making the user choose between pushing and skipping.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/DeloadDetectionService.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/ActiveRecoveryWorkoutBuilder.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DeloadDetectionServiceTests.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ActiveRecoveryWorkoutBuilderTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift`

- [ ] **Step 1: Test deload detection**

Cases:
- Three low recovery scores in seven days returns `isRecommended == true`.
- Pain intensity >= 7 plus poor sleep returns `isRecommended == true`.
- One low day after strong prior scores returns `isRecommended == false`.

Run:

```bash
cd SundeeFundee && swift test --filter DeloadDetectionServiceTests
```

- [ ] **Step 2: Implement `DeloadDetectionService`**

Use historical `RecoveryScoreRecord`, recent `DailyPainLog`, and weekly training summaries. Return a value with `isRecommended`, `reason`, and `recommendedDays`.

- [ ] **Step 3: Test active-recovery workout generation**

Cases:
- Generated session has 3 to 5 low-stress exercises.
- No max-effort or contraindicated exercise names appear.
- Menstrual or low-recovery context favors mobility, carries, light bodyweight, or band work.

Run:

```bash
cd SundeeFundee && swift test --filter ActiveRecoveryWorkoutBuilderTests
```

- [ ] **Step 4: Implement the builder**

Build a regular `Workout` so `ActiveWorkoutView` can launch it without a new workout runtime.

- [ ] **Step 5: Wire UI**

Show "Take an active recovery day" as a secondary action on the daily decision card when deload is recommended.

- [ ] **Step 6: Verify and commit**

```bash
cd SundeeFundee && swift test --filter DeloadDetectionServiceTests
cd SundeeFundee && swift test --filter ActiveRecoveryWorkoutBuilderTests
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/DeloadDetectionService.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/ActiveRecoveryWorkoutBuilder.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DeloadDetectionServiceTests.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ActiveRecoveryWorkoutBuilderTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift
git commit -m "feat(recovery): recommend active recovery deloads"
```

## Task 3: Program Auto-Adjustment

**Story:** 2.

**Outcome:** A structured program session can adapt for cycle phase, recovery score, pain, and available equipment while preserving the program identity and showing a short change summary.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramAdaptationSummary.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ProgramAdaptationSummaryTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramSessionAdaptationService.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ProgramSessionAdaptationServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift`

- [ ] **Step 1: Expand tests for combined adaptation**

Add coverage for:
- Low recovery reduces volume or load.
- High pain swaps contraindicated lower-body exercise.
- Equipment mismatch converts an exercise before injury/cycle scaling.
- The returned summary includes reason codes for every material change.

- [ ] **Step 2: Expand adaptation context**

Add optional fields to `ProgramSessionAdaptationContext`: `recoveryScore`, `painIntensity`, `equipment`, `cycleConfidence`, and `deloadRecommended`.

- [ ] **Step 3: Return exercises plus summary**

Add a new method instead of changing the existing one abruptly:

```swift
public static func adaptWithSummary(
    _ exercises: [GeneratedProgramExercise],
    context: ProgramSessionAdaptationContext
) -> ProgramAdaptationResult
```

Keep the existing `adapt(_:context:)` as a compatibility wrapper.

- [ ] **Step 4: Show adaptation summary in Programs UI**

When a program session is started from an enrolled program, show concise copy such as "Reduced lower-body volume because recovery is low and cycle confidence is high."

- [ ] **Step 5: Verify and commit**

```bash
cd SundeeFundee && swift test --filter ProgramSessionAdaptationServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramAdaptationSummary.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ProgramAdaptationSummaryTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramSessionAdaptationService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ProgramSessionAdaptationServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift
git commit -m "feat(programs): explain adaptive program sessions"
```

## Task 4: Joint-Specific Pain Swaps

**Story:** 5.

**Outcome:** Exercise substitutions explain the affected joint or region and prefer safer movement patterns for the logged pain.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/JointPainSubstitutionPolicy.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/JointPainSubstitutionPolicyTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/PainAwareSubstitutionService.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/PainAwareSubstitutionServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift`

- [ ] **Step 1: Test joint-specific policy**

Cover knee, low-back, shoulder, wrist, and hip pain. Each case should produce an avoided pattern, preferred pattern, and plain-English reason.

- [ ] **Step 2: Implement the policy**

Keep it pure Foundation. Use existing `BodyRegion`, `DailyPainLog`, `Injury`, and `WorkoutMovementPattern` types.

- [ ] **Step 3: Use policy in `PainAwareSubstitutionService`**

Replace generic string matching with the policy. Preserve current ranking behavior for users with no pain logs.

- [ ] **Step 4: Show reasons in `SubstitutionPickerSheet`**

Display reason text below each candidate. Do not show raw medical claims or diagnosis language.

- [ ] **Step 5: Verify and commit**

```bash
cd SundeeFundee && swift test --filter JointPainSubstitutionPolicyTests
cd SundeeFundee && swift test --filter PainAwareSubstitutionServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/JointPainSubstitutionPolicy.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/JointPainSubstitutionPolicyTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/PainAwareSubstitutionService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/PainAwareSubstitutionServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift
git commit -m "feat(coach): explain pain-aware exercise swaps"
```

## Task 5: One-Tap Equipment Conversion

**Story:** 6.

**Outcome:** A workout can be converted to the user's available equipment in one tap, using the same equipment options already available in onboarding, Settings, Coach Plans, and substitutions.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentConversionService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/EquipmentConversionServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/ExerciseCatalog.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutDetailView.swift`

- [ ] **Step 1: Test conversions by equipment**

Cover full gym to dumbbells, full gym to bands, full gym to kettlebell, and full gym to bodyweight. Each conversion must preserve movement pattern where possible and return a reason.

- [ ] **Step 2: Implement `EquipmentConversionService`**

Use `TrainingExerciseDefinition.equipmentTags`, `WorkoutMovementPattern`, and existing substitution ranking. Return unchanged exercises with a reason when no safe conversion exists.

- [ ] **Step 3: Add one-tap UI**

Add a toolbar/menu action in workout detail and active workout screens: "Convert Equipment". Default the picker to `SettingsViewModel.defaultEquipment`.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter EquipmentConversionServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentConversionService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/EquipmentConversionServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/ExerciseCatalog.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutDetailView.swift
git commit -m "feat(workouts): convert workouts by equipment"
```

## Task 6: Starting Weight Calibration and Weekly Planner

**Stories:** 7 and 10.

**Outcome:** Users can calibrate starting loads before a session, and the weekly planner recommends training days that respect preferred days, cycle context, time available, and recovery.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/StartingWeightCalibrationService.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/StartingWeightCalibrationSheet.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/StartingWeightCalibrationServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyTrainingPlan.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyPlanService.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WeeklyPlanServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WorkoutRemindersSettingsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`

- [ ] **Step 1: Test starting load suggestions**

Cover:
- Known one-rep max returns percentage-based first-set load.
- Beginner without max returns conservative empty-bar/bodyweight guidance.
- Low recovery reduces suggested load.
- Bodyweight exercise returns reps/RPE guidance instead of weight.

- [ ] **Step 2: Implement starting-weight service**

Return `StartingWeightSuggestion` with `exerciseName`, `suggestedWeight`, `unit`, `confidence`, `reason`, and `canIncreaseAfterFirstSet`.

- [ ] **Step 3: Add calibration sheet**

Show it from `ActiveWorkoutView` before the first set when a workout has trackable loaded movements and no recent max.

- [ ] **Step 4: Test weekly planner recommendations**

Add tests for cycle-aware weekday placement, preferred days, target count, and no recommendation when the weekly target is complete.

- [ ] **Step 5: Extend weekly plan model with CloudKit-safe fields**

Use additive optional fields only:
- `timeAvailableMinutesByWeekdayRaw: [String: Int]?`
- `cycleAwarePlanningEnabled: Bool?`
- `recoveryAwarePlanningEnabled: Bool?`

Do not use reserved CloudKit field names.

- [ ] **Step 6: Update weekly plan UI**

Reuse `WorkoutRemindersSettingsView` patterns for weekday selection and time preference controls.

- [ ] **Step 7: Verify and commit**

```bash
cd SundeeFundee && swift test --filter StartingWeightCalibrationServiceTests
cd SundeeFundee && swift test --filter WeeklyPlanServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/StartingWeightCalibrationService.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/StartingWeightCalibrationSheet.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/StartingWeightCalibrationServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyTrainingPlan.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyPlanService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WeeklyPlanServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WorkoutRemindersSettingsView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
git commit -m "feat(planning): calibrate loads and plan training weeks"
```

## Task 7: Cycle Confidence

**Story:** 3.

**Outcome:** Cycle guidance clearly shows whether phase estimates are high, medium, or low confidence and tells the user how to improve confidence.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleConfidenceExplainer.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/CycleConfidenceExplainerTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/CyclePhaseCache.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`

- [ ] **Step 1: Test confidence labels**

Cover nil, low, medium, and high confidence. Low confidence must recommend logging the period or connecting cycle data, not blame the user.

- [ ] **Step 2: Implement explainer**

Return label, short description, and action title. Keep copy concise and non-medical.

- [ ] **Step 3: Wire confidence to views**

Use existing `CyclePhaseCache.confidence` instead of recomputing in the views.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter CycleConfidenceExplainerTests
cd SundeeFundee && swift test --filter CyclePhaseHelperTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleConfidenceExplainer.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/CycleConfidenceExplainerTests.swift SundeeFundee/Sources/SundeeFundeeKit/DataLayer/CyclePhaseCache.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
git commit -m "feat(cycle): explain phase confidence"
```

## Task 8: Cycle-Aware Progress Insights

**Story:** 9.

**Outcome:** Progress screens show useful context like PRs, training volume, and consistency by cycle phase without implying a diagnosis.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/CycleAwareProgressInsightService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/CycleAwareProgressInsightServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/ProgressSnapshotService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/CycleCorrelationChart.swift`

- [ ] **Step 1: Test insight generation**

Cases:
- At least three workouts per phase can produce a "strongest phase" insight.
- Sparse data returns a "needs more data" insight.
- Low confidence phases are excluded or down-weighted.

- [ ] **Step 2: Implement insight service**

Use `CyclePerformancePoint`, `Workout`, `OneRepMaxRecord`, and phase confidence. Return no more than three insights.

- [ ] **Step 3: Wire analytics UI**

Place insights above detailed charts in `AnalyticsView`. Keep charts unchanged unless a small label is needed.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter CycleAwareProgressInsightServiceTests
cd SundeeFundee && swift test --filter ChartDataAggregatorTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/CycleAwareProgressInsightService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/CycleAwareProgressInsightServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/ProgressSnapshotService.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/CycleCorrelationChart.swift
git commit -m "feat(progress): add cycle-aware insights"
```

## Task 9: Private Share Cards

**Story:** 11.

**Outcome:** Share cards celebrate PRs, completed workouts, and streaks while hiding sensitive cycle/recovery data by default.

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CompletedWorkoutShareView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CycleInsightShareView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CoachSummaryShareView.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/SharePrivacyTests.swift`

- [ ] **Step 1: Test default redaction**

Verify that cycle phase, cycle day, recovery score, pain text, and exact dates are hidden unless explicitly enabled.

- [ ] **Step 2: Add share privacy options**

Add a `SharePrivacyOptions` value with defaults:
- `showCycleContext = false`
- `showRecoveryScore = false`
- `showPainContext = false`
- `showExactDate = false`

- [ ] **Step 3: Wire options into share variants**

Render celebratory copy by default. Only include sensitive context when the toggle is on.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter SharePrivacyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CompletedWorkoutShareView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CycleInsightShareView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/CoachSummaryShareView.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/SharePrivacyTests.swift
git commit -m "feat(share): hide sensitive context by default"
```

## Task 10: Data Trust Center

**Story:** 12.

**Outcome:** Settings has a clear Data Trust Center showing what data exists, where it is stored, how to export it, and how to delete it.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Privacy/DataInventoryService.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DataInventoryServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/ExportedData.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DataExportServiceTests.swift`

- [ ] **Step 1: Test inventory categories**

Verify the inventory lists workouts, maxes, benchmarks, cycle logs, pain logs, recovery scores, HealthKit reads, iCloud sync, account identity, and exports.

- [ ] **Step 2: Implement inventory service**

Return static metadata plus counts from `DataClientProtocol` where useful. Do not fetch HealthKit data for counts; explain it as optional read access.

- [ ] **Step 3: Add the Settings destination**

Add a `NavigationLink` labeled "Data Trust Center" under Data & Privacy. Include existing export and delete actions, plus plain language storage details.

- [ ] **Step 4: Export any new records**

If Tasks 6 or later add stored records, include them in `ExportedData` and `DataExportService`.

- [ ] **Step 5: Verify and commit**

```bash
cd SundeeFundee && swift test --filter DataInventoryServiceTests
cd SundeeFundee && swift test --filter DataExportServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Privacy/DataInventoryService.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DataInventoryServiceTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/ExportedData.swift SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DataExportServiceTests.swift
git commit -m "feat(privacy): add data trust center"
```

## Task 11: Schema, Screenshots, and Release Verification

**Outcome:** New stored fields are CloudKit-safe, the project builds, tests pass, and user-facing screenshots still cover the improved product surface.

**Files:**
- Modify: `SundeeFundeeApp/cloudkit-schema.json`
- Modify: `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift`
- Modify: `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt`

- [ ] **Step 1: Validate schema names**

For any new CloudKit fields, confirm none use reserved names: `createdAt`, `modifiedAt`, `startDate`, `endDate`.

- [ ] **Step 2: Add screenshot coverage**

Update screenshot tests to capture:
- Today decision card.
- Program adaptation explanation.
- Equipment conversion or pain swap sheet.
- Data Trust Center.

- [ ] **Step 3: Run full verification**

```bash
cd SundeeFundee && swift test
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
swiftlint --config .swiftlint.yml
```

Expected: all commands pass. If `swiftlint` is not installed on this machine, record that explicitly in the final implementation summary.

- [ ] **Step 4: Commit release-support changes**

```bash
git add SundeeFundeeApp/cloudkit-schema.json SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt
git commit -m "chore(release): document user-story improvements"
```

## Execution Notes

- Keep releases small. Tasks 1 and 2 can ship together; tasks 3 through 10 should be separate branches or separate commits at minimum.
- Prefer pure domain tests first. Add UI wiring only after the service behavior is proven.
- Preserve guest mode. Any CloudKit write must be skipped or local-only when `authViewModel.isGuest` is true.
- HealthKit permissions remain optional. Missing HealthKit data should weaken confidence or explanation richness, not block the app.
- Keep user-facing errors actionable. Do not show `error.localizedDescription` directly in new views.
- Use `AppTheme.*` tokens only in SwiftUI changes.
- Add new CloudKit indexes only for new record types that need querying. Additive fields on existing records should be backwards-compatible with custom decode defaults.

## Final Acceptance Criteria

- The Today screen answers "what should I do today?" in one card.
- Recovery explanations show top reasons and next actions without raw internals.
- A tired user can start an active-recovery session instead of skipping.
- Program sessions adapt without hiding the original program context.
- Pain swaps name the practical reason for the alternative.
- Workouts can be converted to available equipment in one tap.
- Starting weights are less guessy for beginners and returning users.
- Weekly planning uses preferences plus recovery/cycle context.
- Cycle phase confidence is visible wherever cycle-based advice appears.
- Progress views connect performance trends to cycle context with confidence safeguards.
- Share cards hide sensitive information by default.
- Settings contains a Data Trust Center with export, delete, and storage explanations.
