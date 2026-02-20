---
phase: "06"
plan: "02"
name: "ios-meta-middleware-playwright"
subsystem: "pwa"
tags: ["pwa", "ios", "meta-tags", "middleware", "playwright", "next.js"]

one-liner: "iOS PWA meta tags in layout.tsx, middleware PWA exclusions, Playwright serviceWorkers block — all 11 E2E tests pass"

dependency-graph:
  requires:
    - "06-01: manifest.json and PWA icons"
  provides:
    - "iOS meta tags (apple-mobile-web-app-capable, title, status-bar-style)"
    - "Manifest link in HTML head"
    - "Apple touch icon link"
    - "Middleware excludes manifest.json, sw.js, workbox-*.js from auth"
    - "Playwright blocks service workers for E2E stability"
  affects:
    - "07-xx: Service worker introduction (middleware exclusions ready)"

tech-stack:
  added: []
  patterns:
    - "Next.js Metadata API appleWebApp + other for iOS dual capable tags"
    - "Middleware negative lookahead regex for PWA static file exclusions"

key-files:
  created: []
  modified:
    - "src/app/layout.tsx"
    - "middleware.ts"
    - "playwright.config.ts"

decisions:
  - id: "D1"
    choice: "Both appleWebApp.capable AND other['apple-mobile-web-app-capable']"
    rationale: "Next.js appleWebApp.capable generates W3C mobile-web-app-capable; Apple requires apple-mobile-web-app-capable with apple- prefix — both needed"
  - id: "D2"
    choice: "serviceWorkers: 'block' added before SW exists"
    rationale: "Guards all 11 E2E tests against future SW interference; safe to add now"

metrics:
  duration: "< 5 minutes"
  tasks-completed: 3
  tasks-total: 3
  tests-passed: 11
  tests-total: 11
  completed: "2026-02-20"
---

# Phase 6 Plan 02: iOS Meta Middleware Playwright Summary

## What Was Built

Added iOS PWA meta tags to `layout.tsx`, updated the Supabase auth middleware to exclude PWA static files, and added `serviceWorkers: 'block'` to `playwright.config.ts`. All 11 E2E tests confirmed passing.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add iOS meta tags and manifest link to layout.tsx | c45de96 | src/app/layout.tsx |
| 2 | Update middleware PWA exclusions and Playwright SW block | 0543973 | middleware.ts, playwright.config.ts |
| 3 | Run E2E tests to verify no regression | — (verification only) | — |

## Decisions Made

**D1: Dual iOS capable tags**
Next.js `appleWebApp.capable: true` generates `<meta name="mobile-web-app-capable">` (W3C standard) — NOT `apple-mobile-web-app-capable` (Apple-specific). The success criteria requires the `apple-` prefixed version, so it is added explicitly via `other: { 'apple-mobile-web-app-capable': 'yes' }`. Both tags coexist.

**D2: serviceWorkers: 'block' before SW exists**
Adding the Playwright guard now (before Phase 7 introduces a service worker) ensures all 11 existing tests are protected from day one and requires no future plan to retrofit it.

## Verification Results

```
✓ manifest.json in middleware exclusion regex
✓ serviceWorkers: 'block' in playwright.config.ts
✓ appleWebApp + manifest fields in layout.tsx
✓ 11/11 E2E tests passed
```

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

Phase 7 (Service Worker) can begin. Prerequisites satisfied:
- Middleware excludes `sw.js` and `workbox-*.js` from Supabase auth
- Playwright blocks service workers so E2E tests remain stable
- iOS meta tags and manifest link are in place
