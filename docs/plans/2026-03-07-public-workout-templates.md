# Public Workout Templates Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auto-contribute anonymized (weight-stripped) AI workouts to CloudKit Public DB on generation.

**Architecture:** Add a `strippedForSharing()` method to `GeneratedWorkout` that nils all weights. Wire `SwiftDataAIWorkoutService.generateWorkout()` to call `SharedWorkoutRepository.contribute()` with the stripped workout after saving the private record. Mark `contributedToDatabase = true` on success.

**Tech Stack:** Swift 6, SwiftData, CloudKit (CKRecord for Public DB writes), Swift Testing

---

### Task 1: Add `strippedForSharing()` to GeneratedWorkout (Domain)

**Files:**
- Modify: `SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift`
- Test: `SundeeFundeTests/AIWorkoutTests.swift`

**Step 1: Write the failing test**

Add to `SundeeFundeTests/AIWorkoutTests.swift`:

```swift
// MARK: - GeneratedWorkout Sharing Tests

@Suite("GeneratedWorkout Sharing")
struct GeneratedWorkoutSharingTests {

    @Test func strippedForSharingNilsAllWeights() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test workout",
            exercises: [
                GeneratedExercise(name: "Back Squat", sets: 3, reps: "5", weightLb: 225),
                GeneratedExercise(name: "DB Bench", sets: 3, reps: "8", weightLb: 50),
                GeneratedExercise(name: "Plank", sets: 3, reps: "60s", bodyweightOnly: true),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )

        let stripped = workout.strippedForSharing()

        #expect(stripped.exercises.count == 3)
        for exercise in stripped.exercises {
            #expect(exercise.weightLb == nil)
        }
        #expect(stripped.coachingSummary == "Test workout")
        #expect(stripped.questionnaire.focus == .fullBody)
        #expect(stripped.id != workout.id, "Stripped workout gets a new ID")
    }

    @Test func strippedForSharingPreservesStructure() {
        let workout = GeneratedWorkout(
            coachingSummary: "Upper day",
            exercises: [
                GeneratedExercise(
                    name: "Bench Press", sets: 4, reps: "6",
                    weightLb: 185, restMinutes: 2.0, notes: "Pause at bottom",
                    reasoning: "Progressive overload"
                ),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 30, focus: .push, energyLevel: .high, equipment: .fullGym
            )
        )

        let stripped = workout.strippedForSharing()
        let ex = stripped.exercises[0]

        #expect(ex.name == "Bench Press")
        #expect(ex.sets == 4)
        #expect(ex.reps == "6")
        #expect(ex.weightLb == nil)
        #expect(ex.restMinutes == 2.0)
        #expect(ex.notes == "Pause at bottom")
        #expect(ex.bodyweightOnly == false)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/GeneratedWorkoutSharingTests 2>&1 | tail -20`
Expected: FAIL — `strippedForSharing()` does not exist

**Step 3: Write minimal implementation**

Add to `SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift`, inside `struct GeneratedWorkout`:

```swift
/// Returns a copy with all weight data stripped for anonymous sharing.
/// Generates a new ID so the shared copy is independent of the original.
func strippedForSharing() -> GeneratedWorkout {
    let strippedExercises = exercises.map { exercise in
        GeneratedExercise(
            name: exercise.name,
            sets: exercise.sets,
            reps: exercise.reps,
            weightLb: nil,
            restMinutes: exercise.restMinutes,
            notes: exercise.notes,
            reasoning: nil,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }
    return GeneratedWorkout(
        id: UUID().uuidString,
        createdAt: createdAt,
        isFavorite: false,
        isCompleted: false,
        coachingSummary: coachingSummary,
        exercises: strippedExercises,
        questionnaire: questionnaire
    )
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/GeneratedWorkoutSharingTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift SundeeFundeTests/AIWorkoutTests.swift
git commit -m "feat: add strippedForSharing() to GeneratedWorkout for anonymous public sharing"
```

---

### Task 2: Update `CloudKitSharedWorkoutRepository.contribute()` to strip weights

**Files:**
- Modify: `SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift:28-60`

**Step 1: Write the failing test**

Add to `SundeeFundeTests/AIWorkoutTests.swift`:

```swift
// MARK: - CloudKitSharedWorkoutRepository Tests

@Suite("CloudKitSharedWorkoutRepository.contributePayload")
struct SharedWorkoutContributePayloadTests {

    @Test func contributePayloadStripsWeights() throws {
        let workout = GeneratedWorkout(
            coachingSummary: "Heavy day",
            exercises: [
                GeneratedExercise(name: "Deadlift", sets: 5, reps: "3", weightLb: 315),
                GeneratedExercise(name: "Pull-ups", sets: 4, reps: "8", bodyweightOnly: true),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 60, focus: .strength, energyLevel: .high, equipment: .fullGym
            )
        )

        let payload = CloudKitSharedWorkoutRepository.buildContributePayload(from: workout)

        #expect(payload.focusRaw == "strength")
        #expect(payload.equipmentRaw == "full_gym")
        #expect(payload.userID == "")

        let data = payload.workoutJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GeneratedWorkout.self, from: data)
        for exercise in decoded.exercises {
            #expect(exercise.weightLb == nil)
        }
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SharedWorkoutContributePayloadTests 2>&1 | tail -20`
Expected: FAIL — `buildContributePayload` does not exist

**Step 3: Write minimal implementation**

Add a static helper to `CloudKitSharedWorkoutRepository` and update `contribute()`:

```swift
/// Payload for contributing a workout to CloudKit Public DB.
struct ContributePayload {
    let userID: String
    let workoutJSON: String
    let focusRaw: String
    let durationMinutes: Int
    let equipmentRaw: String
}

/// Builds an anonymized, weight-stripped payload for public sharing.
/// Extracted as a static method for testability.
static func buildContributePayload(from workout: GeneratedWorkout) -> ContributePayload {
    let stripped = workout.strippedForSharing()
    let jsonData = (try? JSONEncoder().encode(stripped)) ?? Data()
    let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
    return ContributePayload(
        userID: "",
        workoutJSON: jsonString,
        focusRaw: workout.questionnaire.focus.rawValue,
        durationMinutes: workout.questionnaire.timeMinutes,
        equipmentRaw: workout.questionnaire.equipment.rawValue
    )
}
```

Then update `contribute()` to use it:

```swift
func contribute(_ workout: GeneratedWorkout, userID: String) async throws {
    let container = CKContainer(identifier: containerID)
    let publicDB = container.publicCloudDatabase

    let payload = Self.buildContributePayload(from: workout)

    let record = CKRecord(recordType: "SharedWorkoutTemplate")
    record["userID"] = payload.userID
    record["workoutJSON"] = payload.workoutJSON
    record["focusRaw"] = payload.focusRaw
    record["durationMinutes"] = payload.durationMinutes
    record["equipmentRaw"] = payload.equipmentRaw
    record["createdAt"] = Date.now

    try await publicDB.save(record)

    // Cache locally
    let cached = SharedWorkoutTemplateRecord(
        id: record.recordID.recordName,
        userID: payload.userID,
        createdAt: Date.now,
        downloadedAt: Date.now,
        workoutJSON: payload.workoutJSON,
        focusRaw: payload.focusRaw,
        durationMinutes: payload.durationMinutes,
        equipmentRaw: payload.equipmentRaw
    )
    modelContext.insert(cached)
    try? modelContext.save()
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SharedWorkoutContributePayloadTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift SundeeFundeTests/AIWorkoutTests.swift
git commit -m "feat: strip weights from shared workout contributions for privacy"
```

---

### Task 3: Wire auto-contribution into `SwiftDataAIWorkoutService.generateWorkout()`

**Files:**
- Modify: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift:19-48`
- Test: `SundeeFundeTests/AIWorkoutTests.swift`

**Step 1: Write the failing test**

Add to `SundeeFundeTests/AIWorkoutTests.swift`:

```swift
// MARK: - Auto-Contribution Tests

@Suite("SwiftDataAIWorkoutService auto-contribution")
struct AutoContributionTests {

    @Test func contributeOnGenerateCallsRepository() async throws {
        var contributedWorkout: GeneratedWorkout?
        let mockContribute: (GeneratedWorkout, String) async throws -> Void = { workout, _ in
            contributedWorkout = workout
        }

        let result = SwiftDataAIWorkoutService.buildContribution(
            from: GeneratedWorkout(
                coachingSummary: "Test",
                exercises: [
                    GeneratedExercise(name: "Squat", sets: 3, reps: "5", weightLb: 200),
                ],
                questionnaire: QuestionnaireAnswers(
                    timeMinutes: 30, focus: .strength, energyLevel: .medium, equipment: .fullGym
                )
            )
        )

        #expect(result != nil)
        #expect(result!.exercises[0].weightLb == nil, "Contribution should have weights stripped")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AutoContributionTests 2>&1 | tail -20`
Expected: FAIL — `buildContribution` does not exist

**Step 3: Write minimal implementation**

In `SwiftDataAIWorkoutService`, add the static helper and update `generateWorkout()`:

```swift
/// Builds the stripped workout for public contribution. Static for testability.
static func buildContribution(from workout: GeneratedWorkout) -> GeneratedWorkout? {
    return workout.strippedForSharing()
}
```

Update the initializer to accept an optional `SharedWorkoutRepository`:

```swift
private let sharedRepository: (any SharedWorkoutRepository)?

init(
    modelContext: ModelContext,
    geminiService: GeminiWorkoutService = GeminiWorkoutService(),
    sharedRepository: (any SharedWorkoutRepository)? = nil
) {
    self.modelContext = modelContext
    self.geminiService = geminiService
    self.sharedRepository = sharedRepository
}
```

Update `generateWorkout()`:

```swift
func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
    let workout = await Self.generateWithFallback(context: context, geminiService: geminiService)
    guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
        throw AIWorkoutServiceError.encodingFailed
    }
    modelContext.insert(record)
    try? modelContext.save()

    // Auto-contribute anonymized copy to public DB
    if let sharedRepository {
        do {
            try await sharedRepository.contribute(workout, userID: context.userID)
            record.contributedToDatabase = true
            try? modelContext.save()
        } catch {
            print("[AIWorkoutService] Public contribution failed: \(error)")
        }
    }

    return workout
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AutoContributionTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift SundeeFundeTests/AIWorkoutTests.swift
git commit -m "feat: auto-contribute anonymized workouts to public DB on generation"
```

---

### Task 4: Wire `SharedWorkoutRepository` into the service at the call site

**Files:**
- Find and modify: the file that creates `SwiftDataAIWorkoutService` (likely in a ViewModel or App setup)

**Step 1: Find the call site**

```bash
grep -rn "SwiftDataAIWorkoutService(" SundeeFundee/ --include="*.swift"
```

**Step 2: Pass `CloudKitSharedWorkoutRepository` to the service**

At the call site where `SwiftDataAIWorkoutService` is instantiated, add:

```swift
let sharedRepo = CloudKitSharedWorkoutRepository(modelContext: modelContext)
let aiService = SwiftDataAIWorkoutService(
    modelContext: modelContext,
    sharedRepository: sharedRepo
)
```

**Step 3: Build to verify no errors**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire SharedWorkoutRepository into AI workout service for auto-contribution"
```

---

### Task 5: Run full test suite and fix coverage gaps

**Step 1: Run all tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -30`

**Step 2: Fix any failures or coverage gaps**

Check that all new public methods have test coverage. If any existing tests broke due to the new `sharedRepository` parameter on `SwiftDataAIWorkoutService.init`, update those call sites to pass `sharedRepository: nil` explicitly.

**Step 3: Commit fixes**

```bash
git add -A
git commit -m "test: fix coverage for public workout template auto-contribution"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `Domain/AIWorkout/GeneratedWorkout.swift` | Add `strippedForSharing()` method |
| `Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift` | Add `buildContributePayload()`, update `contribute()` to strip weights |
| `Repositories/Firebase/FirebaseAIWorkoutService.swift` | Add `sharedRepository` dependency, auto-contribute on generation |
| Call site (ViewModel/App) | Pass `CloudKitSharedWorkoutRepository` to service |
| `SundeeFundeTests/AIWorkoutTests.swift` | Tests for stripping, payload, auto-contribution |
