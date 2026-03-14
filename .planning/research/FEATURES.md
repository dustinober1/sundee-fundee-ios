# Feature Research

**Domain:** Cross-platform fitness / strength training app with hormonal-cycle-aware training
**Researched:** 2026-03-14
**Confidence:** HIGH (core features verified across multiple sources; React Native-specific capability notes are MEDIUM based on library docs + community evidence)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken. Competitors Hevy, Strong, Fitbod, and FitrWoman all cover this ground.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Workout logging (sets, reps, weight) | Core loop of any strength app — without it there's no product | LOW | Must be fast; under 10 seconds per set is the gold standard (Hevy/Strong benchmark). Plate calculator optional but valued. |
| Rest timer (in-workout) | Strength training requires controlled rest periods — users rely on the app to time this | LOW | Background timer required. iOS: `expo-live-activity-timer` or `react-native-background-timer`. Android: foreground service. Both platforms need screen-on during active set. |
| Exercise library with instructions | Users can't log what they can't find; new exercisers need form guidance | MEDIUM | Min 200 exercises with search/filter. Video or animated GIFs are strongly preferred. Can start with static images + description. |
| Personal records (PRs) / 1RM tracking | Seeing progress is the primary retention mechanic — PRs are the clearest signal | LOW | Auto-detect PRs on log completion. Display prominently. 1RM estimation formula (Epley or Brzycki) is expected. |
| Workout history / chronological log | Users reference past sessions to inform current loading decisions | LOW | Chronological list with per-exercise drill-down. Filters by date range and source. |
| Progress charts and analytics | Visualizing strength gains is the core motivation loop | MEDIUM | Minimum: per-exercise volume/load over time. Ideally: total volume, body weight, muscle group breakdown. |
| Offline functionality | Gyms have unreliable connectivity; data loss during a set is unforgivable | HIGH | Core workout logging must work offline. Firestore offline persistence covers this, but local-first architecture decisions must be made early. |
| Auth with social/Apple sign-in | Users expect to recover their data on a new device | LOW | Firebase Auth: Apple Sign-In (required for iOS App Store apps that offer social auth), Google Sign-In (Android parity), Email/Password. Guest mode for frictionless onboarding. |
| Cloud sync / multi-device | Users switch between iPhone, iPad, and Android; data must follow them | MEDIUM | Firestore real-time sync satisfies this. Conflict resolution strategy needed for offline edits. |
| Program/plan catalog | Many users want structure, not just freeform logging | MEDIUM | Pre-built programs with weekly schedule, session structure, and progression scheme. |
| Customizable workout builder | Experienced users want to create their own routines | MEDIUM | Drag-and-drop set ordering. Custom exercises. Superset grouping is highly valued. |
| Notifications and rest timer alerts | Users leave the app mid-workout; they need a push to start the next set | LOW | Local push notifications for rest timer expiry. Not internet-dependent. |
| Settings: units (lbs/kg), language, theme | Internationalisation basics — US users default to lbs, rest of world expects kg | LOW | User preference stored in Firestore profile. |
| Account management and data export | Users want data portability; Apple App Store review requires privacy disclosures | LOW | Export to CSV or JSON. Delete account with data wipe. |

---

### Differentiators (Competitive Advantage)

These are where Sundee Fundee competes. Aligned to core value: "cycle-aware, body-responsive strength training for any platform."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hormonal cycle phase tracking | No major cross-platform strength app does this well. FitrWoman is cycle-only (no lifting programs). WHOOP requires hardware. Sundee Fundee integrates cycle data into strength programming directly. | HIGH | Four-phase model (follicular, ovulatory, luteal, menstrual). Period logging, symptom tracking, predicted phase. Opt-in — non-cycle users must have full functionality without it. |
| Cycle-aware load adaptation | Automatically adjusts weight, sets, and reps based on current cycle phase using evidence-based multipliers | HIGH | Already validated in iOS app. Port the Domain layer to TypeScript. This is the core differentiator — no strength-focused competitor does this automatically. |
| Injury profile and adaptation engine | Adapts exercises around active injuries; substitutes or removes contraindicated movements automatically | HIGH | Already validated in iOS app. Injury profile with recovery phases, pain trend analysis, phase transition advisor. No mainstream competitor offers this depth without a coach. |
| AI workout generation (Gemini) | Generates a personalized workout on demand, adapts to cycle phase and injury status | HIGH | Via Firebase Cloud Functions (replacing Cloudflare Worker). Offline fallback to templated workouts. Competitor Fitbod offers AI but without cycle/injury integration. |
| Rehab session generation | Creates targeted rehabilitation protocols based on injury profile and recovery phase | HIGH | Unique to Sundee Fundee. No major consumer strength app does this. |
| Pain trend analysis | Tracks pain levels over time and surfaces actionable insights (phase transitions, exercise modifications) | MEDIUM | Differentiates from generic fitness apps; positions as a training + recovery partner. |
| Benchmark catalog with result tracking | Structured performance benchmarks (e.g., CrossFit-style named workouts) with historical result tracking and scoring | MEDIUM | Scoring includes ForTime, AMRAP rounds+reps, MaxLoad. Already validated in iOS app. Competitor Strong has no benchmark concept. |
| WOD (Workout of the Day) feed | Daily curated workouts delivered via Firestore, keeps users engaged without needing to plan | MEDIUM | Requires admin tooling (WOD dashboard). Matched by date. Can be cycle-phase annotated. |
| Readiness survey with subjective input | Daily check-in (sleep, energy, stress, motivation) feeds workout adaptation even without wearables | LOW | More accessible than WHOOP/Garmin HRV because it requires no hardware. Ties into AI prompt context. |
| Android + Web reach | FitrWoman and most cycle-aware apps are iOS-only. React Native gives genuine Android parity. | HIGH | This is a business differentiator, not a feature — but it doubles the addressable market. Web adds corporate/desk use case. |
| Art Deco aesthetic | Distinctive visual identity in a sea of dark-mode/neon fitness apps | MEDIUM | Cream/navy/orange palette. Attracts a specific user who finds typical fitness app aesthetics cold or masculine. Retention signal: app feels like *theirs*. |
| Dual pricing (RevenueCat mobile / Stripe web) | Web subscribers pay less, incentivizing direct purchase. Reduces App Store cut for a meaningful segment. | MEDIUM | RevenueCat handles app store entitlement validation. Stripe webhook updates Firestore subscription status. Requires entitlement syncing logic. |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem natural to build but create disproportionate cost or harm product focus.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Social feed / friend activity | "Everyone does it" — Hevy built 5M users partly on social | Massive ongoing moderation cost; shifts product identity from training tool to social network; content moderation is a second product | PR notifications + leaderboard within a specific program or challenge are sufficient social proof without the feed overhead |
| Video content / exercise streaming | Users ask for form videos; competitors use them | Storage and CDN costs are extremely high at scale; video encoding pipeline is a separate engineering track | Licensed animated GIFs or illustrated statics for exercise demos. Link to YouTube for form tutorials (external link). |
| Real-time coaching / live classes | Peloton has normalized the expectation | Requires instructors, streaming infrastructure, scheduling — a completely separate product | Async AI workout feedback; on-demand programs from qualified coaches |
| Nutrition tracking / macro logging | MyFitnessPal effect — users expect one app for everything | Nutrition is a distinct domain with its own complexity (food databases, barcode scanning, macro math); dilutes the strength training focus | Phase-aware nutrition *guidance* (not tracking): "In luteal phase, prioritize protein and iron" — education not logging |
| Wearable integrations (Apple Watch, Wear OS) | "Can I see my workout on my watch?" is a common request | Watch apps are separate development targets; Wear OS + watchOS are distinct SDKs; React Native has limited native watch support | Prioritize HealthKit/Health Connect write-back for step and workout data so wearable users get *some* integration without a watch app |
| HealthKit / Health Connect deep integration | Users want calorie and step data in their health app | React Native HealthKit libraries (react-native-health, react-native-health-connect) are stable but platform-divergent; deep integration is a time sink | Write completed workout data to HealthKit/Health Connect (duration, calories, workout type) at session end — one-directional write only for launch |
| Data migration from iOS SwiftData app | Existing users want their history | CloudKit → Firestore requires a server-side migration pipeline with Apple account linkage; the user base is small enough that a fresh start is cleaner | Fresh start confirmed in PROJECT.md. Communicate clearly in app as "new chapter" framing. |
| Gamification points/levels/badges | "Makes it more fun" | Engagement loops that require maintenance; badge inventory becomes a product backlog; power users find them patronising | PRs are the natural reward loop in strength training. Phase-aware prompts ("You're in your luteal phase — great time for a deload PR attempt") are more meaningful than arbitrary points. |
| Real-time multiplayer / partner workouts | "Train with a friend remotely" | WebRTC or similar infra; Firestore real-time sync adds complexity; niche use case | Shared programs where partners track the same program independently; compare history view |

---

## Feature Dependencies

```
Auth (Firebase Auth)
    └──requires──> all features (no data without identity)

Cycle Phase Tracking
    └──requires──> Auth
    └──enables──> Cycle-Aware Load Adaptation
    └──enables──> Cycle-Aware AI Workout Generation
    └──enables──> WOD cycle annotations

Injury Profile
    └──requires──> Auth
    └──enables──> Injury Adaptation Engine
    └──enables──> Rehab Session Generation
    └──enables──> Pain Trend Analysis
    └──enables──> Phase Transition Advisor

Workout Logging
    └──requires──> Auth, Exercise Library
    └──enables──> PR Detection
    └──enables──> Progress Charts
    └──enables──> Workout History

Program Catalog
    └──requires──> Auth, Workout Logging
    └──enables──> WOD (programs are the delivery vehicle)

AI Workout Generation
    └──requires──> Auth, Firebase Cloud Functions
    └──enhanced by──> Cycle Phase Tracking (contextual prompt)
    └──enhanced by──> Injury Profile (exclusion list)
    └──enhanced by──> Readiness Survey (intensity modifier)
    └──requires──> offline fallback (templated workouts, no AI)

RevenueCat / Stripe Subscriptions
    └──requires──> Auth (entitlement tied to user ID)
    └──gates──> AI Workout Generation (premium feature)
    └──gates──> Cycle Adaptation (premium feature, or free tier?)

Benchmark Catalog
    └──requires──> Auth, Workout Logging (for result recording)
    └──independent of──> Cycle Tracking (but benefits from phase context)

Offline Functionality
    └──requires──> Firestore offline persistence enabled from app init
    └──affects──> all data-writing features (must queue writes)
```

### Dependency Notes

- **Cycle Phase Tracking requires Auth:** Cycle data is sensitive health data — must be stored under authenticated user ID, never anonymously.
- **AI Workout Generation requires offline fallback:** Firebase Cloud Functions require connectivity; if offline, the app must fall back to templated workout selection. Implementing AI without the fallback is a launch blocker.
- **Subscriptions gate premium features:** The paywall placement decision (which features are free vs. premium) affects onboarding conversion. Recommendation: cycle adaptation and AI workouts are premium; basic logging + programs are free. This mirrors Fitbod's model.
- **Injury Profile enables four downstream features:** Port the entire Domain injury engine to TypeScript before building any of the four dependent features. They share data contracts.

---

## MVP Definition

### Launch With (v1)

Minimum to replace the iOS app's validated feature set on React Native.

- [ ] Firebase Auth (Apple, Google, Email, Guest) — identity without which nothing persists
- [ ] Offline-first Firestore with workout logging — core loop, must work in a dead-zone gym
- [ ] Exercise library (200+ exercises) — logging requires findable exercises
- [ ] Rest timer with background support — in-workout critical path
- [ ] Program catalog (Firestore-backed) — structured training for users who don't want to freeform
- [ ] Cycle phase tracking and load adaptation — primary differentiator, defines product identity
- [ ] Injury profile + adaptation engine — second differentiator, already validated
- [ ] AI workout generation via Firebase Cloud Functions + offline fallback — third differentiator
- [ ] PR detection and progress charts — retention mechanic
- [ ] Workout history with source filtering — users need to review past sessions
- [ ] Benchmark catalog and result recording — sports-performance positioning
- [ ] RevenueCat (iOS + Android) + Stripe (web) subscriptions — monetization gate
- [ ] Art Deco UI with refreshed design tokens — brand identity

### Add After Validation (v1.x)

- [ ] WOD (Workout of the Day) feed — requires admin tooling; valuable once content pipeline exists
- [ ] Readiness survey integration with AI prompt — enhances AI quality; safe to defer to v1.1
- [ ] Pain trend analysis UI — the data collection exists at v1; the analysis view can come later
- [ ] Phase transition advisor UI — same: data in v1, surface insights in v1.1
- [ ] HealthKit / Health Connect write-back — nice for wearable users; not a blocker
- [ ] Rehab session generation — powerful but complex; validate injury profile adoption first

### Future Consideration (v2+)

- [ ] Android watch face or complications — Wear OS is a distinct SDK; defer until RN ecosystem matures
- [ ] In-app exercise video demos — CDN cost; validate MAU before committing storage budget
- [ ] Social / friend leaderboard within a program — validate retention metrics first; only add if churn data supports it
- [ ] Nutrition phase guidance (non-tracking) — editorial content, not a feature; can be blog posts first

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Auth + offline workout logging | HIGH | MEDIUM | P1 |
| Exercise library | HIGH | MEDIUM | P1 |
| Rest timer | HIGH | LOW | P1 |
| Program catalog | HIGH | MEDIUM | P1 |
| Cycle phase tracking | HIGH | HIGH | P1 |
| Cycle-aware load adaptation | HIGH | HIGH | P1 |
| Injury profile + adaptation | HIGH | HIGH | P1 |
| AI workout generation | HIGH | HIGH | P1 |
| PR detection + progress charts | HIGH | MEDIUM | P1 |
| Workout history | HIGH | LOW | P1 |
| RevenueCat + Stripe subscriptions | HIGH | MEDIUM | P1 |
| Benchmark catalog | MEDIUM | MEDIUM | P2 |
| WOD feed | MEDIUM | MEDIUM | P2 |
| Readiness survey | MEDIUM | LOW | P2 |
| Pain trend analysis | MEDIUM | MEDIUM | P2 |
| Phase transition advisor | MEDIUM | MEDIUM | P2 |
| Rehab session generation | MEDIUM | HIGH | P2 |
| HealthKit / Health Connect write-back | LOW | MEDIUM | P3 |
| Exercise video demos | LOW | HIGH | P3 |
| Social features | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Hevy | Strong | Fitbod | FitrWoman | Our Approach |
|---------|------|--------|--------|-----------|--------------|
| Workout logging | Yes, fast UI | Yes, minimalist | Yes | No (cycle app) | Yes, Art Deco UI |
| Offline | Yes | Yes | Partial | Yes | Yes, Firestore offline persistence |
| AI workout gen | No | No | Yes (muscle-based) | No | Yes, cycle + injury aware (Gemini) |
| Cycle tracking | No | No | No | Yes (cycle only) | Yes, integrated with strength programming |
| Cycle-aware load adaptation | No | No | No | Guidance only | Yes, automatic multipliers |
| Injury adaptation | No | No | No | No | Yes, automated substitution engine |
| Benchmarks | No | No | No | No | Yes |
| Program catalog | Yes | No | No | No | Yes |
| Social | Yes, Instagram-like | No | No | No | No at launch (anti-feature) |
| Android + Web | Yes | Yes (Android) | Yes | iOS only | Yes (React Native) |
| Wearable native app | No | No | No | No | No at launch |
| Pricing model | Freemium | One-time + sub | Subscription | Subscription | RevenueCat + Stripe dual |

**Key gap:** No competitor combines strength programming + cycle-aware adaptation + injury modification + AI generation in a single cross-platform app. Sundee Fundee owns this space.

---

## Sources

- [Best Strength Training Apps 2026: Hevy vs Strong vs Fitbod](https://www.findyouredge.app/news/best-strength-training-apps-2026) — feature comparison, confidence HIGH
- [Fitbod, Strong, Hevy, SensAI: 2025 Feature Showdown](https://www.sensai.fit/blog/fitness-app-comparison) — feature matrix, confidence MEDIUM
- [Strong vs Hevy Comparison 2026](https://gymgod.app/blog/strong-vs-hevy) — UX comparison, confidence MEDIUM
- [FitrWoman App Store listing](https://apps.apple.com/us/app/fitrwoman/id1189050449) — cycle app feature set, confidence HIGH
- [WHOOP Menstrual Cycle Insights](https://www.whoop.com/us/en/thelocker/whoop-feature-menstrual-cycle-coaching/) — hardware-based cycle coaching, confidence HIGH
- [Developing an Offline-First Fitness App with React Native](https://dev.to/sathish_daggula/developing-an-offline-first-fitness-app-with-react-native-the-journey-of-gym-tracker-5a2h) — RN offline patterns, confidence MEDIUM
- [Local-first architecture with Expo](https://docs.expo.dev/guides/local-first/) — official Expo docs on offline storage, confidence HIGH
- [Building a Live Activity Timer in Expo React Native](https://levelup.gitconnected.com/building-a-live-activity-timer-in-expo-626b162f3e8d) — background timer, confidence MEDIUM
- [Best App for Tracking Workouts: 15 Apps Tested](https://setgraph.app/ai-blog/best-app-for-tracking-workouts) — UX expectations, confidence MEDIUM
- [9 Best Women's Wellness Apps: Cycle Syncing](https://www.androidheadlines.com/2025/11/9-best-womens-wellness-apps-from-cycle-syncing-to-smarter-self-care.html) — competitor landscape, confidence MEDIUM
- [Top Fitness App Paywalls: UX Patterns + Pricing](https://dev.to/paywallpro/top-fitness-app-paywalls-ux-patterns-pricing-insights-2868) — monetization patterns, confidence MEDIUM
- [Gamification Use in Health/Fitness Apps — PMC Study](https://pmc.ncbi.nlm/articles/PMC6348030/) — gamification evidence base, confidence HIGH

---

*Feature research for: Cross-platform fitness / strength training app (Sundee Fundee React Native rewrite)*
*Researched: 2026-03-14*
