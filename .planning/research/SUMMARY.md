# Project Research Summary

**Project:** Sundee Fundee — iOS + watchOS Strength Training App
**Domain:** Native Apple-platform strength training with hormonal-cycle-aware adaptation
**Researched:** 2026-03-18
**Confidence:** HIGH (iOS/stack layer), MEDIUM-HIGH (watchOS sync patterns)

## Executive Summary

Sundee Fundee is a brownfield Swift 6 + SwiftUI codebase with a substantial feature set already built: workout logging, cycle adaptation, AI generation, benchmarks, programs, WODs, and StoreKit 2 subscriptions. The gap to App Store submission is not feature development — it is resolving critical correctness bugs, activating CloudKit sync (disabled in production), adding a watchOS companion, and wiring push notifications. The existing architecture (SwiftData + CloudKit, repository protocols, `SundeeFundeeShared` domain package) is sound and should not be re-architected.

The recommended sequence is: fix correctness bugs first (they compound every new feature), then activate CloudKit (the sync foundation that watchOS depends on), then build the watchOS companion targeting a minimal `HKWorkoutSession`-based workout logger with `WatchConnectivity` as the real-time sync bridge. Push notifications (APNs) can be added in parallel with or immediately after CloudKit activation since the infrastructure is independent. The entire milestone is an Apple-native effort with no third-party SDK complexity beyond what is already in the codebase.

The primary risks are concentrated in the CloudKit activation phase: the existing codebase has 12 schema versions accumulated under a local-only store, silent data deletion on migration failure, and no production schema deployed. These risks are well-understood and have clear mitigations — but they must be addressed before any TestFlight distribution, and before the watchOS target is added (which would introduce a second CloudKit consumer). Swift 6 concurrency debt (`@unchecked Sendable`) must also be resolved before watchOS multiplies the cross-actor surface.

## Key Findings

### Recommended Stack

The codebase is already on the correct stack (Swift 6, SwiftUI, SwiftData, CloudKit, StoreKit 2, HealthKit, XcodeGen). No re-platforming is needed. The additions required for this milestone are surgical: a watchOS target using the SwiftUI `@main` App protocol (not legacy `WKExtensionDelegate`), `HKWorkoutSession` + `HKLiveWorkoutBuilder` for Watch workout tracking, `WatchConnectivity` (`WCSession`) for real-time Watch→iPhone sync, WidgetKit for watch complications (ClockKit is deprecated), and `UNUserNotificationCenter` for APNs.

**Core technologies (existing, validated):**
- Swift 6 / SwiftUI: all application code across both targets
- SwiftData (V12, 22-model schema): local persistence, CloudKit-backed sync
- CloudKit Private + Public DB: sync ground truth; must be activated in production
- StoreKit 2: Free/Plus/Pro subscription gating — has a cold-launch bug to fix
- HealthKit: iOS read (HRV, sleep, RHR); watchOS write (HKWorkoutSession) — NEW for Watch
- XcodeGen: project generation; watchOS target config needs adding to `project.yml`

**New technologies (must add this milestone):**
- `HKWorkoutSession` + `HKLiveWorkoutBuilder` (watchOS 10): active workout on wrist, Activity ring contribution, HR/calories
- `WatchConnectivity` (`WCSession`): real-time Watch→iPhone workout data push via `transferUserInfo`
- WidgetKit (watchOS complications): cycle phase, streak, last workout on watch face
- `UNUserNotificationCenter` + APNs: rest timer, reminders, WOD push — infrastructure is entirely absent today

**What to avoid:**
- ClockKit / `CLKComplication` — deprecated since watchOS 9
- App Groups for iPhone↔Watch sync — same-device only, cannot span devices
- `@Attribute(.unique)` on CloudKit-synced models — silently breaks CloudKit sync
- `WKExtensionDelegate` lifecycle — legacy pattern; use SwiftUI `@main`
- `@unchecked Sendable` on new code — real data races exist behind the suppression

### Expected Features

The app is feature-rich. The gap to launch is not building new features; it is fixing what is broken, activating what is disabled, and adding the Watch companion and APNs infrastructure that users expect from a premium native app in 2025.

**Must have for App Store v1 (P1):**
- Fix critical bugs: AI weight unit (metric users get lbs values), stale V10 schema reference in sign-out, guest `userID == ""`, StoreKit cold-launch tier elevation window
- Activate CloudKit sync (flip flag after full compatibility audit + Production schema deployment)
- Fix account deletion compliance (App Store mandatory since June 2022)
- watchOS: HKWorkoutSession + set logging + rest timer on wrist + sync to iOS
- Push notifications: rest timer background notification (APNs infrastructure unlocks all others)

**Should have after validation (P2 / v1.x):**
- Push notifications: workout reminders, streak nudges, WOD alerts
- watchOS complication: cycle phase + streak on watch face
- Data export (CSV) — trust signal; required for full user data rights compliance
- Cycle phase education in UI — explain why today's workout changed
- Volume analytics and charts — progress visibility beyond raw PRs

**Defer to v2+:**
- Independent watchOS session (phone-free gym) — complex offline sync; not table stakes for companion positioning
- Video exercise demonstrations — high value, high CDN/content cost
- History-aware AI personalization — requires token budget management architecture
- watchOS 26 Workout Buddy integration — Apple's AI coaching layer; mainstream in 2026+

**Anti-features (deliberately avoid):**
- Social feed / activity sharing — out of scope; dilutes focus
- Nutrition tracking — distinct domain, separate expertise
- Android / Web — Apple-only by design; Watch integration requires it
- RevenueCat — StoreKit 2 native covers all requirements for Apple-only app

### Architecture Approach

The existing architecture is correct: SwiftUI views backed by `@Observable` ViewModels talking to repository protocols, implemented by SwiftData + CloudKit repos on top of a three-tier fallback ModelContainer (CloudKit → local → in-memory). The `SundeeFundeeShared` local Swift Package holds pure domain logic and must be expanded to include `Domain/` types (CycleProgramGenerator, InjuryAdaptationEngine, WeightCalculations) so the watchOS target can consume cycle adaptation without code duplication. The Watch target gets a separate, smaller `WatchAppSchemaV1` (WorkoutTemplate, CompletedWorkout, CompletedSet, UserPreferences) pointing at the same CloudKit container — never the full 22-model schema.

**Major components:**
1. **iPhone Target** — Full feature set, StoreKit paywall, AI generation, HealthKit reads, CloudKit sync authority
2. **SundeeFundeeShared Package** — Pure domain logic (zero framework imports); shared by both targets; must be expanded to include Domain/ types
3. **watchOS Target (new)** — Compact workout logger; `HKWorkoutSession` for background execution; minimal schema; `WCSession` push to iPhone
4. **WatchConnectivity Service** — `@Observable` singleton on both targets; `transferUserInfo` for workout data (reliable), `updateApplicationContext` for settings, `sendMessage` only for real-time optional feedback
5. **CloudKit Container** — Private DB for user data; Public DB for programs/WODs (admin-written); eventual consistency sync bus between devices

**Key patterns:**
- Separate `ModelContainer` per target (same CloudKit container ID) — App Groups cannot span devices
- `transferUserInfo` (not `sendMessage`) as primary Watch→iPhone data path — guaranteed delivery even when iPhone is backgrounded
- `HKWorkoutSession` must be started for every Watch workout — watchOS kills apps without an active session
- Checkpoint workout state to Watch SwiftData on every set log — recovery from SIGKILL and device reboot

### Critical Pitfalls

1. **CloudKit schema not deployed to Production** — Works in Development, fails silently in TestFlight/App Store. Must deploy schema via CloudKit Console before every TestFlight distribution. Make this a mandatory pre-release checklist item.

2. **CloudKit activation crashes app on existing local store** — 12 schema versions accumulated under a non-CloudKit store. Flipping `useCloudKit` without first passing `migrationPlan:` to the local container path, and auditing all models for CloudKit compatibility (optional properties, no `.unique`, no `.deny` rules), causes boot-time crash and potential silent store deletion that wipes user data.

3. **Silent data loss on migration failure** — `AppModelContainer.deleteStoreFiles` wipes all data with no user warning. Must add user-facing alert and a temp-copy safeguard before this path is reachable from a CloudKit activation failure.

4. **WatchConnectivity delegate methods silently never fire** — `sendMessage` fails when iPhone is not reachable. Use `transferUserInfo` for all workout data; add reconciliation sync at workout end; implement retry on `sessionReachabilityDidChange`.

5. **HKWorkoutSession not recovered after Watch reboot** — `handleActiveWorkoutRecovery` is not called after device reboot; must also call `HKHealthStore().recoverActiveWorkoutSession` in `applicationDidFinishLaunching`. Checkpoint every set to local SwiftData.

6. **`@unchecked Sendable` data races** — 9 classes in the codebase suppress Swift 6 concurrency errors. These must be audited and replaced with `actor` isolation or `Mutex` before the watchOS target is added; adding a second target multiplies cross-actor boundaries.

7. **CloudKit add-only schema constraint** — After first production deployment, entity/attribute renames are permanent data loss for existing users. Must establish the Add-Only rule before the first CloudKit production deployment.

## Implications for Roadmap

Based on the dependency chain in research, the natural phase structure is:

### Phase 1: Critical Bug Fixes
**Rationale:** Every subsequent phase builds on a stable foundation. The AI weight bug makes AI workouts broken for metric users. The stale V10 schema reference corrupts sign-out. The guest `userID == ""` breaks data integrity. StoreKit concurrency issues and `@unchecked Sendable` races compound with every new target added. These must be resolved before CloudKit activation (which could trigger the silent store deletion bug) and before watchOS (which multiplies concurrency surface). Fixing bugs is also low-cost relative to the risk of shipping them.
**Delivers:** A stable, correct iOS app ready for CloudKit activation
**Addresses:** AI weight unit bug, sign-out stale schema V10→V12, guest UUID stable Keychain strategy, StoreKit cold-launch tier gate, `@unchecked Sendable` audit, `Transaction.updates` listener lifecycle, account deletion compliance
**Avoids:** Pitfalls 4 (silent store deletion), 8 (StoreKit cold-launch), 9 (transaction listener), 11 (`@unchecked Sendable`), 12 (stale schema sign-out)

### Phase 2: CloudKit Activation
**Rationale:** CloudKit sync is the foundation for multi-device sync AND the Watch companion's eventual-consistency data path. It is currently disabled in production. It cannot be activated safely until Phase 1 is done (migration plan path must be fixed, model compatibility must be audited). Schema must be deployed to Production before any TestFlight distribution. Activate CloudKit as its own milestone so it can be tested in isolation before watchOS is added.
**Delivers:** Working iCloud sync across user's Apple devices; foundation for Watch data flow; CloudKit Production schema deployed
**Addresses:** CloudKit flag activation, entitlements, Production schema deployment, migration plan wiring, `ModelContainer` fallback safety
**Avoids:** Pitfalls 1 (schema not in Production), 2 (migration crash on activation), 3 (add-only constraint), 4 (silent store deletion)
**Uses:** SwiftData `ModelContainer` with `cloudKitContainerIdentifier`, `AppSchemaMigrationPlan`, three-tier fallback pattern

### Phase 3: Push Notifications (APNs Infrastructure)
**Rationale:** APNs infrastructure is entirely absent (no entitlements, no permission flow, no token registration). It is a discrete, well-understood implementation with no dependencies on watchOS. Shipping rest timer background notifications immediately increases gym-floor utility and provides the infrastructure that WOD alerts and streak reminders will build on. Can be developed in parallel with or immediately after CloudKit activation — no dependency between the two.
**Delivers:** Rest timer background notification (highest-value push), APNs token registration, permission flow, notification category actions (Skip / Start Now)
**Addresses:** APNs entitlements in `project.yml`, `.p8` auth key setup, `UNUserNotificationCenter` categories, device token storage in CloudKit, workout reminder push
**Avoids:** Using silent push for time-critical events (silent push is throttled; use local notifications for rest timer), third-party push SDK complexity
**Uses:** `UNUserNotificationCenter`, `.p8` APNs auth key, CloudKit Private DB device token storage

### Phase 4: watchOS Companion — Scaffold + Sync
**Rationale:** Before building Watch UI, the target infrastructure must be correct: XcodeGen watchOS target config, `SundeeFundeeShared` expansion (so Watch can access domain logic), `WatchModelContainer` with minimal schema, and `WatchConnectivityService` on both sides. Getting this architecture right prevents the most expensive pitfalls (App Group sync assumption, full schema replication). Requires CloudKit to be working (Phase 2) so the Watch sync path is valid from day one.
**Delivers:** watchOS target in `project.yml`, `SundeeFundeeWatch/` source tree, `WatchAppSchemaV1` (4 models), `WatchConnectivityService` activated on both sides, domain logic in `SundeeFundeeShared`
**Addresses:** ARCHITECTURE.md scaffold — XcodeGen target, minimal Watch schema, WCSession singleton, domain package expansion
**Avoids:** Pitfalls 5 (App Group assumption), 6 (WCSession delegate never fires — activate at launch), full 22-model schema on Watch (sync performance degradation)
**Uses:** XcodeGen `platform: watchOS`, `deploymentTarget: "10.0"`, `SundeeFundeeShared` SPM expansion, `WatchConnectivityService` `@Observable` singleton pattern

### Phase 5: watchOS Companion — Active Workout Feature
**Rationale:** The core value of the Watch app is logging sets from the wrist during an active workout. This is the highest-complexity watchOS deliverable and must be built on the Phase 4 scaffold. Requires `HKWorkoutSession` for background execution (without it, watchOS kills the app mid-workout). Requires `transferUserInfo` for reliable set-data delivery to iPhone.
**Delivers:** `HKWorkoutSession` + `HKLiveWorkoutBuilder` integration, set logging UI (Digital Crown weight/rep entry), rest timer with haptic, heart rate + calories display, workout end flow with proper session shutdown order, `transferUserInfo` sync to iPhone, workout recovery on app relaunch
**Addresses:** watchOS table stakes from FEATURES.md — Activity ring contribution, wrist logging, rest timer on wrist, HR/calories, end from wrist, sync to iPhone
**Avoids:** Pitfalls 7 (HKWorkoutSession crash recovery — checkpoint every set, recover in `applicationDidFinishLaunching`), 10 (iOS permission change kills Watch — front-load HealthKit auth in iPhone onboarding)
**Uses:** `HKWorkoutSession`, `HKLiveWorkoutBuilder`, `WCSession.transferUserInfo`, Watch SwiftData checkpointing, `WKHapticType.notification`

### Phase 6: watchOS Companion — Dashboard + Complications
**Rationale:** After the workout logging core is working, add the glanceable features that drive daily engagement: a watch face complication showing cycle phase/streak, and a dashboard view with today's program. These are read-only features with lower complexity and well-understood WidgetKit patterns.
**Delivers:** WidgetKit complication (accessoryCircular + accessoryRectangular: cycle phase, streak, last workout), watch dashboard (today's workout, cycle phase glance), haptic PR feedback
**Addresses:** Differentiating watchOS features from FEATURES.md — cycle phase glance, watch face complication, streak display
**Avoids:** ClockKit / `CLKComplication` (deprecated; use WidgetKit accessory families only)
**Uses:** WidgetKit `accessoryCircular`, `accessoryRectangular`, `accessoryCorner`, `accessoryInline` widget families

### Phase 7: Post-Launch Enhancements (v1.x)
**Rationale:** After App Store submission, these features improve the experience and retention but are not blocking launch.
**Delivers:** Additional push notification types (WOD alerts, streak reminders), data export (CSV/ZIP), cycle phase education UI, workout volume analytics and charts
**Addresses:** P2 features from FEATURES.md prioritization matrix
**Avoids:** Over-building before validating market fit

### Phase Ordering Rationale

- Bug fixes must precede CloudKit activation: the stale schema and `@unchecked Sendable` issues become catastrophic when combined with a CloudKit migration attempt
- CloudKit must precede watchOS: the Watch sync architecture depends on CloudKit being a healthy eventual-consistency bus; the `WatchModelContainer` uses the same CloudKit container identifier
- APNs is independent of watchOS and can be sequenced in Phase 3 without blocking the Watch work
- Watch scaffold (Phase 4) must precede Watch features (Phase 5) — XcodeGen target config and `WatchConnectivityService` activation must exist before any workout session code
- Complications (Phase 6) are lower-risk and can follow the core workout feature without risk to the critical path

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (CloudKit Activation):** Model compatibility audit across all 22 V12 models requires careful verification. The migration plan path bug needs confirmation against the exact `AppModelContainer.swift` implementation. Consider `/gsd:research-phase` for the migration crash mitigation.
- **Phase 5 (watchOS Active Workout):** `HKWorkoutSession` session state machine, the correct end-session ordering (`session.end()` before `builder.finishWorkout()`), and the known Sasquatch Studio sample code bug around `startMirroringToCompanionDevice` are edge cases that warrant a targeted research pass.
- **Phase 3 (APNs):** APNs token rotation on reinstall and WOD alert server-side delivery (Cloudflare Worker → APNs flow) need implementation research before coding.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Bug Fixes):** All bugs are identified in CONCERNS.md with clear root causes. No research needed — execute directly.
- **Phase 4 (watchOS Scaffold):** XcodeGen watchOS target configuration is well-documented. SPM expansion is a known pattern.
- **Phase 6 (Complications):** WidgetKit accessory family documentation is authoritative and complete.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Entire stack is Apple system frameworks already in use; new additions (watchOS target, APNs) are well-documented official APIs |
| Features | HIGH (iOS) / MEDIUM (watchOS competitor benchmarking) | iOS feature audit is from codebase; watchOS competitor features from product pages only |
| Architecture | HIGH (iOS patterns) / MEDIUM (watchOS CloudKit sync) | iOS architecture verified via official docs + community; watchOS CloudKit sync has known unreliability on Watch with documented community workarounds |
| Pitfalls | HIGH | Critical pitfalls sourced from Apple Developer Forums, fatbobman.com (authoritative SwiftData/CloudKit resource), and direct CONCERNS.md codebase audit |

**Overall confidence:** HIGH for the iOS + bug fix work; MEDIUM for the watchOS CloudKit sync reliability in production (known community-reported issues without a fully stabilized workaround)

### Gaps to Address

- **watchOS CloudKit sync reliability in production:** Community reports indicate CloudKit sync on watchOS 10 only triggers reliably when Watch is charging with >50% battery. The architecture correctly designates `WCSession.transferUserInfo` as the primary sync channel and CloudKit as eventual fallback — but this tradeoff needs to be communicated in UX (e.g., "sync pending" indicators on Watch). Validate the sync behavior on physical hardware in Phase 4.
- **CloudKit schema compatibility of all 22 V12 models:** Research recommends auditing all models for optional properties, no `.unique`, no `.deny` delete rules. The exact set of models that currently violate these rules is not enumerated in the research — this audit must happen as the first task in Phase 2.
- **Gemini proxy authentication:** The Cloudflare Worker proxy is unauthenticated. The research flags this as a security concern (any caller can incur API costs). App Attest or a shared-secret header should be added; this is deferred to Phase 7 or can be addressed as a low-effort security task in Phase 1.
- **HealthKit write entitlement:** The entitlement is declared but not implemented. Research flags this as a v2 feature. Confirm it is not accidentally exposed to users in the current UI during Phase 1 audit.

## Sources

### Primary (HIGH confidence)
- Apple Developer Docs: Running workout sessions (HKWorkoutSession + mirroring architecture)
- Apple Developer Docs: Sending notification requests to APNs
- Apple Developer Docs: Transferring data with Watch Connectivity
- Apple Developer Docs: Syncing model data across a person's devices (SwiftData + CloudKit)
- Apple Developer Docs: TN3157 — Updating your watchOS project for SwiftUI and WidgetKit
- Apple Developer Docs: Creating independent watchOS apps (SwiftUI App protocol for watchOS)
- fatbobman.com: Key Considerations Before Using SwiftData (CloudKit sync limitations)
- fatbobman.com: Fixing CloudKit Sync in Production: Deploying Schema
- fatbobman.com: From YaoYao to Tooboo — watchOS Development Pitfalls
- WWDC25: Track workouts with HealthKit on iOS and iPadOS
- WWDC25: What's new in StoreKit and In-App Purchase
- Swift 6.2 Release — Swift.org (approachable concurrency)
- XcodeGen ProjectSpec docs (watchOS target configuration)
- CONCERNS.md — internal codebase audit (2026-03-18)

### Secondary (MEDIUM confidence)
- Sasquatch Studio: Building a Workout App for Apple Watch (March 2025) — mirroring session architecture, known sample code bug
- Apple Developer Forums: SwiftData CloudKit sync on watchOS 10 — known reliability issues
- Apple Developer Forums: SwiftData + CloudKit migration failure threads
- avanderlee.com: Approachable Concurrency in Swift 6.2
- Alexander Weiss: Three Ways to Communicate via WatchConnectivity
- Strong App Watch features (official product docs) — competitor benchmarking
- Hevy App features (official product page) — competitor benchmarking
- Wesley Matlock, Medium: Building a Universal Workout App (iPhone ↔ Apple Watch sync)

### Tertiary (LOW confidence)
- Third-party fitness app roundups — used only for confirming feature expectations, not architectural decisions
- Best cycle syncing apps 2025 — niche feature validation only

---
*Research completed: 2026-03-18*
*Ready for roadmap: yes*
