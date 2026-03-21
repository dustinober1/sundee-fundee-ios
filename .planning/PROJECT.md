# Sundee Fundee PWA — Production Readiness

## What This Is

A production-ready PWA (Vite + React + Firebase) for the Sundee Fundee strength training app with hormonal-cycle-aware training. The PWA is deployed with CI/CD, real Stripe payments, AI workout generation via Firebase Cloud Functions, security-hardened Firestore, and production-grade UX polish — ready for real users.

## Core Value

Users can reliably access Sundee Fundee from any browser, with real payments, real AI workouts, and production-grade reliability — this is the primary platform, not a companion.

## Requirements

### Validated

- ✓ Firebase Hosting deployment pipeline with CI/CD — v1.0
- ✓ GitHub Actions CI/CD (build + deploy on push to main) — v1.0
- ✓ Real environment variables (Firebase keys, Stripe price ID, auth domain) — v1.0
- ✓ Production PWA icons (192px, 512px) verified and production-quality — v1.0
- ✓ Firebase Cloud Function for AI workout generation (replacing Cloudflare worker) — v1.0
- ✓ Stripe checkout end-to-end (real price ID, success/cancel URLs, webhook for entitlement) — v1.0
- ✓ Firestore security rules with per-user ownership enforcement — v1.0
- ✓ premiumEntitlement write protection in Firestore rules — v1.0
- ✓ Content Security Policy headers — v1.0
- ✓ AI workout rate limiting (5 per user per day) — v1.0
- ✓ React error boundaries for graceful crash recovery — v1.0
- ✓ Skeleton loading states on all data-fetching routes — v1.0
- ✓ Component test coverage for critical flows (auth, workout session, checkout) — v1.0
- ✓ Firebase Analytics events verified firing — v1.0
- ✓ SEO meta tags (og:title, og:description, og:image, twitter:card) — v1.0
- ✓ Lighthouse PWA audit pass — v1.0
- ✓ Custom offline fallback page — v1.0
- ✓ "Add to Home Screen" install prompt — v1.0
- ✓ Branded 404 page for unknown routes — v1.0
- ✓ 25+ screens (dashboard, programs, workouts, cycle, history, settings) — existing
- ✓ Offline support via service worker (vite-plugin-pwa) — existing
- ✓ Firestore data sync for authenticated users — existing
- ✓ Firebase Auth (email/password, Google, Apple, guest mode) — existing

### Active

(None — next milestone requirements TBD via `/gsd:new-milestone`)

### Out of Scope

- SSR / pre-rendering — app is auth-gated; static OG tags sufficient for SEO
- Custom Stripe Elements — Stripe Checkout redirect is simpler, PCI-compliant by default
- HSTS preloading — Firebase Hosting auto-configures HSTS; preload submission is irreversible
- Native iOS app changes — this milestone was PWA-only
- WOD admin dashboard changes — separate codebase
- Migrating away from Firebase — staying on Firebase ecosystem
- HealthKit integration — browser-only, no native health data access

## Context

Shipped v1.0 with 17,846 LOC TypeScript (16,832 PWA + 1,014 Cloud Functions).
Tech stack: Vite 8 + React 19 + TypeScript 5.9 + Firebase (Hosting, Firestore, Auth, Functions) + Stripe.
PWA lives in `pwa/` directory; Cloud Functions in `functions/`.
Native iOS app (Swift/SwiftUI) exists in parallel but PWA is the primary platform going forward.
Domain logic is pure TypeScript in `src/domain/` — well-tested.

## Constraints

- **Backend**: Firebase ecosystem (Hosting, Firestore, Auth, Functions) — no new providers
- **Payments**: Stripe for web (StoreKit 2 stays iOS-only)
- **AI Provider**: Gemini via Firebase Cloud Function
- **Scope**: Production readiness shipped; next milestone TBD

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Firebase Functions for AI workouts | Already on Firebase; consolidates infrastructure vs. keeping Cloudflare worker | ✓ Good — single deploy target, auth gating built in |
| Stripe for PWA payments | StoreKit 2 is Apple-only; Stripe is already stubbed in PWA code | ✓ Good — checkout + webhook + portal all working |
| GitHub Actions + manual script | CI/CD automation with manual fallback; both built as part of this work | ✓ Good — reliable deploy pipeline |
| Three separate workflow files | CI, preview, deploy separation of concerns vs. monolith | ✓ Good — clear responsibilities |
| Production deploy is manual workflow_dispatch | Safety gate vs. auto-deploy on push | ✓ Good — prevents accidental production deploys |
| Firestore transaction rate limit | Atomic counter at users/{uid}/rateLimits/aiWorkout | ✓ Good — prevents race conditions |
| CSP uses 'unsafe-inline' | Required for Vite/React SPA without SSR nonce injection | ⚠️ Revisit — explore nonce injection if SSR added |
| Separate create/update Firestore rules | resource.data is null on create so two patterns required | ✓ Good — comprehensive field-level protection |
| Root package.json for rules tests | Independent from pwa/ vitest and functions/ jest suites | ✓ Good — isolation prevents test interference |
| Jest with ts-jest for Cloud Functions | functions/ is independent of PWA's vitest | ✓ Good — each project uses its own test runner |
| sharp for icon generation | Generate 192/512 PNGs from SVG at build time | ✓ Good — deterministic, no manual design work |
| Deferred install prompt navigation | pendingNavigation pattern prevents component unmount during banner interaction | ✓ Good — smooth UX flow |
| void logEvent pattern | Analytics must never block user actions | ✓ Good — fire-and-forget |
| --only firestore:rules not --only firestore | firestore.indexes.json does not exist; full deploy would fail | ✓ Good — discovered during gap closure |

---
*Last updated: 2026-03-21 after v1.0 milestone*
