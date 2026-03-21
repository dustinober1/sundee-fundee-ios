# Architecture

**Analysis Date:** 2026-03-21

## Pattern Overview

**Overall:** Layered MVVM (Model-View-ViewModel) with Protocol-Based Data Access

The application follows a strict separation of concerns across three tiers:
- **Presentation Layer (Features):** SwiftUI views + @Observable ViewModels
- **Repository Layer:** Protocol-based data access abstractions
- **Domain Layer:** Pure Swift business logic with zero dependencies
- **Persistence:** SwiftData (local) + CloudKit (sync) + Firebase (backup)

This architecture emphasizes testability, reusability, and clear data flow direction.

**Key Characteristics:**
- Strict unidirectional data flow from domain through repositories to UI
- Protocol-based repositories enable interchangeable implementations (SwiftData, CloudKit, Firebase, etc.)
- Domain layer completely isolated from SwiftUI, networking, and persistence details
- ViewModels as thin orchestrators that compose repositories and domain logic
- Exhaustive use of @Observable for reactive state management
- Test-friendly through dependency injection in every layer

## Layers

**Presentation Layer (Features):**
- Purpose: Render UI and respond to user interactions
- Location: `SundeeFundee/Features/`
- Contains: SwiftUI Views, @Observable ViewModels
- Depends on: Repository protocols, domain types, theme, components
- Used by: App root view

**Feature Structure:**
Each feature in `SundeeFundee/Features/[FeatureName]/` follows:
- `[Feature]View.swift` — SwiftUI view, reads from ViewModel
- `[Feature]ViewModel.swift` — @Observable state holder, calls repositories and domain logic
- Subdirectories: `Views/`, `Components/` for complex features

**Repository Layer (Data Access):**
- Purpose: Abstract all data source details (SwiftData, CloudKit, Firebase, etc.)
- Location: `SundeeFundee/Repositories/`
- Contains: Protocol definitions, multiple implementations
- Depends on: Models, domain types
- Used by: ViewModels, services

**Repository Structure:**
```
Repositories/
├── Protocols/
│   └── RepositoryProtocols.swift       # All protocol definitions (UserRepository, WorkoutRepository, etc.)
├── SwiftData/
│   ├── SwiftDataUserRepository.swift
│   ├── SwiftDataWorkoutRepository.swift
│   ├── SwiftDataCycleRepository.swift
│   ├── SwiftDataLiftRepository.swift
│   └── [other implementations]
├── CloudKit/
│   ├── CloudKitProgramRepository.swift
│   └── CloudKitWODRepository.swift
├── Firebase/
│   └── FirebaseAIWorkoutService.swift
├── Gemini/
│   └── GeminiWorkoutService.swift
├── HealthKit/
│   └── HealthKitReadinessRepository.swift
└── ProgramRepository.swift               # Router that selects implementation
```

**Domain Layer (Pure Business Logic):**
- Purpose: Implement all decision logic, calculations, and algorithms
- Location: `SundeeFundee/Domain/`
- Contains: Pure Swift enums and structs, zero dependencies on SwiftUI or networking
- Depends on: Foundation only
- Used by: ViewModels, repositories, services

**Domain Organization:**
```
Domain/
├── AIWorkout/
│   ├── GeneratedWorkout.swift         # AI-generated workout model
│   ├── OfflineWorkoutGenerator.swift  # Fallback offline generation
│   └── WorkoutGenerationContext.swift # Parameterization for AI requests
├── Calculations/
│   ├── BarbellDefaults.swift
│   ├── PlateCalculation.swift
│   ├── WeightCalculations.swift
│   └── WeightUnitConversion.swift
├── History/
│   └── HistoryItem.swift              # Unified history model
├── CycleAdaptationPolicy.swift        # Hormonal cycle adaptation rules
├── CycleProgramGenerator.swift        # Generates adapted programs based on cycle
├── InjuryAdaptationEngine.swift       # Adapts programs for active injuries
├── LoadAdjustmentPolicy.swift         # Load adjustment strategy
├── PainTrendAnalyzer.swift            # Analyzes pain logs
├── PhaseTransitionAdvisor.swift       # Advises on program phase transitions
├── ProgramAvailability.swift          # Determines which programs are available
├── ReadinessSurvey.swift              # Readiness survey scoring
└── RehabSessionGenerator.swift        # Generates rehab-focused sessions
```

**Models Layer (Persistent Entities):**
- Purpose: Define data structures for persistence and serialization
- Location: `SundeeFundee/Models/`
- Contains: @Model SwiftData types + Codable structures
- Depends on: Foundation, SwiftData

**Key Models:**
- `User.swift` — User profile (name, gender, weight unit preference)
- `CompletedWorkout.swift` — Workout execution record
- `CompletedSet.swift` — Individual set data
- `ActiveCycle.swift` — Current hormonal cycle tracking
- `EnrolledProgram.swift` — Program enrollment state
- `InjuryProfile.swift` — Injury tracking and adaptation
- `Program.swift` — Training program structure (not @Model; fetched from CloudKit)
- `WOD.swift` — Workout of the day (not @Model; fetched from CloudKit)
- `BenchmarkDefinition.swift`, `BenchmarkResult.swift` — Benchmark data

**Auth Layer:**
- Purpose: Manage authentication state and credentials
- Location: `SundeeFundee/Auth/`
- Contains: AuthService, KeychainHelper, SignInView
- Depends on: AuthenticationServices, SwiftData

**App Layer (Infrastructure):**
- Purpose: Initialize app state, configure persistence, set up global services
- Location: `SundeeFundee/App/`
- Contains:
  - `SundeeFundeeApp.swift` — @main app entry point
  - `AppState.swift` — Global auth state enum + state machine (@Observable)
  - `AppModelContainer.swift` — Builds shared SwiftData ModelContainer with fallback tiers
  - `AppSchemaV*.swift` — Data schema versions for SwiftData migrations

**Key Services:**
- `SubscriptionService.swift` — StoreKit 2 subscription management
- `MetricsService.swift` — MetricKit diagnostics logging

## Data Flow

**User Interaction Flow:**

1. **SwiftUI View** captures user action (button tap, form submission)
2. **View calls ViewModel method** to initiate state change
3. **ViewModel orchestrates:**
   - Calls domain logic (pure calculations, decision rules)
   - Calls repository to persist or fetch data
   - Updates @Observable state for reactive re-render
4. **Repository** handles persistence:
   - SwiftDataWorkoutRepository: Insert/fetch/delete from local SwiftData store
   - CloudKitProgramRepository: Fetch programs from CloudKit
   - GeminiWorkoutService: Call external Gemini API
5. **View re-renders** when @Observable ViewModel state changes

**Example: Create and Save a Workout**

```
WODExecutionView (user completes workout)
  → calls WODExecutionViewModel.saveCompletedWorkout()
    → calls InjuryAdaptationEngine.adaptProgram() [domain logic]
    → calls ReadinessSurvey.scoreReadiness() [domain logic]
    → calls workoutRepository.save(completedWorkout) [SwiftData]
    → workoutRepository inserts into ModelContext + saves
    → ViewModel updates @Observable state
      → View re-renders showing success
```

**Program Generation Flow:**

```
AIWorkoutFlowView (user starts AI workout)
  → calls AIWorkoutViewModel.generateWorkout()
    → calls SwiftDataAIWorkoutService.generateWorkout()
      → calls GeminiWorkoutService.generate() [online]
      → falls back to OfflineWorkoutGenerator [offline]
    → calls modelContext.insert(GeneratedWorkoutRecord) [SwiftData]
    → ViewModel updates @Observable state
      → View shows generated workout
```

**Authentication Flow:**

```
SignInView (user taps Sign in with Apple)
  → calls AuthService.performAppleSignIn()
    → ASAuthorizationController handles UI
    → AuthService delegates to KeychainHelper.saveAppleUserID()
    → AuthService updates AppState.authState
      → App routing changes to authenticated tab view
```

**State Management:**
- `AppState.authState` — Top-level auth state (loading, signedOut, needsOnboarding, authenticated, guest)
- Feature ViewModels use `@Observable` with @MainActor for thread-safe reactive state
- ViewModels are NOT shared; each view gets its own ViewModel instance
- State persists via SwiftData + CloudKit; AppState coordinates global transitions

## Key Abstractions

**Repository Protocols:**
- Purpose: Define contracts for data access, enabling multiple implementations
- Examples: `UserRepository`, `WorkoutRepository`, `CycleRepository`, `LiftRepository`
- Pattern: Protocol defines async methods throwing errors; implementations handle concrete logic
- File: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`

**InjuryAdaptationEngine:**
- Purpose: Adapt training programs for active injury profiles
- Pattern: Enum with static methods (pure functional)
- Input: Program + [InjuryProfile], Output: Adapted Program
- Files: `SundeeFundee/Domain/InjuryAdaptationEngine.swift`
- No mutations; returns new Program instances

**CycleAdaptationPolicy & CycleProgramGenerator:**
- Purpose: Apply hormonal cycle-aware training adaptations
- Pattern: Pure domain logic for phase detection and rep/load adjustments
- Files: `SundeeFundee/Domain/CycleAdaptationPolicy.swift`, `CycleProgramGenerator.swift`

**ReadinessSurvey:**
- Purpose: Score user readiness based on survey responses
- Pattern: Static scoring algorithm
- File: `SundeeFundee/Domain/ReadinessSurvey.swift`

**AIWorkoutServiceProtocol:**
- Purpose: Generate workouts via Gemini with offline fallback
- Implementations: `SwiftDataAIWorkoutService` (with SwiftData persistence)
- Pattern: Async generation with automatic fallback to OfflineWorkoutGenerator

**SharedTypes (Encodable Value Types):**
- `ExerciseValue` — Represents sets/reps (fixed, range, AMRAP, text)
- `ConditioningScoringType` — Scoring rules for conditioning benchmarks
- Files: `SundeeFundee/Models/SharedTypes.swift`

## Entry Points

**App Launch:**
- Location: `SundeeFundee/App/SundeeFundeeApp.swift`
- Triggers: App startup
- Responsibilities:
  - Creates AppModelContainer (SwiftData + optional CloudKit)
  - Initializes MetricsService
  - Renders root view

**Root Navigation:**
- Location: `SundeeFundee/Features/Shell/` (implied main navigation structure)
- Triggers: AppState.authState changes
- Responsibilities:
  - Routes to SignInView if signed out
  - Routes to OnboardingFlowView if needsOnboarding
  - Routes to TabView (Dashboard, Workouts, Programs, Cycle, Maxes, Settings) if authenticated
  - Routes to GuestView if guest mode

**Feature Entry (Example: Dashboard):**
- Location: `SundeeFundee/Features/Dashboard/DashboardView.swift`
- Triggers: User selects Dashboard tab
- Responsibilities:
  - Displays current program, today's WOD, readiness metrics
  - Calls DashboardViewModel.load() to fetch state
  - ViewModel coordinates multiple repositories and domain logic

## Error Handling

**Strategy:** Exhaustive error handling with domain-specific error types

**Patterns:**
- Repository methods throw errors (try/catch in ViewModels)
- Domain logic returns successful results or nil (no error throwing)
- Services (Gemini, HealthKit) throw errors caught by calling ViewModel
- Fallback behavior for critical paths (e.g., offline workout generation)

**Example Error Types:**
- `ProgramDecodingError` — Invalid program structure
- `AIWorkoutServiceError` — Encoding/decoding failures, auth failures
- Repository errors bubble up as thrown exceptions

**Error Recovery:**
- SwiftDataAIWorkoutService: Falls back to OfflineWorkoutGenerator on any error
- AppModelContainer: Tiered fallback (CloudKit → LocalPersistent → InMemory)
- ViewModel: Catches and displays error UI (alert, banner, disabled state)

## Cross-Cutting Concerns

**Logging:**
Approach: MetricsService (MetricKit diagnostics) + print() in DEBUG builds
- `SundeeFundee/Observability/MetricsService.swift` subscribes to MetricKit payloads
- Logs CPU time, memory usage, crashes, hangs
- Only enabled in DEBUG builds

**Validation:**
Approach: Input validation at ViewModel level before repository calls
- Weight values validated against min/max ranges
- Program structures validated during decoding
- Exercise values support multiple formats (fixed, range, AMRAP, text)

**Authentication:**
Approach: Sign in with Apple via AuthService, session restoration from Keychain
- AuthService manages ASAuthorizationController delegate chain
- KeychainHelper persists user IDs (Apple ID + guest ID)
- AppState enforces auth state transitions (no unauthorized access)

**Theming:**
Approach: Centralized theme tokens in `SundeeFundee/Theme/`
- Art Deco design: cream (#F4F0DF), navy (#0D1A40), orange (#F2731A)
- SwiftUI Color extensions for consistent styling
- ButtonStyles for standard interaction patterns

**Data Persistence:**
Approach: Multi-tier local-first with optional cloud sync
- SwiftData: Local persistent store (always available)
- CloudKit: Optional sync to iCloud private database
- Firebase: Backup/async operations (AI workouts, crash reporting)
- AsyncStorage (non-persistent preferences): Weight units, cycle settings

---

*Architecture analysis: 2026-03-21*
