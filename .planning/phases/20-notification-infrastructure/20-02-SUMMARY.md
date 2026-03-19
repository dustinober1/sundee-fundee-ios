---
phase: 20-notification-infrastructure
plan: 02
subsystem: ui
tags: [expo-notifications, async-storage, react-native, hooks, android-channels, fcm]

# Dependency graph
requires:
  - phase: 20-01
    provides: AppSettings with restTimerAlertsEnabled toggle; notificationService with registerFCMToken; useNotificationPermission hook

provides:
  - Art Deco NotificationPermissionModal shown once after first workout completion
  - useRestTimer refactored with restTimerAlertsEnabled param and deep-link notification data
  - Android notification channels (rest-timer HIGH, reminders DEFAULT) created at app load
  - FCM token registered after auth resolves for non-guest, non-web users
  - Notification tap deep-links to /workout-session via response listener in app layout
  - Zero eager permission requests remain in codebase

affects:
  - 20-03 (Settings UI toggles affect restTimerAlertsEnabled passed to useRestTimer)
  - 20-04 (FCM token registration also wired here on sign-in via app layout)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deferred permission pattern: Art Deco modal shown after first workout; OS dialog fires only on Enable tap"
    - "AsyncStorage flags @sundee/first_workout_done + @sundee/notif_permission_asked prevent modal re-showing"
    - "Android channels created at module load (outside component) so available before first notification"
    - "RNFB messaging token refresh uses dynamic require() inside try/catch — consistent with Phase 19 pattern"

key-files:
  created:
    - src/components/notifications/NotificationPermissionModal.tsx
  modified:
    - src/hooks/useRestTimer.ts
    - src/hooks/__tests__/useRestTimer.test.ts
    - app/(app)/workout-session.tsx
    - app/(app)/_layout.tsx

key-decisions:
  - "Notification permission modal shown after first workout save (not on screen mount) — respects user trust-building flow"
  - "NOTIF_PERMISSION_ASKED_KEY persisted to AsyncStorage so modal never re-appears regardless of Enable/Not Now choice"
  - "restTimerAlertsEnabled defaults to true; visual timer always runs even when false"

patterns-established:
  - "First-use feature modal: check AsyncStorage key after meaningful action, set key on both accept and dismiss"
  - "Module-level Android channel creation with void prefix (fire-and-forget at load time)"

requirements-completed:
  - NOTIF-01
  - NOTIF-02
  - NOTIF-03

# Metrics
duration: 8min
completed: 2026-03-19
---

# Phase 20 Plan 02: Notification Permission Flow Wiring Summary

**Art Deco permission modal deferred to post-first-workout, useRestTimer toggle guard, Android channels + FCM token registration wired in app layout**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-19T00:45:00Z
- **Completed:** 2026-03-19T00:53:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Created `NotificationPermissionModal` (Art Deco styled: cream bg, navy text, orange accent) shown once after first workout using two AsyncStorage flags
- Refactored `useRestTimer` to accept `restTimerAlertsEnabled` param — notification skipped when false, visual timer always runs; added deep-link data and Android channelId to notification content
- Removed all eager `requestPermissionsAsync`/`getPermissionsAsync` calls from `useRestTimer` and `workout-session.tsx`
- Wired Android `rest-timer` (HIGH importance) and `reminders` (DEFAULT) channels at module load in `_layout.tsx`
- Added FCM token registration on auth resolve with token refresh listener (non-guest, non-web) using RNFB dynamic require pattern
- Added notification response deep-link listener routing to URL stored in notification data

## Task Commits

1. **Task 1: Permission modal, useRestTimer refactor, workout-session eager permission removal** - `d0c5ce2` (feat)
2. **Task 2: Android channels, FCM token registration, deep-link listener in app layout** - `558bc19` (feat)

## Files Created/Modified

- `src/components/notifications/NotificationPermissionModal.tsx` — Art Deco modal with visible/onEnable/onDismiss props; no business logic
- `src/hooks/useRestTimer.ts` — Added `restTimerAlertsEnabled` param; removed eager permission; added deep-link data and Android channelId to notification content
- `src/hooks/__tests__/useRestTimer.test.ts` — Removed obsolete permission mocks; added toggle guard and deep-link content tests (12 tests, all pass)
- `app/(app)/workout-session.tsx` — Removed eager permission useEffect; added first-workout detection + modal handlers; pass settings.restTimerAlertsEnabled to hook
- `app/(app)/_layout.tsx` — Android channels at module load; FCM token registration + refresh listener on auth; notification response deep-link listener

## Decisions Made

- Modal shown after `finishWorkout()` succeeds (not on mount) — preserves trust by showing value proposition only after user has experienced the app
- Both "Enable" and "Not Now" paths set `NOTIF_PERMISSION_ASKED_KEY` — modal never shown again regardless of choice
- `restTimerAlertsEnabled` defaults to `true` so the hook works out of the box before settings are loaded

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — pre-existing PaywallModal and useEntitlements test failures (8 tests) remain unrelated to this plan's changes, as documented in 20-01 SUMMARY.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Permission modal wired and working; FCM token registration live after auth
- Plan 03 can wire notification toggle settings UI (restTimerAlertsEnabled, workoutRemindersEnabled, etc.) — useRestTimer already reads from settings
- Plan 04 sign-in FCM registration will complement the app layout registration (auth layout vs app layout coverage)

## Self-Check: PASSED

- FOUND: src/components/notifications/NotificationPermissionModal.tsx
- FOUND: src/hooks/useRestTimer.ts (restTimerAlertsEnabled param present)
- FOUND: app/(app)/workout-session.tsx (NotificationPermissionModal rendered, eager permission removed)
- FOUND: app/(app)/_layout.tsx (setNotificationChannelAsync + registerFCMToken present)
- FOUND commit: d0c5ce2 (Task 1 feat)
- FOUND commit: 558bc19 (Task 2 feat)

---
*Phase: 20-notification-infrastructure*
*Completed: 2026-03-19*
