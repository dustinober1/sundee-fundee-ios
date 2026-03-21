---
phase: 04-pwa-quality
plan: "00"
subsystem: testing
tags: [vitest, react-testing-library, tdd, pwa, install-prompt]

requires:
  - phase: 03-security-hardening
    provides: PWA security hardening complete, ready for feature development

provides:
  - Failing test scaffold for useInstallPrompt hook (6 test cases, RED phase)

affects:
  - 04-01 (implements useInstallPrompt hook to make these tests pass)

tech-stack:
  added: []
  patterns:
    - "TDD RED phase: write failing tests before implementation exists"
    - "renderHook + act from @testing-library/react for custom React hook testing"
    - "vi.fn() mocks for matchMedia, navigator.userAgent, sessionStorage"

key-files:
  created:
    - pwa/src/hooks/useInstallPrompt.test.ts
  modified: []

key-decisions:
  - "Test scaffold imports from ./useInstallPrompt (not yet created) — intentional RED state satisfying Nyquist rule"
  - "6 test cases cover: standalone detection, Android beforeinstallprompt capture, iOS user-agent detection, dismiss() + sessionStorage flag, isDismissed init from sessionStorage, triggerAndroid() calling prompt()"

patterns-established:
  - "TDD RED scaffold pattern: test file lives alongside implementation in pwa/src/hooks/"

requirements-completed: [PWA-04]

duration: 1min
completed: 2026-03-21
---

# Phase 4 Plan 00: PWA Install Prompt — Failing Test Scaffold

**6-test TDD RED scaffold for useInstallPrompt hook covering standalone detection, Android/iOS prompt capture, dismiss persistence, and triggerAndroid() call flow**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-21T19:34:09Z
- **Completed:** 2026-03-21T19:34:50Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created `pwa/src/hooks/` directory (did not exist)
- Wrote 6 failing test cases covering all useInstallPrompt behaviors
- Confirmed tests produce `1 failed` when run (RED state — module does not exist yet)
- Satisfied Nyquist rule: tests written before implementation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create failing test scaffold for useInstallPrompt** - `b7d0a71` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `pwa/src/hooks/useInstallPrompt.test.ts` - 6 test cases for install prompt hook (RED phase, failing by design)

## Decisions Made
None - followed plan as specified.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Failing test scaffold is in place for useInstallPrompt
- Plan 04-01 can implement the hook (GREEN phase) to make these tests pass
- Tests cover all specified behaviors from the phase context decisions

---
*Phase: 04-pwa-quality*
*Completed: 2026-03-21*
