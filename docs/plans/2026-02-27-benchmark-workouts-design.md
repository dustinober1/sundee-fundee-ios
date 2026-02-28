# Benchmark Workouts — Design Document
_Date: 2026-02-27_

## Summary

Replace the existing freeform `Benchmark` model with a catalog-driven system that supports predefined named benchmark workouts (CrossFit WODs, strength standards, endurance milestones) alongside user-created custom benchmarks. Results are logged per benchmark with scoring adapted to the workout type (time, reps, weight, or distance/time).

---

## Data Models

### `BenchmarkScoringType` (enum, Codable/RawRepresentable)

```
case time        // stored as seconds (Double); lower is better
case reps        // stored as Double (cast from Int); higher is better
case weight      // stored as kg (Double); higher is better
case distance    // fixed distance, logged as time in seconds; lower is better
```

### `BenchmarkDefinition` (SwiftData @Model)

| Field | Type | Notes |
|---|---|---|
| `id` | String | UUID |
| `userID` | String | Empty for predefined (global), user's ID for custom |
| `name` | String | e.g. "Fran", "1RM Deadlift", "1-Mile Run" |
| `category` | String | "CrossFit WOD", "Strength", "Endurance", "Gymnastics", "General" |
| `workoutDescription` | String | Description of movements/structure |
| `scoringType` | String | Raw value of BenchmarkScoringType |
| `isPredefined` | Bool | True = ships with app catalog |
| `sortOrder` | Int | Controls display order within category |

### `BenchmarkResult` (SwiftData @Model — replaces `Benchmark`)

| Field | Type | Notes |
|---|---|---|
| `id` | String | UUID |
| `userID` | String | |
| `definitionID` | String | FK → BenchmarkDefinition.id |
| `scoreValue` | Double | Seconds, kg, or reps depending on scoring type |
| `notes` | String | |
| `performedAt` | Date | |

---

## Schema Migration

- Introduce `AppSchemaV2` adding `BenchmarkDefinition` and `BenchmarkResult`, removing `Benchmark`
- Lightweight destructive migration for `Benchmark` (no data preservation — freeform benchmark history is not migrated)
- Add `MigrationStage` in `AppSchemaMigrationPlan`

---

## Predefined Benchmark Catalog (`BenchmarkCatalog.swift`)

Hardcoded Swift file (similar to `WeightliftingExerciseCatalog.swift`).

### CrossFit WOD — Time
- **Fran** — 21-15-9: Thrusters (95/65 lb) + Pull-ups
- **Helen** — 3 rounds: 400m Run + 21 KB Swings (53/35 lb) + 12 Pull-ups
- **Grace** — 30 Clean & Jerks (135/95 lb)
- **Karen** — 150 Wall Ball Shots (20/14 lb)
- **DT** — 5 rounds: 12 Deadlifts + 9 Hang Power Cleans + 6 Push Jerks (155/105 lb)
- **Murph** — 1-Mile Run + 100 Pull-ups + 200 Push-ups + 300 Squats + 1-Mile Run
- **Annie** — 50-40-30-20-10: Double-Unders + Sit-ups

### CrossFit WOD — Reps/Rounds
- **Cindy** — 20-min AMRAP: 5 Pull-ups + 10 Push-ups + 15 Air Squats
- **Fight Gone Bad** — 3 rounds of 5 stations (Wall Ball, SDHP, Box Jump, Push Press, Row) — total reps

### Strength — Weight (1RM)
- 1RM Back Squat
- 1RM Deadlift
- 1RM Bench Press
- 1RM Overhead Press
- 1RM Clean & Jerk
- 1RM Snatch

### Endurance — Time
- 1-Mile Run
- 5K Run
- 1.5-Mile Run (Cooper Test)
- 2K Row

### Gymnastics — Reps (max unbroken)
- Max Pull-ups
- Max Push-ups in 2 min
- Max Handstand Push-ups
- Max Muscle-ups

### General Fitness
- 100 Push-ups for Time (time)
- 100 Sit-ups for Time (time)
- L-Sit Hold (time)

---

## UI Design

### `BenchmarksView` (main screen)
- List grouped by category
- Each row: benchmark name, best result formatted for scoring type, date of best, result count
- Tap → `BenchmarkDetailView`
- "+" toolbar button → `AddCustomBenchmarkSheet`

### `BenchmarkDetailView`
- Header: name, category badge, workout description
- "Log Result" button → `LogBenchmarkResultSheet`
- History list: all results sorted by date, best result highlighted
- Swift Charts line chart: score over time (inverted y-axis for time/distance)

### `LogBenchmarkResultSheet`
Adapts input to scoring type:
- **time / distance** → minute + second pickers (MM:SS)
- **weight** → decimal text field (kg, with lb conversion if user preference set)
- **reps** → number stepper or text field
- Date picker (defaults to today)
- Notes field

### `AddCustomBenchmarkSheet`
- Name text field
- Category picker (CrossFit WOD / Strength / Endurance / Gymnastics / General)
- Scoring type picker
- Description text field (optional)

---

## Repository Layer

- `BenchmarkDefinitionRepository` protocol + `SwiftDataBenchmarkDefinitionRepository`
- `BenchmarkResultRepository` protocol + `SwiftDataBenchmarkResultRepository`
- Remove existing `BenchmarkRepository` / `SwiftDataBenchmarkRepository`

---

## View Model Layer

- `BenchmarksViewModel` — loads definitions (predefined + user-created), groups by category
- `BenchmarkDetailViewModel` — loads results for a given definition, computes best result, prepares chart data
