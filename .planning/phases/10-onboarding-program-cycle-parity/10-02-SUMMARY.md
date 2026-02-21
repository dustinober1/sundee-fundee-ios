---
phase: "10"
plan: "02"
subsystem: programs-data-layer
tags: [flutter, riverpod, json-assets, program-catalog, data-models]
requires: ["10-01"]
provides: ["program-catalog-ui", "program-v2-models", "json-asset-loading"]
affects: ["10-03"]
tech-stack:
  added: []
  patterns: ["FutureProvider.family", "rootBundle asset loading", "in-memory repository cache"]
key-files:
  created:
    - flutter_app/lib/data/models/program_v2.dart
    - flutter_app/lib/data/repositories/program_repository.dart
    - flutter_app/lib/shared/providers/program_provider.dart
    - flutter_app/lib/features/programs/program_detail_screen.dart
    - flutter_app/assets/programs/back-squat-complete-cycle.json
    - flutter_app/assets/programs/bench-press-strength.json
    - flutter_app/assets/programs/box-jump-power.json
    - flutter_app/assets/programs/burpees-conditioning.json
    - flutter_app/assets/programs/deadlift-5x5.json
    - flutter_app/assets/programs/front-squat-volume.json
  modified:
    - flutter_app/lib/features/programs/programs_screen.dart
    - flutter_app/lib/router/router.dart
    - flutter_app/pubspec.yaml
decisions:
  - id: dual-json-schema
    choice: "Handle both sessions-based (back-squat) and days-based (5 other programs) JSON formats in a single model"
    rationale: "5 of 6 program JSON files use daysPerWeek/weeks[].days[] instead of sessionsPerWeek/weeks[].sessions[]. Single model with optional fields avoids data duplication."
    alternatives: ["separate model classes per format", "normalize JSON files at build time"]
metrics:
  duration: "3m"
  completed: "2026-02-21"
---

# Phase 10 Plan 02: Program Data Layer + Catalog UI Summary

**One-liner:** ProgramV2 models with dual-schema JSON parsing, rootBundle asset loading with in-memory caching, and catalog/detail screens consuming real program data via Riverpod FutureProvider.

## What Was Built

**Data Layer:**
- `ProgramV2`, `Phase`, `Session`, `ExerciseV2`, `WeekV2` model classes with `factory fromJson` constructors (no code generation — plain Dart)
- `ProgramRepository` loading 6 JSON assets via `rootBundle.loadString` with in-memory `Map<String, ProgramV2>` cache
- Three Riverpod providers: `programRepositoryProvider`, `programsProvider`, `programByIdProvider`

**UI:**
- `ProgramsScreen` rebuilt as `ConsumerWidget` showing 6 program cards with name, description (truncated 2 lines), difficulty chip (color-coded), and "N weeks · M sessions/week" metadata
- `ProgramDetailScreen` showing program name, difficulty, description, duration, frequency, training phases (when present) with name/goal/weekRange, and a disabled "Start This Program" button placeholder for Plan 03
- `/programs/:id` route added to router alongside existing routes

**Assets:**
- 6 JSON files copied from `src/data/programs/` → `flutter_app/assets/programs/`
- `pubspec.yaml` updated with `assets: - assets/programs/`

## Decisions Made

### Dual JSON Schema Support
The plan spec assumed all 6 programs matched back-squat's `sessionsPerWeek`/`sessions[]` structure. In reality, 5 of 6 programs use `daysPerWeek`/`days[]`. Model was designed to handle both:

- `ProgramV2.fromJson`: uses `json['sessionsPerWeek'] ?? json['daysPerWeek']`  
- `WeekV2.fromJson`: uses `json['sessions'] ?? json['days']`
- `Session.fromJson`: detects format by presence of `sessionId` key; falls back to `day` number format

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 5 of 6 JSON files use different schema than plan spec assumed**

- **Found during:** Task 1 — inspecting actual JSON file structures
- **Issue:** Plan spec specified `sessionsPerWeek`, `phases`, `weeks[].sessions[]` for all programs. Only `back-squat-complete-cycle.json` uses this format. The other 5 programs (`bench-press-strength`, `box-jump-power`, `burpees-conditioning`, `deadlift-5x5`, `front-squat-volume`) use `daysPerWeek`, no `phases` array, and `weeks[].days[]` with a simple `{day, exercises}` structure.
- **Fix:** Added dual-format parsing in `ProgramV2.fromJson`, `WeekV2.fromJson`, and `Session.fromJson`. All 6 programs now parse correctly without errors.
- **Files modified:** `flutter_app/lib/data/models/program_v2.dart`
- **Commits:** 73a3acf

## Verification Results

- ✅ `flutter analyze`: zero issues
- ✅ `flutter build web`: succeeds (28.1s)
- ✅ All 6 JSON files parse without type errors (verified via model review)
- ✅ `programs-screen` key preserved on Scaffold
- ✅ `program-detail-screen` key on detail Scaffold
- ✅ `start-cycle-button` key on disabled ElevatedButton (placeholder for Plan 03)
- ✅ `programsProvider` wired in ProgramsScreen via `ref.watch`
- ✅ `rootBundle.loadString('assets/programs/...')` in ProgramRepository

## Next Phase Readiness

Plan 03 can wire up the "Start This Program" button: the `start-cycle-button` key and `onPressed: null` placeholder are in place. `programByIdProvider` is available for detail-to-cycle navigation.
