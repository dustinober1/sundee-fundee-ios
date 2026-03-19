---
phase: 20-notification-infrastructure
plan: 01
subsystem: infra
tags: [expo-notifications, firebase-messaging, async-storage, react-native, hooks]

# Dependency graph
requires:
  - phase: 17.1-repo-restructure
    provides: Consolidated repo root with TypeScript + Firebase setup
  - phase: 18-native-modules
    provides: expo-notifications and @react-native-firebase/messaging native modules installed
provides:
  - AppSettings extended with 4 granular notification toggles and reminder time fields
  - notificationService module with scheduleDailyReminder, cancelDailyReminder, registerFCMToken
  - notification-copy domain module with cycle-phase-aware and generic copy
  - useNotificationPermission hook returning OS permission status
affects:
  - 20-02 (permission modal, useRestTimer toggle wiring use AppSettings + notificationService)
  - 20-03 (Settings UI renders notification toggles from AppSettings)
  - 20-04 (FCM token registration calls registerFCMToken on sign-in)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Notification service uses cancel-and-reschedule pattern via AsyncStorage-persisted notification ID"
    - "FCM token registration uses dynamic require() inside try/catch (consistent with initAnalytics/initCrashlytics)"
    - "Domain layer notification-copy has zero dependencies — pure TypeScript, fully unit tested"
    - "Granular per-type notification toggles replace single notificationsEnabled boolean"

key-files:
  created:
    - src/repositories/__tests__/SettingsRepo.test.ts
    - src/domain/__tests__/notification-copy.test.ts
    - src/services/__tests__/notificationService.test.ts
    - src/domain/notifications/notification-copy.ts
    - src/services/notificationService.ts
    - src/hooks/useNotificationPermission.ts
  modified:
    - src/repositories/SettingsRepo.ts
    - src/repositories/__tests__/FirestoreSettingsRepo.test.ts
    - src/repositories/__tests__/LocalSettingsRepo.test.ts
    - src/repositories/__tests__/migration.test.ts
    - src/hooks/__tests__/useRestTimer.test.ts
    - app/(app)/__tests__/workout-detail.test.tsx
    - app/(app)/__tests__/exercise-detail.test.tsx
    - app/(app)/ai-workout/__tests__/config.test.tsx
    - __mocks__/expo-notifications.ts

key-decisions:
  - "notificationsEnabled boolean replaced by 4 granular toggles: restTimerAlertsEnabled (true), workoutRemindersEnabled (false), wodAlertsEnabled (true), subscriptionAlertsEnabled (true)"
  - "Old Firestore docs missing new fields get defaults via { ...DEFAULT_SETTINGS, ...stored } spread in consumers — no migration needed"
  - "notificationService test uses explicit jest.mock('expo-notifications') to avoid duplicate mock resolution from .claude/worktrees"

patterns-established:
  - "Notification IDs stored in AsyncStorage under @sundee/daily_reminder_id for cancel-and-reschedule"
  - "SchedulableTriggerInputTypes.DAILY with repeats:true for daily reminders"

requirements-completed:
  - NOTIF-06
  - NOTIF-07
  - NOTIF-08

# Metrics
duration: 5min
completed: 2026-03-19
---

# Phase 20 Plan 01: Notification Infrastructure Foundation Summary

**AppSettings extended with 4 granular notification toggles + reminder time; notificationService with daily reminder scheduling and FCM token registration; cycle-phase-aware copy domain module; useNotificationPermission hook**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-19T00:39:24Z
- **Completed:** 2026-03-19T00:43:52Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Replaced single `notificationsEnabled` boolean with 4 per-type toggles and 2 reminder time fields across AppSettings
- Created `notificationService.ts` with cancel-and-reschedule daily reminder, FCM token registration (skips web + guest), and cycle-aware copy selection
- Created pure domain `notification-copy.ts` with CYCLE_COPY (4 phases) and GENERIC_COPY (4 variations) — fully unit tested
- Created `useNotificationPermission` hook for OS permission status
- Updated 8 existing test files to use new AppSettings schema — full suite at 1382/1390 passing (8 pre-existing unrelated failures)

## Task Commits

1. **Task 1 (RED): Tests for notification foundation** - `655d23a` (test)
2. **Task 1 (GREEN): Notification foundation implementation** - `6840116` (feat)
3. **Task 2: Update existing tests for AppSettings schema change** - `1b41baf` (feat)

## Files Created/Modified

- `src/repositories/SettingsRepo.ts` — AppSettings interface extended; notificationsEnabled removed; 6 new fields with defaults
- `src/domain/notifications/notification-copy.ts` — CYCLE_COPY, GENERIC_COPY, getCycleAwareCopy, getGenericCopy
- `src/services/notificationService.ts` — scheduleDailyReminder, cancelDailyReminder, registerFCMToken
- `src/hooks/useNotificationPermission.ts` — hook returning status/isGranted/isDenied/checkPermission
- `__mocks__/expo-notifications.ts` — added SchedulableTriggerInputTypes enum
- 7 existing test files updated to remove notificationsEnabled references

## Decisions Made

- `notificationsEnabled` replaced by `restTimerAlertsEnabled` (true), `workoutRemindersEnabled` (false), `wodAlertsEnabled` (true), `subscriptionAlertsEnabled` (true) — matches the per-feature toggle model planned in Phase 20 context
- No Firestore migration needed — existing documents missing new fields get defaults via `{ ...DEFAULT_SETTINGS, ...stored }` spread in consumers
- `notificationService.test.ts` uses explicit `jest.mock('expo-notifications')` rather than auto-mock due to duplicate mock resolution from `.claude/worktrees/` directory

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added SchedulableTriggerInputTypes to expo-notifications mock**
- **Found during:** Task 1 (GREEN — notificationService.ts implementation)
- **Issue:** `__mocks__/expo-notifications.ts` did not export `SchedulableTriggerInputTypes`, causing `TypeError: Cannot read properties of undefined (reading 'DAILY')` in notificationService.ts
- **Fix:** Added `SchedulableTriggerInputTypes` enum to mock file; also added explicit `jest.mock('expo-notifications')` in the test file to avoid resolution conflicts with `.claude/worktrees/` duplicate
- **Files modified:** `__mocks__/expo-notifications.ts`, `src/services/__tests__/notificationService.test.ts`
- **Verification:** All 32 target tests pass
- **Committed in:** `6840116` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for test infrastructure correctness. No scope creep.

## Issues Encountered

- jest-haste-map reports duplicate manual mocks between `__mocks__/` and `.claude/worktrees/serene-poincare/SundeeFundeeRN/__mocks__/` — pre-existing warning, does not affect test results but requires explicit `jest.mock()` calls in some test files. Logged to deferred-items.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- AppSettings foundation ready for Plan 02 (permission modal, useRestTimer toggle wiring)
- `notificationService.scheduleDailyReminder` ready to wire to Settings UI in Plan 03
- `registerFCMToken` ready to call on sign-in in Plan 04
- Pre-existing PaywallModal and useEntitlements test failures (8 tests) are unrelated blockers that existed before this phase

## Self-Check: PASSED

- FOUND: src/repositories/SettingsRepo.ts
- FOUND: src/domain/notifications/notification-copy.ts
- FOUND: src/services/notificationService.ts
- FOUND: src/hooks/useNotificationPermission.ts
- FOUND: .planning/phases/20-notification-infrastructure/20-01-SUMMARY.md
- FOUND commit: 655d23a (test RED)
- FOUND commit: 6840116 (feat GREEN)
- FOUND commit: 1b41baf (feat task 2)

---
*Phase: 20-notification-infrastructure*
*Completed: 2026-03-19*
