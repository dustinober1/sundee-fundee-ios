---
phase: 08
plan: 01
subsystem: pwa-install
tags: [pwa, beforeinstallprompt, ios, install-prompt, hooks, components]
requires: [07-02]
provides: [INSTALL-01, INSTALL-02]
affects: [08-02]
tech-stack:
  added: []
  patterns: [beforeinstallprompt-deferral, ios-ua-detection, standalone-mode-guard, localstorage-dismiss]
key-files:
  created:
    - src/hooks/use-install-prompt.ts
    - src/components/pwa/install-prompt-banner.tsx
    - src/components/pwa/ios-install-modal.tsx
  modified:
    - src/app/dashboard/page.tsx
decisions:
  - id: d1
    summary: "iOS modal localStorage handling stays in hook (not component)"
    rationale: "Centralises dismiss state; component only calls onDismiss() callback — hook owns persistence"
  - id: d2
    summary: "IosInstallModal mounted on dashboard page (not layout root)"
    rationale: "Consistent placement with InstallPromptBanner; only shows once after PWA criteria met"
  - id: d3
    summary: "Standalone mode guard inside useInstallPrompt useEffect"
    rationale: "Prevents install banner from appearing when app already running from home screen"
metrics:
  duration: "~2 minutes"
  completed: "2026-02-20"
---

# Phase 8 Plan 01: PWA Install Experience Summary

**One-liner:** Android `beforeinstallprompt` deferral hook + iOS A2HS modal wired to dashboard (INSTALL-01, INSTALL-02).

## What Was Built

Two hooks and two components implementing the full PWA install experience:

- **`useInstallPrompt`** — captures and defers the `beforeinstallprompt` event (Android/Chrome), exposes `canInstall`, `promptInstall()`, and `dismiss()`. Guards against already-installed standalone mode and localStorage-persisted dismissal.
- **`useIsIosInstallable`** — detects iOS Safari + not standalone + not dismissed, returns `showIosPrompt` boolean and `dismissIos()` function.
- **`InstallPromptBanner`** — renders a lightweight banner CTA when `canInstall` is true (returns null otherwise); uses `Download` and `X` from lucide-react.
- **`IosInstallModal`** — shadcn `Dialog` with ordered step-by-step Share → Add to Home Screen instructions; uses `Share` and `PlusSquare` icons.
- **Dashboard integration** — both components rendered after `<OfflineBanner />` inside `<FadeIn>` wrapper.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create useInstallPrompt + useIsIosInstallable hooks | 11222be | src/hooks/use-install-prompt.ts |
| 2 | Create install banner + iOS modal; integrate on dashboard | 1a72d2d | src/components/pwa/install-prompt-banner.tsx, ios-install-modal.tsx, src/app/dashboard/page.tsx |

## Verification Results

| Check | Result |
|-------|--------|
| `npx tsc --noEmit` (src/ only) | ✅ 0 errors |
| `npm run build` | ✅ Compiled + 45 precache entries |
| `npx playwright test` | ✅ 11/11 passed |
| `grep InstallPromptBanner src/` | ✅ Import + render in dashboard/page.tsx |
| `grep IosInstallModal src/` | ✅ Import + render in dashboard/page.tsx |
| `grep beforeinstallprompt src/` | ✅ Listener in use-install-prompt.ts |
| No inline SVG in pwa/ | ✅ All icons from lucide-react |

## Decisions Made

1. **iOS localStorage handling owned by hook** — `IosInstallModal` calls `onDismiss()` only; the hook's `dismiss()` sets localStorage. This keeps persistence logic in one place.
2. **Dashboard page mount point** — both install components render on the dashboard page (not root layout), matching the plan's recommendation for consistent placement.
3. **Standalone guard in useEffect** — `window.matchMedia('(display-mode: standalone)').matches` checked inside `useEffect` to avoid SSR crash; banner won't flash before check resolves because `deferredPrompt` starts null.

## Deviations from Plan

None — plan executed exactly as written. The research patterns in `08-RESEARCH.md` were used verbatim for the hook implementation.

## Authentication Gates

None.

## Next Phase Readiness

- **Phase 08 Plan 02 (ICON-01–04):** Ready. Install hooks/components are independent. Icon enrichment can proceed on `offline-banner.tsx`, dashboard card headers, workout components, and bottom nav.
- **No blockers.**
