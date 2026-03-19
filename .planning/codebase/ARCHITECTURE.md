# Architecture

**Analysis Date:** 2026-03-18

## Pattern Overview

**Overall:** MVVM + Repository Pattern with Protocol Abstractions

**Key Characteristics:**
- `@Observable` ViewModels (Swift 5.9 Observation framework) drive all SwiftUI views
- Repository protocols decouple storage backends from feature logic
- Domain layer is pure Swift — no SwiftUI, no SwiftData, no framework imports
- SwiftData as the primary local persistence layer, optionally synced via CloudKit
- Features are isolated verticals: each feature owns its View + ViewModel pair

## Layers

**App Layer:**
- Purpose: Entry point, container bootstrap, and top-level routing
- Location: `SundeeFundee/App/`
- Contains: `SundeeFundeeApp.swift` (@main), `AppRootView.swift` (auth router), `AppState.swift` (@Observable auth state), `AppModelContainer.swift` (SwiftData container factory), versioned schema files (`AppSchemaV1.swift` through `AppSchemaV12.swift`), `AppSchemaMigrationPlan.swift`
- Depends on: Auth layer, SwiftData
- Used by: Nothing (top of the stack)

**Auth Layer:**
- Purpose: Sign in with Apple, session restoration, and keychain credential management
- Location: `SundeeFundee/Auth/`
- Contains: `AuthService.swift` (NSObject with ASAuthorizationController integration), `KeychainHelper.swift`, `SignInView.swift`
- Depends on: SwiftData (writes new User on first sign-in), Keychain
- Used by: `AppState`, `AppRootView`

**Feature Layer:**
- Purpose: UI screens and feature-specific ViewModels
- Location: `SundeeFundee/Features/`
- Contains: Feature directories each with `*View.swift` and `*ViewModel.swift` pairs
- Depends on: Repository protocols, Domain, SwiftData via `ModelContext`
- Used by: `MainTabView`, `AppRootView`

**Domain Layer:**
- Purpose: Pure business logic — cycle adaptation, weight calculations, injury engine, AI workout generation
- Location: `SundeeFundee/Domain/`
- Contains: Stateless value types and functions. No framework imports. Fully unit-testable in isolation.
- Depends on: Nothing
- Used by: ViewModels, Repository implementations

**Repository Layer:**
- Purpose: Protocol-based data access abstractions with SwiftData, CloudKit, Firebase, HealthKit, and Gemini backends
- Location: `SundeeFundee/Repositories/`
- Contains: `Protocols/RepositoryProtocols.swift` (all protocol definitions), `SwiftData/` (local CRUD implementations), `CloudKit/` (CloudKit public/private DB), `Firebase/` (AI workout Firestore backend), `HealthKit/` (readiness metrics), `Gemini/` (AI workout generation)
- Depends on: SwiftData, CloudKit, Firebase, HealthKit SDKs
- Used by: ViewModels

**Models Layer:**
- Purpose: SwiftData `@Model` classes persisted to the local store
- Location: `SundeeFundee/Models/`
- Contains: `User.swift`, `CompletedWorkout.swift`, `ActiveCycle.swift`, `EnrolledProgram.swift`, `InjuryProfile.swift`, `BenchmarkDefinition.swift`, and more (22 models total in `AppSchemaV12`)
- Depends on: SwiftData
- Used by: Repository implementations, ViewModels via `@Query`

**Shared Package:**
- Purpose: Types shared between the main app and the WOD admin dashboard (CloudKit-serializable `Program`, `WOD`, validation logic)
- Location: `SundeeFundee/Packages/SundeeFundeeShared/Sources/SundeeFundeeShared/`
- Contains: `Models/Program.swift`, `Models/WOD.swift`, `Models/ExerciseCatalog.swift`, `CloudKit/ProgramCKRecord.swift`, `CloudKit/WODCKRecord.swift`, `Validation/ProgramValidator.swift`
- Depends on: Nothing (plain Swift)
- Used by: Repository implementations, Domain

**Services Layer:**
- Purpose: Cross-cutting infrastructure services
- Location: `SundeeFundee/Services/`, `SundeeFundee/Observability/`
- Contains: `SubscriptionService.swift` (StoreKit 2 in-app purchases), `MetricsService.swift` (MetricKit diagnostics)

**Theme Layer:**
- Purpose: Design token constants for the Art Deco visual theme
- Location: `SundeeFundee/Theme/`
- Contains: `AppTheme.swift` (colors, spacing, corner radii, fonts, view modifiers), `ButtonStyles.swift`

## Data Flow

**User Authentication:**

1. `SundeeFundeeApp` creates `ModelContainer` and renders `AppRootView`
2. `AppRootView` calls `AuthService.restoreSession(modelContext:)` on appear
3. `AuthService` checks Apple ID credential state from Keychain
4. `AuthService` returns `AuthState` (.loading → .authenticated / .needsOnboarding / .signedOut / .guest)
5. `AppState.apply(_:)` updates `authState`, triggering `AppRootView` to switch destination
6. `AppRootView.Destination` routes to `LoadingView`, `SignInView`, `OnboardingFlowView`, or `MainTabView`

**Workout Data Load (Dashboard):**

1. `DashboardView` creates `DashboardViewModel` and calls `.load(modelContext:)` on task
2. ViewModel creates SwiftData repository instances inline (e.g., `SwiftDataUserRepository(context: modelContext)`)
3. ViewModel fetches program catalog via `CloudKitProgramRepository` (async)
4. ViewModel reads cycle logs, injury records, readiness metrics from local SwiftData
5. Domain functions (`CycleProgramGenerator.adaptProgram`, `InjuryAdaptationEngine.adaptProgram`) transform raw data into adapted `Program`
6. ViewModel publishes state; SwiftUI diffs and re-renders

**Workout Execution:**

1. User taps "Start Workout" from Dashboard; `WorkoutExecutionViewModel` is initialized with `ProgramSession`, `EnrolledProgram`, `Program`
2. User records sets via `WorkoutExecutionView`; state held in `[String: [SetExecutionState]]` dictionary
3. On "Complete", ViewModel saves `CompletedWorkout` + `CompletedSet` records via `SwiftDataWorkoutRepository`
4. `EnrolledProgramRepository.updateProgress` advances the week/day cursor
5. `NotificationCenter.post(.didSaveNewPRs)` fires if personal records are broken

**State Management:**
- Global: `AppState` (`@Observable`) injected via `.environment(appState)` from `AppRootView`
- Global: `SubscriptionService` (`@Observable`) injected via `.environment(subscriptionService)` from `AppRootView`
- Feature: `@Observable` ViewModels created by their parent View, passed as `@State`
- Local persistence: SwiftData `ModelContext` accessed via `@Environment(\.modelContext)` and `@Query`
- User defaults: Subscription tier cache, dismissed phase transitions, HealthKit toggle

## Key Abstractions

**Repository Protocols:**
- Purpose: Swap storage backends without touching ViewModels (enables testing with mocks)
- Definition: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
- Protocols: `UserRepository`, `WorkoutRepository`, `CycleRepository`, `LiftRepository`, `EnrolledProgramRepository`, `BenchmarkDefinitionRepository`, `BenchmarkResultRepository`, `InjuryRepository`, `PainLogRepository`, `ReadinessRepository`, `ProgramRepository`, `WODRepository`, `AIWorkoutServiceProtocol`, `SharedWorkoutRepository`, `BarbellRepository`
- Implementations: `SwiftData*` (local), `CloudKit*` (remote catalog), `Firebase*` (AI), `HealthKit*` (biometrics)

**AuthState Enum:**
- Purpose: Drives top-level routing as a finite state machine
- Definition: `SundeeFundee/App/AppState.swift`
- Cases: `.loading`, `.signedOut`, `.needsOnboarding(userID:appleUserID:)`, `.authenticated(userID:)`, `.guest`

**Domain Functions (stateless):**
- `CycleProgramGenerator.adaptProgram(_:phase:settings:preferences:periodLogs:readinessScore:)` — adapts a `Program` for the user's hormonal cycle phase: `SundeeFundee/Domain/CycleProgramGenerator.swift`
- `InjuryAdaptationEngine.adaptProgram(_:activeInjuries:)` — modifies exercises based on active injuries: `SundeeFundee/Domain/InjuryAdaptationEngine.swift`
- `CycleCalculations.calculateCycleStatus(periodLogs:settings:)` — computes current phase from period log history: `SundeeFundee/Domain/CycleCalculations.swift`
- `PlateCalculation` — barbell and plate math: `SundeeFundee/Domain/Calculations/PlateCalculation.swift`
- `WeightCalculations` — 1RM estimation formulas: `SundeeFundee/Domain/Calculations/WeightCalculations.swift`

**AppModelContainer:**
- Purpose: Factory for SwiftData `ModelContainer` with three-tier fallback (CloudKit → local persistent → in-memory)
- Definition: `SundeeFundee/App/AppModelContainer.swift`
- Schema version: `AppSchemaV12` (22 `@Model` types), migration plan in `AppSchemaMigrationPlan.swift`

**Enum Raw-Value Pattern for SwiftData:**
- SwiftData `@Model` classes cannot store Swift enums directly (CloudKit compatibility)
- Pattern: Store as `String` raw value property (e.g., `genderRaw: String`), expose computed enum property (e.g., `var gender: Gender`)
- Example: `SundeeFundee/Models/User.swift`

## Entry Points

**App Entry:**
- Location: `SundeeFundee/App/SundeeFundeeApp.swift`
- Triggers: iOS app launch (`@main`)
- Responsibilities: Instantiates `ModelContainer`, starts `MetricsService`, renders `AppRootView`

**Main Navigation Shell:**
- Location: `SundeeFundee/Features/Shell/MainTabView.swift`
- Triggers: `AppRootView` when `authState` is `.authenticated` or `.guest`
- Responsibilities: 5-tab navigation (Dashboard, Programs, WODs, History, More); "More" tab expands to Maxes, Benchmarks, Cycle (female/unspecified only), Settings via `NavigationLink`

**Onboarding:**
- Location: `SundeeFundee/Onboarding/OnboardingFlowView.swift`
- Triggers: `AppRootView` when `authState` is `.needsOnboarding`
- Responsibilities: 5-step profile collection (name → experience → goal → gender → cycle opt-in), writes `User` record to SwiftData, transitions to `.authenticated`

## Error Handling

**Strategy:** Synchronous throws propagated via `try?` at call sites; async errors surfaced as ViewModel `errorMessage: String?` properties

**Patterns:**
- Repository methods throw synchronously: `func save(_ workout: CompletedWorkout) throws`
- ViewModels call repos with `try?`, silently degrading on failure (data-loss risk — see CONCERNS.md)
- Async AI/CloudKit calls use `try/catch` inside `Task` blocks with ViewModel `errorMessage` binding
- `AppModelContainer` uses cascading fallback (CloudKit → local → in-memory) rather than fatal errors, except as last resort

## Cross-Cutting Concerns

**Logging:** `print(...)` with bracketed prefixes (e.g., `[AppRootView]`, `[AppModelContainer]`). No structured logging framework.
**Validation:** Input validation in `SundeeFundee/Packages/SundeeFundeeShared/Sources/SundeeFundeeShared/Validation/` (`ProgramValidator.swift`, `WODValidator.swift`).
**Authentication:** Sign in with Apple via `AuthService`; credential persisted in Keychain. No Firebase Auth in the Swift codebase.
**Observability:** MetricKit via `MetricsService` (CPU, memory, crashes). Debug-only console logging of payloads.
**Subscriptions:** StoreKit 2 via `SubscriptionService` (tiers: free, plus, pro). Product IDs: `com.sundeefundee.plusmonthly`, `com.sundeefundee.pro.monthly`.

---

*Architecture analysis: 2026-03-18*
