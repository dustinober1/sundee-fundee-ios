---
phase: 13
plan: 01
subsystem: sync-infrastructure
tags: [supabase, drift, flutter, riverpod, uuid, migration]

dependency-graph:
  requires: [12-05]
  provides: [drift-v4-schema, supabase-deps, conditional-supabase-init, nullable-supabase-provider]
  affects: [13-02, 13-03, 13-04, 13-05]

tech-stack:
  added: [supabase_flutter@2.12.0, uuid@4.5.3]
  patterns: [conditional-compile-time-env-init, nullable-provider-try-catch, drift-addColumn-migration]

key-files:
  created:
    - flutter_app/lib/shared/providers/supabase_provider.dart
  modified:
    - flutter_app/pubspec.yaml
    - flutter_app/pubspec.lock
    - flutter_app/lib/data/database/app_database.dart
    - flutter_app/lib/data/database/app_database.g.dart
    - flutter_app/lib/main.dart

decisions:
  - id: D1
    choice: syncId is nullable + unique (not non-null + unique)
    rationale: Existing rows have no syncId yet; populated lazily on first push. Nullable avoids breaking existing CompletedWorkoutsCompanion inserts in tests.
  - id: D2
    choice: String.fromEnvironment (compile-time) over Platform.environment (runtime)
    rationale: Runtime env vars not available on web/mobile; compile-time --dart-define works cross-platform
  - id: D3
    choice: try/catch in supabaseClientProvider (returns null)
    rationale: Clean null-safe pattern; callers check for null to skip sync without crashing

metrics:
  duration: 2m 2s
  completed: 2026-02-21
---

# Phase 13 Plan 01: Supabase Dependencies + Drift v4 Schema Summary

**One-liner:** Drift schema bumped to v4 with syncId UUID bridge columns on 5 sync tables; supabase_flutter added with conditional compile-time env-var initialization.

## What Was Built

Foundation infrastructure for optional cloud sync:

1. **Drift schema v4** — `syncId TEXT UNIQUE nullable` added to `CompletedWorkouts`, `CompletedSets`, `ActiveCycles`, `OneRepMaxes`, `PersonalRecords`. `Users` table intentionally excluded (auth.uid() handles user identity). Migration step added for `onUpgrade` from v3→v4.

2. **New packages** — `supabase_flutter: ^2.12.0` and `uuid: ^4.5.3` added to `pubspec.yaml` and resolved.

3. **supabase_provider.dart** — `supabaseClientProvider` (Riverpod `Provider<SupabaseClient?>`) wraps `Supabase.instance.client` in try/catch, returning `null` when Supabase was not initialized. All future sync code uses this provider instead of `Supabase.instance.client` directly.

4. **Conditional Supabase.initialize()** in `main.dart` — reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `String.fromEnvironment` (compile-time `--dart-define`). When either is empty (no env vars provided), initialization is skipped entirely — app boots offline-first exactly as before.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add Supabase+UUID deps, migrate Drift schema to v4 | f71817e | pubspec.yaml, app_database.dart, app_database.g.dart |
| 2 | Conditional Supabase init + nullable client provider | 01838d4 | main.dart, supabase_provider.dart |

## Verification Results

- `flutter pub get` — ✅ exit 0, supabase_flutter + uuid resolved
- `build_runner build --delete-conflicting-outputs` — ✅ exit 0, 100 outputs written
- `grep -c 'syncId' app_database.dart` — returns 10 (5 column defs + 5 migration addColumn refs)
- `schemaVersion => 4` — ✅ present
- `flutter analyze --no-fatal-infos` — ✅ No issues found
- `flutter test` — ✅ All 4 tests pass (syncId nullable; existing Companion inserts unaffected)

## Decisions Made

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | syncId nullable + unique | Existing rows have no UUID yet; populated lazily on first push to Supabase |
| D2 | `String.fromEnvironment` for env vars | Compile-time constants work on web/mobile; `Platform.environment` does not |
| D3 | `try/catch` returns null in provider | Clean null-safe pattern; callers check null to skip sync without crashing |

## Deviations from Plan

### Minor Verification Note
The plan's verify step specified `grep -c 'syncId' app_database.dart` returns 5. The actual count is 10 — 5 column definitions (one per table) plus 5 `addColumn` migration references. This is correct behavior; the plan underestimated migration references. No functional deviation.

## Next Phase Readiness

- **Unblocked by this plan:** 13-02 (sync repository layer), 13-03 (upsert logic), 13-04 (sync UI indicators), 13-05 (tests)
- **Required before 13-02:** Supabase project must exist with matching table schema (UUIDs as PKs in cloud, integer local PKs bridged by syncId)
- **No blockers identified**
