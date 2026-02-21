# Project State

## Project Reference
See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current focus:** Phase 10 in progress — Onboarding + Program/Cycle Parity (plans 1–3 of N complete)

## Current Position
**Milestone**: v2.0 Flutter Full Rewrite (in progress)
**Phase**: 10 of 14 (Onboarding + Program/Cycle Parity) — **In progress**
**Plan**: 3 completed
**Status**: 10-03 complete (PROG-02 satisfied)

```
v2.0 Progress: [█] [░] [ ] [ ] [ ] [ ]
              Ph9 Ph10 Ph11 Ph12 Ph13 Ph14

Phase 10 Plans: [█] [█] [█] ...
                P1  P2  P3
```

**Last activity**: 2026-02-21 — Completed 10-03-PLAN.md (active cycles data layer + start cycle flow)

## Performance Metrics
- **Velocity**: Baseline reset for v2.0 planning cycle
- **Blockers**: None
- **Next Decision**: Continue Phase 10 Plan 03 (Cycle/Training parity) — complete; continue Phase 10 Plan 04 if exists

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

### Roadmap Evolution
- Milestone v2.0 inserted after Phase 8 using integer continuation: new phases 9-14.
- Requirements mapped 22/22 with no orphans and no duplicate phase assignments.

### v1.1 Delivered Capabilities
- App-wide Sundee-Fundee rebrand (user-facing + project metadata)
- PWA manifest + icon pipeline + service worker + offline fallback page
- Android install prompt + iOS Add-to-Home-Screen guidance modal
- Lucide icon enrichment across dashboard, workout, and navigation

## Session Continuity
- **Last session**: 2026-02-21 — Completed 10-03-PLAN.md (active cycles + start cycle flow)
- **Stopped at**: Completed 10-03-PLAN.md
- **Resume file**: None
- **Resume with**: Continue Phase 10 Plan 04 (if exists) or Phase 11
