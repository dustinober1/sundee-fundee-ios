# Codebase Concerns

**Analysis Date:** 2026-03-18

---

## Tech Debt

**CloudKit sync disabled in production container:**
- Issue: `AppModelContainer.makeSharedContainer` hardcodes `useCloudKit: Bool = false`. The `.cloudKit` case is fully implemented and wired, but the default call path always uses `.localPersistent`. User data never syncs to iCloud.
- Files: `SundeeFundee/App/AppModelContainer.swift` line 22
- Impact: Advertised CloudKit sync (iCloud backup, multi-device) does not happen in production builds.
- Fix approach: Flip `useCloudKit` default to `true` after confirming entitlements are provisioned, or expose it as a build configuration flag.

**Migration plan missing from local persistent store:**
- Issue: `makeContainer(for: .localPersistent)` does not pass `migrationPlan: AppSchemaMigrationPlan.self`. The migration plan is only applied on the `.cloudKit` path. Any upgrade from V1 through V11 on a local-only install may fail or skip migrations.
- Files: `SundeeFundee/App/AppModelContainer.swift` lines 94–96
- Impact: Users who install the app, accumulate data, and upgrade will have SwiftData attempt an implicit schema migration with no plan, risking data corruption or a crash that triggers silent store deletion.
- Fix approach: Apply `migrationPlan: AppSchemaMigrationPlan.self` to the `.localPersistent` container creation as well.

**`signOut` and `deleteAccountAndData` reference stale `AppSchemaV10.models`:**
- Issue: Both methods in `AppState` iterate `AppSchemaV10.models` to delete all records. Current schema is V12, which adds `BarbellPreset` and `ExerciseBarMapping` (V11) and no additional models in V12. Those two model types are absent from V10 and will not be wiped on sign-out.
- Files: `SundeeFundee/App/AppState.swift` lines 28 and 40
- Impact: Orphaned `BarbellPreset` and `ExerciseBarMapping` records remain in the local store after sign-out or account deletion.
- Fix approach: Replace `AppSchemaV10.models` with `AppSchemaV12.models` (already used as `allModels` in `AppModelContainer`).

**AI weights hard-coded in pounds regardless of user's weight unit:**
- Issue: `GeminiWorkoutService` prompts the model to prescribe weights in lbs only (`GeminiPromptBuilder.systemPrompt` lines 15–30). `WorkoutExecutionViewModel.initializeAISets` stores `exercise.weightLb` directly into `prescribedWeightKg` and `actualWeightKg` without any kg/lb conversion. Users set to kilograms see lb values displayed as if they were kg.
- Files: `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift`, `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift` lines 127–129
- Impact: Incorrect prescribed weights for all metric-unit users completing AI-generated workouts.
- Fix approach: Either have the prompt conditionally prescribe kg values when user is metric, or convert `weightLb` to kg before assigning it to `prescribedWeightKg` / `actualWeightKg`.

**`userID ?? ""` empty-string fallback throughout UI:**
- Issue: Calls like `appState.currentUserID ?? ""` and `appState.currentUserID ?? ""` are passed as `userID` into workout saves, enrollment actions, and AI workout generation. In guest mode `currentUserID` is `nil`, so all data is written with `userID = ""`.
- Files: `SundeeFundee/Features/Dashboard/DashboardView.swift` lines 95, 103, 126, 133, 156; `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift` line 140; `SundeeFundee/Features/Workouts/WODExecutionView.swift` line 70; `SundeeFundee/Features/Programs/ProgramDetailView.swift` lines 156, 168
- Impact: When guest users sign in after accumulating data, any fetch keyed by `userID` misses all rows stored under `""`. Also conflates all guest data when two different users share a device in guest mode.
- Fix approach: Enforce a stable guest UUID (e.g. stored in `AppState.signInAsGuest`) and use it instead of the empty fallback.

**Subscription tier cached in `UserDefaults` without server verification on cold launch:**
- Issue: `SubscriptionService.init` reads `currentTier` from `UserDefaults` before calling `loadStatus()`. If the subscription lapses between launches the user sees premium features until `loadStatus()` completes asynchronously.
- Files: `SundeeFundee/Services/SubscriptionService.swift` lines 68–72
- Impact: Brief premium feature access window for lapsed subscribers on every cold launch.
- Fix approach: Treat the cached tier as `.free` until `loadStatus()` resolves, or gate premium features behind `subscriptionService.isStatusLoaded`.

**Gemini model name hard-coded as string literal:**
- Issue: `"gemini-3.1-flash-lite-preview"` is written directly in `GeminiWorkoutService.buildRequest`. The model is a preview model that may be deprecated without a binary update.
- Files: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift` line 61
- Impact: Silent breakage if the preview model is retired (returns HTTP 404/400 → falls back to offline generator with no user notification).
- Fix approach: Extract to a named constant or configuration value; add an error path that surfaces model-not-found errors distinctly from other network failures.

---

## Known Bugs

**AI workout prescribed weights stored as lbs but displayed as kg:**
- Symptoms: Metric users see e.g. "135" displayed as kilograms when the intended value is 135 lbs (~61 kg).
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift` line 127–129
- Trigger: Any AI-generated workout execution by a user with `weightUnit == .kilograms`.
- Workaround: None.

**Orphaned enrollment if CloudKit program fetch fails mid-session:**
- Symptoms: If `CloudKitProgramRepository.fetchPrograms()` returns empty (transient CloudKit error), `DashboardViewModel.loadActiveProgram` cancels the enrollment because `program == nil`.
- Files: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift` lines 162–167
- Trigger: Temporary CloudKit unavailability while the user has an active enrollment.
- Workaround: Re-enrolling manually recovers.

---

## Security Considerations

**Gemini API key exposed via Cloudflare Worker, no client-side auth:**
- Risk: `GeminiWorkoutService` posts directly to `workout-proxy.sundeefundee.workers.dev` with no authentication header. Any party who discovers the URL can call it freely, incurring Gemini API costs.
- Files: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift` lines 14–16, 76–79
- Current mitigation: Rate limiting must be enforced at the Cloudflare Worker layer (not visible here).
- Recommendations: Add a shared secret header or App Attest token to restrict calls to the app binary. The planned Firebase Cloud Function replacement is the correct long-term fix.

**NSPredicate format string in CloudKit query:**
- Risk: `NSPredicate(format: "focusRaw = %@", focus)` builds a predicate from the `focus` parameter. While this is not a direct injection risk because CloudKit queries are server-side evaluated, the pattern is fragile if the predicate is ever moved to a SwiftData or SQLite context.
- Files: `SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift` line 91
- Current mitigation: CloudKit public DB queries are sandboxed.
- Recommendations: Low priority; document it as safe only in CloudKit context.

**Subscription tier stored in `UserDefaults` (not Keychain):**
- Risk: `UserDefaults` is readable by other processes in some configurations and is not encrypted. The tier value can be modified by a user via device-level defaults manipulation, elevating themselves to `.pro` without a valid transaction.
- Files: `SundeeFundee/Services/SubscriptionService.swift` lines 62, 141
- Current mitigation: `loadStatus()` verifies via StoreKit `Transaction.currentEntitlements` on launch.
- Recommendations: The short window before `loadStatus()` completes is the main risk; acceptable if the UX concern above is addressed.

---

## Performance Bottlenecks

**`DashboardViewModel.load` executes 8+ synchronous SwiftData fetches on the main actor:**
- Problem: `load(modelContext:)` calls `loadUserConfiguration`, `loadOneRepMaxes`, `loadEnrollment`, `loadCycleData`, `loadInjuries`, `loadWODAndRecentWorkouts` sequentially, all performing `modelContext.fetch` synchronously on `@MainActor`. Each also constructs a new repository instance inline.
- Files: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift` lines 51–73
- Cause: No batching, no background context usage, repository objects instantiated on every `load` call.
- Improvement path: Perform independent fetches (ORM, enrollment, injuries, WODs) concurrently with `async let`; cache repository instances; use a background context for bulk reads.

**`BundledProgramRepository` and `BundledWODRepository` read JSON files synchronously via `Data(contentsOf:)` on the calling actor:**
- Problem: `Data(contentsOf: url)` is a synchronous blocking I/O call issued from an `async` function.
- Files: `SundeeFundee/Repositories/ProgramRepository.swift` line 23; `SundeeFundee/Repositories/WODRepository.swift` line 23
- Cause: No explicit off-main dispatch for file I/O.
- Improvement path: Wrap in `Task.detached` or `actor`-isolated method; or switch to `URLSession.data(from:)` which is async-native.

---

## Fragile Areas

**`AppModelContainer.deleteStoreFiles` silently destroys all user data on migration failure:**
- Files: `SundeeFundee/App/AppModelContainer.swift` lines 55–66
- Why fragile: If the local persistent store fails to open (e.g. an interrupted write), the container falls back to deleting all `.store`, `.store-wal`, `.store-shm` files and creating a fresh empty store. The user loses all local data with no warning.
- Safe modification: Before wiping, surface a user-facing alert explaining data loss and offering an iCloud restore path (if CloudKit sync is enabled). Alternatively, copy the corrupt store file to a temporary location for diagnostics.
- Test coverage: No test exercises the fallback deletion path in isolation.

**`@unchecked Sendable` on 9 repository and service classes:**
- Files: `SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift`; `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`; `SundeeFundee/Repositories/ProgramRepository.swift` (both classes); `SundeeFundee/Repositories/WODRepository.swift` (both classes); `SundeeFundee/Repositories/HealthKit/HealthKitReadinessRepository.swift`; `SundeeFundee/Observability/MetricsService.swift`; `SundeeFundee/Features/Dashboard/DashboardView.swift` (`RefreshPerformer`)
- Why fragile: `@unchecked Sendable` suppresses Swift Concurrency's data-race detection. Each class carries state (e.g. `modelContext`, `cache`) that is shared across actor boundaries without documented synchronization guarantees.
- Safe modification: Audit each class for mutable shared state; replace `@unchecked Sendable` with `actor` isolation or proper `Sendable` conformance where possible.

**`DashboardView.swift` contains 18+ struct/class definitions (888 lines):**
- Files: `SundeeFundee/Features/Dashboard/DashboardView.swift`
- Why fragile: Cards, banners, destination types, and helper structs for unrelated features (`WODCard`, `MenstrualPhaseCard`, `AIWorkoutCTACard`, `TravelModeBanner`) are all co-located. Any change to a single card risks unintended interactions and merge conflicts.
- Safe modification: Extract each card view to its own file under `SundeeFundee/Features/Dashboard/Cards/`.

**`SettingsView.swift` contains inline business logic (669 lines):**
- Files: `SundeeFundee/Features/Settings/SettingsView.swift`
- Why fragile: Inline `UserDefaults` reads and `Task` blocks for HealthKit authorization live inside the view body, bypassing the `SettingsViewModel`.
- Safe modification: Move HealthKit toggle logic into `SettingsViewModel`; keep the view as pure SwiftUI layout.

---

## Scaling Limits

**CloudKit Public Database shared workout templates: no pagination:**
- Current capacity: `CloudKitSharedWorkoutRepository.fetchFromCloudKit` fetches all records matching a predicate in one query. CloudKit returns at most 200 records per `records(matching:)` call (default limit).
- Limit: Beyond 200 shared templates, older entries silently disappear from the list.
- Scaling path: Use `CKQueryOperation` with `resultsLimit` and a cursor to paginate results.

**`BundledProgramRepository` and `BundledWODRepository` in-memory cache is unbounded:**
- Current capacity: Entire JSON file cached in memory after first read.
- Limit: Acceptable for current data size (~hundreds of KB); becomes a concern if program/WOD catalogs grow significantly.
- Scaling path: Already a simple in-memory `[Program]?` / `[WOD]?`; acceptable for the near term.

---

## Dependencies at Risk

**`gemini-3.1-flash-lite-preview` Gemini model:**
- Risk: Preview models can be deprecated at any time without a migration window.
- Impact: AI workout generation silently falls back to `OfflineWorkoutGenerator` with no user notification.
- Migration plan: Monitor Google AI deprecation notices; update the model string in `GeminiWorkoutService`; the planned Firebase Cloud Function migration removes this risk entirely.

**Cloudflare Worker proxy (`workout-proxy.sundeefundee.workers.dev`):**
- Risk: Worker is an external dependency not in this repo; outages or misconfiguration break AI generation in the legacy Swift app.
- Impact: Falls back to `OfflineWorkoutGenerator`; no user alert distinguishes proxy outage from Gemini API error.
- Migration plan: Replace with Firebase Cloud Function (referenced in CLAUDE.md).

---

## Test Coverage Gaps

**`AppModelContainer` error-recovery path (store deletion) has no unit tests:**
- What's not tested: The fallback that deletes corrupt store files and creates a fresh container.
- Files: `SundeeFundee/App/AppModelContainer.swift` lines 55–66
- Risk: Regression could silently wipe user data or leave a permanently unusable store.
- Priority: High

**`SubscriptionService` cold-launch tier-elevation window not covered:**
- What's not tested: The brief period between app launch and `loadStatus()` completion where a lapsed subscriber can access premium features.
- Files: `SundeeFundee/Services/SubscriptionService.swift`
- Risk: Paywall bypass not caught by CI.
- Priority: Medium

**`CloudKitSharedWorkoutRepository.fetchFromCloudKit` pagination not implemented or tested:**
- What's not tested: Behavior when CloudKit returns a cursor indicating more results.
- Files: `SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift`
- Risk: Shared workout database appears truncated at 200 entries with no error surfaced.
- Priority: Medium

**AI workout weight unit conversion gap has no test:**
- What's not tested: That `initializeAISets` correctly handles metric users receiving lb values from the Gemini response.
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift` lines 122–133
- Risk: Bug goes undetected for metric users.
- Priority: High

---

*Concerns audit: 2026-03-18*
