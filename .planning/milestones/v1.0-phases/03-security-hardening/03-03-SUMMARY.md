---
phase: 03-security-hardening
plan: 03
subsystem: firebase-hosting
tags: [security, csp, headers, firestore-rules]
dependency_graph:
  requires: [03-01, 03-02]
  provides: [SEC-03]
  affects: [firebase-hosting, firestore-rules-deployment]
tech_stack:
  added: []
  patterns: [content-security-policy, security-headers, firebase-hosting-headers]
key_files:
  created: []
  modified:
    - firebase.json
decisions:
  - "CSP uses 'unsafe-inline' in script-src and style-src — required for Vite/React SPA without SSR nonce injection"
  - "CSP header placed on wildcard source '**' before specific Cache-Control headers — Firebase Hosting evaluates more-specific patterns first"
  - "Firestore rules wired into firebase.json firestore block so rules deploy alongside hosting via single firebase deploy command"
metrics:
  duration: "~20min (including deploy + verification)"
  completed: "2026-03-21"
  tasks_completed: 2
  tasks_total: 2
requirements:
  - SEC-03
---

# Phase 3 Plan 3: CSP and Security Headers Summary

**One-liner:** Content Security Policy with Firebase/Stripe/Cloud Functions coverage deployed to Firebase Hosting, plus Firestore rules wired into firebase.json for unified deployment.

## What Was Built

Added three HTTP security headers to Firebase Hosting and wired Firestore rules into the deploy config:

1. **Content-Security-Policy** — Restricts script, style, font, image, connect, and frame sources to known-safe domains (Firebase Auth/Firestore, Stripe Checkout, Cloud Functions, Google Fonts)
2. **X-Frame-Options: SAMEORIGIN** — Prevents clickjacking by blocking iframe embedding from foreign origins
3. **X-Content-Type-Options: nosniff** — Prevents MIME-type sniffing attacks
4. **Firestore rules reference** — `"firestore": { "rules": "firestore.rules" }` block added so `firebase deploy` also deploys security rules

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add CSP, X-Frame-Options, X-Content-Type-Options, and Firestore rules reference to firebase.json | 39f18bf | firebase.json |
| 2 | Verify CSP does not block app functionality after deploy (checkpoint: human-verify) | — | — |

## Verification Results

All three headers confirmed live via `curl -sI https://sundeefundee.web.app/`:
- `content-security-policy` — present
- `x-frame-options: SAMEORIGIN` — present
- `x-content-type-options: nosniff` — present

Browser test via Playwright: ZERO CSP violations. Only pre-existing Firebase API key expiry errors (unrelated to CSP, pre-existing condition).

## CSP Coverage

| Directive | Allowed Sources |
|-----------|----------------|
| default-src | 'self' |
| script-src | 'self' 'unsafe-inline' https://checkout.stripe.com |
| style-src | 'self' 'unsafe-inline' https://fonts.googleapis.com |
| font-src | 'self' https://fonts.gstatic.com |
| img-src | 'self' data: https://*.stripe.com |
| connect-src | 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firestore.googleapis.com https://checkout.stripe.com https://q.stripe.com https://r.stripe.com https://us-central1-sundee-fundee.cloudfunctions.net |
| frame-src | https://checkout.stripe.com |
| object-src | 'none' |
| base-uri | 'self' |

## Deviations from Plan

None — plan executed exactly as written.

## Auth Gates

None.

## Self-Check: PASSED

- firebase.json modified with CSP, X-Frame-Options, X-Content-Type-Options: confirmed (commit 39f18bf exists)
- Live headers verified by user via curl and Playwright browser test
- No CSP violations found in browser DevTools
