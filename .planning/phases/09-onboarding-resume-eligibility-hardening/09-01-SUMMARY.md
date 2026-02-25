---
phase: 09-onboarding-resume-eligibility-hardening
plan: 01
subsystem: auth
tags: [onboarding, auth-bootstrap, eligibility, regression]
requires:
  - phase: 05-profile-persistence-foundation
    provides: "Initial auth bootstrap stream and onboarding status routing"
provides:
  - "Central onboarding-eligibility evaluator with deterministic legacy-history rules"
  - "Auth bootstrap fallback to resume onboarding on legacy probe timeout/error"
  - "Non-blocking onboarding flag auto-heal for stale legacy profiles"
affects: [09-02, 09-03, 10]
tech-stack:
  added: []
  patterns:
    - "Single evaluator contract for onboarding eligibility decisions"
    - "Bounded probe + conservative fallback for bootstrap uncertainty"
key-files:
  created:
    - flutter_app/lib/features/auth/domain/onboarding_eligibility_evaluator.dart
    - flutter_app/test/features/auth/domain/onboarding_eligibility_evaluator_test.dart
    - flutter_app/test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart
  modified:
    - flutter_app/lib/features/auth/data/auth_repository.dart
    - flutter_app/lib/features/auth/domain/auth_state.dart
    - flutter_app/lib/domain/models/user_model.dart
    - flutter_app/test/domain/models/user_model_test.dart
key-decisions:
  - "Treat name as required onboarding field and auto-heal onboardingComplete when name is present"
  - "Differentiate workout-history vs max-only legacy records before resume routing"
  - "Default to resume onboarding when legacy evidence probing times out or errors"
patterns-established:
  - "AuthRepository resolves profile status through resolveAuthSessionForProfile"
  - "Evaluator outputs reasoned decisions (complete vs resume) with recovery metadata"
duration: 49 min
completed: 2026-02-25
---

# Phase 09 Plan 01 Summary

**Deterministic onboarding eligibility evaluation now prevents false resume prompts while preserving conservative resume fallback on uncertainty.**

## Performance

- **Duration:** 49 min
- **Started:** 2026-02-25T22:40:00Z
- **Completed:** 2026-02-25T23:29:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added `OnboardingEligibilityEvaluator` with explicit reason codes and legacy evidence handling.
- Refactored bootstrap profile resolution to use one decision path with timeout/error fallback to `resumeOnboarding`.
- Added matrix coverage for ONB-04/ONB-05 and explicit gender-answer normalization behavior.

## Task Commits

1. **Task 1: Create onboarding eligibility evaluator contract** - `0fe9044` (feat)
2. **Task 2: Wire evaluator into auth bootstrap with fallback and auto-heal** - `0fe9044` (feat)
3. **Task 3: Add decision-matrix repository and domain regression tests** - `0fe9044` (feat)

## Files Created/Modified
- `flutter_app/lib/features/auth/domain/onboarding_eligibility_evaluator.dart` - Central eligibility decision engine.
- `flutter_app/lib/features/auth/data/auth_repository.dart` - Auth bootstrap routing integration with bounded legacy probes.
- `flutter_app/lib/features/auth/domain/auth_state.dart` - Session metadata extension for downstream recovery messaging.
- `flutter_app/lib/domain/models/user_model.dart` - Explicit gender-answer helper for normalized completion paths.
- `flutter_app/test/features/auth/domain/onboarding_eligibility_evaluator_test.dart` - Eligibility matrix tests.
- `flutter_app/test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart` - Bootstrap fallback and ordering tests.
- `flutter_app/test/domain/models/user_model_test.dart` - Model-level explicit-gender assertions.

## Decisions Made
- Consolidated onboarding eligibility logic into one evaluator to remove contradictory auth bootstrap branches.
- Kept legacy evidence probing lightweight (`limit(1)` existence checks) to avoid broad collection hydration.
- Routed probe failures to resume onboarding to meet conservative uncertainty policy.

## Deviations from Plan

None - plan executed within intended scope.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Session metadata and evaluator outcomes are ready for user-visible recovery messaging.
- Ready for `09-02` UX hardening and restart reset semantics.

---
*Phase: 09-onboarding-resume-eligibility-hardening*
*Completed: 2026-02-25*
