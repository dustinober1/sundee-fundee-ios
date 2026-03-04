# Spicy Rating History Display — Design

## Context

Issue #51 requires "Historical ratings visible on workout history/dashboard." The core Spicy Rating feature (SpicyRatingView, perceivedEffort model field, V8 migration, WorkoutSummary integration) was completed in prior commits. This design covers the remaining history/dashboard visibility.

## Components

### 1. SpicyBadge — Inline flame on history cards

Small read-only badge showing a filled flame icon + effort label on each `WorkoutHistoryRow` in the dashboard. Only displayed when `perceivedEffort` is non-nil. Appears next to the duration text.

Layout: `[flame.fill] Hot · 42m` (orange flame, secondary text for label, existing duration)

### 2. EffortTrendsCard — Dashboard stats section

Card placed above the "Recent Workouts" section showing:
- Average effort across rated workouts (e.g., "3.7")
- Visual flame row showing average (filled flames proportional to average)
- Count of rated workouts (e.g., "7 of 10 rated")

Only shown when at least 1 workout has a rating. Uses existing card patterns (cardBackground, cream/navy/orange theme).

### 3. Static helpers for calculation

`DashboardView.averageEffort(from:)` — static method computing average perceivedEffort from an array of CompletedWorkout. Returns nil if none are rated. Testable without hosting the view.

## Files to modify

- `SundeeFundee/Features/Dashboard/DashboardView.swift` — Add EffortTrendsCard, modify WorkoutHistoryRow
- `SundeeFundeTests/` — Add test coverage for averageEffort calculation, SpicyBadge label, EffortTrendsCard display logic
