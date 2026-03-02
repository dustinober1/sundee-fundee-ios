# Spicy Rating Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 1–5 pepper difficulty rating to the post-workout summary screen for all workout types.

**Architecture:** Add an optional `perceivedEffort` field to `CompletedWorkout`, migrate schema V7→V8, create a shared `SpicyRatingView` component, and embed it in `WorkoutSummaryView` (used by both program workouts and WODs).

**Tech Stack:** Swift 6, SwiftUI, SwiftData, iOS 17+

---

### Task 1: Add `perceivedEffort` to CompletedWorkout model

**Files:**
- Modify: `SundeeFundee/Models/CompletedWorkout.swift:5-43`

**Step 1: Add the property and init parameter**

In `CompletedWorkout`, add `perceivedEffort: Int?` after `notes` (line 16), and add the corresponding init parameter with default `nil`:

```swift
// After line 16 (var notes: String?)
var perceivedEffort: Int?
```

Update `init` to include:
```swift
init(
    id: String,
    userID: String,
    activeCycleID: String,
    programID: String,
    enrollmentID: String? = nil,
    week: Int,
    day: Int,
    sessionID: String,
    completedAt: Date = .now,
    durationSeconds: Int = 0,
    notes: String? = nil,
    perceivedEffort: Int? = nil
) {
    // ... existing assignments ...
    self.perceivedEffort = perceivedEffort
}
```

**Step 2: Commit**

```bash
git add SundeeFundee/Models/CompletedWorkout.swift
git commit -m "feat: add perceivedEffort field to CompletedWorkout model"
```

---

### Task 2: Schema migration V7 → V8

**Files:**
- Create: `SundeeFundee/App/AppSchemaV8.swift`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Modify: `SundeeFundee/App/AppModelContainer.swift:104`

**Step 1: Create AppSchemaV8.swift**

Copy the pattern from `AppSchemaV7.swift`. The model list is identical (no new models, just a new optional field on `CompletedWorkout`):

```swift
import SwiftData

/// Schema V8 — adds perceivedEffort (spicy rating) to CompletedWorkout.
enum AppSchemaV8: VersionedSchema {
    static let versionIdentifier = Schema.Version(8, 0, 0)

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

**Step 2: Update AppSchemaMigrationPlan.swift**

Add `AppSchemaV8.self` to schemas array and new migration stage:

```swift
static var schemas: [any VersionedSchema.Type] {
    [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self]
}

static var stages: [MigrationStage] {
    [migrateV1toV6, migrateV6toV7, migrateV7toV8]
}

/// V7 → V8: Adds perceivedEffort (spicy rating) to CompletedWorkout.
static let migrateV7toV8 = MigrationStage.lightweight(
    fromVersion: AppSchemaV7.self,
    toVersion: AppSchemaV8.self
)
```

**Step 3: Update AppModelContainer.swift line 104**

```swift
private static let allModels: [any PersistentModel.Type] = AppSchemaV8.models
```

**Step 4: Commit**

```bash
git add SundeeFundee/App/AppSchemaV8.swift SundeeFundee/App/AppSchemaMigrationPlan.swift SundeeFundee/App/AppModelContainer.swift
git commit -m "feat: add schema V8 migration for perceivedEffort field"
```

---

### Task 3: Add AppSchemaV8 to project.yml

**Files:**
- Modify: `project.yml` (if AppSchemaV8.swift isn't auto-discovered by the source glob)

**Step 1: Check if project.yml uses a source glob**

If sources are specified as `SundeeFundee/` (glob), no change needed — the new file is auto-discovered. If individual files are listed, add the new file.

**Step 2: Regenerate Xcode project**

```bash
xcodegen generate
```

**Step 3: Build to verify schema compiles**

```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: BUILD SUCCEEDED

**Step 4: Commit if project.yml changed**

```bash
git add project.yml SundeeFundee.xcodeproj
git commit -m "chore: regenerate Xcode project for schema V8"
```

---

### Task 4: Create SpicyRatingView component

**Files:**
- Create: `SundeeFundee/Features/Shared/SpicyRatingView.swift`

**Step 1: Write the failing test**

Add to an appropriate test file (e.g., new section in `ViewModelCoverageTests.swift` or `ProgramWorkoutViewCoverageTests.swift`):

```swift
@Suite("SpicyRatingView Coverage")
struct SpicyRatingViewCoverageTests {
    @Test
    func spicyLabelReturnsCorrectText() {
        #expect(SpicyRatingView.label(for: 1) == "Mild")
        #expect(SpicyRatingView.label(for: 2) == "Warm")
        #expect(SpicyRatingView.label(for: 3) == "Medium")
        #expect(SpicyRatingView.label(for: 4) == "Hot")
        #expect(SpicyRatingView.label(for: 5) == "Inferno")
        #expect(SpicyRatingView.label(for: 0) == "")
        #expect(SpicyRatingView.label(for: 6) == "")
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/SpicyRatingViewCoverageTests
```

Expected: FAIL — `SpicyRatingView` not found.

**Step 3: Create SpicyRatingView.swift**

```swift
import SwiftUI

/// Pepper-based difficulty rating (1–5). Tap to select, tap again to deselect.
struct SpicyRatingView: View {
    @Binding var rating: Int?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("How spicy was it?")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        rating = rating == level ? nil : level
                    } label: {
                        Image(systemName: level <= (rating ?? 0) ? "flame.fill" : "flame")
                            .font(.system(size: 32))
                            .foregroundStyle(level <= (rating ?? 0) ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level) pepper\(level == 1 ? "" : "s")")
                }
            }

            if let rating {
                Text(Self.label(for: rating))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: rating)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    /// Maps a 1–5 rating to a display label. Returns empty string for out-of-range.
    static func label(for rating: Int) -> String {
        switch rating {
        case 1: return "Mild"
        case 2: return "Warm"
        case 3: return "Medium"
        case 4: return "Hot"
        case 5: return "Inferno"
        default: return ""
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/SpicyRatingViewCoverageTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Shared/SpicyRatingView.swift SundeeFundeTests/
git commit -m "feat: add SpicyRatingView pepper rating component with tests"
```

---

### Task 5: Integrate SpicyRatingView into WorkoutSummaryView

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WorkoutSummaryView.swift`

**Step 1: Add spicy rating state and save logic to WorkoutSummaryViewModel**

In `WorkoutSummaryViewModel` (line 183), add:

```swift
var perceivedEffort: Int? = nil

func saveSpicyRating(modelContext: ModelContext) {
    workout.perceivedEffort = perceivedEffort
    try? modelContext.save()
}
```

Also initialize from existing data in case of re-display:
```swift
init(workout: CompletedWorkout) {
    self.workout = workout
    self.perceivedEffort = workout.perceivedEffort
}
```

**Step 2: Add SpicyRatingView to the summary body**

In `WorkoutSummaryView.body` (line 23), insert the spicy rating between `statsRow` and the PR banner. Around line 25-26:

```swift
VStack(spacing: AppTheme.Spacing.lg) {
    completionHeader
    statsRow
    spicyRating          // ← NEW
    if !viewModel.newPRs.isEmpty || !viewModel.newConditioningPRs.isEmpty { prBanner }
    setBreakdown
    doneButton
}
```

Add the computed property:

```swift
private var spicyRating: some View {
    SpicyRatingView(rating: Bindable(viewModel).perceivedEffort)
        .onChange(of: viewModel.perceivedEffort) {
            viewModel.saveSpicyRating(modelContext: modelContext)
        }
}
```

**Step 3: Write test for saveSpicyRating**

Add to the existing `WorkoutSummaryViewModel Coverage` suite in `ViewModelCoverageTests.swift`:

```swift
@Test @MainActor
func saveSpicyRatingPersistsEffortOnWorkout() throws {
    let store = try makeV7TestStore()  // will become makeV8TestStore
    let workout = CompletedWorkout(
        id: "w1", userID: "u1", activeCycleID: "",
        programID: "p1", week: 1, day: 1, sessionID: "s1"
    )
    store.context.insert(workout)
    try store.context.save()

    let vm = WorkoutSummaryViewModel(workout: workout)
    vm.perceivedEffort = 4
    vm.saveSpicyRating(modelContext: store.context)

    #expect(workout.perceivedEffort == 4)
}

@Test @MainActor
func spicyRatingInitializesFromWorkout() throws {
    let store = try makeV7TestStore()
    let workout = CompletedWorkout(
        id: "w2", userID: "u1", activeCycleID: "",
        programID: "p1", week: 1, day: 1, sessionID: "s1",
        perceivedEffort: 3
    )
    store.context.insert(workout)
    try store.context.save()

    let vm = WorkoutSummaryViewModel(workout: workout)
    #expect(vm.perceivedEffort == 3)
}
```

Note: `makeV7TestStore` needs to become `makeV8TestStore` (using `AppSchemaV8.models`) since the new field is in V8. Either update existing helper or add a new one:

```swift
@MainActor
private func makeV8TestStore() throws -> TestStore {
    let schema = Schema(AppSchemaV8.models)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    return TestStore(container: container, context: ModelContext(container))
}
```

**Step 4: Run tests**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/WorkoutSummaryViewModelCoverage
```

Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Workouts/WorkoutSummaryView.swift SundeeFundeTests/ViewModelCoverageTests.swift
git commit -m "feat: integrate spicy rating into workout summary screen"
```

---

### Task 6: Update test helpers and fix any V8 schema references

**Files:**
- Modify: Various test files that use `makeV7TestStore` for workout-related tests
- Modify: `SundeeFundeTests/AppInfraCoverageTests.swift` — add V8 schema coverage test

**Step 1: Add schema V8 test**

In `AppInfraCoverageTests.swift`, add a test verifying V8 schema contains `CompletedWorkout`:

```swift
@Test
func appSchemaV8_containsPerceivedEffort() {
    let models = AppSchemaV8.models
    #expect(models.contains(where: { $0 == CompletedWorkout.self }))
    #expect(AppSchemaV8.versionIdentifier == Schema.Version(8, 0, 0))
}
```

**Step 2: Add migration plan coverage**

Verify the migration plan includes V8:

```swift
@Test
func migrationPlanIncludesV8() {
    let schemas = AppSchemaMigrationPlan.schemas
    #expect(schemas.count == 4)
    #expect(schemas.last is AppSchemaV8.Type)
}
```

**Step 3: Run full test suite**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests
```

Expected: ALL PASS

**Step 4: Commit**

```bash
git add SundeeFundeTests/
git commit -m "test: add V8 schema and spicy rating coverage tests"
```

---

### Task 7: Full build + test verification

**Step 1: Clean build**

```bash
xcodebuild clean build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 2: Full test suite**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests
```

**Step 3: Verify no regressions — all tests pass, build succeeds**

Expected: BUILD SUCCEEDED, all tests PASS
