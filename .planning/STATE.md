# Project State

## Project Reference
See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current focus:** Phase 14 in progress — plans 14-01 through 14-05 complete

## Current Position
**Milestone**: v2.0 Flutter Full Rewrite (in progress)
**Phase**: 14 of 14 (Release Hardening + Cutover Safety) — **In progress**
**Plan**: 5 of 6
**Status**: Plans 14-01, 14-02, 14-03, 14-04, 14-05 complete

```
v2.0 Progress: [█] [█] [█] [█] [█] [░]
              Ph9 Ph10 Ph11 Ph12 Ph13 Ph14

Phase 14 Plans: [█] [█] [█] [█] [█] [░]
                P1  P2  P3  P4  P5  P6
```

**Last activity**: 2026-02-21 — Plan 14-05 complete: GitHub Actions flutter-release.yml (web/Android AAB/iOS IPA jobs); Android build.gradle.kts release signing via GitHub Secrets; isMinifyEnabled=false for Drift compatibility.

## Performance Metrics
- **Velocity**: Baseline reset for v2.0 planning cycle
- **Blockers**: None
- **Next Decision**: Execute Phase 14

## Accumulated Context

- Rest timer background recalculation: `_pauseTimerForBackground` cancels Timer without changing status; `_recalculateRemainingTime` uses `DateTime.now().difference(startedAt)` on foreground return — accurate after any background duration
- Start Workout button on DashboardScreen (Key 'start-workout-button') navigates to `/workout/${activeCycle.programId}` — only visible when active cycle exists
- startCycleFromPrograms helper uses runtime guard before tapping start-cycle-button (idempotent across test re-runs)
- Vibration errors silently swallowed (web/simulator safe — `Vibration.vibrate` throws on non-mobile)
- Drift schema is at v4 with syncId TEXT UNIQUE nullable on CompletedWorkouts, CompletedSets, ActiveCycles, OneRepMaxes, PersonalRecords (Users excluded — auth.uid() handles identity)
- supabase_flutter initialized via `String.fromEnvironment` (compile-time `--dart-define`); skipped when env vars absent
- `supabaseClientProvider` returns `null` via try/catch when Supabase not initialized — use everywhere instead of `Supabase.instance.client` directly
- AuthNotifier contains zero sync logic — SyncNotifier handles `onAuthStateChange` stream independently
- syncId written to Drift BEFORE Supabase upsert call — ensures idempotent retries on failure
- SyncService push order: active_cycles → completed_workouts → completed_sets/PRs/1RMs (FK constraint order)
- Offline retry queue uses SharedPreferences JSON-encoded List<int> (survives app restart)
- SyncNotifier._trySetState() swallows StateError on disposed notifier (safe async gaps)
- syncProvider = NotifierProvider<SyncNotifier, SyncState> — consume via ref.read(syncProvider.notifier).syncAfterWorkout(id)
- signUp returns `true` when `response.user != null` (not session) — handles email confirmation flow gracefully
- `/auth` route added to GoRouter with no redirect guard changes — auth is optional

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
- Android release signing: Base64 keystore decoded at CI time from GitHub Secrets (env var → build dir); fallback to debug keys locally
- `isMinifyEnabled = false` in Android release buildType — Drift generated code incompatible with R8 minification
- iOS CI produces unsigned IPA via `--no-codesign`; signing is manual via Xcode/Transporter before App Store Connect
- Parity gate tests use platform-agnostic Key selectors only (no CupertinoButton/MaterialButton finders)
- all_tests.dart aggregator pattern: single flutter drive target, per-gate files remain independently runnable
- `fakeAsync` is NOT exported from `package:flutter_test` for plain `test()` calls — only available inside `testWidgets` binding; use real async with minimal maxAttempts for retry tests
- `extends Fake implements ConcreteClass` creates safe stubs in mocktail where constructor injection is needed but methods are never called
- Integration tests with `IntegrationTestWidgetsFlutterBinding` require a device/simulator; run `flutter test integration_test/... -d <device_id>`; use `xcrun simctl boot <uuid>` to start a simulator
- `SyncState.copyWith(errorMessage: null)` PRESERVES the old errorMessage value (uses `??`); to clear error, set state directly via `SyncState(..., errorMessage: null)` in the notifier
- `if (mounted)` pattern for async gaps in ConsumerState (not `if (context.mounted)`)
- Riverpod 3.x: use `NotifierProvider` (not `StateProvider` which is legacy-only); expose mutation via methods on Notifier (`.state` is `@protected`)
- Riverpod 3.x: `overrideWith(() => MyNotifier(initialState: value))` to inject pre-loaded async state before runApp
- ProgramV2 models use plain Dart fromJson (NOT freezed — avoids build_runner conflicts with Drift)
- Dual JSON schema: back-squat uses sessionsPerWeek/sessions[]; other 5 programs use daysPerWeek/days[] — both handled by same model via nullable fallbacks
- Dart 3 wildcard `(_, _)` pattern for unused error handler params (satisfies `unnecessary_underscores` lint)
- CycleRepository.startCycle() returns `null` (not exception) for duplicate active cycle — caller shows SnackBar
- FutureProvider + invalidate pattern for activeCycleProvider (simpler than streaming for infrequent cycle state changes)
- Drift cascade delete on CompletedSets FK requires explicit `PRAGMA foreign_keys = ON` in `NativeDatabase.memory()` test setup (production drift_flutter already enables FKs)
- Epley formula uses `reps.clamp(1, 10)` to cap rep input at 10 (matching v1.1 `Math.min(reps, 10)`)
- `EXERCISES` constant name kept uppercase (v1.1 parity); `// ignore: constant_identifier_names` added to document intent
- `detectPlateauForExercise` takes `AppDatabase` directly (not WorkoutRepository) for compound Drift query access
- `getDeloadWeight` lives in `plateau_detection.dart` (not `calculations.dart`) — only meaningful in plateau context
- PR detection runs BEFORE 1RM save in completeWorkout() — preserves pre-session baseline for accurate comparison
- `historicalMax <= 0` guard in checkAndSaveWeightPR prevents first-ever-lift from being flagged as PR
- `bestHistorical <= 0` guard in checkAndSaveVolumePR prevents first-session volume from being flagged as PR
- `completeWorkout()` returns `({int? workoutId, List<String> weightPRs, List<String> volumePRs})?` record type (backward-compatible)

### Roadmap Evolution
- Milestone v2.0 inserted after Phase 8 using integer continuation: new phases 9-14.
- Requirements mapped 22/22 with no orphans and no duplicate phase assignments.

### v1.1 Delivered Capabilities
- App-wide Sundee-Fundee rebrand (user-facing + project metadata)
- PWA manifest + icon pipeline + service worker + offline fallback page
- Android install prompt + iOS Add-to-Home-Screen guidance modal
- Lucide icon enrichment across dashboard, workout, and navigation

## Session Continuity
- **Last session**: 2026-02-21 — Completed 14-05-PLAN.md (flutter-release.yml: web/Android AAB/iOS IPA CI jobs; Android release signing via GitHub Secrets; isMinifyEnabled=false)
- **Stopped at**: Phase 14 Plan 05 complete
- **Resume with**: Execute Phase 14 remaining plan (14-06)
