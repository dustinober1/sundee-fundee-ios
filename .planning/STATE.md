---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: "Completed 07-02-PLAN.md: data export module with 7 CSV formatters and cross-platform orchestrator"
last_updated: "2026-03-15T19:51:45.569Z"
last_activity: "2026-03-14 — Completed Plan 03-02: 5-step onboarding flow with Art Deco styling, atomic persistence, gender-adaptive step skipping, routing bug fixes"
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 33
  completed_plans: 31
  percent: 16
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Users get personalized, cycle-aware strength training that adapts to their body — available on any platform, online or offline.
**Current focus:** Phase 1 — Foundation and Infrastructure

## Current Position

Phase: 3 of 7 (Data Layer and Offline Architecture) — IN PROGRESS
Plan: 2 of 3 in current phase (Plans 01 and 02 done)
Status: Phase 3 Plan 02 complete
Last activity: 2026-03-14 — Completed Plan 03-02: 5-step onboarding flow with Art Deco styling, atomic persistence, gender-adaptive step skipping, routing bug fixes

Progress: [███░░░░░░░] 16%

## Performance Metrics

**Velocity:**
- Total plans completed: 1
- Average duration: 10 min
- Total execution time: 10 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation-and-infrastructure | 1 | 10 min | 10 min |

**Recent Trend:**
- Last 5 plans: 10 min
- Trend: establishing baseline

*Updated after each plan completion*
| Phase 01-foundation-and-infrastructure P01-01 | 10 | 3 tasks | 25 files |
| Phase 01-foundation-and-infrastructure P01-02 | 7 | 3 tasks | 19 files |
| Phase 01-foundation-and-infrastructure P01-03 | 60 | 3 tasks | 18 files |
| Phase 02-domain-layer-port P01 | 6 | 2 tasks | 12 files |
| Phase 02-domain-layer-port P02 | 9 | 2 tasks | 8 files |
| Phase 02-domain-layer-port P03 | 10 | 2 tasks | 10 files |
| Phase 02-domain-layer-port P02-04 | 13 | 2 tasks | 19 files |
| Phase 02-domain-layer-port P05 | 5 | 1 tasks | 2 files |
| Phase 03-data-layer-and-offline-architecture P03-01 | 7 | 2 tasks | 27 files |
| Phase 04-core-workout-loop P04-02 | 3 | 2 tasks | 6 files |
| Phase 04-core-workout-loop P01 | 5 | 2 tasks | 10 files |
| Phase 04-core-workout-loop P03 | 3 | 2 tasks | 10 files |
| Phase 04-core-workout-loop P04-04 | 7 | 2 tasks | 7 files |
| Phase 04-core-workout-loop P04-06 | 22 | 2 tasks | 10 files |
| Phase 04-core-workout-loop P04-05 | 8 | 2 tasks | 13 files |
| Phase 04-core-workout-loop P04-07 | 6 | 2 tasks | 10 files |
| Phase 04-core-workout-loop P04-08 | 12 | 1 tasks | 4 files |
| Phase 05-differentiating-features P05-02 | 15 | 1 tasks | 7 files |
| Phase 05-differentiating-features P05-01 | 7 | 2 tasks | 21 files |
| Phase 05-differentiating-features P05-04 | 12 | 2 tasks | 7 files |
| Phase 05-differentiating-features P05-03 | 12 | 2 tasks | 9 files |
| Phase 05-differentiating-features P05-07 | 5 | 2 tasks | 8 files |
| Phase 05-differentiating-features P05-05 | 20 | 2 tasks | 8 files |
| Phase 05-differentiating-features P06 | 6 | 2 tasks | 5 files |
| Phase 05-differentiating-features P05-08 | 15 | 2 tasks | 5 files |
| Phase 05-differentiating-features P09 | 35 | 3 tasks | 5 files |
| Phase 06-subscriptions-and-monetization P01 | 3 | 1 tasks | 11 files |
| Phase 06-subscriptions-and-monetization P02 | 8 | 2 tasks | 9 files |
| Phase 06-subscriptions-and-monetization P03 | 35 | 2 tasks | 11 files |
| Phase 07-polish-and-pre-launch P07-02 | 5 | 1 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: React Native Firebase (native SDK) required from day one — Expo Go cannot be used
- [Roadmap]: Firestore security rules on health data written in Phase 1 before any data is stored
- [Roadmap]: RevenueCat + Stripe webhook pipeline wired in Phase 1 before paywall UI built in Phase 6
- [Roadmap]: Domain layer ported and 100% tested in Phase 2 before any UI or repository work
- [Roadmap]: Repository factory pattern required — Firestore for auth users, AsyncStorage for guest
- [01-01]: Platform-specific file extensions (auth.native.ts / auth.web.ts) used — Metro resolver handles platform selection automatically, prevents cross-platform bundle errors
- [01-01]: react-native-purchases installed with --legacy-peer-deps due to React 19 peer support gap in RevenueCat SDK
- [01-01]: Jest setup.js pre-stubs Expo SDK 55 WinterCG globals — fixes "import outside test scope" error in jest-expo SDK 55
- [01-01]: Dynamic require() used in firestore.ts for platform branching — prevents native module from bundling on web
- [Phase 01-foundation-and-infrastructure]: Platform-specific file extensions (auth.native.ts/auth.web.ts) used — Metro resolver handles platform selection automatically, prevents @react-native-firebase/auth from bundling on web
- [Phase 01-foundation-and-infrastructure]: Jest setup.js pre-stubs Expo SDK 55 WinterCG globals to fix import-outside-scope errors during jest-expo setupFiles phase
- [Phase 01-foundation-and-infrastructure]: react-native-purchases installed with --legacy-peer-deps due to React 19 peer support gap in RevenueCat SDK v9
- [Phase 01-foundation-and-infrastructure]: SessionProvider accepts onUserSignIn callback not inline repo logic — keeps AuthContext pure, RootLayout handles data concerns
- [Phase 01-foundation-and-infrastructure]: expo-apple-authentication exports standalone functions (signInAsync) not object — named function imports required
- [01-03]: auth.native.ts renamed to auth.ts — TypeScript requires base file for .web.ts Metro override to resolve correctly
- [01-03]: sign-in.tsx needs explicit useEffect redirect — onAuthStateChanged context updates do not auto-trigger Expo Router navigation
- [01-03]: Alert.alert is a no-op on web — use window.confirm fallback for all confirmation dialogs in web-compatible screens
- [01-03]: All auth hooks must import from src/firebase/auth.ts platform wrapper — direct @react-native-firebase/auth imports cause web bundle failure
- [Phase 02-domain-layer-port]: Equidistant snap ties break toward first match (matching Swift min(by:) strict-less-than semantics)
- [Phase 02-domain-layer-port]: String unions used for all domain types instead of TypeScript enums — better serialization and narrowing
- [Phase 02-domain-layer-port]: Locale-dependent formatting omitted from weight-unit-conversion.ts — belongs in UI layer
- [Phase 02-domain-layer-port]: blendMultiplier formula clamp(1 + (target-1)*rs*cs, 0.75, 1.25) matches Swift CycleAdaptationPolicy exactly
- [Phase 02-domain-layer-port]: RN ProgramExercise.weight (ExerciseValue) replaces Swift percent1RM (Double) — adaptation scales absolute weights, not percentages
- [Phase 02-domain-layer-port]: adaptProgram always adapts regardless of adaptationEnabled flag — caller decides whether to invoke
- [Phase 02-domain-layer-port]: InjuryProfile gains optional location string field for Swift CloudKit parity — adaptation engine uses free-text location matching
- [Phase 02-domain-layer-port]: Barrel index.ts files marked with istanbul ignore file — pure re-exports produce no executable statements for Istanbul
- [Phase 02-domain-layer-port]: WorkoutFocus, EnergyLevel, EquipmentAccess, BenchmarkScoringType in types/index.ts updated to match Swift raw enum values
- [Phase 02-domain-layer-port]: ReadinessSurvey storage functions omitted from domain layer — saveTodayResult/loadTodayResult belong in Phase 3 repository layer
- [Phase 02-domain-layer-port]: Explicit named re-exports with adaptCycleProgram/adaptInjuryProgram aliases used in barrel — export * from both cycle and injury caused TypeError: Cannot redefine property: adaptProgram
- [Phase 03-data-layer-and-offline-architecture]: Settings merged into /users/{uid} to avoid extra Firestore read on startup
- [Phase 03-data-layer-and-offline-architecture]: ReadinessSurvey uses date string as Firestore doc ID for O(1) point lookups
- [Phase 03-data-layer-and-offline-architecture]: migrateGuestDataToFirestore: AsyncStorage only cleared after successful batch.commit() to preserve data on failure
- [Phase 03-data-layer-and-offline-architecture]: Web Firestore uses persistentLocalCache for IndexedDB offline persistence; instance cached to prevent double-init
- [03-02]: OnboardingContext saves all draft data atomically on final step — no partial persistence during multi-step wizard
- [03-02]: getNextStep() returns null as completion signal — screens call completeOnboarding() when null, not a named done route
- [03-02]: (app)/_layout.tsx reads hasCompletedOnboarding via getOnboardingProfileRepo (not LocalUserRepo) — same storage key as write path to prevent onboarding loop
- [03-02]: app/_layout.tsx no longer gates Stack render on onboardingComplete — blank-page bug when unauthenticated; all routing owned by (app)/_layout.tsx
- [Phase 04-core-workout-loop]: ExerciseMax in pr-detection subdomain is separate from ExerciseMax in ai-workout — different shape with repRange + estimated1RM vs simple name + weightLb
- [Phase 04-core-workout-loop]: checkForPR takes exerciseId string not exercise name — matches Swift domain pattern of ID-based lookups for correctness across exercise renames
- [Phase 04-core-workout-loop]: exercises.json bundled as static JSON (202 entries) — no network dependency for exercise catalog
- [Phase 04-core-workout-loop]: Timer functions accept optional 'now' parameter — enables deterministic unit tests without mocking Date.now
- [Phase 04-core-workout-loop]: forTime mode uses durationMs=0 sentinel — isTimerComplete always false for stopwatch mode
- [Phase 04-core-workout-loop]: ExerciseMaxRepo.saveMax skips write when new weight is not strictly higher — avoids regressing PR records on bad data entry
- [Phase 04-core-workout-loop]: FirestoreExerciseMaxRepo uses compositeId (exerciseId_repRange) as doc ID — ensures one document per max slot, efficient upserts
- [Phase 04-core-workout-loop]: WorkoutRecord.workout made optional for backward compatibility — existing AI records unchanged, custom records use exercises field
- [Phase 04-core-workout-loop]: CompletedWorkoutRecord defined in progress domain not WorkoutRepo — keeps domain layer independent of repository types
- [Phase 04-core-workout-loop]: Volume chart only counts completed sets (set.completed === true) — incomplete sets excluded from volume metrics
- [Phase 04-core-workout-loop]: Chart data points use string dates (YYYY-MM-DD) not Date objects — safer sorting and serialization
- [Phase 04-core-workout-loop]: expo-keep-awake activateKeepAwakeAsync called on timer-mode mount, deactivated on unmount — keeps screen awake during active timed workout
- [Phase 04-core-workout-loop]: EMOM schedules N individual notifications per minute (not repeating) — individual schedule per minute for reliability and per-minute cancellation on pause
- [Phase 04-core-workout-loop]: useFocusEffect + router.setParams used for exercise-picker result passing — Expo Router has no native modal result callback
- [Phase 04-core-workout-loop]: useRestTimer: 100ms tick interval for display; AppState listener re-syncs from timestamps on foreground
- [Phase 04-core-workout-loop]: workoutRecordToHistoryItem maps WorkoutRecord.source to HistoryItemSource at UI layer — keeps repository types decoupled from domain types
- [Phase 04-core-workout-loop]: AI workout detail uses AIExerciseSection — GeneratedExercise.sets is a number not array, requires separate rendering from CompletedExercise
- [Phase 04-core-workout-loop]: Volume chart shown only when 2+ data points — single point provides no trend information
- [Phase 04-core-workout-loop]: Dashboard uses useFocusEffect to refresh last-workout card so it updates after each session
- [Phase 04-core-workout-loop]: timerMode param passed as router push param to workout-session — keeps screen reusable for open and timed modes
- [Phase 04-core-workout-loop]: defaultRestDuration added to AppSettings interface (not a separate key) — keeps settings atomic
- [Phase 05-differentiating-features]: gemini-2.0-flash with responseMimeType: application/json used for Cloud Function — eliminates text parsing overhead and reduces retry frequency vs Anthropic format
- [Phase 05-differentiating-features]: minInstances: 1 set on generateWorkout Cloud Function — cold start mitigation for latency-sensitive AI workout generation (GEMINI_API_KEY secret required before deploy)
- [Phase 05-differentiating-features]: PeriodLogRecord and PainLogRecord wrap domain types with id (UUID) and ISO string dates for Firestore doc IDs and cross-platform date serialization
- [Phase 05-differentiating-features]: WODRepo factory takes no isGuest parameter — WODs are public read-only data, same Firestore impl for all users
- [Phase 05-differentiating-features]: FirestoreProgramDocument uses weeks[].sessions[] schema; firestoreProgramToProgram flattens to domain Program.sessions
- [Phase 05-differentiating-features]: programs.json bundled in src/resources/ — LocalProgramRepo serves programs offline with no network dependency
- [Phase 05-differentiating-features]: react-native-calendars markingType=period used for date range marking — best native support for multi-day period visualization
- [Phase 05-differentiating-features]: Two-tap period logging: pendingStart state pattern avoids modal — taps on calendar are natural and familiar to health app users
- [Phase 05-differentiating-features]: href: null conditional tab hiding based on cycleOptIn flag loaded from onboarding profile in layout useEffect
- [Phase 05-differentiating-features]: 4-slider readiness survey (sleep/energy/stress/soreness) satisfies READ-01 and CYCL-02 — no separate symptom logging feature needed
- [Phase 05-differentiating-features]: Step-based slider control instead of @react-native-community/slider — avoids new native dependency, fully testable
- [Phase 05-differentiating-features]: calculateReadinessScore energyLevel defaults to 5 for backward compatibility with existing 3-param callers
- [Phase 05-differentiating-features]: formatScore('reps', N) treats N>=10000 as encoded roundsAndReps, otherwise plain reps — single scorer handles both AMRAP and rep-only benchmarks
- [Phase 05-differentiating-features]: WOD Start expands exercise list inline (not workout-session) — WOD exercises are string[] plain text not structured data
- [Phase 05-differentiating-features]: BodyMap uses Pressable grid cells instead of react-native-svg (not installed) — plan explicitly offered this as fallback approach
- [Phase 05-differentiating-features]: recoveryPhaseLabel/recoveryPhaseColor defined in injuries/index.tsx and imported by [id].tsx — single source of truth
- [Phase 05-differentiating-features]: fixed ExerciseValue with value <= 1.0 treated as 1RM percentage — programs.json uses text weights today but future programs can encode percentages as fractions
- [Phase 05-differentiating-features]: getMissing1RMs excludes text and amrap weights — only fixed percentage ExerciseValues require a 1RM; Skip is first-class action in enrollment flow
- [Phase 05-differentiating-features]: Module-level shared state (getSharedWorkout/setSharedWorkout) passes GeneratedWorkout from config to preview — Expo Router params have serialization limits unsuitable for full workout objects
- [Phase 05-differentiating-features]: Cloud Function failure falls back to generateOfflineWorkout() with Alert notification — single offline code path for both no-network and function-error cases
- [Phase 05-differentiating-features]: AdaptationIndicator uses static formatDelta helper — returns 'down 10%' for 0.9, 'up 5%' for 1.05, '' for 1.0 — pure function for test coverage without React rendering
- [Phase 05-differentiating-features]: Adaptation context loads asynchronously via useFocusEffect — never blocks workout start, gracefully degrades when cycle/injury/readiness data is unavailable
- [Phase 05-differentiating-features]: Dashboard quick-access grid (Programs/Benchmarks/Injuries) provides navigation entry points alongside tab bar for full Phase 5 feature access
- [Phase 06-subscriptions-and-monetization]: stripeWebhook uses rawBody (not body) for Stripe signature verification — required by Stripe SDK constructEvent
- [Phase 06-subscriptions-and-monetization]: past_due included in ACTIVE_STATUSES for grace period — subscriptions not immediately revoked on failed payment
- [Phase 06-subscriptions-and-monetization]: RC entitlement uses lifetime duration for promotional grant — expiry managed via webhook revoke, not RC TTL
- [Phase 06-subscriptions-and-monetization]: useEntitlements accepts optional uid param — re-runs effect when uid changes for login/logout cycles
- [Phase 06-subscriptions-and-monetization]: Platform.OS test mocking: Object.defineProperty(Platform, 'OS', {value, configurable:true}) in beforeEach — jest.mock module path does not intercept imported Platform.OS
- [Phase 06-subscriptions-and-monetization]: jest.mock factory variables must be named with 'mock' prefix — babel hoisting safety rule blocks access to non-mock-prefixed variables
- [Phase 06-subscriptions-and-monetization]: jest.spyOn(Linking, 'openURL') used for Linking deep-link testing — mocking full react-native module breaks @testing-library/react-native FlatList
- [Phase 06-subscriptions-and-monetization]: TrialBanner uses null-return pattern — safe to render unconditionally in dashboard
- [Phase 06-subscriptions-and-monetization]: Programs catalog gates on enrollment (card tap) not browsing — catalog stays free per user decision
- [Phase 07-polish-and-pre-launch]: RepoBundle injected as parameter to collectAllUserData/exportUserData — testable without module-level singletons
- [Phase 07-polish-and-pre-launch]: Web export downloads individual CSV files — browser has no native zip API, react-native-zip-archive is mobile-only
- [Phase 07-polish-and-pre-launch]: Pain logs fetched per-injury via Promise.all on getPainLogs — no getAllPainLogs on InjuryRepository

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 4]: Background timer on Android (expo-task-manager foreground service) diverges from iOS — needs implementation spike before planning
- [Phase 5]: Firebase Cloud Functions v2 cold start mitigation for Gemini proxy — needs research before planning
- [Phase 6]: RevenueCat Web Billing paywall UI theming depth unclear — validate during Phase 6 planning
- [Phase 1]: Firebase App Check emulator bypass pattern needs confirmation before Phase 1 closes
- [Phase 1]: Firestore security rules must be deployed (`firebase deploy --only firestore:rules`) before Plan 02 writes any user data

## Session Continuity

Last session: 2026-03-15T19:51:45.566Z
Stopped at: Completed 07-02-PLAN.md: data export module with 7 CSV formatters and cross-platform orchestrator
Resume file: None
