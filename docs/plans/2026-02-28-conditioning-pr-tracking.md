# Conditioning PR Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auto-detect and display conditioning PRs (reps-based and time-based) alongside existing strength PRs in the Maxes tab.

**Architecture:** New `ConditioningPR` SwiftData model + `ConditioningExerciseCatalog` domain type + extended `detectPRs()` logic + collapsible conditioning section in MaxLiftsView. Schema migration V6→V7.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, XcodeGen

---

### Task 1: Add ConditioningScoringType Enum

**Files:**
- Create: `SundeeFundee/Domain/ConditioningExerciseCatalog.swift`
- Test: `SundeeFundeTests/BusinessLogicTests.swift` (append)

**Step 1: Write the failing test**

In `SundeeFundeTests/BusinessLogicTests.swift`, add at the bottom of the file:

```swift
// MARK: - ConditioningScoringType Tests

func testConditioningScoringType_rawValues() {
    XCTAssertEqual(ConditioningScoringType.time.rawValue, "time")
    XCTAssertEqual(ConditioningScoringType.reps.rawValue, "reps")
}

func testConditioningScoringType_isBetterThan_time_lowerIsBetter() {
    XCTAssertTrue(ConditioningScoringType.time.isBetterThan(newValue: 90, existingValue: 100))
    XCTAssertFalse(ConditioningScoringType.time.isBetterThan(newValue: 110, existingValue: 100))
    XCTAssertFalse(ConditioningScoringType.time.isBetterThan(newValue: 100, existingValue: 100))
}

func testConditioningScoringType_isBetterThan_reps_higherIsBetter() {
    XCTAssertTrue(ConditioningScoringType.reps.isBetterThan(newValue: 110, existingValue: 100))
    XCTAssertFalse(ConditioningScoringType.reps.isBetterThan(newValue: 90, existingValue: 100))
    XCTAssertFalse(ConditioningScoringType.reps.isBetterThan(newValue: 100, existingValue: 100))
}

func testConditioningScoringType_isBetterThan_nilExisting_alwaysTrue() {
    XCTAssertTrue(ConditioningScoringType.time.isBetterThan(newValue: 90, existingValue: nil))
    XCTAssertTrue(ConditioningScoringType.reps.isBetterThan(newValue: 10, existingValue: nil))
}

func testConditioningScoringType_formatValue_time() {
    XCTAssertEqual(ConditioningScoringType.time.formatValue(90), "1:30")
    XCTAssertEqual(ConditioningScoringType.time.formatValue(3661), "61:01")
    XCTAssertEqual(ConditioningScoringType.time.formatValue(45), "0:45")
}

func testConditioningScoringType_formatValue_reps() {
    XCTAssertEqual(ConditioningScoringType.reps.formatValue(100), "100 reps")
    XCTAssertEqual(ConditioningScoringType.reps.formatValue(1), "1 rep")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BusinessLogicTests 2>&1 | tail -20`
Expected: FAIL — `ConditioningScoringType` not defined

**Step 3: Write minimal implementation**

Create `SundeeFundee/Domain/ConditioningExerciseCatalog.swift`:

```swift
import Foundation

// MARK: - ConditioningScoringType

enum ConditioningScoringType: String, Codable, CaseIterable, Sendable {
    case time = "time"   // lower is better (seconds)
    case reps = "reps"   // higher is better (count)

    /// Returns `true` when `newValue` is a PR over `existingValue`.
    func isBetterThan(newValue: Double, existingValue: Double?) -> Bool {
        guard let existing = existingValue else { return true }
        switch self {
        case .time: return newValue < existing
        case .reps: return newValue > existing
        }
    }

    /// Human-readable display string for a score value.
    func formatValue(_ value: Double) -> String {
        switch self {
        case .time:
            let totalSeconds = Int(value)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        case .reps:
            let count = Int(value)
            return count == 1 ? "1 rep" : "\(count) reps"
        }
    }
}

// MARK: - ConditioningExerciseCatalog

enum ConditioningExerciseCatalog {

    struct Entry: Identifiable, Sendable {
        let id: String
        let defaultScoringType: ConditioningScoringType
    }

    static let all: [Entry] = [
        // Reps-based (higher is better)
        Entry(id: "Wall Ball",              defaultScoringType: .reps),
        Entry(id: "Box Jump",               defaultScoringType: .reps),
        Entry(id: "Burpee",                 defaultScoringType: .reps),
        Entry(id: "Kettlebell Swing",       defaultScoringType: .reps),
        Entry(id: "Double Under",           defaultScoringType: .reps),
        Entry(id: "Pull-Up (Kipping)",      defaultScoringType: .reps),
        Entry(id: "Toes-to-Bar",            defaultScoringType: .reps),
        Entry(id: "Muscle-Up",              defaultScoringType: .reps),
        Entry(id: "Push-Up",                defaultScoringType: .reps),
        Entry(id: "Sit-Up",                 defaultScoringType: .reps),
        Entry(id: "Air Squat",              defaultScoringType: .reps),
        Entry(id: "Thruster",               defaultScoringType: .reps),
        Entry(id: "Rowing (Calories)",      defaultScoringType: .reps),
        Entry(id: "Assault Bike (Calories)", defaultScoringType: .reps),
        // Time-based (lower is better)
        Entry(id: "400m Run",               defaultScoringType: .time),
        Entry(id: "800m Run",               defaultScoringType: .time),
        Entry(id: "1-Mile Run",             defaultScoringType: .time),
        Entry(id: "5K Run",                 defaultScoringType: .time),
        Entry(id: "500m Row",               defaultScoringType: .time),
        Entry(id: "2K Row",                 defaultScoringType: .time),
        Entry(id: "1K Assault Bike",        defaultScoringType: .time),
    ]

    static let exerciseIDs: Set<String> = Set(all.map(\.id))

    static func isConditioningExercise(_ exerciseID: String) -> Bool {
        exerciseIDs.contains(exerciseID)
    }

    static func scoringType(for exerciseID: String) -> ConditioningScoringType? {
        all.first { $0.id == exerciseID }?.defaultScoringType
    }
}
```

**Step 4: Add file to project.yml**

In `project.yml`, the sources are auto-discovered from `SundeeFundee/` so no manual addition is needed. Run `xcodegen generate`.

**Step 5: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BusinessLogicTests 2>&1 | tail -20`
Expected: PASS

**Step 6: Add catalog tests**

In `SundeeFundeTests/BusinessLogicTests.swift`, add:

```swift
// MARK: - ConditioningExerciseCatalog Tests

func testConditioningExerciseCatalog_isConditioningExercise() {
    XCTAssertTrue(ConditioningExerciseCatalog.isConditioningExercise("Wall Ball"))
    XCTAssertTrue(ConditioningExerciseCatalog.isConditioningExercise("1-Mile Run"))
    XCTAssertFalse(ConditioningExerciseCatalog.isConditioningExercise("Back Squat"))
    XCTAssertFalse(ConditioningExerciseCatalog.isConditioningExercise("Nonexistent"))
}

func testConditioningExerciseCatalog_scoringType() {
    XCTAssertEqual(ConditioningExerciseCatalog.scoringType(for: "Wall Ball"), .reps)
    XCTAssertEqual(ConditioningExerciseCatalog.scoringType(for: "1-Mile Run"), .time)
    XCTAssertNil(ConditioningExerciseCatalog.scoringType(for: "Back Squat"))
}
```

**Step 7: Run tests, commit**

Run: `xcodegen generate && xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BusinessLogicTests 2>&1 | tail -20`

```bash
git add SundeeFundee/Domain/ConditioningExerciseCatalog.swift SundeeFundeTests/BusinessLogicTests.swift
git commit -m "feat: add ConditioningScoringType enum and ConditioningExerciseCatalog"
```

---

### Task 2: Add ConditioningPR SwiftData Model

**Files:**
- Modify: `SundeeFundee/Models/Maxes.swift` (append ConditioningPR class)
- Create: `SundeeFundee/App/AppSchemaV7.swift`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Modify: `SundeeFundee/App/AppModelContainer.swift:104`

**Step 1: Add ConditioningPR model**

Append to `SundeeFundee/Models/Maxes.swift`:

```swift
/// Auto-detected conditioning personal record (reps-based or time-based).
@Model
final class ConditioningPR {
    var id: String
    var userID: String
    var exerciseID: String
    var scoringTypeRaw: String       // "time" or "reps" — CloudKit-safe
    var bestValue: Double            // seconds for time, count for reps
    var weightKg: Double?            // optional: for weighted conditioning (e.g., 20lb wallball)
    var achievedAt: Date
    var workoutID: String?

    init(
        id: String,
        userID: String,
        exerciseID: String,
        scoringType: ConditioningScoringType,
        bestValue: Double,
        weightKg: Double? = nil,
        achievedAt: Date = .now,
        workoutID: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.scoringTypeRaw = scoringType.rawValue
        self.bestValue = bestValue
        self.weightKg = weightKg
        self.achievedAt = achievedAt
        self.workoutID = workoutID
    }

    var scoringType: ConditioningScoringType {
        get { ConditioningScoringType(rawValue: scoringTypeRaw) ?? .reps }
        set { scoringTypeRaw = newValue.rawValue }
    }
}
```

**Step 2: Add optional fields to CompletedSet**

In `SundeeFundee/Models/CompletedWorkout.swift`, add two optional properties to `CompletedSet` (after `completedAt: Date` on line 57):

```swift
var actualTimeSeconds: Double?      // conditioning: time in seconds
var scoringTypeRaw: String?         // nil = strength, "time" or "reps" = conditioning
```

And add corresponding init parameters (with defaults so existing callers don't break):

```swift
init(
    id: String,
    userID: String,
    workoutID: String,
    exerciseName: String,
    setIndex: Int,
    prescribedReps: String,
    actualReps: Int? = nil,
    prescribedWeightKg: Double? = nil,
    actualWeightKg: Double? = nil,
    isCompleted: Bool = false,
    completedAt: Date = .now,
    actualTimeSeconds: Double? = nil,
    scoringTypeRaw: String? = nil
) {
    self.id = id
    self.userID = userID
    self.workoutID = workoutID
    self.exerciseName = exerciseName
    self.setIndex = setIndex
    self.prescribedReps = prescribedReps
    self.actualReps = actualReps
    self.prescribedWeightKg = prescribedWeightKg
    self.actualWeightKg = actualWeightKg
    self.isCompleted = isCompleted
    self.completedAt = completedAt
    self.actualTimeSeconds = actualTimeSeconds
    self.scoringTypeRaw = scoringTypeRaw
}
```

**Step 3: Create AppSchemaV7**

Create `SundeeFundee/App/AppSchemaV7.swift`:

```swift
import SwiftData

/// Schema V7 — adds ConditioningPR model and conditioning fields on CompletedSet.
enum AppSchemaV7: VersionedSchema {
    static let versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            User.self,
            ActiveCycle.self,
            CompletedWorkout.self,
            CompletedSet.self,
            OneRepMax.self,
            PersonalRecord.self,
            LiftMax.self,
            PeriodLog.self,
            SymptomLog.self,
            CycleSettings.self,
            CycleAdaptationPreferences.self,
            InjuryProfile.self,
            EnrolledProgram.self,
            EnrollmentEvent.self,
            BenchmarkDefinition.self,
            BenchmarkResult.self,
            PainLog.self,
            ConditioningPR.self,
        ]
    }
}
```

**Step 4: Update migration plan**

In `SundeeFundee/App/AppSchemaMigrationPlan.swift`, update:

```swift
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV6, migrateV6toV7]
    }

    static let migrateV1toV6 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV6.self
    )

    /// V6 → V7: Adds ConditioningPR model and optional conditioning fields on CompletedSet.
    static let migrateV6toV7 = MigrationStage.lightweight(
        fromVersion: AppSchemaV6.self,
        toVersion: AppSchemaV7.self
    )
}
```

**Step 5: Update AppModelContainer**

In `SundeeFundee/App/AppModelContainer.swift:104`, change:

```swift
private static let allModels: [any PersistentModel.Type] = AppSchemaV7.models
```

**Step 6: Regenerate Xcode project, build**

```bash
xcodegen generate
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add SundeeFundee/Models/Maxes.swift SundeeFundee/Models/CompletedWorkout.swift SundeeFundee/App/AppSchemaV7.swift SundeeFundee/App/AppSchemaMigrationPlan.swift SundeeFundee/App/AppModelContainer.swift
git commit -m "feat: add ConditioningPR model, CompletedSet conditioning fields, schema V7 migration"
```

---

### Task 3: Extend LiftRepository with Conditioning PR Methods

**Files:**
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift:43-53`
- Modify: `SundeeFundee/Repositories/SwiftData/SwiftDataLiftRepository.swift` (append)

**Step 1: Add protocol methods**

In `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`, add to the `LiftRepository` protocol (before the closing brace on line 53):

```swift
    func saveConditioningPR(_ pr: ConditioningPR) throws
    func fetchConditioningPR(exercise: String) throws -> ConditioningPR?
    func fetchAllConditioningPRs() throws -> [ConditioningPR]
```

**Step 2: Implement in SwiftDataLiftRepository**

Append to `SundeeFundee/Repositories/SwiftData/SwiftDataLiftRepository.swift` before the closing brace:

```swift
    // MARK: - ConditioningPR

    func saveConditioningPR(_ pr: ConditioningPR) throws {
        context.insert(pr)
        try context.save()
    }

    func fetchConditioningPR(exercise: String) throws -> ConditioningPR? {
        let descriptor = FetchDescriptor<ConditioningPR>(
            predicate: #Predicate { $0.exerciseID == exercise },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    func fetchAllConditioningPRs() throws -> [ConditioningPR] {
        let descriptor = FetchDescriptor<ConditioningPR>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
```

**Step 3: Fix any test mocks that conform to LiftRepository**

Search for `LiftRepository` conformances in test files and add stub implementations:

```swift
func saveConditioningPR(_ pr: ConditioningPR) throws {}
func fetchConditioningPR(exercise: String) throws -> ConditioningPR? { nil }
func fetchAllConditioningPRs() throws -> [ConditioningPR] { [] }
```

**Step 4: Build and verify**

```bash
xcodegen generate
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift SundeeFundee/Repositories/SwiftData/SwiftDataLiftRepository.swift SundeeFundeTests/
git commit -m "feat: add conditioning PR repository methods to LiftRepository"
```

---

### Task 4: Extend detectPRs() for Conditioning Exercises

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WorkoutSummaryView.swift:173-239` (WorkoutSummaryViewModel)
- Modify: `SundeeFundee/Domain/CelebrationEvent.swift` (add conditioning case)

**Step 1: Add conditioning celebration event**

In `SundeeFundee/Domain/CelebrationEvent.swift`, add a new case after `newPersonalRecord`:

```swift
case newConditioningPR(exerciseName: String, value: Double, scoringType: ConditioningScoringType)
```

Add to `title`:
```swift
case .newConditioningPR:
    return "New Conditioning PR!"
```

Add to `subtitle(unit:)`:
```swift
case .newConditioningPR(let name, let value, let scoringType):
    return "\(name) — \(scoringType.formatValue(value))"
```

**Step 2: Add conditioning PR data to ViewModel**

In `WorkoutSummaryViewModel` (line 175), add a new property:

```swift
var newConditioningPRs: [(String, Double, ConditioningScoringType)] = []
```

**Step 3: Extend detectPRs() method**

After the existing strength PR detection loop (after line 229 `newPRs = detectedPRs`), add:

```swift
// Auto-detect conditioning PRs
var detectedConditioningPRs: [(String, Double, ConditioningScoringType)] = []
for (exercise, exerciseSets) in grouped {
    guard let scoringType = ConditioningExerciseCatalog.scoringType(for: exercise) else { continue }

    let bestValue: Double? = {
        switch scoringType {
        case .reps:
            return exerciseSets.compactMap { $0.actualReps.map(Double.init) }.max()
        case .time:
            return exerciseSets.compactMap { $0.actualTimeSeconds }.filter { $0 > 0 }.min()
        }
    }()

    guard let newValue = bestValue else { continue }

    let existing = try? liftRepo.fetchConditioningPR(exercise: exercise)
    if scoringType.isBetterThan(newValue: newValue, existingValue: existing?.bestValue) {
        let pr = ConditioningPR(
            id: UUID().uuidString,
            userID: workout.userID,
            exerciseID: exercise,
            scoringType: scoringType,
            bestValue: newValue,
            weightKg: exerciseSets.first?.actualWeightKg,
            achievedAt: workout.completedAt,
            workoutID: workout.id
        )
        try? liftRepo.saveConditioningPR(pr)
        detectedConditioningPRs.append((exercise, newValue, scoringType))
    }
}
newConditioningPRs = detectedConditioningPRs
```

**Step 4: Update primaryCelebrationEvent**

Update the `primaryCelebrationEvent` computed property to also check conditioning PRs:

```swift
var primaryCelebrationEvent: CelebrationEvent? {
    if let first = newPRs.first {
        return .newPersonalRecord(exerciseName: first.0, weightKg: first.1)
    }
    if let first = newConditioningPRs.first {
        return .newConditioningPR(exerciseName: first.0, value: first.1, scoringType: first.2)
    }
    return .workoutCompleted(durationSeconds: workout.durationSeconds)
}
```

**Step 5: Update the notification check in WorkoutSummaryView.body.task**

Change the notification condition to also include conditioning PRs:

```swift
.task {
    await viewModel.detectPRs(modelContext: modelContext)
    if !viewModel.newPRs.isEmpty || !viewModel.newConditioningPRs.isEmpty {
        NotificationCenter.default.post(name: .didSaveNewPRs, object: nil)
    }
    celebrationEvent = viewModel.primaryCelebrationEvent
}
```

**Step 6: Update prBanner to show conditioning PRs**

In the `prBanner` view, after the existing strength PR `ForEach`, add:

```swift
ForEach(viewModel.newConditioningPRs, id: \.0) { (exercise, value, scoringType) in
    HStack {
        Text(exercise)
        Spacer()
        Text(scoringType.formatValue(value))
            .foregroundStyle(AppTheme.Colors.accentOrange)
    }
    .font(AppTheme.Fonts.body)
    .foregroundStyle(AppTheme.Colors.navy)
}
```

Also update the `if` condition for prBanner:
```swift
if !viewModel.newPRs.isEmpty || !viewModel.newConditioningPRs.isEmpty { prBanner }
```

**Step 7: Build, run tests**

```bash
xcodegen generate
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

**Step 8: Commit**

```bash
git add SundeeFundee/Features/Workouts/WorkoutSummaryView.swift SundeeFundee/Domain/CelebrationEvent.swift
git commit -m "feat: extend detectPRs to auto-detect conditioning PRs"
```

---

### Task 5: Add Conditioning PRs Section to MaxLiftsView

**Files:**
- Modify: `SundeeFundee/Features/Maxes/MaxLiftsViewModel.swift`
- Modify: `SundeeFundee/Features/Maxes/MaxLiftsView.swift`

**Step 1: Add conditioning PR data to ViewModel**

In `MaxLiftsViewModel`, add properties:

```swift
var conditioningPRs: [ConditioningPR] = []
var conditioningExerciseNames: [String] = []
```

In the `load()` method, after line 40 (`personalRecords = prDict`), add:

```swift
// Load conditioning PRs
let cPRs = try! repo.fetchAllConditioningPRs()
conditioningPRs = cPRs
conditioningExerciseNames = Array(Set(cPRs.map(\.exerciseID))).sorted()
```

**Step 2: Add ConditioningPRRow view**

In `MaxLiftsView.swift`, add a new view struct:

```swift
// MARK: - ConditioningPRRow

struct ConditioningPRRow: View {
    let pr: ConditioningPR

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseID)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                if let kg = pr.weightKg, kg > 0 {
                    Text("@ \(Int(kg)) kg")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(pr.scoringType.formatValue(pr.bestValue))
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                Text(pr.achievedAt, style: .date)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}
```

**Step 3: Add conditioning section to MaxLiftsView body**

In the `List` within `MaxLiftsView.body`, after the existing strength exercises `ForEach` block (and inside the `else` branch), add a new section:

```swift
if !viewModel.conditioningExerciseNames.isEmpty {
    Section {
        ForEach(viewModel.conditioningPRs, id: \.id) { pr in
            ConditioningPRRow(pr: pr)
        }
    } header: {
        Text("Conditioning PRs")
            .font(AppTheme.Fonts.subheading)
            .foregroundStyle(AppTheme.Colors.navy)
    }
}
```

**Step 4: Build and verify**

```bash
xcodegen generate
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Maxes/MaxLiftsViewModel.swift SundeeFundee/Features/Maxes/MaxLiftsView.swift
git commit -m "feat: add conditioning PRs section to MaxLiftsView"
```

---

### Task 6: Update CelebrationOverlayView for Conditioning PRs

**Files:**
- Modify: `SundeeFundee/Features/Shared/CelebrationOverlayView.swift`

**Step 1: Read CelebrationOverlayView**

Read the file to understand how it renders celebration events. It likely switches on `CelebrationEvent` cases — add handling for `.newConditioningPR`.

**Step 2: Add the new case to any switch statements**

The overlay view calls `event.title` and `event.subtitle(unit:)` which are already implemented in Task 4. If there are any explicit switches on the enum, add the new case. If the view just uses `title`/`subtitle`, no changes needed.

**Step 3: Build and verify**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

**Step 4: Commit if changes were needed**

```bash
git add SundeeFundee/Features/Shared/CelebrationOverlayView.swift
git commit -m "feat: handle conditioning PR celebration in overlay view"
```

---

### Task 7: Update Tests for Full Coverage

**Files:**
- Modify: `SundeeFundeTests/BusinessLogicTests.swift` (CelebrationEvent conditioning case)
- Modify: `SundeeFundeTests/ViewModelCoverageTests.swift` (WorkoutSummaryViewModel conditioning detection)
- Modify: `SundeeFundeTests/RepositoryCoverageTests.swift` (ConditioningPR CRUD)
- Modify: `SundeeFundeTests/AppInfraCoverageTests.swift` (schema V7 migration)

**Step 1: Add CelebrationEvent conditioning tests**

In `BusinessLogicTests.swift`:

```swift
func testCelebrationEvent_conditioningPR_title() {
    let event = CelebrationEvent.newConditioningPR(exerciseName: "Wall Ball", value: 100, scoringType: .reps)
    XCTAssertEqual(event.title, "New Conditioning PR!")
}

func testCelebrationEvent_conditioningPR_subtitle_reps() {
    let event = CelebrationEvent.newConditioningPR(exerciseName: "Wall Ball", value: 100, scoringType: .reps)
    XCTAssertEqual(event.subtitle, "Wall Ball — 100 reps")
}

func testCelebrationEvent_conditioningPR_subtitle_time() {
    let event = CelebrationEvent.newConditioningPR(exerciseName: "1-Mile Run", value: 390, scoringType: .time)
    XCTAssertEqual(event.subtitle, "1-Mile Run — 6:30")
}
```

**Step 2: Add ConditioningPR model tests**

```swift
func testConditioningPR_scoringTypeAccessor() {
    let pr = ConditioningPR(id: "1", userID: "u", exerciseID: "Wall Ball", scoringType: .reps, bestValue: 100)
    XCTAssertEqual(pr.scoringType, .reps)
    XCTAssertEqual(pr.scoringTypeRaw, "reps")
    pr.scoringType = .time
    XCTAssertEqual(pr.scoringTypeRaw, "time")
}
```

**Step 3: Add CompletedSet conditioning field tests**

```swift
func testCompletedSet_conditioningFields_defaultNil() {
    let set = CompletedSet(id: "1", userID: "u", workoutID: "w", exerciseName: "Squat", setIndex: 0, prescribedReps: "5")
    XCTAssertNil(set.actualTimeSeconds)
    XCTAssertNil(set.scoringTypeRaw)
}

func testCompletedSet_conditioningFields_canBeSet() {
    let set = CompletedSet(id: "1", userID: "u", workoutID: "w", exerciseName: "Wall Ball", setIndex: 0, prescribedReps: "100", actualTimeSeconds: 180, scoringTypeRaw: "time")
    XCTAssertEqual(set.actualTimeSeconds, 180)
    XCTAssertEqual(set.scoringTypeRaw, "time")
}
```

**Step 4: Add schema V7 tests**

In `AppInfraCoverageTests.swift`:

```swift
func testAppSchemaV7_containsConditioningPR() {
    let modelTypes = AppSchemaV7.models
    XCTAssertTrue(modelTypes.contains(where: { $0 == ConditioningPR.self }))
}

func testAppSchemaV7_versionIdentifier() {
    XCTAssertEqual(AppSchemaV7.versionIdentifier, Schema.Version(7, 0, 0))
}

func testMigrationPlan_includesV6toV7() {
    XCTAssertEqual(AppSchemaMigrationPlan.schemas.count, 3)
    XCTAssertEqual(AppSchemaMigrationPlan.stages.count, 2)
}
```

**Step 5: Run full test suite**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -30
```

**Step 6: Commit**

```bash
git add SundeeFundeTests/
git commit -m "test: add full coverage for conditioning PR tracking"
```

---

### Task 8: Final Integration Test and Cleanup

**Step 1: Run full build**

```bash
xcodegen generate
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

**Step 2: Run full test suite with coverage**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -30
```

**Step 3: Check for any missing coverage**

Review test output. If any new code paths are uncovered, add targeted tests.

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: conditioning PR tracking - complete implementation"
```
