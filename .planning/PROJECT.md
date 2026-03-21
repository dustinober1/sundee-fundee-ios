# Sundee Fundee PWA — Production Readiness

## What This Is

A production readiness push for the Sundee Fundee PWA (Vite + React + Firebase), the primary platform for the strength training app with hormonal-cycle-aware training. The PWA is feature-complete with 25+ screens, offline support, and Firestore sync — but needs deployment infrastructure, real credentials, security hardening, test coverage, and polish before shipping to real users.

## Core Value

Users can reliably access Sundee Fundee from any browser, with real payments, real AI workouts, and production-grade reliability — this is the primary platform, not a companion.

## Requirements

### Validated

<!-- Existing PWA capabilities confirmed from codebase map -->

- ✓ 25+ screens implemented (dashboard, programs, workouts, cycle, history, settings, etc.) — existing
- ✓ Offline support via service worker (vite-plugin-pwa) — existing
- ✓ Firestore data sync for authenticated users — existing
- ✓ Firebase Auth (email/password, Google, Apple, guest mode) — existing
- ✓ Drag-and-drop reorder for workout exercises — existing
- ✓ SVG charts for progress visualization (Recharts) — existing
- ✓ AI workout generation (offline fallback) — existing
- ✓ CSV/ZIP data export — existing
- ✓ Cycle tracking with phase-aware recommendations — existing
- ✓ Injury adaptation engine — existing
- ✓ Benchmark tracking and scoring — existing
- ✓ Art Deco theme (cream/navy/orange) — existing
- ✓ Vitest test suite — existing

### Active

<!-- Production readiness items — all 17 from triage -->

- [ ] Firebase Hosting deployment pipeline with deploy script
- [ ] GitHub Actions CI/CD (build + deploy on push to main)
- [ ] Real environment variables (Firebase keys, Stripe price ID, auth domain)
- [ ] Production PWA icons (192px, 512px) verified and production-quality
- [ ] Firebase Cloud Function for AI workout generation (replacing Cloudflare worker)
- [ ] Stripe checkout end-to-end (real price ID, success/cancel URLs, webhook for entitlement)
- [ ] Firestore security rules audit and lockdown
- [ ] React error boundaries for graceful crash recovery
- [ ] Loading/skeleton states on all data-fetching routes
- [ ] Component test coverage for critical flows (auth, workout session, checkout)
- [ ] Analytics verification (Firebase events firing correctly)
- [ ] SEO/meta tags (og:tags, description, title for link sharing)
- [ ] Lighthouse PWA audit (accessibility, performance, PWA compliance)
- [ ] Custom offline fallback page
- [ ] "Add to Home Screen" install prompt
- [ ] Rate limiting on Firestore reads and AI generation
- [ ] Content Security Policy headers
- [ ] 404 page for unknown routes

### Out of Scope

- Native iOS app changes — this milestone is PWA-only
- WOD admin dashboard changes — separate codebase
- New feature development — strictly production readiness of existing features
- Migrating away from Firebase — staying on Firebase ecosystem
- HealthKit integration — browser-only, no native health data access

## Context

- PWA lives in `pwa/` directory, built with Vite 8 + React 19 + TypeScript 5.9
- Firebase project already exists with Firestore, Auth, and Cloud Functions
- Cloudflare worker proxy at `workout-proxy.sundeefundee.workers.dev/generate-workout` handles AI generation — will be replaced by Firebase Cloud Function
- Stripe is stubbed in code but uses placeholder price IDs
- Native iOS app (Swift/SwiftUI) exists in parallel but PWA is the primary platform going forward
- Domain logic is pure TypeScript in `src/domain/` — already well-tested

## Constraints

- **Backend**: Firebase ecosystem (Hosting, Firestore, Auth, Functions) — no new providers
- **Payments**: Stripe for web (StoreKit 2 stays iOS-only)
- **AI Provider**: Gemini via Firebase Cloud Function (replacing Cloudflare worker)
- **Timeline**: Weeks out — want it solid before shipping, no hard deadline
- **Scope**: All 17 triage items must be complete before launch

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Firebase Functions for AI workouts | Already on Firebase; consolidates infrastructure vs. keeping Cloudflare worker | — Pending |
| Stripe for PWA payments | StoreKit 2 is Apple-only; Stripe is already stubbed in PWA code | — Pending |
| GitHub Actions + manual script | CI/CD automation with manual fallback; both built as part of this work | — Pending |
| All 17 items before launch | PWA is primary platform — quality bar must be high | — Pending |

---
*Last updated: 2026-03-21 after initialization*
