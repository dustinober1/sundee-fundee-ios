# 05-02 Summary - Auth bootstrap state machine and onboarding routing

## Outcome
Implemented bootstrap routing states for onboarding completion, resume flow, and injury-required gating with deterministic redirect behavior.

## Completed Work
- Expanded `AuthStatus` with:
  - `resumeOnboarding`
  - `needsInjuryProfile`
- Refactored `AuthRepository.authStateChanges()` to derive session status from normalized profile data (instead of only `onboardingComplete` flag).
- Added onboarding restart operation for contradictory/partial legacy states.
- Updated onboarding screen with explicit resume vs restart decision UI.
- Updated router redirects to handle the new bootstrap states.
- Added dedicated routes for profile editing screens.
- Updated dashboard status rendering to include new auth states.

## Tests
- `flutter test test/features/auth/presentation/router_redirect_test.dart`
- `flutter test test/features/auth/presentation/onboarding_screen_test.dart`
- `flutter test test/features/auth/data/auth_repository_test.dart`

## Files
- `flutter_app/lib/features/auth/domain/auth_state.dart`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/lib/features/auth/presentation/onboarding_screen.dart`
- `flutter_app/lib/app/router.dart`
- `flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart`
- `flutter_app/test/features/auth/presentation/router_redirect_test.dart`
- `flutter_app/test/features/auth/presentation/onboarding_screen_test.dart`

## Commits
- Pending (batched in current session)
