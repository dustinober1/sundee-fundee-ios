---
phase: 05-differentiating-features
plan: 03
subsystem: ui
tags: [readiness, survey, react-native, firestore, asyncstorage, date-fns, art-deco]

# Dependency graph
requires:
  - phase: 05-01
    provides: ReadinessRepo (FirestoreReadinessRepo + LocalReadinessRepo), ReadinessSurveyRecord type, calculateReadinessScore domain function

provides:
  - ReadinessSurveyCard: dismissable dashboard prompt card (Art Deco styled, all users)
  - ReadinessSurveyModal: 4-slider survey modal (sleep, energy, stress, soreness)
  - energyLevel field on ReadinessSurveyRecord (4th slider per locked decision)
  - calculateReadinessScore updated to 4 parameters with backward-compatible default
  - Dashboard integration: shows card when no survey today, badge after completion
  - CYCL-02 satisfied: readiness survey captures equivalent daily symptom data

affects:
  - 05-04 (AI workout generation uses todayReadiness for workout adaptation via READ-02)
  - 05-05 (cycle adaptation context references readiness tier)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Static helpers on components (cardHeadingText, formatReadinessBadge) extracted for testability
    - Step-based slider control (minus/plus buttons + visual track) — no @react-native-community/slider needed
    - useFocusEffect for readiness check on dashboard focus (consistent with last-workout load pattern)

key-files:
  created:
    - SundeeFundeeRN/src/components/readiness/ReadinessSurveyCard.tsx
    - SundeeFundeeRN/src/components/readiness/ReadinessSurveyModal.tsx
    - SundeeFundeeRN/src/components/readiness/__tests__/ReadinessSurveyCard.test.tsx
  modified:
    - SundeeFundeeRN/src/domain/readiness/readiness-survey.ts
    - SundeeFundeeRN/src/repositories/ReadinessRepo.ts
    - SundeeFundeeRN/src/repositories/__tests__/FirestoreReadinessRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/LocalReadinessRepo.test.ts
    - SundeeFundeeRN/src/domain/__tests__/ai-workout.test.ts
    - SundeeFundeeRN/app/(app)/(tabs)/index.tsx

key-decisions:
  - "4-slider readiness survey (sleep, energy, stress, soreness) satisfies both READ-01 and CYCL-02 per locked decision — no separate symptom logging feature needed"
  - "Step-based slider (minus/plus + track) instead of @react-native-community/slider — avoids adding a new native dependency, fully testable, consistent with existing project patterns"
  - "energyLevel field added to ReadinessSurveyRecord between stressLevel and result — no migration required (new field, all saves include it)"
  - "New scoring weights: SLEEP=0.3, STRESS=0.25, SORENESS=0.25, ENERGY=0.2 (total=1.0); energyLevel defaults to 5 for backward compatibility with 3-param callers"

patterns-established:
  - "Static helpers on views: cardHeadingText(), formatReadinessBadge() extracted as module-level functions for Jest testability without mounting"
  - "useFocusEffect for loading both workout history and readiness state on dashboard — consistent pattern for focus-triggered data refresh"

requirements-completed: [READ-01, READ-02, CYCL-02]

# Metrics
duration: 12min
completed: 2026-03-15
---

# Phase 05 Plan 03: Readiness Survey Summary

**4-slider daily readiness survey (sleep, energy, stress, soreness) with dismissable dashboard card, modal submit flow, and Firestore/AsyncStorage persistence satisfying READ-01, READ-02, and CYCL-02**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-15T13:59:27Z
- **Completed:** 2026-03-15T14:11:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Built ReadinessSurveyCard: dismissable Art Deco card prompting the daily check-in, available to all users
- Built ReadinessSurveyModal: 4-slider survey (sleep, energy, stress, body soreness) with auto-dismiss after result display
- Extended ReadinessSurveyRecord with energyLevel field and updated calculateReadinessScore to 4 params with backward-compatible default
- Integrated into dashboard: card shown when no survey today, readiness badge shown after completion
- All 178 repo and component tests pass; 165 domain tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend data model with energyLevel and build survey components** - `168098d` (feat)
2. **Task 2: Integrate readiness survey into dashboard** - `4b52a4b` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `SundeeFundeeRN/src/components/readiness/ReadinessSurveyCard.tsx` — Dismissable dashboard card with Art Deco styling, orange accent bar, onPress/onDismiss callbacks
- `SundeeFundeeRN/src/components/readiness/ReadinessSurveyModal.tsx` — 4-slider modal with step controls, submit/save flow, 2-second result display, auto-dismiss
- `SundeeFundeeRN/src/components/readiness/__tests__/ReadinessSurveyCard.test.tsx` — Static helper tests + render tests for heading, subtext, onPress, onDismiss
- `SundeeFundeeRN/src/domain/readiness/readiness-survey.ts` — Updated to 4-param calculateReadinessScore, new weights (0.3/0.25/0.25/0.2)
- `SundeeFundeeRN/src/repositories/ReadinessRepo.ts` — Added energyLevel field to ReadinessSurveyRecord
- `SundeeFundeeRN/src/repositories/__tests__/FirestoreReadinessRepo.test.ts` — Updated test fixture to include energyLevel
- `SundeeFundeeRN/src/repositories/__tests__/LocalReadinessRepo.test.ts` — Updated test fixtures to include energyLevel
- `SundeeFundeeRN/src/domain/__tests__/ai-workout.test.ts` — Updated score assertion from 7.7 to 7.15 (new weights)
- `SundeeFundeeRN/app/(app)/(tabs)/index.tsx` — Dashboard integration: readiness card, modal, badge, checkTodayReadiness on focus

## Decisions Made

- **Step-based slider instead of native slider package:** No `@react-native-community/slider` in project; implemented clean minus/plus button controls with visual track — avoids new native dependency and is fully testable.
- **energyLevel defaults to 5:** Allows existing 3-param callers (e.g., ai-workout.test.ts) to continue passing without modification.
- **Score assertion update in ai-workout.test.ts:** The weight change from (0.4/0.3/0.3) to (0.3/0.25/0.25/0.2) changes the 3-param score from 7.7 to 7.15. Updated test comment and assertion accordingly.

## Deviations from Plan

None - plan executed exactly as written. The step-based slider approach is a natural consequence of no slider package being installed (Rule 3 prevention — implementing without adding new dependency).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ReadinessSurveyRecord.energyLevel available to AI workout generation (CYAD-03 / 05-04)
- todayReadiness result available in dashboard state for workout context injection
- ReadinessRepo factory works for both guest (AsyncStorage) and authenticated (Firestore) users

---
*Phase: 05-differentiating-features*
*Completed: 2026-03-15*

## Self-Check: PASSED

- ReadinessSurveyCard.tsx: FOUND
- ReadinessSurveyModal.tsx: FOUND
- ReadinessSurveyCard.test.tsx: FOUND
- 05-03-SUMMARY.md: FOUND
- Commit 168098d (Task 1): FOUND
- Commit 4b52a4b (Task 2): FOUND
