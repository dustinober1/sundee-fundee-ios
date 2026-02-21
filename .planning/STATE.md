# Project State

## Project Reference
See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current focus:** Phase 11 in progress; Plan 01 complete

## Current Position
**Milestone**: v2.0 Flutter Full Rewrite (in progress)
**Phase**: 11 of 14 (Workout Logging + Rest + Offline Continuity) — **IN PROGRESS**
**Plan**: 1 of 3
**Status**: Plan 01 complete; Plans 02–03 pending

```
v2.0 Progress: [█] [█] [░] [ ] [ ] [ ]
              Ph9 Ph10 Ph11 Ph12 Ph13 Ph14

Phase 11 Plans: [█] [░] [░] ...
                P1  P2  P3
```

**Last activity**: 2026-02-21 — Phase 11 Plan 01 complete: Drift schema v3 (4 new workout tables), SetData model, WorkoutRepository with transactional saveWorkout(), workoutRepositoryProvider, 3 passing unit tests.

## Performance Metrics
- **Velocity**: Baseline reset for v2.0 planning cycle
- **Blockers**: None
- **Next Decision**: Execute Phase 11 Plan 02 (WorkoutSessionProvider)

## Accumulated Context

### Key Decisions (carried forward)
- Local-first architecture with Dexie as source of truth (v1.1 baseline behavior)
- Optional Supabase sync with offline queue and explicit status indicators
- `super('StrengthApp')` in Dexie remains permanently frozen
- `@serwist/turbopack` used for service worker under Next.js 16
- Supabase routes in SW are `NetworkOnly` to avoid stale auth/data
- Playwright uses `serviceWorkers: 'block'` for deterministic E2E runs
- Flutter package name: `sundee_fundee` (not flutter_app default)
- integration_test uses `sdk: flutter` form (not deprecated pub.dev package)
- pubspec.lock committed in flutter_app/ (application repo convention)
- Drift web assets (sqlite3.wasm, drift_worker.js) committed to flutter_app/web/
- Radio<String> deprecated in Flutter 3.32+; use Icon-based selection instead
- FakeConnectivityPlatform must extend ConnectivityPlatform with MockPlatformInterfaceMixin (token check)
- Parity gate tests use platform-agnostic Key selectors only (no CupertinoButton/MaterialButton finders)
- all_tests.dart aggregator pattern: single flutter drive target, per-gate files remain independently runnable
- `if (mounted)` pattern for async gaps in ConsumerState (not `if (context.mounted)`)
- Riverpod 3.x: use `NotifierProvider` (not `StateProvider` which is legacy-only); expose mutation via methods on Notifier (`.state` is `@protected`)
- Riverpod 3.x: `overrideWith(() => MyNotifier(initialState: value))` to inject pre-loaded async state before runApp
- ProgramV2 models use plain Dart fromJson (NOT freezed — avoids build_runner conflicts with Drift)
- Dual JSON schema: back-squat uses sessionsPerWeek/sessions[]; other 5 programs use daysPerWeek/days[] — both handled by same model via nullable fallbacks
- Dart 3 wildcard `(_, _)` pattern for unused error handler params (satisfies `unnecessary_underscores` lint)
- CycleRepository.startCycle() returns `null` (not exception) for duplicate active cycle — caller shows SnackBar
- FutureProvider + invalidate pattern for activeCycleProvider (simpler than streaming for infrequent cycle state changes)
- Drift cascade delete on CompletedSets FK requires explicit `PRAGMA foreign_keys = ON` in `NativeDatabase.memory()` test setup (production drift_flutter already enables FKs)

### Roadmap Evolution
- Milestone v2.0 inserted after Phase 8 using integer continuation: new phases 9-14.
- Requirements mapped 22/22 with no orphans and no duplicate phase assignments.

### v1.1 Delivered Capabilities
- App-wide Sundee-Fundee rebrand (user-facing + project metadata)
- PWA manifest + icon pipeline + service worker + offline fallback page
- Android install prompt + iOS Add-to-Home-Screen guidance modal
- Lucide icon enrichment across dashboard, workout, and navigation

## Session Continuity
- **Last session**: 2026-02-21 — Completed 11-01-PLAN.md (Drift schema v3 + WorkoutRepository)
- **Stopped at**: Phase 11 Plan 01 complete; Plan 02 is next
- **Resume with**: Execute `.planning/phases/11-workout-logging-rest-offline-continuity/11-02-PLAN.md`
