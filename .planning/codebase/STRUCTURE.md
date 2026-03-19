# Codebase Structure

**Analysis Date:** 2026-03-18

## Directory Layout

```
SundeeFundee/                          # Xcode project root
├── SundeeFundee/                      # Main app source
│   ├── App/                           # Entry point, container, routing
│   ├── Auth/                          # Sign in with Apple, keychain
│   ├── Domain/                        # Pure Swift business logic
│   │   ├── AIWorkout/                 # AI workout generation domain types
│   │   ├── Calculations/              # Weight math, plate calculator
│   │   └── History/                   # History domain types
│   ├── Features/                      # SwiftUI screens (View + ViewModel pairs)
│   │   ├── AIWorkout/                 # AI workout flow and history
│   │   ├── Benchmarks/                # Benchmark tracking
│   │   ├── Cycle/                     # Hormonal cycle tracking
│   │   ├── Dashboard/                 # Main dashboard
│   │   ├── Maxes/                     # 1RM and lift max tracking
│   │   ├── Programs/                  # Program catalog and enrollment
│   │   ├── Readiness/                 # Readiness survey and cards
│   │   ├── Settings/                  # User settings
│   │   ├── Shared/                    # Cross-feature UI components
│   │   ├── Shell/                     # Tab navigation shell
│   │   ├── Subscription/              # Paywall
│   │   ├── WODs/                      # Workout of the Day
│   │   └── Workouts/                  # Workout execution
│   ├── Models/                        # SwiftData @Model classes
│   ├── Observability/                 # MetricKit metrics service
│   ├── Onboarding/                    # Multi-step onboarding flow
│   ├── Packages/                      # Local Swift Packages
│   │   └── SundeeFundeeShared/        # Shared types (Program, WOD, validation)
│   │       └── Sources/SundeeFundeeShared/
│   │           ├── CloudKit/          # CKRecord wrappers
│   │           ├── Models/            # Program.swift, WOD.swift, ExerciseCatalog
│   │           └── Validation/        # ProgramValidator, WODValidator
│   ├── Repositories/                  # Data access layer
│   │   ├── Protocols/                 # All repository protocol definitions
│   │   ├── SwiftData/                 # Local SwiftData implementations
│   │   ├── CloudKit/                  # CloudKit public/private DB
│   │   ├── Firebase/                  # Firebase AI workout service
│   │   ├── Gemini/                    # Gemini AI workout generation
│   │   └── HealthKit/                 # HealthKit readiness metrics
│   ├── Resources/                     # Assets, bundled JSON
│   │   ├── Assets.xcassets/           # Images, colors, app icon
│   │   ├── Programs/                  # Bundled program JSON files
│   │   └── WODs/                      # Bundled WOD JSON files
│   ├── Services/                      # Infrastructure services
│   └── Theme/                         # Design tokens (AppTheme, ButtonStyles)
├── SundeeFundeTests/                  # XCTest suite (~60+ test files)
├── SundeeFundee.xcodeproj/            # Xcode project file
├── wod-dashboard/                     # Next.js admin dashboard
│   └── src/app/                       # Next.js App Router pages
├── fastlane/                          # Fastlane lanes for CI/CD
├── ci_scripts/                        # CI shell scripts
└── project.yml                        # XcodeGen project spec
```

## Directory Purposes

**`SundeeFundee/App/`:**
- Purpose: App lifecycle, SwiftData container, auth-based routing
- Contains: `SundeeFundeeApp.swift` (@main), `AppRootView.swift`, `AppState.swift`, `AppModelContainer.swift`, `AppSchemaMigrationPlan.swift`, `AppSchemaV1.swift` – `AppSchemaV12.swift`
- Key files: `SundeeFundee/App/AppState.swift` (auth state machine), `SundeeFundee/App/AppModelContainer.swift` (container factory)

**`SundeeFundee/Auth/`:**
- Purpose: Authentication only — Sign in with Apple + keychain
- Contains: `AuthService.swift`, `KeychainHelper.swift`, `SignInView.swift`
- Key files: `SundeeFundee/Auth/AuthService.swift`

**`SundeeFundee/Domain/`:**
- Purpose: Zero-dependency business logic — safe to unit-test without any mocks or containers
- Contains: Cycle adaptation policies, weight calculations, injury engine, AI workout domain types, phase transition advisors, readiness survey logic
- Key files: `SundeeFundee/Domain/CycleProgramGenerator.swift`, `SundeeFundee/Domain/InjuryAdaptationEngine.swift`, `SundeeFundee/Domain/CycleCalculations.swift`, `SundeeFundee/Domain/Calculations/PlateCalculation.swift`, `SundeeFundee/Domain/Calculations/WeightCalculations.swift`

**`SundeeFundee/Features/`:**
- Purpose: All SwiftUI feature screens. Each subdirectory is a self-contained vertical slice
- Contains: `*View.swift` (SwiftUI) + `*ViewModel.swift` (`@Observable @MainActor final class`) pairs
- Key files: `SundeeFundee/Features/Shell/MainTabView.swift`, `SundeeFundee/Features/Dashboard/DashboardView.swift`, `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift`

**`SundeeFundee/Models/`:**
- Purpose: SwiftData `@Model` class definitions — the local data schema
- Contains: 22 model types including `User.swift`, `CompletedWorkout.swift`, `ActiveCycle.swift`, `EnrolledProgram.swift`, `InjuryProfile.swift`, `BenchmarkDefinition.swift`, `BenchmarkResult.swift`, `LiftMax.swift`, `OneRepMax.swift`, `PersonalRecord.swift`, `ConditioningPR.swift`, `GeneratedWorkoutRecord.swift`, `BarbellPreset.swift`, `ExerciseBarMapping.swift`
- Key files: `SundeeFundee/Models/User.swift`, `SundeeFundee/Models/CompletedWorkout.swift`

**`SundeeFundee/Repositories/Protocols/`:**
- Purpose: Protocol definitions for all data access. Reference here before implementing any new data logic.
- Key files: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`

**`SundeeFundee/Repositories/SwiftData/`:**
- Purpose: Concrete SwiftData repository implementations conforming to repository protocols
- Key files: `SwiftDataWorkoutRepository.swift`, `SwiftDataUserRepository.swift`, `SwiftDataCycleRepository.swift`, `SwiftDataLiftRepository.swift`, `SwiftDataEnrolledProgramRepository.swift`, `SwiftDataInjuryRepository.swift`, `SwiftDataBarbellRepository.swift`, `SwiftDataBenchmarkDefinitionRepository.swift`, `SwiftDataBenchmarkResultRepository.swift`, `SwiftDataPainLogRepository.swift`

**`SundeeFundee/Packages/SundeeFundeeShared/`:**
- Purpose: Local Swift Package for types shared between the iOS app and the WOD admin dashboard. `Program` and `WOD` value types live here so they can be used both in `wod-dashboard/` and in repository code.
- Key files: `Sources/SundeeFundeeShared/Models/Program.swift`, `Sources/SundeeFundeeShared/Models/WOD.swift`, `Sources/SundeeFundeeShared/Models/ExerciseCatalog.swift`

**`SundeeFundee/Theme/`:**
- Purpose: Centralized design tokens — never hardcode colors, spacing, or font sizes in views
- Key files: `SundeeFundee/Theme/AppTheme.swift`

**`SundeeFundeTests/`:**
- Purpose: XCTest test suite (~60+ files covering domain, repositories, ViewModels, and view rendering)
- Contains: One test file per feature/layer concern, `BarbellTestHelpers.swift` shared helpers

**`wod-dashboard/`:**
- Purpose: Next.js admin dashboard for managing WODs and Programs, writes to CloudKit/Firestore
- Contains: `src/app/` (Next.js App Router), `src/components/`, `src/lib/`, `src/types/`
- Key files: `wod-dashboard/src/app/editor/[date]/page.tsx` (WOD editor), `wod-dashboard/src/app/programs/[id]/page.tsx` (program editor)

## Key File Locations

**Entry Points:**
- `SundeeFundee/App/SundeeFundeeApp.swift`: `@main` app struct
- `SundeeFundee/App/AppRootView.swift`: Auth-state router (loading / sign-in / onboarding / tabs)
- `SundeeFundee/Features/Shell/MainTabView.swift`: 5-tab navigation shell

**Configuration:**
- `project.yml`: XcodeGen project specification — edit this, not the `.xcodeproj` directly
- `SundeeFundee/App/AppSchemaMigrationPlan.swift`: SwiftData migration plan
- `SundeeFundee/App/AppSchemaV12.swift`: Current schema (list of all 22 `@Model` types)

**Core Logic:**
- `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`: All repository protocol contracts
- `SundeeFundee/App/AppState.swift`: `AuthState` enum + `AppState` observable
- `SundeeFundee/Services/SubscriptionService.swift`: StoreKit 2 subscription management
- `SundeeFundee/Theme/AppTheme.swift`: All design tokens

**Testing:**
- `SundeeFundeTests/`: All test files flat in this directory

## Naming Conventions

**Files:**
- SwiftUI view: `FeatureNameView.swift` (e.g., `DashboardView.swift`)
- ViewModel: `FeatureNameViewModel.swift` (e.g., `DashboardViewModel.swift`)
- SwiftData repository: `SwiftData{Entity}Repository.swift` (e.g., `SwiftDataWorkoutRepository.swift`)
- CloudKit repository: `CloudKit{Entity}Repository.swift`
- Protocol definition: `RepositoryProtocols.swift` (all in one file)
- Schema version: `AppSchemaV{N}.swift`

**Types:**
- ViewModels: `@Observable @MainActor final class` named `{Feature}ViewModel`
- Repositories: `final class` named `SwiftData{Entity}Repository` or `CloudKit{Entity}Repository`
- Models: `@Model final class` using PascalCase
- Enums stored in SwiftData: suffix raw storage property with `Raw` (e.g., `genderRaw: String`)

**Directories:**
- Features are PascalCase matching the feature name (e.g., `Features/Dashboard/`, `Features/Workouts/`)
- Repository backends are PascalCase matching the backend (e.g., `Repositories/SwiftData/`, `Repositories/CloudKit/`)

## Where to Add New Code

**New Feature Screen:**
- Create directory: `SundeeFundee/Features/{FeatureName}/`
- View: `SundeeFundee/Features/{FeatureName}/{FeatureName}View.swift`
- ViewModel: `SundeeFundee/Features/{FeatureName}/{FeatureName}ViewModel.swift`
- Register tab in `SundeeFundee/Features/Shell/MainTabView.swift` if top-level

**New SwiftData Model:**
1. Create model file in `SundeeFundee/Models/{ModelName}.swift`
2. Increment schema version: create `SundeeFundee/App/AppSchemaV{N+1}.swift` with `models` array
3. Add lightweight migration stage to `SundeeFundee/App/AppSchemaMigrationPlan.swift`
4. Update `AppModelContainer.allModels` to point to new schema version

**New Repository Protocol + Implementation:**
1. Add protocol to `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
2. Create implementation in the appropriate backend directory (e.g., `SundeeFundee/Repositories/SwiftData/SwiftData{Entity}Repository.swift`)

**New Domain Logic:**
- Pure Swift functions/types only — no framework imports
- Place in `SundeeFundee/Domain/` or a new subdirectory under Domain
- Add corresponding tests in `SundeeFundeTests/`

**New Tests:**
- Add to `SundeeFundeTests/` directory, named `{Subject}Tests.swift`
- Domain tests require no mocking — instantiate domain types directly
- ViewModel tests inject mock repository implementations via protocol

**Shared Types (app + dashboard):**
- Add to `SundeeFundee/Packages/SundeeFundeeShared/Sources/SundeeFundeeShared/`
- Must be `public` and `Sendable`

**Utilities:**
- Shared UI helpers: `SundeeFundee/Features/Shared/`
- Design tokens: `SundeeFundee/Theme/AppTheme.swift`

## Special Directories

**`SundeeFundee/App/` (schema versions):**
- Purpose: Each `AppSchemaV{N}.swift` captures the full list of models at that migration step
- Generated: No (hand-maintained)
- Committed: Yes

**`SundeeFundee/Packages/SundeeFundeeShared/`:**
- Purpose: Local Swift Package embedded in the Xcode project; not published to a registry
- Generated: No
- Committed: Yes

**`wod-dashboard/.next/`:**
- Purpose: Next.js build output
- Generated: Yes
- Committed: No (should be in .gitignore)

**`fastlane/`:**
- Purpose: Fastlane lanes for TestFlight distribution and CI
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-03-18*
