# Codebase Concerns

**Analysis Date:** 2026-03-14

## Tech Debt

**Debug seed data uses force unwrap:**
- Issue: `DebugSeedData.swift` line 15 uses `try!` to fetch existing users during seeding
- Files: `SundeeFundee/App/DebugSeedData.swift:15`
- Impact: If SwiftData context errors occur during debug seeding, the app crashes rather than gracefully handling the error
- Fix approach: Replace `try!` with `(try? ...) ?? []` to handle errors gracefully; provide user feedback if seeding fails

**Gemini proxy URL hardcoded as fatalError:**
- Issue: `GeminiWorkoutService.swift` line 16 uses `fatalError()` for an invalid literal URL
- Files: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift:14-19`
- Impact: While the literal is valid at compile time, if CloudFlare Worker domain changes, recompilation is required. This is appropriate for a compile-time constant but should have a fallback for runtime robustness
- Fix approach: Consider storing proxy URL in configuration file or environment variable for production builds

**Silent repository errors in critical workflows:**
- Issue: `WorkoutExecutionViewModel.swift` extensively uses `try?` to suppress repository errors, defaulting to empty collections
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift:198, 206, 218, 237, 276, 294, 301, 304, 316, 348`
- Impact: When saving barbell presets, exercise mappings, completed workouts, or updating enrollment progress fails, the app silently continues. User thinks data was saved but it wasn't. No error feedback to user
- Fix approach: Capture errors, log them with meaningful context, and show error dialogs to users. The pattern from CLAUDE.md guidance should be: `(try? ...) ?? defaultValue` with explicit error handling for data-writing operations

**Model-level enum storage workaround not enforced:**
- Issue: CLAUDE.md states "Enums must be stored as raw strings (CloudKit requirement)" but enforcement is manual
- Files: `SundeeFundee/Models/SharedTypes.swift` (290 lines) and all model files
- Impact: New developers may add enum properties directly to `@Model` types without `String` wrapper, causing CloudKit sync failures or migration errors
- Fix approach: Add compiler-time validation or documentation lint rule; add explicit comment on every enum property explaining the CloudKit constraint

**Hardcoded URLs and API endpoints:**
- Issue: Hardcoded Cloudflare Worker proxy URL, CloudKit container ID, keychain service identifiers scattered across auth and service layers
- Files: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift:15`, `SundeeFundee/App/AppModelContainer.swift:91`, `SundeeFundee/Auth/KeychainHelper.swift`, `SundeeFundee/Services/SubscriptionService.swift:62`
- Impact: Changing URLs requires code edits and recompilation; no runtime configuration flexibility
- Fix approach: Consolidate all URLs and identifiers into a single Configuration.swift file; separate debug and release configurations

---

## View Complexity

**Extremely large view files:**
- DashboardView: 888 lines
- SettingsView: 669 lines
- WorkoutExecutionView: 705 lines
- CycleTrackingView: 489 lines
- OnboardingFlowView: 483 lines

- Issue: SwiftUI views above 500 lines are difficult to test, refactor, and maintain
- Files: `SundeeFundee/Features/Dashboard/DashboardView.swift` (888), `SundeeFundee/Features/Settings/SettingsView.swift` (669), `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift` (705)
- Impact: These views contain multiple subviews, state management, and business logic in single file; SourceKit performance degrades; testing requires full view instantiation
- Fix approach: Extract large views into smaller, testable components. Example: `DashboardView` should split into `ActiveEnrollmentCard`, `ReadinessCard`, `PainCheckInCard`, `InjuryStatusCard` as separate files with isolated `@Observable` ViewModels

**State management scattered in views:**
- Issue: Views hold multiple `@State` properties for sheet presentation, confirmation dialogs, and UI state
- Files: `SundeeFundee/Features/Dashboard/DashboardView.swift:10-15`, `SundeeFundee/Features/Settings/SettingsView.swift:9-11`
- Impact: State is fragmented between view and ViewModel; harder to predict UI behavior; testing requires mocking both
- Fix approach: Migrate sheet/dialog state to ViewModel as `@Observable` properties; views become pure rendering functions

---

## Error Handling & Robustness

**Graceful degradation not applied consistently:**
- Issue: Some code paths use `try?` gracefully, others silently fail
- Files: `SundeeFundee/Repositories/SwiftData/SwiftDataWorkoutRepository.swift:41` (`try?`), vs `SundeeFundee/Auth/KeychainHelper.swift:30` (logs to console)
- Impact: Inconsistent error visibility and debugging difficulty
- Fix approach: Establish error handling policy: data reads → gracefully degrade, data writes → inform user, critical paths → log + report

**CloudKit sync failures not surfaced:**
- Issue: SwiftData CloudKit sync errors may occur silently; no user notification mechanism for sync state
- Files: `SundeeFundee/App/AppModelContainer.swift:43-46` (CloudKit fallback to local)
- Impact: Users may think data is synced when it's only local; on device switch, data doesn't transfer
- Fix approach: Add sync status indicator to AppState; show banner when CloudKit is unavailable or syncing; provide manual "Retry Sync" action

**Migration failure path untested:**
- Issue: Schema migrations are lightweight (no custom data transforms); if a migration fails, app falls back to in-memory store
- Files: `SundeeFundee/App/AppSchemaMigrationPlan.swift`, `SundeeFundee/App/AppModelContainer.swift:70-77`
- Impact: User loses all local data if migration encounters unexpected state. No recovery path beyond device reset
- Fix approach: Test migration path with pre-release schema to detect issues before release; add migration logging and analytics

---

## Subscription & IAP

**StoreKit transaction verification relies on checkedVerified:**
- Issue: `SubscriptionService.swift:92` uses `checkVerified()` which may throw
- Files: `SundeeFundee/Services/SubscriptionService.swift:85-107`
- Impact: If verification fails, purchase is not marked finished; StoreKit may retry/nag user
- Fix approach: Ensure all purchase paths have comprehensive error handling; test with invalid/expired certificates

**Product ID mismatch risk:**
- Issue: Product IDs hardcoded in two places: `SubscriptionTier` enum and App Store Connect
- Files: `SundeeFundee/Services/SubscriptionService.swift:30-32`, `SundeeFundee/Services/SubscriptionService.swift:35-38`
- Impact: If App Store product ID changes, code must be updated manually
- Fix approach: Store product IDs in configuration plist; load at runtime; validate against App Store

**AI workout generation limits not enforced locally:**
- Issue: `SubscriptionTier.dailyAILimit` is defined but enforcement logic is in ViewModels/QuestionnaireViewModel
- Files: `SundeeFundee/Services/SubscriptionService.swift:19-24`, `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift` (274 lines)
- Impact: Limit enforcement scattered across codebase; easy to bypass in new features
- Fix approach: Create `AIWorkoutLimitService` that centralizes all limit checking and counter management

---

## Data Persistence & Migrations

**8 schema versions with only lightweight migrations:**
- Issue: `AppSchemaMigrationPlan.swift` shows V1→V6→V7→V8→V9→V10→V11→V12 with all lightweight migrations
- Files: `SundeeFundee/App/AppSchemaMigrationPlan.swift:10-65`, multiple AppSchemaV*.swift files
- Impact: Complex data transforms cannot be applied; if a property is removed or renamed, data is silently dropped or corrupted
- Fix approach: Review schema history and document why custom migrations were avoided; plan for future migrations if transform logic becomes necessary

**No default values on new properties:**
- Issue: CLAUDE.md warns "When adding new @Model properties, always provide default values for lightweight migration" but not all new properties have defaults
- Files: All AppSchemaV*.swift files
- Impact: If a property is added without default, app may crash when accessing it
- Fix approach: Add lint check in schema files to verify all properties have defaults

**ModelContext.delete used without prior fetch:**
- Issue: `DebugSeedData.swift:96-99` deletes model types without ensuring they exist first
- Files: `SundeeFundee/App/DebugSeedData.swift:96-99`
- Impact: If model type doesn't exist in store, deletion silently fails; partial data corruption possible
- Fix approach: Wrap deletion in transaction; log what was deleted; validate store state after

---

## Testing & Coverage Gaps

**Workout execution save path under-tested:**
- Issue: `WorkoutExecutionViewModel.finishWorkout()` performs 5+ repository saves with silent error suppression
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift:276-316`
- Impact: Test suite doesn't verify all saves succeed; repository errors silently fail
- Fix approach: Add integration test for full workout save flow; mock repository to inject errors at each step; assert error handling

**AI workout generation retry logic missing:**
- Issue: Gemini API proxy calls have 15-second timeout but no retry on transient failure
- Files: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift:24`
- Impact: Brief network glitches cause permanent workout generation failure; user forced to restart
- Fix approach: Implement exponential backoff retry (max 3 attempts); add timeout configuration to DI

**Barbell presets loading not tested:**
- Issue: `WorkoutExecutionViewModel.loadBarbellPresets()` at line 197 loads presets on view appear
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift:197-205`
- Impact: If load fails, user gets empty preset list with no error message
- Fix approach: Add test that verifies fallback to default barbell; test error scenarios

---

## Performance Bottlenecks

**Large SwiftUI view bodies cause SourceKit/compiler slowdown:**
- Issue: DashboardView (888 lines) with 40+ conditional subviews and `.background()` modifiers
- Files: `SundeeFundee/Features/Dashboard/DashboardView.swift`
- Impact: Xcode preview slow to load; incremental compilation takes 10+ seconds for small edits
- Fix approach: Split into 5-8 smaller views; use lazy loading for below-the-fold content

**Fetch-on-every-render pattern in viewModel:**
- Issue: Some ViewModels fetch data in `init` or on `.onAppear`, not cached
- Files: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift:334` (loads active enrollment, program, sessions on init)
- Impact: Unnecessary SwiftData queries; if fetch fails silently, ViewModel has stale data
- Fix approach: Implement caching with cache invalidation strategy; show loading state while fetching

**History view merges two separate record types:**
- Issue: `UnifiedHistoryView` fetches both `GeneratedWorkoutRecord` and `CompletedWorkout`, then merges in memory
- Files: `SundeeFundee/Features/AIWorkout/UnifiedHistoryView.swift:4`
- Impact: If user has 1000+ workouts, merge performance degrades; no pagination
- Fix approach: Add SwiftData predicate-based sorting to combine queries; implement infinite scroll pagination

---

## Fragile Areas

**Injury adaptation engine transforms all program data:**
- Issue: `InjuryAdaptationEngine.adaptProgram()` creates entirely new Program with adapted sessions
- Files: `SundeeFundee/Domain/InjuryAdaptationEngine.swift:17-44`
- Impact: Any bug in adaptation logic silently produces wrong exercises; adaptation applied at render time, not at enrollment
- Fix approach: Cache adapted programs at enrollment time; log all exercise substitutions; add test coverage for all injury types

**Auth session restoration race condition:**
- Issue: `AppRootView.swift:38-40` checks if session needs restoration on `.onAppear`, but `AppState` initialization may still be in progress
- Files: `SundeeFundee/App/AppRootView.swift:38-40`
- Impact: User may see sign-in screen briefly even though authenticated
- Fix approach: Ensure AppState is fully loaded before rendering AppRootView; use `.task` instead of `.onAppear` for async operations

**Enum raw value assumptions:**
- Issue: Code assumes all enums have raw String values matching stored database values
- Files: All files accessing enum properties (e.g., `SundeeFundee/Models/SharedTypes.swift`)
- Impact: If raw value changes or mismatches stored value, decoding silently fails or crashes
- Fix approach: Add runtime validation; test all enum decode/encode paths with invalid values

---

## Security Considerations

**Keychain helper prints errors to console:**
- Issue: `KeychainHelper.swift:30` prints SecItemAdd errors (may contain sensitive status codes)
- Files: `SundeeFundee/Auth/KeychainHelper.swift:30`
- Impact: Sensitive security operations logged to console; visible in crash reports
- Fix approach: Log to secure analytics service; suppress console logging for release builds

**Apple User ID persisted without validation:**
- Issue: `AuthService.swift` loads Apple User ID from keychain but doesn't validate it's valid format
- Files: `SundeeFundee/Auth/AuthService.swift:93-97`
- Impact: Corrupted keychain entry could cause auth failure
- Fix approach: Validate loaded User ID format; add recovery path if invalid

**CloudKit public DB writes require user auth but no check:**
- Issue: `ProgramRepository` reads from CloudKit public DB; code doesn't verify user is authenticated
- Files: `SundeeFundee/Repositories/ProgramRepository.swift`
- Impact: Public DB read failures silent if user logged out
- Fix approach: Add explicit auth check before CloudKit operations; propagate auth errors to UI

**WOD admin dashboard (Next.js) uses CloudKit API token:**
- Issue: `wod-dashboard/.env.local` contains CloudKit API token (file marked in .gitignore)
- Files: `wod-dashboard/.env.local`
- Impact: If token leaked, attacker can write WODs to all users' devices
- Fix approach: Rotate API tokens regularly; use role-based access if CloudKit offers it; store token in secure environment variable service

---

## Missing Critical Features / Known Limitations

**No offline workout execution:**
- Issue: `WorkoutExecutionViewModel` fetches oneRepMaxes, enrollments, and programs at runtime
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift:197-210`
- Impact: If network drops mid-workout, app may lose context or prevent saving
- Fix approach: Pre-load all required data when enrollment is started; cache locally

**No workout history search/filter:**
- Issue: `UnifiedHistoryView` shows all workouts in chronological order only
- Files: `SundeeFundee/Features/AIWorkout/UnifiedHistoryView.swift`
- Impact: Finding specific workout difficult if user has 100+ records
- Fix approach: Add date range picker, exercise filter, source filter (AI/Program) with persistent settings

**No manual sync trigger for CloudKit:**
- Issue: CloudKit sync automatic; no manual "sync now" button
- Files: `SundeeFundee/App/AppModelContainer.swift`
- Impact: If CloudKit falls behind, user has no way to force sync
- Fix approach: Add sync status indicator and manual retry button

**Readiness survey stores result but no trend analysis:**
- Issue: `ReadinessSurvey.swift` captures daily readiness but code doesn't analyze trends
- Files: `SundeeFundee/Domain/ReadinessSurvey.swift`
- Impact: Feature incomplete; UI shows today's readiness but no coaching on trends
- Fix approach: Add `ReadinessTrendAnalyzer` domain service to detect declining readiness patterns

---

## Known Test Gaps

**AI workout service not tested with network errors:**
- Issue: `GeminiWorkoutService` tests don't inject HTTP 500, timeout, or invalid JSON scenarios
- Files: `SundeeFundeTests/GeminiWorkoutServiceTests.swift`
- Impact: Real-world failures (proxy down, rate limit) not covered
- Fix approach: Add test wave covering: timeout, 4xx/5xx errors, invalid JSON, empty response

**View controller lifecycle not tested:**
- Issue: `.onAppear { viewModel.loadBarbellPresets() }` is not tested
- Files: `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift:47`
- Impact: If loadBarbellPresets throws, view doesn't show error
- Fix approach: Extract `.onAppear` logic to testable ViewModel method; add test

**Migration path not tested end-to-end:**
- Issue: Schema migrations defined but never tested with real pre-migration data
- Files: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Impact: Migration may fail on first production run
- Fix approach: Before release, create test database with old schema; run full migration; verify data integrity

---

## Scaling Limits

**All user data in single CloudKit private database:**
- Current capacity: No partition strategy visible
- Limit: CloudKit record size 400KB; operation rate limits unknown
- Scaling path: Partition by user ID hash; implement record versioning; add indexing strategy

**In-memory workout merge (UnifiedHistoryView):**
- Current capacity: ~1000 records can fit in memory
- Limit: Beyond 10k records, merge becomes slow
- Scaling path: Add server-side sort; implement pagination with offset/limit; add database-level deduplication

**Print-based logging to console:**
- Current capacity: Console can handle ~1000 log statements per session
- Limit: No log rotation or analytics aggregation
- Scaling path: Implement proper logging service; aggregate metrics; add log level filtering

---

*Concerns audit: 2026-03-14*
