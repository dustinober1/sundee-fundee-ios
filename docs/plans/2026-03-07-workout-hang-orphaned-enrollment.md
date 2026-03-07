# Workout Hang & Orphaned Enrollment Fixes

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix two bugs: (1) workout generation hangs on CloudKit contribute, (2) stale program enrollment persists when program removed from bundle.

**Architecture:** Make CloudKit contribution fire-and-forget via `Task.detached`. Auto-cancel orphaned enrollments when `fetchProgram(id:)` returns nil in dashboard load.

**Tech Stack:** Swift 6, SwiftData, CloudKit, Swift Testing

---

### Task 1: Fire-and-forget CloudKit contribute

**Files:**
- Modify: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift:59-67`

**Step 1: Modify generateWorkout to use fire-and-forget contribute**

Replace the awaited contribute block (lines 59-67) with a detached Task:

```swift
func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
    let workout = await Self.generateWithFallback(context: context, geminiService: geminiService)
    guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
        throw AIWorkoutServiceError.encodingFailed
    }
    modelContext.insert(record)
    try? modelContext.save()

    // Fire-and-forget: contribute anonymized copy to public DB
    if let sharedRepository {
        Task.detached { [sharedRepository] in
            do {
                try await sharedRepository.contribute(workout, userID: context.userID)
            } catch {
                print("[AIWorkoutService] Public contribution failed: \(error)")
            }
        }
    }

    return workout
}
```

**Step 2: Build to verify compilation**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run existing AI workout tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AutoContributionTests 2>&1 | tail -10`
Expected: PASS (existing tests should still pass — they test `buildContribution` static method, not the async flow)

**Step 4: Commit**

```bash
git add SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift
git commit -m "fix: make CloudKit contribute fire-and-forget to prevent workout generation hang"
```

---

### Task 2: Auto-cancel orphaned enrollments

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift:41-57,127-154`

**Step 1: Add modelContext parameter to loadActiveProgram and cancel orphaned enrollment**

Update `load()` to pass modelContext to `loadActiveProgram()`, and update `loadActiveProgram()` to cancel the enrollment when the program doesn't exist:

In `load()` (line 50), change the call:
```swift
await loadActiveProgram(
    modelContext: modelContext,
    periodLogs: cycleData.periodLogs,
    cycleSettings: cycleData.cycleSettings,
    effectiveCyclePrefs: cycleData.effectiveCyclePrefs,
    activeInjuries: activeInjuries
)
```

Update `loadActiveProgram()` signature and add orphan cleanup:
```swift
private func loadActiveProgram(
    modelContext: ModelContext,
    periodLogs: [PeriodLog],
    cycleSettings: CycleSettings?,
    effectiveCyclePrefs: CycleAdaptationPreferences,
    activeInjuries: [InjuryProfile]
) async {
    guard let enrollment = activeEnrollment else { return }

    var program = try? await programRepo.fetchProgram(id: enrollment.programID)

    if program == nil {
        // Program no longer exists — cancel orphaned enrollment
        let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
        try? enrollmentRepo.cancel(enrollment)
        activeEnrollment = nil
        return
    }

    if let raw = program {
        var adapted = CycleProgramGenerator.adaptProgram(
            raw,
            phase: currentCyclePhase,
            settings: cycleSettings,
            preferences: effectiveCyclePrefs,
            periodLogs: periodLogs,
            readinessScore: readinessScore
        )
        if !activeInjuries.isEmpty {
            adapted = InjuryAdaptationEngine.adaptProgram(adapted, activeInjuries: activeInjuries)
        }
        program = adapted
    }
    activeProgram = program
    if let adapted = activeProgram {
        nextSession = findNextSession(in: adapted, enrollment: enrollment)
    }
}
```

**Step 2: Build to verify compilation**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run existing DashboardViewModel tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/DashboardViewModelCoverageTests 2>&1 | tail -10`
Expected: All existing tests PASS

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Dashboard/DashboardViewModel.swift
git commit -m "fix: auto-cancel orphaned enrollments when program no longer exists"
```

---

### Task 3: Add test for orphaned enrollment cleanup

**Files:**
- Modify: `SundeeFundeTests/ViewModelCoverageTests.swift` (add test in `DashboardViewModelCoverageTests` suite)

**Step 1: Write the test**

Add this test to the `DashboardViewModelCoverageTests` suite (after line 467):

```swift
@Test @MainActor
func loadCancelsOrphanedEnrollmentWhenProgramNotFound() async throws {
    let store = try makeTestStore()

    // Create enrollment referencing a program ID that doesn't exist
    let enrollment = EnrolledProgram(
        id: "orphan1",
        userID: "u1",
        programID: "deleted-program",
        startDate: .now,
        currentWeek: 1,
        currentDay: 1
    )
    store.context.insert(enrollment)
    try store.context.save()

    // FakeProgramRepository has no programs — fetchProgram returns nil
    let vm = DashboardViewModel(programRepo: FakeProgramRepository(programs: []))
    await vm.load(modelContext: store.context)

    #expect(vm.activeEnrollment == nil, "Orphaned enrollment should be cleared")
    #expect(vm.activeProgram == nil, "No program should be loaded")

    // Verify enrollment was canceled in SwiftData
    let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: store.context)
    let active = try? enrollmentRepo.fetchActiveEnrollment()
    #expect(active == nil, "Orphaned enrollment should be canceled in the database")
}
```

**Step 2: Run the test**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/DashboardViewModelCoverageTests 2>&1 | tail -10`
Expected: All tests PASS including the new one

**Step 3: Commit**

```bash
git add SundeeFundeTests/ViewModelCoverageTests.swift
git commit -m "test: add coverage for orphaned enrollment auto-cancel"
```

---

### Task 4: Run full test suite

**Step 1: Run all tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -20`
Expected: All tests PASS

**Step 2: Final commit if any adjustments needed**

If tests revealed issues, fix and commit individually.
