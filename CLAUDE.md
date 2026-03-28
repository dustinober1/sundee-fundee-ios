# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a native iOS strength training app with hormonal-cycle-aware training recommendations. Swift 6 + SwiftUI, targeting iOS 26.0+.

## Commands

### Setup
```bash
# Regenerate Xcode project after modifying project.yml
xcodegen generate
```

### Build
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO
```

### Test
```bash
# Run all tests (CI enforces 100% line coverage)
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO

# Run a single test class
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/BusinessLogicTests \
  CODE_SIGNING_ALLOWED=NO
```

### Deploy
TestFlight builds are deployed via **Xcode Cloud** (manual trigger only):
- In Xcode: Product → Xcode Cloud → Start Build
- Xcode Cloud handles signing, building, and uploading to TestFlight automatically
- CI post-clone script (`ci_scripts/ci_post_clone.sh`) installs XcodeGen and regenerates the project
- No local Distribution certificate — archive uploads **must** go through Xcode Cloud

### Firebase Hosting

Privacy policy and support page are deployed to Firebase Hosting (`public/` directory):
- Privacy: https://sundee-fundee.web.app/privacy.html
- Support: https://sundee-fundee.web.app/support.html
- Deploy: `firebase deploy --only hosting`

## Architecture

```
SwiftUI Views
    ↓
@Observable ViewModels (@MainActor)
    ↓
Repository Protocols (testable, Sendable)
    ↓
SwiftData ←→ CloudKit (Private DB for users, Public DB for programs)
    ↓
Domain/ (pure Swift, zero dependencies, 100% tested)
```

### Key Directories

- **`App/`** — Entry point, `AppState` (auth routing), `ModelContainer` setup, schema migrations (V1→V8), debug seed data
- **`Auth/`** — Sign in with Apple, `KeychainHelper`, guest mode
- **`Domain/`** — All business logic: weight calculations, cycle phase adaptation, injury modification engine, benchmark catalog, pain trend analysis, rehab session generation, phase transition advice. No framework dependencies — fully unit tested.
- **`Models/`** — 18 SwiftData `@Model` types. **Enums must be stored as raw strings** (CloudKit requirement); typed accessors are computed properties.
- **`Repositories/`** — Protocol-based data access layer with SwiftData implementations. `ProgramRepository` fetches from CloudKit Public DB with bundled `programs.json` fallback.
- **`Features/`** — One subdirectory per tab: Dashboard, Programs, Workouts, Cycle, Maxes, Benchmarks, Settings + Shell (tab bar). `Shared/` contains reusable components (e.g., `SpicyRatingView`).
- **`Observability/`** — Analytics and metrics: `AnalyticsEvent`, `AnalyticsService`, `MetricsService`
- **`Onboarding/`** — `OnboardingFlowView` and onboarding step views (separate from `Auth/`)
- **`Theme/`** — Art Deco design tokens: cream/navy/orange palette

### Auth & Routing

`AppState` controls the root navigation state machine:
- `loading` → `signIn` → `onboarding` → `mainTab`
- `.authenticated` mode: full CloudKit sync enabled
- `.guest` mode: local SwiftData only, no CloudKit
- **Onboarding does not collect name** — `AuthService` extracts `fullName` from the Sign in with Apple credential and writes it to the User stub. This is required by App Store Guideline 4 (do not re-ask for data Apple already provides).
- **`appState.currentUserID` returns `User.id` (a UUID), NOT `User.appleUserID`** (the Apple Sign-In identifier). Always use `User.id` / `appState.currentUserID` for data ownership queries. `appleUserID` is only for Sign in with Apple credential state checks.

### SwiftData / CloudKit Constraints

- **ModelContext is main-queue only.** `@Environment(\.modelContext)` is bound to the main queue. Any service class holding a `ModelContext` must be `@MainActor` — marking only the caller `@MainActor in` is insufficient because `await` on a non-`@MainActor` method hops off the main thread. Symptoms: "Unbinding from the main queue" warning + silent data operation failures.
- **`.task` runs once per view lifetime.** In a `TabView`, tabs stay alive — `.task` won't re-run on tab switch. Use `.onAppear` for data that must refresh when the user returns to a tab (Dashboard, Maxes, History).
  - **Verified `.onAppear` users:** DashboardView, MaxLiftsView, WorkoutHistoryView, BenchmarksView, CycleTrackingView, ProgramListView.
  - If adding a new tab view, always use `.onAppear` (not `.task`) for data loading.
- Enum properties on `@Model` types **must be stored as `String` raw values** — CloudKit does not support Swift enums directly.
- A single entitlements file (`SundeeFundee.entitlements`) is used for both Debug and Release, enabling CloudKit + Sign in with Apple. Requires paid developer team (87VVCMCW3F) for signing. HealthKit is **not** currently integrated — cycle data is stored in SwiftData, not Apple Health.
- **Schema version consistency:** When adding a new `AppSchemaVN`, you must update THREE places: (1) add to `AppSchemaMigrationPlan.schemas`, (2) add a migration stage to `AppSchemaMigrationPlan.stages`, (3) update `AppModelContainer.allModels` to reference the new schema. Missing any of these causes silent data loss.
- **`CKContainer(identifier:)` fatally traps (SIGTRAP) without CloudKit entitlements** — this is NOT a catchable Swift error. The CloudKit repos (`CloudKitWODRepository`, `CloudKitProgramRepository`, `CloudKitBenchmarkDefinitionRepository`) guard with `CloudKitWODRepository.hasCloudKitEntitlement`; do not bypass it.
- **CloudKit integer fields return `Int64`** — casting `record["field"] as? Int` silently fails. Use `(record["field"] as? Int64).map(Int.init)`.
- **`@Model` types are not `Sendable`** — async protocols returning `@Model` instances still require `Sendable` on the protocol for cross-actor calls. Repos need `@unchecked Sendable`. Cache Codable DTOs (not `@Model` instances) to avoid data races.
- **VersionedSchema checksum collisions:** When two schema versions reference the same live model types with identical properties, SwiftData produces duplicate checksums and crashes with "Duplicate version checksums across stages detected." Fix: use frozen `@Model` classes (namespaced under the schema enum, e.g., `AppSchemaV7.CompletedWorkout`) for models that changed between versions. See V6 (`CompletedSet`) and V7 (`CompletedWorkout`) for examples.
- **Never remove a schema version from the migration plan** — existing user stores reference that version. Removing it causes "Cannot use staged migration with an unknown model version" and forces store deletion (data loss).

### Navigation Pitfalls

- **`NavigationLink(value:)` only resolves at the NavigationStack root.** If a view with `navigationDestination(for:)` is pushed from another stack (e.g., Dashboard → Browse Programs), value-based links won't fire. Use `NavigationLink(destination:)` for views that may be pushed from multiple stacks.
- **iOS 26 TabView auto-creates "More" for >4 tabs.** The system "More" tab wraps overflow items in its own `UINavigationController`. Do NOT wrap overflow tabs in `NavigationStack` — only wrap the first `directTabLimit` (4) tabs. See `MainTabView.directTabLimit`.
- **Always `xcrun simctl uninstall` before testing a fresh build** — stale builds from other schemes/apps persist on the simulator and cause confusing test results.

### Programs

Programs are delivered via two channels:
1. Bundled `Resources/Programs/programs.json` (always available)
2. CloudKit Public DB (admin-seeded, for remote updates)

WODs (Workouts of the Day) are delivered via bundled `Resources/WODs/wods.json`, matched by date.

### Benchmarks

Sundee Fundee Benchmarks (admin-created) follow the same CloudKit + bundled fallback pattern as Programs:
1. Bundled `Resources/Benchmarks/benchmarks.json` (always available)
2. CloudKit Public DB record type `BenchmarkDefinition` (admin-seeded via WOD Dashboard, fetched by `CloudKitBenchmarkDefinitionRepository`)

`BenchmarksViewModel` merges three sources: hardcoded `BenchmarkCatalog.predefined` (Classic WODs, Strength, etc.) + remote benchmarks (CloudKit/bundled JSON, "Sundee Fundee" category) + user-created (SwiftData).

### AI Workout Generation

Personalized workouts are generated on-device via Apple's Foundation Models framework (iOS 26+). The app sends a simplified prompt (time, focus, energy, equipment, injuries) and receives structured output via `@Generable` types (`AIWorkoutOutput`). `WorkoutPostProcessor` then applies deterministic personalization: weight calculations from 1RM maxes, cycle phase multipliers, energy adjustments, and rest period assignment. Falls back to `OfflineWorkoutGenerator` when Apple Intelligence is unavailable on the device. The Cloudflare Worker (`workout-proxy.sundeefundee.workers.dev/generate-workout`) is retained for the WOD Dashboard only.

- **Foundation Models availability check:** Use `SystemLanguageModel.default.isAvailable` — not `FoundationModelAvailability()` (outdated). Generate structured output with `session.respond(to:generating:)` and access result via `.content`.
- **AI-generated exercise names don't match `WeightliftingExerciseCatalog` entries.** Any UI that filters by catalog membership will hide AI workout data. When displaying user-tracked data (OneRepMax, PersonalRecord), include all exercises — don't gate on catalog membership.
- **AI workout flow navigation:** `AIWorkoutFlowView` uses `@State` bindings (`generatedWorkout`, `workoutToStart`) with `.navigationDestination(item:)` to chain Questionnaire → Preview → Execution → Summary. Each step must be wired — no-op closures like `{ _ in }` silently break the flow.
- **`AIExerciseOutput.reps` is `Int`, not `String`.** The AI prompt requests exact rep counts (e.g. 8, not "8-10"). Use 0 for AMRAP. `WorkoutPostProcessor` converts to String for `GeneratedExercise` (0 → "AMRAP"). `WorkoutExecutionViewModel.parseActualReps(_:)` handles the reverse for pre-populating actual reps in the execution UI.

### SundeeFundeeShared Package

`SundeeFundee/Packages/SundeeFundeeShared/` is an **inlined local Swift package** (not a submodule, not a remote package). It contains shared models (Program, WOD, ExerciseCatalog), CloudKit record decoders, and validators used by both the iOS app and the WOD Dashboard. Referenced in `project.yml` under `packages:`.
- **`swift-tools-version` in `Package.swift` must match platform minimums** — `.iOS(.v26)` requires `swift-tools-version: 6.2`. Mismatches cause build failures.

### Subscriptions

**Active:** `AppState.subscriptionTier` defaults to `.free` and is updated by `SubscriptionManager` via StoreKit entitlements. `SubscriptionManager.start()` loads products and refreshes subscription status on launch. The Subscription section is visible in SettingsView.

Product IDs use the `com.sundeefundee.sub.*` prefix (earlier `com.sundeefundee.app.*` IDs are permanently burned in App Store Connect). Four products:
- `com.sundeefundee.sub.plus.monthly` ($4.99/mo)
- `com.sundeefundee.sub.plus.annual` ($39.99/yr)
- `com.sundeefundee.sub.premium.monthly` ($9.99/mo)
- `com.sundeefundee.sub.premium.annual` ($79.99/yr)

Product IDs are defined in `Domain/Subscription/SubscriptionTier.swift` and mirrored in `Resources/SundeeFundee.storekit`.

### Testing

- **Onboarding changes ripple across 3+ test files:** `AuthOnboardingCoverageWave3Tests`, `AuthOnboardingCoverageWave5Tests`, `AuthOnboardingViewCoverageTests`, and `UICriticalFlowTests` all test `OnboardingFlowView` statics. Grep for usage before modifying the onboarding signature.
- **Schema/tab metadata tests:** `AppAuthCoverageTests.appSchemaAndContainerMetadataIsAccessible` asserts schema count and stage count. `MainTabCoverageTests` asserts exact tab order and system images. Update these when changing schemas or tabs.
- **Tab visibility:** `MainTabView.TabRoute` enum cases are NOT automatically visible — only cases in `orderedTabs()` appear in the tab bar. Adding a route to the enum without adding it to `orderedTabs()` makes the feature unreachable.
- **100% line coverage is enforced** in CI (GitHub Actions parses `xccov` output).
- `Domain/` code is tested in isolation via pure Swift unit tests — no mocking needed.
- ViewModels, Repositories, Auth/Onboarding flows, and critical UI paths each have dedicated test wave files.
- When adding new `Domain/` types or public methods, add coverage in the corresponding `*CoverageTests.swift` file.
- When changing default parameter values, update all test call sites to pass the value explicitly — tests that omit the parameter will silently use the new default and may break.
- **Never ignore pre-existing failures.** If test runs, builds, or CI surface issues that predate your changes, investigate and resolve them — do not dismiss them as "pre-existing." Every identified problem is your responsibility to address.

### Project Generation

The Xcode project is generated from `project.yml` via XcodeGen. **Never edit `.xcodeproj` directly** — modify `project.yml` and run `xcodegen generate`. Sources are auto-discovered by XcodeGen from the directory structure — no need to manually add new `.swift` files to `project.yml`.
**After adding new `.swift` files, always run `xcodegen generate`** — even though sources are auto-discovered, the existing `.xcodeproj` won't include new files until regenerated. Without this, new files compile but are invisible to other compilation units in explicit module builds.
- **Deployment target has FOUR locations in `project.yml`:** `options.deploymentTarget.iOS`, `settings.base.IPHONEOS_DEPLOYMENT_TARGET`, `targets.SundeeFundee.deploymentTarget`, and `targets.SundeeFundeTests.deploymentTarget`. Update all four when changing.
- **Build number (`CURRENT_PROJECT_VERSION` in `project.yml`) must be incremented for each App Store Connect upload** — duplicate build numbers cause "Preparing build for App Store Connect failed". HealthKit entitlements require `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in Info.plist (`project.yml` info properties).

### CloudKit Server-to-Server Auth

The WOD Dashboard uses ECDSA server-to-server authentication (no user sign-in needed). Keys:
- Private key: `wod-dashboard/cloudkit-server.pem` (gitignored)
- Key IDs are environment-scoped: development and production keys are separate
- Signature format: `sha256(date:base64(sha256(body)):subpath)` signed with EC P-256
- Required headers: `X-Apple-CloudKit-Request-KeyID`, `X-Apple-CloudKit-Request-ISO8601Date`, `X-Apple-CloudKit-Request-SignatureV1`

### CloudKit Repository Wiring

ViewModels must default to `CloudKit*Repository()` (not `Bundled*Repository()`) for CloudKit-published data to appear in the app. CloudKit repos fall back to bundled JSON automatically. When decoding CloudKit records, use `try?` per-record in `compactMap` so one malformed record doesn't poison the entire fetch.

### CloudKit Schema Management

- `xcrun cktool export-schema --team-id 87VVCMCW3F --container-id iCloud.com.sundeefundee.app --environment development --output-file schema.ckdb`
- `xcrun cktool import-schema ... --file schema.ckdb` (development only; deploy to production via CloudKit Dashboard)
- New record types must be created in development first, then deployed to production — REST API cannot create record types

### WOD Dashboard Patterns

When adding a new entity type to the dashboard (`wod-dashboard/`):
1. Add type to `src/lib/types.ts`
2. Add path to `src/lib/paths.ts`
3. Create API route at `src/app/api/<entity>/route.ts` (GET/PATCH/DELETE, uses `readJSONFile`/`writeJSONFile`)
4. Add CloudKit save function to `src/lib/cloudkit.ts`
5. Update `src/app/api/cloudkit/publish/route.ts` to support the new type
6. Create list + editor components in `src/components/`
7. Create page at `src/app/<entity>/page.tsx` (two-panel split-view)
8. Add nav link to `src/components/sidebar.tsx`

AI generation routes (`src/app/api/generate/`) follow a shared pattern: accept parameters → build Gemini prompt → POST to Cloudflare Worker → strip markdown fences → parse and validate JSON → return typed response. Currently: `wod/`, `program/`, `benchmark/`.

### Coding Conventions

- **Benchmark `roundsAndReps` scoring** encodes as `rounds * 10000 + reps` in a single `Double`. Higher is better. Decode: `rounds = Int(value) / 10000`, `reps = Int(value) % 10000`.
- **Never use `try!`** in production code — always use `(try? ...) ?? defaultValue` for repository calls. SwiftData context errors should degrade gracefully, not crash.
- **Disable buttons for invalid input** rather than silently failing on save. Follow the pattern in `AddCustomBenchmarkSheet` (`.disabled(condition)`).
- **Thread `userID`** from `AppState` through all data-writing operations. Use `appState.currentUserID ?? ""` at the call site; never hardcode empty strings in ViewModels or Repositories.
- **Static helper methods** on Views are the preferred pattern for testability — actions, formatters, and computed state are extracted as `static func` so they can be unit tested without hosting the view.
- **Phase transition dismissals** are persisted to `UserDefaults` under the key `dismissedPhaseTransitions` (keyed by injury ID → suggested phase raw value). Clear on phase change.
