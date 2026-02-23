# 05-03 Summary - Settings profile edits, injury CRUD, and plan refresh wiring

## Outcome
Added profile-edit surfaces in settings, injury CRUD/history actions, retry controls for failed writes, and plan-refresh invalidation hooks.

## Completed Work
- Added `OnboardingProfileScreen` for post-onboarding answer edits.
- Added `InjuryProfileScreen` for injury create/update/resolve flows.
- Added settings entry points for both profile editing surfaces.
- Added auth repository injury operations:
  - save injury
  - resolve injury
  - retry queued profile writes
- Wired profile changes to invalidate adapted program provider so plan views refresh after profile updates.

## Tests
- `flutter test test/features/settings/presentation/settings_screen_test.dart`
- `flutter test test/features/settings/presentation/injury_profile_screen_test.dart`
- `flutter test test/features/programs/providers/adapted_program_provider_test.dart`

## Files
- `flutter_app/lib/features/settings/presentation/settings_screen.dart`
- `flutter_app/lib/features/settings/presentation/onboarding_profile_screen.dart`
- `flutter_app/lib/features/settings/presentation/injury_profile_screen.dart`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/lib/features/programs/providers/adapted_program_provider.dart`
- `flutter_app/test/features/settings/presentation/settings_screen_test.dart`
- `flutter_app/test/features/settings/presentation/injury_profile_screen_test.dart`

## Commits
- Pending (batched in current session)
