# Conditioning PR Tracking Design

**Date:** 2026-02-28
**Status:** Approved

## Problem

The app only detects strength PRs (via Epley 1RM estimation). Conditioning exercises like wallballs, runs, and rows complete without tracking personal records. As programs expand to include conditioning work, users lose visibility into their conditioning progress.

## Approach

Extend CompletedSet with optional conditioning fields + create a new ConditioningPR SwiftData model. Follows existing patterns (parallel to OneRepMax). Minimal disruption to working strength PR flow.

## Data Model

### New: ConditioningPR (@Model)
- `id: String`
- `userID: String`
- `exerciseID: String` — canonical exercise name
- `scoringTypeRaw: String` — "time" or "reps" (CloudKit-safe)
- `bestValue: Double` — seconds (time) or count (reps)
- `weightKg: Double?` — for weighted conditioning (e.g., 20lb wallball)
- `achievedAt: Date`
- `workoutID: String?`

### Extended: CompletedSet
- `actualTimeSeconds: Double?` — for time-based conditioning
- `scoringTypeRaw: String?` — nil = strength, "time" or "reps" for conditioning

### New: ConditioningScoringType enum
- `.time` — lower is better
- `.reps` — higher is better

### Schema Migration V7

## Exercise Identification

New `ConditioningExerciseCatalog` (parallel to `WeightliftingExerciseCatalog`) maps conditioning exercise names to their default scoring type.

## PR Detection

Extend `detectPRs()` in WorkoutSummaryView:
1. Existing strength PR detection (unchanged)
2. For remaining exercises, check ConditioningExerciseCatalog
3. Reps-based: actualReps > stored bestValue = PR
4. Time-based: actualTimeSeconds < stored bestValue = PR
5. Save ConditioningPR, fire didSaveNewPRs notification

## UI

- **MaxLiftsView:** Collapsible "Conditioning PRs" section below strength maxes
- **WorkoutExecutionView:** Time or reps-only input for conditioning exercises
- **WorkoutSummaryView:** Conditioning PRs in celebration display

## Repository

Extend LiftRepository protocol:
- `saveConditioningPR(_ pr: ConditioningPR)`
- `fetchConditioningPR(exercise: String) -> ConditioningPR?`
- `fetchAllConditioningPRs() -> [ConditioningPR]`

## Testing

100% line coverage maintained. Test waves:
- Domain: ConditioningScoringType, PR comparison logic
- ViewModel: detectPRs() conditioning path
- Repository: ConditioningPR CRUD
- View: Conditioning section in MaxLiftsView
