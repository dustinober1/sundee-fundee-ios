---
phase: 04-pwa-quality
plan: 02
subsystem: pwa-install-prompt
tags: [pwa, install-prompt, hooks, tdd, android, ios]
dependency_graph:
  requires: [04-00, 04-01]
  provides: [useInstallPrompt hook, InstallBanner component, deferred navigation in workout flows]
  affects: [WorkoutSession, ProgramSession]
tech_stack:
  added: []
  patterns: [deferred-navigation-via-state, session-scoped-dismissal, platform-ua-detection]
key_files:
  created:
    - pwa/src/hooks/useInstallPrompt.ts
    - pwa/src/components/InstallBanner.tsx
  modified:
    - pwa/src/hooks/useInstallPrompt.test.ts
    - pwa/src/routes/WorkoutSession.tsx
    - pwa/src/routes/ProgramSession.tsx
decisions:
  - "Replaced Storage.prototype.setItem spy with sessionStorage.getItem assertion in dismiss() test — jsdom does not route sessionStorage through Storage.prototype in vitest; behavioral equivalence preserved"
  - "pendingNavigation stored as function (() => void) | null via useState — avoids stale closure by storing a thunk rather than the navigation target string"
  - "InstallBanner onAfterDismiss prop defers navigation to after banner interaction — prevents premature component unmount"
metrics:
  duration: "10min"
  completed: "2026-03-21"
  tasks_completed: 2
  tasks_total: 3
  files_changed: 5
---

# Phase 04 Plan 02: PWA Install Prompt Summary

Cross-platform PWA install prompt after workout completion: Android native prompt + iOS share-icon instructions banner, with session-scoped dismissal and deferred navigation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create useInstallPrompt hook with tests and InstallBanner component | bf88428 | useInstallPrompt.ts, useInstallPrompt.test.ts, InstallBanner.tsx |
| 2 | Wire install prompt into workout completion flows | 2f652a2 | WorkoutSession.tsx, ProgramSession.tsx |
| 3 | Lighthouse PWA audit | — | (awaiting human verification) |

## What Was Built

### useInstallPrompt hook (`pwa/src/hooks/useInstallPrompt.ts`)
- Android: listens for `beforeinstallprompt` event, calls `e.preventDefault()`, stores event in state
- iOS: detects via `/iPad|iPhone|iPod/.test(navigator.userAgent)` when not standalone
- Standalone detection: `window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true`
- Session-scoped dismissal: `sessionStorage.setItem('installPromptDismissed', '1')` — banner reappears next session
- `showPrompt` computed: `(androidPrompt !== null || isIOS) && !isDismissed && !isStandalone`
- `triggerAndroid()`: calls `prompt()`, awaits `userChoice`, auto-dismisses if user rejects

### InstallBanner component (`pwa/src/components/InstallBanner.tsx`)
- iOS variant: share icon (↑) + "Tap Share then 'Add to Home Screen'" text
- Android variant: "Install Sundee Fundee" heading + orange "Install" button
- Art Deco styling: cream (#F4F0DF) background, navy (#0D1A40) text, orange (#F2731A) CTA
- Fixed bottom positioning with subtle top shadow
- Accessible: `role="banner"`, `aria-label`, clear button labels
- `onAfterDismiss` callback — callers pass deferred navigation here

### Deferred navigation pattern (WorkoutSession + ProgramSession)
- After successful save: if `showPrompt` is true → store `() => navigate('/')` in `pendingNavigation` state; do NOT navigate
- `InstallBanner` renders when `pendingNavigation !== null && installPrompt.showPrompt`
- `onAfterDismiss` fires `pendingNavigation()` — navigation only happens after user interaction with banner

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] jsdom Storage.prototype.setItem spy unreliable in vitest**
- **Found during:** Task 1 (TDD GREEN phase)
- **Issue:** `vi.spyOn(Storage.prototype, 'setItem')` reported 0 calls in jsdom even when `sessionStorage.setItem` was being called — jsdom's in-memory storage does not route through `Storage.prototype`
- **Fix:** Updated test to assert `sessionStorage.getItem('installPromptDismissed') === '1'` after `dismiss()` — same behavioral contract, more reliable assertion mechanism
- **Files modified:** pwa/src/hooks/useInstallPrompt.test.ts
- **Commit:** bf88428

## Verification

- All 6 useInstallPrompt tests pass (GREEN)
- Full vitest suite: 779 tests pass across 18 test files
- TypeScript: clean compile (`npx tsc -b --noEmit` — no errors)
- Production build: `npm run build` succeeds (465 modules, manifest.webmanifest included)

## Pending

Task 3 (Lighthouse PWA audit) requires human verification:
- Deploy to production or run `cd pwa && npm run build && npx vite preview`
- Chrome DevTools → Application → Manifest (verify icons, installability)
- Chrome DevTools → Lighthouse → PWA audit (green installability checks)
- Offline test: DevTools → Network → Offline → navigate (branded offline page)
- Optional: complete a workout on Android/iOS to test install prompt end-to-end

## Self-Check

### Files Created
- pwa/src/hooks/useInstallPrompt.ts — FOUND
- pwa/src/components/InstallBanner.tsx — FOUND
- pwa/src/hooks/useInstallPrompt.test.ts — FOUND (modified)

### Commits
- bf88428 — feat(04-02): add useInstallPrompt hook, tests, and InstallBanner component — FOUND
- 2f652a2 — feat(04-02): wire install prompt into WorkoutSession and ProgramSession — FOUND

## Self-Check: PASSED
