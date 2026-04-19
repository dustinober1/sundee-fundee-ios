# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.5.1] - 2026-04-19

### Fixed

- Guest data now migrates to CloudKit on Apple sign-in — guest
  workouts, challenges, injuries, 1RMs, benchmark results, enrolled
  programs, settings, and celebration events are copied across
  atomically (source only cleared on full success). Previously this
  data was orphaned on-device after sign-in.
- Friendlier error copy across Settings load/save, Insights,
  Substitution picker, and Challenges (replaces raw
  `localizedDescription`).
- Labeled loading spinners in Challenges, Insights, Analytics, and
  Pain Tracking (no more context-free spinners).
- Variable shadowing in `ProgramsListView.startSession` renamed.

### Improved

- Parallelized fetches in `BenchmarkDetailViewModel.loadBenchmark`,
  `BenchmarksListViewModel.loadData`, and
  `ProgramDetailViewModel.startSession` — ~700ms total latency
  removed across those screens.
- `MaxesListViewModel` caches `UserSettings` at VM lifetime scope
  instead of refetching on every `.refreshable`.
- `DashboardView.loadActiveChallenge` accepts optional cached
  workouts to avoid a second `fetchAll("Workout")` when the stats
  tier already fetched.
- `ShareCardRenderer.render(_:aspect:)` is now async; the 3×
  `ImageRenderer` work is dispatched via `Task.detached` to remove
  the save-time main-thread stall.
- Empty state for Benchmarks when a category filter has no matches.
- Haptics on set complete, PR detection, challenge tier and
  completion, and share save/copy (via new centralized
  `HapticFeedback` helper).
- Dynamic Type support for icon sizes across Dashboard, Insights,
  Settings, Workouts, Benchmarks, Maxes, Challenges, Pain Tracking,
  Analytics, Cycle, and onboarding views.
- Combined accessibility elements on Settings link rows with explicit
  "opens in browser" labels for VoiceOver.
- Art Deco theme consistency: `Color.red/.orange/.green` replaced
  with `AppTheme.Accent.orange` / `AppTheme.Recovery.green` tokens in
  `SharkWeekBanner`, `CycleCalendarView`, and `PainTrackingView`.

### Internal

- New `DiagnosticsService` tracks record decode failures across
  `CloudKitClient` and `LocalDataClient`. Surfaced via a new
  Diagnostics section in Settings (only visible when there's
  something to show).
- `SyncQueue` now moves mutations to `stuckMutations` after
  `maxRetryAttempts` is exceeded instead of silently dropping them.
  Persisted across app launches under a new UserDefaults key.
  (Currently dormant — will light up once SyncQueue is wired into
  `DataClientFactory` in production.)
- `GuestDataMigrator` + unit tests for atomic guest→CloudKit data
  migration (failure-atomic: source is only cleared on full success).
- Removed dead `MaxRow` struct in `MaxesListView`.
- `CelebrationEvent.challengeCompleted(challengeTitle:)` case added
  so completion haptics can distinguish full completion from tier
  milestones.

## [1.5] - 2026-04-19

### Added

- Share Card Library (`UI/Share/`): unified `ShareCardRenderer` with four variants
  — Completed Workout, New PR, Cycle Insight, and Selfie Overlay (PhotosPicker) —
  rendered at 9:16 (Story) and 1:1 (Square) aspects with branded footer.
- `ShareCardSheet`: live preview, segmented aspect picker, native `ShareLink`
  export. Used from `WorkoutDetailView`, the active workout PR flow, and the
  dashboard cycle phase banner.
- Post-PR share prompt: `ActiveWorkoutSessionViewModel.pendingPRShare` surfaces
  a share sheet immediately when a new 1RM is detected.
- Dashboard cycle phase banner now has a "Share insight" context-menu action.
- In-flow swap on active workouts: "Swap exercise" menu on the current exercise
  card opens `SubstitutionPickerSheet` (backed by `DeterministicCoachService`);
  mid-exercise swaps confirm before clearing logged sets.
- Plateau badge on `MaxesListView` rows with popover showing the recommendation.
- Session load heat bar on program session cards (Light / Moderate / Heavy by
  total set count).

### Changed

- Legacy `WorkoutShareCardView` removed; its layout was ported into
  `CompletedWorkoutShareView` with two aspect ratios.
- `WorkoutDetailView` share pipeline now routes through `ShareCardSheet`.
- `MARKETING_VERSION` bumped to 1.5, build 4.

### Notes

- Dashboard insight cards (surfacing CoachInsightsResponse plateaus/trends in
  place of the summary snippet) and the Reschedule Week flow are planned for a
  follow-up release; underlying `DeterministicCoachService` wiring is unchanged.

## [1.4] - 2026-04-19

### Added

- Home Screen and Lock Screen widgets for Cycle Phase and Recovery Score
- Siri / App Intents: `StartWorkoutIntent`, `LogWorkoutSetIntent`, `GetRecoveryScoreIntent`, `ExerciseCatalogEntity`
- Pain and Cycle promoted to top-level tabs (new `CycleTrackingView`)
- Exercise catalog dropdown (`ExerciseCatalogMenu`) wired into 1RM entry
- Recovery Score infrastructure (calculator, CloudKit `RecoveryScoreRecord`, dashboard card, trend chart) — card hidden on dashboard pending algorithm rework
- App Group (`group.com.sundeefundee.shared`) + `SharedSnapshotStore` for widget data sharing

### Fixed

- Sign in with Apple: proper token revocation in `deleteAccount` with re-authentication
- CloudKit `serverRecordChanged` now merges server state and retries
- Decode legacy `Workout` records as `CompletedWorkoutRecord`
- `EnrolledProgramRecord` and `UserSettings` handle Bool-as-Int64 from CloudKit
- Workout exercises default to empty array for old CloudKit records; challenge tiers default when missing
- Deduplicate lifetime challenges on load
- Swift 6 concurrency fixes: static `AppIntent` properties, `SharedSnapshotStore.defaults`
- Settings save race serialized with cancellable task
- Force-unwrap cleanup in `SettingsView` and `ActiveWorkoutSessionViewModel`
- Settings now shows dynamic version from bundle (was hardcoded)

### Changed

- `MARKETING_VERSION` bumped to 1.4, build 3
- Removed unused iCloud Key-Value Store entitlement

## [1.0.0] - 2026-04-08

### Changed

- **Major: Repository consolidated to iOS-only.** The web application (Next.js PWA), Cloud Functions (Firebase), and all supporting infrastructure have been retired and archived. The repository now contains only the native iOS app (SundeeFundeeKit + SundeeFundeeApp).

### Removed

- `web-app/` — Next.js 16 PWA (211 files)
- `firebase/` — Cloud Functions for AI workout generation (14 files)
- `backend/` — Cloudflare Workers + teenybase wrappers (3 files)
- `scripts/` — Python marketing screenshot generators (2 files)
- `docs/` — Screenshots, app store copy, documentation (51 files)
- `plans/` — Historical planning documents (28 files)
- `.agents/` — Agent skill configurations (29 files)
- 11 root-level config files (package.json, firebase.json, wrangler.toml, etc.)
- Web-specific .gitignore patterns (node_modules, .next, coverage, etc.)

### Added

- `MIGRATION.md` — Documents the platform transition with archive location
- `.gitignore` updated for iOS/Xcode patterns
- `CLAUDE.md` rewritten for iOS-only architecture
- `README.md` rewritten with iOS project overview and setup instructions
- `CHANGELOG.md` — This file

### Technical Details

- Archive of all removed code: `sundee-fundee-archive-2026-04-08.zip` (4.1 MB, 335 files)
- Zero iOS build dependencies were affected (confirmed via cross-reference scan)
- Xcode project builds successfully post-cleanup
- All 60 unit tests pass post-cleanup
