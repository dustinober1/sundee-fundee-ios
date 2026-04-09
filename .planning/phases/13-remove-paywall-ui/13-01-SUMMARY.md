---
phase: 13-remove-paywall-ui
plan: 01
subsystem: ui
tags: [swiftui, subscription, paywall, views, viewmodels]

# Dependency graph
requires:
  - phase: 12-unlock-features
    provides: FreeSubscriptionClient that always returns premium tier
provides:
  - All views stripped of subscription UI (upgrade prompts, lock icons, tier badges, subscription sheets)
  - All view models stripped of subscription-checking code (subscriptionClient, tier checks, access flags)
  - Features always enabled regardless of tier (coaching insights, cycle correlation, export, substitutions)
affects: [13-02]

# Tech tracking
tech-stack:
  added: []
  patterns: [unconditional feature access, no subscription gating in UI]

key-files:
  created: []
  modified:
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/CycleCorrelationChart.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Export/ExportView.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ExportViewModel.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/PainTrackingViewModel.swift

key-decisions:
  - "Removed subscriptionClient from all view model inits -- views no longer need subscription awareness"
  - "Coaching insights now show based solely on data availability, not tier"
  - "Deleted SubscriptionView, SubscriptionViewModel, TierBadge, and upgradeCard as complete units"

patterns-established:
  - "Feature access is unconditional: no tier checks in views or view models"

requirements-completed: [SUB-03, SUB-04]

# Metrics
duration: 12min
completed: 2026-04-09
---

# Phase 13 Plan 01: Remove Paywall UI Summary

**Stripped all subscription gating UI and subscription-checking code from 5 views and 3 view models**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-09T10:15:37Z
- **Completed:** 2026-04-09T10:27:38Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Removed all upgrade prompts, lock icons, tier badges, and subscription sheets from Dashboard, Analytics, CycleCorrelationChart, Settings, and Export views
- Deleted SubscriptionView, SubscriptionViewModel, and TierBadge structs entirely from SettingsView
- Removed subscriptionClient dependencies from AnalyticsViewModel, ExportViewModel, and PainTrackingViewModel
- All features now unconditionally enabled (coaching insights, cycle correlation, export, substitutions)

## Task Commits

Each task was committed atomically:

1. **Task 1: Strip subscription UI from views** - `8727806c` (feat)
2. **Task 2: Remove subscription-checking code from view models** - `098030a4` (feat)

## Files Created/Modified
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` - Removed upgrade prompts, locked feature cards, subscription sheet, subscriptionClient from view model, tier checks
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift` - Removed subscription state, removed hasAccess param from CycleCorrelationChart call
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/CycleCorrelationChart.swift` - Removed hasAccess param, upgrade card, lock icon, subscription sheet
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` - Removed Manage Subscription button, TierBadge, SubscriptionView, SubscriptionViewModel, Pro label, subscription sheet
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Export/ExportView.swift` - Removed subscription gating conditional, upgrade section, subscription sheet, checkSubscription task
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift` - Removed subscriptionClient, subscriptionTier, hasCycleAccess; always compute cycle data
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ExportViewModel.swift` - Removed subscriptionClient, currentTier, showingSubscription, canExport, checkSubscription()
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/PainTrackingViewModel.swift` - Removed subscriptionClient; always load substitution suggestions for active injuries

## Decisions Made
- Removed subscriptionClient from all view model inits -- views no longer need subscription awareness
- Coaching insights now show based solely on data availability (`insightsSummary != nil`), not tier
- Deleted SubscriptionView, SubscriptionViewModel, TierBadge, and upgradeCard as complete units rather than emptying them
- Kept `canGenerateAIWorkout` property in DashboardViewModel but always sets it to `true` in loadData()

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All subscription UI removed from views and view models
- Plan 13-02 can proceed to delete the Subscription/ directory and remaining subscription infrastructure files
- SubscriptionClientProtocol and FreeSubscriptionClient still exist (kept for CoachContextBuilder and other dependencies)

---
*Phase: 13-remove-paywall-ui*
*Completed: 2026-04-09*

## Self-Check: PASSED

All 9 files found. Both task commits (8727806c, 098030a4) found in git history.
