# ActiveWorkoutView Design Spec

**Date:** 2026-04-10
**Status:** Approved
**Scope:** Add a live workout tracking view that connects to the existing `ActiveWorkoutSessionViewModel`.

---

## Problem

Tapping "Start This Workout" from the AI workout preview saves the workout immediately as a completed record and dismisses back to the workout list. There is no active workout tracking screen. The `ActiveWorkoutSessionViewModel` has full session logic (timers, set tracking, rest, PRs, Live Activity) but nothing presents it.

## Solution

Create `ActiveWorkoutView` — a full-screen modal that guides the user through each set of their workout, one at a time. After the final set, show a completion summary with celebrations.

## Decisions

| Decision | Choice |
|---|---|
| Navigation style | Full-screen modal (covers everything, must finish or abandon) |
| Set flow | Single-set focus — guided, one set at a time |
| Rep/weight logging | Tap to accept prescribed values (expandable to edit) |
| Completion | Summary + celebration screen before dismiss |

## Screen 1 — Active Workout

Full-screen modal (`fullScreenCover`). Three zones stacked vertically:

### Header Bar
- Left: Close button (triggers abandon confirmation alert)
- Center: Workout name in `headlineMedium`
- Right: Elapsed time in orange, `monoLarge`

### Progress Bar
- Segmented bar — one segment per exercise
- Filled = all sets complete, half-filled = in progress, empty = remaining
- Below: "X of Y sets · Exercise N of M" in `labelSmall`, secondary text color

### Current Exercise Card (ArtDecoCard)
- Exercise name in `headlineLarge`
- "Set N of M" subtitle in `bodySmall`, secondary color
- Three inline stat boxes: Target Reps, Weight (lb), Rest duration
  - Values in `displaySmall`, labels in `labelSmall`
  - MVP: display-only, prescribed values accepted on Complete Set tap
  - Future: tappable to open inline stepper for adjusting before completing

### Rest Timer Card (conditional)
- Only visible when `viewModel.isResting == true`
- Dark navy background (`AppTheme.Background.navy`)
- "REST" label in gold, `labelMedium`, uppercase with letter spacing
- Countdown in `displayLarge`, cream color, monospaced (`monoLarge` or custom large mono)
- "Next: Set N of X reps" subtitle in gold
- "Skip Rest" button in gold secondary style

### Complete Set Button
- Full-width, `.accent` style (orange background)
- Disabled during rest
- Tapping calls `viewModel.completeSet(actualReps:completedWeight:)` with prescribed values
- If user edited reps/weight, uses the edited values

## Screen 2 — Workout Complete

Appears within the same modal after the last set completes. Replaces the active workout content:

- Trophy icon in gold
- "Workout Complete" in `displayLarge`
- Elapsed time in `headlineMedium`
- Stats row: total sets completed, exercises completed (using StatCard or similar)
- PR celebration cards (gold-highlighted ArtDecoCard) for each PR hit
- "Done" button (`.primary` style) that dismisses the modal

## Data Flow

```
AI Workout Preview
  → User taps "Start This Workout"
  → Create Workout from generated exercises
  → Create ActiveWorkoutSessionViewModel(workout:)
  → Present ActiveWorkoutView as fullScreenCover
  → On appear: viewModel.beginSession()
  → Per set:
      User taps Complete Set
      → viewModel.completeSet(actualReps, completedWeight)
      → Rest timer auto-starts from ViewModel
      → Progress updates via published properties
  → Last set:
      viewModel.completeSet triggers finishWorkout()
      → Show completion screen
  → User taps Done
      → Dismiss modal
      → Switch to Workouts tab
```

## Files to Create/Modify

### Create
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift` — Main active workout view

### Modify
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift` — Change `startGeneratedWorkout()` to present ActiveWorkoutView instead of saving immediately
- `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift` — May need state to present fullScreenCover from root

## Key Constraints

- **No new ViewModel** — reuse `ActiveWorkoutSessionViewModel` as-is
- **ViewModel handles persistence** — CloudKit save, PR detection, HealthKit, Live Activity
- **View just binds** — read published properties, call async methods
- **Art Deco theme** — AppTheme tokens, ArtDecoCard, ArtDecoButtonStyle
- **Swift 6 strict concurrency** — `@MainActor`, Sendable compliance
- **Abandon confirmation** — alert before closing mid-workout, calls `viewModel.abandonWorkout()`
