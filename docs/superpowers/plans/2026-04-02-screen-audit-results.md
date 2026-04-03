# Screen Audit Results -- 2026-04-02

## Build Verification

| Check | Result |
|-------|--------|
| `xcodegen generate` | Pass -- project regenerated |
| `xcodebuild build` (iPhone 17 Pro Sim, Debug, iOS 26.4) | **BUILD SUCCEEDED** |
| Code signing | Skipped (CODE_SIGNING_ALLOWED=NO) |
| Package resolution (SundeeFundeeKit) | Resolved successfully |

## Triage Legend

- **Ship** -- Screen is functional, ready for TestFlight testers.
- **Fix** -- Screen has a known issue that should be resolved before or shortly after first TestFlight build.
- **Hide** -- Screen should be hidden or gated until the backing feature is implemented.

## Screen Audit

| # | Screen | File(s) | Verdict | Notes |
|---|--------|---------|---------|-------|
| 1 | **Auth (Sign in with Apple)** | `UI/App/SundeeFundeeApp.swift` (AuthView) | Ship | Apple Sign-In flow via `AppleAuthClient`. Error display present. Keychain persistence for session restore. |
| 2 | **Onboarding** | `UI/Views/Onboarding/OnboardingView.swift` | Ship | 4-step flow (welcome, experience, goal, preferences). Saves to CloudKit, marks complete in Keychain. |
| 3 | **Dashboard** | `UI/Views/Dashboard/DashboardView.swift` | Ship | Cycle phase banner, stat cards, suggested workout, quick actions, recent wins. All sections data-driven with graceful fallbacks. |
| 4 | **Workouts List** | `UI/Views/Workouts/WorkoutsListView.swift` | Ship | CRUD complete: list, create, delete. Empty state present. NavigationLink to detail. |
| 5 | **New Workout** | `UI/Views/Workouts/WorkoutsListView.swift` (NewWorkoutView) | Ship | Manual workout builder with exercise picker, sets/reps/weight config. AI generation option. Validates before save. |
| 6 | **Workout Detail** | `UI/Views/Workouts/WorkoutDetailView.swift` | Ship | Full exercise/set display, toggle set completion, finish workout, volume calculation. |
| 7 | **Exercise Picker** | `UI/Views/Workouts/ExercisePickerView.swift` | Ship | Category filter, search, multi-select from domain catalog. |
| 8 | **AI Workout (Questionnaire)** | `UI/Views/Workouts/AIWorkoutView.swift` | Ship | Full flow: questionnaire -> generating -> preview -> start. Uses domain functions (`energyMultiplier`, `applyWeights`, `assignRestMinutes`). Generates locally -- no cloud AI call needed. |
| 9 | **Programs List** | `UI/Views/Programs/ProgramsListView.swift` | Fix | List renders, enroll works. **"Continue" button is a no-op** (line 92-94: empty action closure). No `ProgramDetailView` exists. Enroll/unenroll functional. |
| 10 | **Maxes List** | `UI/Views/Maxes/MaxesListView.swift` | Ship | List, add (sheet form), delete. Weight unit picker (lbs/kg). |
| 11 | **1RM Entry** | `UI/Views/Maxes/MaxesListView.swift` (OneRepMaxEntryView) | Ship | Exercise name text field, weight input, unit picker, save validation. |
| 12 | **Benchmarks List** | `UI/Views/Benchmarks/BenchmarksListView.swift` | Ship | Category picker, readiness indicators, best result display, intensity dots. NavigationLink to detail. |
| 13 | **Benchmark Detail** | `UI/Views/Benchmarks/BenchmarksListView.swift` (BenchmarkDetailView) | Ship | Readiness card, description, details, coach notes, previous results. Score entry sheet. |
| 14 | **Benchmark Score Entry** | `UI/Views/Benchmarks/BenchmarksListView.swift` (BenchmarkScoreEntryView) | Ship | Scoring-type-aware input (time mm:ss, rounds+reps, numeric). Parses correctly per `roundsAndReps` encoding convention. |
| 15 | **Cycle Calendar** | `UI/Views/Cycle/CycleCalendarView.swift` | Ship | Month grid with phase overlays, period dots, cycle day numbers. Phase legend. Current phase detail with training recommendations. Month navigation. |
| 16 | **Pain Tracking** | `UI/Views/Pain/PainTrackingView.swift` | Ship | Body region selector, intensity slider (1-10), pain type picker, notes, log history. Active injuries banner. |
| 17 | **Pain Log Form** | `UI/Views/Pain/PainTrackingView.swift` (PainLogFormView) | Ship | Multi-region selection, intensity slider, pain type grid, notes field. Disabled save until region selected. |
| 18 | **Settings** | `UI/Views/Settings/SettingsView.swift` | Ship | Profile display, subscription management, cycle tracking toggle, weight unit/experience/goal pickers, about section, sign out. |
| 19 | **Cycle Settings** | `UI/Views/Settings/SettingsView.swift` (CycleSettingsView) | Ship | Cycle length slider (21-35 days), last period date picker. Loads/saves to CloudKit. |
| 20 | **Subscription** | `UI/Views/Settings/SettingsView.swift` (SubscriptionView) | Ship | Current plan display, feature list, upgrade button. Uses `MockSubscriptionClient` (intentional -- RevenueCat not yet integrated). |
| 21 | **RevenueCatClient** | `Subscription/RevenueCatClient.swift` | N/A | Intentional stub. All methods return mock data. `MockSubscriptionClient` is the active implementation used by all ViewModels. No action needed for TestFlight. |
| 22 | **AuthViewModel** | `UI/ViewModels/AuthViewModel.swift` | Ship | Sign in with Apple, sign out, session restore from Keychain, onboarding gate. |

## Summary

| Verdict | Count | Screens |
|---------|-------|---------|
| Ship | 20 | Auth, Onboarding, Dashboard, Workouts List, New Workout, Workout Detail, Exercise Picker, AI Workout, Maxes List, 1RM Entry, Benchmarks List, Benchmark Detail, Score Entry, Cycle Calendar, Pain Tracking, Pain Log Form, Settings, Cycle Settings, Subscription, AuthViewModel |
| Fix | 1 | Programs List ("Continue" button is a no-op) |
| Hide | 0 | -- |

## Known Issues

### P1 -- Fix before TestFlight

1. **Programs "Continue" button does nothing** (`ProgramsListView.swift:92-94`)
   - The button has an empty action closure: `Button("Continue") { // Navigate to program detail }`
   - No `ProgramDetailView` exists in the codebase
   - **Recommended fix:** Either (a) create a minimal `ProgramDetailView` showing enrolled program workouts, or (b) hide the "Continue" button and only show "Enrolled" badge

### P2 -- Acceptable for TestFlight, fix later

2. **RevenueCat is a stub** -- `MockSubscriptionClient` is used everywhere. All users show as "Free" tier. This is fine for TestFlight since subscription billing should not be active during testing.

3. **CloudKit container not yet configured** -- The container ID `iCloud.com.sundeefundee.app` is referenced but may not be provisioned in the Apple Developer portal yet. Data operations will fail silently until CloudKit is set up. All views handle errors gracefully (print + continue).

4. **HealthKit permissions** -- Cycle phase features depend on HealthKit menstrual data. On first launch the user will need to grant permission. If denied, cycle features degrade gracefully (no phase shown).
