# Codebase Structure

**Analysis Date:** 2026-03-21

## Directory Layout

```
SundeeFundee/
├── App/                           # App entry point and initialization
├── Auth/                          # Authentication (Sign in with Apple, Keychain)
├── Domain/                        # Pure business logic (zero dependencies)
├── Features/                      # Feature modules (views + view models)
├── Models/                        # Data models (@Model and Codable types)
├── Observability/                 # Metrics and diagnostics
├── Onboarding/                    # Onboarding flow (separate from features)
├── Packages/                      # Swift packages (SundeeFundeeShared)
├── Repositories/                  # Data access layer (protocols + implementations)
├── Resources/                     # Assets, plist, entitlements, bundled data
├── Services/                      # Business services (subscriptions, metrics)
└── Theme/                         # Design tokens and styling

SundeeFundeTests/                  # Test suite (co-located with source)

Resources/
├── Assets.xcassets/               # App icon, launch screen, images
├── Programs/                      # Bundled programs.json
├── WODs/                          # Bundled wods.json
├── Info.plist
├── PrivacyInfo.xcprivacy
├── SundeeFundee.entitlements      # iCloud entitlements
└── SundeeFundee.storekit          # StoreKit configuration
```

## Directory Purposes

**App:**
- Purpose: Global app setup, state management, container initialization
- Contains: Main app entry point, root view routing, SwiftData container configuration, schema migrations
- Key files:
  - `SundeeFundeeApp.swift` — @main entry point, initializes container
  - `AppState.swift` — @Observable global state (authState, currentUserID)
  - `AppModelContainer.swift` — Builds shared ModelContainer with fallback tiers
  - `AppSchemaV1-V12.swift` — SwiftData schema versions for migrations
  - `AppSchemaMigrationPlan.swift` — Migration strategy from old to new schema

**Auth:**
- Purpose: Authentication and session management
- Contains: Sign in with Apple, Apple ID credential handling, Keychain operations
- Key files:
  - `AuthService.swift` — Manages ASAuthorizationController, dependency-injected
  - `KeychainHelper.swift` — Persists Apple user ID and guest user ID

**Domain:**
- Purpose: Pure business logic with zero external dependencies
- Contains: Algorithms, decision engines, value transformations
- Subdirectories:
  - `AIWorkout/` — AI workout generation context and offline fallback
  - `Calculations/` — Weight conversions, plate calculations, maxes estimation
  - `History/` — Unified history model for workouts/WODs
- Key files:
  - `InjuryAdaptationEngine.swift` — Adapts programs for active injuries (pure functional)
  - `CycleAdaptationPolicy.swift` — Hormonal cycle adaptation rules
  - `CycleProgramGenerator.swift` — Generates cycle-adapted programs
  - `ReadinessSurvey.swift` — Readiness scoring algorithm
  - `PainTrendAnalyzer.swift` — Analyzes pain logs over time
  - `PhaseTransitionAdvisor.swift` — Advises on program phase changes
  - `ProgramAvailability.swift` — Determines available programs

**Features:**
- Purpose: Feature-specific UI and view models
- Contains: SwiftUI Views, @Observable ViewModels, feature components
- Subdirectories (one per feature):
  - `AIWorkout/` — AI workout generation and preview
  - `Benchmarks/` — Benchmark tracking and scoring
  - `Cycle/` — Hormonal cycle tracking and phase display
  - `Dashboard/` — Home screen, current program, today's WOD
  - `Maxes/` — One-rep max tracking
  - `Programs/` — Program enrollment and session execution
  - `Readiness/` — Readiness survey modals and cards
  - `Settings/` — User settings, weight units, barbell presets
  - `Shared/` — Shared components across features (celebration overlay, banners)
  - `Shell/` — Main tab navigation structure
  - `Subscription/` — Paywall, trial banner, premium features
  - `WODs/` — Workout of the day display and history
  - `Workouts/` — Workout execution timers (EMOM, AMRAP, ForTime)
- Pattern per feature:
  - `[Feature]View.swift` — Main UI
  - `[Feature]ViewModel.swift` — @Observable state holder
  - Optional: `Views/` subdirectory for sub-views
  - Optional: `Components/` subdirectory for reusable feature-specific UI

**Models:**
- Purpose: Persistent data structures and their encoding/decoding
- Contains: @Model SwiftData types and Codable structures
- Files (all Swift files, examples):
  - `User.swift` — User profile (@Model)
  - `CompletedWorkout.swift` — Workout execution record (@Model)
  - `CompletedSet.swift` — Individual set data (@Model)
  - `ActiveCycle.swift` — Current cycle state (@Model)
  - `EnrolledProgram.swift` — Program enrollment (@Model)
  - `InjuryProfile.swift` — Injury tracking (@Model)
  - `Program.swift` — Training program (Codable; fetched from CloudKit)
  - `WOD.swift` — Workout of the day (Codable; fetched from CloudKit)
  - `BenchmarkDefinition.swift` — User-created benchmark definitions (@Model)
  - `BenchmarkResult.swift` — Benchmark scoring (@Model)
  - `ConditioningPR.swift` — Conditioning personal records (@Model)
  - `OneRepMax.swift` — One-rep max tracking (@Model)
  - `PersonalRecord.swift` — Strength PR tracking (@Model)
  - `SharedTypes.swift` — Shared encoding types (ExerciseValue, ConditioningScoringType)
  - `CycleModels.swift` — Cycle-related structures (PeriodLog, SymptomLog, CycleSettings)

**Observability:**
- Purpose: Diagnostics, metrics, crash reporting
- Contains: MetricKit integration
- Key files:
  - `MetricsService.swift` — Subscribes to MetricKit payloads (CPU, memory, crashes)

**Onboarding:**
- Purpose: Multi-step user onboarding flow
- Contains: Onboarding eligibility, views, state management
- Key files:
  - `OnboardingFlowView.swift` — Main onboarding container
  - `OnboardingEligibilityEvaluator.swift` — Determines onboarding requirements

**Packages:**
- Purpose: Shared code usable by other targets (e.g., watchOS)
- Contains: Swift Package definitions
- Subdirectories:
  - `SundeeFundeeShared/` — Shared models, validators, CloudKit wrappers

**Repositories:**
- Purpose: Data access layer with protocol-based implementations
- Contains: Repository protocols and multiple implementations
- Subdirectories:
  - `Protocols/` — All repository protocol definitions
  - `SwiftData/` — SwiftData implementations (local persistence)
  - `CloudKit/` — CloudKit implementations (programs, WODs)
  - `Firebase/` — Firebase implementations (AI workouts, shared workouts)
  - `Gemini/` — Gemini API service for workout generation
  - `HealthKit/` — HealthKit readiness repository
- Key files:
  - `RepositoryProtocols.swift` — Defines UserRepository, WorkoutRepository, CycleRepository, etc.
  - `ProgramRepository.swift` — Router/factory selecting CloudKit implementation
  - `WODRepository.swift` — Router/factory selecting CloudKit implementation
  - `SwiftDataUserRepository.swift` — Implements UserRepository (SwiftData)
  - `SwiftDataWorkoutRepository.swift` — Implements WorkoutRepository (SwiftData)
  - `SwiftDataCycleRepository.swift` — Implements CycleRepository (SwiftData)
  - `CloudKitProgramRepository.swift` — Fetches programs from CloudKit
  - `CloudKitWODRepository.swift` — Fetches WODs from CloudKit
  - `GeminiWorkoutService.swift` — Calls Gemini API for AI workouts
  - `HealthKitReadinessRepository.swift` — Reads HealthKit readiness metrics

**Resources:**
- Purpose: Bundled assets, configuration, and data
- Contains: App icons, launch screens, bundled JSON programs/WODs
- Subdirectories:
  - `Assets.xcassets/` — App icon, launch background, images
  - `Programs/` — Bundled programs.json (always available offline)
  - `WODs/` — Bundled wods.json (always available offline)
- Files:
  - `Info.plist` — App metadata
  - `PrivacyInfo.xcprivacy` — Privacy manifest
  - `SundeeFundee.entitlements` — iCloud entitlements
  - `SundeeFundee.storekit` — StoreKit testing configuration

**Services:**
- Purpose: Business services (subscriptions, metrics)
- Contains: StoreKit 2 integration, subscription management
- Key files:
  - `SubscriptionService.swift` — StoreKit 2 subscription tracking and validation

**Theme:**
- Purpose: Design tokens and styling
- Contains: Color definitions, button styles, typography
- Approach: Art Deco style (cream, navy, orange)

**Tests (SundeeFundeTests):**
- Purpose: Unit and integration tests
- Pattern: One test file per major component (ViewModel, domain logic, repository)
- Examples:
  - `AIWorkoutTests.swift` — Tests for AI workout generation
  - `ReadinessSurveyViewModelTests.swift` — Tests for readiness survey
  - `BarbellTestHelpers.swift` — Shared test fixtures
  - `AuthOnboardingViewCoverageTests.swift` — SwiftUI smoke tests

## Key File Locations

**Entry Points:**
- `SundeeFundee/App/SundeeFundeeApp.swift` — @main app entry point
- `SundeeFundee/Features/Shell/` — Main tab navigation (implied structure)

**Configuration:**
- `SundeeFundee/App/AppModelContainer.swift` — SwiftData container setup with fallbacks
- `SundeeFundee/App/AppSchemaMigrationPlan.swift` — Schema migration strategy
- `SundeeFundee/Resources/Info.plist` — App metadata
- `SundeeFundee/Resources/SundeeFundee.entitlements` — iCloud + HealthKit entitlements

**Core Logic:**
- `SundeeFundee/Domain/InjuryAdaptationEngine.swift` — Injury adaptation
- `SundeeFundee/Domain/CycleAdaptationPolicy.swift` — Hormonal cycle logic
- `SundeeFundee/Domain/ReadinessSurvey.swift` — Readiness scoring

**Data Access:**
- `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` — All protocol definitions
- `SundeeFundee/Repositories/SwiftData/` — Local persistence implementations
- `SundeeFundee/Repositories/CloudKit/` — CloudKit sync implementations
- `SundeeFundee/Repositories/Firebase/` — Firebase AI workout service

**UI Components:**
- `SundeeFundee/Features/Dashboard/DashboardView.swift` — Home screen
- `SundeeFundee/Features/Workouts/WODExecutionView.swift` — Workout execution
- `SundeeFundee/Features/Programs/` — Program enrollment and sessions

**Authentication:**
- `SundeeFundee/Auth/AuthService.swift` — Sign in with Apple
- `SundeeFundee/Auth/KeychainHelper.swift` — Credential persistence
- `SundeeFundee/App/AppState.swift` — Auth state management

**Testing:**
- `SundeeFundeTests/` — All test files (same structure as main)
- `SundeeFundeTests/__mocks__/` — Mock fixtures and test helpers
- `SundeeFundeTests/*Tests.swift` — Test files matching source components

## Naming Conventions

**Files:**
- `[Feature]View.swift` — SwiftUI view component
- `[Feature]ViewModel.swift` — @Observable view model
- `[Thing]Tests.swift` — Test file for [Thing]
- Protocol files: `[ProtocolName]Protocols.swift` or `[Protocol].swift`
- Repository implementations: `[PlatformOrType][Name]Repository.swift` (e.g., `SwiftDataUserRepository.swift`)
- Service files: `[ServiceName]Service.swift`

**Directories:**
- Feature directories: PascalCase singular (`Dashboard`, `Workouts`, `AIWorkout`)
- Implementation directories: Indicate platform/storage (`SwiftData`, `CloudKit`, `Firebase`, `HealthKit`)
- Subdirectories within features: `Views/`, `Components/`

**Code Symbols:**
- Classes/Structs: PascalCase
- Functions/properties: camelCase
- Constants: camelCase or UPPER_SNAKE_CASE for config values
- Enum cases: camelCase
- Protocol names: End with `Protocol` or `Repository` or `Service` for clarity

## Where to Add New Code

**New Feature (e.g., "RecoveryPlanning"):**
1. Create `SundeeFundee/Features/RecoveryPlanning/` directory
2. Add `RecoveryPlanningView.swift` (SwiftUI view)
3. Add `RecoveryPlanningViewModel.swift` (@Observable view model)
4. If new data model needed, add to `SundeeFundee/Models/`
5. If new data access needed:
   - Add protocol to `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
   - Implement in `SundeeFundee/Repositories/SwiftData/SwiftData[Thing]Repository.swift`
6. If new domain logic needed, add to `SundeeFundee/Domain/` (e.g., `RecoveryPlanningEngine.swift`)
7. Add tests in `SundeeFundeTests/RecoveryPlanningViewModelTests.swift`

**New Component (e.g., "RecoveryCard"):**
1. If feature-specific: Add to `SundeeFundee/Features/[Feature]/Components/RecoveryCard.swift`
2. If shared: Add to `SundeeFundee/Features/Shared/RecoveryCard.swift`
3. Prefer components over inline layouts for reusability

**New Domain Logic (e.g., "RecoveryPhaseValidator"):**
1. Add to `SundeeFundee/Domain/RecoveryPhaseValidator.swift`
2. Use pure Swift with no external dependencies (no SwiftUI, no networking)
3. Implement as `enum` with static methods for clarity
4. Add comprehensive unit tests in `SundeeFundeTests/RecoveryPhaseValidatorTests.swift`

**New Data Model:**
1. Add `@Model` struct to `SundeeFundee/Models/` if it persists to SwiftData
2. Add `Codable` struct if it's decoded from CloudKit or APIs
3. If adding to SwiftData, create new `AppSchemaVN.swift` with updated model list
4. Add migration case to `AppSchemaMigrationPlan.swift`

**New Repository Implementation:**
1. Add protocol to `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` if not exists
2. Implement in appropriate platform directory:
   - SwiftData local: `SundeeFundee/Repositories/SwiftData/SwiftData[Name]Repository.swift`
   - CloudKit sync: `SundeeFundee/Repositories/CloudKit/CloudKit[Name]Repository.swift`
   - Firebase: `SundeeFundee/Repositories/Firebase/Firebase[Name]Service.swift`
3. Constructor uses dependency injection (e.g., `modelContext: ModelContext`)
4. All methods throw errors or return async results
5. Write tests that mock both success and failure scenarios

**New Service:**
1. Add to `SundeeFundee/Services/[ServiceName]Service.swift`
2. Make @MainActor if dealing with UI updates
3. Use dependency injection for testability
4. Implement error handling with specific error types

## Special Directories

**Packages/SundeeFundeeShared:**
- Purpose: Shared code reusable by other targets (e.g., watchOS companion)
- Generated: No, hand-written Swift Package
- Committed: Yes
- Contents: Shared models, CloudKit wrappers, validation logic
- Build: Part of main app build; defines Package.swift with library targets

**Resources/Programs, Resources/WODs:**
- Purpose: Bundled JSON data for offline access
- Generated: No; managed by admin dashboard
- Committed: Yes
- Format: JSON arrays of Program/WOD objects
- Load: Decoded at app startup via JSONDecoder

**SundeeFundeTests:**
- Purpose: Unit and integration tests
- Generated: No
- Committed: Yes
- Run: `xcodebuild test -scheme SundeeFundee`
- Coverage: Comprehensive for domain logic, ViewModels, repositories; smoke tests for Views

---

*Structure analysis: 2026-03-21*
