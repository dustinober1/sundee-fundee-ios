---
phase: 13
plan: "04"
name: "sync-ui-wiring"
subsystem: "sync-ui"
tags: ["flutter", "riverpod", "sync", "ui", "settings", "dashboard"]

dependency-graph:
  requires: ["13-02", "13-03"]
  provides: ["SyncStatusBadge widget", "DashboardScreen AppBar actions", "syncAfterWorkout wiring", "SettingsScreen", "/settings route"]
  affects: ["13-05"]

tech-stack:
  added: []
  patterns: ["ConsumerWidget for reactive sync badge", "fire-and-forget async pattern for sync trigger", "KeyedSubtree for widget key assignment"]

file-tracking:
  key-files:
    created:
      - flutter_app/lib/shared/widgets/sync_status_badge.dart
      - flutter_app/lib/features/settings/settings_screen.dart
    modified:
      - flutter_app/lib/features/dashboard/dashboard_screen.dart
      - flutter_app/lib/shared/providers/workout_session_provider.dart
      - flutter_app/lib/router/router.dart

decisions:
  - id: "D1"
    what: "Remove unnecessary null check on workoutId in syncAfterWorkout call"
    why: "saveWorkout() returns non-nullable int; null check caused `unnecessary_null_comparison` warning failing flutter analyze"
    impact: "Cleaner code; no behavior change since workoutId is always non-null at that point"

metrics:
  duration: "~2 minutes"
  completed: "2026-02-21"
---

# Phase 13 Plan 04: Sync UI Wiring Summary

**One-liner:** SyncStatusBadge (cloud icon per SyncStatus) in DashboardScreen AppBar + auth nav + fire-and-forget syncAfterWorkout on workout completion + minimal SettingsScreen with sign-out/last-synced.

## What Was Built

### SyncStatusBadge widget
`flutter_app/lib/shared/widgets/sync_status_badge.dart` — ConsumerWidget that watches `syncProvider` and renders:
- `disabled` → `SizedBox.shrink()` (invisible; Supabase not configured)
- `offline` → `Icons.cloud_off` (grey)
- `pending` → `Icons.cloud_upload` (orange)
- `syncing` → 20×20 `CircularProgressIndicator`
- `synced` → `Icons.cloud_done` (green)
- `error` → `Icons.cloud_off` (red)

Key `sync-status-badge` applied via `KeyedSubtree` wrapper.

### DashboardScreen AppBar actions
Added `actions` list to existing `AppBar`:
1. `const SyncStatusBadge()` — always present, invisible when disabled
2. `Consumer` widget — shows `Icons.login` (Key: `nav-auth`) when unauthenticated, `Icons.settings` (Key: `nav-settings`) when authenticated. Navigates to `/auth` or `/settings` respectively.

### syncAfterWorkout wiring
`workout_session_provider.dart` — after `state = null;` at end of `completeWorkout()`, calls `ref.read(syncProvider.notifier).syncAfterWorkout(workoutId)` as fire-and-forget (`// ignore: unawaited_futures`). Workout completion is never blocked by sync outcome.

### SettingsScreen
`flutter_app/lib/features/settings/settings_screen.dart` — ConsumerWidget with:
- Scaffold Key: `settings-screen`, AppBar title: "Settings"
- **Authenticated state:** email display (Key: `settings-user-email`), last synced formatted string (Key: `settings-last-synced`, shows "Never" if null), sign-out button (Key: `settings-sign-out`) that calls `authProvider.notifier.signOut()` then navigates to `/dashboard`
- **Unauthenticated state:** "Not signed in" text + "Sign In" button navigating to `/auth`

### Router update
Added `/settings` GoRoute importing `SettingsScreen` to `router.dart`.

## Decisions Made

| Decision | What | Why | Impact |
|----------|------|-----|--------|
| D1 | Remove null check on workoutId | saveWorkout() returns non-nullable int; check caused flutter analyze warning | Clean code, no behavior change |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unnecessary null check on workoutId**

- **Found during:** Task 2 — `flutter analyze` reported `unnecessary_null_comparison`
- **Issue:** Plan template included `if (workoutId != null)` guard, but `workoutId` is the direct return value of `saveWorkout()` (non-nullable `int`)
- **Fix:** Removed the null check; kept the `// ignore: unawaited_futures` comment on the bare call
- **Files modified:** `flutter_app/lib/shared/providers/workout_session_provider.dart`
- **Commit:** 4fdf8af

## Next Phase Readiness

Plan 13-05 (parity gate tests) can now proceed:
- `Key('sync-status-badge')` available on DashboardScreen
- `Key('nav-auth')` and `Key('nav-settings')` available on DashboardScreen AppBar
- `Key('settings-screen')`, `Key('settings-user-email')`, `Key('settings-last-synced')`, `Key('settings-sign-out')` available on SettingsScreen
- `/settings` route registered in GoRouter
- `syncAfterWorkout` wired into `completeWorkout()` fire-and-forget
