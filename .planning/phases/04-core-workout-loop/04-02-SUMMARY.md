---
phase: 04-core-workout-loop
plan: 02
subsystem: domain
tags: [typescript, jest, tdd, pr-detection, workout-session, epley-formula]

# Dependency graph
requires:
  - phase: 02-domain-layer-port
    provides: estimated1RM and isPR functions from epley-formula.ts
provides:
  - checkForPR pure function detecting weight PRs and estimated 1RM PRs across tracked rep ranges
  - findClosestRepRange function mapping any rep count to nearest tracked range (1,3,5,8,10)
  - createSession, addExercise, removeExercise, addSet, removeSet, completeSet, reorderExercises reducers
  - ExerciseMax, PRCheckResult, TrackedRepRange types in pr-detection subdomain
  - LoggedSet, ActiveExercise, WorkoutSession types in workout-session subdomain
affects: [04-core-workout-loop, 05-ai-workout-generation, 06-maxes-and-history]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Pure reducer-style immutable domain functions (no mutation of input)
    - TDD red-green flow for domain logic
    - Barrel index.ts with istanbul ignore file for pure re-exports
    - Optional idGenerator pattern (crypto.randomUUID with fallback)

key-files:
  created:
    - SundeeFundeeRN/src/domain/pr-detection/check-pr.ts
    - SundeeFundeeRN/src/domain/pr-detection/index.ts
    - SundeeFundeeRN/src/domain/workout-session/session-actions.ts
    - SundeeFundeeRN/src/domain/workout-session/index.ts
    - SundeeFundeeRN/src/domain/__tests__/pr-detection.test.ts
    - SundeeFundeeRN/src/domain/__tests__/workout-session.test.ts
  modified: []

key-decisions:
  - "ExerciseMax in pr-detection subdomain is separate from ExerciseMax in ai-workout (different shape: repRange + estimated1RM vs name + weightLb)"
  - "checkForPR takes exerciseId string not exercise name — matches Swift domain pattern of ID-based lookups"
  - "completeSet records completedAt ISO string at call time (new Date()) — enables replay and audit of set completion order"
  - "reorderExercises filters out unknown ids (silent no-op) — avoids throwing on stale state from rapid UI reordering"

patterns-established:
  - "Domain subdomain barrel: /* istanbul ignore file */ + type-only re-exports to avoid coverage gaps"
  - "Session reducers: spread at each level (session, exercise array, set array) to guarantee immutability"
  - "findClosestRepRange: strict less-than comparison for tie-breaking (first/lower range wins)"

requirements-completed: [WORK-01, WORK-06, WORK-12, MAX-01, MAX-03]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 04 Plan 02: PR Detection and Workout Session Actions Summary

**checkForPR with Epley-based 1RM comparison across tracked rep ranges (1,3,5,8,10) and immutable workout session reducer functions (createSession/addExercise/removeExercise/addSet/removeSet/completeSet/reorderExercises)**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-15T00:23:25Z
- **Completed:** 2026-03-15T00:26:25Z
- **Tasks:** 2 (6 commits: 2 RED + 2 GREEN + 0 refactor)
- **Files modified:** 6 created, 0 modified

## Accomplishments

- PR detection compares weight at closest rep range and estimated 1RM (Epley) across all rep ranges for an exercise
- findClosestRepRange handles all edge cases: equidistant ties prefer lower range, sub-1 reps clamp to 1
- Session actions cover the full in-progress workout lifecycle: create → add exercises/sets → complete sets → reorder → remove
- All 48 tests pass (21 PR detection + 27 session actions), all immutability invariants verified

## Task Commits

Each task was committed atomically with RED→GREEN TDD flow:

1. **Task 1: PR Detection (RED)** - `d882182` (test)
2. **Task 1: PR Detection (GREEN)** - `e1d5d24` (feat)
3. **Task 2: Session Actions (RED)** - `1ed19e3` (test)
4. **Task 2: Session Actions (GREEN)** - `ce740c1` (feat)

_Note: TDD tasks have multiple commits (test → feat). No refactor commit needed — code was clean._

## Files Created/Modified

- `SundeeFundeeRN/src/domain/pr-detection/check-pr.ts` — checkForPR, findClosestRepRange, ExerciseMax/PRCheckResult/TrackedRepRange types
- `SundeeFundeeRN/src/domain/pr-detection/index.ts` — barrel re-export
- `SundeeFundeeRN/src/domain/workout-session/session-actions.ts` — all session reducers and LoggedSet/ActiveExercise/WorkoutSession types
- `SundeeFundeeRN/src/domain/workout-session/index.ts` — barrel re-export
- `SundeeFundeeRN/src/domain/__tests__/pr-detection.test.ts` — 21 tests for PR detection
- `SundeeFundeeRN/src/domain/__tests__/workout-session.test.ts` — 27 tests for session actions

## Decisions Made

- ExerciseMax in `pr-detection` subdomain differs from ExerciseMax in `ai-workout` — different shape (repRange + estimated1RM vs simple name + weightLb). Coexist independently.
- `checkForPR` takes `exerciseId` (string) not the exercise name — matches Swift domain pattern of ID-based lookups for correctness across exercise renames.
- `completeSet` records `completedAt` at call time via `new Date().toISOString()` — enables replay and audit of set completion order.
- `reorderExercises` silently filters unknown IDs rather than throwing — safe against stale state from rapid UI drag-and-drop reordering.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

All files verified present:
- SundeeFundeeRN/src/domain/pr-detection/check-pr.ts - FOUND
- SundeeFundeeRN/src/domain/pr-detection/pr-types.ts - FOUND
- SundeeFundeeRN/src/domain/pr-detection/index.ts - FOUND
- SundeeFundeeRN/src/domain/workout-session/session-actions.ts - FOUND
- SundeeFundeeRN/src/domain/workout-session/session-types.ts - FOUND
- SundeeFundeeRN/src/domain/workout-session/index.ts - FOUND

All commits verified:
- d882182 - FOUND (test: failing PR detection tests)
- e1d5d24 - FOUND (feat: PR detection implementation)
- 1ed19e3 - FOUND (test: failing session action tests)
- ce740c1 - FOUND (feat: session actions implementation)
- 34fdb41 - FOUND (fix: type extraction refactor)
- b95e11d - FOUND (docs: SUMMARY + STATE)

## Next Phase Readiness

- PR detection and session reducers are ready to be consumed by workout UI screens (Plan 04-05, 04-06)
- WorkoutSession type provides the data shape for the active workout screen
- ExerciseMax type is ready for the maxes repository (Plan 04-03) to persist and query
- Potential integration: domain index.ts barrel can be updated to re-export pr-detection and workout-session when needed downstream

---
*Phase: 04-core-workout-loop*
*Completed: 2026-03-15*
