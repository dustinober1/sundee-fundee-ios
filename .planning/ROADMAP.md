# Roadmap: Sundee Fundee PWA — Production Readiness

## Overview

The PWA is feature-complete with 25+ screens, offline support, and Firestore sync. This roadmap takes it from feature-complete to production-ready by working through six sequentially-dependent phases: deploy pipeline first (nothing ships without it), then backend Cloud Functions (AI + Stripe), then security hardening (Firestore rules + CSP), then PWA quality (icons, offline, install prompt), then error resilience and loading states, and finally analytics verification and SEO. Each phase unlocks the next — the order is not arbitrary, it reflects hard dependencies.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Deploy Pipeline** - Firebase Hosting config, GitHub Actions CI/CD, environment variables (completed 2026-03-21)
- [x] **Phase 2: Cloud Functions** - AI workout generation and Stripe checkout/webhook Cloud Functions (completed 2026-03-21)
- [ ] **Phase 3: Security Hardening** - Firestore rules, premiumEntitlement protection, CSP headers, rate limiting
- [ ] **Phase 4: PWA Quality** - Production icons, Lighthouse audit, offline fallback, install prompt
- [ ] **Phase 5: Error Resilience** - Error boundaries, skeleton loading states, 404 page
- [ ] **Phase 6: Analytics and SEO** - OG/Twitter meta tags, Firebase Analytics verification, component test coverage

## Phase Details

### Phase 1: Deploy Pipeline
**Goal**: The app is live at a production URL and auto-deploys on every push to main
**Depends on**: Nothing (first phase)
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04
**Success Criteria** (what must be TRUE):
  1. Visiting the production URL serves the app over HTTPS with no 404 on deep-link refreshes
  2. Pushing to main triggers a GitHub Actions run that runs tests, builds, and deploys — without manual intervention
  3. Running `firebase deploy` manually from a local machine succeeds as a fallback
  4. The deployed app uses real Firebase project credentials and the correct Stripe price ID (no placeholder values)
**Plans:** 2/2 plans complete

Plans:
- [x] 01-01-PLAN.md — Create firebase.json, GitHub Actions workflows, update .env.example
- [x] 01-02-PLAN.md — Set up secrets, DNS, service account, and verify pipeline end-to-end

### Phase 2: Cloud Functions
**Goal**: AI workout generation runs through a Firebase Cloud Function and Stripe checkout flow is backed by server-side functions
**Depends on**: Phase 1
**Requirements**: BACK-01, BACK-02, BACK-03
**Success Criteria** (what must be TRUE):
  1. Authenticated users can generate an AI workout via the Cloud Function; unauthenticated calls are rejected
  2. Clicking "Subscribe" creates a Stripe Checkout session and redirects the user to Stripe's hosted checkout page
  3. Completing a Stripe test checkout triggers the webhook, verifies the signature, and writes the `premiumEntitlement` field to Firestore
**Plans:** 3/3 plans complete

Plans:
- [x] 02-00-PLAN.md — Wave 0: Create test stubs for all Cloud Functions (Nyquist compliance)
- [x] 02-01-PLAN.md — Scaffold functions/ directory, implement generateAIWorkout, wire client
- [x] 02-02-PLAN.md — Implement Stripe checkout + portal + webhook functions, update deploy workflow

### Phase 3: Security Hardening
**Goal**: User data is protected by ownership-enforced Firestore rules and the app serves a Content Security Policy with known-safe domains
**Depends on**: Phase 2
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04
**Success Criteria** (what must be TRUE):
  1. Authenticated user A cannot read or write user B's Firestore documents (cycle data, pain logs, injury profiles)
  2. A client-side attempt to write the `premiumEntitlement` field directly to Firestore is rejected by security rules
  3. The app's HTTP response headers include a Content Security Policy that covers Firebase, Stripe, and Gemini domains without blocking any app functionality
  4. A single user cannot trigger more than 5 AI workout generations per day; the 6th attempt is rejected with an error
**Plans**: TBD

### Phase 4: PWA Quality
**Goal**: The app passes a Lighthouse PWA audit, shows production-quality icons, serves a branded offline page, and surfaces an install prompt
**Depends on**: Phase 3
**Requirements**: PWA-01, PWA-02, PWA-03, PWA-04
**Success Criteria** (what must be TRUE):
  1. The app's manifest icons include working 192px and 512px PNG files and Chrome's installability check passes
  2. A Lighthouse PWA audit run against the production URL shows green for installability, accessibility, and performance
  3. When the device goes offline, the service worker serves a branded offline page instead of a Chrome error screen
  4. Android users see an "Add to Home Screen" banner; iOS Safari users see an instructional prompt explaining how to install
**Plans**: TBD

### Phase 5: Error Resilience
**Goal**: Render errors, loading states, and unknown routes are handled gracefully — users never see a white screen or blank flash
**Depends on**: Phase 4
**Requirements**: UX-01, UX-02, UX-03
**Success Criteria** (what must be TRUE):
  1. A JavaScript render error on any route shows a recovery UI with a retry option instead of a white screen
  2. Navigating to Dashboard, Programs, History, Cycle, or Maxes before data loads shows shimmer skeleton cards, not blank space
  3. Navigating to an unknown URL shows a branded 404 page with a link back to the app
**Plans**: TBD

### Phase 6: Analytics and SEO
**Goal**: Firebase Analytics events fire correctly in production, social sharing shows proper previews, and critical user flows have component test coverage
**Depends on**: Phase 5
**Requirements**: QUAL-01, QUAL-02, QUAL-03
**Success Criteria** (what must be TRUE):
  1. Key user actions (sign in, workout complete, subscription start) appear as events in Firebase DebugView
  2. Sharing the app URL on Slack, iMessage, or Twitter shows a card with title, description, and image
  3. Component tests pass for the auth flow, workout session completion, and Stripe checkout trigger
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Deploy Pipeline | 2/2 | Complete   | 2026-03-21 |
| 2. Cloud Functions | 3/3 | Complete   | 2026-03-21 |
| 3. Security Hardening | 0/TBD | Not started | - |
| 4. PWA Quality | 0/TBD | Not started | - |
| 5. Error Resilience | 0/TBD | Not started | - |
| 6. Analytics and SEO | 0/TBD | Not started | - |
