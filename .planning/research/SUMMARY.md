# Project Research Summary

**Project:** Sundee Fundee v2
**Domain:** Cycle-aware strength training iOS app — recovery scoring, deload automation, and social fitness feed
**Researched:** 2026-04-15
**Confidence:** HIGH

## Executive Summary

Sundee Fundee v2 extends a mature SwiftUI/CloudKit/HealthKit codebase with three new capability areas: a composite recovery score, signal-based deload automation, and a friends-only social activity feed. All three features build on infrastructure that already exists in the app — HealthKit HRV reads, WeeklyLoadAnalyzer, PlateauDetector, EnrolledProgramRecord, and CloudKit CRUD — which substantially reduces risk. The dominant technical challenge is not net-new integration but correct composition of existing signals into accurate, trustworthy output.

The recovery score is the linchpin. It must ship before deload automation (which consumes recovery score as its primary trigger signal) and before the social layer can display recovery context. The recommended approach mirrors evidence-based apps (HRV4Training, Athlytic, Garmin): a personal rolling baseline rather than population thresholds, with cycle phase as a normalization input rather than a flat modifier. This is the genuine market gap — no competitor combines cycle-phase normalization with a composite training recovery score. The social layer is architecturally independent and can be developed in parallel, but it ships last because it depends on activity-feed seeding from features built in earlier phases.

The single most critical risk is an HRV baseline that is cycle-blind: progesterone suppresses HRV 10-20% during the luteal phase, which will cause the score to read "low recovery" every cycle regardless of training state. The fix is to maintain per-phase rolling HRV baselines rather than a global 30-day average. This decision must be embedded in the domain layer scoring engine from day one — it cannot be retrofitted cheaply. Secondary risks are HealthKit sleep sample deduplication (inflates duration 2-3x if not handled) and the CloudKit discovery API deprecation (no username search; friend-add must be invite-link-only from the start).

---

## Key Findings

### Recommended Stack

The existing stack is the correct stack. No new frameworks or external dependencies are introduced. The gaps are additive: sleep analysis (`HKCategoryType(.sleepAnalysis)`) is a new HealthKit authorization type; the recovery scoring engine is a new pure domain function; the deload detector extends the existing `Intelligence/` directory; and the social layer introduces a new `SocialClient` actor targeting CloudKit's shared database scope — a scope the existing `CloudKitClient` does not currently address.

**Core technologies:**
- **HealthKitClient (actor, extended):** Sleep and HRV reads — extend with `fetchSleepAnalysis()` and 60-day HRV window for chronic baseline; existing `withCheckedThrowingContinuation` bridge pattern applies directly
- **RecoveryScoreEngine (new pure domain):** Five-component weighted formula (HRV 35%, sleep 25%, training load 20%, cycle phase 15%, resting HR 5%); pure function enables immediate unit testing and weight tuning without architecture changes
- **DeloadDetector (new pure domain):** Extends `Intelligence/` alongside `PlateauDetector`; inputs from existing `WeeklyLoadAnalyzer` and new `RecoveryScore` type; deload state stored as `EnrolledProgramRecord` with `isDeloadWeek` flag — no new CloudKit record type needed
- **SocialClient (new actor):** CloudKit zone sharing via `CKShare` on a per-user "SundeeActivity" `CKRecordZone`; reads from `sharedCloudDatabase` (distinct query path from existing `CloudKitClient`); separate `SocialClientProtocol` — must not extend `DataClientProtocol`
- **UICloudSharingController (SwiftUI-wrapped):** Invitation-only friend add via share URL; `CKDiscoverUserIdentitiesOperation` is deprecated — link sharing is the only viable path on iOS 17+

---

### Expected Features

**Must have (table stakes):**
- 0-100 recovery score visible on dashboard without tapping — Whoop/Oura convention; other patterns require user re-education
- Color-coded zones (green 70-100, yellow 40-69, red 0-39) — traffic-light pattern users already know
- Score breakdown detail screen — "why is my score X?" is the second most-asked question after the score itself
- HRV as primary score input (35% weight) — drives majority of score in every mainstream recovery platform
- Sleep quality as significant input (25% weight) — requires new `HKCategoryType(.sleepAnalysis)` permission
- "Push / Train light / Rest" recommendation tied to score — app's stated core value proposition
- Fatigue detection with user confirmation before deload activates — auto-change-without-notice causes user distrust
- Active recovery suggestions during deload week (mobility, yoga, light cardio) — full rest weeks cause habit regression
- Friends list via invite-link + activity feed (PRs, workouts, challenge badges) — Hevy/Strava established this pattern
- High-five reactions on feed items — Strava's 14 billion kudos validates this as the atomic social unit

**Should have (differentiators):**
- Cycle-phase normalization of HRV in the recovery score — no competitor does this; genuine market gap
- Cycle-correlated score trend chart — "your recovery is always lower in luteal phase" is uniquely valuable
- Pain/injury log feeding recovery score — already logged in-app; no competitor uses this as a recovery input
- Score computation timestamp displayed ("Computed 7:34 AM") — allows users to assess data freshness
- Deload week countdown — clear start/end date and day-by-day active recovery plan

**Defer to follow-on:**
- Phase-calibrated active recovery suggestions (luteal vs. follicular-specific sessions)
- Push notifications for friend activity (requires APNs entitlement setup; polling sufficient for MVP)
- Intraday recovery score updates (background HealthKit delivery fires unreliably; morning-only is correct)
- Social cycle-phase context visibility to friends (privacy-sensitive; needs usage data before designing)

---

### Architecture Approach

All new features follow the existing layered architecture: pure domain functions in `DomainLayer/` with zero framework imports, actor-based service layer assembling inputs from HealthKit/CloudKit and passing plain values to domain, `@MainActor ObservableObject` ViewModels publishing to SwiftUI views. The recovery score follows the `CoachContext`/`CoachContextBuilder` assembly pattern exactly. The social layer's `SocialClient` actor is the only architectural novelty — it must target `container.sharedCloudDatabase` directly and must have its own `SocialClientProtocol`, not conform to `DataClientProtocol`.

**Major components:**
1. **RecoveryScoreEngine** (`DomainLayer/Recovery/`) — Pure function; `RecoveryInputs` in, `RecoveryScore` out; per-phase HRV baseline; cycle phase modifier as multiplier on composite total
2. **DeloadDetector** (`DomainLayer/Intelligence/`) — Pure function alongside `PlateauDetector`; threshold-based, not ML; only recommends — never auto-enrolls
3. **SocialClient** (`DataLayer/Social/`) — Actor; creates/manages "SundeeActivity" `CKRecordZone` lazily; queries `sharedCloudDatabase` for friend activity
4. **SocialActivityBroadcaster** (`DataLayer/Social/`) — Fire-and-forget actor posting `ActivityEvent` records; decouples `WorkoutViewModel`/`MaxesViewModel` from `SocialClient`
5. **RecoveryViewModel** (`UI/ViewModels/`) — Assembles `RecoveryInputs` from HealthKit + DataClient + CyclePhaseCache; triggers deload evaluation post-scoring; publishes daily score and 30-day trend array
6. **FriendsViewModel** (`UI/ViewModels/`) — Consumes `SocialClient`; manages friend list, merged feed, and pending share invitations from scene URL handling

---

### Critical Pitfalls

1. **Cycle-blind HRV baseline triggers false deloads every luteal phase** — Progesterone suppresses HRV 10-20% in luteal phase independent of training fatigue. Prevention: maintain per-phase rolling HRV average and compare current HRV to the current phase's expected range. Must be in the domain engine from day one. (Phase 1)

2. **Sleep sample deduplication inflates duration 2-3x** — HealthKit returns overlapping samples from Apple Watch (per-stage) and iPhone (InBed) simultaneously; summing all inflates duration. Prevention: filter by source bundle ID (prefer `com.apple.health`); merge overlapping intervals before summing. Test on real device — simulator hides this bug. (Phase 1)

3. **CloudKit user discovery is deprecated — no friend search possible** — `CKDiscoverUserIdentitiesOperation` is deprecated in iOS 17+. There is no API path for username or email lookup. Prevention: design friend-add as invite-link-only from the start; do not design a "search by name/email" screen. (Phase 3)

4. **Background HealthKit delivery races ahead of Apple Watch sync** — Sleep data syncs from Watch to iPhone asynchronously after wake. A score triggered by background delivery may compute before sleep data arrives. Prevention: compute score lazily on app foreground, not in background callbacks. (Phase 1)

5. **`sharedCloudDatabase` requires a separate query path** — Friend activity lives in the shared database; queries against `privateCloudDatabase` return empty results for shared records with no error. Prevention: `SocialClient` must explicitly target `container.sharedCloudDatabase`; test with two physical iCloud accounts. (Phase 3)

---

## Implications for Roadmap

### Phase 1: Recovery Score Foundation

**Rationale:** Every downstream feature either consumes recovery score output or is independent of it. Highest user value density and most research-validated implementation path.

**Delivers:** Daily 0-100 recovery score on dashboard, score breakdown detail screen, sleep HealthKit integration, score persistence to CloudKit, 30-day trend chart with cycle phase color bands.

**Addresses:** All recovery score table stakes; cycle-phase normalization differentiator; "push/rest" recommendation.

**Avoids:** Pitfall 1 (per-phase HRV baseline from day one), Pitfall 2 (sleep deduplication in HealthKit layer), Pitfall 4 (foreground-compute not background-delivery), Pitfall 5 (Swift 6 actor boundaries — extract primitives only before crossing actor), Pitfall 10 (explicit "check permissions" UI state).

**Build sequence:**
1. Extend `HealthClientProtocol` + `HealthKitClient` + `MockHealthKitClient` with `fetchSleepAnalysis()`
2. `RecoveryScoreEngine` pure domain function with per-phase HRV baseline and injectable weights
3. `RecoveryScoreRecord` model (CloudKit-safe field names: `scoreDate`, not `startDate`/`createdAt`)
4. `RecoveryViewModel` wiring all inputs
5. `RecoveryDashboardCard` + `RecoveryDetailView` + `RecoveryTrendChart` UI

---

### Phase 2: Deload Detection and Active Recovery

**Rationale:** Depends on `RecoveryScore` type from Phase 1. Minimal new infrastructure: one new domain function, one confirmation sheet UI, one backwards-compatible record field.

**Delivers:** Automatic fatigue detection, single-screen deload confirmation flow, active recovery week programming (3-4 sessions), 4-week deload cooldown suppression.

**Addresses:** All deload automation table stakes; deload week countdown.

**Avoids:** Pitfall 7 (4-week cooldown window post-deload), Pitfall 8 (injectable weights; score explanation already in Phase 1), Pitfall 11 (suggestion rotation to avoid repetition across deload weeks).

**Build sequence:**
1. `DeloadDetector` pure domain function in `DomainLayer/Intelligence/`
2. `ActiveRecoverySession` model and generator
3. Add `isDeloadWeek: Bool` to `EnrolledProgramRecord` with backwards-compatible `Int64` fallback decode
4. `DeloadSuggestionSheet` UI confirmation flow
5. Integrate deload evaluation into `RecoveryViewModel.refresh()` post-scoring

---

### Phase 3: Social Layer — Friends and Activity Feed

**Rationale:** Architecturally independent of Phases 1 and 2 (can be developed in parallel), but ships last: activity feed is seeded by events validated in earlier phases; CloudKit zone sharing has the highest operational risk and requires two real iCloud accounts for testing.

**Delivers:** CloudKit zone sharing, friends list via invite-link, activity feed (PRs, workouts, challenge badges), high-five reactions, share URL handling in App.swift.

**Addresses:** All social feed table stakes; invite-link-only friend add (respects CloudKit discovery deprecation constraint).

**Avoids:** Pitfall 3 (invite-link-only; no search screen), Pitfall 4 (one zone per user as their activity zone), Pitfall 9 (explicit `sharedCloudDatabase` query path), Pitfall 12 (no per-reaction push notifications; defer notifications entirely).

**Build sequence:**
1. `ActivityEvent` model + `SocialClientProtocol`
2. `SocialClient` actor (zone creation, `CKShare` management)
3. `MockSocialClient` for testing and screenshots
4. CloudKit Dashboard: create "SundeeActivity" record type, deploy to production
5. `SocialActivityBroadcaster` actor
6. Wire broadcaster into `WorkoutViewModel` and `MaxesViewModel` post-save hooks
7. `FriendsViewModel` + `FriendsFeedView` + `FriendProfileView` + `ReactionView` UI
8. Share URL handling in `App.swift` via `.onOpenURL`; add `CKSharingSupported: YES` to `Info.plist`

---

### Phase Ordering Rationale

- Phase 1 is required before Phase 2: `DeloadDetector` consumes `RecoveryScore` type; deload signals require real score data to be meaningful.
- Phase 3 is parallel-eligible but ships last: social activity event definitions (PR, workout, challenge) are validated by the domain work in Phases 1 and 2; zone sharing carries the highest operational risk and should not block core feature delivery.
- No phase creates a new CloudKit record schema that touches existing records, except the backwards-compatible `isDeloadWeek` Bool flag in Phase 2 — which follows the established `Int64` fallback decode pattern already used by `EnrolledProgramRecord` and `UserSettingsRecord`.
- All three phases use the same testing infrastructure: protocol-typed dependency injection in ViewModels, MockHealthKitClient, MockDataClient, MockSocialClient.

### Research Flags

Needs deeper research during planning:
- **Phase 1 (per-phase HRV threshold calibration):** Specific ratio thresholds and window sizes (7-day acute, 60-day chronic) should be validated against menstrual cycle HRV literature before the scoring formula is finalized. MEDIUM confidence on specific numbers; HIGH confidence on approach.
- **Phase 3 (CloudKit zone sharing participant limits):** Officially undocumented. Plan empirical testing with `sample-cloudkit-zonesharing` reference. Include a friend count cap UI warning as a fallback.

Standard patterns (skip research-phase):
- **Phase 2 (deload detection logic):** Threshold-based decision logic and 4-week cooldown are well-documented in sports science and `PlateauDetector` is the direct architectural precedent.
- **Phase 1 (HealthKit sleep integration):** Apple docs and `HKCategoryValueSleepAnalysis` are authoritative; deduplication pattern is well-documented. Only HRV formula calibration needs scrutiny.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new frameworks; all additions extend verified existing patterns; Apple docs authoritative |
| Features | HIGH | Recovery: verified against Whoop, Oura, Garmin, HRV4Training; Social: verified against Hevy, Strava; Deload: verified against Fitbod and sports science literature |
| Architecture | HIGH | Based on direct codebase inspection; all component placements match existing established patterns; SocialClient grounded in official Apple sample code |
| Pitfalls | HIGH | HRV/cycle relationship grounded in peer-reviewed PMC research; sleep deduplication confirmed by Apple Developer Forums; CloudKit discovery deprecation confirmed in Apple docs |

**Overall confidence:** HIGH

### Gaps to Address

- **HRV threshold calibration per cycle phase:** The 10-20% luteal suppression range comes from PMC research but may vary by individual. Plan to tune thresholds via TestFlight feedback with real user data in the 2 weeks post-Phase 1 ship.
- **CloudKit zone participant limits:** Officially undocumented; forum guidance only. Test empirically during Phase 3 with two real iCloud accounts. Plan a UI warning if a friend count cap is needed.
- **Score weight tuning:** The five-component weights (HRV 35%, sleep 25%, load 20%, cycle 15%, RHR 5%) are grounded in competitor analysis but not empirically validated for this user population. Implement as injectable constants so they can be tuned without architectural changes.
- **Sleep permission UX for users without Apple Watch:** Users with no sleep stage data need copy that explains "score is limited, not broken." This is a UX gap to address in Phase 1 design, not implementation.

---

## Sources

### Primary (HIGH confidence)
- [HKCategoryValueSleepAnalysis — Apple Developer Docs](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [heartRateVariabilitySDNN — Apple Developer Docs](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn)
- [CKShare — Apple Developer Docs](https://developer.apple.com/documentation/cloudkit/ckshare)
- [Sharing CloudKit Data with Other iCloud Users — Apple Developer Docs](https://developer.apple.com/documentation/CloudKit/sharing-cloudkit-data-with-other-icloud-users)
- [apple/sample-cloudkit-zonesharing — GitHub](https://github.com/apple/sample-cloudkit-zonesharing)
- [Menstrual cycle changes in vagally-mediated HRV — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7141121/)
- Existing codebase `/SundeeFundee/Sources/SundeeFundeeKit/` (direct inspection)

### Secondary (MEDIUM confidence)
- [HRV and readiness — Marco Altini, Medium](https://medium.com/@altini_marco/on-heart-rate-variability-hrv-and-readiness-394a499ed05b)
- [Zone sharing in CloudKit — Swift with Majid](https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/)
- [Acute:Chronic Workload Ratio — Science for Sport](https://www.scienceforsport.com/acutechronic-workload-ratio/)
- [Apple Developer Forums: Non-overlapping sleep samples](https://developer.apple.com/forums/thread/730258)
- [HealthKit Background Delivery — Apple Developer Docs](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery)
- [Readiness, recovery, and strain: consumer wearables evaluation — ResearchGate](https://www.researchgate.net/publication/390665585_Readiness_recovery_and_strain_an_evaluation_of_composite_health_scores_in_consumer_wearables)

### Tertiary (MEDIUM-LOW confidence)
- [CloudKit Sharing limits — Apple Developer Forums](https://developer.apple.com/forums/thread/767226) — participant limit guidance (forum thread, not official docs)
- Athlytic / Cora / HRV4Training recovery score pattern survey — behavioral inference from App Store descriptions and help docs

---
*Research completed: 2026-04-15*
*Ready for roadmap: yes*
