# Feature Landscape

**Domain:** Cycle-aware strength training iOS app — recovery scoring, deload automation, and social fitness feed
**Researched:** 2026-04-15
**Confidence:** HIGH for recovery scoring patterns, MEDIUM for social-via-CloudKit, HIGH for deload patterns

---

## Context: What Already Exists

These features are in production and inform what "table stakes" means for the new features:

- Cycle-phase adaptive training (multiplier-based)
- Workout tracking with exercise catalog
- 1RM tracking and plateau detection
- Weekly load analysis and schedule reshuffling
- Program templates and AI workout generation
- Benchmarks with cycle-phase readiness
- Challenge system with lifetime tracking
- Pain/injury tracking with contraindications
- On-device AI coach with memory
- CloudKit persistence with offline sync
- HealthKit HRV reads (wired, not yet used for scoring)
- Share cards for workouts/PRs
- Apple Sign-In with guest mode

---

## Table Stakes

Features users will expect if the marketing describes recovery scoring and social feeds. Missing any of these and the feature feels broken or half-shipped.

### Recovery Score

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Single 0-100 score shown on dashboard | Every competitor (Whoop, Oura, Garmin) uses this convention — any other pattern requires re-education | Low | Score must be visible on first screen without tapping |
| Color-coded zones (green/yellow/red) | Users are trained by Whoop/Oura to read traffic-light recovery; no color = no immediate comprehension | Low | Green 70-100, yellow 40-69, red 0-39 |
| Score breakdown on tap | Users demand to understand why their score is what it is — Oura "Readiness Contributors" screen is the standard | Medium | Show contributing factors with individual ratings |
| HRV as primary input | HRV drives >50% of score weight in every mainstream recovery platform (Whoop, Oura, Garmin Body Battery) | Low | Already wired via `heartRateVariabilitySDNN`; must now be computed into score |
| Sleep quality as a significant input | Garmin Body Battery: sleep is the #1 replenishment signal. Oura: sleep balance + recovery index are explicit contributors | Medium | Requires new HealthKit permission (`HKCategoryTypeIdentifierSleepAnalysis`) |
| Score updates each morning | Whoop and Oura both compute overnight and present score at wake. Intraday updates cause confusion | Low | Compute once per day on app foreground after 6am |
| "Push day vs rest day" recommendation | Project's core value prop — a simple training recommendation tied to the score | Low | Binary recommendation with nuance: "Train hard / Train light / Rest" |

### Deload Automation

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Fatigue detection based on training signals | Fitbod auto-deloads via load trends; no manual deload input is the expectation for smart apps | High | Must aggregate load trends, recovery score, training frequency |
| Explicit confirmation step before deload starts | Users are caught off-guard by auto-changes to their program; Fitbod's "your program has updated" pattern causes confusion without notice | Low | Single-screen: "You seem fatigued. Deload week?" with Confirm/Dismiss |
| Deload replaces lifting with active recovery suggestions | Full rest weeks cause habit regression; Fitbod and Pliability both show this is better UX | Medium | Generate 3-5 low-intensity suggestions (mobility, yoga, light cardio) per deload day |
| Clear start/end for the deload period | Users need to know when normal training resumes | Low | 7-day window; show countdown in dashboard |
| Ability to dismiss/override the deload suggestion | Users who feel fine must be able to say no | Low | Dismiss persists for 7 days before re-detecting |

### Social Feed

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Friends list / follow system | Social feed means nothing without a social graph | High | CloudKit shared zones is the implementation path |
| Activity feed showing friends' workouts, PRs, and milestones | Hevy and Strava established this as the core loop — content without a feed isn't social | Medium | Show event type, timestamp, summary stats |
| Reaction to friend activity (high-five / like) | Strava kudos and Hevy likes are the atomic social unit in fitness apps — 14 billion kudos given on Strava in 2025 | Low | One reaction per activity; simple heart or high-five icon |
| PR notifications in feed | Hevy auto-detects PRs and surfaces them; users expect their achievements to be visible to friends | Low | Piggyback on existing PR/plateau detector output |
| Invite friends via contacts / link | Standard iOS share sheet; Apple Fitness uses this pattern | Low | Deep link or CloudKit share invitation |

---

## Differentiators

Features that distinguish Sundee Fundee from Whoop/Oura (which don't know your cycle) and from Hevy/Strong (which don't score recovery).

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Cycle phase as a recovery input | No competitor factors menstrual cycle phase into recovery score — this is genuinely novel. Follicular phase = higher HRV baseline; luteal phase = HRV suppressed. Score should account for this normalization | Medium | Use existing `CyclePhaseHelper` multipliers; adjust HRV thresholds by phase |
| Cycle-correlated score trends | "Your recovery is always lower in luteal phase" — showing the pattern over time is uniquely useful for this audience | Medium | Requires time-series chart: recovery score vs cycle phase color bands |
| Active recovery suggestions calibrated to cycle phase | Luteal phase active recovery differs from follicular; suggesting gentle yoga vs higher-intensity mobility based on phase is a differentiator | Medium | Extend existing injury/contraindication engine to deload suggestions |
| Pain/injury signals feeding recovery score | Logging pain already happens in-app; no competitor uses pain logs as a recovery input. This gives users a reason to keep logging pain beyond just contraindications | Low | Weight active pain log entries as a recovery depressor |
| Social feed with cycle-phase context (optional) | Friends can optionally see "in luteal phase" as context on low-activity days — normalizes cycle variability in fitness | Medium | Privacy-sensitive: must be explicit opt-in per-user |
| Training volume as a recovery input | Weekly load analyzer output already exists — feeding accumulated training stress into recovery score is a unique synthesis of existing data | Low | Use `WeeklyLoadAnalyzer` output; acute:chronic workload ratio as fatigue proxy |

---

## Anti-Features

Things to explicitly not build in this milestone, even if they seem adjacent.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Leaderboards / competitive ranking | PROJECT.md explicitly rules this out. Strava leaderboards create anxiety and exclusion — not the culture this app wants | High-five reactions only; no rank ordering |
| Social posts with photos | Photos require storage infrastructure (CloudKit asset limits are 1MB per field, 50GB total free), moderation complexity, and slow feed loads. Hevy allows it but it's a significant operational cost | Text + stats only in feed; existing share cards are the photo surface |
| Real-time strain tracking (intraday) | Garmin Body Battery does intraday but requires continuous wear data. This app has no wearable of its own — pulling HealthKit on demand is fine, intraday requires background refresh with significant battery impact | Morning-only score computation |
| Scheduled fixed-interval deloads | PROJECT.md rules this out. Fixed 4-week blocks don't account for cycle variability or real-world fatigue | Adaptive signal-based detection only |
| Social DMs / messaging | Full messaging is a product in itself (moderation, spam, storage). "High-fives" satisfy the connection need | Reactions only; no message threads |
| Recovery score sharing to public feed | Score is personal health data. Sharing should be opt-in and friends-only, never public | Friends-only with privacy controls |
| Subscriptions / paywalls on these features | PROJECT.md: the app is free with no IAPs | All features free for all users |
| Notification spam for every friend activity | Fitness apps lose users to notification fatigue. Strava had to add granular notification controls | Batch notifications; let users configure frequency |
| Body composition or weight tracking integration | Out of scope per PROJECT.md | Defer to v3 |
| External backend for social (Firebase/Supabase) | PROJECT.md explicitly limits to CloudKit | CloudKit shared zones only |

---

## Feature Dependencies

```
HRV data (existing) → Recovery Score
Sleep data (new HealthKit read) → Recovery Score
Cycle Phase (existing CyclePhaseHelper) → Recovery Score (normalization)
Pain log (existing) → Recovery Score
WeeklyLoadAnalyzer (existing) → Recovery Score → Deload Detection
Recovery Score → Deload Detection → Active Recovery Week generation
Recovery Score → Dashboard card (tap-through to breakdown)
Recovery Score trends → Cycle-correlated trends chart

CloudKit shared zones → Friends list
Friends list → Activity feed
Activity feed → Reactions (high-five)
PR/Plateau detector (existing) → Activity feed events
Workout completion (existing) → Activity feed events
Challenge system (existing) → Activity feed events
```

Key constraint: Recovery Score must be built before Deload Detection. Both must be complete before social features can display recovery context. Social graph (friends system) is independent of scoring and can proceed in parallel.

---

## MVP Recommendation

Prioritize in this order based on dependencies and user value:

1. **Recovery Score engine + dashboard card** — Core value prop. Nothing else lands without this. HRV + sleep + cycle phase + pain = score. Display as 0-100 with color zone and "push/rest" recommendation.

2. **Score breakdown detail screen** — Users will not trust a number without explanation. This is the second most-asked question after "what is my score" — "why is my score X?"

3. **Sleep HealthKit integration** — Required input for score accuracy. Without sleep data the score is incomplete and users notice.

4. **Recovery score trends over time** — Cycle-correlated trends is the differentiator. One chart showing score vs cycle phase over 8 weeks proves the cycle-awareness story.

5. **Deload detection + confirmation flow** — Builds on scoring. Auto-detection from load trends + recovery score, single confirmation screen, active recovery suggestions for the week.

6. **Friends system + activity feed** — Independent work stream. CloudKit shared zones. Show workout completions, PRs, challenge achievements.

7. **High-five reactions** — Lowest complexity, high social reward. Build immediately after feed.

**Defer:**
- Social cycle-phase context: Privacy UX needs careful design — defer to after social MVP is live and usage patterns are understood
- Cycle-calibrated active recovery suggestions: Nice-to-have; basic deload suggestions ship first, phase-calibration in a follow-on

---

## Competitive Summary

| App | Recovery Score | Cycle Awareness | Deload Auto | Social Feed | Reactions |
|-----|---------------|-----------------|-------------|-------------|-----------|
| Whoop | Yes (HRV/sleep/RHR) | No | No | No | No |
| Oura | Yes (HRV/sleep/temp) | Yes (but not training-integrated) | No | No | No |
| Garmin Body Battery | Yes (HRV/stress/sleep) | No | No | No | No |
| Fitbod | No | No | Yes (auto) | No | No |
| Hevy | No | No | No | Yes | Yes (likes) |
| Strava | No | No | No | Yes | Yes (kudos) |
| Apple Fitness+ | No | No | No | Yes (ring sharing) | Yes (emoji reply) |
| **Sundee Fundee v2** | **Yes + cycle-normalized** | **Yes (training-integrated)** | **Yes (signal-based)** | **Yes (friends-only)** | **Yes (high-five)** |

No competitor combines all five. The cycle-integrated recovery score is a genuine gap in the market.

---

## Sources

- [WHOOP Recovery: How It Works](https://www.whoop.com/us/en/thelocker/how-does-whoop-recovery-work-101/)
- [WHOOP Developer Docs — 101](https://developer.whoop.com/docs/whoop-101/)
- [Oura Readiness Score](https://ouraring.com/blog/readiness-score/)
- [Oura Readiness Contributors](https://support.ouraring.com/hc/en-us/articles/360057791533-Readiness-Contributors)
- [Garmin Body Battery FAQ](https://support.garmin.com/en-US/?faq=VOFJAsiXut9K19k1qEn5W5)
- [Fitbod Algorithm Q&A](https://fitbod.zendesk.com/hc/en-us/articles/16254175592215-Fitbod-s-Algorithm-Q-A)
- [Hevy Social Features](https://www.hevyapp.com/features/social-features/)
- [Hevy Content Feed](https://www.hevyapp.com/features/content-feed/)
- [Strava Kudos](https://support.strava.com/hc/en-us/articles/216918397-What-is-Kudos)
- [Apple Activity Sharing](https://support.apple.com/guide/iphone/share-your-activity-iph0b826155d/ios)
- [CloudKit Zone Sharing](https://developer.apple.com/videos/play/tech-talks/10874/)
- [Pliability Active Recovery](https://pliability.com/stories/active-recovery-workout)
- [Best Recovery Apps 2026 — Cora](https://www.corahealth.app/blog/best-recovery-apps)
