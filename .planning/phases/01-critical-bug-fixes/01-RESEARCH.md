# Phase 1: Critical Bug Fixes - Research

**Researched:** 2026-03-18
**Domain:** Swift / SwiftData / StoreKit 2 / Keychain / Gemini Prompt Engineering
**Confidence:** HIGH — all findings derived from direct source-code inspection of the live codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**AI Weight Unit (FIX-01)**
- Parameterize the system prompt in GeminiPromptBuilder — inject user's unit so bar weights, plate values, dumbbell/kettlebell lists are all in the correct unit
- Maintain a separate kg equipment list with real gym values (20 kg bar, 1.25–25 kg plates, standard kg dumbbell/kettlebell sets) — do not convert the lbs list
- Convert user's known maxes to their selected unit before sending to Gemini — no mixed unit signals in the prompt
- All prompt parameterization happens client-side in GeminiPromptBuilder — Cloudflare Worker stays a dumb proxy

**Guest UUID & Data Migration (FIX-03)**
- Generate stable UUID at first launch, store in Keychain using the existing KeychainHelper pattern (new key alongside appleUserID)
- On Apple sign-in: silent merge — seamlessly keep all local data, no user prompt
- Batch update all SwiftData records from guest UUID to Apple user ID at sign-in time
- Flag-based retry — set a "migration pending" flag before starting; if still set on next launch, retry the batch

**StoreKit Cold-Launch Gate (FIX-04)**
- Default to free tier on cold launch — do not read cached tier from UserDefaults
- Once StoreKit verification completes (typically <1 second), silently upgrade to verified tier
- Remove UserDefaults cache entirely — only trust live StoreKit verification; if offline, default to free
- UI transition style: Claude's discretion

**Sign-Out vs Delete-Account (FIX-02)**
- Sign-out: Clear auth state + wipe user-specific workout data, but preserve app preferences (onboarding complete, weight unit, theme). After sign-out, user returns to guest mode
- Delete-account: Destructive confirmation dialog. Wipe all V12 SwiftData models, clear all Keychain entries (Apple ID + guest UUID), reset to fresh install state
- Both paths must reference V12 schema (current), not stale V10

**SwiftData Migration Path (FIX-05)**
- Apply `migrationPlan: AppSchemaMigrationPlan.self` to the local persistent store path (currently only applied to CloudKit path)

### Claude's Discretion
- StoreKit tier upgrade UI transition (invisible vs subtle animation)
- Exact error handling for edge cases in batch userID migration
- Migration plan application approach for local store

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FIX-01 | AI workout generation prescribes weights in the user's selected unit (lbs or kg), not hardcoded lbs | `GeminiPromptBuilder.systemPrompt` is a static string with hardcoded lbs rules; `WorkoutGenerationContext.weightUnit` exists but is unused by the system prompt; `ExerciseMax.weightLb` always stores in lbs and must be converted before sending |
| FIX-02 | Sign-out and account deletion wipe all model types through current schema (V12), not stale V10 references | `AppState.signOut` and `AppState.deleteAccountAndData` both iterate `AppSchemaV10.models` which is missing `BarbellPreset` and `ExerciseBarMapping` (added in V11/V12) |
| FIX-03 | Guest mode uses a stable UUID as userID instead of empty string, preserving data on sign-in upgrade | `AppState.signInAsGuest()` sets `currentUserID = nil`; `AuthService` already has `KeychainHelper` integration; guest UUID key just needs to be added |
| FIX-04 | Subscription tier defaults to free on cold launch until StoreKit verification completes | `SubscriptionService.init()` reads UserDefaults on line 70 before StoreKit verification; that read must be removed |
| FIX-05 | SwiftData migration plan is applied to both CloudKit and local persistent store paths | `AppModelContainer.makeContainer(.localPersistent)` at line 95–96 creates the container without `migrationPlan:` parameter; `.cloudKit` case at line 93 correctly includes it |
</phase_requirements>

---

## Summary

All five bugs in this phase have been confirmed by direct code inspection. Each has a narrow, well-understood fix. There are no ambiguous root causes, no third-party API unknowns, and no risky refactors. The primary risk surface is side effects: the prompt builder change affects the AI response schema (the field is still called `weightLb` in JSON), and the sign-out schema change must not accidentally wipe models it shouldn't. Tests already cover most affected units and will need targeted updates.

**FIX-01 (AI weight unit)** requires the most lines of change because it needs two separate equipment lists in the system prompt (one lbs, one kg), conversion of known maxes before embedding them, and a conversion of body weight. The JSON response schema field `weightLb` also needs renaming or the display layer needs a unit-aware converter — this is the one open question requiring a decision.

**FIX-02 (schema wipe)** is a one-line change in `AppState.swift`: replace `AppSchemaV10.models` with `AppSchemaV12.models` in both `signOut` and `deleteAccountAndData`. Sign-out additionally needs adjusted scope per the locked decision (wipe workout data only, not preferences).

**FIX-03 (guest UUID)** requires adding a `guestUserID` Keychain key to `KeychainHelper`, generating/loading it at first launch in `AppState.signInAsGuest()`, and implementing a batch userID update in `AuthService.resolveAfterAppleSignIn` that migrates all SwiftData records owned by the guest UUID to the new Apple user ID.

**FIX-04 (StoreKit gate)** is a one-line removal in `SubscriptionService.init()`: delete the `UserDefaults.standard.string` read (line 69–70). The existing `loadStatus()` async method is already wired correctly; it just needs to be the only source of truth. The existing test `restoresTierFromUserDefaults` will break and must be updated (or removed) since the behavior it tests is being intentionally deleted.

**FIX-05 (SwiftData migration path)** is a one-line addition in `AppModelContainer.makeContainer(.localPersistent)`: add `migrationPlan: AppSchemaMigrationPlan.self` to the `ModelContainer` initializer call.

**Primary recommendation:** Implement fixes in dependency order — FIX-05 first (migration safety), then FIX-02 (schema correctness), then FIX-04 (StoreKit gate), then FIX-03 (guest UUID), then FIX-01 (AI weight prompt) — each as its own atomic plan.

---

## Standard Stack

### Core (already in project — no new dependencies needed)

| Component | Current State | Fix Uses |
|-----------|---------------|----------|
| SwiftData | V12 schema, migration plan exists | FIX-02, FIX-05 |
| Security framework / Keychain | `KeychainHelper` with `kSecClassGenericPassword` pattern | FIX-03 |
| StoreKit 2 | `Transaction.currentEntitlements` async stream in `loadStatus()` | FIX-04 |
| `GeminiPromptBuilder` | Static string system prompt, `userPrompt(from:)` function | FIX-01 |
| `WeightUnitConversion` | `value(fromKilograms:unit:)`, `kilograms(from:unit:)` | FIX-01 |

No new packages, frameworks, or SPM dependencies are needed for any fix in this phase.

---

## Architecture Patterns

### Established Patterns to Follow

**KeychainHelper pattern (FIX-03)**
- Service: `"com.sundeefundee.app"`, account key differentiates entries
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — use same accessibility for guest UUID key
- Pattern: delete-then-add (not update) for idempotency
- New key: `"guestUserID"` alongside existing `"appleUserID"`

**SwiftData batch delete pattern (FIX-02)**
```swift
// Source: AppState.swift (existing pattern — just needs V12 instead of V10)
let allModelTypes: [any PersistentModel.Type] = AppSchemaV12.models
for type in allModelTypes {
    try? modelContext.delete(model: type)
}
try? modelContext.save()
```

**SwiftData batch update pattern (FIX-03 — guest UUID migration)**
```swift
// Fetch all records with old userID, update to new userID
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.id == guestUserID }
)
// Repeat for each model type that has a userID field
```

**ModelContainer with migrationPlan (FIX-05)**
```swift
// Source: AppModelContainer.swift line 93 (cloudKit case — pattern to replicate)
return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
```

**SubscriptionService init pattern (FIX-04 — after fix)**
```swift
init() {
    // currentTier starts as .free (default property value)
    // NO UserDefaults read here
    startObservingTransactions()
}
```

### Recommended Project Structure (no structural changes needed)

All fixes are in-place edits to existing files:

```
SundeeFundee/
├── App/
│   ├── AppModelContainer.swift   ← FIX-05: add migrationPlan to localPersistent case
│   └── AppState.swift            ← FIX-02: V10 → V12; FIX-03: guest UUID generation
├── Auth/
│   ├── AuthService.swift         ← FIX-03: batch userID migration on Apple sign-in
│   └── KeychainHelper.swift      ← FIX-03: add guestUserID key/methods
├── Repositories/Gemini/
│   └── GeminiPromptBuilder.swift ← FIX-01: parameterize system prompt by weight unit
└── Services/
    └── SubscriptionService.swift ← FIX-04: remove UserDefaults read in init()
```

### Anti-Patterns to Avoid

- **Referencing AppSchemaVN.models for schema wipe:** Always use `AppSchemaV12.models` (current) or a computed property that stays in sync with the latest schema. Using any version-pinned list will rot.
- **Converting lbs lists to kg in the Gemini prompt:** The decision locks in separate native lists — do not mathematically convert the lbs equipment list. Converted values produce unrealistic numbers (45 lb bar → 20.4 kg).
- **Reading UserDefaults for tier in SubscriptionService:** After FIX-04, the only source of truth is live StoreKit verification. Writing back to UserDefaults in `setTier` is safe (for other purposes) but reading on init is what creates the security window.
- **Batch-updating only User records for guest migration:** All models that have a `userID` field must be updated — check `CompletedWorkout`, `CompletedSet`, `InjuryProfile`, `PainLog`, `BenchmarkResult`, `ConditioningPR`, `GeneratedWorkoutRecord`, `EnrolledProgram`, `BarbellPreset`, `ExerciseBarMapping`. Missing any creates orphaned data.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Keychain persistence | Custom file/UserDefaults storage | `Security` framework via existing `KeychainHelper` pattern | Survives reinstall, encrypted at rest, OS-managed |
| SwiftData model wipe | Custom deletion loops | `modelContext.delete(model:)` bulk API | Single-call bulk delete, handles relationships |
| StoreKit verification | Custom receipt parsing | `Transaction.currentEntitlements` async stream | Apple-signed, handles renewals, handles revocations |
| Weight unit conversion | Custom math | `WeightUnitConversion` (already in Domain) | Correct constant (2.2046226218), tested |

---

## Common Pitfalls

### Pitfall 1: JSON response schema field named `weightLb` after FIX-01
**What goes wrong:** After fixing the system prompt to prescribe kg, Gemini still returns a field called `weightLb` per the response schema. The display layer reads this as lbs and shows correct numbers for lbs users but still has a semantic mismatch for kg users.
**Why it happens:** The response schema in `GeminiPromptBuilder.responseSchema` defines the field as `"weightLb": ["type": "number"]`. The field name is cosmetic — Gemini fills it with whatever unit the prompt instructs.
**How to avoid:** Two valid approaches: (a) rename the schema field to `"weight"` and update `GeminiResponseParser` and `GeneratedWorkout` model to match, or (b) keep `weightLb` as a display artifact and add a `weightUnit: String` field to the response so the display layer knows the unit. Option (a) is cleaner. Decide before implementing FIX-01 Task 1.
**Warning signs:** kg users see correct values at generation time but workout history shows incorrect values if the unit is not persisted alongside the weight.

### Pitfall 2: V12 model list in sign-out scope is too broad
**What goes wrong:** Sign-out (per the locked decision) should NOT wipe all V12 models — it should wipe user-specific workout data while preserving app preferences. Using the full `AppSchemaV12.models` list in `signOut()` would also wipe `User` (which contains weight unit preference), `CycleSettings`, and other preference-like models.
**Why it happens:** The locked decision distinguishes sign-out from delete-account: sign-out returns to guest mode; delete-account wipes everything.
**How to avoid:** In `AppState.signOut()`, delete only workout-data models (e.g., `CompletedWorkout`, `CompletedSet`, `GeneratedWorkoutRecord`, `EnrolledProgram`, `BenchmarkResult`, `ConditioningPR`). The `User` record, `CycleSettings`, `InjuryProfile`, etc. remain. In `deleteAccountAndData()`, use the full `AppSchemaV12.models` list.
**Warning signs:** After sign-out, user's weight unit resets to default on next launch — that means `User` was incorrectly deleted.

### Pitfall 3: Guest UUID not generated before sign-in flow starts
**What goes wrong:** If guest UUID is only generated at sign-in time (not at first app launch), the window between first launch and first sign-in produces data recorded with no userID, which can't be migrated.
**Why it happens:** Easy to wire UUID generation to the sign-in button press rather than to app launch.
**How to avoid:** Generate (or load) the guest UUID in `AppState.signInAsGuest()` which is called at launch when no Apple credential is found. Store to Keychain immediately. Use this UUID as `currentUserID` in guest mode.
**Warning signs:** `currentUserID` is nil during guest session — data cannot be queried by userID.

### Pitfall 4: Migration pending flag lost if app is force-quit during batch update
**What goes wrong:** Batch updating guest UUID → Apple ID across potentially hundreds of SwiftData records can take multiple event loop ticks. If the app is killed mid-batch, some records have been updated and some haven't.
**Why it happens:** No atomicity guarantee across a multi-record batch in SwiftData without explicit transaction handling.
**How to avoid:** Set a `UserDefaults` flag (e.g., `"guestMigrationPending"`) before starting the batch. Clear it only after `modelContext.save()` succeeds. On each launch in `AppState`, check this flag and re-run migration if set.
**Warning signs:** After force-quit during sign-in, user sees duplicate or partial workout history.

### Pitfall 5: Existing test `restoresTierFromUserDefaults` contradicts FIX-04
**What goes wrong:** `SubscriptionServiceTests.restoresTierFromUserDefaults` explicitly sets a UserDefaults value and expects `SubscriptionService.init()` to read it. After removing that read in FIX-04, this test will fail.
**Why it happens:** The test was written to validate behavior that FIX-04 intentionally removes.
**How to avoid:** Delete or update this test as part of FIX-04. The correct new behavior (always starts free) is already covered by `defaultsToFree()`.
**Warning signs:** Test suite reports failures in `SubscriptionServiceTests` after FIX-04 is applied.

### Pitfall 6: Maxes stored as `weightLb` in `ExerciseMax` — double-converting for kg users
**What goes wrong:** `ExerciseMax.weightLb` stores the value in pounds. The existing `userPrompt` code embeds it as-is with a "lb" label. For kg users, both the label and the value need to change.
**Why it happens:** `ExerciseMax` was designed lbs-first with no unit field.
**How to avoid:** In `GeminiPromptBuilder.userPrompt(from:)`, when `context.weightUnit == "kg"`, convert `max.weightLb` via `WeightUnitConversion.kilograms(from:unit:.pounds)` before embedding. Update the label to the user's unit. Do not modify `ExerciseMax` itself — it's a storage type and the conversion belongs in the prompt builder.

---

## Code Examples

Verified patterns from source-code inspection:

### FIX-01: System prompt parameterization skeleton
```swift
// GeminiPromptBuilder.swift — replace static systemPrompt with function
static func systemPrompt(weightUnit: String) -> String {
    let isKg = weightUnit.lowercased().contains("kg")
    if isKg {
        return """
        You are an experienced strength and conditioning coach. ...
        - Prescribes all weights in KILOGRAMS (kg)

        BARBELL weights:
        - Men use a 20 kg bar, women use a 15 kg bar
        - Available plates per side: 25, 20, 15, 10, 5, 2.5, 1.25 kg
        ...
        DUMBBELL weights — ONLY use these exact kg values: 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32
        KETTLEBELL weights — ONLY use these exact kg values: 8, 12, 16, 20, 24, 28, 32
        """
    } else {
        return """
        ... (existing lbs prompt) ...
        """
    }
}
```

### FIX-01: Max conversion in userPrompt
```swift
// Source: GeminiPromptBuilder.swift userPrompt(from:) — maxes section
if !context.maxes.isEmpty {
    let isKg = context.weightUnit.lowercased().contains("kg")
    var maxesSection = "Known Maxes:\n"
    for max in context.maxes {
        let displayWeight: Int
        if isKg {
            displayWeight = Int((max.weightLb / WeightUnitConversion.poundsPerKilogram).rounded())
        } else {
            displayWeight = Int(max.weightLb.rounded())
        }
        let unitLabel = isKg ? "kg" : "lb"
        maxesSection += "- \(max.name): \(displayWeight) \(unitLabel)\n"
    }
    sections.append(maxesSection)
}
```

### FIX-02: Correct schema wipe (delete-account)
```swift
// AppState.swift — deleteAccountAndData (after fix)
func deleteAccountAndData(modelContext: ModelContext) {
    let allModelTypes: [any PersistentModel.Type] = AppSchemaV12.models  // was V10
    for type in allModelTypes {
        try? modelContext.delete(model: type)
    }
    try? modelContext.save()
    KeychainHelper.deleteAppleUserID()
    KeychainHelper.deleteGuestUserID()   // NEW: also clear guest UUID
    UserDefaults.standard.removeObject(forKey: "com.sundeefundee.subscription.tier")
    UserDefaults.standard.removeObject(forKey: "dismissedPhaseTransitions")
    UserDefaults.standard.removeObject(forKey: "com.sundeefundee.ai.dataConsent")
    authState = .signedOut
    currentUserID = nil
}
```

### FIX-03: Guest UUID Keychain methods
```swift
// KeychainHelper.swift — add alongside existing appleUserID methods
private static let guestUserIDKey = "guestUserID"

static func saveGuestUserID(_ userID: String) {
    let data = Data(userID.utf8)
    let deleteQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: guestUserIDKey,
    ]
    SecItemDelete(deleteQuery as CFDictionary)
    let addQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: guestUserIDKey,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]
    SecItemAdd(addQuery as CFDictionary, nil)
}

static func loadGuestUserID() -> String? { /* same pattern as loadAppleUserID */ }
static func deleteGuestUserID() { /* same pattern as deleteAppleUserID */ }
```

### FIX-04: SubscriptionService.init() after fix
```swift
// SubscriptionService.swift — init (after fix)
init() {
    // currentTier is already .free from the property declaration
    // Do NOT read UserDefaults here — StoreKit is the single source of truth
    startObservingTransactions()
}
```
The caller (`SundeeFundeeApp` or the scene root) calls `await subscriptionService.loadStatus()` once the view appears, completing the async verification within ~1 second on a live connection.

### FIX-05: ModelContainer with migrationPlan for local store
```swift
// AppModelContainer.swift — makeContainer (after fix)
case .localPersistent:
    let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
    //                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ADD THIS
```

---

## State of the Art

| Old Approach | Current Approach | Impact on This Phase |
|--------------|------------------|----------------------|
| UserDefaults tier cache in StoreKit service | Live-only `Transaction.currentEntitlements` | FIX-04 removes the cache |
| Static lbs-only system prompt | Unit-parameterized system prompt function | FIX-01 requires this change |
| `AppSchemaV10.models` for wipe | `AppSchemaV12.models` | FIX-02 requires this update |

---

## Open Questions

1. **Response schema field: rename `weightLb` to `weight` or keep and add `weightUnit`?**
   - What we know: The JSON field name `weightLb` is cosmetic — Gemini fills it with whatever unit the prompt instructs. The field name creates confusion in the codebase and in the `GeneratedWorkout` Swift model.
   - What's unclear: Renaming requires updating `GeminiResponseParser`, `GeneratedWorkout`, and anywhere `weightLb` is read for display. Keeping it requires a runtime unit lookup.
   - Recommendation: Rename to `weight` and add `weightUnit: String` to the response schema. This is the clearest long-term solution. Scope: ~3 files, low risk.

2. **Which SwiftData models carry a `userID` field for guest migration?**
   - What we know: `User`, `CompletedWorkout`, `InjuryProfile`, `BenchmarkResult`, `EnrolledProgram`, `BarbellPreset`, `ExerciseBarMapping` are very likely candidates from reading the V12 model list and existing repository patterns.
   - What's unclear: Exact field names on each model (some may use `userID`, some `ownerID`, some may be implicit via CloudKit relationships). Full audit requires reading each model file.
   - Recommendation: The planner should add a sub-task in plan 01-03 to audit all V12 model files for `userID` fields before writing the batch migration.

3. **Sign-out: which V12 models count as "workout data" vs "preferences"?**
   - What we know: Locked decision says sign-out wipes workout data but preserves preferences. `User` (preferences), `CycleSettings`, `CycleAdaptationPreferences` seem like preference models. `CompletedWorkout`, `CompletedSet`, `GeneratedWorkoutRecord` are clearly workout data.
   - What's unclear: `InjuryProfile`, `BenchmarkDefinition`, `BarbellPreset` — are these user preferences or data? `InjuryProfile` feels like a preference; `BenchmarkResult` feels like data.
   - Recommendation: Treat as "data" (wiped on sign-out): `CompletedWorkout`, `CompletedSet`, `OneRepMax`, `PersonalRecord`, `LiftMax`, `PeriodLog`, `SymptomLog`, `BenchmarkResult`, `ConditioningPR`, `GeneratedWorkoutRecord`, `ActiveCycle`, `EnrolledProgram`. Treat as "preferences" (preserved on sign-out): `User`, `CycleSettings`, `CycleAdaptationPreferences`, `InjuryProfile`, `PainLog`, `BenchmarkDefinition`, `SharedWorkoutTemplateRecord`, `BarbellPreset`, `ExerciseBarMapping`.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`) — Xcode 16 native |
| Config file | Xcode scheme / xctest target `SundeeFundeTests` |
| Quick run command | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/GeminiPromptBuilderTests` |
| Full suite command | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | System prompt uses kg equipment list when weightUnit is kg | unit | `-only-testing:SundeeFundeTests/GeminiPromptBuilderTests` | Partial (existing tests pass; new kg-specific tests needed) |
| FIX-01 | Maxes converted to kg in userPrompt when unit is kg | unit | `-only-testing:SundeeFundeTests/GeminiPromptBuilderTests` | Partial |
| FIX-01 | Body weight converted to correct unit | unit | `-only-testing:SundeeFundeTests/GeminiPromptBuilderTests` | Partial |
| FIX-02 | Sign-out deletes workout-data models (not preference models) | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | Partial |
| FIX-02 | Delete-account wipes all V12 models including BarbellPreset, ExerciseBarMapping | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | Partial (new tests needed) |
| FIX-03 | Guest UUID stored in Keychain at first launch | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | No — Wave 0 |
| FIX-03 | Batch migration updates all records from guest UUID to Apple ID | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | No — Wave 0 |
| FIX-04 | SubscriptionService.init() starts at .free regardless of UserDefaults | unit | `-only-testing:SundeeFundeTests/SubscriptionServiceTests` | Partial (`defaultsToFree` already passes; `restoresTierFromUserDefaults` must be deleted) |
| FIX-05 | Local persistent container opens without crash after migration | smoke | Manual device test — cannot automate SwiftData migration in unit tests | N/A (manual only) |

### Sampling Rate
- **Per task commit:** Run the specific test suite for the touched file (e.g., `GeminiPromptBuilderTests` after FIX-01)
- **Per wave merge:** Full suite — `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] New test cases in `GeminiPromptBuilderTests.swift` — covers FIX-01 kg system prompt, kg maxes conversion, kg body weight
- [ ] New test cases in `AppAuthCoverageTests.swift` — covers FIX-02 sign-out scope, FIX-02 delete-account V12 completeness, FIX-03 guest UUID Keychain persistence, FIX-03 batch migration
- [ ] Delete `restoresTierFromUserDefaults` test in `SubscriptionServiceTests.swift` — behavior intentionally removed by FIX-04

---

## Sources

### Primary (HIGH confidence — direct code inspection)

- `/SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift` — confirmed static lbs-only system prompt, `weightLb`-labeled maxes, no unit branching
- `/SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift` — confirmed `weightUnit: String` property exists but flows nowhere in system prompt
- `/SundeeFundee/App/AppState.swift` — confirmed `AppSchemaV10.models` used in both `signOut` and `deleteAccountAndData`
- `/SundeeFundee/App/AppSchemaV10.swift` — confirmed V10 is missing `BarbellPreset` and `ExerciseBarMapping`
- `/SundeeFundee/App/AppSchemaV12.swift` — confirmed V12 adds those two models
- `/SundeeFundee/App/AppModelContainer.swift` line 93 vs 95–96 — confirmed `migrationPlan:` present on cloudKit, absent on localPersistent
- `/SundeeFundee/Services/SubscriptionService.swift` lines 69–70 — confirmed UserDefaults read in `init()`
- `/SundeeFundee/Auth/KeychainHelper.swift` — confirmed existing pattern for guest UUID addition
- `/SundeeFundee/Auth/AuthService.swift` — confirmed `signInAsGuest()` sets `currentUserID = nil`, no UUID generated
- `/SundeeFundeTests/GeminiPromptBuilderTests.swift` — existing test coverage confirmed
- `/SundeeFundeTests/SubscriptionServiceTests.swift` — confirmed `restoresTierFromUserDefaults` test that will conflict with FIX-04

---

## Metadata

**Confidence breakdown:**
- FIX-01 root cause: HIGH — static string confirmed; kg equipment values are domain knowledge (standard gym equipment)
- FIX-02 root cause: HIGH — V10 vs V12 model list diff confirmed by reading both files
- FIX-03 root cause: HIGH — `currentUserID = nil` in guest mode confirmed; Keychain pattern confirmed
- FIX-04 root cause: HIGH — UserDefaults read in `init()` confirmed at exact line
- FIX-05 root cause: HIGH — missing `migrationPlan:` parameter confirmed by reading both switch cases
- Open question on response schema field rename: MEDIUM — impact analysis requires reading GeminiResponseParser and GeneratedWorkout model files

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (stable APIs — no fast-moving dependencies)
