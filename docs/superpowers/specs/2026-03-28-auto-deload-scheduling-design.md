# Auto-Deload Scheduling Design

**Date:** 2026-03-28
**Status:** Approved
**Tier:** Plus ($4.99/mo)

## Purpose

A Dashboard card that appears when accumulated fatigue is detected, recommending the user take a deload week. Pure recommendation — no automatic program modifications.

## Detection Algorithm

### DeloadDetector (new Domain type, pure Swift)

**Inputs:**
- `[CompletedWorkout]` with associated `[CompletedSet]` data — last 4 weeks
- `Date?` of last deload dismissal (from UserDefaults)
- Current date (injectable for testing)

**Triggers when ALL conditions are met:**
1. **Effort threshold**: Average `perceivedEffort` over last 14 days ≥ 3.5
2. **Volume trend**: Total volume (actualReps × actualWeightKg) in last 14 days is ≥15% higher than the preceding 14 days
3. **Time guard**: At least 28 days since last dismissal (or no prior dismissal)
4. **Minimum data**: At least 4 rated workouts in the last 14 days

**Output:** `DeloadRecommendation?`
- `nil` = no recommendation
- When present: `averageEffort: Double`, `volumeIncreasePercent: Double`, `message: String`

### Volume Calculation

```
volume = sum of (actualReps × actualWeightKg) for all completed sets
```

Uses existing pattern from `WorkoutSummaryViewModel.totalVolumeKg`. Bodyweight-only sets (nil weight) contribute 0 to volume — this is intentional since deload detection targets weighted training load.

## Dashboard Card

Appears at the top of the Dashboard (above workout history) when `DeloadDetector` returns a recommendation. Gated behind `.autoDeload` feature entitlement.

**Content:**
- Title: "Time for a Deload?"
- Body: "Your effort has averaged {X}/5 and training volume is up {Y}% over the last 2 weeks. Consider reducing volume by 40-50% this week."
- Dismiss button: hides card, records dismissal date to UserDefaults
- Learn More button: brief explanation of deloading benefits

**Dismissal:** Persisted to UserDefaults keyed as `deloadDismissedAt`. Card won't reappear for 28 days after dismissal.

## Files

### New Files
- `SundeeFundee/Domain/DeloadDetector.swift` — Pure detection algorithm with `DeloadRecommendation` struct
- `SundeeFundee/Features/Dashboard/DeloadCardView.swift` — Dashboard card UI

### Modified Files
- `SundeeFundee/Features/Dashboard/DashboardView.swift` — Show DeloadCardView when recommendation exists
- `SundeeFundeTests/SubscriptionTests.swift` — DeloadDetector tests

## Testing

**DeloadDetector tests (pure domain):**
- Triggers when all 4 conditions met (effort ≥ 3.5, volume up ≥ 15%, 28+ days, 4+ workouts)
- Does NOT trigger when average effort is low (< 3.5)
- Does NOT trigger when volume is flat or decreasing
- Does NOT trigger when fewer than 4 rated workouts
- Does NOT trigger when dismissed within last 28 days
- Correctly calculates volume from CompletedSet data
- Returns correct averageEffort and volumeIncreasePercent in recommendation
- Edge case: zero volume in baseline period (no division by zero)

## Out of Scope

- Automatic program modification (future enhancement)
- Pain/injury signals as detection input
- Cycle phase awareness as detection input
- HealthKit integration (sleep, HRV, RHR)
- Customizable thresholds
