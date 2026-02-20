# Feature Research

**Domain:** Cross-platform workout tracker rewrite (Flutter web + Android + iOS)
**Researched:** 2026-02-20
**Confidence:** MEDIUM-HIGH

- **HIGH confidence:** Flutter platform support, Flutter web service worker status, Firebase Flutter multi-platform setup (official docs).
- **MEDIUM confidence:** Feature behavior expectations and parity patterns synthesized from Flutter offline-first architecture guidance + existing v1.1 product behavior.
- **LOW confidence (flagged):** Exact Firestore offline default behavior details from direct doc extraction were not retrievable in-tool this run; verify during implementation if Firestore cache defaults are relied on.

## Cross-Platform Parity Behavior (Expected)

These are expected behaviors for **feature parity** in v2.0. If behavior diverges, users will experience regression.

| Capability | Web (Flutter) | Android (Flutter) | iOS (Flutter) | Parity Rule |
|---|---|---|---|---|
| Onboarding/profile setup | Same multi-step flow and validation | Same | Same | Same required fields, same completion criteria |
| Program browsing | Same filtering, details, progression metadata | Same | Same | Same program definitions and ordering |
| Workout logging (sets/reps/weight) | Same form behavior, rest timer, completion flow | Same | Same | Same calculations and PR trigger thresholds |
| Recommendations | Same recommendation cards and rules | Same | Same | Same rule engine outputs for same inputs |
| Plateau + PR celebration | Same detection logic + celebratory event | Same | Same | Logic parity > animation parity |
| Progress charts | Same datasets/time windows | Same | Same | Data parity required; chart styling may adapt to screen size |
| Offline-first core loop | Must work with no network after initial load | Must work offline | Must work offline | Log workout and view recent history offline on all platforms |
| Optional cloud sync UX | Same sync status language and conflict policy | Same | Same | Same queue/sync states and failure messaging |
| Install/offline app polish | Web app load/update messaging (custom SW strategy) | Native app install via store build; no PWA prompt | Native app install via store build; no PWA prompt | “Install” UX can differ by platform, core app behavior cannot |

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist for parity with shipped v1.1 behavior.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Functional parity: onboarding, programs, active workout logging | Core value proposition already validated in v1.x | HIGH | Depends on preserving existing domain model semantics from v1 (`users`, cycles, workouts, sets, metrics). |
| Rule parity: recommendations + plateau detection + PR trigger logic | Users trust consistent coaching logic | HIGH | Must port calculation/rule logic exactly before UX refinements. |
| Progress parity: 1RM trend, volume, activity history | Existing users expect historical insight continuity | MEDIUM-HIGH | Depends on stable transformed data layer; chart library can differ by platform. |
| Offline-first local source of truth | Workout app must be reliable in gyms with weak/no network | HIGH | Flutter guidance favors local-first repository with sync; avoid online-only writes for workout logging. |
| Optional sync with clear state (synced/pending/error) | Existing product already has sync UX and queue expectations | HIGH | Depends on auth + remote backend + explicit retry policy. |
| Deterministic calculation parity (%1RM, rounding, PR checks) | Small numeric differences undermine trust | MEDIUM | Must reuse/port formulas and rounding behavior exactly; regression tests required. |
| Mobile-first ergonomics retained | Existing app optimized for one-handed workout usage | MEDIUM | Same task completion with thumb-reachable primary actions on Android/iOS; responsive adaptation on web. |
| Data migration/continuity strategy from v1 | Rewrite without continuity creates perceived data loss | HIGH | At minimum: import/seed strategy for users starting on v2 and clear messaging for legacy data behavior. |
| Platform-consistent error handling | Users expect graceful behavior offline, auth expired, sync conflict | MEDIUM | Keep same error taxonomy and user-facing language patterns from v1. |
| Release-quality parity tests across 3 platforms | Rewrite risk is behavior drift | HIGH | Must include cross-platform acceptance suite for core flows and rules. |

### Differentiators (Competitive Advantage)

Useful but optional for this milestone if risk threatens parity delivery.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Unified parity contract tests (golden behavior fixtures) | Prevents logic drift across platforms over time | MEDIUM | Add shared input/output fixtures for calculations and recommendation rules. |
| Enhanced cross-device sync confidence UX (last sync source + timestamp detail) | Increases trust when switching devices | MEDIUM | Layer on top of table-stakes sync status once base queue/retry is stable. |
| Adaptive chart interactivity by platform (hover web, touch mobile) | Better usability per platform without changing insights | LOW-MEDIUM | Keep dataset and interpretation consistent; only interaction model differs. |
| Smart onboarding continuity (resume incomplete onboarding) | Reduces drop-off on mobile interruptions | LOW-MEDIUM | Should not change required profile fields from v1 behavior. |
| Performance instrumentation from day 1 (Firebase Performance + crash telemetry) | Faster stabilization during rewrite | MEDIUM | Valuable operational differentiator, but does not replace feature parity requirements. |

### Anti-Features (Commonly Requested, Often Problematic)

Do **not** include these in v2.0 parity milestone.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Net-new social/community layer | “Make it more engaging” | Large scope explosion unrelated to parity; delays launch | Defer to post-parity milestone with separate requirements |
| Wearables and live sensor integrations now | “More data is better” | High platform/API variance; major integration/testing burden | Keep manual logging + optional set metrics parity first |
| Real-time collaborative syncing/conflict UI | “Multi-device should feel instant” | Complex conflict semantics for little solo-user benefit | Keep explicit queue + retry + clear last-write policy |
| Pixel-identical UI across web/android/iOS | “Consistency” | Fights platform conventions and harms UX | Enforce behavior parity and design language parity, not pixel identity |
| Depend on Flutter-generated default PWA service worker | “Easy offline web” | Generated SW path is deprecated; update/offline behavior risks | Use explicit custom web SW strategy or disable generated PWA SW and design offline strategy intentionally |

## Feature Dependencies

```text
[Domain Model Parity]
    └──requires──> [Calculation/Rule Parity]
                         └──requires──> [Workout Logging Parity]
                                              └──requires──> [Recommendations + PR + Plateau Parity]

[Local-First Data Layer]
    └──requires──> [Offline UX + Error States]
                         └──enables──> [Optional Cloud Sync UX]

[Parity Acceptance Tests]
    └──validates──> [All Table Stakes]

[Platform-specific Install Polish]
    └──must not block──> [Core Parity Delivery]
```

### Dependency Notes

- **Rule parity requires domain model parity:** recommendation and PR/plateau behavior are only trustworthy if underlying workout/set/1RM semantics match v1.
- **Sync UX depends on local-first write path:** queue/retry is only meaningful if workouts are saved locally first and never blocked by network.
- **Cross-platform testing is a hard dependency, not a cleanup task:** without it, parity claims are not credible.
- **Install/distribution differences are platform-specific:** web deployment and mobile app distribution can differ, but must not alter core user workflows.

## MVP Definition (for this milestone: v2.0 full parity)

### Launch With (v2.0 parity gate)

- [ ] Onboarding/program/workout logging parity across web + Android + iOS
- [ ] Recommendation/plateau/PR logic parity with deterministic test fixtures
- [ ] Progress analytics parity (same insights and time windows)
- [ ] Offline-first core loop parity (log + review offline on all platforms)
- [ ] Optional cloud sync parity UX (status, retry, failure messaging)
- [ ] Cross-platform acceptance test coverage for critical workflows

### Add After Parity Stabilization (v2.0.x)

- [ ] Enhanced sync transparency UX (per-device/source details)
- [ ] Platform-optimized chart interactions
- [ ] Onboarding resume/continuity improvements

### Future Consideration (v3+)

- [ ] Wearables integration
- [ ] Social/community features
- [ ] Advanced real-time collaboration/conflict tooling

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Workout logging parity | HIGH | HIGH | P1 |
| Rule parity (recommendations/plateau/PR) | HIGH | HIGH | P1 |
| Offline-first parity | HIGH | HIGH | P1 |
| Progress charts parity | HIGH | MEDIUM-HIGH | P1 |
| Sync UX parity | HIGH | HIGH | P1 |
| Cross-platform acceptance tests | HIGH | HIGH | P1 |
| Enhanced sync transparency | MEDIUM | MEDIUM | P2 |
| Adaptive chart interactions | MEDIUM | LOW-MEDIUM | P2 |
| Wearables integration | MEDIUM | HIGH | P3 |

## Sources

### High-confidence (official docs)
- Flutter supported deployment platforms: https://docs.flutter.dev/reference/supported-platforms
- Flutter web FAQ (service worker deprecation / PWA strategy): https://docs.flutter.dev/platform-integration/web/faq
- Flutter offline-first architecture patterns: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Firebase for Flutter setup (platform support and initialization): https://firebase.google.com/docs/flutter/setup

### Medium-confidence (project behavior baseline)
- Existing v1.x product and milestone context: `/Users/dustinober/Projects/Sundee-Fundee/.planning/PROJECT.md`

### Low-confidence / needs validation during implementation
- Firestore offline default behavior by platform (web vs Android/iOS) should be re-verified directly in implementation docs/tests because direct extraction failed in this run.

---
*Feature research for: Flutter full rewrite parity (web/Android/iOS)*
*Researched: 2026-02-20*