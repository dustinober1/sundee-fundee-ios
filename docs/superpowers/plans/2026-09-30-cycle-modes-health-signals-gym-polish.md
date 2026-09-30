# Implementation Plan: Cycle Inclusivity Modes, Autonomous Morning Signals & Gym Flow Polish

**Target Release:** Sundee Fundee Next Release (v2.2)  
**Date:** September 30, 2026  
**Scope:** 3 Major Themes (Cycle Inclusivity Modes & 7-Day Forecast, Autonomous Morning Signals & HealthKit Background Delivery, Gym Flow Polish - Warmup Progression & Audio Rest Cues)  

---

## 1. High-Level Architecture & Principles

1. **Zero External Dependencies**: All features implemented exclusively with Swift Standard Library, SwiftUI, HealthKit, CloudKit, and AVFoundation.
2. **Swift 6 Strict Concurrency**: `@MainActor` view models, `actor` data clients, `Sendable` types throughout.
3. **AppTheme Tokens Only**: Strictly use `AppTheme.Accent.*`, `AppTheme.Semantic.*`, `AppTheme.Recovery.*`, `AppTheme.Typography.*`, and `AppTheme.Spacing.*`. Zero hardcoded colors.
4. **100% Free**: No paywalls, subscriptions, or feature locks.
5. **Continuous Quality Gate**: Single-file commits (`type(scope): description`) per file, no `git add .` or `-A`. Verify with `swift test` and `xcodebuild` at every step.

---

## 2. Phase Breakdown

### Phase 1: Theme 1 — Cycle Inclusivity Modes & 7-Day Forward Forecast
- **Goal**: Support standard natural cycles, hormonal contraceptives (monophasic), irregular/PCOS, and perimenopause. Prevent artificial phase labeling when inappropriate, and provide a 7-day forward-looking forecast strip on the Today tab.
- **Components**:
  1. `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleTrackingMode.swift`: Enum representing the 4 modes with display names, descriptions, and adaptation characteristics.
  2. `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleSettingsRecord.swift`: Add `cycleTrackingModeRaw: String?` with backward-compatible decode defaulting to `.standard`.
  3. `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleForecastService.swift`: Pure domain service generating 7-day forecasts (`[CycleDayForecast]`) combining phase boundaries, mode rules, and training guidance.
  4. `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/CyclePhaseCache.swift`: Update cache to observe and respect `CycleTrackingMode`.
  5. `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleForecastStripView.swift`: Art Deco 7-day forecast strip with expandable day details.
  6. `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleSettingsView.swift`: Mode picker with clinical descriptions and privacy notes.
  7. `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`: Integration of forecast strip and mode-aware cycle card.
  8. Tests: `CycleTrackingModeTests.swift` and `CycleForecastServiceTests.swift`.

### Phase 2: Theme 2 — Autonomous Morning Signals & HealthKit Background Delivery
- **Goal**: Automatically calculate and store morning readiness before the user opens the app via background delivery, plus opt-in deduplicated menstrual flow write-back to Apple Health.
- **Components**:
  1. `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/HealthClientProtocol.swift` & `HealthKitClient.swift`: Add `saveMenstrualFlow(...)` and background delivery observer setup.
  2. `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/HealthKit/HealthKitBackgroundDeliveryCoordinator.swift`: Observes overnight sleep and HRV changes, computes `DailyReadinessSnapshot`, and updates `SharedSnapshotStore`.
  3. Deduplication in `CyclePhaseCache.swift`: Prevents circular feedback loops when reading back menstrual samples logged by Sundee Fundee.
  4. `UserSettingsRecord`: Add `isMenstrualWriteBackEnabled: Bool?` and settings toggle in `SettingsView`.
  5. Tests: `HealthKitBackgroundDeliveryTests.swift` and `MenstrualWriteBackTests.swift`.

### Phase 3: Theme 3 — Gym Flow Polish (Warmup Progression & Audio Rest Cues)
- **Goal**: Automated barbell warmup ramp calculation with plate loading per warmup set, plus background rest countdown audio chimes with AVAudioSession ducking.
- **Components**:
  1. `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Exercise/WarmupProgressionService.swift`: Generates ramp sets (empty bar, 50%, 70%, 85%, working set) with plate loading per set.
  2. `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WarmupCalculatorSheet.swift`: Interactive warmup sheet showing sets, plates, and completion checkoffs.
  3. `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Audio/AudioRestChimeService.swift`: Synthesizes and plays a two-tone bell chime using `AVAudioSession` with `.duckOthers`.
  4. Integration in `ActiveWorkoutSessionViewModel.swift`: Triggers chime on rest timer completion if enabled.
  5. Integration in `ActiveWorkoutView.swift`: Add "Warmup Ramp" action button to barbell exercises.
  6. Tests: `WarmupProgressionServiceTests.swift`.

---

## 3. Verification & Safety Verification
- Lint check: `swiftlint --config .swiftlint.yml` (0 errors).
- Test check: `swift test --package-path SundeeFundee` (all existing + new tests passing).
- Build check: `xcodebuild -project SundeeFundeeApp/SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (** BUILD SUCCEEDED **).
- Build check: `xcodebuild -project SundeeFundeeApp/SundeeFundee.xcodeproj -scheme SundeeFundeeWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build` (** BUILD SUCCEEDED **).
- Commit format: `type(scope): description` for each individual file.
