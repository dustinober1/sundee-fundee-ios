# Architecture

**Analysis Date:** 2026-04-15

## Pattern Overview

**Overall:** Clean layered architecture with strict separation between business logic (DomainLayer), data persistence (DataLayer), authentication, and presentation (UI).

**Key Characteristics:**
- Pure domain layer with zero framework dependencies
- Protocol-based data layer enabling client switching (CloudKit for signed-in, LocalDataClient for guests)
- Actor-based concurrency for thread-safe data clients
- Swift 6 strict concurrency throughout
- Environment-based dependency injection for ViewModels
- Tab-based navigation with feature-specific views

## Layers

**DomainLayer:**
- Purpose: Pure business logic mirroring the original web app's domain layer
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`
- Contains: Cycle calculations, benchmarks, challenges, exercises, injury models, program templates, coach logic, analytics, celebration events, AI workout generation, intelligence features (plateau detection, schedule reshuffling, substitution ranking, weekly load analysis), export logic
- Depends on: Nothing (zero framework imports)
- Used by: DataLayer, ViewModels, UI layer

**DataLayer:**
- Purpose: Abstract persistence via protocols; implementations handle CloudKit (signed-in users), local storage (guests), mock implementations (testing)
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/`
- Contains:
  - `Protocols/`: `DataClientProtocol`, `ContentClientProtocol`, `HealthClientProtocol`
  - `Actors/`: `CloudKitClient` (CloudKit persistence), `LocalDataClient` (local guest storage), `HealthKitClient` (HealthKit integration)
  - `Mocks/`: `MockCloudKitClient`, `MockHealthKitClient` (for testing)
  - `BundledContent/`: `BundledContentProvider` (hardcoded fallback for exercises, benchmarks, programs)
  - `Helpers/`: `CyclePhaseHelper` (cycle calculations), `CyclePhaseCache` (observable cycle phase state)
  - `SyncQueue/`: `SyncQueue` (offline-first mutation queue), `NetworkMonitor` (connectivity tracking), `PendingMutation` (enqueued operation)
  - `DataClientFactory`: Thread-safe singleton for switching clients at runtime
- Depends on: DomainLayer types (for Codable models)
- Used by: ViewModels, AuthViewModel

**AuthLayer:**
- Purpose: Apple Sign-In authentication and Keychain session storage
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Auth/`
- Contains: `AppleAuthClient` (Sign in with Apple flow), `AppleAuthClientProtocol` (interface), `AuthError` (localized errors), `AppleAuthResult` (credential result), `KeychainHelper` (Keychain read/write)
- Depends on: Foundation, SwiftUI, AuthenticationServices
- Used by: `AuthViewModel`

**SubscriptionLayer:**
- Purpose: StoreKit 2 subscription management
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Subscription/`
- Contains: Subscription models and StoreKit 2 integration
- Depends on: StoreKit
- Used by: ViewModels, Settings UI
- **Note:** App is free with all features unlocked; no paywalls or purchase flows

**ActivityLayer:**
- Purpose: Live activity integration for workout sessions
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Activity/`
- Contains: `LiveWorkoutActivityManager`, `LiveWorkoutActivityAttributes`
- Depends on: ActivityKit, SwiftUI
- Used by: `ActiveWorkoutSessionViewModel`

**UILayer:**
- Purpose: SwiftUI views, view models, and design system
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/`
- Contains:
  - `App/`: `SundeeFundeeApp` (MainTabView), `MainTabView` (tab navigation)
  - `Theme/`: `AppTheme` (Art Deco design tokens: cream #f4f0df, navy #0d1a40, gold #d4a520, orange #f27319)
  - `ViewModels/`: `AuthViewModel`, `DashboardViewModel`, `AnalyticsViewModel`, `BenchmarksViewModel`, `ExportViewModel`, `ActiveWorkoutSessionViewModel`, `PainTrackingViewModel`
  - `Views/`: Feature-specific views organized by domain (Dashboard, Workouts, Programs, Maxes, Analytics, Benchmarks, Challenges, Cycle, Insights, Pain, Onboarding, Settings, Export, Share)
  - `Models/`: `SharedModels.swift` (UI-specific types)
- Depends on: SwiftUI, DomainLayer, DataLayer, AuthLayer
- Used by: Xcode app target (`SundeeFundeeApp/SundeeFundee/App.swift`)

**ModelsLayer:**
- Purpose: Shared Codable data models for persistence and cross-module communication
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Models/`
- Contains: `Challenge.swift`, `Exercise.swift`, `Workout.swift`
- Depends on: Foundation (Codable)
- Used by: DomainLayer, DataLayer, ViewModels

## Data Flow

**Authentication & Session Setup:**

1. User launches app
2. `SundeeFundeeMain` checks `AuthViewModel.checkExistingSession()`
3. AuthViewModel restores Keychain session or presents `AuthView` for Sign in with Apple
4. On successful sign-in: `AppleAuthClient.signIn()` → credential + identity token
5. AuthViewModel stores to Keychain, saves `UserRecord` to CloudKit via `DataClientFactory.shared.client`
6. Factory switches client: `CloudKitClient` for signed-in users, `LocalDataClient` for guests
7. After auth, `MainTabView()` renders tab navigation

**Guest Mode (No CloudKit):**

1. User taps "Continue as Guest"
2. `AuthViewModel.continueAsGuest()` sets `isGuest = true`, `userID = "guest_local"`
3. `DataClientFactory.shared.client` switches to `LocalDataClient`
4. Data persists locally; no CloudKit writes
5. Guest data does NOT sync to CloudKit on later sign-in

**Data Fetching (e.g., Workouts):**

1. ViewController initializes: `@StateObject private var viewModel = WorkoutViewModel()`
2. ViewModel's `init()` accesses `DataClientFactory.shared.client`
3. `Task { await viewModel.loadData() }` called in `.task { }` modifier
4. ViewModel calls `dataClient.fetchAll(WorkoutRecord.self)` (protocol method)
5. `CloudKitClient` or `LocalDataClient` executes async fetch
6. Results decoded from JSON; individual record decode failures logged (resilient decode)
7. ViewModel updates `@Published` properties
8. SwiftUI body re-renders with new data

**Data Writing (e.g., Save Workout):**

1. User completes workout in `ActiveWorkoutView`
2. `ActiveWorkoutSessionViewModel.saveWorkout()` called
3. Guard: `if !authViewModel.isGuest` (skip CloudKit write for guests)
4. ViewModel creates `WorkoutRecord` (Codable model)
5. `dataClient.save(record)` enqueues mutation
6. If online: `CloudKitClient.save()` immediately writes to CloudKit
7. If offline: `SyncQueue` enqueues `PendingMutation`
8. `NetworkMonitor` detects connectivity → `SyncQueue` replays mutations
9. Notification `.workoutCompleted` posted for UI refresh

**Cycle Phase Calculation & Caching:**

1. Dashboard loads; requests cycle phase
2. `cyclePhaseCache.refresh()` called
3. Cache fetches `CycleSettingsRecord` and `PeriodLogRecord` from DataClient
4. Calls `CycleCalculations.calculatePhase(date:, settings:)` (pure domain function)
5. Returns `CyclePhase` enum (menstrual, follicular, ovulation, luteal)
6. Cache stores phase as `@Published` property
7. Views listen to `@EnvironmentObject var cyclePhaseCache: CyclePhaseCache`
8. `SharkWeekBanner` displays if `cyclePhaseCache.isSharkWeek`

## Key Abstractions

**DataClientProtocol:**
- Purpose: Generic async protocol for persistent data operations
- Examples: `CloudKitClient`, `LocalDataClient`, `MockCloudKitClient`
- Pattern: Generic `fetchAll<T: Codable & Sendable>()`, `fetch<T>(recordID:)`, `save<T>(record:)`, `delete(recordID:)`, `deleteAll<T>()`
- Returns: Async throws for error handling

**AppleAuthClientProtocol:**
- Purpose: Authenticate via Apple Sign-In
- Examples: `AppleAuthClient` (production), mock for testing
- Pattern: `signIn(scopes:) async throws -> AppleAuthResult`, `getCredentialState(forUserID:)`, `revokeToken()`

**ContentClientProtocol:**
- Purpose: Fetch bundled content (exercises, benchmarks, programs)
- Examples: `BundledContentProvider` (hardcoded fallback)
- Pattern: Read-only access to reference data

**HealthClientProtocol:**
- Purpose: Read HealthKit data (activity rings, step count, etc.)
- Examples: `HealthKitClient` (production), `MockHealthKitClient` (testing)
- Pattern: Async query methods

**CyclePhaseCache:**
- Purpose: Observable cached cycle phase state
- Pattern: `@StateObject` in views; `@EnvironmentObject` passed down
- Exposes: `currentPhase`, `isSharkWeek`, `refresh()` method

**ViewModels:**
- Purpose: Bind UI to data, manage state, coordinate data operations
- Examples: `AuthViewModel` (@MainActor singleton in App.swift), `DashboardViewModel` (@StateObject in views)
- Pattern: `@Published` properties for binding, async `loadData()` methods, error handling via `@Published errorMessage`

## Entry Points

**App Entry Point:**
- Location: `SundeeFundeeApp/SundeeFundee/App.swift`
- Triggers: App launch
- Responsibilities: 
  - Create `@StateObject` instances: `AuthViewModel`, `ThemeViewModel`
  - Check auth state; conditionally show `OnboardingView`, `MainTabView`, or `AuthView`
  - Apply theme via `artDecoBackground()` modifier
  - Log iCloud availability and active DataClient
  - Handle screenshot seeding (`--seed-screenshots` command line argument)

**UI Entry Point (MainTabView):**
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`
- Triggers: After successful authentication
- Responsibilities:
  - Create `@StateObject` instances: `CyclePhaseCache`, `SharkWeekMonitor`
  - Render 7-tab navigation: Dashboard, Workouts, Programs, Maxes, Analytics, Benchmarks, Settings
  - Display `SharkWeekBanner` overlay when `sharkWeekMonitor.isSharkWeek`

**Feature Views:**
- Examples: `DashboardView`, `WorkoutsListView`, `ActiveWorkoutView`, `BenchmarksListView`, `SettingsView`
- Pattern: Create feature-specific `@StateObject viewModel`, environment inject `AuthViewModel` and shared state (e.g., `CyclePhaseCache`)
- Lifecycle: `.task { await viewModel.loadData() }` on appear, `.refreshable { }` for pull-to-refresh, `.onReceive()` for notifications

## Error Handling

**Strategy:** Localized errors with recovery suggestions; resilient data decoding (skip corrupt records).

**Patterns:**

**Auth Errors** (`AuthError`):
- Cases: `cancelled`, `authorizationFailed`, `noPresentationContext`, `credentialStateCheckFailed`, `invalidIdentityToken`, `missingUserInfo`, `notAvailable`
- Displayed in: `AuthViewModel.errorMessage` (@Published) → Alert in UI
- Example: User cancels sign-in → `AuthError.cancelled` → "Sign in was cancelled" + "Try signing in again when ready"

**Data Errors** (`DataError`):
- Cases: `recordNotFound`, `networkError`, `permissionDenied`, `invalidData`, `schemaNotDeployed`
- Handling: ViewModels catch and set `@Published errorMessage` or `isLoading`
- Example: Offline operation → `DataError.networkError` → SyncQueue enqueues mutation → replays on connectivity

**Resilient Decode:**
- Both `CloudKitClient.fetchAll()` and `LocalDataClient.fetchAll()` skip individual records that fail to decode
- Logged as warnings; entire query does NOT fail
- Allows app to function even if one corrupted record exists

## Cross-Cutting Concerns

**Logging:**
- Framework: `os.log` with `Logger` (subsystem: "com.sundeefundee.app", categories per feature)
- Examples: `DashboardView` (category: "Dashboard"), `App.swift` (category: "AppStartup")
- Level: `.info()` for state changes, `.error()` for failures, `.debug()` for tracing

**Validation:**
- Domain functions validate inputs and return errors
- Views validate user input before passing to ViewModels
- Example: Workout weight must be > 0; UI prevents saving if invalid

**Authentication:**
- Gated by `authViewModel.isAuthenticated` check in App.swift
- CloudKit writes guarded: `if !authViewModel.isGuest`
- Session restored from Keychain on app launch

**Concurrency:**
- Swift 6 strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY: complete`)
- Data clients are `actor`-based for thread safety
- ViewModels marked `@MainActor` for UI updates
- All async operations use `async/await`

**State Management:**
- UI state: `@State` for local view state, `@StateObject` for per-view ViewModels
- App state: `@EnvironmentObject` for shared objects (`AuthViewModel`, `CyclePhaseCache`)
- Persistence: DataLayer (CloudKit or local) via `DataClientFactory.shared.client`

**Theme:**
- Centralized in `AppTheme` enum with color, spacing, typography tokens
- Colors: Cream background, Navy/white text, Gold/orange accents (WCAG AA/AAA compliant)
- Applied via `.artDecoBackground()` modifier on root WindowGroup

---

*Architecture analysis: 2026-04-15*
