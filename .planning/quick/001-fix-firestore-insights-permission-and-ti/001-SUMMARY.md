# Quick Task Summary 001

## Description
Fix Firestore insights permission-denied and timeout errors on dashboard insight loading.

## Implementation
- Removed hard 10-second `.timeout(...)` wrappers from cycle stream providers that were forcing `TimeoutException` errors during slower initial stream delivery.
- Added guarded stream handling in cycle providers to seed safe fallback values and suppress recoverable Firestore read errors (`permission-denied`, `unauthenticated`, `unavailable`, `deadline-exceeded`).
- Added recoverable error handling in `CycleInsightsChart` workout stream and UI error branch so recoverable read failures degrade to hidden insights instead of repeated error text/log spam.
- Kept non-recoverable errors surfaced for debugging.

## Files Changed
- `flutter_app/lib/features/cycle/providers.dart`
- `flutter_app/lib/features/dashboard/presentation/cycle_insights_chart.dart`

## Verification
- `dart format lib/features/cycle/providers.dart lib/features/dashboard/presentation/cycle_insights_chart.dart`
- `flutter analyze` (1 pre-existing info in onboarding profile screen: deprecated `value` usage)
- `flutter test test/features/cycle/presentation/cycle_tracking_screen_test.dart` (pass)
- `flutter test test/features/programs/presentation/programs_screen_test.dart` (pass)

## Commit
- `f325ea8` — code changes for this quick task
