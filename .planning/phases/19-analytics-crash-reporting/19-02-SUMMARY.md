---
phase: 19-analytics-crash-reporting
plan: 02
subsystem: analytics
tags: [analytics, crashlytics, event-logging, screen-tracking, user-properties]
dependency_graph:
  requires: ["19-01"]
  provides: ["ANLYT-01", "ANLYT-02", "ANLYT-03", "ANLYT-04", "ANLYT-05"]
  affects: ["app/_layout.tsx", "app/(app)/workout-session.tsx", "src/components/paywall/PaywallModal.tsx", "app/(app)/ai-workout/config.tsx", "app/(app)/(tabs)/cycle.tsx"]
tech_stack:
  added: []
  patterns: ["fire-and-forget void logEvent()", "useScreenTracking() in root layout", "setCrashlyticsKeys on sign-in"]
key_files:
  modified:
    - app/_layout.tsx
    - app/(app)/workout-session.tsx
    - src/components/paywall/PaywallModal.tsx
    - app/(app)/ai-workout/config.tsx
    - app/(app)/(tabs)/cycle.tsx
decisions:
  - "useScreenTracking() placed at top of RootLayout body (before useEffect) to ensure it fires on every tab change"
  - "setUserProperties defaults subscription_tier to 'free' on sign-in — EntitlementProvider refines this"
  - "logEvent calls use void prefix (fire-and-forget) — analytics failure must never block user action"
  - "subscription_started fires on both purchaseProduct and purchasePackage code paths for full coverage"
metrics:
  duration: "137 seconds"
  completed_date: "2026-03-18"
  tasks: 2
  files_modified: 5
---

# Phase 19 Plan 02: Analytics + Crashlytics Wiring Summary

**One-liner:** Wired screen tracking, 5 key event calls, user properties, and Crashlytics session keys into live app files connecting Plan 01 helpers to actual user actions.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Wire screen tracking, user properties, and Crashlytics keys in root layout | a5b12e1 | app/_layout.tsx |
| 2 | Wire key event logging at five action call sites | 3ddef5d | workout-session.tsx, PaywallModal.tsx, ai-workout/config.tsx, cycle.tsx |

## What Was Built

### Task 1 — Root Layout Integration

`app/_layout.tsx` now:
- Calls `useScreenTracking()` at the top of `RootLayout` body (before any `useEffect`) so every Expo Router navigation fires a `screen_view` event
- Calls `setUserProperties({ subscriptionTier: 'free', cycleTrackingEnabled: false })` in `handleUserSignIn` after profile persistence — defaults to 'free' as most users start free; EntitlementProvider refines when it loads
- Calls `setCrashlyticsKeys({ subscriptionTier: 'free', cyclePhase: 'unknown' })` in `handleUserSignIn` so every crash report includes tier and phase context
- Calls `crashlytics().setUserId(user.uid)` via require guard (non-fatal, mobile-only) for crash correlation

### Task 2 — Key Event Logging

Five events are now wired at their correct trigger points:

| Event | File | Trigger |
|-------|------|---------|
| `workout_started` | app/(app)/workout-session.tsx | After `startWorkout()` on session mount |
| `workout_completed` | app/(app)/workout-session.tsx | After `finishWorkout()` in handleFinish success path |
| `subscription_started` | src/components/paywall/PaywallModal.tsx | After `purchaseProduct()` success AND after `purchasePackage()` success (both code paths) |
| `ai_workout_generated` | app/(app)/ai-workout/config.tsx | After workout generation, before navigation to preview |
| `cycle_phase_updated` | app/(app)/(tabs)/cycle.tsx | After `savePeriodLog()` success |

All `logEvent` calls use the `void` prefix (fire-and-forget pattern consistent with Plan 01 design). None appear in error/catch blocks.

## Verification

All plan success criteria met:
- `useScreenTracking()` called at top of RootLayout
- `setUserProperties` called in `handleUserSignIn` with subscriptionTier and cycleTrackingEnabled
- `setCrashlyticsKeys` called in `handleUserSignIn` with subscriptionTier and cyclePhase
- All 5 logEvent calls present at correct locations in 4 files
- Test suite: 74/76 test suites pass (2 pre-existing failures in PaywallModal and useEntitlements — confirmed pre-existing before any changes)

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

All 5 modified files verified to exist on disk. Both task commits (a5b12e1, 3ddef5d) verified in git log.
