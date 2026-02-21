---
phase: 10
plan: "03"
subsystem: data-persistence
tags: [flutter, drift, riverpod, active-cycles, training-cycle, schema-migration]

dependency-graph:
  requires: ["10-01", "10-02"]
  provides: ["active-cycle-data-layer", "cycle-start-flow", "dashboard-cycle-display"]
  affects: ["10-04", "11-workout-logging"]

tech-stack:
  added: []
  patterns:
    - "Drift schema migration (onCreate + onUpgrade from v1 → v2)"
    - "Single active cycle enforcement in CycleRepository"
    - "ConsumerStatefulWidget for async-safe navigation after cycle start"
    - "FutureProvider<ActiveCycle?> invalidation to trigger dashboard refresh"

file-tracking:
  created:
    - flutter_app/lib/data/repositories/cycle_repository.dart
    - flutter_app/lib/shared/providers/cycle_provider.dart
  modified:
    - flutter_app/lib/data/database/app_database.dart
    - flutter_app/lib/data/database/app_database.g.dart
    - flutter_app/lib/features/programs/program_detail_screen.dart
    - flutter_app/lib/features/dashboard/dashboard_screen.dart

decisions:
  - id: D1
    choice: "Return null from startCycle() to signal duplicate active cycle"
    rationale: "Simple int? return type avoids exceptions for expected business logic; caller shows SnackBar"
  - id: D2
    choice: "FutureProvider (poll) over Stream for activeCycleProvider"
    rationale: "Cycle state changes infrequently (on explicit user action); invalidate pattern is simpler than streaming"
  - id: D3
    choice: "Dart 3 wildcard (_, _) in error handlers to satisfy unnecessary_underscores lint"
    rationale: "Dart 3.x allows repeated _ as wildcard parameter; cleaner than naming unused params"

metrics:
  duration: "~2 minutes"
  tasks-completed: 2
  completed: "2026-02-21"
---

# Phase 10 Plan 03: Active Cycles Data Layer + Start Cycle Flow Summary

**One-liner:** Drift ActiveCycles table (schema v2 migration) + CycleRepository + wired Start This Program button + dashboard active cycle card.

## What Was Built

### ActiveCycles Drift Table
Added `ActiveCycles` table to `app_database.dart` with 9 columns matching v1.1's ActiveCycle interface: `id`, `userId` (FK → Users), `programId`, `cycleName`, `startDate`, `currentWeek` (default 1), `currentSessionId` (nullable), `currentPhase` (nullable), `status` (default 'active').

Schema incremented from v1 → v2 with `MigrationStrategy`:
- `onCreate`: creates all tables fresh
- `onUpgrade` from < 2: creates only the `activeCycles` table (safe migration for existing installs)

Build runner regenerated `app_database.g.dart` with `ActiveCycle` data class, `ActiveCyclesCompanion`, and `$ActiveCyclesTable`.

### CycleRepository
`flutter_app/lib/data/repositories/cycle_repository.dart` provides:
- `startCycle()` — enforces single active cycle (returns `null` if one exists, inserted ID otherwise)
- `getActiveCycle()` — queries by userId + status='active'
- `updateProgress()` — updates week/session/phase
- `completeCycle()` — sets status to 'completed'

### Riverpod Providers
`cycle_provider.dart` exports:
- `cycleRepositoryProvider` — Provider<CycleRepository> backed by databaseProvider
- `activeCycleProvider` — FutureProvider<ActiveCycle?> watching userProvider, refreshed on invalidation

### ProgramDetailScreen (ConsumerStatefulWidget)
Converted from `ConsumerWidget` to `ConsumerStatefulWidget` to safely use `mounted` after async gap. The `_startCycle()` method:
1. Gets user from `userProvider.future` — shows SnackBar if null
2. Calls `cycleRepositoryProvider.startCycle()` — shows SnackBar if duplicate
3. On success: invalidates `activeCycleProvider`, navigates to `/dashboard` with `if (mounted)` guard

Start button replaced by "Currently Active" Chip when `activeCycle.programId == programId`.

### DashboardScreen (ConsumerWidget)
Converted from `StatelessWidget`. Now shows:
- Personalized greeting: "Welcome, {name}!" when user loaded, fallback to "Welcome to Sundee Fundee"
- Active cycle card (Key: `active-cycle-card`) with `cycleName`, `currentWeek`, and `status` Chip
- "No active programs — Browse programs to start training" card when no active cycle
- All preserved keys: `dashboard-screen`, `nav-programs`, `nav-progress`

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Duplicate cycle handling | Return `null` from `startCycle()` | Avoids exceptions for expected business logic; caller shows SnackBar |
| State management pattern | FutureProvider + invalidate | Cycle state changes infrequently; invalidate on start is simpler than streaming |
| Lint compliance | Dart 3 wildcard `(_, _)` | `unnecessary_underscores` lint satisfied; Dart 3.x allows repeated `_` as wildcard |

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` | ✅ Zero issues |
| `flutter build web` | ✅ Succeeded |
| `flutter test test/widget_test.dart` | ✅ Passed |
| Start cycle button wired | ✅ `_startCycle()` method with `cycleRepositoryProvider` |
| Active cycle card on dashboard | ✅ `activeCycleProvider` watched, card displayed |
| Required keys preserved | ✅ `dashboard-screen`, `nav-programs`, `nav-progress` |

## Commits

| Hash | Description |
|------|-------------|
| `32b000d` | feat(10-03): add ActiveCycles table, migration, repository, and providers |
| `5cd776d` | feat(10-03): wire Start Cycle button and active cycle dashboard card |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `unnecessary_underscores` lint violations**

- **Found during:** Task 2 flutter analyze
- **Issue:** `(_, __)` double-underscore in error handlers triggered `unnecessary_underscores` lint rule (exits 1)
- **Fix:** Changed all three occurrences to Dart 3 wildcard `(_, _)` pattern
- **Files modified:** `dashboard_screen.dart`, `program_detail_screen.dart`
- **Commit:** `5cd776d`

## Next Phase Readiness

**PROG-02 satisfied:** User can start a training cycle from program detail and see it tracked on the dashboard. Active cycle data persists across app restart via Drift DB.

**Ready for:**
- Plan 10-04 (if exists): Workout logging or additional cycle management
- Phase 11 (workout logging): `CycleRepository.updateProgress()` is ready for session tracking
