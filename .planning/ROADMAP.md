# Roadmap: Sundee Fundee — React Native Rewrite

## Overview

This roadmap covers the full rewrite of Sundee Fundee from native iOS (Swift 6 + SwiftUI) to React Native + Expo, targeting iOS, Android, and Web. The build follows a strict dependency order: infrastructure and auth first, then the pure TypeScript domain layer, then the data/repository layer, then the core workout loop, then differentiating features, then subscriptions, and finally platform polish before launch. Each phase delivers a verifiable capability; no phase delivers a collection of unrelated tasks. The result is a cross-platform app where users get cycle-aware, injury-modified, AI-enhanced strength training that works offline on any device.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation and Infrastructure** - Firebase, Auth, EAS build, security rules, RevenueCat + Stripe pipeline
- [ ] **Phase 2: Domain Layer Port** - Full TypeScript port of all iOS domain logic with 100% test coverage
- [x] **Phase 3: Data Layer and Offline Architecture** - Repository interfaces, Firestore + AsyncStorage implementations, offline guarantee (completed 2026-03-14)
- [x] **Phase 4: Core Workout Loop** - Exercise library, workout logging, timers, PR detection, history, progress charts (completed 2026-03-15)
- [ ] **Phase 5: Differentiating Features** - Cycle tracking/adaptation, injury engine, AI workouts, programs, benchmarks, WODs, readiness
- [x] **Phase 6: Subscriptions and Monetization** - RevenueCat paywall, Stripe web checkout, entitlement gates, account management (completed 2026-03-15)
- [x] **Phase 7: Polish and Pre-Launch** - Art Deco refinement, Android adaptations, App Check, security audit, data export, app store submission (completed 2026-03-15)

## Phase Details

### Phase 1: Foundation and Infrastructure
**Goal**: The app boots, users can authenticate on all platforms, data is secured, and the subscription entitlement pipeline is live
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07, PLAT-01, PLAT-02, PLAT-03
**Success Criteria** (what must be TRUE):
  1. User can sign up with email/password, sign in with Apple (iOS), sign in with Google (Android + Web), or continue as a guest — all from a single auth screen
  2. User session persists across app restarts without requiring re-authentication
  3. User can sign out from the settings screen on any platform
  4. Authenticated user data syncs to Firestore and is visible on a second device after sign-in
  5. EAS development build runs on iOS Simulator, Android Emulator, and web — React Native Firebase SDK is used (not JS SDK); Expo Go is not used at any point
**Plans:** 3/3 plans complete

Plans:
- [x] 01-01-PLAN.md — Scaffold Expo project with Firebase, EAS, Firestore rules, RevenueCat, and test infrastructure
- [x] 01-02-PLAN.md — Build auth layer: SessionProvider, auth hooks (Apple, Google, Email, Guest), and tests
- [x] 01-03-PLAN.md — Build auth UI, protected routes, tab shell, settings with sign-out, and cross-platform verification

### Phase 2: Domain Layer Port
**Goal**: All iOS business logic exists as tested TypeScript with verified numeric/date parity against the Swift originals
**Depends on**: Phase 1
**Requirements**: CYAD-01, CYAD-02, CYAD-03, INJR-02, INJR-04, INJR-05, INJR-06, WORK-06, MAX-03
**Success Criteria** (what must be TRUE):
  1. Cycle phase inference produces identical output to Swift baseline for any given period log sequence (verified by parity test suite with shared inputs)
  2. Injury adaptation engine correctly substitutes or removes contraindicated exercises for every body location and recovery phase combination (unit tested)
  3. Benchmark scoring (ForTime, AMRAP roundsAndReps, MaxLoad) produces identical numeric results to Swift implementation with no floating-point drift
  4. 1RM estimation formulas (Epley, Brzycki, etc.) match Swift outputs to at least 4 decimal places on 50+ test cases
  5. All ported domain files have 100% line coverage in Jest; CI enforces coverage threshold
**Plans:** 5 plans

Plans:
- [ ] 02-01-PLAN.md — Install date-fns, define shared domain types, port calculations subdomain with parity fixtures
- [ ] 02-02-PLAN.md — Port cycle domain (CycleCalculations, CycleAdaptationPolicy, CycleProgramGenerator)
- [ ] 02-03-PLAN.md — Port injury domain (InjuryAdaptationEngine, PainTrendAnalyzer, PhaseTransitionAdvisor, RehabSessionGenerator)
- [ ] 02-04-PLAN.md — Port AI workout, benchmarks, readiness, history, shared modules, and create top-level barrel
- [ ] 02-05-PLAN.md — Gap closure: fix barrel re-exports and add types test coverage

### Phase 3: Data Layer and Offline Architecture
**Goal**: All data access goes through typed repository interfaces; Firestore and AsyncStorage implementations are swappable; offline workout logging is guaranteed with no data loss
**Depends on**: Phase 2
**Requirements**: ONBD-01, ONBD-02, ONBD-03, WORK-11, AUTH-07
**Success Criteria** (what must be TRUE):
  1. User completes onboarding (name, experience, goal, gender, cycle opt-in) and data persists in Firestore after authentication or locally for guest
  2. Onboarding skips cycle-related steps for users who do not opt in (or for male-identified users)
  3. Workout log written in airplane mode appears in history after reconnection without any data loss or user action
  4. Guest user's locally stored data is accessible without network; authenticated user's data loads from Firestore offline persistence on first offline session
  5. Repository factory correctly returns Firestore implementations for authenticated users and AsyncStorage implementations for guest users — verified by integration test with Firebase emulator
**Plans:** 2/2 plans complete

Plans:
- [ ] 03-01-PLAN.md — Build all repository interfaces, dual implementations (Firestore + AsyncStorage), factory functions, migration helper, web persistence, and tests
- [ ] 03-02-PLAN.md — Build 5-step onboarding flow UI, wire into root layout with completion gate, and verify end-to-end

### Phase 4: Core Workout Loop
**Goal**: Users can log any workout, execute timed workouts, and see their progress — entirely offline if needed
**Depends on**: Phase 3
**Requirements**: WORK-01, WORK-02, WORK-03, WORK-04, WORK-05, WORK-06, WORK-07, WORK-08, WORK-09, WORK-10, WORK-12, EXEC-01, EXEC-02, EXEC-03, EXEC-04, MAX-01, MAX-02, MAX-03
**Success Criteria** (what must be TRUE):
  1. User can log sets with reps and weight for any exercise from a 200+ exercise library, including custom exercises they created, with no network connection required
  2. Rest timer counts down between sets, continues while the screen is locked, and survives the app being backgrounded — confirmed on both iOS and Android
  3. ForTime, AMRAP, and EMOM workout timers all function correctly; timer state survives screen lock on iOS and Android
  4. App automatically detects and displays a personal record notification when a set completion exceeds the user's previous best weight for that exercise
  5. User can view workout history filtered by source (AI, Program, Custom), delete individual workouts, view per-exercise progress charts, and track 1RM history over time
**Plans:** 8/8 plans complete

Plans:
- [ ] 04-01-PLAN.md — Install deps, create exercise catalog with search/filter, timer domain types, workout session and PR detection contracts
- [ ] 04-02-PLAN.md — TDD: PR detection logic (multi-rep-range) and workout session state management (add/remove/complete/reorder)
- [ ] 04-03-PLAN.md — ExerciseRepo + ExerciseMaxRepo with dual implementations, expand WorkoutRecord for custom workouts
- [ ] 04-04-PLAN.md — Expand history with 'custom' source, filtering, date grouping, progress chart data preparation
- [ ] 04-05-PLAN.md — Workout logging UI: exercise picker, session screen, set rows, rest timer bar, PR toast
- [ ] 04-06-PLAN.md — Timed workout modes: ForTime/AMRAP/EMOM timer hook, 3-2-1-Go countdown, full-screen timer UI
- [ ] 04-07-PLAN.md — History tab, Maxes tab, workout detail, exercise detail with 1RM charts and rep-range PRs
- [ ] 04-08-PLAN.md — Wire tabs + modals, dashboard entry points, settings rest timer, end-to-end verification checkpoint

### Phase 5: Differentiating Features
**Goal**: Cycle-aware training adaptation, injury modification, AI workout generation, programs, benchmarks, WODs, and readiness are all live and integrated
**Depends on**: Phase 4
**Requirements**: CYCL-01, CYCL-02, CYCL-03, CYCL-04, CYCL-05, CYAD-01, CYAD-02, CYAD-03, READ-01, READ-02, INJR-01, INJR-02, INJR-03, INJR-04, INJR-05, INJR-06, AIWK-01, AIWK-02, AIWK-03, AIWK-04, AIWK-05, PROG-01, PROG-02, PROG-03, PROG-04, BNCH-01, BNCH-02, BNCH-03, BNCH-04, WODS-01, WODS-02
**Success Criteria** (what must be TRUE):
  1. User who opted into cycle tracking can log period dates, view their inferred current phase and predicted upcoming phases, and see workout load/set/rep targets automatically adjusted for that phase — users who skipped opt-in see none of this
  2. User with an active injury profile sees contraindicated exercises automatically substituted or removed from any workout; pain level logging and pain trend insights are accessible from the injury profile screen
  3. User can generate an AI workout specifying time, focus, equipment, and energy level — the workout incorporates their current cycle phase, active injuries, and readiness score; when offline, a templated fallback workout is generated instead
  4. User can browse the program catalog from Firestore, enroll in a program, and see current session exercises with target weights calculated from their logged 1RMs
  5. User can browse the benchmark catalog, record a result with correct scoring format (ForTime time, AMRAP rounds+reps, MaxLoad weight), view their improvement history, and create custom benchmarks; daily WOD from Firestore is visible on the home feed
**Plans:** 6/9 plans executed

Plans:
- [ ] 05-01-PLAN.md — Create all 5 repositories (Cycle, Injury, Program, Benchmark, WOD) with dual implementations and tests
- [ ] 05-02-PLAN.md — Migrate Cloud Function from Anthropic to Gemini with minInstances and JSON response mode
- [ ] 05-03-PLAN.md — Build readiness survey UI (dashboard card + modal) and integrate into dashboard
- [ ] 05-04-PLAN.md — Build Cycle tab with period calendar, phase banner, 2-cycle forecast, conditional tab visibility
- [ ] 05-05-PLAN.md — Build injury management: body map, injury profile, pain logging, trend chart, rehab, transition advice
- [ ] 05-06-PLAN.md — Build program catalog, enrollment with 1RM prompt, and active session with target weights
- [ ] 05-07-PLAN.md — Build benchmark catalog with scoring-aware recording, history charts, custom creation, and WOD display
- [ ] 05-08-PLAN.md — Build AI workout generation flow: config cards, adaptation context, Cloud Function call, offline fallback, preview
- [ ] 05-09-PLAN.md — Wire dashboard integration, workout session adaptation indicators, and end-to-end verification

### Phase 6: Subscriptions and Monetization
**Goal**: Users can subscribe via in-app purchase or Stripe web checkout; premium features are gated; entitlements are unified across platforms
**Depends on**: Phase 5
**Requirements**: SUBS-01, SUBS-02, SUBS-03, SUBS-04, SUBS-05
**Success Criteria** (what must be TRUE):
  1. User on iOS or Android can subscribe via the App Store or Google Play through RevenueCat paywall; subscription status is immediately reflected without restart
  2. User on web can subscribe via Stripe checkout at a lower price point; entitlements sync to RevenueCat within 60 seconds of successful payment
  3. Premium features (cycle adaptation, AI workout generation) are inaccessible to free users; the paywall screen is shown without blocking the first workout attempt
  4. Subscribed user can view, change, or cancel their subscription from the settings screen; restore purchases works after reinstall
  5. Subscription entitlements are consistent across all platforms for the same Firebase UID — a user who subscribed on web has premium access on iOS and Android
**Plans:** 3/3 plans complete

Plans:
- [ ] 06-01-PLAN.md — Build Stripe Cloud Functions (createCheckoutSession + stripeWebhook) with RC entitlement bridge and tests
- [ ] 06-02-PLAN.md — Upgrade useEntitlements hook with real-time listener, wire RC logIn to auth, build PaywallModal and PremiumBadge
- [ ] 06-03-PLAN.md — Gate 4 premium features, add Settings subscription management, trial banner, and trial-ended modal

### Phase 7: Polish and Pre-Launch
**Goal**: The app looks and feels correct on iOS, Android, and Web; sensitive data is secured; users can manage their data; the app passes App Store and Play Store review
**Depends on**: Phase 6
**Requirements**: PLAT-04, PLAT-05, PLAT-06, PLAT-07
**Success Criteria** (what must be TRUE):
  1. Art Deco design (cream/navy/orange palette) renders consistently across iOS and Android; Android navigation conventions (back gesture, bottom sheet behavior, keyboard handling) feel native and correct
  2. User can switch between lbs and kg in settings; all logged values and displayed targets update immediately throughout the app
  3. User can export their workout data as CSV or JSON from the settings screen; the exported file contains complete workout history
  4. User can delete their account from settings, which triggers full data wipe from Firestore and revokes Firebase Auth; the app returns to the sign-in screen
  5. App passes Firebase App Check validation (DeviceCheck on iOS, Play Integrity on Android); Firestore security rules audit shows no public access to any user health data collection
**Plans:** 3/3 plans complete

Plans:
- [ ] 07-01-PLAN.md — Weight unit switching (formatWeight utility + Settings toggle + app-wide threading) and Firebase App Check init
- [ ] 07-02-PLAN.md — Data export module (CSV formatters for all data types, JSON export, zip bundling, cross-platform sharing)
- [ ] 07-03-PLAN.md — Account deletion Cloud Function, stripeWebhook fix, Settings export/delete UI, goodbye screen, Art Deco polish

### Phase 8: Fix Cycle Adaptation Wiring
**Goal:** Cycle-aware workout load adjustment actually activates for users who opted into cycle tracking
**Requirements:** CYAD-01, CYAD-02, CYAD-03
**Gap Closure:** Closes gaps from audit — replace dead `cycleTrackingEnabled` gate with `profile?.cycleOptIn === true`
**Plans:** 1/1 plans complete

Plans:
- [ ] 08-01-PLAN.md — Fix cycle adaptation gates in workout-session and dashboard, add gate logic tests

### Phase 9: Fix Guest Migration + AI Profile Wiring
**Goal:** Guest-to-auth upgrade preserves all user data; AI workouts use real user profile instead of hardcoded values
**Requirements:** AUTH-07, AIWK-02
**Gap Closure:** Closes gaps from audit — call migrateGuestDataToFirestore after linkWithCredential; read profile in AI workout config
**Plans:** 2/2 plans complete

Plans:
- [ ] 09-01-PLAN.md — Expand migration to 13 keys with multi-batch support, wire into upgrade() and add _layout.tsx retry
- [ ] 09-02-PLAN.md — Wire real user profile, settings, maxes, and recent workouts into AI workout config

### Phase 10: UI Polish Fixes
**Goal:** Historical weight display respects user unit preference; goodbye screen has proper navigation; web export bundles into zip
**Requirements:** PLAT-05
**Gap Closure:** Closes tech debt from audit — formatWeight in detail views, goodbye.tsx Stack.Screen, web CSV zip
**Plans:** 1/1 plans complete

Plans:
- [ ] 10-01-PLAN.md — Fix formatWeight in workout detail, add goodbye Stack.Screen, bundle web CSV export into zip

### Phase 11: Wire Guest Upgrade Entry Point
**Goal:** Guest users who sign up retain all their locally stored data instead of starting fresh
**Requirements:** AUTH-07
**Gap Closure:** Closes gaps from audit — sign-in.tsx auth handlers must detect anonymous user and call guest.upgrade(credential) instead of creating new accounts
**Plans:** 1/1 plans complete

Plans:
- [ ] 11-01-PLAN.md — Refactor auth hooks to expose getCredential, wire isAnonymous guard into sign-in.tsx handlers, add tests

### Phase 12: Fix Firestore Pain Log Security Rules
**Goal:** Authenticated users can persist pain logs to Firestore; pain trend analysis receives real data
**Requirements:** INJR-03, INJR-04
**Gap Closure:** Closes gaps from audit — Firestore security rules must allow writes to 2-level nested subcollections (injuries/{id}/painLogs/{id})
**Plans:** 1/1 plans complete

Plans:
- [x] 12-01-PLAN.md — Add nested painLogs match block to firestore.rules and security rule tests

### Phase 13: Complete Weight Unit Threading
**Goal:** All screens display weights in the user's chosen unit (lbs or kg) with no hardcoded suffixes
**Requirements:** PLAT-05
**Gap Closure:** Closes gaps from audit — thread weightUnit into HistoryCard.tsx and exercise-detail.tsx

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Infrastructure | 3/3 | Complete   | 2026-03-14 |
| 2. Domain Layer Port | 5/5 | Complete   | 2026-03-14 |
| 3. Data Layer and Offline Architecture | 2/2 | Complete   | 2026-03-14 |
| 4. Core Workout Loop | 8/8 | Complete   | 2026-03-15 |
| 5. Differentiating Features | 9/9 | Complete   | 2026-03-15 |
| 6. Subscriptions and Monetization | 3/3 | Complete   | 2026-03-15 |
| 7. Polish and Pre-Launch | 3/3 | Complete   | 2026-03-15 |
| 8. Fix Cycle Adaptation Wiring | 1/1 | Complete   | 2026-03-15 |
| 9. Fix Guest Migration + AI Profile Wiring | 2/2 | Complete   | 2026-03-15 |
| 10. UI Polish Fixes | 1/1 | Complete    | 2026-03-15 |
| 11. Wire Guest Upgrade Entry Point | 1/1 | Complete    | 2026-03-15 |
| 12. Fix Firestore Pain Log Security Rules | 1/1 | Complete   | 2026-03-15 |
| 13. Complete Weight Unit Threading | 0/0 | Pending |  |
