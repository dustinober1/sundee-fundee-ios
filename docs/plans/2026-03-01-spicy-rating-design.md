# Spicy Rating (Post-Workout Difficulty) — Design

**Issue:** #51
**Date:** 2026-03-01

## Summary

After completing any workout (programmed or WOD), users can rate difficulty on a 1–5 pepper scale directly on the summary screen. Rating is optional and one-time (not editable after leaving summary).

## Data Layer

- Add `perceivedEffort: Int?` (1–5, nil = not rated) to `CompletedWorkout`
- Schema migration V7 → V8 (lightweight — new optional field)

## UI

- Shared `SpicyRatingView` component: 5 tappable pepper icons in HStack
- Selected: filled pepper in `accentOrange`; unselected: gray outline
- Tap to select, tap same to deselect
- Label below: "Mild" / "Warm" / "Medium" / "Hot" / "Inferno"
- Auto-saves on tap (no confirm button)
- Placed on `WorkoutSummaryView` between stats row and set breakdown
- Same component added to WOD completion flow

## Out of Scope

- History/analytics views for ratings
- Editability after leaving summary
- Aggregation or trends dashboard
