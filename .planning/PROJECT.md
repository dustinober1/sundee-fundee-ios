# Sundee Fundee

## What This Is

A native Apple strength training app with hormonal-cycle-aware training adaptation, injury modification, AI workout generation, and multi-device sync. Built with Swift 6 + SwiftUI targeting iOS and watchOS. Backed by CloudKit for sync, Cloudflare Worker for AI (Gemini proxy), APNs for push notifications, and StoreKit 2 for subscriptions.

## Core Value

Users get personalized, cycle-aware strength training that adapts to their body — with seamless sync across iPhone and Apple Watch.

## Requirements

### Validated

<!-- Inferred from existing Swift codebase (codebase map 2026-03-18) -->

- ✓ SwiftUI app scaffold with Sign in with Apple auth — existing
- ✓ SwiftData local persistence with versioned schema (V1–V12) — existing
- ✓ CloudKit sync infrastructure (implemented but disabled in production) — existing (needs activation)
- ✓ Exercise library with workout logging and set tracking — existing
- ✓ Cycle tracking (period logging, symptom tracking, phase inference) — existing
- ✓ Cycle adaptation engine (load/volume/exercise adjustments per phase) — existing
- ✓ Injury management (profiles, body map, substitution engine) — existing
- ✓ Pain logging with trend analysis and rehab generation — existing
- ✓ AI workout generation via Cloudflare Worker (Gemini proxy) — existing
- ✓ Benchmark system (WOD-style scoring with catalog) — existing
- ✓ Max lifts (1RM) tracking — existing
- ✓ Workout history with summary views — existing
- ✓ Onboarding flow (experience, goals, cycle opt-in) — existing
- ✓ Art Deco design theme (cream/navy/orange palette) — existing
- ✓ StoreKit subscription service with tier gating — existing
- ✓ Programs with enrollment and workout execution — existing
- ✓ WOD (Workout of the Day) execution — existing
- ✓ Readiness survey / spicy rating — existing
- ✓ Weight unit support (lbs/kg) — existing (has bugs, needs fixing)
- ✓ Celebration overlay for PRs — existing

### Active

- [ ] Fix critical bugs identified in codebase audit (CloudKit activation, migration plan, schema references, AI weight units, guest userID, subscription cache)
- [ ] watchOS companion app with workout logging from wrist
- [ ] Push notifications via APNs (rest timer, reminders, streaks, WOD alerts)
- [ ] Full feature parity with React Native build (notifications, analytics, data export, account management)
- [ ] App Store submission and launch

### Out of Scope

- React Native / cross-platform — customer requires Apple-only
- Android / Web targets — Apple ecosystem only
- Firebase / Firestore — using CloudKit instead
- RevenueCat — using StoreKit 2 directly
- Real-time chat / social features — not core to training value
- Video content / streaming — storage/bandwidth cost, defer to future
- Nutrition tracking / macro logging — distinct domain, dilutes strength training focus

## Context

This is a rebuild from an existing Swift/SwiftUI codebase that was previously archived when the project pivoted to React Native. The RN version shipped v1.0 (72 requirements, 16 phases) and was mid-v1.1 (Launch Readiness) when the customer changed requirements back to Apple-only.

The legacy Swift codebase has substantial functionality already built:
- MVVM + Repository pattern with protocol abstractions
- Domain layer is pure Swift (no framework imports)
- SwiftData with 12 schema versions and migration plan
- CloudKit sync infrastructure (implemented but production-disabled)
- Feature verticals: Workouts, Cycle, Injuries, AI, Benchmarks, Programs, WODs
- Cloudflare Worker proxy for Gemini AI at `workout-proxy.sundeefundee.workers.dev`
- WOD admin dashboard (Next.js + CloudKit JS) at `wod-dashboard/`

Known bugs from codebase audit (CONCERNS.md):
- CloudKit sync disabled in production (flag flip needed + entitlements)
- Migration plan not applied to local persistent store path
- Sign-out/delete references stale AppSchemaV10 instead of V12
- AI weights hardcoded in lbs regardless of user unit preference
- Guest mode uses empty string userID (should use stable UUID)
- Subscription tier cached without server verification on cold launch
- Gemini model name hardcoded as string literal

## Constraints

- **Platform**: Swift 6 + SwiftUI, iOS 17.0+, watchOS 10.0+
- **Data**: CloudKit for sync, SwiftData for local persistence
- **AI**: Cloudflare Worker proxy → Gemini API (existing infrastructure)
- **Payments**: StoreKit 2 (native Apple subscriptions)
- **Notifications**: APNs (local + remote)
- **Design**: Art Deco aesthetic (cream #F4F0DF, navy #0D1A40, orange #F2731A)
- **Build**: XcodeGen (project.yml), Xcode 16+
- **Domain Logic**: Pure Swift, no framework dependencies, fully unit testable

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pivot from React Native back to Swift | Customer changed requirements, willing to pay more for Apple-native | — Pending |
| iOS + watchOS targets | Customer wants Apple Watch workout logging | — Pending |
| CloudKit over Firebase | Native Apple sync, no third-party backend dependency | — Pending |
| StoreKit 2 over RevenueCat | Apple-only means no cross-platform subscription complexity | — Pending |
| Rebuild from legacy Swift code | Substantial existing codebase with working features, not starting from scratch | — Pending |
| Keep Cloudflare Worker for AI | Existing Gemini proxy works, no need to change AI infrastructure | — Pending |
| Keep WOD dashboard (Next.js + CloudKit JS) | Admin tool works independently, no platform dependency | — Pending |

---
*Last updated: 2026-03-18 after project re-initialization (Swift pivot)*
