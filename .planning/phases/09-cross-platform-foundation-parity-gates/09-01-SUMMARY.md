---
phase: 09-cross-platform-foundation-parity-gates
plan: "01"
subsystem: flutter-scaffold
tags: [flutter, drift, riverpod, go_router, web, sqlite3, wasm]

dependency-graph:
  requires: []
  provides:
    - flutter_app/ Flutter project targeting web/android/ios
    - All Phase 9 dependencies resolved (drift, riverpod, go_router, connectivity_plus)
    - Drift web assets (sqlite3.wasm, drift_worker.js) in flutter_app/web/
  affects:
    - 09-02: Drift database schema and repository layer (requires flutter_app scaffold)
    - 09-03: Navigation + shell scaffold (requires go_router installed)
    - All subsequent Phase 9 plans

tech-stack:
  added:
    - flutter: "3.41.2 (stable)"
    - drift: "^2.31.0"
    - drift_flutter: "^0.2.8"
    - flutter_riverpod: "^3.2.1"
    - go_router: "^17.1.0"
    - connectivity_plus: "^7.0.0"
    - shared_preferences: "^2.5.4"
    - build_runner: "^2.11.1"
    - drift_dev: "^2.31.0"
    - mocktail: "^1.0.4"
    - sqlite3: "2.9.4 (transitive)"
  patterns:
    - Flutter monorepo co-location (flutter_app/ alongside Next.js src/)
    - Drift web WASM setup (sqlite3.wasm + drift_worker.js in web/)
    - SDK dev dependencies (integration_test, flutter_test) not from pub.dev

key-files:
  created:
    - flutter_app/pubspec.yaml
    - flutter_app/pubspec.lock
    - flutter_app/lib/main.dart
    - flutter_app/web/sqlite3.wasm
    - flutter_app/web/drift_worker.js
    - flutter_app/web/index.html
    - flutter_app/web/manifest.json
    - flutter_app/android/ (full Android scaffold)
    - flutter_app/ios/ (full iOS scaffold)
    - flutter_app/test/widget_test.dart
    - flutter_app/analysis_options.yaml
  modified:
    - .gitignore (Flutter build artifact entries appended)

decisions:
  - id: package-name-rename
    choice: "Package name changed from flutter_app to sundee_fundee"
    rationale: "Matches project brand; flutter create defaults to directory name"
  - id: integration-test-sdk
    choice: "integration_test: sdk: flutter (not pub.dev package)"
    rationale: "Dart 3 incompatible with old pub.dev integration_test ^1.0.2+3"
  - id: drift-worker-downloaded
    choice: "sqlite3.wasm and drift_worker.js downloaded from GitHub releases"
    rationale: "drift_flutter README requires these files in web/ for web DB support"
  - id: pubspec-lock-committed
    choice: "pubspec.lock committed (not gitignored)"
    rationale: "Application repo, not library — lockfile ensures reproducible builds"

metrics:
  duration: "3m 34s"
  tasks-completed: 2
  tasks-total: 2
  completed: "2026-02-20"
---

# Phase 9 Plan 01: Flutter Project Scaffold Summary

**One-liner:** Flutter 3.41.2 monorepo scaffold with drift/riverpod/go_router targeting web+android+ios, Drift WASM assets downloaded, web build verified.

## What Was Built

Created `flutter_app/` as a co-located Flutter project within the existing Next.js monorepo, targeting web, Android, and iOS. All production and development dependencies for Phase 9 were installed and verified. Drift web assets (`sqlite3.wasm` from sqlite3 v2.9.4 and `drift_worker.js` from drift v2.31.0) were downloaded to `flutter_app/web/`. The root `.gitignore` was extended with Flutter-specific build artifact exclusions. `flutter build web` completes successfully in ~18s.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Create Flutter project and install all dependencies | `21d706a` | flutter_app/pubspec.yaml, flutter_app/pubspec.lock, flutter_app/lib/main.dart, flutter_app/android/, flutter_app/ios/ |
| 2 | Download Drift web assets, update .gitignore, verify web build | `fcaeb5c` | flutter_app/web/sqlite3.wasm, flutter_app/web/drift_worker.js, .gitignore |

## Verification Results

| Check | Result |
|-------|--------|
| `flutter_app/pubspec.yaml` exists with all deps | ✅ PASS |
| `cd flutter_app && flutter pub get` exits 0 | ✅ PASS |
| `cd flutter_app && flutter build web` exits 0 | ✅ PASS (~18s) |
| `ls flutter_app/web/sqlite3.wasm` | ✅ PASS (714KB) |
| `ls flutter_app/web/drift_worker.js` | ✅ PASS (347KB) |
| `.gitignore` has Flutter entries | ✅ PASS |
| `flutter doctor` web platform available | ✅ PASS (Chrome) |

## Decisions Made

1. **Package name:** Changed from `flutter_app` to `sundee_fundee` in pubspec.yaml to match project brand
2. **integration_test as SDK dep:** Used `sdk: flutter` form, not the deprecated pub.dev package (which is Dart 3 incompatible)
3. **Drift web assets downloaded from GitHub releases:** sqlite3.wasm from `simolus3/sqlite3.dart@2.9.4` and drift_worker.js from `simolus3/drift@2.31.0`
4. **pubspec.lock committed:** Application repo convention for reproducible builds

## Deviations from Plan

None — plan executed exactly as written.

The plan's Step A fallback worked as intended: `flutter build web` succeeded immediately without requiring the WASM file for the default counter app scaffold. However, as the plan notes, `sqlite3.wasm` and `drift_worker.js` must be present for Drift to function on web — both were downloaded before the final verification build.

## Next Phase Readiness

**09-02 (Drift Database Schema):** Ready — `flutter_app/` exists with drift + drift_dev + build_runner installed.

**09-03 (Navigation + Shell):** Ready — go_router installed and resolving.

**Blockers:** None. Android SDK and Xcode are not installed on this machine (flutter doctor shows warnings), but web builds are fully functional and that is the primary parity gate target for Phase 9.
