# Sex-Aware Tab Visibility & Profile Editing — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Hide the Cycle tab for male users and allow editing biological sex + cycle tracking in Settings.

**Architecture:** Add a `Gender` parameter to `MainTabView.orderedTabs(for:)` to conditionally exclude the `.cycle` tab. Extend `SettingsViewModel` with `gender` and `cycleTrackingEnabled` properties, and add corresponding UI in `EditProfileView`. All changes follow existing patterns (raw-value enum storage, `@Observable` ViewModel, XCTest + Swift Testing).

**Tech Stack:** Swift 6, SwiftUI, SwiftData, XCTest, Swift Testing

---

### Task 1: Create feature branch

**Step 1: Create and switch to feature branch**

Run: `git checkout -b feature/sex-aware-tab-visibility`

**Step 2: Verify clean branch**

Run: `git status`

---

### Task 2: Make MainTabView filter tabs by gender

**Files:**
- Modify: `SundeeFundee/Features/Shell/MainTabView.swift`

**Step 1: Write failing test**

Add to `SundeeFundeTests/MainTabCoverageTests.swift`:

```swift
func testOrderedTabsExcludesCycleForMale() {
    let tabs = MainTabView.orderedTabs(for: .male)
    XCTAssertFalse(tabs.contains(.cycle))
    XCTAssertEqual(tabs, [.dashboard, .programs, .maxes, .benchmarks, .settings])
}

func testOrderedTabsIncludesCycleForFemale() {
    let tabs = MainTabView.orderedTabs(for: .female)
    XCTAssertTrue(tabs.contains(.cycle))
}

func testOrderedTabsIncludesCycleForPreferNotToSay() {
    let tabs = MainTabView.orderedTabs(for: .preferNotToSay)
    XCTAssertTrue(tabs.contains(.cycle))
}

func testOrderedTabsIncludesCycleForNilGender() {
    let tabs = MainTabView.orderedTabs(for: nil)
    XCTAssertTrue(tabs.contains(.cycle))
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/MainTabCoverageTests
```

Expected: Compile error — `orderedTabs(for:)` doesn't exist yet.

**Step 3: Implement `orderedTabs(for:)` in MainTabView**

In `SundeeFundee/Features/Shell/MainTabView.swift`, change:

```swift
static var orderedTabs: [TabRoute] { TabRoute.allCases }
```

To:

```swift
static var orderedTabs: [TabRoute] { orderedTabs(for: nil) }

static func orderedTabs(for gender: Gender?) -> [TabRoute] {
    if gender == .male {
        return TabRoute.allCases.filter { $0 != .cycle }
    }
    return TabRoute.allCases
}
```

**Step 4: Update `body` to use gender-filtered tabs**

Add a `@Query` to fetch the current user's gender and use it:

```swift
@Query private var users: [User]

private var currentGender: Gender? {
    users.first?.gender
}
```

Change the `body` `ForEach` from `Self.orderedTabs` to `Self.orderedTabs(for: currentGender)`.

**Step 5: Update existing tests that reference `orderedTabs`**

In `MainTabCoverageTests`, the existing `testTabMetadataAndOrderAreStable` uses `MainTabView.orderedTabs` (the no-arg version). This still works since it returns all tabs (nil gender). No change needed.

For `testMainTabHostsAndBuildsAllTabsWithStubDestinations`, update the assertion to compare against `MainTabView.orderedTabs` (which includes all tabs since no user is in the context).

**Step 6: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/MainTabCoverageTests
```

Expected: All pass.

**Step 7: Commit**

```bash
git add SundeeFundee/Features/Shell/MainTabView.swift SundeeFundeTests/MainTabCoverageTests.swift
git commit -m "feat: hide Cycle tab for male users in MainTabView"
```

---

### Task 3: Add gender and cycleTrackingEnabled to SettingsViewModel

**Files:**
- Modify: `SundeeFundee/Features/Settings/SettingsViewModel.swift`

**Step 1: Write failing test**

Add to `SundeeFundeTests/ViewModelCoverageTests.swift` inside the `SettingsViewModelCoverageTests` suite:

```swift
@Test("loads gender and cycleTrackingEnabled from user")
@MainActor
func loadsGenderAndCycleTracking() async throws {
    let store = try makeTestStore()
    let user = User(
        id: "u1", name: "Test", experienceLevelRaw: "beginner",
        primaryGoalRaw: "strength", genderRaw: "female",
        appleUserID: "apple1", cycleTrackingEnabled: true,
        onboardingComplete: true, createdAt: Date()
    )
    store.context.insert(user)
    try store.context.save()

    let vm = SettingsViewModel()
    await vm.load(modelContext: store.context, userID: "u1")

    #expect(vm.gender == .female)
    #expect(vm.cycleTrackingEnabled == true)
}

@Test("saveProfile persists gender and cycleTrackingEnabled")
@MainActor
func savesGenderAndCycleTracking() async throws {
    let store = try makeTestStore()
    let user = User(
        id: "u1", name: "Test", experienceLevelRaw: "beginner",
        primaryGoalRaw: "strength", genderRaw: "female",
        appleUserID: "apple1", cycleTrackingEnabled: true,
        onboardingComplete: true, createdAt: Date()
    )
    store.context.insert(user)
    try store.context.save()

    let vm = SettingsViewModel()
    await vm.load(modelContext: store.context, userID: "u1")
    vm.gender = .male
    vm.cycleTrackingEnabled = false
    await vm.saveProfile()

    let repo = SwiftDataUserRepository(context: store.context)
    let saved = try repo.fetchCurrentUser()
    #expect(saved?.gender == .male)
    #expect(saved?.cycleTrackingEnabled == false)
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/ViewModelCoverageTests
```

Expected: Compile error — `vm.gender` and `vm.cycleTrackingEnabled` don't exist on SettingsViewModel.

**Step 3: Add properties to SettingsViewModel**

In `SundeeFundee/Features/Settings/SettingsViewModel.swift`, add properties:

```swift
var gender: Gender = .preferNotToSay
var cycleTrackingEnabled: Bool = false
```

In `load(modelContext:userID:)`, add after `weightUnit = user.weightUnit`:

```swift
gender = user.gender
cycleTrackingEnabled = user.cycleTrackingEnabled
```

In `saveProfile()`, add after `user.weightUnit = weightUnit`:

```swift
user.gender = gender
user.cycleTrackingEnabled = cycleTrackingEnabled
```

**Step 4: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/ViewModelCoverageTests
```

Expected: All pass.

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Settings/SettingsViewModel.swift SundeeFundeTests/ViewModelCoverageTests.swift
git commit -m "feat: add gender and cycleTrackingEnabled to SettingsViewModel"
```

---

### Task 4: Add Biological Sex picker and Cycle Tracking toggle to EditProfileView

**Files:**
- Modify: `SundeeFundee/Features/Settings/SettingsView.swift` (EditProfileView section)

**Step 1: Write failing test for EditProfileView rendering with gender fields**

Add to `SundeeFundeTests/FeatureViewsCoverageWave3Tests.swift` (or the file that already tests EditProfileView):

```swift
func testEditProfileViewShowsGenderPicker() async throws {
    let vm = SettingsViewModel()
    vm.gender = .female
    vm.cycleTrackingEnabled = true
    let view = NavigationStack { EditProfileView(viewModel: vm) }
    XCTAssertNotNil(host(view).view)
}

func testEditProfileViewHidesCycleToggleForMale() async throws {
    let vm = SettingsViewModel()
    vm.gender = .male
    let view = EditProfileView(viewModel: vm)
    // Verify the static helper correctly identifies male
    XCTAssertTrue(EditProfileView.shouldHideCycleToggle(for: .male))
    XCTAssertFalse(EditProfileView.shouldHideCycleToggle(for: .female))
    XCTAssertFalse(EditProfileView.shouldHideCycleToggle(for: .preferNotToSay))
}
```

**Step 2: Run tests to verify they fail**

Expected: Compile error — `shouldHideCycleToggle` doesn't exist.

**Step 3: Add UI to EditProfileView**

In `SundeeFundee/Features/Settings/SettingsView.swift`, in `EditProfileView`:

Add static helper:

```swift
static func shouldHideCycleToggle(for gender: Gender) -> Bool {
    gender == .male
}
```

Add sections to `body` Form, after the "Weight Unit" section:

```swift
Section("Biological Sex") {
    Picker("Sex", selection: $viewModel.gender) {
        ForEach(Gender.allCases, id: \.self) { gender in
            Text(gender.displayName).tag(gender)
        }
    }
    .onChange(of: viewModel.gender) { _, newValue in
        if newValue == .male {
            viewModel.cycleTrackingEnabled = false
        }
    }
}
if !Self.shouldHideCycleToggle(for: viewModel.gender) {
    Section("Cycle Tracking") {
        Toggle("Enable cycle-aware training", isOn: $viewModel.cycleTrackingEnabled)
    }
}
```

**Step 4: Verify `Gender.displayName` exists**

Check that the `Gender` enum has a `displayName` computed property. If not, add one:

```swift
var displayName: String {
    switch self {
    case .male: return "Male"
    case .female: return "Female"
    case .preferNotToSay: return "Prefer not to say"
    }
}
```

**Step 5: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/FeatureViewsCoverageWave3Tests
```

Expected: All pass.

**Step 6: Commit**

```bash
git add SundeeFundee/Features/Settings/SettingsView.swift SundeeFundeTests/FeatureViewsCoverageWave3Tests.swift
git commit -m "feat: add biological sex picker and cycle tracking toggle to EditProfileView"
```

---

### Task 5: Run full test suite and fix coverage

**Step 1: Run full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests
```

Expected: All tests pass. If any existing tests break due to `orderedTabs` changes, fix them.

**Step 2: Check coverage for new code**

Verify the new `orderedTabs(for:)`, `shouldHideCycleToggle(for:)`, and SettingsViewModel gender properties are covered. Add tests if any lines are uncovered.

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "test: fix coverage for sex-aware tab visibility"
```

---

### Task 6: Regenerate Xcode project (if needed)

If no new files were created (only modifications), skip this task. If `project.yml` needed changes:

Run: `xcodegen generate`

---
