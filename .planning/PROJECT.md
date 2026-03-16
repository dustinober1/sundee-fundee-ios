# Sundee Fundee — React Native

## What This Is

A cross-platform strength training app with hormonal-cycle-aware training adaptation, injury modification, AI workout generation, and offline-first architecture. Built with React Native + Expo targeting iOS, Android, and Web. Backed by Firebase (Firestore, Auth, Cloud Functions) with RevenueCat + Stripe dual subscription pipeline.

## Core Value

Users get personalized, cycle-aware strength training that adapts to their body — available on any platform, online or offline.

## Requirements

### Validated

- ✓ React Native + Expo project scaffold (iOS, Android, Web) — v1.0
- ✓ Firebase Auth (Apple, Google, Email/Password, Guest mode) — v1.0
- ✓ Firestore database with offline persistence — v1.0
- ✓ Full TypeScript port of Domain logic (cycle adaptation, injury engine, benchmarks, pain analysis, rehab generation) — v1.0
- ✓ Onboarding flow (name, experience, goal, gender, cycle opt-in) — v1.0
- ✓ Exercise library (202+), workout logging, timers, PR detection — v1.0
- ✓ Unified history (AI/Program/Custom sources, filtering, delete) — v1.0
- ✓ Progress charts and 1RM tracking — v1.0
- ✓ Cycle tracking (period logging, symptom tracking, phase inference, adaptation) — v1.0
- ✓ Injury management (profiles, substitution, pain logging, trend analysis, rehab, phase transition) — v1.0
- ✓ AI workout generation via Gemini Cloud Function with offline fallback — v1.0
- ✓ Programs from Firestore with enrollment and target weight calculation — v1.0
- ✓ Benchmarks with scoring-aware recording and custom creation — v1.0
- ✓ WODs from Firestore matched by date — v1.0
- ✓ Readiness survey feeding into workout adaptation — v1.0
- ✓ RevenueCat mobile subscriptions + Stripe web checkout — v1.0
- ✓ Entitlement gating across all platforms — v1.0
- ✓ Art Deco design (cream/navy/orange palette) — v1.0
- ✓ Weight unit switching (lbs/kg) threaded through all screens — v1.0
- ✓ Data export (CSV/JSON with zip bundling) — v1.0
- ✓ Account deletion with full data wipe — v1.0
- ✓ Guest-to-auth upgrade with data preservation — v1.0
- ✓ Firebase App Check (DeviceCheck on iOS, Play Integrity on Android) — v1.0

### Active

(None — next milestone requirements TBD via `/gsd:new-milestone`)

### Out of Scope

- CloudKit migration tool — fresh start, no data migration from existing iOS app
- Native iOS Swift app maintenance — replaced by React Native version
- Real-time chat/social features — not core to training value
- Video content/streaming — storage/bandwidth cost, defer to future
- Wearable integrations (Apple Watch, Wear OS) — defer to post-launch
- Nutrition tracking / macro logging — distinct domain, dilutes strength training focus

## Context

Shipped v1.0 with 44,211 LOC TypeScript (14,618 test LOC across 72 test files).
Tech stack: React Native + Expo, Firebase (Firestore, Auth, Cloud Functions), RevenueCat, Stripe, Gemini AI.
72 requirements satisfied across 16 phases and 43 plans in 30 days.
All 10 E2E user flows verified passing.

Known tech debt: ~30 human verification items (device testing), Firestore rules deploy pending, Nyquist validation partial.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| React Native + Expo over Flutter | Professional multi-platform with web support; JS/TS ecosystem | ✓ Good — delivered iOS/Android/Web from single codebase |
| Firebase over Supabase | Better Expo integration, proven at scale, offline persistence built in | ✓ Good — offline-first worked well with Firestore |
| Fresh start (no data migration) | Small user base, clean break simplifies architecture | ✓ Good — no migration complexity |
| RevenueCat + Stripe dual payments | RevenueCat handles app store complexity; Stripe web checkout at lower prices | ✓ Good — unified entitlements across platforms |
| Port Domain logic to TypeScript | Existing pure Swift logic is well-tested and proven; rewrite in TS maintains same algorithms | ✓ Good — numeric parity verified |
| Firebase Cloud Functions for AI | Consolidates backend; removes Cloudflare Worker dependency | ✓ Good — Gemini 2.0 Flash with JSON mode |
| String unions over TS enums | Better serialization and narrowing for domain types | ✓ Good — cleaner code throughout |
| Dual repository pattern (Firestore/AsyncStorage) | Supports auth + guest modes with same interface | ✓ Good — seamless offline experience |
| Module-level shared state for workout passing | Expo Router params have serialization limits | ⚠️ Revisit — works but not ideal for complex state |

## Constraints

- **Offline**: Must work offline for core workout functionality — gyms have unreliable connectivity
- **Platform**: React Native + Expo (managed workflow)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions)
- **Payments**: RevenueCat (mobile) + Stripe (web)
- **Design**: Art Deco aesthetic (cream/navy/orange)
- **Domain Logic**: All business logic ported from Swift with numeric parity
- **Quality**: High test coverage on Domain logic and critical paths

---
*Last updated: 2026-03-16 after v1.0 milestone*
