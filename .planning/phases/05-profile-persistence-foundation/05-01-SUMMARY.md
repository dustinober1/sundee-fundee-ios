# 05-01 Summary - Canonical profile schema and persistence foundation

## Outcome
Implemented canonical onboarding/injury profile persistence primitives with legacy-safe normalization and schema-hardening checks.

## Completed Work
- Added `InjuryProfileModel` with active/resolved lifecycle and completeness helpers.
- Extended `UserModel` with:
  - `onboardingComplete` + computed completeness (`onboardingCompleteComputed`)
  - `profileUpdatedAt`
  - normalized `injuryProfiles` list with legacy `injuryProfile` fallback support.
- Added `ProfileRepository`:
  - normalized profile stream reads
  - non-blocking default backfill writes
  - injury save/resolve/clear operations
  - queued retry support for failed writes.
- Added provider wiring for profile repository.
- Hardened Firestore rule surface for core profile fields (`onboardingComplete`, `profileUpdatedAt`, `injuryProfiles`).

## Tests
- `flutter test test/domain/models/user_model_test.dart`
- `flutter test test/features/profile/data/profile_repository_test.dart`
- `flutter test test/features/profile/data/firestore_profile_rules_test.dart`
- `flutter test test/features/auth/data/auth_repository_test.dart`

## Files
- `firestore.rules`
- `flutter_app/lib/domain/models/injury_profile_model.dart`
- `flutter_app/lib/domain/models/user_model.dart`
- `flutter_app/lib/features/profile/data/profile_repository.dart`
- `flutter_app/lib/features/profile/providers.dart`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/test/domain/models/user_model_test.dart`
- `flutter_app/test/features/profile/data/profile_repository_test.dart`
- `flutter_app/test/features/profile/data/firestore_profile_rules_test.dart`

## Commits
- Pending (batched in current session)
