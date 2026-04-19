# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
