# Architecture

**Analysis Date:** 2025-03-14

## Pattern Overview

**Overall:** MVVM + Domain-Driven Design with Protocol-Based Data Layer

**Key Characteristics:**
- SwiftUI views bind to `@Observable` `@MainActor` ViewModels
- Protocol-based repository layer enables testability and pluggable implementations (SwiftData, CloudKit, Gemini, HealthKit)
- Pure Swift Domain layer with zero framework dependencies — fully unit tested and independently composable
- CloudKit (private + public databases) for authenticated users; SwiftData local-first for guests
- Authentication routing via `AppState` state machine with Sign in with Apple integration

## Layers

**Presentation (SwiftUI Views + ViewModels):**
- Purpose: Render UI and respond to user interactions; route between auth states and features
- Location: `SundeeFundee/Features/`, `SundeeFundee/App/`, `SundeeFundee/Onboarding/`, `SundeeFundee/Auth/`
- Contains: SwiftUI Views, `@Observable` ViewModels, view-specific state management
- Depends on: Repositories (via protocol), Domain for business logic calculation
- Used by: SwiftUI rendering engine; nothing else

**Domain (Business Logic):**
- Purpose: Pure Swift implementations of training adaptation, cycle phase calculations, injury modifications, benchmarking, pain trend analysis, workout generation context
- Location: `SundeeFundee/Domain/` (21 files including subdirectories: AIWorkout, Calculations, History)
- Contains: Enums, structs, utility functions with no SwiftUI/SwiftData imports; 100% test coverage enforced
- Depends on: Foundation only; no framework dependencies
- Used by: ViewModels, Repositories, Services for decision-making and calculations

**Data Layer (Repositories):**
- Purpose: Abstract data access; provide protocol-based interfaces for SwiftData, CloudKit, Gemini, HealthKit, file system
- Location: `SundeeFundee/Repositories/` with subdirectories: Protocols, SwiftData, CloudKit, Gemini, HealthKit
- Contains: Protocol definitions (`RepositoryProtocols.swift`), concrete implementations for each backend
- Depends on: Models, Domain (for domain types), external SDKs (CloudKit, Gemini API, HealthKit)
- Used by: ViewModels, Services

**Models (SwiftData + DTOs):**
- Purpose: Define persistent data structures and domain-agnostic DTOs
- Location: `SundeeFundee/Models/` (18 `@Model` types) and `Repositories/Protocols/` (DTOs like `BarbellPresetDTO`)
- Contains: SwiftData `@Model` classes; Codable enums (stored as raw `String` for CloudKit compatibility)
- Depends on: Foundation, SwiftData
- Used by: Repositories, ViewModels, Domain types

**Services:**
- Purpose: Singleton-scoped cross-cutting concerns: authentication, metrics, subscription management
- Location: `SundeeFundee/Services/` (`SubscriptionService.swift`), `SundeeFundee/App/`, `SundeeFundee/Auth/`
- Contains: `AppState`, `AuthService`, `SubscriptionService`, `MetricsService`
- Depends on: Repositories, Models, framework SDKs
- Used by: App root, Views (via environment), ViewModels

**Theme:**
- Purpose: Centralized design tokens (Art Deco palette: cream/navy/orange) and reusable view modifiers
- Location: `SundeeFundee/Theme/`
- Contains: `AppTheme` enum with Colors, Spacing, Radius, Fonts; `ButtonStyles`
- Depends on: SwiftUI only
- Used by: All feature views

## Data Flow

**Authentication Flow:**

1. App launches → `SundeeFundeeApp` creates `AppModelContainer` (CloudKit or local SwiftData)
2. `AppRootView` initializes `AppState` → calls `AuthService.restoreSession()`
3. `AuthService` checks keychain for stored Apple User ID
   - If found and valid → `AppState.apply(.authenticated(userID:))`
   - If expired or absent → `AppState.apply(.signedOut)`
4. `AppRootView` routes to `SignInView`, `OnboardingFlowView`, or `MainTabView` based on `AppState.authState`
5. On Sign in with Apple → `AuthService` persists Apple User ID to keychain, creates `User` model
6. Guest mode: User taps "Continue as Guest" → `AppState.signInAsGuest()` → uses local SwiftData only, no CloudKit

**Workout Execution Flow:**

1. User opens `DashboardView` → loads via `DashboardViewModel`
   - Queries `ProgramRepository` (CloudKit with bundled fallback) for enrolled programs
   - Queries `SwiftDataWorkoutRepository` for recent workouts
   - Queries `CycleRepository` for current menstrual phase (if applicable)
2. User taps "Start Workout" → navigates to `WorkoutExecutionView` with `WorkoutExecutionViewModel`
3. ViewModel queries `ProgramRepository` for session details, applies:
   - `InjuryAdaptationEngine.adaptProgram()` — filters/replaces exercises for active injuries
   - `CycleAdaptationPolicy` — scales load/sets/reps based on current cycle phase
4. User completes exercises, saves sets via `SwiftDataWorkoutRepository.save()`
5. On workout completion, `WorkoutExecutionViewModel` records `CompletedWorkout` and triggers celebration event

**AI Workout Generation Flow:**

1. User opens AIWorkout tab → `AIWorkoutView` with `AIWorkoutViewModel`
2. ViewModel collects questionnaire: time, focus, energy, equipment, desired skills
3. Calls `GeminiWorkoutService` (proxied through Cloudflare Worker) with `WorkoutGenerationContext`
   - Context includes: current cycle phase, active injuries, one-rep maxes, readiness score
4. `GeminiPromptBuilder` constructs system + user prompts incorporating cycle + injury adaptations
5. Gemini returns structured JSON → `GeminiResponseParser` deserializes to `GeneratedWorkout`
6. ViewModel applies `OfflineWorkoutGenerator` fallback if API fails
7. Workout saved to `SwiftDataAIWorkoutService` (SwiftData-backed Firebase alternative)

**Unified History Flow:**

1. `MainTabView` renders `HistoryTabView` (wrapper that defers service construction)
2. `HistoryTabView` captures `modelContext` from environment, creates `UnifiedHistoryViewModel`
   - ViewModel queries `SwiftDataWorkoutRepository` for `CompletedWorkout` records
   - ViewModel queries `SwiftDataAIWorkoutService` for `GeneratedWorkoutRecord` records
3. Domain type `HistoryItem` merges both sources into single chronological list
4. View supports filtering (All/AI/Program) and swipe-to-delete via `UnifiedHistoryView`

**State Management:**
- `AppState` (@Observable @MainActor) — top-level auth routing
- Feature ViewModels (@Observable @MainActor) — feature-scoped state; queried from environment via `@State` + `@Environment`
- `SubscriptionService` (@Observable @MainActor) — subscription tier, passed via environment
- SwiftData `ModelContext` — implicit via `@Environment(\.modelContext)` in Views

## Key Abstractions

**Repository Protocols:**
- Purpose: Enable swapping implementations without changing caller code
- Examples: `ProgramRepository`, `WorkoutRepository`, `CycleRepository`, `AIWorkoutServiceProtocol`, `ReadinessRepository`, `BarbellRepository`
- Location: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` (204 lines)
- Pattern: Async/throws methods marked `Sendable` where applicable; protocol conformance for concrete implementations

**Domain Engines:**
- Purpose: Encapsulate complex decision logic
- Examples: `InjuryAdaptationEngine`, `CycleAdaptationPolicy`, `PhaseTransitionAdvisor`, `BenchmarkCatalog`, `RehabSessionGenerator`, `PainTrendAnalyzer`
- Location: `SundeeFundee/Domain/`
- Pattern: Static enum methods (immutable, composable); return new instances rather than mutate inputs

**Program + Session Models:**
- Purpose: Represent program structure and sessions hierarchically
- Examples: `Program` (Codable, CloudKit-compatible), `ProgramWeek`, `ProgramSession`, `ProgramPhase`
- Location: `SundeeFundee/Models/Program.swift` and related files
- Pattern: Nested Codable structures; cycle adjustment metadata embedded in programs

**Generated Workout Domain Type:**
- Purpose: Encapsulate AI-generated workout with exercises, questionnaire context, scoring logic
- Examples: `GeneratedWorkout`, `GeneratedExercise` with equipment type inference and weight snapping
- Location: `SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift`
- Pattern: Codable for JSON serialization; computed properties for derived data (muscle groups, duration, equipment type)

**History Item:**
- Purpose: Unified DTO merging program and AI workout sources
- Examples: `HistoryItem` (enum: `.program(CompletedWorkout)` | `.aiGenerated(GeneratedWorkoutRecord)`)
- Location: `SundeeFundee/Domain/History/HistoryItem.swift`
- Pattern: Allows single query/filter/sort over heterogeneous data sources

## Entry Points

**App Initialization:**
- Location: `SundeeFundee/App/SundeeFundeeApp.swift`
- Triggers: App launch; skips ModelContainer creation during tests to avoid CloudKit validation
- Responsibilities: Set test environment flag, instantiate shared ModelContainer, start metrics service

**Root Navigation:**
- Location: `SundeeFundee/App/AppRootView.swift`
- Triggers: When `AppState.authState` changes
- Responsibilities: Route between loading, sign-in, onboarding, main tabs; restore session from keychain; initialize `SubscriptionService`

**Main Tab Shell:**
- Location: `SundeeFundee/Features/Shell/MainTabView.swift`
- Triggers: User authenticated or in guest mode
- Responsibilities: Render tab bar, switch between 8 tabs (Dashboard, Programs, WODs, History, Maxes, Benchmarks, Cycle, Settings); filter Cycle tab for male users

**Dashboard:**
- Location: `SundeeFundee/Features/Dashboard/DashboardView.swift` + `DashboardViewModel.swift`
- Triggers: User taps Dashboard tab
- Responsibilities: Load active program, recent workouts, cycle phase, readiness score, active injuries; offer "Start Workout" action

## Error Handling

**Strategy:** Graceful degradation with user-facing feedback; no `try!` in production code

**Patterns:**
- `(try? ...) ?? defaultValue` — repository calls degrade to empty results or cached data on failure
- `@ViewBuilder` conditional rendering — show placeholder/error state instead of crashing
- CloudKit fallback to bundled JSON — `CloudKitProgramRepository` falls back to `BundledProgramRepository` on network/auth failure
- SwiftData context error recovery — `AppModelContainer` tries local persistent store, then in-memory if corrupted
- API timeouts → offline fallback (e.g., `OfflineWorkoutGenerator` when Gemini proxy times out)

## Cross-Cutting Concerns

**Logging:** Print statements with `[ComponentName]` prefix (e.g., `[AppRootView]`, `[AppModelContainer]`); debug-only diagnostics via `MetricsService`

**Validation:** Input validation in Views via `.disabled(condition)` pattern (e.g., `AddCustomBenchmarkSheet`); Domain types validate invariants in init

**Authentication:**
- `AppState` drives auth routing
- `AuthService` manages Apple ID sign-in, credential state checks, keychain persistence
- `AppState.currentUserID` threaded through data-writing operations (never hardcoded empty strings)

**Cycle Phase Adaptation:**
- `CycleAdaptationPolicy` computes load/set/rep multipliers based on current phase + readiness score
- Applied automatically during program adaptation in ViewModels before rendering

**Injury Modification:**
- `InjuryAdaptationEngine` substitutes/removes exercises for active injury profiles
- Applied during program load; metadata tracks original exercises for analytics

**Subscription Tier:**
- `SubscriptionService` loads tier from UserDefaults + StoreKit 2 transactions
- Features check `subscriptionService.tier` before enabling premium functionality (passed via environment)

**Test Isolation:**
- `SundeeFundeeApp.init()` detects test execution via `XCTestConfigurationFilePath` environment variable
- Test container uses in-memory schema with no SwiftData/CloudKit validation
- ViewModels accept injected repository dependencies for mock substitution
