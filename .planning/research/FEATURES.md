# Feature Research

**Domain:** iOS + watchOS native strength training app with hormonal-cycle-aware training adaptation
**Researched:** 2026-03-18
**Confidence:** HIGH (iOS features from existing codebase audit), MEDIUM (watchOS competitor benchmarking from current search)

---

## Context

This is a brownfield project. The Swift codebase already ships: workout logging, cycle tracking + adaptation, injury management, AI workout generation, benchmarks, programs, WODs, subscriptions (StoreKit 2), 1RM tracking, and workout history.

The active work is:
1. Fix critical bugs in the existing iOS app
2. Add a watchOS companion app
3. Achieve feature parity with the React Native build (push notifications, analytics, data export, account management)
4. Ship to the App Store

Features already built are marked **[EXISTS]**. Gaps are marked **[MISSING]** or **[PARTIAL]**.

---

## Feature Landscape

### Table Stakes — iOS (Users Expect These)

Features that every serious strength training app in 2025 has. Missing these = users leave.

| Feature | Why Expected | Status | Complexity | Notes |
|---------|--------------|--------|------------|-------|
| Workout logging (sets, reps, weight) | Core utility | **[EXISTS]** | — | SwiftData backed, CompletedWorkout/CompletedSet models |
| Exercise library with search | Can't log what you can't find | **[EXISTS]** | — | Bundled catalog; custom exercise creation unknown |
| Rest timer between sets | Universally expected since ~2018 | **[EXISTS]** | — | Implemented; needs APNs notification for background |
| Personal record (PR) detection + celebration | Every competitor has this | **[EXISTS]** | — | Celebration overlay + NotificationCenter post |
| 1RM tracking | Strength baseline | **[EXISTS]** | — | Max lifts feature exists |
| Workout history with summary | Users review past performance | **[EXISTS]** | — | History tab exists |
| Progressive overload visibility | Core reason users use apps vs paper | **[EXISTS]** | — | Volume tracking implied by history; explicit week-over-week view unknown |
| Weight unit toggle (lbs / kg) | Required for non-US market | **[PARTIAL]** | LOW | Unit preference exists; AI weight bug documented in CONCERNS.md |
| Apple Watch companion | Competitor standard since 2022; users expect wrist logging | **[MISSING]** | HIGH | Primary active requirement |
| Push notifications — rest timer | Users expect phone-down gym experience | **[MISSING]** | MEDIUM | APNs infrastructure needed |
| Push notifications — workout reminders | Standard feature | **[MISSING]** | LOW | Requires APNs + user permission flow |
| In-app account deletion | Apple App Store mandatory since June 2022 | **[PARTIAL]** | LOW | `deleteAccountAndData` exists but references stale V10 schema (CONCERNS.md) |
| Sign in with Apple | App Store guideline when third-party auth exists | **[EXISTS]** | — | Fully implemented |
| CloudKit / iCloud sync | Users expect data on all their Apple devices | **[PARTIAL]** | MEDIUM | Implemented but disabled in production (flag flip needed) |
| Subscription + paywall | Monetization expected | **[EXISTS]** | — | StoreKit 2, Free/Plus/Pro tiers |
| Onboarding flow | Personalization from day 1 | **[EXISTS]** | — | 5-step onboarding |
| Settings screen | Units, notifications, account | **[EXISTS]** | — | Exists; notification settings needed |

### Table Stakes — watchOS Companion

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Active workout session (HKWorkoutSession) | Required for Activity Ring contribution + sensor access | HIGH | Must use HKWorkoutSession + HKLiveWorkoutBuilder; keeps app foregrounded on wrist during workout |
| Log sets from wrist | Core reason to have a Watch app | HIGH | Tap-to-complete set, weight/rep entry via Digital Crown or number picker |
| Current exercise display | User needs to know what to do next | MEDIUM | Exercise name, target sets/reps, previous performance |
| Rest timer on wrist | Removes need to look at phone | MEDIUM | Countdown with haptic + crown scroll to extend/skip |
| Heart rate display during workout | Users expect biometrics | LOW | Provided automatically by HKLiveWorkoutBuilder |
| Calories burned display | Users expect it | LOW | Provided automatically by HKLiveWorkoutBuilder |
| Activity ring contribution | Workout must count toward Move/Exercise rings | HIGH | Requires proper HKWorkoutSession workout type (Traditional Strength Training) |
| Auto-navigate to Watch app when workout starts | UX expectation for companion apps | MEDIUM | iPhone starts session, Watch mirrors via HealthKit mirroring API (iOS 17+/watchOS 10+) |
| End workout from wrist | User should not need phone to finish | MEDIUM | Proper shutdown sequence: end session before finishWorkout() |
| Workout summary on Watch | Immediate post-workout feedback | LOW | Duration, sets completed, calories, heart rate |
| Sync to iPhone after workout | Data must appear in history | HIGH | HealthKit mirroring or Watch Connectivity; offline support needed |

### Differentiators (Competitive Advantage)

These are what set Sundee Fundee apart. Not universally expected but valued — and some are already built.

| Feature | Value Proposition | Status | Complexity | Notes |
|---------|-------------------|--------|------------|-------|
| Hormonal cycle adaptation engine | No competitor (at this quality) does load/volume/exercise adjustment per cycle phase for strength training | **[EXISTS]** | — | `CycleProgramGenerator.adaptProgram` is a genuine differentiator |
| Injury modification + body map | Context-aware substitutions; reduces dropout from injury | **[EXISTS]** | — | `InjuryAdaptationEngine`, pain logging, rehab generation |
| AI workout generation (Gemini) | Personalized, context-aware workout generation vs cookie-cutter programs | **[EXISTS]** | — | Requires fix: lbs-only weight bug for metric users |
| Readiness survey driving daily adaptation | Combines subjective feel with objective cycle phase for daily adjustment | **[EXISTS]** | — | "Spicy rating" + readiness score |
| Cycle phase education during adaptation | Users understand *why* today's workout changed | **[MISSING]** | MEDIUM | Phase-specific explanation copy needed in UI |
| watchOS cycle phase glance | See cycle phase + training recommendation without opening phone | **[MISSING]** | MEDIUM | Watch complication or glance view; differentiates from generic workout apps |
| Art Deco design aesthetic | Memorable, premium feel vs generic fitness app grids | **[EXISTS]** | — | Cream/navy/orange palette; strong brand identity |
| Programs with enrollment + adaptive execution | Structured progression + adaptation; not just a log | **[EXISTS]** | — | CloudKit program delivery + enrollment tracking |
| WOD (Workout of the Day) system | Daily variety; community touchpoint | **[EXISTS]** | — | Bundled + CloudKit delivery |
| Benchmark system (WOD-style scoring) | Goal-setting and achievement tracking beyond PRs | **[EXISTS]** | — | Benchmark catalog with `roundsAndReps` scoring |
| Plate calculator (barbell math) | Everyday gym tool; keeps users in-app | **[EXISTS]** | — | `PlateCalculation` domain |
| HealthKit readiness integration (HRV, sleep, resting HR) | Objective recovery data feeding adaptation | **[EXISTS]** | — | Read-only currently; HRV + sleep + RHR |
| Data export (CSV/ZIP) | Empowers power users; trust signal | **[MISSING]** | MEDIUM | In RN build; not in Swift codebase |
| Workout analytics + volume charts | Progress visibility beyond raw PRs | **[MISSING]** | MEDIUM | Sets per muscle group, weekly volume trends |
| Push notifications — streak reminders | Habit formation; engagement | **[MISSING]** | LOW | APNs infrastructure needed first |
| Push notifications — WOD alerts | Daily touchpoint driving engagement | **[MISSING]** | LOW | Requires APNs + remote push |
| watchOS complication (last workout, streak, cycle phase) | Glanceable data on watch face; retention | **[MISSING]** | MEDIUM | WidgetKit complications; differentiating against competitors |
| Shared workout templates (CloudKit public DB) | Community/social angle without social complexity | **[EXISTS]** | — | Anonymous contribution; crowdsourced templates |

### Anti-Features (Deliberately Avoid)

| Anti-Feature | Why Requested | Why Problematic | What to Do Instead |
|--------------|---------------|-----------------|-------------------|
| Social feed / activity sharing | Engagement metrics; competitors like Hevy have it | Entirely different product surface; moderation burden; dilutes strength training focus; not core to cycle-aware value | Anonymous shared workout templates already provide community feel without social infrastructure |
| Nutrition / macro tracking | Users ask for it; fitness apps bundle it | Distinct domain with its own complexity, separate databases, and separate expertise; dilutes the strength training + cycle-awareness focus | Recommend/integrate with Apple Health for nutrition; note as out of scope |
| Video exercise library (embedded) | Users want to see form demonstrations | Storage costs, bandwidth, CDN, content maintenance, licensing; not how premium apps win | Link to external references or use still-image illustrations; table this for v2+ |
| Real-time coaching / chat | "Personal trainer in your pocket" appeal | Real-time infrastructure complexity; support burden; liability; the AI workout generator already serves this need | Lean into AI generation + cycle adaptation as the coaching surface |
| Android / Web builds | Wider market | Customer explicitly requires Apple-only; adds cross-platform overhead that degrades native experience | Stay Apple-native; Apple Watch integration requires it |
| Manual CloudKit record management UI | Power users want to inspect/edit data | Fragile; exposes internal schema to users; not how consumer apps work | Data export as CSV is the correct power-user escape hatch |
| Gamification (badges, points, leaderboards) | Engagement; Hevy has leaderboards | Shallow engagement vs genuine training value; cycle-aware women's health niche users tend to distrust gimmicks | Streak tracking and PR celebrations are enough gamification; focus on training quality |

---

## Feature Dependencies

```
[CloudKit sync (activate)] ──required for──> [Multi-device sync]
[CloudKit sync (activate)] ──required for──> [iCloud backup]

[Push notifications (APNs infrastructure)]
    └──required for──> [Rest timer background notification]
    └──required for──> [Workout reminder push]
    └──required for──> [WOD alert push]
    └──required for──> [Streak reminder push]

[watchOS: HKWorkoutSession]
    └──required for──> [Activity ring contribution]
    └──required for──> [Heart rate / calorie display during workout]
    └──required for──> [App stays foregrounded on wrist during workout]

[watchOS: HealthKit mirroring session (iOS 17/watchOS 10)]
    └──required for──> [iPhone ↔ Watch live sync during workout]
    └──required for──> [Workout data appears in iOS history after Watch-only session]

[watchOS: Set logging on Watch]
    └──requires──> [WatchConnectivity or HealthKit mirroring data channel]
    └──requires──> [Exercise list delivery to Watch]

[WidgetKit complications]
    └──enhances──> [watchOS cycle phase glance]
    └──enhances──> [streak / last workout display on watch face]

[Data export]
    └──requires──> [Account deletion flow] (logically paired; user data rights)
    └──enhances──> [Trust with power users]

[Fix AI weight unit bug]
    └──required before──> [AI workout generation is usable for metric users]

[Fix sign-out stale V10 schema]
    └──required before──> [Account deletion is compliant with App Store rules]

[Fix guest UUID (stable ID)]
    └──required before──> [Guest users who sign in don't lose data]
```

### Dependency Notes

- **watchOS companion requires HKWorkoutSession**: Cannot contribute to Activity rings or keep the Watch app foregrounded without a proper workout session. This is not optional — users will notice if workouts don't appear in Fitness.app.
- **APNs infrastructure before any push notifications**: Rest timer, reminders, WODs — all blocked until APNs entitlements, permission flow, and token registration are in place.
- **Critical bugs before feature work**: The AI weight bug, stale schema on sign-out, and guest UUID issue should be resolved before shipping new features that compound these problems.
- **CloudKit activation before watchOS sync**: Watch-to-iPhone sync via HealthKit mirroring is independent of CloudKit, but iCloud multi-device sync is broken without activating the CloudKit container.

---

## MVP Definition

### Launch With (v1) — App Store Submission

The bar for App Store submission given existing functionality:

- [x] **Fix critical bugs** — weight unit in AI, stale schema on sign-out, guest UUID, subscription cold-launch window (CONCERNS.md). These are blocking correctness issues.
- [x] **Activate CloudKit sync** — Flip the `useCloudKit` flag, confirm entitlements. Without this, advertised iCloud sync is a lie.
- [x] **watchOS companion: basic workout logging** — HKWorkoutSession, current exercise + set display, tap-to-log a set, rest timer on wrist, heart rate/calories, end workout, sync to iOS. Minimum viable Watch experience.
- [x] **Push notifications: rest timer** — The single highest-value notification; lets users put phone down between sets. APNs infrastructure unlocks all other notifications.
- [x] **Account deletion (compliant)** — Fix the stale V10 schema reference; App Store requires this to work correctly.
- [x] **Weight unit fix end-to-end** — Metric users are currently broken on AI workouts. Unacceptable for launch.

### Add After Validation (v1.x)

Features that improve the experience once the core is working:

- [ ] **Push notifications: workout reminders + streak reminders** — Habit loop completion; add after APNs infrastructure lands.
- [ ] **Push notifications: WOD alerts** — Daily touchpoint; add after reminder flow is stable.
- [ ] **watchOS complication** — Cycle phase + streak on watch face; drives daily engagement.
- [ ] **Data export (CSV)** — Power user trust; required for GDPR completeness.
- [ ] **Analytics: volume charts, sets per muscle group** — Progress visibility; differentiate further.
- [ ] **Cycle phase education UI** — Explain *why* the workout changed today; reduces confusion for new users.

### Future Consideration (v2+)

- [ ] **HealthKit write (workout save to Health.app)** — Write entitlement declared but not implemented; v2 feature.
- [ ] **Video exercise demonstrations** — High value but high cost; defer until PMF established.
- [ ] **Advanced AI personalization (history-aware)** — Gemini prompt currently uses current context; feeding full history requires token budget management and v2 architecture.
- [ ] **Apple Watch independent session (no iPhone required)** — Phone-free gym experience; technically feasible via watchOS standalone app + background session; complex to implement correctly with offline sync.
- [ ] **watchOS 26 Workout Buddy integration** — Apple's new AI coaching layer (WWDC 2025); relevant once watchOS 26 is mainstream (2026+).

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Fix critical bugs (weight unit, schema, guest UUID) | HIGH | LOW | P1 |
| Activate CloudKit sync | HIGH | LOW | P1 |
| Account deletion compliance fix | HIGH | LOW | P1 |
| watchOS: HKWorkoutSession + set logging | HIGH | HIGH | P1 |
| watchOS: Rest timer on wrist | HIGH | MEDIUM | P1 |
| Push notifications: rest timer (APNs infra) | HIGH | MEDIUM | P1 |
| watchOS: Heart rate / calories display | MEDIUM | LOW | P1 |
| Push notifications: workout reminders | MEDIUM | LOW | P2 |
| watchOS: Complication (cycle phase, streak) | MEDIUM | MEDIUM | P2 |
| Data export (CSV) | MEDIUM | MEDIUM | P2 |
| Cycle phase education in UI | MEDIUM | LOW | P2 |
| Workout volume analytics / charts | MEDIUM | MEDIUM | P2 |
| Push notifications: WOD alerts | LOW | LOW | P2 |
| watchOS: Independent session (phone-free) | MEDIUM | HIGH | P3 |
| Video exercise library | HIGH | HIGH | P3 |
| History-aware AI personalization | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for App Store launch
- P2: Add in first update cycle after launch
- P3: Future consideration (v2+)

---

## Competitor Feature Analysis

| Feature | Strong (Strong App) | Hevy | Our Approach |
|---------|---------------------|------|--------------|
| Apple Watch app | Full — set logging, rest timer, HR, calories, Handoff | Full — leave phone in locker, full sync | Full parity required; add cycle phase glance as differentiator |
| Rest timers | Auto-start after set completion | Auto-start, log from notification | Auto-start + background APNs notification + Watch haptic |
| Exercise library | Large, video demos | 1000+ exercises, video | Bundled catalog; custom exercises; no video at launch |
| AI / personalization | None | HevyGPT (basic) | Gemini-powered + cycle-aware adaptation = significant advantage |
| Cycle awareness | None | None | Core differentiator — no mainstream competitor has this |
| Social features | Minimal | Social feed, leaderboards, Strava | Shared templates only; no feed |
| Data export | Yes (CSV) | Yes | Add in v1.x; currently missing |
| Complications | Unknown | Custom watch faces | WidgetKit complications for Watch face |
| Subscription model | Freemium | Freemium | Free/Plus/Pro via StoreKit 2 |
| Programs | Yes | Yes (routines) | Yes, CloudKit-delivered |
| Analytics | Volume charts, 1RM graphs | Monthly reports, muscle distribution | Missing — add in v1.x |
| HealthKit integration | Yes | Yes | Yes (read: HRV, sleep, RHR); write incomplete |
| iCloud sync | No (iCloud Drive workaround) | CloudKit | Full CloudKit sync once activated |

---

## watchOS-Specific Features (Detailed)

### Required for Shipping

| Feature | Technical Approach | Notes |
|---------|--------------------|-------|
| HKWorkoutSession + HKLiveWorkoutBuilder | Traditional Strength Training workout type | Keeps Watch app foregrounded; contributes to Activity rings; provides HR + calories automatically |
| HealthKit mirroring session (iOS 17/watchOS 10+) | `HKWorkoutSession.startMirroringToCompanionDevice()` | Replaces Watch Connectivity for workout sync; bidirectional data channel; handles reconnect |
| Set logging UI | Digital Crown for weight/rep adjustment; swipe gestures for next exercise | Single-focus design: one set at a time per Apple HIG for Watch |
| Rest timer | Countdown view + haptic on completion | Uses WKHapticType.notification; foreground display during rest |
| Exercise name + targets display | Sent from iPhone via mirroring data channel | Current exercise, target sets × reps, previous best weight |
| End workout action | Proper shutdown: `session.end()` then `builder.finishWorkout()` | Critical order per Apple docs; incorrect order causes data loss |
| Workout session recovery | `handleActiveWorkoutRecovery()` on Watch app launch | Handles app termination during workout; must recover state |

### Differentiating Watch Features

| Feature | Technical Approach | Notes |
|---------|--------------------|-------|
| Cycle phase glance during workout | Phase + adaptation reason sent via mirroring channel | e.g., "Follicular — peak strength phase. Push hard today." |
| Watch face complication | WidgetKit complication with CLKComplicationTemplate | Show cycle phase, streak count, or last workout date; drives daily app opens |
| Haptic cues for PR | `WKInterfaceDevice.current().play(.success)` on new PR detection | Immediate wrist feedback when a personal record is set |

### What to NOT Build on Watch at Launch

| Feature | Why Defer |
|---------|-----------|
| Independent Watch session (no iPhone) | Complex offline sync + background session; not table stakes for companion app positioning; adds significant test surface |
| AI workout generation on Watch | Network call from Watch is unreliable; start workouts from iPhone |
| Full program enrollment flow on Watch | Multi-step UI doesn't work well on Watch; start programs from iPhone |
| Cycle logging on Watch | Period/symptom logging requires deliberate input; better on iPhone |
| Social / shared workout templates on Watch | Not a gym-floor use case |

---

## Sources

- [Strong for Apple Watch — Strong Help Center](https://help.strongapp.io/article/222-strong-for-apple-watch) — MEDIUM confidence (official product docs)
- [Hevy App Features](https://www.hevyapp.com/features/) — MEDIUM confidence (official product page)
- [Building a Workout App for Apple Watch — Sasquatch Studio, March 2025](https://sasq.ca/blog/2025/3/2/building-a-workout-app-for-apple-watch) — MEDIUM confidence (practitioner article, current)
- [HKWorkoutSession — Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/hkworkoutsession) — HIGH confidence (official)
- [watchOS 26 announcements — Apple Newsroom, June 2025](https://www.apple.com/newsroom/2025/06/watchos-26-delivers-more-personalized-ways-to-stay-active-and-connected/) — HIGH confidence (official)
- [Apple App Store account deletion requirement — Apple Developer News](https://developer.apple.com/news/?id=12m75xbj) — HIGH confidence (official)
- [Best Workout Tracker Apps for iPhone in 2025 — Setgraph](https://setgraph.app/ai-blog/best-workout-tracker-apps-for-iphone) — LOW confidence (third-party roundup)
- [Best cycle syncing apps 2025](https://cycle-syncing.org/best-cycle-syncing-app/) — LOW confidence (third-party)
- [DC Rainmaker: watchOS 26 Workout Buddy real world](https://www.dcrainmaker.com/2025/07/apple-watchos-26-workout-buddy-real-world.html) — MEDIUM confidence (respected fitness tech reviewer)
- Existing codebase audit (CONCERNS.md, ARCHITECTURE.md, INTEGRATIONS.md) — HIGH confidence

---

*Feature research for: iOS + watchOS strength training app with cycle-aware adaptation*
*Researched: 2026-03-18*
