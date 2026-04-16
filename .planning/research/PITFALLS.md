# Domain Pitfalls

**Domain:** Cycle-aware strength training app — recovery scoring, deload automation, CloudKit social
**Researched:** 2026-04-15
**Milestone context:** Subsequent milestone adding to existing app with Swift 6 strict concurrency, actor-based data clients, zero external dependencies

---

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, or App Store rejection.

---

### Pitfall 1: HRV Scores Drop in Luteal Phase — Algorithm Misreads as Fatigue

**What goes wrong:** HRV decreases 10–20% during the luteal phase as progesterone suppresses parasympathetic activity. A recovery score algorithm that treats all HRV drops as training fatigue will trigger false "low recovery" readings and premature deload suggestions every cycle, independent of actual training load.

**Why it happens:** Research confirms HRV is significantly lower in the luteal phase even with optimal sleep and no training stress. Progesterone is the primary driver — not fatigue, not sleep debt. An algorithm that baselines HRV globally rather than phase-specifically will systematically misread this population.

**Consequences:** Deload suggestions fire every luteal phase regardless of training load. Users distrust the score ("it's always low before my period"). Deload automation becomes noise rather than signal.

**Prevention:**
- Maintain a per-phase HRV baseline: compute rolling average HRV within each cycle phase, not across the whole cycle
- When computing recovery score, compare current HRV to the current phase's expected range, not the global 30-day average
- The `CyclePhaseHelper` and `multiplier-based adaptation` system already phase-codes training — apply the same phase-awareness to the recovery score denominator

**Detection:** If deload suggestions always fire in luteal phase and almost never in follicular phase, the baseline is phase-blind. Check against cycle calendar before shipping.

**Phase:** Recovery Score implementation (Phase 1)

---

### Pitfall 2: Sleep Sample Deduplication Produces Double-Counted Sleep Duration

**What goes wrong:** HealthKit intentionally returns overlapping sleep samples. An Apple Watch records per-stage samples (Awake, Core, REM, Deep) while the iPhone simultaneously records an InBed interval covering the same time window. Summing all returned samples without deduplication inflates sleep duration by 2–3x. A user who slept 7 hours could appear to have slept 14 hours.

**Why it happens:** HealthKit is designed to store samples from multiple sources simultaneously. The `HKSampleQuery` returns all of them. Apple explicitly states deduplication is the developer's responsibility.

**Consequences:** Sleep component of the recovery score is meaningless. High-sleep scores for poor sleepers. The whole composite score drifts.

**Prevention:**
- When fetching `HKCategoryTypeIdentifier.sleepAnalysis`, filter by source bundle ID. Prefer `com.apple.health` (Watch-sourced stage data) over `com.apple.Health` (iPhone bedtime estimate).
- When sources overlap, take the most granular (Watch stages > iPhone InBed).
- Sort samples by start date, then merge overlapping intervals before summing duration.
- During development, test with real devices — the simulator produces single-source data that hides this bug entirely.

**Detection:** Log total sleep duration alongside raw sample count. If duration exceeds 12 hours or sample count exceeds 30 for a single night, deduplication is broken.

**Phase:** HealthKit sleep integration (Phase 1)

---

### Pitfall 3: CloudKit User Discovery Fully Deprecated — No Viable Friend-Finding Without Contacts

**What goes wrong:** `CKDiscoverUserIdentitiesOperation` (contact-based user lookup) and `CKDiscoverAllUserIdentitiesOperation` (find all app users) are deprecated. As of iOS 17, there is no CloudKit API to find other users of your app by email or phone number without going through the Contacts framework, and Apple's privileged access to Contacts for this purpose is not available to third-party apps. The only supported path for adding a friend is sending a share URL out-of-band (Messages, AirDrop, email) and having the recipient accept it.

**Why it happens:** Apple deprecated social-graph discovery for privacy reasons. The only sanctioned model is explicit invitation: user A generates a CKShare URL, sends it to user B via an external channel, and B accepts.

**Consequences:** "Find friends who use Sundee Fundee" is not implementable via CloudKit alone. Username search is not implementable. The social UX must be built around share links, not user search. This affects onboarding and friend-add UX design.

**Prevention:**
- Design the friend-add flow as invite-link only from the start. Do not design a "search by name/email" flow expecting to add it later — there is no API path for it.
- Use `UICloudSharingController` for the invitation UI — it handles permission prompts and participant management.
- Document the constraint explicitly in the social feature spec so the design does not include a search screen.

**Detection:** If the design includes a "Find friends" or "Search users" screen backed by CloudKit, the feature cannot ship as designed. Catch this in design review, not implementation.

**Phase:** Social/friends feature (Phase 3)

---

### Pitfall 4: One CKShare Per Zone — Feeds Require Per-User Zone Architecture

**What goes wrong:** CloudKit allows exactly one `CKShare` per custom zone. If the social design creates a single shared zone per user for their activity feed, that works. But if a design assumes one zone can hold multiple independently shareable groups of records (e.g., "share workouts with group A, share benchmarks with group B"), each group requires its own zone with its own `CKShare`. Attempts to add a second `CKShare` to a zone replace the first.

**Why it happens:** The CloudKit zone-sharing model is one-share-per-zone by design. There is no sub-zone scoping.

**Consequences:** Permission models that need independent sharing of different record subsets require zone proliferation. Each new friendship means a new zone. With 50 friends, a user has 50 zones or the architecture needs rethinking.

**Prevention:**
- Design one zone per user as their "activity zone" — they own it, friends read it. This is the correct model for a friend feed.
- Zone sharing cannot coexist with hierarchical sharing in the same zone — pick one model and do not mix them.
- Validate the zone count ceiling: CloudKit limits custom zones per database (currently 255 per private database per container). 50–100 friends would consume 50–100 zones — manageable but worth tracking.

**Detection:** If the architecture doc shows a single zone being shared with multiple friends at different permission levels, the zone model is wrong.

**Phase:** Social/friends feature (Phase 3)

---

### Pitfall 5: Swift 6 Strict Concurrency Violations with HKHealthStore Callbacks

**What goes wrong:** `HKHealthStore` query callbacks fire on arbitrary background threads. `HKSample` subclasses are not `Sendable`. In Swift 6 strict concurrency mode, passing HealthKit results across actor boundaries without explicit `@Sendable` closures or value copies produces compiler errors that are non-trivial to fix mid-feature. If not addressed during design, they surface as a cascade of errors during actor integration.

**Why it happens:** The HealthKit SDK was not designed with Swift 6 concurrency in mind. Query completion handlers are pre-actor-era APIs.

**Consequences:** Initial HealthKit integration code compiles under relaxed mode, then fails when integrated into the actor-based `DataClientFactory` infrastructure. Large refactors mid-feature.

**Prevention:**
- Wrap all HealthKit fetch operations in a dedicated `HealthKitClient` actor that bridges callback-based HK APIs to `async/await`.
- Extract only `Sendable`-compatible values (primitives, `Date`, `Double`, `String`) from `HKSample` objects inside the query handler before crossing actor boundaries. Never pass raw `HKSample` instances across actors.
- Use `withCheckedContinuation` or `withCheckedThrowingContinuation` to bridge callback-to-async. Test compilation with `SWIFT_STRICT_CONCURRENCY: complete` from the first commit.

**Detection:** Any `HKSample` reference stored as a property outside the HealthKit callback scope, or passed to a `@MainActor` method, is a concurrency violation waiting to fail.

**Phase:** Recovery Score / HealthKit integration (Phase 1)

---

### Pitfall 6: Background Delivery Fires Unreliably — Do Not Build Time-Critical Logic on It

**What goes wrong:** `HKObserverQuery` with `enableBackgroundDelivery()` promises to wake the app when new data arrives. In practice, the system delivers notifications hourly at best and sometimes once per day. Sleep data is particularly problematic: Watch syncs sleep to iPhone asynchronously after wake-up. If the recovery score computation is triggered by a background delivery, morning scores may compute before sleep data has synced, producing stale inputs.

**Why it happens:** iOS aggressively throttles background wake-ups. The frequency parameter in `enableBackgroundDelivery()` is advisory, not guaranteed. Watchdog timeouts (15 seconds) kill the background task if processing is slow.

**Consequences:** Recovery scores appear on the dashboard before they are ready. Users open the app at 8am and see yesterday's score or a score computed before Watch sync completed.

**Prevention:**
- Compute the recovery score lazily on app foreground, not on background delivery.
- On foreground: fetch the latest sleep/HRV data, then compute and display.
- Background delivery should only invalidate a cached score (set a `needsRefresh` flag), not trigger computation.
- Show the score computation timestamp ("Computed 7:34 AM") so users can see data freshness.

**Detection:** Test the flow by opening the app within 5 minutes of waking up. If the sleep duration shows 0 or yesterday's value, background delivery raced ahead of Watch sync.

**Phase:** Recovery Score dashboard (Phase 1)

---

## Moderate Pitfalls

---

### Pitfall 7: Deload Trigger Has No Minimum Cooldown — Fires Repeatedly

**What goes wrong:** An auto-detect deload algorithm based on acute:chronic workload ratio (ACWR) or multi-day low recovery scores can trigger a second deload suggestion within days of the user completing one. The algorithm doesn't know the user just finished a deload week.

**Prevention:**
- After any accepted deload, suppress deload detection for at least 4 weeks.
- Track deload state explicitly in the data layer (last deload date, current deload active flag).
- The deload suggestion should only fire if: (a) fatigue signals meet threshold AND (b) last deload was more than 4 weeks ago AND (c) no deload is currently active.

**Phase:** Deload detection (Phase 2)

---

### Pitfall 8: Composite Score Weights Are Arbitrary Without Personalization Anchor

**What goes wrong:** Apps typically weight HRV at ~40% and sleep at ~20–30%, but these weights are population-level averages with no peer-reviewed validation for individual users. For users on hormonal contraceptives, HRV fluctuates differently. For shift workers, sleep duration is structurally poor but performance is normal. A fixed weight formula will persistently score some users poorly.

**Prevention:**
- Start with HRV + sleep as inputs but weight cycle phase heavily (it is the app's core differentiator).
- Do not present the recovery score as medically validated — frame it as a personalized readiness estimate.
- Build the score computation as a pure function with injectable weights so the formula can be tuned without architectural changes.
- Add a "score explanation" tap-through from day one. Users who understand why the score is low are far less likely to disengage.

**Phase:** Recovery Score algorithm (Phase 1)

---

### Pitfall 9: CloudKit sharedCloudDatabase Requires Separate Query Path

**What goes wrong:** Records saved by a friend in their private database are read by you from `sharedCloudDatabase`, not `privateCloudDatabase`. Developers who build queries against `privateCloudDatabase` (the existing pattern in `CloudKitClient`) and assume they can read shared records the same way will get empty results with no error.

**Prevention:**
- The friend feed must use a separate fetch path against `sharedCloudDatabase`.
- The existing `CloudKitClient` needs a second query path that explicitly targets the shared database container.
- Record types in the shared zone must match exactly — test with two physical iCloud accounts during development.

**Detection:** If friend activity never appears in the feed and no error is thrown, the wrong database is being queried.

**Phase:** Social friend feed (Phase 3)

---

### Pitfall 10: HealthKit Authorization Denial Silently Appears as Empty Data

**What goes wrong:** `HKHealthStore.authorizationStatus(for:)` always returns `.notDetermined` or `.sharingAuthorized` for read types — it never returns `.sharingDenied` for privacy reasons. If the user denied sleep or HRV access, queries return zero samples with no error. Code that treats zero samples as "no data yet" rather than "possibly denied" will display a permanently incomplete score with no explanation.

**Prevention:**
- After a query returns zero samples for a data type that should have data (e.g., the user has an Apple Watch), prompt the user to check HealthKit permissions in Settings.
- Show a distinct UI state: "Sleep data unavailable — check Health permissions" rather than silently omitting the sleep component from the score.
- Request authorization for sleep types at feature onboarding, not lazily at first fetch. Handle the case where the user has never worn a Watch and genuinely has no HRV data.

**Phase:** HealthKit integration (Phase 1)

---

## Minor Pitfalls

---

### Pitfall 11: Active Recovery Suggestions Repeat Without Variety Tracking

**What goes wrong:** The deload week generates active recovery suggestions (mobility, yoga, light cardio). If the same suggestions appear every deload week, users disengage. Without tracking which suggestions were recently shown, the generator defaults to its top-ranked items every time.

**Prevention:** Track the last 2–3 deload weeks' suggestions in the data layer. Rotate suggestion pools based on recency to avoid repetition.

**Phase:** Deload generation (Phase 2)

---

### Pitfall 12: High-Five Reactions Create Notification Spam

**What goes wrong:** If each high-five on a friend's activity generates a push notification, a user with 20 active friends gets dozens of notifications per day. Users turn off all notifications.

**Prevention:** Batch reaction notifications ("3 friends high-fived your PR") rather than one per reaction. Use a delivery delay of 15–30 minutes before sending a batched summary. This is a pure CloudKit record design decision — implement it before the notification system is wired.

**Phase:** Social reactions (Phase 3)

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Recovery score — HRV component | Phase-blind baseline (Pitfall 1) | Per-phase rolling average, not global |
| HealthKit sleep fetch | Duplicate samples (Pitfall 2) | Source filter + overlap merge before summing |
| HealthKit client actor | Swift 6 Sendable violations (Pitfall 5) | Dedicated HealthKitClient actor, extract primitives only |
| Recovery score morning read | Background delivery race (Pitfall 6) | Lazy compute on foreground, not background callback |
| Deload detection | No cooldown = repeat suggestions (Pitfall 7) | 4-week suppression window post-deload |
| Recovery score algorithm | Arbitrary weights (Pitfall 8) | Pure function, injectable weights, score explanation UI |
| Friend add UX design | Discovery deprecated (Pitfall 3) | Invite-link-only design from the start |
| Friend feed fetch | Wrong database (Pitfall 9) | sharedCloudDatabase query path, separate from private |
| CloudKit zone architecture | One share per zone (Pitfall 4) | One zone per user as their activity zone |
| HealthKit permission | Silent denial (Pitfall 10) | Explicit "check permissions" UI state |

---

## Sources

- [Apple Developer Forums: Non-overlapping sleep samples](https://developer.apple.com/forums/thread/730258)
- [HealthKit Pitfalls — Beda Software](https://beda.software/blog/apple-healthkit-pitfalls)
- [CloudKit Sharing: Five Tips and Tricks — Dan Griffin](https://contagious.dev/blog/cloudkit-sharing-five-tips-and-tricks/)
- [Zone sharing in CloudKit — Swift with Majid](https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/)
- [Get the most out of CloudKit Sharing — Apple Tech Talks](https://developer.apple.com/videos/play/tech-talks/10874/)
- [Readiness, recovery, and strain: evaluation of composite health scores in consumer wearables](https://www.researchgate.net/publication/390665585_Readiness_recovery_and_strain_an_evaluation_of_composite_health_scores_in_consumer_wearables)
- [HRV and readiness — Marco Altini](https://medium.com/@altini_marco/on-heart-rate-variability-hrv-and-readiness-394a499ed05b)
- [HRV, the Menstrual Cycle, Pregnancy, and Menopause — Marco Altini](https://marcoaltini.substack.com/p/heart-rate-variability-hrv-the-menstrual)
- [Menstrual cycle changes in vagally-mediated HRV associated with progesterone — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7141121/)
- [HealthKit Background Delivery](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery)
- [HKCategoryValueSleepAnalysis — Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [CKShare — Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckshare)
- [Sharing CloudKit Data with Other iCloud Users — Apple Developer Documentation](https://developer.apple.com/documentation/CloudKit/sharing-cloudkit-data-with-other-icloud-users)
- [CloudKit Sharing, Apple, and You — deeje (2023 update)](https://deeje.medium.com/cloudkit-sharing-apple-and-you-900441dbef29)
