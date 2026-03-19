# Phase 2: CloudKit Activation - Research

**Researched:** 2026-03-19
**Domain:** SwiftData + CloudKit private database sync, entitlements, schema deployment, container error handling
**Confidence:** HIGH — all model audits performed by direct source-code inspection; CloudKit rules verified against official Apple documentation and multiple authoritative secondary sources

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SYNC-01 | CloudKit sync activated in production with verified schema compliance (all optionals, no unique constraints, optional relationships with inverses) | Two `@Attribute(.unique)` violations found in `GeneratedWorkoutRecord` and `SharedWorkoutTemplateRecord`; all other 20 models pass audit. Must be removed before `useCloudKit = true` |
| SYNC-02 | CloudKit production schema deployed via CloudKit Console before TestFlight distribution | Development environment auto-creates record types on first write; Production does NOT — manual Deploy step in CloudKit Console is required. Confirmed that skipping this step silently blocks sync in TestFlight |
| SYNC-03 | User's workout data syncs across all their Apple devices via iCloud without manual intervention | `ModelConfiguration(.private("iCloud.com.sundeefundee.app"))` is already wired; Release entitlement already has the iCloud container and CloudKit service entries; flipping `useCloudKit = true` in `makeSharedContainer` activates sync |
| SYNC-04 | Container open failure triggers a user-visible error instead of silently deleting the local store | Current `makeSharedContainer` silently calls `deleteStoreFiles()` and falls back to in-memory on any open failure — this must be replaced with a thrown error that the UI surfaces as an alert |
</phase_requirements>

---

## Summary

Phase 2 has four discrete deliverables: (1) remove two `@Attribute(.unique)` annotations that block CloudKit compatibility, (2) flip the `useCloudKit` flag and wire the Debug entitlement, (3) manually deploy the Production CloudKit schema via the CloudKit Console dashboard, and (4) replace silent store-deletion on container failure with a user-visible error alert.

The Release entitlement at `SundeeFundee/Resources/SundeeFundee.entitlements` already contains `iCloud.com.sundeefundee.app` and the CloudKit service key — no Release-config entitlement work is needed. The Debug entitlement at `SundeeFundee.Debug.entitlements` is currently an empty plist and must gain the same iCloud entries so that development builds can actually open the CloudKit container during local testing.

The `useCloudKit: Bool = false` default in `AppModelContainer.makeSharedContainer` is the production gating flag. Changing it to `true` (or passing `true` from `SundeeFundeeApp.init`) activates the CloudKit store path. The CloudKit container identifier `iCloud.com.sundeefundee.app` and the private DB configuration code are already correct — no `ModelConfiguration` changes are needed.

The two `@Attribute(.unique)` violations must be removed before the CloudKit path is enabled. CloudKit cannot enforce cross-device uniqueness atomically; if the container initializer encounters these annotations with a CloudKit-backed configuration it will throw an error, causing the app to fall back to local-persistent and never sync. The fix is to remove the attribute annotations and enforce uniqueness application-side (by checking before insert, or accepting last-write-wins behavior on id collision).

Schema deployment to Production is a manual step that must happen once — before the first TestFlight build goes out. Skipping it means iCloud sync silently fails for all TestFlight users because their app writes to the Development environment but their records are in the Production environment.

**Primary recommendation:** Implement in dependency order — (1) remove `@Attribute(.unique)`, (2) wire Debug entitlement + flip `useCloudKit`, (3) add container-failure alert, (4) deploy Production schema, (5) validate on two physical devices via TestFlight.

---

## Model Compatibility Audit

All 22 V12 models inspected. CloudKit requires: all stored properties optional or with default values; no `@Attribute(.unique)`; no `@Relationship(deleteRule: .deny)`; no non-optional properties without a declared default.

### Violations Found

| Model | Violation | Fix |
|-------|-----------|-----|
| `GeneratedWorkoutRecord` | `@Attribute(.unique) var id: String` (line 11) | Remove `@Attribute(.unique)` — enforce uniqueness application-side before inserting |
| `SharedWorkoutTemplateRecord` | `@Attribute(.unique) var id: String` (line 8) | Remove `@Attribute(.unique)` — enforce uniqueness application-side before inserting |

### All Other Models: PASS

| Model | Non-optional scalars? | Default values? | Enums stored as raw strings? | Relationships? | Status |
|-------|-----------------------|-----------------|------------------------------|----------------|--------|
| `User` | `id`, `name`, `experienceLevelRaw`, `primaryGoalRaw`, `genderRaw`, `appleUserID`, `cycleTrackingEnabled`, `onboardingComplete`, `createdAt`, `travelModeEnabled` | All have init-provided values | Yes (all enum properties use `*Raw: String`) | None | PASS |
| `ActiveCycle` | `id`, `userID`, `programID`, `cycleName`, `startDate`, `currentWeek`, `currentSessionID`, `statusRaw` | All init-provided | Yes | None | PASS |
| `CompletedWorkout` | `id`, `userID`, `activeCycleID`, `programID`, `week`, `day`, `sessionID`, `completedAt`, `durationSeconds` | All init-provided | N/A | None | PASS |
| `CompletedSet` | `id`, `userID`, `workoutID`, `exerciseName`, `setIndex`, `prescribedReps`, `isCompleted`, `completedAt` | All init-provided | Yes (scoringTypeRaw?) | None | PASS |
| `OneRepMax` | `id`, `userID`, `exerciseID`, `weightKg`, `date`, `isEstimated` | All init-provided | N/A | None | PASS |
| `PersonalRecord` | `id`, `userID`, `exerciseID`, `repMaxTypeRaw`, `weightKg`, `reps`, `achievedAt` | All init-provided | Yes | None | PASS |
| `LiftMax` | `id`, `userID`, `exerciseID`, `weightKg`, `date` | All init-provided | N/A | None | PASS |
| `PeriodLog` | `id`, `userID`, `startDate`, `flowLevelRaw` | All init-provided | Yes | None | PASS |
| `SymptomLog` | `id`, `userID`, `date`, `symptomID`, `severity` | All init-provided | N/A | None | PASS |
| `CycleSettings` | `id`, `userID`, `averageCycleLengthDays`, `averagePeriodLengthDays`, `lutealPhaseLengthDays`, `isTrackingEnabled`, `updatedAt` | All init-provided | N/A | None | PASS |
| `CycleAdaptationPreferences` | `id`, `userID`, `adaptationEnabled`, `fallbackPhase`, `updatedAt` | All init-provided | N/A | None | PASS |
| `InjuryProfile` | `id`, `userID`, `location`, `movementLimitations`, `recoveryGoal`, `statusRaw`, `createdAt`, `updatedAt`, `recoveryPhaseRaw`, `locationRegionsRaw`, `acknowledgedDisclaimerIDsRaw` | All init-provided (non-optionals get empty string defaults) | Yes | None | PASS |
| `EnrolledProgram` | `id`, `userID`, `programID`, `startDate`, `currentWeek`, `currentDay`, `statusRaw`, `completedWeeksRaw` | All init-provided | Yes | None | PASS |
| `EnrollmentEvent` | `id`, `enrollmentID`, `eventTypeRaw`, `occurredAt` | All init-provided | Yes | None | PASS |
| `BenchmarkDefinition` | `id`, `userID`, `name`, `category`, `workoutDescription`, `scoringTypeRaw`, `isPredefined`, `sortOrder` | All init-provided | Yes | None | PASS |
| `BenchmarkResult` | `id`, `userID`, `definitionID`, `scoreValue`, `notes`, `performedAt` | All init-provided | N/A | None | PASS |
| `PainLog` | `id`, `injuryProfileID`, `painLevel`, `recordedAt` | All init-provided | Yes (symptomTypeRaw?, intensityContextRaw?) | None | PASS |
| `ConditioningPR` | `id`, `userID`, `exerciseID`, `scoringTypeRaw`, `bestValue`, `achievedAt` | All init-provided | Yes | None | PASS |
| `GeneratedWorkoutRecord` | `@Attribute(.unique) var id` | — | N/A | None | **FAIL** |
| `SharedWorkoutTemplateRecord` | `@Attribute(.unique) var id` | — | N/A | None | **FAIL** |
| `BarbellPreset` | `id`, `userID`, `name`, `weightKg`, `isBuiltIn`, `sortOrder` | All init-provided | N/A | None | PASS |
| `ExerciseBarMapping` | `id`, `userID`, `exerciseName`, `barbellPresetID` | All init-provided | N/A | None | PASS |

**Note on `Benchmark` (V1 stub):** This model lives in `AppSchemaV1` only and is not in V12. It is a migration tombstone, not an active model. No audit needed.

---

## Standard Stack

### Core (all already present — no new dependencies needed)

| Component | Current State | Phase 2 Uses |
|-----------|---------------|-------------|
| SwiftData `ModelContainer` | V12 schema, `migrationPlan:` applied to both store paths | CloudKit path enabled by flipping `useCloudKit` flag |
| CloudKit private DB | `cloudKitDatabase: .private("iCloud.com.sundeefundee.app")` in `.cloudKit` case | Already configured, just gated off |
| iCloud entitlements | Release entitlement complete; Debug entitlement empty | Debug entitlement must gain iCloud entries |
| `project.yml` / XcodeGen | `cloudKit.framework` SDK dependency present in target | No changes needed for framework linkage |
| SwiftUI `Alert` | Used throughout the app | Container failure alert is new |

No new SPM packages, frameworks, or third-party libraries are needed for any deliverable in this phase.

### Installation

No `npm install` or `swift package resolve` steps required. All dependencies are already present.

---

## Architecture Patterns

### Recommended Project Structure (minimal changes)

```
SundeeFundee/
├── App/
│   └── AppModelContainer.swift   ← Change useCloudKit default to true; add error-throwing path for container failure
├── Models/
│   ├── GeneratedWorkoutRecord.swift  ← Remove @Attribute(.unique) from id
│   └── SharedWorkoutTemplateRecord.swift  ← Remove @Attribute(.unique) from id
├── Resources/
│   └── SundeeFundee.Debug.entitlements  ← Add iCloud container + CloudKit service entries
└── Features/Shell/
    └── (or AppRootView.swift)    ← Surface container-failure error as SwiftUI Alert
```

### Pattern 1: Flipping the CloudKit Flag

The `useCloudKit` parameter in `makeSharedContainer` is the sole production gate. It defaults to `false`; changing it to `true` routes through the CloudKit path.

**Current state:**
```swift
// AppModelContainer.swift line 22 — change default value
static func makeSharedContainer(
    isRunningTests: Bool = isRunningTests,
    useCloudKit: Bool = false,   // ← change to true
    ...
```

**The CloudKit path is already fully wired (no other changes needed in this function):**
```swift
if useCloudKit {
    do {
        return try makeContainer(.cloudKit)  // uses iCloud.com.sundeefundee.app
    } catch {
        log("AppModelContainer: CloudKit container failed: \(error). Trying local persistent store.")
        // falls through to local
    }
}
```

### Pattern 2: Removing @Attribute(.unique) — Application-Side Deduplication

CloudKit uses a last-write-wins merge strategy for conflicting records. On `id` fields (UUID strings), collisions in practice are astronomically unlikely. Removing the annotation and doing nothing else is safe for UUID-keyed models.

For defensive deduplication before insert (optional hardening):
```swift
// Before inserting a GeneratedWorkoutRecord
let existing = try? modelContext.fetch(
    FetchDescriptor<GeneratedWorkoutRecord>(
        predicate: #Predicate { $0.id == newRecord.id }
    )
)
guard existing?.isEmpty != false else { return }  // already present
modelContext.insert(newRecord)
```

### Pattern 3: Debug Entitlement — iCloud Entries

The Debug entitlement must mirror the Release entitlement's iCloud entries. Without this, development builds fail to open the CloudKit container.

```xml
<!-- SundeeFundee.Debug.entitlements — add these keys -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.sundeefundee.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### Pattern 4: Container-Failure Alert (SYNC-04)

The current `makeSharedContainer` silently deletes store files on failure and falls back to in-memory. Per SYNC-04, the user must see a clear error message. The recommended approach is to make the failure observable and display a SwiftUI `Alert`.

**Approach A — @Observable error state on AppModelContainer (recommended):**

Add an `@Observable` class (or use `@Environment`) that holds the container error state, set it when `makeContainer(.cloudKit)` throws, and bind it to an `.alert` modifier at the root view level.

```swift
// New observable wrapper (or extend AppRootView)
@Observable
class ContainerHealth {
    var containerOpenError: Error? = nil
    var showAlert: Bool { containerOpenError != nil }
}
```

In `makeSharedContainer`, instead of silently recovering from the CloudKit open failure, capture the error and surface it through the `ContainerHealth` object:

```swift
if useCloudKit {
    do {
        return try makeContainer(.cloudKit)
    } catch {
        containerHealth.containerOpenError = error
        // Do NOT delete local store — fall through to local-persistent as read-only temp copy
        let local = try? makeContainer(.localPersistent)
        return local ?? (try makeContainer(.fallbackInMemory))
    }
}
```

At the root view:
```swift
// AppRootView.swift
.alert("iCloud Sync Unavailable", isPresented: $containerHealth.showAlert) {
    Button("OK") { }
} message: {
    Text("Your data is safe on this device, but iCloud sync is currently unavailable. Please check your iCloud settings and restart the app.")
}
```

**What NOT to do:** Delete the local store files on CloudKit open failure (current behavior). This loses the user's data. The safe fallback is local-persistent read-only, with the alert explaining what happened.

### Pattern 5: Production Schema Deployment (Manual Step)

CloudKit Development environment auto-creates record types as data is written. Production environment does NOT — the schema must be manually deployed.

**Process (one-time, before each TestFlight release that adds new record types):**
1. Run the app in Development against the CloudKit container (automatically populates Development schema)
2. Navigate to [CloudKit Console](https://icloud.developer.apple.com/dashboard) → select container `iCloud.com.sundeefundee.app` → Schema tab
3. Click "Deploy Schema Changes to Production"
4. Confirm the diff — all V12 record types should appear
5. Deployment is irreversible per record type (types cannot be deleted from Production once deployed)

**For this phase:** All 22 V12 record types (minus the two fixed violations) need to be present in Development schema before deployment. Running the CloudKit-enabled app once and writing one record of each type populates the Development schema automatically, or use CloudKit Dashboard to add missing record types manually.

### Anti-Patterns to Avoid

- **Deleting local store on CloudKit container failure:** This silently destroys user data. Current code does this — it must be replaced with an alert + local fallback.
- **Leaving `@Attribute(.unique)` with a CloudKit-backed store:** The container initializer will throw; the app silently falls back to local-persistent and never syncs.
- **Deploying to Production before removing `@Attribute(.unique)`:** The Production schema will contain a unique constraint that CloudKit cannot enforce, causing unpredictable sync behavior.
- **Setting `useCloudKit = true` without Debug entitlement:** Development builds will fail to open the CloudKit container (entitlement mismatch), making local testing of the CloudKit path impossible.
- **Assuming Development schema == Production schema:** They are entirely independent. A new model type added in Development is invisible to Production until explicitly deployed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-device data sync | Custom sync engine | SwiftData + CloudKit private DB (already wired) | Apple manages conflict resolution, retry, background delivery, delta sync |
| Uniqueness enforcement | Custom de-dup middleware | Remove `@Attribute(.unique)` + check-before-insert at call sites | CloudKit last-write-wins on UUID fields is safe in practice; atomic uniqueness is impossible across distributed devices |
| iCloud availability detection | Custom CKContainer availability check | Let ModelContainer throw on failure and surface the error | ModelContainer initialization failure is the canonical signal; polling iCloud availability separately is redundant |
| Schema migration | Manual record transforms | `AppSchemaMigrationPlan` (already complete through V12) | SwiftData handles lightweight migrations automatically on container open |

---

## Common Pitfalls

### Pitfall 1: @Attribute(.unique) Silently Falls Back to Local Store

**What goes wrong:** With `useCloudKit = true` but `@Attribute(.unique)` still present, `makeContainer(.cloudKit)` throws. The fallback logic runs silently, the app opens the local persistent store, appears to work, but never syncs. No error is shown.

**Why it happens:** `@Attribute(.unique)` is incompatible with CloudKit (confirmed by Apple Developer Forums thread 656380 and multiple authoritative sources). CloudKit cannot enforce atomic uniqueness across distributed devices.

**How to avoid:** Remove `@Attribute(.unique)` from `GeneratedWorkoutRecord.id` and `SharedWorkoutTemplateRecord.id` before flipping `useCloudKit`. Add a smoke test that attempts to open a CloudKit-configured container in the simulator and verifies no throw.

**Warning signs:** App runs, data saves locally, but no records appear in CloudKit Console → Data Browser.

---

### Pitfall 2: Debug Entitlement Missing → Development Builds Cannot Test CloudKit Path

**What goes wrong:** `SundeeFundee.Debug.entitlements` is currently empty. Development builds use this entitlement file. Without `com.apple.developer.icloud-container-identifiers`, the CloudKit container open fails with an entitlement error.

**Why it happens:** Release and Debug use separate entitlement files; the Debug one was never populated.

**How to avoid:** Add the iCloud container and CloudKit service entries to `SundeeFundee.Debug.entitlements` as part of Plan 02-02.

**Warning signs:** Dev build on device throws "CloudKit container not found" or similar entitlement error on first launch with `useCloudKit = true`.

---

### Pitfall 3: TestFlight Sync Fails Because Production Schema Was Never Deployed

**What goes wrong:** TestFlight builds use the Production CloudKit environment. If the schema has never been deployed, every write that SwiftData attempts to sync fails with a "record type not found" error. Data stays on device, no cross-device sync happens.

**Why it happens:** Development environment creates record types on first write (JIT schema). Production environment is read-only from a schema perspective until explicitly deployed via CloudKit Console.

**How to avoid:** Complete the Production schema deployment step (Plan 02-03) before submitting any TestFlight build. Verify in CloudKit Console → Production → Schema that all expected record types are listed.

**Warning signs:** App appears to work normally on a single device in TestFlight, but data does not appear on a second device. CloudKit Console → Production → Data shows no records.

---

### Pitfall 4: Silent Store Deletion on Container Failure (Current SYNC-04 Bug)

**What goes wrong:** The current fallback logic in `makeSharedContainer` calls `deleteStoreFiles()` when the local container fails to open (after the CloudKit failure). If CloudKit fails and the local store is also corrupted, the user loses all local data without any warning.

**Why it happens:** The current design prioritizes "app always opens" over "user knows their data is at risk."

**How to avoid:** Replace silent deletion with: (1) attempt CloudKit → failure → capture error into observable state → (2) attempt local-persistent as read-only safe copy → (3) show alert explaining iCloud sync unavailable, data is safe on device. Only delete files if the local store itself throws AND the user explicitly confirms after seeing an alert.

**Warning signs:** User reports "all my workouts disappeared" after app update.

---

### Pitfall 5: All-Models-Optional Requirement Is Already Met — Don't Over-Engineer

**What goes wrong:** Developers sometimes read "CloudKit requires all properties to be optional" and start making every field optional, breaking the model's initialization contract and introducing force-unwraps throughout the codebase.

**Why it happens:** Misreading the CloudKit requirement. The actual rule is: non-optional properties must have a declared default value or be provided in the `init`. Most of the 20 compliant models already satisfy this via their initializers.

**How to avoid:** The audit above shows all 20 passing models are fine as-is. Only the two `@Attribute(.unique)` violations need to change. No property optionality changes are required.

**Warning signs:** PRs that change `var name: String` to `var name: String?` across model files — this is unnecessary churn.

---

### Pitfall 6: Production Schema Deployment Is One-Way

**What goes wrong:** Record types deployed to Production cannot be deleted (CloudKit schema is append-only in Production). If you deploy a schema with incorrect field names, those fields remain in Production permanently.

**Why it happens:** CloudKit Production schema protects existing user data by preventing field/type deletion.

**How to avoid:** Verify the Development schema in CloudKit Console → Data Browser before deploying. Confirm all 20 record type names match the Swift model class names that SwiftData generates (SwiftData uses the class name as the CKRecord type name).

**Warning signs:** Record types in Production with typos or stale names that can never be removed.

---

## Code Examples

### Remove @Attribute(.unique) — GeneratedWorkoutRecord

```swift
// Source: SundeeFundee/Models/GeneratedWorkoutRecord.swift
// BEFORE:
@Attribute(.unique) var id: String

// AFTER (remove the attribute annotation, keep the property):
var id: String
```

### Remove @Attribute(.unique) — SharedWorkoutTemplateRecord

```swift
// Source: SundeeFundee/Models/SharedWorkoutTemplateRecord.swift
// BEFORE:
@Attribute(.unique) var id: String  // CloudKit record name

// AFTER:
var id: String  // CloudKit record name
```

### Flip useCloudKit Flag

```swift
// Source: AppModelContainer.swift — makeSharedContainer signature
// BEFORE:
static func makeSharedContainer(
    isRunningTests: Bool = isRunningTests,
    useCloudKit: Bool = false,

// AFTER:
static func makeSharedContainer(
    isRunningTests: Bool = isRunningTests,
    useCloudKit: Bool = true,
```

### Debug Entitlement — Complete iCloud Entries

```xml
<!-- SundeeFundee/Resources/SundeeFundee.Debug.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.sundeefundee.app</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

### Container Failure Alert — AppRootView Integration

```swift
// AppRootView.swift — add container health state + alert modifier
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState: AppState = AppState()
    @State private var subscriptionService = SubscriptionService()
    @State private var cloudKitError: Error? = nil   // NEW

    var body: some View {
        Group {
            // ... existing destination switch ...
        }
        .environment(appState)
        .environment(subscriptionService)
        .task { await Self.restoreSessionIfNeeded(...) }
        .task { await subscriptionService.loadStatus() }
        // NEW: surface container open failure
        .alert(
            "iCloud Sync Unavailable",
            isPresented: Binding(
                get: { cloudKitError != nil },
                set: { if !$0 { cloudKitError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { cloudKitError = nil }
        } message: {
            Text("Your data is safe on this device, but iCloud sync could not start. Check your iCloud account in Settings and restart the app.")
        }
    }
}
```

**How `cloudKitError` gets populated:** Pass an error-capturing closure or `@Observable` object into `AppModelContainer.makeSharedContainer` so that when the CloudKit path fails, the error is set before falling through to local-persistent. The existing `log:` closure parameter can be replaced with or augmented by an `onCloudKitFailure: ((Error) -> Void)?` parameter.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `useCloudKit = false` (dev gate) | `useCloudKit = true` (Phase 2 activates this) | Enables iCloud sync for all users |
| `@Attribute(.unique)` on id fields | Remove annotation; enforce app-side | Required before CloudKit path can open without throwing |
| Silent store deletion on failure | User-visible alert + local-persistent fallback | Meets SYNC-04; preserves user data |
| Development-only schema (JIT) | Production schema deployed via CloudKit Console | Required for TestFlight/App Store sync |

**Note on Development vs Production CloudKit environments:** The app already connects to the correct container identifier. The environment (Dev vs Prod) is determined automatically by whether the build is signed with a development or distribution certificate — no code change is needed for this distinction.

---

## Open Questions

1. **Who calls `makeSharedContainer(useCloudKit: true)` — static default or call-site parameter?**
   - What we know: `AppModelContainer.shared` calls `makeSharedContainer()` with all defaults. Changing `useCloudKit: Bool = false` to `= true` in the default is the simplest approach. Alternatively, the parameter could be passed from `SundeeFundeeApp.init()` based on a compile-time flag or build configuration.
   - What's unclear: Whether a build-configuration-based gate (debug vs release) is preferable to a single default-`true` value. The current code structure uses `isRunningTests` as a precedent for environment-based branching.
   - Recommendation: Change the default to `true` directly. The test suite already gates on `isRunningTests: Bool` and uses in-memory containers — they will not be affected. Development builds will use the CloudKit path if the Debug entitlement is added (which is part of this phase).

2. **Container-failure error state: @Observable class vs Environment injection vs SceneStorage?**
   - What we know: `AppRootView` uses `@State private var appState: AppState` and `@State private var subscriptionService = SubscriptionService()` — both are `@Observable`. Adding `@State private var cloudKitError: Error? = nil` is a localized approach but requires AppModelContainer to communicate the error outward.
   - What's unclear: The cleanest wiring — should `AppModelContainer.shared` be a class that holds an `@Observable` property, or should the error be passed via a closure into `makeSharedContainer`?
   - Recommendation: Extend `makeSharedContainer` with an `onCloudKitFailure: ((Error) -> Void)?` closure parameter (defaulting to `nil`). In `SundeeFundeeApp.init()`, pass a closure that sets an `@State` error variable. This keeps `AppModelContainer` as a pure enum with no retained state.

3. **AppInfraCoverageTests references `AppSchemaV10.models` — update needed?**
   - What we know: `AppInfraCoverageTests.makeContainer()` uses `AppSchemaV10.models` on line 12. This is for the test helper container only and does not affect production. However, it may cause test failures if V10 models don't include all V12 additions used by the test body.
   - What's unclear: Whether any of the Phase 2 test additions will require the full V12 schema in the test helper container.
   - Recommendation: The planner should note this as a potential test-helper update in Plan 02-01.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`) — Xcode 16 native |
| Config file | Xcode scheme / xctest target `SundeeFundeTests` |
| Quick run command | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/AppInfraCoverageTests` |
| Full suite command | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-01 | `GeneratedWorkoutRecord` has no `@Attribute(.unique)` | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` (schema validation) | Partial — new test needed |
| SYNC-01 | `SharedWorkoutTemplateRecord` has no `@Attribute(.unique)` | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` | Partial — new test needed |
| SYNC-01 | CloudKit-configured container opens without throwing | smoke | Manual device test with CloudKit entitlement — cannot run in simulator without real iCloud account | N/A (manual only) |
| SYNC-02 | Production schema contains all 20 V12 record types | manual | CloudKit Console → Production → Schema visual inspection | N/A (manual only) |
| SYNC-03 | Workout written on Device A appears on Device B after CloudKit sync | e2e | Two-device physical test — cannot automate in unit tests | N/A (manual only) |
| SYNC-04 | Container CloudKit failure shows alert instead of silently wiping data | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` (inject failing container) | No — Wave 0 |

### Sampling Rate

- **Per task commit:** Run `AppInfraCoverageTests` after any container or model change
- **Per wave merge:** Full suite — `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green + two-device physical sync test passing before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] New test in `AppInfraCoverageTests.swift` — verifies `GeneratedWorkoutRecord` and `SharedWorkoutTemplateRecord` models have no `@Attribute(.unique)` by asserting a CloudKit-configured container opens without throwing (using test-account credentials, or by verifying the Schema object has no unique constraints via reflection)
- [ ] New test in `AppInfraCoverageTests.swift` — `makeSharedContainer(useCloudKit: true, ...)` with a stub `makeContainer` that throws on `.cloudKit` and verifies `onCloudKitFailure` closure is invoked and the alert state is set
- [ ] Manual test checklist — two-device TestFlight sync validation (Device A write → Device B sync) documented as a verification step in Plan 02-05

---

## Sources

### Primary (HIGH confidence — direct source-code inspection)

- `/SundeeFundee/Models/GeneratedWorkoutRecord.swift` — confirmed `@Attribute(.unique) var id: String` at line 11
- `/SundeeFundee/Models/SharedWorkoutTemplateRecord.swift` — confirmed `@Attribute(.unique) var id: String` at line 8
- `/SundeeFundee/App/AppModelContainer.swift` — confirmed `useCloudKit: Bool = false` gate; CloudKit container config uses `iCloud.com.sundeefundee.app`; silent `deleteStoreFiles()` fallback on failure
- `/SundeeFundee/Resources/SundeeFundee.entitlements` — confirmed Release entitlement has `iCloud.com.sundeefundee.app` + CloudKit service
- `/SundeeFundee/Resources/SundeeFundee.Debug.entitlements` — confirmed Debug entitlement is empty (missing iCloud entries)
- `/SundeeFundee/App/AppSchemaV12.swift` — confirmed 22 models in V12
- `/SundeeFundee/App/AppSchemaMigrationPlan.swift` — confirmed 8 schema versions, 7 migration stages, all lightweight
- All 22 model files in `/SundeeFundee/Models/` — inspected all properties for optionality and attribute annotations
- `project.yml` — confirmed `cloudKit.framework` SDK dependency is present; Debug/Release entitlement file paths are correctly mapped

### Secondary (MEDIUM confidence — multiple credible sources agree)

- Apple Developer Forums thread 656380: "CloudKit integration does not support unique constraints" — confirms `@Attribute(.unique)` incompatibility
- [fatbobman.com — Rules for Adapting Data Models to CloudKit](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) — authoritative community reference, consistent with Apple documentation
- [fatbobman.com — Fixing CloudKit Sync in Production: Deploying Schema](https://fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login/) — confirms Production schema deployment requirement and JIT vs Production environment distinction
- [Apple Developer Documentation — Syncing model data across a person's devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) — official SwiftData+CloudKit guidance

### Tertiary (LOW confidence — single source, included for awareness)

- Multiple community reports (Hacking with Swift Forums, Medium) note that simulator-based CloudKit testing requires a real iCloud-signed-in Apple ID in the simulator; a sandbox account in the Development environment is sufficient for schema validation but full sync testing requires two physical devices.

---

## Metadata

**Confidence breakdown:**
- Model audit (SYNC-01 violations): HIGH — direct code inspection of all 22 model files
- CloudKit `@Attribute(.unique)` incompatibility: HIGH — confirmed Apple Developer Forums + multiple authoritative sources + consistent with V1 schema comment "no @Attribute(.unique) for CloudKit compatibility"
- Flag flip + entitlement wiring (SYNC-03): HIGH — direct inspection of `AppModelContainer.swift`, both entitlement files, and `project.yml`
- Production schema deployment process (SYNC-02): MEDIUM — confirmed by fatbobman and community sources; Apple's official doc confirms the Development vs Production environment distinction
- Container failure alert pattern (SYNC-04): MEDIUM — SwiftUI `Alert` pattern is well-established; specific wiring to `AppModelContainer` error state is a design choice with multiple valid implementations

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (stable APIs — SwiftData + CloudKit are not fast-moving at this point)
