# Project State

## Project Reference
See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current focus:** Phase 11 complete — all 3 plans done

## Current Position
**Milestone**: v2.0 Flutter Full Rewrite (in progress)
**Phase**: 11 of 14 (Workout Logging + Rest + Offline Continuity) — **COMPLETE**
**Plan**: 3 of 3
**Status**: All plans complete; Phase 11 fully executed

```
v2.0 Progress: [█] [█] [█] [ ] [ ] [ ]
              Ph9 Ph10 Ph11 Ph12 Ph13 Ph14

Phase 11 Plans: [█] [█] [█]
                P1  P2  P3
```

**Last activity**: 2026-02-21 — Phase 11 Plan 03 complete: RestTimerProvider with background recalculation, RestTimerSheet modal bottom sheet, rest timer integrated into WorkoutScreen.

## Performance Metrics
- **Velocity**: Baseline reset for v2.0 planning cycle
- **Blockers**: None
- **Next Decision**: Execute Phase 12 (next phase in roadmap)

## Accumulated Context

- Rest timer background recalculation: `_pauseTimerForBackground` cancels Timer without changing status; `_recalculateRemainingTime` uses `DateTime.now().difference(startedAt)` on foreground return — accurate after any background duration
- Vibration errors silently swallowed (web/simulator safe — `Vibration.vibrate` throws on non-mobile)

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
- **Last session**: 2026-02-21 — Completed 11-03-PLAN.md (RestTimerProvider + RestTimerSheet + WorkoutScreen integration)
- **Stopped at**: Phase 11 complete (all 3 plans done)
- **Resume with**: Execute Phase 12
