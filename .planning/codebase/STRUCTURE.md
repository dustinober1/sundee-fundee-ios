# Codebase Structure

**Analysis Date:** 2025-03-14

## Directory Layout

```
SundeeFundee/
├── App/                  # Initialization, routing, schema, debug data
├── Auth/                 # Sign in with Apple, keychain, session restoration
├── Domain/               # Pure Swift business logic (100% coverage)
├── Features/             # Tab-based feature modules (Views + ViewModels)
├── Models/               # SwiftData @Model types, enums as raw strings
├── Onboarding/           # Post-sign-in user profile setup
├── Observability/        # Metrics collection (MetricKit)
├── Packages/             # SundeeFundeeShared submodule
├── Repositories/         # Data access protocols + implementations
├── Resources/            # Assets, bundled JSON (programs.json, wods.json)
├── Services/             # Singleton services (Subscription, Auth)
└── Theme/                # Design tokens, colors, fonts, spacing

SundeeFundeTests/         # Test suite (100% line coverage enforced)
└── *Tests.swift          # Unit + integration tests by component
```

## Directory Purposes

**App:**
- Purpose: Application initialization, root state machine, SwiftData schema management, debug utilities
- Contains: SwiftUI entry point, AppState, ModelContainer setup, schema migrations V1–V12, seed data
- Key files:
  - `SundeeFundeeApp.swift` — @main entry point; skips ModelContainer in test mode
  - `AppState.swift` — @Observable state machine (loading → signedOut → needsOnboarding → authenticated/guest)
  - `AppRootView.swift` — Routes between auth states; initializes SubscriptionService
  - `AppModelContainer.swift` — Vends shared ModelContainer with CloudKit or local fallback
  - `AppSchema*.swift` — 12 versioned schema files for lightweight migrations

**Auth:**
- Purpose: Sign in with Apple integration, keychain management, credential state validation
- Contains: AuthService, Apple ID credential handling, sign-in UI components
- Key files:
  - `AuthService.swift` — Manages Apple authentication flow, keychain persistence, session restoration
  - `KeychainHelper.swift` (inferred) — Persistence for Apple User IDs

**Domain:**
- Purpose: Business logic layer with zero framework dependencies
- Contains: Calculation engines, policy engines, data transformers
- Key subdirectories/files:
  - `AIWorkout/` — GeneratedWorkout model, WorkoutGenerationContext, OfflineWorkoutGenerator
  - `Calculations/` — Weight calculations, plate/barbell defaults, unit conversion
  - `History/` — HistoryItem DTO merging CompletedWorkout and GeneratedWorkoutRecord
  - `CycleAdaptationPolicy.swift` — Load/rep/set multipliers by menstrual phase + readiness
  - `InjuryAdaptationEngine.swift` — Exercise replacement/removal for injury profiles
  - `PhaseTransitionAdvisor.swift` — Cycle phase change guidance
  - `BenchmarkCatalog.swift` — Standard fitness benchmarks
  - `RehabSessionGenerator.swift` — Injury recovery workout generation
  - `PainTrendAnalyzer.swift` — Pain log trend analysis
  - `CycleCalculations.swift`, `CycleProgramGenerator.swift` — Menstrual cycle logic
  - `ReadinessSurvey.swift` — Readiness questionnaire
  - All marked for 100% line coverage in tests

**Features:**
- Purpose: Tab-based feature modules; each directory contains View + ViewModel pair(s)
- Contains: User-facing screens and feature-scoped state management
- Key subdirectories (one per tab or feature):
  - `Dashboard/` — Home screen; active program, recent workouts, readiness banner
  - `Programs/` — Program discovery, enrollment, progress tracking
  - `WODs/` — Workout of the Day feed (bundled + CloudKit)
  - `Workouts/` — Program session execution (timer views: ForTime, AMRAP, EMOM)
  - `AIWorkout/` — AI-generated workout creation + history
  - `History/` — Unified history (both program + AI workouts) with filtering
  - `Maxes/` — One-rep max tracking
  - `Benchmarks/` — Benchmark definition + result tracking
  - `Cycle/` — Menstrual cycle tracking, symptom/period logs, adaptation settings
  - `Settings/` — User profile, preferences, legal, account deletion
  - `Subscription/` — Paywall + StoreKit 2 integration
  - `Shared/` — Reusable components (SpicyRatingView, CelebrationOverlay, ReadinessAdjustmentBanner)
  - `Shell/` — MainTabView (tab navigation controller)
  - `Readiness/` — HealthKit readiness metrics survey

**Models:**
- Purpose: Define persistent data structures and marshaling types
- Contains: SwiftData @Model classes, domain-specific enums (stored as raw String for CloudKit)
- Key files (18 @Model types):
  - `User.swift` — User profile, experience level, goal, gender, weight unit, body weight
  - `Program.swift` — Training program structure (weeks, sessions, phases, cycle adjustments)
  - `CompletedWorkout.swift` — Recorded session completion; CompletedSet child records
  - `GeneratedWorkoutRecord.swift` — Persisted AI-generated workouts
  - `EnrolledProgram.swift` — User's active program enrollment + progress
  - `ActiveCycle.swift`, `CycleModels.swift` — Menstrual cycle tracking (periods, symptoms, settings)
  - `InjuryProfile.swift` — Active injury records with recovery phase + body location
  - `BenchmarkDefinition.swift`, `Benchmark.swift`, `BenchmarkResult.swift` — Fitness benchmarks
  - `LiftMax.swift`, `Maxes.swift` — One-rep max history
  - `PainLog.swift` — Injury pain recordings
  - `WOD.swift` — Workout of the Day (bundled + CloudKit)
  - `BarbellPreset.swift`, `ExerciseBarMapping.swift` — Equipment config
  - `SharedWorkoutTemplateRecord.swift` — Community-shared workouts
  - `SharedTypes.swift` — Enums (all stored as raw `String`): ExperienceLevel, PrimaryGoal, Gender, WeightUnit, SubscriptionTier, etc.

**Onboarding:**
- Purpose: Post-sign-in user profile setup
- Contains: Onboarding flow, eligibility evaluation
- Key files:
  - `OnboardingFlowView.swift` — Multi-step questionnaire (name, experience, goal, gender, cycle tracking opt-in)
  - `OnboardingEligibilityEvaluator.swift` — Determines which onboarding steps to show

**Observability:**
- Purpose: Metrics and diagnostics collection
- Contains: MetricKit integration for performance monitoring
- Key files:
  - `MetricsService.swift` — Singleton subscriber to MXMetricManager; logs CPU, memory, crash diagnostics to Xcode Organizer

**Packages:**
- Purpose: Git submodule for shared code with Flutter app (SundeeFundeeShared)
- Contains: `SundeeFundeeShared/` as a tracked submodule
- Note: Modifications must be committed to submodule first, then added to main repo

**Repositories:**
- Purpose: Protocol-based data access layer with multiple implementations
- Contains: Repository protocols, CloudKit, SwiftData, Gemini, HealthKit, Firebase backends
- Key subdirectories:
  - `Protocols/RepositoryProtocols.swift` — All 12 protocol definitions
  - `SwiftData/` — 11 SwiftData implementations (WorkoutRepository, CycleRepository, LiftRepository, BenchmarkRepository, etc.)
  - `CloudKit/` — CloudKitProgramRepository, CloudKitWODRepository, CloudKitSharedWorkoutRepository
  - `Gemini/` — GeminiWorkoutService, GeminiPromptBuilder, GeminiResponseParser (API integration via Cloudflare Worker)
  - `HealthKit/` — HealthKitReadinessRepository (VO2max, HRV, sleep metrics)
  - `Firebase/` — FirebaseAIWorkoutService (legacy/alternative to Gemini)
  - Top-level files: ProgramRepository (cloudKit + bundled fallback), WODRepository (CloudKit + bundled fallback)

**Resources:**
- Purpose: Bundled data files and assets
- Contains:
  - `Programs/programs.json` — Bundled training programs (fallback when CloudKit unavailable)
  - `WODs/wods.json` — Bundled Workouts of the Day (matched by date)
  - `Assets.xcassets/` — App icons, image assets, color sets
  - `SundeeFundee.entitlements` — Production capabilities (CloudKit, Sign in with Apple, HealthKit)
  - `SundeeFundee.Debug.entitlements` — Debug capabilities (empty for Personal Team signing)
  - `SundeeFundee.storekit` — StoreKit 2 product configuration
  - `Info.plist` — App metadata, privacy policy links
  - `PrivacyInfo.xcprivacy` — Privacy manifest (required iOS 17+)

**Services:**
- Purpose: Singleton-scoped cross-cutting concerns
- Contains:
  - `SubscriptionService.swift` — Subscription tier state (@Observable), StoreKit 2 integration
  - `AuthService.swift` (also in Auth/) — Sign in with Apple orchestration

**Theme:**
- Purpose: Centralized design token library
- Contains: Colors (Art Deco: cream #F4F0DF, navy #0D1A40, orange #F2731A), spacing, fonts, button styles
- Key files:
  - `AppTheme.swift` — Enum namespace with Color, Colors (semantic aliases), Spacing, Radius, Fonts, view modifiers
  - `ButtonStyles.swift` — Reusable button style definitions

## Key File Locations

**Entry Points:**
- `SundeeFundee/App/SundeeFundeeApp.swift` — @main struct; app initialization
- `SundeeFundee/App/AppRootView.swift` — Root routing controller
- `SundeeFundee/Features/Shell/MainTabView.swift` — Tab navigation root
- `SundeeFundee/Onboarding/OnboardingFlowView.swift` — Post-sign-in setup flow

**Configuration:**
- `SundeeFundee/App/AppModelContainer.swift` — SwiftData container setup, CloudKit/local fallback strategy
- `SundeeFundee/App/AppSchema*.swift` — Schema version definitions (currently V12)
- `SundeeFundee/App/AppSchemaMigrationPlan.swift` — Lightweight migration stages
- `SundeeFundee/Resources/SundeeFundee.entitlements` — CloudKit + iCloud container ID
- `project.yml` (repo root) — XcodeGen project configuration (source of truth for build settings)

**Core Logic:**
- `SundeeFundee/Domain/InjuryAdaptationEngine.swift` — Injury-based exercise modification
- `SundeeFundee/Domain/CycleAdaptationPolicy.swift` — Menstrual cycle load adaptation
- `SundeeFundee/Domain/CycleCalculations.swift` — Phase inference from period logs
- `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` — All repository contracts
- `SundeeFundee/Models/Program.swift` — Program data structure with CloudKit decoding

**Testing:**
- `SundeeFundeTests/` — All test files (30+ test classes)
- `SundeeFundeTests/DomainCoverageTests.swift` — Domain layer 100% coverage wave
- `SundeeFundeTests/ViewModelCoverageTests.swift` — ViewModel 100% coverage wave
- `SundeeFundeTests/RepositoryCoverageTests.swift` — Repository mock + integration tests
- Test files use naming pattern: `*Tests.swift` or `*CoverageTests.swift`

## Naming Conventions

**Files:**
- Views: `[Feature]View.swift` (e.g., `DashboardView.swift`, `MaxLiftsView.swift`)
- ViewModels: `[Feature]ViewModel.swift` (e.g., `DashboardViewModel.swift`)
- Repositories: `[Backend][Domain]Repository.swift` (e.g., `SwiftDataWorkoutRepository.swift`, `CloudKitProgramRepository.swift`)
- Services: `[Service]Service.swift` (e.g., `GeminiWorkoutService.swift`, `SubscriptionService.swift`)
- Tests: `*Tests.swift` or `*CoverageTests.swift`
- Models: Noun-based (e.g., `User.swift`, `Program.swift`, `InjuryProfile.swift`)
- Domain logic: Descriptive nouns/verbs (e.g., `InjuryAdaptationEngine.swift`, `CycleAdaptationPolicy.swift`, `BenchmarkCatalog.swift`)

**Directories:**
- Feature directories: PascalCase, feature name (e.g., `Dashboard/`, `AIWorkout/`, `WODs/`)
- Repository subdirectories: Backend name (e.g., `SwiftData/`, `CloudKit/`, `Gemini/`)
- Domain subdirectories: Concept name (e.g., `Calculations/`, `AIWorkout/`, `History/`)

## Where to Add New Code

**New Feature (UI + Logic):**
1. Create feature directory: `SundeeFundee/Features/[FeatureName]/`
2. Add View file: `[FeatureName]View.swift`
3. Add ViewModel file: `[FeatureName]ViewModel.swift` (if stateful)
4. Inject repositories via ViewModel init dependency injection
5. Add to shell: Register in `MainTabView.destination(for:)` switch if it's a new tab
6. Add tests: `SundeeFundeTests/[FeatureName]CoverageTests.swift`

**New Domain Type/Calculation:**
1. Add to appropriate subdirectory: `SundeeFundee/Domain/[Category]/[TypeName].swift`
2. Use pure Swift (no framework imports except Foundation)
3. Implement as enum (methods) or struct (values) with static functions
4. Add 100% coverage tests in: `SundeeFundeTests/DomainCoverageTests.swift` (or category-specific wave)
5. Example: `CycleAdaptationPolicy` → tests in `DomainCoverageTests.swift`

**New Model Type:**
1. Add `@Model` class to: `SundeeFundee/Models/[ModelName].swift` or append to existing `SharedTypes.swift`
2. All enum properties stored as raw `String` (CloudKit requirement)
3. Provide computed properties for typed accessors: `var gender: Gender { ... }`
4. Update schema: copy `AppSchemaV{N}.swift` → `AppSchemaV{N+1}.swift`, bump version
5. Add lightweight migration stage to `AppSchemaMigrationPlan.swift`
6. Update `AppModelContainer.allModels` to reference new schema
7. Add tests: query/fetch tests in `SundeeFundeTests/RepositoryCoverageTests.swift`

**New Repository Implementation:**
1. Add to appropriate subdirectory: `SundeeFundee/Repositories/[Backend]/[Domain]Repository.swift`
2. Conform to protocol in `RepositoryProtocols.swift`
3. For async repositories: mark as `Sendable` if no mutable state
4. Add error handling: return empty results or cached data on failure
5. Add tests: mock test cases in `SundeeFundeTests/RepositoryCoverageTests.swift`

**Utilities & Helpers:**
1. Shared calculations: `SundeeFundee/Domain/Calculations/[Util].swift`
2. Shared UI components: `SundeeFundee/Features/Shared/[Component]View.swift`
3. View helpers: static methods on Views (preferred for testability) or extension functions
4. Example: `DashboardView.static func durationLabel(...) -> String` → unit testable without hosting view

## Special Directories

**Packages/SundeeFundeeShared:**
- Purpose: Shared Swift code with Flutter app (git submodule)
- Generated: No (manual commits)
- Committed: Yes (tracked as submodule)
- To update: `cd SundeeFundee/Packages/SundeeFundeeShared && git commit ...`, then `git add` in main repo

**Resources/Programs/ and Resources/WODs/:**
- Purpose: Bundled JSON fallbacks when CloudKit is unavailable
- Generated: No (hand-edited or admin-seeded)
- Committed: Yes
- Format: JSON encoded (Program, WOD array)
- Usage: Loaded by BundledProgramRepository and CloudKitWODRepository fallbacks

**Tests Directory (SundeeFundeTests/):**
- Purpose: 100% line coverage test suite
- Generated: No (hand-written)
- Committed: Yes
- Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee ...`
- Coverage: CI enforces 100% via `xccov` output parsing in GitHub Actions

**.xcodeproj Directory:**
- Purpose: Generated from project.yml via XcodeGen
- Generated: Yes (run `xcodegen generate`)
- Committed: Yes (after regeneration; schema migrations may require regeneration)
- Never edit `.pbxproj` directly — modify `project.yml` instead

---

*Structure analysis: 2025-03-14*
