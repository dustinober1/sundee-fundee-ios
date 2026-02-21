---
phase: 14
plan: "01"
name: calculations-parity-gate
subsystem: testing
tags: [parity-gate, flutter, calculations, unit-test, PLAT-02]

dependency-graph:
  requires: []
  provides:
    - calculations parity gate test (PLAT-02 satisfied)
  affects:
    - Phase 14 plans 02+ (establishes parity gate pattern for remaining gates)

tech-stack:
  added: []
  patterns:
    - parity-gate unit tests with closeTo() float matchers
    - grouped tests mirroring v1.1 function structure

file-tracking:
  key-files:
    created:
      - flutter_app/test/parity_gates/calculations_parity_test.dart
    modified: []

decisions:
  - id: D1
    choice: "29 assertions including extra detectPlateau tail-window cases"
    rationale: "Plan specified 8 function groups; additional plateau cases strengthen parity confidence at no cost"
    alternatives: ["Exactly match plan's specified case count"]

metrics:
  duration: "1m 3s"
  completed: "2026-02-21"
---

# Phase 14 Plan 01: Calculations Parity Gate Summary

**One-liner:** Unit parity gate verifying Flutter `calculations.dart` is a correct port of v1.1 `calculations.ts` — 29 assertions across 8 functions using `closeTo(expected, 0.01)` float matchers.

## What Was Built

Created `flutter_app/test/parity_gates/calculations_parity_test.dart` — a permanent parity gate satisfying PLAT-02. The test file validates every exported function in `calculations.dart` against known v1.1 expected values derived directly from the TypeScript baseline.

### Test Coverage (29 assertions across 8 groups)

| Group | Function | Cases | Key Parity Assertions |
|---|---|---|---|
| 1 | `roundToNearestFive` | 5 | round-down, round-up, half-up, boundary, sub-5 |
| 2 | `epley` | 5 | reps=1 identity, reps=5/10 formula, reps>10 cap, mid-range |
| 3 | `getNextRecommendedWeight` | 4 | first/success/failure + floor clamp |
| 4 | `wasSetSuccessful` | 4 | null prescribedWeight, reps not met, weight met/not met |
| 5 | `wasSessionSuccessful` | 3 | empty (vacuous true), all pass, one fail |
| 6 | `isPersonalRecord` | 3 | strictly greater, equal (false), less than |
| 7 | `detectPlateau` | 5 | <3 weights, variance <5, variance ≥5, tail-only window ×2 |

## Decisions Made

| Decision | Choice | Rationale |
|---|---|---|
| Extra plateau cases | Added 2 tail-window cases beyond plan minimum | Validates the `sublist(length-3)` logic explicitly; zero cost |

## Verification Results

```
flutter test test/parity_gates/calculations_parity_test.dart
→ 00:01 +29: All tests passed!

flutter analyze test/parity_gates/calculations_parity_test.dart
→ No issues found!
```

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Additional Work

**Extra test cases for detectPlateau (Rule 2 — Missing Critical)**
- **Found during:** Task 1 implementation
- **Issue:** Plan specified 3 detectPlateau cases; the `sublist(length-3)` tail-window logic was not explicitly covered
- **Fix:** Added 2 additional cases (plateau in tail, progress in tail) verifying only last 3 weights are evaluated
- **Files modified:** calculations_parity_test.dart
- **Commit:** 7b4f576

## Next Phase Readiness

- PLAT-02 calculations parity requirement: ✅ satisfied
- Parity gate pattern established for Phase 14 remaining plans
- No blockers for 14-02+
