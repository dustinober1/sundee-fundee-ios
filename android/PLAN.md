# Sundee Fundee Android — Implementation Plan

## Context

Sundee Fundee is a cycle-aware strength training iOS app with 9 tabs, 20+ data models, and ~44 domain logic files. This plan ports the full feature set to a native Android app in Kotlin + Jetpack Compose. The Android code lives at `/android` in the same repo, using Supabase (replacing CloudKit), Google Health Connect (replacing HealthKit), and Google Sign-In (replacing Apple Sign-In).

## Architecture

```
android/
  settings.gradle.kts          # :app + :core modules
  app/                         # UI layer (Compose screens, ViewModels, DI, widgets)
  core/                        # Domain + Data layer (pure business logic, Room, Supabase client, auth)
```

**Layers:**
- **Domain** (`core/domain/`) — Pure Kotlin functions ported from iOS `DomainLayer/`. Zero framework deps.
- **Data** (`core/data/`) — Protocol-based persistence. `DataClient` interface → `SupabaseDataClient` (auth'd users) or `RoomDataClient` (guests). Offline sync queue. Health Connect integration.
- **UI** (`app/`) — Jetpack Compose screens, ViewModels, Art Deco Material 3 theme, navigation, widgets (Glance), foreground workout notification.

## Key iOS → Android Mappings

| iOS | Android |
|---|---|
| `DataClientProtocol` (actor) | `DataClient` interface (suspend functions) |
| `CloudKitClient` | `SupabaseDataClient` (Postgrest) |
| `LocalDataClient` (UserDefaults) | `RoomDataClient` (Room SQLite) |
| `DataClientFactory` | Hilt DI with auth-state switching |
| `HealthKitClient` | `HealthConnectClient` (Health Connect API) |
| `AppleAuthClient` | `GoogleAuthClient` (Google Sign-In) |
| `KeychainHelper` | `EncryptedSharedPreferences` |
| `SyncQueue` (actor) | `SyncQueue` wrapping DataClient + Room queue |
| `@Published` / `@StateObject` | `StateFlow` / `viewModel()` |
| `NotificationCenter` | `SharedFlow<AppEvent>` via Hilt singleton |
| SwiftUI Charts | Vico compose-m3 |
| ActivityKit Live Activity | Foreground notification service |
| WidgetKit widgets | Glance API widgets |
| `Codable + Sendable` | `data class` + `@Serializable` |

## Dependencies

- **Kotlin 2.1**, Jetpack Compose, Material 3, Compose Navigation
- **Room** (local DB + offline queue)
- **Supabase Kotlin SDK** (Postgrest + Auth + Realtime)
- **Google Sign-In** (play-services-auth)
- **Health Connect** (connect-client)
- **Hilt** (DI)
- **Vico** (charts — pure Compose, lightweight)
- **Glance** (widgets)
- **kotlinx.serialization** + **kotlinx-datetime**
- Zero other external dependencies

## Implementation Phases

### Phase 0: Project Scaffolding — DONE
- [x] Create `android/` directory with Gradle multi-module build
- [x] Configure Hilt, Compose, Room, Supabase dependencies
- [x] Application class, MainActivity, bottom navigation with 9 tab placeholders
- [x] Port Art Deco theme (colors, typography, shapes, component styles from `AppTheme.swift`)
- [x] Core interfaces: `DataClient`, `HealthClient`, `ContentClient`
- [x] DI modules, widget stubs, service stubs, AndroidManifest

### Phase 1: Domain Layer Port — DONE
- [x] Port all models (~15 data classes) from `Models/` and `UI/Models/SharedModels.swift`
- [x] Port all domain logic (27 Kotlin files across 14 subdirectories):
  - [x] Cycle: `CycleCalculations`, `CycleAdaptationPolicy` (phase boundaries, multipliers, blending)
  - [x] Exercise: `ExerciseCatalog` (58 weightlifting + 31 conditioning), `ExerciseValue` sealed class, `Calculators`
  - [x] Injury: `InjuryModels` (17 regions), `InjuryAdaptationEngine` (contraindication rules, regression table, load multipliers)
  - [x] Program: `ProgramTemplateGenerator` (7 templates with weekly progression + First Margarita)
  - [x] Benchmark: `BenchmarkCatalog` (30 benchmarks), `BenchmarkReadiness` (cycle-aware)
  - [x] Challenge: `ChallengeEngine` (volume tracking, tier progression, retroactive calc)
  - [x] Coach: `DeterministicCoachService`, `PreferenceLearner`, `CoachMemoryModels`
  - [x] Intelligence: `PlateauDetector`, `ScheduleReshuffler`, `SubstitutionRanker`, `WeeklyLoadAnalyzer`
  - [x] Recovery: `RecoveryScoreCalculator` (5 weighted inputs), all sub-scorers
  - [x] Analytics: `ChartDataAggregator`
  - [x] AI Workout: deterministic generation from exercise pools
  - [x] Celebration, Export
- [ ] Port all unit tests (35+ test files)
- **Verify:** domain logic compiles, tests pass on JVM

### Phase 2: Room Data Layer
- [ ] Define Room database with 13 entities and DAOs
- [ ] TypeConverters for complex types (List<ExerciseSet>, ExerciseValue, CyclePhase, etc.)
- [ ] Implement `RoomDataClient` (guest mode)
- [ ] Implement `BundledContentProvider`
- **Verify:** Room integration tests pass

### Phase 3: Auth + Session
- [ ] `GoogleAuthClient` via `ActivityResultContracts`
- [ ] `SessionManager` via `EncryptedSharedPreferences`
- [ ] `AuthViewModel` (signIn, guest, signOut, deleteAccount, session restore)
- [ ] `AuthScreen` + `OnboardingScreen` (4-step flow)
- **Verify:** sign in, guest mode, sign out, session restore work

### Phase 4: Supabase Data Layer
- [ ] Define Supabase table schema (20 tables, mirrors CloudKit record types)
- [ ] `SupabaseDataClient` implementing `DataClient`
- [ ] `SupabaseMapper` for record type ↔ table name mapping
- [ ] Wire Supabase Auth with Google Sign-In ID token
- [ ] `DataClientFactory` via Hilt (switches Supabase/Room based on auth state)
- **Verify:** CRUD operations against Supabase test project

### Phase 5: Offline Sync
- [ ] `NetworkMonitor` (ConnectivityManager)
- [ ] `SyncQueue` wrapping DataClient
- [ ] `SyncQueueStore` (Room table for pending mutations)
- [ ] `ConnectivityReceiver` for auto-flush
- **Verify:** offline mutations queue and replay on reconnect

### Phase 6: Health Connect
- [ ] `HealthConnectClient` implementing `HealthClient`
- [ ] Map Health Connect types: ExerciseSession, MenstruationFlow, HRV, Sleep, RestingHeartRate, ActiveCalories
- [ ] Permission request flow
- **Verify:** health data reads with Health Connect permissions granted

### Phase 7: ViewModels + Screens (largest phase)
- [ ] Dashboard (stat cards, phase banner, recovery score, coaching insights, challenges)
- [ ] Workouts (list, create, redo, detail, exercise picker, AI workout generation)
- [ ] Active Workout (set-by-set tracking, rest timer, PR detection via Epley, foreground notification)
- [ ] Programs (7 templates, enrollment, session-by-session tracking)
- [ ] Maxes (1RM CRUD, unit conversion)
- [ ] Pain (17-region selector, intensity slider, injuries, contraindicated exercises, smart substitutions)
- [ ] Cycle (calendar view, phase overlay, settings, period logging, Shark Week banner)
- [ ] Analytics (4 chart types with Vico, time range picker)
- [ ] Benchmarks (30 benchmarks, readiness, score entry)
- [ ] Challenges (lifetime/exercise/custom, tier progress)
- [ ] Settings (profile, units, data export, sign out, delete)
- [ ] Insights (coach insights, plateaus, trends)
- **Verify:** each screen works end-to-end with mock + real data

### Phase 8: Widgets + Notifications
- [ ] `SharedSnapshotStore` (SharedPreferences for widget data)
- [ ] Recovery Score widget (Glance)
- [ ] Cycle Phase widget (Glance)
- [ ] Workout foreground notification service
- [ ] `CyclePhaseCache` (shared across ViewModels)
- **Verify:** widgets update, notification shows during workout

### Phase 9: Sharing + Polish
- [ ] Workout share card (Compose → Bitmap → share Intent)
- [ ] Data export (JSON)
- [ ] Accessibility audit (TalkBack, content descriptions, font scaling)
- **Verify:** share flow, export file content

### Phase 10: Testing + Refinement
- [ ] ViewModel tests with MockDataClient
- [ ] UI tests for critical flows
- [ ] ProGuard/R8 config
- [ ] Performance profiling
- **Verify:** full test suite green, no crashes on real device

## iOS Source Files for Porting (Critical Reference)

### Domain Layer
- `SundeeFundeeKit/DomainLayer/Cycle/CycleCalculations.swift` — phase boundaries, cycle status, day math
- `SundeeFundeeKit/DomainLayer/Cycle/CycleAdaptationPolicy.swift` — phase multipliers, blending, readiness
- `SundeeFundeeKit/DomainLayer/Cycle/CycleCalendar.swift` — calendar overlay data
- `SundeeFundeeKit/DomainLayer/Exercise/ExerciseCatalog.swift` — 51 weightlifting + 31 conditioning entries
- `SundeeFundeeKit/DomainLayer/Exercise/ExerciseValue.swift` — discriminated union: fixed/amrap/range/text
- `SundeeFundeeKit/DomainLayer/Injury/BodyLocation.swift` — 17 body regions
- `SundeeFundeeKit/DomainLayer/Injury/InjuryAdaptationEngine.swift` — contraindication rules, regression table
- `SundeeFundeeKit/DomainLayer/Injury/InjuryModels.swift` — Injury, DailyPainLog, PainType, PainLevel
- `SundeeFundeeKit/DomainLayer/Injury/InjurySupport.swift` — clinical synonyms, load multipliers
- `SundeeFundeeKit/DomainLayer/Program/ProgramTemplateGenerator.swift` — 7 templates
- `SundeeFundeeKit/DomainLayer/Program/FirstMargaritaProgram.swift` — hand-crafted 8-week program
- `SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkCatalog.swift` — 30 predefined benchmarks
- `SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkModels.swift` — scoring types, readiness
- `SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkReadiness.swift` — cycle-aware readiness calc
- `SundeeFundeeKit/DomainLayer/Challenge/ChallengeEngine.swift` — volume tracking, tier progression
- `SundeeFundeeKit/DomainLayer/Challenge/ChallengeService.swift` — retroactive volume
- `SundeeFundeeKit/DomainLayer/Coach/DeterministicCoachService.swift` — workout generation from pools
- `SundeeFundeeKit/DomainLayer/Coach/PreferenceLearner.swift` — preference learning
- `SundeeFundeeKit/DomainLayer/Coach/CoachMemoryService.swift` — memory persistence
- `SundeeFundeeKit/DomainLayer/Coach/CoachMemoryModels.swift` — CoachProfile, WorkoutEdit, etc.
- `SundeeFundeeKit/DomainLayer/Coach/CoachContext.swift` — context builder
- `SundeeFundeeKit/DomainLayer/Coach/CoachServiceProtocol.swift` — coach interface
- `SundeeFundeeKit/DomainLayer/Coach/OnDeviceCoachService.swift` — iOS-enhanced (skip for Android)
- `SundeeFundeeKit/DomainLayer/Intelligence/PlateauDetector.swift` — exercise-aware plateau detection
- `SundeeFundeeKit/DomainLayer/Intelligence/ScheduleReshuffler.swift` — schedule reshuffling
- `SundeeFundeeKit/DomainLayer/Intelligence/SubstitutionRanker.swift` — Jaccard similarity ranking
- `SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` — 8 trend types
- `SundeeFundeeKit/DomainLayer/Analytics/ChartDataAggregator.swift` — chart aggregation
- `SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift` — 5 weighted inputs
- `SundeeFundeeKit/DomainLayer/Recovery/HRVBaselineNormalizer.swift` — phase-normalized HRV
- `SundeeFundeeKit/DomainLayer/Recovery/SleepDeduplicator.swift` — deduplicated sleep
- `SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift` — training load scorer
- `SundeeFundeeKit/DomainLayer/Recovery/CyclePhaseScorer.swift` — cycle phase scorer
- `SundeeFundeeKit/DomainLayer/Recovery/PainScorer.swift` — pain scorer
- `SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreInputs.swift` — input data classes
- `SundeeFundeeKit/DomainLayer/Recovery/RecoveryScore.swift` — result data classes
- `SundeeFundeeKit/DomainLayer/AIWorkout/AIWorkout.swift` — questionnaire + generation
- `SundeeFundeeKit/DomainLayer/Celebration/CelebrationEvent.swift` — 6 event types
- `SundeeFundeeKit/DomainLayer/Export/DataExportService.swift` — export logic
- `SundeeFundeeKit/DomainLayer/Export/ExportedData.swift` — export data structures

### Models
- `SundeeFundeeKit/Models/Workout.swift` — Workout, Exercise, ExerciseSet
- `SundeeFundeeKit/Models/Exercise.swift` — ExerciseCategory, ExerciseType
- `SundeeFundeeKit/Models/Challenge.swift` — Challenge, ChallengeTier, ChallengeType
- `SundeeFundeeKit/Models/RecoveryScoreRecord.swift` — persisted recovery scores
- `SundeeFundeeKit/UI/Models/SharedModels.swift` — OneRepMaxRecord, EnrolledProgramRecord, CelebrationEventRecord, etc.

### Data Layer
- `SundeeFundeeKit/DataLayer/Protocols/DataClientProtocol.swift` — core interface
- `SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift` — CloudKit mapping (reference for Supabase schema)
- `SundeeFundeeKit/DataLayer/Actors/LocalDataClient.swift` — local storage (reference for Room)
- `SundeeFundeeKit/DataLayer/DataClientFactory.swift` — factory pattern
- `SundeeFundeeKit/DataLayer/SyncQueue/SyncQueue.swift` — offline queue
- `SundeeFundeeKit/DataLayer/SyncQueue/NetworkMonitor.swift` — connectivity
- `SundeeFundeeKit/DataLayer/SyncQueue/PendingMutation.swift` — mutation model

### Auth
- `SundeeFundeeKit/Auth/AppleAuthClient.swift` — auth interface (reference for GoogleAuthClient)
- `SundeeFundeeKit/Auth/KeychainHelper.swift` — session storage (reference for EncryptedSharedPreferences)

### Theme
- `SundeeFundeeKit/UI/Theme/AppTheme.swift` — complete design system (already ported)

### UI (reference for Compose screens)
- `SundeeFundeeKit/UI/App/SundeeFundeeApp.swift` — tab structure
- `SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` — most complex ViewModel
- `SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` — auth state management
- `SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift` — chart data
- `SundeeFundeeKit/UI/ViewModels/PainTrackingViewModel.swift` — pain/injury CRUD
- `SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.kt` — recovery aggregation
- `SundeeFundeeKit/UI/ViewModels/ExportViewModel.swift` — data export

### Subscription
- `SundeeFundeeKit/Subscription/SubscriptionTier.swift` — tier definitions
- `SundeeFundeeKit/Subscription/FreeSubscriptionClient.swift` — free tier (currently all features unlocked)

## Supabase Table Schema (mirrors CloudKit record types)

| CloudKit Record Type | Supabase Table |
|---|---|
| "Workout" | "workouts" |
| "OneRepMaxRecord" | "one_rep_max_records" |
| "Challenge" | "challenges" |
| "Injury" | "injuries" |
| "DailyPainLog" | "daily_pain_logs" |
| "EnrolledProgram" | "enrolled_programs" |
| "ProgramSessionRecord" | "program_session_records" |
| "BenchmarkResult" | "benchmark_results" |
| "CycleSettings" | "cycle_settings" |
| "PeriodLogRecord" | "period_log_records" |
| "UserData" | "user_data" |
| "UserSettings" | "user_settings" |
| "CyclePhaseInfo" | "cycle_phase_info" |
| "CelebrationEventRecord" | "celebration_events" |
| "RecoveryScoreRecord" | "recovery_score_records" |
| "CompletedWorkoutRecord" | "completed_workout_records" |
| "CoachProfile" | "coach_profiles" |
| "WorkoutEdit" | "workout_edits" |
| "AcceptedSubstitution" | "accepted_substitutions" |
| "CoachWeeklySummary" | "coach_weekly_summaries" |

## Verification Steps

1. **Build:** `cd android && ./gradlew assembleDebug` succeeds
2. **Unit tests:** `./gradlew :core:test` — all 35+ domain tests pass
3. **Integration:** `./gradlew :app:connectedAndroidTest` — Room and ViewModel tests pass
4. **Manual:** Run on emulator, sign in as guest, complete onboarding, navigate all 9 tabs, create/complete a workout, verify dashboard updates
5. **Parity check:** Compare each Android screen side-by-side with iOS to verify feature completeness and visual consistency
