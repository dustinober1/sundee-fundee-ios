# Sundee Fundee — React Native Rewrite

## What This Is

A full rewrite of Sundee Fundee from native iOS (Swift 6 + SwiftUI) to React Native + Expo, targeting iOS, Android, and Web. Sundee Fundee is a strength training app with hormonal-cycle-aware training recommendations that adapts workouts based on menstrual cycle phase, injuries, and readiness. The rewrite moves from CloudKit/SwiftData to Firebase, adds cross-platform reach, and refreshes the Art Deco design language.

## Core Value

Users get personalized, cycle-aware strength training that adapts to their body — available on any platform, online or offline.

## Requirements

### Validated

<!-- Capabilities proven in the existing iOS app. These must be rebuilt in React Native. -->

- ✓ Sign in with Apple authentication — existing
- ✓ Guest mode (local-only, no sync) — existing
- ✓ Onboarding flow (name, experience, goal, gender, cycle opt-in) — existing
- ✓ Program catalog with structured weekly sessions — existing
- ✓ Workout execution (ForTime, AMRAP, EMOM timers) — existing
- ✓ Cycle phase tracking (period logging, symptom tracking, phase inference) — existing
- ✓ Cycle-aware training adaptation (load/set/rep multipliers by phase) — existing
- ✓ Injury profile management with recovery phases — existing
- ✓ Injury adaptation engine (exercise substitution/removal) — existing
- ✓ AI workout generation via Gemini (with offline fallback) — existing
- ✓ One-rep max tracking — existing
- ✓ Benchmark catalog and result tracking — existing
- ✓ Pain trend analysis — existing
- ✓ Rehab session generation — existing
- ✓ Phase transition advisor — existing
- ✓ Unified history (program + AI workouts, filtering, delete) — existing
- ✓ WOD (Workout of the Day) feed — existing
- ✓ Readiness survey with HealthKit integration — existing
- ✓ Art Deco themed UI (cream/navy/orange palette) — existing

### Active

<!-- New capabilities for the React Native version. -->

- [ ] React Native + Expo project scaffold (iOS, Android, Web)
- [ ] Firebase Auth (Apple, Google, Email/Password, Guest mode)
- [ ] Firestore database with offline persistence
- [ ] Full port of Domain logic (cycle adaptation, injury engine, benchmarks, etc.)
- [ ] Programs stored and managed via Firestore
- [ ] WODs stored and managed via Firestore
- [ ] AI workout generation via Firebase Cloud Functions (replacing Cloudflare Worker)
- [ ] RevenueCat integration for mobile subscriptions (iOS + Android)
- [ ] Stripe web checkout with lower pricing tier
- [ ] Google Sign In for Android users
- [ ] Email/password authentication
- [ ] Android-specific platform adaptations
- [ ] Web-specific responsive layout
- [ ] Refreshed Art Deco design (evolved from current cream/navy/orange)
- [ ] Offline-first architecture (workouts must work without signal)

### Out of Scope

- CloudKit migration tool — fresh start, no data migration from existing iOS app
- Flutter rewrite — previously considered, shelved in favor of React Native
- Native iOS maintenance — existing Swift app will be replaced, not maintained in parallel
- Real-time chat/social features — not core to training value
- Video content/streaming — storage/bandwidth cost, defer to future
- HealthKit deep integration on Android — no equivalent; use manual readiness survey
- Wearable integrations (Apple Watch, Wear OS) — defer to post-launch

## Context

- The existing iOS app has a mature Domain layer (~21 files) of pure Swift business logic with zero framework dependencies. This logic (cycle adaptation, injury modification, benchmarks, pain analysis, rehab generation) needs to be ported to TypeScript.
- The iOS app uses an MVVM + protocol-based repository pattern. The React Native version should use a similar separation of concerns.
- The Cloudflare Worker proxy (`workout-proxy.sundeefundee.workers.dev`) currently handles Gemini API calls. This will be replaced by Firebase Cloud Functions.
- The WOD admin dashboard (Next.js at `wod-dashboard/`) currently writes to CloudKit. It will need to be updated to write to Firestore instead.
- The existing app has 18 SwiftData `@Model` types that need Firestore equivalents.
- 100% test coverage is enforced on the current iOS app. Testing strategy for RN needs to be defined.

## Constraints

- **Offline**: Must work offline for core workout functionality — gyms have unreliable connectivity
- **Platform**: React Native + Expo (managed workflow preferred for simplicity)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions, Cloud Storage)
- **Payments**: RevenueCat (mobile) + Stripe (web) — dual pricing strategy
- **Design**: Refreshed Art Deco aesthetic, not a completely new design language
- **Domain Logic**: All existing business logic must be ported — cycle adaptation, injury engine, benchmarks, pain analysis, rehab generation, phase transition advisor
- **Quality**: Maintain high test coverage on ported Domain logic

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| React Native + Expo over Flutter | Professional multi-platform with web support; JS/TS ecosystem | — Pending |
| Firebase over Supabase | Better Expo integration, proven at scale, offline persistence built in | — Pending |
| Fresh start (no data migration) | Small user base, clean break simplifies architecture | — Pending |
| RevenueCat + Stripe dual payments | RevenueCat handles app store complexity; Stripe web checkout at lower prices incentivizes direct purchase | — Pending |
| Port Domain logic to TypeScript | Existing pure Swift logic is well-tested and proven; rewrite in TS maintains same algorithms | — Pending |
| Firebase Cloud Functions for AI | Consolidates backend; removes Cloudflare Worker dependency | — Pending |

---
*Last updated: 2026-03-14 after initialization*
