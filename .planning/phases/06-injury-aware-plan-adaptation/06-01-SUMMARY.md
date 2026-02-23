---
phase: 06
plan: 01
subsystem: domain-engine
tags: [flutter, dart, tdd, injury-adaptation, program-models, pure-domain]

dependency-graph:
  requires:
    - "05-01: ProfilePersistenceProvider (InjuryProfileModel available)"
    - "flutter_app/lib/domain/models/exercise_definitions.dart"
    - "flutter_app/lib/domain/models/program_models.dart"
  provides:
    - "InjuryAdaptationEngine.adaptProgram static method"
    - "ProgramExercise injury metadata fields (injuryReplacedOriginal, injuryReplacementReason, isContraindicatedOriginal)"
    - "ProgramSession.recoveryPrepExercises field"
  affects:
    - "06-02: InjuryAdaptationProvider (consumes InjuryAdaptationEngine)"
    - "06-03: Adapted program display UI (consumes adapted ProgramV2)"
    - "06-04: Disclaimer/override flow (uses isContraindicatedOriginal)"

tech-stack:
  added: []
  patterns:
    - "TDD: RED-GREEN-REFACTOR cycle with 12 test cases"
    - "Pure static domain engine (no state, no side effects)"
    - "5-priority replacement fallback chain (regression table → category/muscle match → bodyweight → placeholder)"
    - "View-layer-only model fields (excluded from fromJson/toJson serialization)"
    - "Lazy Map<String, ExerciseDefinition> for O(1) exercise lookup"
    - "Identity fast-path (returns same reference when no injuries)"

file-tracking:
  created:
    - flutter_app/lib/domain/calculations/injury_adaptation_engine.dart
    - flutter_app/test/domain/injury_adaptation_engine_test.dart
  modified:
    - flutter_app/lib/domain/models/program_models.dart

decisions:
  - id: "view-layer-only-fields"
    choice: "Injury fields on ProgramExercise/ProgramSession are NOT serialized"
    rationale: "These fields are set by the engine at view time and should not pollute Firestore data. fromJson/toJson round-trips remain backward compatible."
  - id: "identity-fast-path"
    choice: "Return same program reference when activeInjuries is empty"
    rationale: "Zero allocation cost when no injury context is active. Providers downstream can use identical() to detect no-op."
  - id: "static-regression-table"
    choice: "Hardcoded regression table for primary lifts"
    rationale: "Deterministic and auditable. Safer alternatives for Back Squat, Front Squat, Conventional Deadlift, Flat Barbell Bench Press, Strict Press verified to exist in Exercises.all."
  - id: "isContraindicatedOriginal-default-false"
    choice: "Engine always sets isContraindicatedOriginal=false"
    rationale: "Per plan spec: this field is only set to true when the user manually reverts to the original — never by the engine itself. Preserves user agency model."

metrics:
  duration: "~3 minutes"
  completed: "2026-02-23"
  tests-run: 12
  tests-passed: 12
  lines-added: ~400
---

# Phase 6 Plan 01: InjuryAdaptationEngine — Exercise Replacement + Recovery Prep Injection Summary

**One-liner:** Pure static TDD engine replacing contraindicated exercises via 5-priority fallback chain and injecting per-session recovery prep blocks, with zero serialization impact on existing program models.

## What Was Built

### Model Extensions (`program_models.dart`)

**ProgramExercise** — three new view-layer-only fields (not serialized):
- `String? injuryReplacedOriginal` — original exercise name when replaced
- `String? injuryReplacementReason` — human-readable reason (format: "Replaced — {location} injury limits {original}. Using {replacement} instead.")
- `bool isContraindicatedOriginal = false` — only set to `true` by user revert action, never by the engine

**ProgramSession** — one new view-layer-only field:
- `List<ProgramExercise> recoveryPrepExercises = const []` — targeted warm-up/mobility block set by engine

Existing `fromJson`/`toJson` methods untouched — backward compatibility guaranteed.

### InjuryAdaptationEngine (`injury_adaptation_engine.dart`)

Pure static class with no state or side effects:

```dart
InjuryAdaptationEngine.adaptProgram(
  baseProgram: program,
  activeInjuries: [kneeInjury],
)
```

**No-op fast path:** Returns `baseProgram` as the same reference when `activeInjuries` is empty.

**Contraindication rules (static map):**
- `knee` → category: Squat Variations; muscle: quads
- `shoulder` → categories: Overhead Pressing, Bench Press Variations; muscle: shoulders
- `back`/`spine` → categories: Hinge Variations, Deadlift Variations; muscle: back
- `hip` → muscles: glutes + hamstrings

**5-priority replacement fallback chain:**
1. Static regression table (verified against Exercises.all)
2. Same category + overlapping muscle group
3. Same category, any muscle emphasis
4. Safe bodyweight set (Air Squats, Bird-Dogs, Bodyweight Lunges)
5. Annotated placeholder ("Consult coach — no safe automatic replacement found")

**Regression table entries:**
- Back Squat → Goblet Squat, Air Squats, Leg Press
- Front Squat → Goblet Squat, Air Squats
- Conventional Deadlift (No Straps) → Romanian Deadlift / RDL (No Straps), Trap Bar / Hex Bar Deadlift
- Flat Barbell Bench Press → Dumbbell Bench Press, Floor Press
- Strict Press / Military Press → Lateral Raises, Z-Press

**Recovery prep map:**
- `knee` → Bird-Dogs, Bodyweight Lunges
- `shoulder` → Banded Pull-Aparts, Face Pulls
- `back`/`spine` → Bird-Dogs (+ Bodyweight Lunges for back)
- `hip` → Bodyweight Lunges, Bird-Dogs
- Deduplication + 5-exercise cap enforced

Recovery prep exercises: 2 sets, 8-15 reps, 0.5 min rest, notes prefixed with "Injury recovery prep —".

## Tests (12/12 pass)

| # | Test Case |
|---|-----------|
| 1 | No injuries → same program reference (identity) |
| 2 | Back Squat replaced with knee injury; injuryReplacedOriginal set |
| 3 | Flat Barbell Bench Press replaced with shoulder injury |
| 4 | Recovery prep in every session when knee injury active |
| 5 | Multi-injury recovery prep deduplicated, capped at 5 |
| 6 | Non-contraindicated exercise passes through; recovery prep still added |
| 7 | Replacement reason format: starts with "Replaced", mentions location |
| 8 | isContraindicatedOriginal is false on replaced exercises |
| 9 | Injury fields null on non-replaced exercises |
| 10 | Input program not mutated |
| 11 | fromJson/toJson excludes injury-only fields |
| 12 | Recovery prep structure: sets 2-3, reps 8-15, rest 0.5, notes prefix |

## Decisions Made

1. **View-layer-only fields** — injury metadata fields not added to fromJson/toJson, keeping Firestore data clean and backward compatible.
2. **Identity fast-path** — when no injuries, same reference returned (zero allocation).
3. **Hardcoded regression table** — deterministic, auditable alternatives for primary lifts.
4. **isContraindicatedOriginal stays false** — engine respects user agency model; only user revert actions set this to true.
5. **Lazy exercise map** — `Map<String, ExerciseDefinition>` built once and reused for O(1) lookup.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Style] Fixed local variable naming convention**
- **Found during:** REFACTOR phase (`flutter analyze`)
- **Issue:** `_safeBodyweight` local variable used underscore prefix, violating `no_leading_underscores_for_local_identifiers` lint rule
- **Fix:** Renamed to `safeBodyweight`
- **Files modified:** `flutter_app/lib/domain/calculations/injury_adaptation_engine.dart`
- **Commit:** 96000f3

None others — plan executed as written.

## Next Phase Readiness

- **06-02** (InjuryAdaptationProvider): InjuryAdaptationEngine.adaptProgram is ready to consume. Signature: `({required ProgramV2 baseProgram, required List<InjuryProfileModel> activeInjuries}) → ProgramV2`
- **06-03** (Adapted program UI): ProgramSession.recoveryPrepExercises and ProgramExercise injury fields are ready for display.
- **06-04** (Disclaimer/override flow): `isContraindicatedOriginal` field exists on ProgramExercise, defaults to false, ready for user revert action.

No blockers for subsequent plans.
