# Sundee Fundee Next 15 User Stories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 15 next-step user stories as shippable product slices that make Sundee Fundee easier to use in the gym, more adaptive over time, clearer about data safety, and more useful for monthly reflection.

**Architecture:** Keep decision logic in pure domain services under `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`, then expose those services through existing SwiftUI view models and views. Persist only durable user state through CloudKit-safe records, using `dateCreated` and `dateUpdated` names and ISO8601 strings where needed. Reuse the existing `Workout`, `Exercise`, `EquipmentAccess`, `ScheduleReshuffler`, `SubstitutionRanker`, share-card, export, and settings seams instead of introducing a new backend or package dependency.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, XCTest and Swift Testing, CloudKit through `DataClientProtocol`, HealthKit through `HealthClientProtocol`, no external package dependencies, iOS 18+.

---

## Scope Check

The 15 stories touch several independent subsystems. Build them as five release slices instead of one large branch:

1. **In-gym flow:** quick workouts, equipment profiles, station-taken swaps, technique cues, warmups, and rest guidance.
2. **Learning loop:** RPE logging and adaptation explanations with undo.
3. **Health-context insights:** symptom trends and return-to-lifting ramps.
4. **Planning and trust:** missed-workout reshuffling and visible sync status.
5. **Growth and reflection:** share privacy presets, buddy check-ins, and monthly review.

Do not submit to App Store review as part of this plan unless the user explicitly asks after implementation and verification.

## Baseline Assumptions

- Start this plan after the existing 12-story roadmap work in the current tree is committed, shelved, or otherwise stabilized. Do not overwrite those uncommitted changes.
- `TodayTrainingDecision`, `EquipmentConversionService`, `WeeklyPlanService`, `DataTrustCenterView`, private share-card defaults, and `ScheduleReshuffler` are treated as baseline seams.
- All new user-facing errors use actionable copy. Do not display raw `error.localizedDescription`.
- All theme usage goes through `AppTheme.*`.

## Story Coverage

- Story 1, best next 20 minutes: Task 1.
- Story 2, what changed and why with undo: Task 8.
- Story 3, station taken swap: Task 3.
- Story 4, saved equipment profiles: Task 2.
- Story 5, setup cues and common mistakes: Task 4.
- Story 6, contextual warmup: Task 5.
- Story 7, smart rest timer suggestions: Task 6.
- Story 8, RPE and effort learning: Task 7.
- Story 9, symptom pattern tracking: Task 9.
- Story 10, staged return-to-lifting ramp: Task 10.
- Story 11, missed workout reshuffle: Task 11.
- Story 12, local vs synced status: Task 12.
- Story 13, private share cards by default: Task 13.
- Story 14, lightweight buddy check-ins: Task 14.
- Story 15, monthly review: Task 15.

## File Structure

**Create:**

- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/QuickWorkoutBuilder.swift` - builds the best workout that fits a short time cap.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentProfile.swift` - CloudKit-safe saved equipment profile model.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentProfileService.swift` - loads, saves, sorts, and selects equipment profiles.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/StationTakenSwapService.swift` - ranks swaps when a rack, bench, machine, or station is unavailable.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/ExerciseTechniqueLibrary.swift` - concise setup cues, common mistakes, and safer regressions.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WarmupBuilder.swift` - creates contextual warmup blocks from the first lift and readiness inputs.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/RestGuidanceService.swift` - recommends rest duration and reason after each set.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutEffortLog.swift` - persisted RPE and session-feel records.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutAdaptationDecisionRecord.swift` - persisted adaptation decision and reversible original workout snapshot.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutAdaptationDecisionService.swift` - records, explains, and undoes workout changes before progress is logged.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SymptomCheckInRecord.swift` - cramps, fatigue, soreness, and energy check-in record.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/SymptomTrainingTrendService.swift` - summarizes symptom and training correlations.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Injury/ReturnToLiftingRampRecord.swift` - persisted ramp plan for a body region or exercise pattern.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Injury/ReturnToLiftingRampService.swift` - computes staged load and volume caps.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/MissedWorkoutRecoveryService.swift` - wraps `ScheduleReshuffler` for user-facing weekly recovery plans.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Diagnostics/SyncStatusService.swift` - user-facing local/synced/queued/needs-action status.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Social/BuddyCheckInRecord.swift` - CloudKit-safe check-in record with privacy-preserving fields.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Social/BuddyCheckInService.swift` - creates, accepts, and summarizes buddy check-ins.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/MonthlyReviewService.swift` - builds monthly summaries from workouts, recovery, symptoms, and effort logs.
- Focused tests under `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/`.
- View-model tests under `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/`.

**Modify:**

- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` - quick workout, missed-workout recovery, sync status, monthly review entry points.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift` - station-taken swap, technique cues, warmup, rest guidance, RPE prompt, adaptation explanation.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` - drive in-workout state and persistence.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift` - quick workout launch and monthly review links if appropriate.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` - adaptation decision logging and undo before session start.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift` - symptom check-ins and symptom trend cards.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift` - return-to-lifting ramp entry points and symptom context.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` - equipment profiles, default share privacy, and sync status entry points.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift` - local/synced status and queued sync diagnostics.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift` - monthly review and buddy check-in surfaces.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift` - buddy check-in integration.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift` - monthly review and buddy check-in share variants.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift` - saved privacy preset selection.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardRenderer.swift` - new share variants.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/ExportedData.swift` - export new durable records.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift` - include new record types.
- `SundeeFundeeApp/cloudkit-schema.json` - add new record types and fields after domain tests pass.
- `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift` - add targeted screenshots only after flows are stable.

## Task 1: Best Next 20 Minutes

**Story:** As a busy user, I want a "best next 20 minutes" workout option, so I can still train when my day gets compressed.

**Outcome:** The Today screen can launch a short workout that respects time, focus, energy, equipment, cycle/recovery decision, and pain context.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/QuickWorkoutBuilder.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/QuickWorkoutBuilderTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`

- [ ] **Step 1: Add failing builder tests**

Create `QuickWorkoutBuilderTests` with these cases:

```swift
func testBuildsWorkoutWithinTwentyMinuteCap() {
    let result = QuickWorkoutBuilder.build(
        request: QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .homeDumbbells,
            todayDecisionKind: .modify,
            recoveryScoreTotal: 55,
            painLogs: []
        )
    )

    XCTAssertLessThanOrEqual(result.estimatedMinutes, 20)
    XCTAssertEqual(result.workout.duration, 20)
    XCTAssertFalse(result.workout.exercises.isEmpty)
}

func testLowRecoveryAvoidsMaxEffortBarbellWork() {
    let result = QuickWorkoutBuilder.build(
        request: QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .lowerBody,
            energyLevel: .low,
            equipment: .fullGym,
            todayDecisionKind: .recover,
            recoveryScoreTotal: 32,
            painLogs: []
        )
    )

    let names = result.workout.exercises.map(\.name).joined(separator: " ")
    XCTAssertFalse(names.localizedCaseInsensitiveContains("1RM"))
    XCTAssertFalse(names.localizedCaseInsensitiveContains("Max"))
    XCTAssertTrue(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("recovery") }))
}
```

Run:

```bash
cd SundeeFundee && swift test --filter QuickWorkoutBuilderTests
```

Expected: compile failure because `QuickWorkoutBuilder` does not exist.

- [ ] **Step 2: Implement the public surface**

Add:

```swift
public struct QuickWorkoutRequest: Sendable, Equatable {
    public let timeMinutes: Int
    public let focus: WorkoutFocus
    public let energyLevel: EnergyLevel
    public let equipment: EquipmentAccess
    public let todayDecisionKind: TodayTrainingDecisionKind
    public let recoveryScoreTotal: Int?
    public let painLogs: [DailyPainLog]
}

public struct QuickWorkoutResult: Sendable, Equatable {
    public let workout: Workout
    public let estimatedMinutes: Int
    public let reasons: [String]
}

public enum QuickWorkoutBuilder {
    public static func build(request: QuickWorkoutRequest) -> QuickWorkoutResult
}
```

The implementation should use 2 to 4 exercises, 1 to 3 working sets each, and a capped estimate of `sets * restMinutes + simple transition time`.

- [ ] **Step 3: Wire Today UI**

Add a compact action to `DashboardView` near the existing daily decision card:

- Label: `Best next 20 min`
- Icon: `timer`
- Action: build a `QuickWorkoutRequest` from dashboard state and present `ActiveWorkoutView`.
- Empty-state behavior: if there is no readiness data, default to `.modify`, `.medium`, `.fullBody`, and the user's default equipment.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter QuickWorkoutBuilderTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and build pass.

## Task 2: Saved Equipment Profiles

**Story:** As a user who trains in multiple places, I want saved equipment profiles for Home, Gym, and Travel, so workouts convert instantly.

**Outcome:** Users can save equipment profiles, set a default, and choose one from workout generation or an active workout.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentProfile.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/EquipmentProfileService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/EquipmentProfileServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`

- [ ] **Step 1: Add failing model and service tests**

Cover:

- The default seeded profiles are `Gym`, `Home`, and `Travel`.
- Saving a new default clears `isDefault` from the previous default.
- Profiles sort by `sortOrder`, then `name`.
- Invalid duplicate names are normalized to one saved profile per name.

Run:

```bash
cd SundeeFundee && swift test --filter EquipmentProfileServiceTests
```

Expected: compile failure because the service does not exist.

- [ ] **Step 2: Implement CloudKit-safe model**

Add:

```swift
public struct EquipmentProfile: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public var name: String
    public var equipmentRaw: String
    public var isDefault: Bool
    public var sortOrder: Int
    public var dateCreated: Date
    public var dateUpdated: Date

    public var equipment: EquipmentAccess {
        EquipmentAccess(rawValue: equipmentRaw) ?? .fullGym
    }
}
```

Record type: `EquipmentProfile`.

- [ ] **Step 3: Implement service**

Add `EquipmentProfileService` as an actor with:

```swift
public actor EquipmentProfileService {
    public init(dataClient: DataClientProtocol)
    public func loadProfiles() async -> [EquipmentProfile]
    public func saveProfile(_ profile: EquipmentProfile) async throws
    public func setDefault(profileID: String) async throws
    public func defaultProfile() async -> EquipmentProfile
}
```

When no records exist, return seeded local defaults without saving them automatically.

- [ ] **Step 4: Wire UI**

- Settings gets an `Equipment Profiles` row.
- Active workout equipment conversion offers saved profiles before raw `EquipmentAccess` options.
- Coach Plan defaults to the selected default profile.

- [ ] **Step 5: Verify**

```bash
cd SundeeFundee && swift test --filter EquipmentProfileServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 3: Station Taken Swap

**Story:** As a user in a crowded gym, I want a "station taken" swap, so I can keep the same training intent without waiting.

**Outcome:** Active workout users can tap a single action to get substitutes ranked for the same movement pattern and available equipment.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/StationTakenSwapService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/StationTakenSwapServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`

- [ ] **Step 1: Add failing tests**

Test:

- `Back Squat` with a taken rack and dumbbells available ranks `Goblet Squat` ahead of unrelated upper-body movements.
- A taken bench for `Flat Barbell Bench Press` ranks a dumbbell press or push-up variation.
- A swap cannot be applied silently after sets are complete; the existing confirmation flow must still appear.

Run:

```bash
cd SundeeFundee && swift test --filter StationTakenSwapServiceTests
```

- [ ] **Step 2: Implement domain service**

Add:

```swift
public enum BlockedStationKind: String, Codable, Sendable, Equatable {
    case rack
    case bench
    case machine
    case cable
    case floorSpace
}

public struct StationTakenSwapRequest: Sendable, Equatable {
    public let exerciseName: String
    public let blockedStation: BlockedStationKind
    public let equipment: EquipmentAccess
    public let painLogs: [DailyPainLog]
}

public enum StationTakenSwapService {
    public static func rankedSwaps(
        request: StationTakenSwapRequest
    ) -> [SubstitutionRanker.RankedSubstitution]
}
```

Use `SubstitutionRanker.rank` and filter out substitutions that still require the blocked station.

- [ ] **Step 3: Wire active workout**

Add an option in the active workout menu:

- `Station taken`
- Shows a confirmation dialog for blocked station kind.
- Presents ranked swaps through the existing substitution sheet style.
- Uses the existing mid-exercise confirmation if any set is logged.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter StationTakenSwapServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 4: Exercise Technique Cues

**Story:** As a newer lifter, I want setup cues and common mistakes for each exercise, so substitutions feel safe and clear.

**Outcome:** Core lifts and common substitutions expose concise, non-medical technique cues inside the active workout.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/ExerciseTechniqueLibrary.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ExerciseTechniqueLibraryTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Add failing coverage tests**

Cover at least these exercises:

- `Back Squat`
- `Goblet Squat`
- `Flat Barbell Bench Press`
- `Dumbbell Bench Press`
- `Romanian Deadlift (No Straps)`
- `Dumbbell Row`
- `Kettlebell Swing`
- `Push-Up`

Assert each has 2 to 4 setup cues, 1 to 3 common mistakes, and no cue contains diagnosis-style words such as `treat`, `heal`, or `injury cure`.

- [ ] **Step 2: Implement library**

Add:

```swift
public struct ExerciseTechniqueCue: Sendable, Equatable {
    public let exerciseName: String
    public let setupCues: [String]
    public let commonMistakes: [String]
    public let regression: String?
}

public enum ExerciseTechniqueLibrary {
    public static func cue(for exerciseName: String) -> ExerciseTechniqueCue?
}
```

Store entries in static dictionaries keyed by exact exercise names already present in `ExerciseCatalog`.

- [ ] **Step 3: Wire UI**

In `ActiveWorkoutView.currentExerciseCard`, add a compact `Form` disclosure with cue bullets. Hide the section when the library has no entry.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter ExerciseTechniqueLibraryTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 5: Contextual Warmup Builder

**Story:** As a user starting a workout, I want a warm-up based on today's first lift, pain, recovery, and cycle context, so I do not have to guess.

**Outcome:** Workouts can start with a short warmup block that matches the first working movement and current readiness.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WarmupBuilder.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WarmupBuilderTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- A squat-first workout gets hips, ankles, and light squat-pattern prep.
- Low recovery caps warmup at low intensity.
- Active knee pain avoids jump-heavy prep.
- Warmup returns an empty result for workouts with no exercises.

- [ ] **Step 2: Implement public types**

```swift
public struct WarmupRequest: Sendable, Equatable {
    public let workout: Workout
    public let recoveryScoreTotal: Int?
    public let cyclePhase: CyclePhase?
    public let painLogs: [DailyPainLog]
    public let maxMinutes: Int
}

public struct WarmupBlock: Sendable, Equatable {
    public let title: String
    public let estimatedMinutes: Int
    public let exercises: [Exercise]
    public let reasons: [String]
}

public enum WarmupBuilder {
    public static func build(request: WarmupRequest) -> WarmupBlock?
}
```

- [ ] **Step 3: Wire active workout**

On first appearance, if the workout has no warmup-category exercise, show a `Start Warmup` secondary action above the first exercise. Applying it prepends warmup exercises with `ExerciseCategory.warmup`.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter WarmupBuilderTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 6: Smart Rest Guidance

**Story:** As a user mid-workout, I want smart rest timer suggestions, so I know when to rest longer or move on.

**Outcome:** Rest timers explain their duration and respond to exercise type, effort, recovery, and set performance.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/RestGuidanceService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/RestGuidanceServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- Heavy compound work recommends longer rest than isolation work.
- RPE 9 or missed reps adds rest.
- Low recovery adds rest but caps at 5 minutes.
- Conditioning work keeps rest short unless the user missed reps.

- [ ] **Step 2: Implement service**

```swift
public struct RestGuidanceContext: Sendable, Equatable {
    public let exercise: Exercise
    public let completedSet: ExerciseSet
    public let lastRPE: Int?
    public let recoveryScoreTotal: Int?
}

public struct RestGuidance: Sendable, Equatable {
    public let seconds: Int
    public let reason: String
    public let allowsSkip: Bool
}

public enum RestGuidanceService {
    public static func guidance(context: RestGuidanceContext) -> RestGuidance
}
```

- [ ] **Step 3: Wire timer**

Replace the fixed `exercise.restMinutes * 60` timer input with `RestGuidanceService.guidance`. Show the reason in `restTimerCard` and keep the existing skip action.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter RestGuidanceServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 7: RPE and Effort Learning

**Story:** As a user whose effort varies day to day, I want quick RPE or "how did that feel?" logging, so the app learns my real tolerance.

**Outcome:** The active workout can capture set or session effort, persist it, and feed future adaptation without forcing detailed journaling.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutEffortLog.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WorkoutEffortLogTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/PreferenceLearner.swift`

- [ ] **Step 1: Add failing model tests**

Cover:

- RPE values below 1 or above 10 are clamped or rejected by initializer.
- A session-level effort log can be saved and fetched through `MockCloudKitClient`.
- Export coding includes workout ID, exercise name, set ID, RPE, and `dateCreated`.

- [ ] **Step 2: Implement record**

```swift
public struct WorkoutEffortLog: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let exerciseName: String?
    public let setID: String?
    public let rpe: Int
    public let note: String?
    public let dateCreated: Date
}
```

Record type: `WorkoutEffortLog`.

- [ ] **Step 3: Wire active workout**

Add a compact RPE stepper or segmented control after completing a set. Default to optional; if skipped, no record is saved. On finish, ask for session RPE if no set-level RPE was logged.

- [ ] **Step 4: Feed adaptation**

Update `PreferenceLearner` to treat repeated high-RPE completions as a signal to reduce future volume and repeated low-RPE completions as a signal to allow normal progression.

- [ ] **Step 5: Verify**

```bash
cd SundeeFundee && swift test --filter WorkoutEffortLogTests
cd SundeeFundee && swift test --filter PreferenceLearnerTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 8: Adaptation Explanation and Undo

**Story:** As a program user, I want to see what changed in today's workout and why, so I can trust or undo the adaptation.

**Outcome:** Program sessions and generated workouts can show an adaptation summary and restore the original workout before any set is logged.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutAdaptationDecisionRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutAdaptationDecisionService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WorkoutAdaptationDecisionServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Program/ProgramSessionAdaptationService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- Recording an adaptation stores original and adapted workout JSON strings.
- Undo succeeds when no sets are complete.
- Undo fails with a user-facing reason once progress is logged.
- Decision reasons include cycle, recovery, pain, equipment, and effort when present.

- [ ] **Step 2: Implement record**

```swift
public struct WorkoutAdaptationDecisionRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let originalWorkoutJSON: String
    public let adaptedWorkoutJSON: String
    public let reasonIDs: [String]
    public let reasonText: [String]
    public let dateCreated: Date
}
```

Record type: `WorkoutAdaptationDecisionRecord`.

- [ ] **Step 3: Implement service**

Use `JSONEncoder` and `JSONDecoder` with `.iso8601`. Return user-facing failure copy from undo:

```swift
public enum WorkoutUndoResult: Sendable, Equatable {
    case restored(Workout)
    case blocked(reason: String)
}
```

- [ ] **Step 4: Wire UI**

Show a `What changed` row before session start and inside `ActiveWorkoutView` until the first set is logged. Provide an `Undo changes` button only while `currentExerciseHasProgress == false` and `completedSets == 0`.

- [ ] **Step 5: Verify**

```bash
cd SundeeFundee && swift test --filter WorkoutAdaptationDecisionServiceTests
cd SundeeFundee && swift test --filter ProgramSessionAdaptationServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 9: Symptom Pattern Tracking

**Story:** As a user with recurring symptoms, I want to track cramps, fatigue, soreness, and energy against workouts, so I can see useful patterns.

**Outcome:** Users can log lightweight symptoms and see pattern summaries without medical diagnosis language.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SymptomCheckInRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/SymptomTrainingTrendService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SymptomTrainingTrendServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- A week with high cramps and missed workouts produces a neutral pattern insight.
- A week with high energy and completed workouts produces a positive consistency insight.
- Output never uses diagnostic language such as `diagnose`, `treat`, or `condition`.

- [ ] **Step 2: Implement check-in record**

```swift
public struct SymptomCheckInRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let symptomDate: Date
    public let cramps: Int
    public let fatigue: Int
    public let soreness: Int
    public let energy: Int
    public let notes: String?
    public let dateCreated: Date
}
```

Record type: `SymptomCheckInRecord`.

- [ ] **Step 3: Implement trend service**

```swift
public struct SymptomTrainingInsight: Sendable, Equatable {
    public let title: String
    public let message: String
    public let relatedSignal: String
}

public enum SymptomTrainingTrendService {
    public static func insights(
        symptoms: [SymptomCheckInRecord],
        workouts: [Workout],
        cyclePhase: CyclePhase?
    ) -> [SymptomTrainingInsight]
}
```

- [ ] **Step 4: Wire UI**

Add a lightweight symptom check-in card to Cycle or Recovery. Add trend cards below existing cycle/recovery summaries.

- [ ] **Step 5: Verify**

```bash
cd SundeeFundee && swift test --filter SymptomTrainingTrendServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 10: Return-to-Lifting Ramp

**Story:** As a user returning from pain, I want a staged return-to-lifting ramp, so the app does not jump me straight back to normal loads.

**Outcome:** Active pain or recently resolved pain can produce staged loading and volume caps for affected movement patterns.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Injury/ReturnToLiftingRampRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Injury/ReturnToLiftingRampService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReturnToLiftingRampServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/PainAwareSubstitutionService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Pain/PainTrackingView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- Severe current pain blocks heavy loading for affected patterns.
- Resolved pain starts at a conservative percentage and advances weekly.
- Ramp caps do not affect unrelated movement patterns.
- User copy says `ease back in`, not medical treatment language.

- [ ] **Step 2: Implement record and service**

```swift
public struct ReturnToLiftingRampRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let locationIds: String
    public let movementPatternRaw: String
    public var currentWeek: Int
    public var maxLoadPercent: Double
    public var maxWorkingSets: Int
    public let dateCreated: Date
    public var dateUpdated: Date
}

public struct ReturnToLiftingRampRecommendation: Sendable, Equatable {
    public let movementPattern: WorkoutMovementPattern
    public let maxLoadPercent: Double
    public let maxWorkingSets: Int
    public let reason: String
}
```

Record type: `ReturnToLiftingRampRecord`.

- [ ] **Step 3: Integrate with pain-aware substitutions**

Before ranking substitutions, ask `ReturnToLiftingRampService` for caps. Reduce sets or load for affected exercises when a safe substitution is not necessary.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter ReturnToLiftingRampServiceTests
cd SundeeFundee && swift test --filter PainAwareSubstitutionServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 11: Missed Workout Reshuffle

**Story:** As a user who misses a planned workout, I want the week reshuffled automatically, so one missed day does not ruin the plan.

**Outcome:** The weekly plan can identify missed sessions, move what still fits, and explain what was kept or dropped.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/MissedWorkoutRecoveryService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/MissedWorkoutRecoveryServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/ScheduleReshuffler.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyPlanService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- A missed compound day moves to the next available day when capacity allows.
- Conditioning is dropped before compound work when capacity is tight.
- The service returns `No recovery needed` when no workouts are missed.
- Existing `ScheduleReshufflerTests` still pass.

- [ ] **Step 2: Implement wrapper service**

```swift
public struct MissedWorkoutRecoveryPlan: Sendable, Equatable {
    public let result: ScheduleReshuffler.ReshuffleResult
    public let userSummary: String
    public let actionTitle: String
}

public enum MissedWorkoutRecoveryService {
    public static func recoveryPlan(
        weeklyPlan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int
    ) -> MissedWorkoutRecoveryPlan?
}
```

- [ ] **Step 3: Wire Dashboard**

If a missed workout exists, show a card with:

- `Recover this week`
- The reshuffle summary.
- Primary action: `Apply new week`.
- Secondary action: `Keep original`.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter MissedWorkoutRecoveryServiceTests
cd SundeeFundee && swift test --filter ScheduleReshufflerTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 12: Local vs Synced Status

**Story:** As a privacy-conscious user, I want clear "saved locally" and "synced to iCloud" status after workouts, so I know my data is safe.

**Outcome:** Settings, Data Trust Center, and post-workout completion show current data state without exposing raw CloudKit errors.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Diagnostics/SyncStatusService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SyncStatusServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Diagnostics/SyncQueueDiagnosticsService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- Guest mode reports `Saved on this device`.
- Signed-in with empty queue reports `Synced with iCloud`.
- Pending queue reports `Waiting to sync`.
- Stuck queue reports `Needs attention` with actionable copy.

- [ ] **Step 2: Implement service**

```swift
public enum SyncStatusKind: String, Sendable, Equatable {
    case localOnly
    case synced
    case queued
    case needsAttention
}

public struct SyncStatus: Sendable, Equatable {
    public let kind: SyncStatusKind
    public let title: String
    public let message: String
    public let systemImage: String
}

public enum SyncStatusService {
    public static func status(
        isGuest: Bool,
        pendingMutationCount: Int,
        stuckMutationCount: Int
    ) -> SyncStatus
}
```

- [ ] **Step 3: Wire UI**

Show sync status:

- In the workout completion screen.
- In `DataTrustCenterView`.
- In Settings diagnostics only when queued or stuck.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter SyncStatusServiceTests
cd SundeeFundee && swift test --filter SyncQueueStuckTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 13: Share Privacy Presets

**Story:** As a user sharing wins, I want share cards that redact cycle, pain, and recovery details by default, so I can celebrate without oversharing.

**Outcome:** Share cards keep private defaults, and users can save a preferred preset without accidentally enabling sensitive fields.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardRenderer.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/SharePrivacyPresetTests.swift`

- [ ] **Step 1: Add failing privacy tests**

Cover:

- `SharePrivacyOptions.privateDefault` hides cycle phase, cycle day, recovery score, pain text, and exact date.
- Saving a preset with `showCycleContext == true` does not imply `showPainContext == true`.
- Monthly review and buddy check-in variants use private defaults.

- [ ] **Step 2: Add preset model**

Keep it lightweight and local to share UI unless the user explicitly needs CloudKit sync:

```swift
public struct SharePrivacyPreset: Codable, Sendable, Equatable {
    public var showCycleContext: Bool
    public var showRecoveryScore: Bool
    public var showPainContext: Bool
    public var showExactDate: Bool
}
```

Persist with `UserDefaults` under a namespaced key such as `com.sundeefundee.sharePrivacyPreset`.

- [ ] **Step 3: Wire UI**

Add `Save as default` in `ShareCardSheet`. Settings gets `Share Privacy Defaults` with the same toggles.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter SharePrivacyPresetTests
cd SundeeFundee && swift test --filter SharePrivacyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 14: Buddy Check-Ins

**Story:** As a user who needs accountability, I want lightweight buddy or challenge check-ins, so I stay consistent without exposing private health context.

**Outcome:** Users can create private check-in threads around completion status and encouragement, without exposing cycle, recovery, pain, or HealthKit data.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Social/BuddyCheckInRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Social/BuddyCheckInService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BuddyCheckInServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- A check-in record stores status, display name, and message only.
- It never stores cycle phase, recovery score, pain intensity, HealthKit IDs, or exact workout details.
- A weekly check-in summary counts completed check-ins.

- [ ] **Step 2: Implement record**

```swift
public enum BuddyCheckInStatus: String, Codable, Sendable, Equatable {
    case planned
    case completed
    case skipped
}

public struct BuddyCheckInRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let threadID: String
    public let displayName: String
    public let statusRaw: String
    public let message: String?
    public let checkInDate: Date
    public let dateCreated: Date
}
```

Record type: `BuddyCheckInRecord`.

- [ ] **Step 3: Implement service**

```swift
public actor BuddyCheckInService {
    public init(dataClient: DataClientProtocol)
    public func save(_ record: BuddyCheckInRecord) async throws
    public func weeklySummary(threadID: String, weekStartDate: Date) async -> BuddyCheckInSummary
}
```

- [ ] **Step 4: Wire UI**

Add a compact `Check in with buddy` action from Challenges and Progress. Use share sheets for invites and keep the record itself CloudKit-backed.

- [ ] **Step 5: Verify**

```bash
cd SundeeFundee && swift test --filter BuddyCheckInServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 15: Monthly Review

**Story:** As a long-term user, I want a monthly review of strength, consistency, cycle phase, recovery, and pain trends, so I can see what is actually working.

**Outcome:** Progress gets a monthly review card with concise wins, patterns, and next-month suggestions.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Analytics/MonthlyReviewService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/MonthlyReviewServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardVariant.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardRenderer.swift`

- [ ] **Step 1: Add failing tests**

Cover:

- A month with workouts and PRs surfaces consistency and strength wins.
- Missing recovery or symptom data produces a clear "connect/log more data" suggestion, not an empty card.
- Sensitive details are marked private before sharing.

- [ ] **Step 2: Implement service**

```swift
public struct MonthlyReview: Sendable, Equatable {
    public let monthTitle: String
    public let workoutCount: Int
    public let personalRecordCount: Int
    public let topWins: [String]
    public let patterns: [String]
    public let nextMonthSuggestions: [String]
}

public enum MonthlyReviewService {
    public static func build(
        month: Date,
        workouts: [Workout],
        recoveryScores: [RecoveryScoreRecord],
        painLogs: [DailyPainLog],
        effortLogs: [WorkoutEffortLog],
        symptomLogs: [SymptomCheckInRecord]
    ) -> MonthlyReview
}
```

- [ ] **Step 3: Wire Progress**

Add a monthly review section in `ProgressHubView` with share support through a new `.monthlyReview` share-card variant. Keep exact cycle and pain details redacted by default.

- [ ] **Step 4: Verify**

```bash
cd SundeeFundee && swift test --filter MonthlyReviewServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Task 16: Export, CloudKit Schema, Screenshots, and Release Readiness

**Outcome:** All durable records are exported, schema snapshots are current, and UI coverage proves the main new surfaces render.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/ExportedData.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DataExportServiceTests.swift`
- Modify: `SundeeFundeeApp/cloudkit-schema.json`
- Modify: `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift`
- Modify: `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt`

- [ ] **Step 1: Extend export data**

Include these records:

- `EquipmentProfile`
- `WorkoutEffortLog`
- `WorkoutAdaptationDecisionRecord`
- `SymptomCheckInRecord`
- `ReturnToLiftingRampRecord`
- `BuddyCheckInRecord`

Do not export local-only `SharePrivacyPreset` unless product requirements change.

- [ ] **Step 2: Update schema snapshot**

Add CloudKit record types and fields for each durable record. Preserve schema rules:

- Do not use `createdAt`, `modifiedAt`, `startDate`, or `endDate`.
- Prefer `dateCreated`, `dateUpdated`, `checkInDate`, and `symptomDate`.
- Store nested workout snapshots as JSON strings, not nested struct arrays.
- Add `recordName` queryable indexes for new record types in CloudKit Dashboard before production release.

- [ ] **Step 3: Add screenshot coverage**

Add targeted screenshot paths for:

- Quick workout action.
- Active workout station-taken menu.
- Equipment profiles settings.
- Data Trust Center sync status.
- Monthly review.

Keep screenshots guarded so missing seed data skips a capture path cleanly instead of failing the whole run.

- [ ] **Step 4: Run full verification**

```bash
cd SundeeFundee && swift test
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeeUITests/SundeeFundeeScreenshotTests build-for-testing
```

If `swiftlint` is installed:

```bash
swiftlint --config .swiftlint.yml
```

Expected: all tests and builds pass. If `swiftlint` is not installed, record that as an environment limitation and do not block the plan on it.

## Implementation Order

1. Task 1: Best Next 20 Minutes.
2. Task 2: Saved Equipment Profiles.
3. Task 3: Station Taken Swap.
4. Task 4: Exercise Technique Cues.
5. Task 5: Contextual Warmup Builder.
6. Task 6: Smart Rest Guidance.
7. Task 7: RPE and Effort Learning.
8. Task 8: Adaptation Explanation and Undo.
9. Task 9: Symptom Pattern Tracking.
10. Task 10: Return-to-Lifting Ramp.
11. Task 11: Missed Workout Reshuffle.
12. Task 12: Local vs Synced Status.
13. Task 13: Share Privacy Presets.
14. Task 14: Buddy Check-Ins.
15. Task 15: Monthly Review.
16. Task 16: Export, CloudKit Schema, Screenshots, and Release Readiness.

## Final Verification Checklist

- [ ] `cd SundeeFundee && swift test`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeeUITests/SundeeFundeeScreenshotTests build-for-testing`
- [ ] `swiftlint --config .swiftlint.yml`, only if installed
- [ ] Confirm no new user-facing errors display raw `localizedDescription`
- [ ] Confirm no new CloudKit fields use reserved names
- [ ] Confirm all share-card paths default to private redaction
- [ ] Confirm HealthKit denial still leaves quick workouts, equipment profiles, RPE, and monthly review usable
