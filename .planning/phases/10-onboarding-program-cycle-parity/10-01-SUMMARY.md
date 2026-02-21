---
phase: 10
plan: "01"
name: "Onboarding Wizard Goal Selection + Persistence"
subsystem: onboarding
tags: [flutter, riverpod, go_router, shared_preferences, drift, onboarding]
one-liner: "3-step onboarding (name→experience→goal) with Drift DB save, SharedPreferences flag, and go_router redirect guard for restart parity"

dependency-graph:
  requires:
    - "09-05 — Drift persistence layer (AppDatabase, Users table)"
    - "09-01 — Flutter project bootstrap (router, app structure)"
  provides:
    - "onboarding_status_provider.dart — NotifierProvider<bool> for completion state"
    - "user_provider.dart — FutureProvider<User?> for current user from Drift"
    - "3-step onboarding wizard with goal selection and v1.1 parity defaults"
    - "go_router redirect guard preventing dashboard access before onboarding"
    - "SharedPreferences persistence so onboarding survives app restarts"
  affects:
    - "Phase 10 plans 02+ (program/cycle parity) — dashboard accessible after onboarding"
    - "Any screen using userProvider for greeting/personalization"

tech-stack:
  added: []
  patterns:
    - "Riverpod 3.x NotifierProvider<T> with initialState constructor parameter for testable overrides"
    - "ProviderScope.overrideWith pattern for pre-loading async state (SharedPreferences) before runApp"
    - "go_router redirect guard + dynamic initialLocation from provider state"
    - "Icon-based radio selection (Icons.radio_button_checked/unchecked) — avoids deprecated Radio<String>"

key-files:
  created:
    - flutter_app/lib/shared/providers/onboarding_status_provider.dart
    - flutter_app/lib/shared/providers/user_provider.dart
  modified:
    - flutter_app/lib/features/onboarding/onboarding_screen.dart
    - flutter_app/lib/main.dart
    - flutter_app/lib/router/router.dart

decisions:
  - id: D-10-01-A
    decision: "Use NotifierProvider instead of StateProvider for onboarding flag"
    rationale: "Riverpod 3.x removed StateProvider from main export; only available via legacy.dart. NotifierProvider with setComplete() method is the idiomatic 3.x pattern."
    alternatives: "Import StateProvider from flutter_riverpod/legacy.dart"
  - id: D-10-01-B
    decision: "Expose setComplete() method on OnboardingStatusNotifier rather than setting .state externally"
    rationale: "Riverpod 3.x marks .state as @protected/@visibleForTesting outside Notifier subclasses — direct external mutation produces analyzer warnings."
    alternatives: "Use legacy.dart StateProvider which allows direct state mutation"
  - id: D-10-01-C
    decision: "OnboardingStatusNotifier accepts initialState constructor param for override-ability"
    rationale: "Allows main.dart to inject SharedPreferences value via overrideWith() and allows test helpers to force onboarding state without SharedPreferences mock."
    alternatives: "Read SharedPreferences inside the notifier build() method"

metrics:
  duration: "~15 minutes"
  completed: "2026-02-21"
  tasks-completed: 2
  tasks-total: 2
  deviations: 1
---

# Phase 10 Plan 01: Onboarding Wizard Goal Selection + Persistence Summary

## What Was Built

Enhanced the Flutter onboarding wizard to achieve full v1.1 behavioral parity:
- **3-step flow** (name → experience → goal) with step indicator "Step X of 3"
- **Pre-selected defaults** matching v1.1: `beginner` for experience, `strength` for goal
- **Goal selection step** with 3 ListTile options (Build Strength / Muscle Growth / Power & Speed) using Icon-based selection
- **Drift DB persistence** saves name, experience level, and goal on completion
- **SharedPreferences flag** (`onboarding_complete`) set on completion
- **go_router redirect guard** prevents dashboard access before onboarding and skips onboarding on restart for completed users

## Satisfies

- **ONBD-01**: Same 3 required fields as v1.1 (name required, experience/goal have defaults)
- **ONBD-02**: Profile data and completion flag persists across app restarts; router routes correctly

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Enhance onboarding wizard with goal selection + persistence | 27ce155 | onboarding_screen.dart, onboarding_status_provider.dart, user_provider.dart |
| 2 | Add go_router redirect guard + update main.dart | 6a29a92 | main.dart, router.dart |

## Verification Results

- ✅ `flutter analyze` — zero issues
- ✅ `flutter build web` — succeeds (25.5s)
- ✅ `flutter test test/widget_test.dart` — passes
- ✅ `_selectedGoal` present in onboarding_screen.dart
- ✅ All goal Keys present (goal-strength, goal-hypertrophy, goal-explosiveness)
- ✅ Router has redirect guard + dynamic initialLocation
- ✅ main.dart loads SharedPreferences before app start

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Riverpod 3.x StateProvider not available in main export**

- **Found during:** Task 1 — `flutter analyze` error: "The function 'StateProvider' isn't defined"
- **Issue:** Riverpod 3.x (v3.2.1) moved `StateProvider` to `legacy.dart`; it's not exported from `flutter_riverpod.dart`
- **Fix:** Replaced `StateProvider<bool>` with `NotifierProvider<OnboardingStatusNotifier, bool>` using Riverpod 3.x idiomatic pattern. Added `setComplete()` method to `OnboardingStatusNotifier` since `.notifier.state = x` is `@protected` in 3.x. Updated `main.dart` override to use `overrideWith(() => OnboardingStatusNotifier(initialState: value))`.
- **Files modified:** `onboarding_status_provider.dart`, `onboarding_screen.dart`, `main.dart`
- **Commits:** 27ce155, 6a29a92

## Integration Test Compatibility

The `pumpApp` helper in `app_helper.dart` uses `const ProviderScope(child: SundeeFundeeApp())` which defaults `onboardingCompleteProvider` to `false` — tests start at `/onboarding` as intended. The redirect guard redirects any non-onboarding path to `/onboarding` when incomplete, which is correct test behavior. All existing Keys preserved:
- `onboarding-name-input`, `onboarding-next-button`, `onboarding-back-button` (unchanged)
- `onboarding-start-button` (moved to Row alongside Back button)
- `experience-beginner/intermediate/advanced` (unchanged)
- `goal-strength/hypertrophy/explosiveness` (new, as specified)

## Next Phase Readiness

- ✅ Onboarding complete → dashboard accessible
- ✅ User profile (name, experience, goal) saved in Drift DB
- ✅ `userProvider` available for dashboard greeting and future screens
- ✅ Router redirect guard in place for all navigation
- Ready for Phase 10 Plan 02 (Program/Cycle parity)
