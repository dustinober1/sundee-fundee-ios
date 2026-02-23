# Phase 04 Failure Inventory

Phase: 04-full-suite-test-stabilization-verification-hardening
Date: 2026-02-23
Status: resolved

## Baseline Run
- Command: `cd flutter_app && flutter test`
- Result: failed
- Suite progress at stop: `109` tests run, `1` failure

## Failure Catalog

### 1) `test/features/programs/squad_squat_program_test.dart`
- Failing test: `Week 12 Session C is the 1RM test`
- Category: brittle assertion drift
- Failure signature:
  - Expected: `'back-squat'`
  - Actual: `'Back Squat'`
  - Location: `test/features/programs/squad_squat_program_test.dart:34`
- Determinism check:
  - Command: `cd flutter_app && flutter test test/features/programs/squad_squat_program_test.dart`
  - Result: failed with same mismatch (deterministic)
- Disposition: fix test expectation
- Owner: phase-04 stabilization
- Status: fixed

## Triage Summary
- behavior regression: 0
- brittle assertion drift: 1
- environment/flaky: 0
- obsolete coverage: 0

## Final Disposition
- Item `1` closed by updating stale expectation in:
  - `flutter_app/test/features/programs/squad_squat_program_test.dart`
- Validation:
  - Focused rerun passed.
  - Broad rerun (`flutter test`) passed.
