# Offline Sync Playbook

## Purpose
Operational and QA checklist for validating offline behavior and reconnect stability across cycle/program/workout flows.

## Quick Health Checks
1. Confirm app loads previously available data while offline.
2. Confirm sync badge reflects `Offline cache` or `Syncing changes` as expected.
3. Confirm no blocking conflict dialogs appear during reconnect.

## QA Scenarios
1. Sign in online, then disable network and relaunch.
2. Open cycle screen and verify existing records render.
3. Edit cycle/program progress offline.
4. Re-enable network and verify UI settles without forced navigation/reset.
5. Confirm `Last synced`/badge state updates quietly.

## Expected Behavior
- Offline reads remain available from cached data where present.
- Offline writes do not block the user interaction flow.
- Reconnect resolves with latest-edit-wins semantics.
- Sync status remains subtle (no celebratory toasts/banners).

## Troubleshooting
- If users report stale data: verify `lastSyncedAt` progression after reconnect.
- If users report blocked actions: check for repository write exceptions and retry paths.
- If badge state appears stuck: verify provider graph (`cycleSyncStatusProvider`) and active async/loading state.

## Verification Commands
Run in `flutter_app/`:
- `flutter analyze`
- `flutter test test/features/auth/data/auth_repository_test.dart test/features/programs/providers/adapted_program_provider_test.dart test/features/programs/presentation/programs_screen_test.dart test/features/cycle/presentation/cycle_tracking_screen_test.dart test/features/workouts/presentation/workout_execution_screen_phase_update_test.dart test/features/workouts/presentation/workout_execution_progress_test.dart test/features/repositories/data/firestore_cycle_repository_test.dart test/features/repositories/data/firestore_phase1_smoke_test.dart test/accessibility/accessibility_smoke_test.dart test/accessibility/theme_contrast_test.dart test/widget_test.dart`
