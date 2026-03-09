# Travel Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persistent Travel Mode toggle that constrains AI workout generation to bodyweight-only or hotel gym equipment, adds space/noise-aware AI prompt constraints, and defaults to shorter workout durations.

**Architecture:** Travel Mode is stored as a `Bool` on the `User` SwiftData model. A new `hotelGym` case is added to `EquipmentAccess`. When active, the questionnaire filters equipment options and changes the default duration. The Gemini prompt builder appends travel-specific constraints. The Dashboard shows a banner when Travel Mode is on.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing

---

### Task 1: Add `hotelGym` to `EquipmentAccess` enum

**Files:**
- Modify: `SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift:57-80`

**Step 1: Add the new enum case**

In `EquipmentAccess`, add `hotelGym` between `homeDumbbells` and `bodyweightOnly`:

```swift
enum EquipmentAccess: String, Codable, Sendable, CaseIterable {
    case fullGym = "full_gym"
    case homeDumbbells = "home_dumbbells"
    case hotelGym = "hotel_gym"
    case bodyweightOnly = "bodyweight_only"
    case outdoor

    var displayName: String {
        switch self {
        case .fullGym: "Full Gym"
        case .homeDumbbells: "Home Dumbbells"
        case .hotelGym: "Hotel Gym"
        case .bodyweightOnly: "Bodyweight Only"
        case .outdoor: "Outdoor"
        }
    }

    var icon: String {
        switch self {
        case .fullGym: "building.2"
        case .homeDumbbells: "dumbbell"
        case .hotelGym: "bed.double"
        case .bodyweightOnly: "figure.strengthtraining.traditional"
        case .outdoor: "sun.max"
        }
    }
}
```

**Step 2: Build to check for exhaustive switch errors**

Run:
```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|warning:.*switch"
```

Fix any exhaustive switch errors found (expect them in `OfflineWorkoutGenerator.swift` and `GeminiPromptBuilder.swift`).

**Step 3: Handle `hotelGym` in `OfflineWorkoutGenerator.filterForEquipment`**

File: `SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift:154-167`

Add `hotelGym` case — same as `homeDumbbells` (allows dumbbells, no barbell):

```swift
case .hotelGym:
    return !template.requiresBarbell
```

**Step 4: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift
git commit -m "feat: add hotelGym equipment access option"
```

---

### Task 2: Add `travelModeEnabled` to User model + schema migration

**Files:**
- Modify: `SundeeFundee/Models/User.swift`
- Create: `SundeeFundee/App/AppSchemaV12.swift`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`

**Step 1: Add `travelModeEnabled` property to User**

File: `SundeeFundee/Models/User.swift`

Add after `bodyWeightKg`:
```swift
var travelModeEnabled: Bool
```

Add `travelModeEnabled: Bool = false` parameter to `init`, and assign `self.travelModeEnabled = travelModeEnabled` in the body.

**Step 2: Create AppSchemaV12**

File: `SundeeFundee/App/AppSchemaV12.swift`

```swift
import SwiftData

/// Schema V12 — adds travelModeEnabled to User for travel mode feature.
enum AppSchemaV12: VersionedSchema {
    static let versionIdentifier = Schema.Version(12, 0, 0)

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
            GeneratedWorkoutRecord.self,
            SharedWorkoutTemplateRecord.self,
            BarbellPreset.self,
            ExerciseBarMapping.self,
        ]
    }
}
```

**Step 3: Update AppSchemaMigrationPlan**

File: `SundeeFundee/App/AppSchemaMigrationPlan.swift`

Add `AppSchemaV12.self` to `schemas` array and add migration stage:

```swift
static var schemas: [any VersionedSchema.Type] {
    [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self, AppSchemaV9.self, AppSchemaV10.self, AppSchemaV11.self, AppSchemaV12.self]
}

static var stages: [MigrationStage] {
    [migrateV1toV6, migrateV6toV7, migrateV7toV8, migrateV8toV9, migrateV9toV10, migrateV10toV11, migrateV11toV12]
}

/// V11 → V12: Adds travelModeEnabled to User.
static let migrateV11toV12 = MigrationStage.lightweight(
    fromVersion: AppSchemaV11.self,
    toVersion: AppSchemaV12.self
)
```

**Step 4: Build to verify migration compiles**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 5: Commit**

```bash
git add SundeeFundee/Models/User.swift SundeeFundee/App/AppSchemaV12.swift SundeeFundee/App/AppSchemaMigrationPlan.swift
git commit -m "feat: add travelModeEnabled to User model with V12 migration"
```

---

### Task 3: Add Travel Mode toggle to Settings

**Files:**
- Modify: `SundeeFundee/Features/Settings/SettingsViewModel.swift`
- Modify: `SundeeFundee/Features/Settings/SettingsView.swift`

**Step 1: Add `travelModeEnabled` to SettingsViewModel**

File: `SundeeFundee/Features/Settings/SettingsViewModel.swift`

Add property after `bodyWeight`:
```swift
var travelModeEnabled: Bool = false
```

In `load()`, after setting `bodyWeight`, add:
```swift
travelModeEnabled = user.travelModeEnabled
```

In `saveProfile()`, after `user.bodyWeightKg = bodyWeight`, add:
```swift
user.travelModeEnabled = travelModeEnabled
```

**Step 2: Add toggle to SettingsView Training section**

File: `SundeeFundee/Features/Settings/SettingsView.swift`

In the `Section("Training")` block, add after the HealthKit toggle:
```swift
Toggle("Travel Mode", isOn: $viewModel.travelModeEnabled)
    .onChange(of: viewModel.travelModeEnabled) { _, _ in
        Task { await viewModel.saveProfile() }
    }
```

**Step 3: Build and verify**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Settings/SettingsViewModel.swift SundeeFundee/Features/Settings/SettingsView.swift
git commit -m "feat: add Travel Mode toggle in Settings"
```

---

### Task 4: Add `travelModeEnabled` to WorkoutGenerationContext

**Files:**
- Modify: `SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift:116-168`

**Step 1: Add property to the struct**

Add `let travelModeEnabled: Bool` after `workoutCompletionRate`.

Add `travelModeEnabled: Bool = false` to the init parameter list and `self.travelModeEnabled = travelModeEnabled` in the body.

**Step 2: Update QuestionnaireViewModel.buildContext**

File: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift:83-103`

In the `WorkoutGenerationContext` init call, add:
```swift
travelModeEnabled: currentUser?.travelModeEnabled ?? false
```

**Step 3: Build and fix any test compilation errors**

All test call sites that create `WorkoutGenerationContext` may need updating if they pass all parameters explicitly. The default value `= false` should cover most cases.

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 4: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift
git commit -m "feat: thread travelModeEnabled through WorkoutGenerationContext"
```

---

### Task 5: Update GeminiPromptBuilder for travel constraints

**Files:**
- Modify: `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift:38-147`
- Test: `SundeeFundeTests/GeminiPromptBuilderTests.swift`

**Step 1: Write failing tests**

File: `SundeeFundeTests/GeminiPromptBuilderTests.swift`

Add tests using the existing `makeContext` helper (add `travelModeEnabled` parameter):

```swift
@Test func travelModeAddsSpaceConstraints() {
    let context = makeContext(equipment: .hotelGym, travelModeEnabled: true)
    let prompt = GeminiPromptBuilder.userPrompt(from: context)
    #expect(prompt.contains("traveling"))
    #expect(prompt.contains("minimize space"))
    #expect(prompt.contains("jumping"))
}

@Test func travelModeOffDoesNotAddConstraints() {
    let context = makeContext(equipment: .fullGym, travelModeEnabled: false)
    let prompt = GeminiPromptBuilder.userPrompt(from: context)
    #expect(!prompt.contains("traveling"))
}

@Test func hotelGymEquipmentDisplaysInPrompt() {
    let context = makeContext(equipment: .hotelGym)
    let prompt = GeminiPromptBuilder.userPrompt(from: context)
    #expect(prompt.contains("Hotel Gym"))
}
```

Update the `makeContext` helper to accept `travelModeEnabled: Bool = false` and pass it through.

**Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/GeminiPromptBuilderTests
```

**Step 3: Implement travel mode section in prompt builder**

File: `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift`

In `userPrompt(from:)`, add after the training consistency section (before the final return):

```swift
// Travel mode constraints
if context.travelModeEnabled {
    sections.append("""
        TRAVEL MODE ACTIVE:
        - User is traveling — minimize space requirements
        - Avoid exercises requiring jumping or loud impacts (no box jumps, burpees with jumps, or dropping weights)
        - Prefer exercises that can be done in a small room or hotel gym
        - Keep noise levels low — no slamming or dropping weights
        """)
}
```

Also add to the system prompt, in the `hotelGym` weight rules — add after the kettlebell section:

```swift
HOTEL GYM weights:
- Dumbbells only: 10, 15, 20, 25, 30, 35, 40, 45, 50 lb
- No barbell available
- Basic cable machine may be available
- No kettlebells
```

**Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/GeminiPromptBuilderTests
```

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift SundeeFundeTests/GeminiPromptBuilderTests.swift
git commit -m "feat: add travel mode constraints to Gemini prompt builder"
```

---

### Task 6: Filter questionnaire equipment options in Travel Mode

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift`
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireView.swift`

**Step 1: Add travel mode state to QuestionnaireViewModel**

File: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift`

Add property:
```swift
var travelModeEnabled: Bool = false
```

Add a static helper for filtered equipment options:
```swift
static func availableEquipment(travelMode: Bool) -> [EquipmentAccess] {
    if travelMode {
        return [.bodyweightOnly, .hotelGym]
    }
    return EquipmentAccess.allCases
}
```

Add a static helper for default duration:
```swift
static func defaultTimeMinutes(travelMode: Bool) -> Int {
    travelMode ? 30 : 45
}
```

**Step 2: Load travel mode from User in QuestionnaireView**

The `QuestionnaireView` receives `userID` but needs the travel mode flag. Update `QuestionnaireView` to query the User model on appear and set defaults:

In `QuestionnaireView.body`, add `.task`:
```swift
.task {
    let userRepo = SwiftDataUserRepository(context: modelContext)
    if let user = try? userRepo.fetchCurrentUser() {
        viewModel.travelModeEnabled = user.travelModeEnabled
        if user.travelModeEnabled {
            viewModel.timeMinutes = QuestionnaireViewModel.defaultTimeMinutes(travelMode: true)
            viewModel.equipment = .bodyweightOnly
        }
    }
}
```

**Step 3: Filter equipment picker in page2**

In `QuestionnaireView`, change the equipment `ForEach` on line 133 from:
```swift
ForEach(EquipmentAccess.allCases, id: \.self) { equip in
```
to:
```swift
ForEach(QuestionnaireViewModel.availableEquipment(travelMode: viewModel.travelModeEnabled), id: \.self) { equip in
```

**Step 4: Add Travel Mode indicator chip**

In `QuestionnaireView.page1`, add at the top of the VStack (before `sectionHeader("How long do you have?")`):

```swift
if viewModel.travelModeEnabled {
    HStack(spacing: AppTheme.Spacing.xs) {
        Image(systemName: "suitcase.fill")
        Text("Travel Mode")
            .font(AppTheme.Fonts.caption)
    }
    .foregroundStyle(AppTheme.Colors.cream)
    .padding(.horizontal, AppTheme.Spacing.md)
    .padding(.vertical, AppTheme.Spacing.xs)
    .background(AppTheme.Colors.navy)
    .clipShape(Capsule())
}
```

**Step 5: Build and verify**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 6: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift SundeeFundee/Features/AIWorkout/QuestionnaireView.swift
git commit -m "feat: filter questionnaire equipment and duration in Travel Mode"
```

---

### Task 7: Add Travel Mode banner to Dashboard

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift`

**Step 1: Add travel mode state to DashboardView**

The Dashboard needs to know if travel mode is active. Read it from the `DashboardViewModel` or query directly. Check if `DashboardViewModel` loads the User — if so, add `travelModeEnabled` there. Otherwise, query in the view.

File: Check `DashboardViewModel` for user loading. Add:
```swift
var travelModeEnabled: Bool = false
```
Set it in the `load()` method from the User model.

**Step 2: Add TravelModeBanner view**

Add to `DashboardView.swift` (before the closing of the file):

```swift
struct TravelModeBanner: View {
    let onTurnOff: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "suitcase.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Travel Mode Active")
                    .font(AppTheme.Fonts.body)
                Text("Limited equipment — bodyweight & hotel gym only")
                    .font(AppTheme.Fonts.caption)
                    .opacity(0.8)
            }
            Spacer()
            Button("Turn Off", action: onTurnOff)
                .font(AppTheme.Fonts.caption)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.Colors.accentOrange)
                .foregroundStyle(AppTheme.Colors.cream)
                .clipShape(Capsule())
        }
        .foregroundStyle(AppTheme.Colors.cream)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.navy)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }
}
```

**Step 3: Show banner in Dashboard body**

In `DashboardView.body`, inside the `VStack`, add after `greetingHeader`:

```swift
if viewModel.travelModeEnabled {
    TravelModeBanner {
        viewModel.toggleTravelMode(modelContext: modelContext, enabled: false)
    }
}
```

**Step 4: Add toggle method to DashboardViewModel**

Add a method to `DashboardViewModel`:
```swift
func toggleTravelMode(modelContext: ModelContext, enabled: Bool) {
    let userRepo = SwiftDataUserRepository(context: modelContext)
    if let user = try? userRepo.fetchCurrentUser() {
        user.travelModeEnabled = enabled
        try? modelContext.save()
        travelModeEnabled = enabled
    }
}
```

**Step 5: Build and verify**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 6: Commit**

```bash
git add SundeeFundee/Features/Dashboard/DashboardView.swift
git commit -m "feat: add Travel Mode banner on Dashboard with turn-off button"
```

---

### Task 8: Update OfflineWorkoutGenerator coaching summary for travel mode

**Files:**
- Modify: `SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift:354-382`

**Step 1: Write failing test**

File: `SundeeFundeTests/AIWorkoutTests.swift` (or appropriate test file)

```swift
@Test func offlineCoachingSummaryMentionsTravelMode() {
    let context = WorkoutGenerationContext(
        userID: "u1", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
        equipment: .hotelGym, maxes: [], recentWorkouts: [], cyclePhase: nil,
        readinessTier: nil, activeInjuries: [], experienceLevel: "beginner",
        primaryGoal: "strength", gender: "male", weightUnit: "lb",
        travelModeEnabled: true
    )
    let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 5)
    #expect(summary.contains("travel"))
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 3: Add travel mode to coaching summary**

In `OfflineWorkoutGenerator.buildCoachingSummary`, add before the return:

```swift
if context.travelModeEnabled {
    parts.append("Travel mode: exercises selected for minimal space and equipment.")
}
```

**Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift SundeeFundeTests/AIWorkoutTests.swift
git commit -m "feat: include travel mode note in offline workout coaching summary"
```

---

### Task 9: Write comprehensive tests

**Files:**
- Modify: `SundeeFundeTests/AIWorkoutTests.swift`
- Modify: `SundeeFundeTests/GeminiPromptBuilderTests.swift`

**Step 1: Add tests for EquipmentAccess.hotelGym**

File: `SundeeFundeTests/AIWorkoutTests.swift`

```swift
@Test func hotelGymHasDisplayName() {
    #expect(EquipmentAccess.hotelGym.displayName == "Hotel Gym")
}

@Test func hotelGymHasIcon() {
    #expect(EquipmentAccess.hotelGym.icon == "bed.double")
}

@Test func hotelGymRawValueEncodes() throws {
    let context = WorkoutGenerationContext(
        userID: "u1", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
        equipment: .hotelGym, maxes: [], recentWorkouts: [], cyclePhase: nil,
        readinessTier: nil, activeInjuries: [], experienceLevel: "beginner",
        primaryGoal: "strength", gender: "male", weightUnit: "lb"
    )
    let data = try JSONEncoder().encode(context)
    let decoded = try JSONDecoder().decode(WorkoutGenerationContext.self, from: data)
    #expect(decoded.equipment == .hotelGym)
}
```

**Step 2: Add tests for offline generator equipment filtering**

```swift
@Test func offlineFilterAllowsDumbbellsForHotelGym() {
    let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .hotelGym)
    let hasBarbellExercise = templates.contains { $0.requiresBarbell }
    #expect(!hasBarbellExercise)
}

@Test func offlineFilterAllowsBodyweightForHotelGym() {
    let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .hotelGym)
    let hasBodyweight = templates.contains { $0.bodyweightOnly }
    #expect(hasBodyweight)
}
```

**Step 3: Add tests for questionnaire equipment filtering**

```swift
@Test func availableEquipmentTravelModeFiltersToTwoOptions() {
    let options = QuestionnaireViewModel.availableEquipment(travelMode: true)
    #expect(options == [.bodyweightOnly, .hotelGym])
}

@Test func availableEquipmentNormalModeShowsAll() {
    let options = QuestionnaireViewModel.availableEquipment(travelMode: false)
    #expect(options == EquipmentAccess.allCases)
}

@Test func defaultTimeTravelModeIs30() {
    #expect(QuestionnaireViewModel.defaultTimeMinutes(travelMode: true) == 30)
}

@Test func defaultTimeNormalModeIs45() {
    #expect(QuestionnaireViewModel.defaultTimeMinutes(travelMode: false) == 45)
}
```

**Step 4: Run all tests**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 5: Commit**

```bash
git add SundeeFundeTests/
git commit -m "test: add comprehensive Travel Mode and hotelGym coverage tests"
```

---

### Task 10: Final build + full test run

**Step 1: Full build**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 2: Full test suite**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 3: Verify no pre-existing test failures were introduced**

Review output for any failures. Fix if needed.

**Step 4: Create PR branch and push**

```bash
git checkout -b feature/travel-mode
git push -u origin feature/travel-mode
```

**Step 5: Create PR**

```bash
gh pr create --title "feat: Travel Mode with hotel gym support" --body "$(cat <<'EOF'
## Summary
- Add persistent Travel Mode toggle in Settings that constrains AI workouts for traveling
- New `hotelGym` equipment option (dumbbells 10-50 lb, no barbell)
- When active: equipment filtered to bodyweight/hotel gym, duration defaults to 30 min
- Dashboard banner shows when Travel Mode is on with quick turn-off button
- Questionnaire shows Travel Mode chip indicator
- Gemini prompt adds space/noise-aware constraints
- Offline fallback respects travel equipment filtering
- SwiftData V12 migration for `travelModeEnabled` on User model

## Test plan
- [ ] Toggle Travel Mode on in Settings, verify Dashboard banner appears
- [ ] Start AI workout with Travel Mode on — only bodyweight/hotel gym equipment shown
- [ ] Verify default duration is 30 min in Travel Mode
- [ ] Turn off Travel Mode from Dashboard banner, verify it disappears
- [ ] Generate workout with hotel gym — verify no barbell exercises
- [ ] Generate workout offline with Travel Mode — verify coaching summary mentions travel
- [ ] All unit tests pass with 100% coverage

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
