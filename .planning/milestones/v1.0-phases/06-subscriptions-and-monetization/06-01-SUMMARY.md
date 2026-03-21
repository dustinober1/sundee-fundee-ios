---
phase: 06-analytics-seo
plan: 01
subsystem: analytics-seo
tags: [analytics, seo, og-tags, firebase-analytics]
dependency_graph:
  requires: []
  provides: [og-meta-tags, firebase-analytics-events]
  affects: [pwa/index.html, pwa/src/routes/SignIn.tsx, pwa/src/routes/WorkoutSession.tsx, pwa/src/entitlements/stripe-checkout.ts, pwa/src/routes/Settings.tsx]
tech_stack:
  added: []
  patterns: [firebase-analytics-logEvent, og-meta-tags, twitter-card]
key_files:
  created: [pwa/public/og-image.png]
  modified:
    - pwa/index.html
    - pwa/src/routes/SignIn.tsx
    - pwa/src/routes/WorkoutSession.tsx
    - pwa/src/entitlements/stripe-checkout.ts
    - pwa/src/routes/Settings.tsx
decisions:
  - All analytics logEvent calls use void (fire-and-forget) so analytics failures never block user flows
  - og-image.png reuses icon-512.png — no separate social preview image required for v1
  - login event used for sign-in (Firebase recommended name), sign_up for account creation
  - subscription_manage fires before portal redirect attempt so event is captured even if portal fails
metrics:
  duration: 106s
  completed_date: "2026-03-21"
  tasks_completed: 2
  files_modified: 6
---

# Phase 06 Plan 01: SEO Meta Tags and Firebase Analytics Events Summary

**One-liner:** OG/Twitter social preview tags in index.html and non-blocking Firebase Analytics events on sign-in, workout completion, and subscription actions.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Add OG and Twitter meta tags to index.html | ee32250 | pwa/index.html, pwa/public/og-image.png |
| 2 | Instrument key user actions with Firebase Analytics events | a3ad856 | SignIn.tsx, WorkoutSession.tsx, stripe-checkout.ts, Settings.tsx |

## What Was Built

**Task 1 — SEO Meta Tags:**
- Added `<meta name="description">` for organic search snippets
- Added Open Graph tags: `og:type`, `og:title`, `og:description`, `og:image`, `og:url`
- Added Twitter Card tags: `twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`
- Copied `icons/icon-512.png` to `public/og-image.png` for social sharing card image
- All tags reference `https://sundeefundee.com` as canonical URL

**Task 2 — Firebase Analytics Events:**
- **SignIn.tsx**: `sign_up` (email account creation), `login` with `method` param for email/google/apple/guest
- **WorkoutSession.tsx**: `workout_complete` with `exercise_count` and `duration_seconds` after successful save
- **stripe-checkout.ts**: `begin_checkout` with `price_id` before Stripe redirect
- **Settings.tsx**: `subscription_manage` before customer portal redirect

All logEvent calls are non-blocking (void) — analytics failures are silently swallowed and never disrupt user flows.

## Decisions Made

- **void logEvent pattern throughout:** Analytics must never block user actions. Used `void logEvent(...)` consistently across all call sites.
- **og-image.png = icon-512.png:** Reuse existing icon as social preview image for v1. No separate design asset needed.
- **Firebase recommended event names:** `login` (not `sign_in`) and `sign_up` (not `sign_up_success`) align with Firebase's predefined event schema for better DebugView and dashboard integration.
- **subscription_manage before portal redirect:** Event fires before `await redirectToCustomerPortal()` so the analytics event is always captured, even if the portal request fails.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `grep -c "og:title" pwa/index.html` → 1 (PASS)
- `grep -c "twitter:card" pwa/index.html` → 1 (PASS)
- `test -f pwa/public/og-image.png` → PASS
- All 4 source files contain logEvent calls (PASS)
- `npx tsc -b --noEmit` → clean (PASS)
- `npx vitest run` → 808 tests passed (PASS)

## Self-Check: PASSED

Files confirmed present:
- pwa/index.html — modified with OG/Twitter tags
- pwa/public/og-image.png — created
- pwa/src/routes/SignIn.tsx — logEvent calls present
- pwa/src/routes/WorkoutSession.tsx — logEvent call present
- pwa/src/entitlements/stripe-checkout.ts — logEvent call present
- pwa/src/routes/Settings.tsx — logEvent call present

Commits confirmed:
- ee32250: feat(06-01): add OG and Twitter meta tags to index.html
- a3ad856: feat(06-01): instrument key user actions with Firebase Analytics events
