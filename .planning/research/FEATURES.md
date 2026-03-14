# Feature Research

**Domain:** Elite-tier iOS strength training app (premium AI coaching, biometric integration, computer vision)
**Researched:** 2026-03-14
**Confidence:** MEDIUM — Competitor features verified via multiple sources; technical capability claims verified against Apple documentation; pricing/positioning current as of early 2026.

---

## Feature Landscape

This document covers all five Elite tier features individually: (1) Predictive PR Forecasting & Analytics, (2) Bar Path & Form Analysis, (3) Travel Mode & Multi-Gym Profiles, (4) Conversational AI Coach with Voice, and (5) Readiness & Auto-Regulation.

---

## Feature 1: Predictive PR Forecasting & Analytics

### What Users Expect (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| e1RM trend line per lift | Every serious tracker (Hevy, StrengthLog, JuggernautAI) shows estimated 1RM over time | LOW | Already have raw 1RM data from existing MaxesFeature. Epley formula standard; display as chart |
| Historical PR timeline | Users expect to see when each PR was set | LOW | Flag PRs on existing history. Hevy does this for free |
| Strength level benchmarks | "Is my deadlift weak/novice/advanced?" context | LOW | Leverages existing BenchmarkCatalog |
| Volume load tracking per muscle/week | Table stakes in Hevy, Fitbod, JuggernautAI | MEDIUM | Requires tagging exercises to muscle groups |
| Muscle fatigue/recovery heatmap | Fitbod's signature feature; users in strength apps now expect this | MEDIUM | MuscleMap Swift package (iOS 17+, SwiftUI-native) available; requires muscle tagging on exercises |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Predictive PR date forecast ("You're on track for a 200 lb bench in ~6 weeks") | No mainstream app does forward projection; JuggernautAI adjusts programs but doesn't show a predicted date | HIGH | Linear regression on recent e1RM trend. Confidence interval needed. Beware over-promising accuracy |
| Peaking readiness indicator | Flag when a lifter is ready to peak vs. in accumulation | HIGH | Requires combining e1RM trend slope + fatigue heatmap + readiness score — unique to Sundee Fundee's data richness |
| Cycle-aware strength trend annotation | Annotate e1RM charts with menstrual phase markers | MEDIUM | Unique differentiator; no competitor does this. Leverage existing CycleAdaptationPolicy |
| Injury-aware volume warnings | Alert when a muscle group is being overloaded given tracked injury | MEDIUM | Cross-feature: bridges InjuryAdaptationEngine with volume analytics |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| "You'll hit a 300 lb squat in X days" absolute date forecasts | Sounds impressive | e1RM trends are noisy; false precision erodes trust when prediction misses | Show direction + confidence range: "trending upward, possible PR window in 4–8 weeks" |
| Real-time 1RM prediction mid-set via watch | Novelty | Requires Watch app and always-on data; adds significant scope | Post-session e1RM is sufficient and already accurate |
| Competition attempt calculator | Requested by powerlifters | Niche use case; adds complexity; JuggernautAI already owns this | Defer; out of scope for v1.0 Elite |

---

## Feature 2: Bar Path & Form Analysis

### What Users Expect (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Post-set video playback with bar path overlay | Apps like Iron Path, BarSense, Metric VBT have set this expectation | HIGH | On-device Vision tracking; user must set phone to frame the lift |
| Basic deviation feedback ("bar drifted forward") | FormCheck AI, AiKYNETIX give scoring and cues | HIGH | Apple Vision does not provide barbell-specific tracking; must use VNDetectRectanglesRequest or custom object tracking on the bar's endpoints |
| Setup guidance (framing instructions) | Every vision-based app shows camera angle guides | LOW | Onboarding modal before starting recording |
| Exercise scope: Squat, Bench, Deadlift minimum | Users expect the big three; anything less feels incomplete for strength app | MEDIUM | Three lift models at launch; can extend post-v1 |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Gemini multimodal coaching cues from video clip | AI-generated specific feedback ("your hips rise before your shoulders on the pull") vs. generic deviation alerts | HIGH | Gemini can accept video frames; proxy through existing Cloudflare Worker. Monthly cap critical given cost |
| Injury-aware form feedback ("watch knee tracking given your logged knee injury") | No competitor cross-references injury log with form cues | MEDIUM | Requires InjuryAdaptationEngine context passed to Gemini prompt |
| Cycle-phase context in coaching cue ("ligament laxity may be elevated in luteal phase — prioritize bar control") | No competitor does this | LOW | Prompt engineering addition, not engineering complexity |
| Progress view: bar path comparison over time | Show before/after for same lift across sessions | MEDIUM | Store encoded path data per session; render overlay comparison |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time live bar path during the lift | Feels like true coaching | Processing latency on device during heavy lift; distracting; accuracy degrades in real-time | Post-set analysis: record, then process and display |
| Unlimited AI form checks | Users want as many as possible | Gemini multimodal video calls have non-trivial per-call cost; unlimited at $19.99/mo is unsustainable | Monthly cap (e.g., 10 checks/month); clearly displayed usage counter |
| Full body pose correction (not just bar path) | Would cover more form aspects | Requires full-body framing + VNDetectHumanBodyPoseRequest + training on lift-specific norms; doubles scope | Scope to bar path only in v1.0; body pose as v2 consideration |

---

## Feature 3: Travel Mode & Multi-Gym Equipment Profiles

### What Users Expect (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Named equipment profiles (e.g., "Home Gym", "Hotel Gym", "Main Gym") | Fitbod does this; users expect their app to "know" what they have access to | LOW | Simple SwiftData model: EquipmentProfile with name + equipment list |
| Quick-switch between profiles | Needs to be 1-2 taps; if buried in settings it won't be used | LOW | Prominent selector on workout start screen |
| Instant workout regeneration with active profile | Fitbod and Gymverse do this on equipment change | MEDIUM | Wire EquipmentProfile into existing AI workout generation prompt |
| Bodyweight/minimal equipment option | Hotel gyms often have nothing; users expect this to still produce a workout | LOW | Bodyweight exercise catalog already exists in program data |
| Profile persists across sessions | Profile should be sticky until explicitly changed | LOW | Store active profile ID in UserDefaults or AppState |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Auto-detect travel context from Calendar/location (optional) | Proactively switch to travel profile | HIGH | Privacy-sensitive; optional opt-in. Likely too much scope for v1.0 |
| Equipment profile influences program enrollment | Warn user if enrolled program requires equipment they've marked unavailable | MEDIUM | Cross-feature: bridges Programs feature with EquipmentProfile |
| Cycle-phase + equipment adaptation ("reduced equipment + high-fatigue phase = focus on unilateral control") | No competitor combines cycle context with equipment constraint | MEDIUM | Gemini prompt engineering; reuses existing adaptation patterns |
| Saved hotel gym search / gym finder integration | Users traveling want to find gyms | HIGH | Third-party data dependency; significant scope. Defer |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Equipment barcode/QR scanning to build profile | Novelty | Very high engineering effort for marginal gain; databases of gym equipment are unreliable | Manual checklist with common equipment types (barbells, dumbbells, cables, machines, bodyweight) |
| Automatic GPS-based profile switching | "Magical" UX | Location permission friction; false activations; battery impact | Manual one-tap profile switch is sufficient |

---

## Feature 4: Conversational AI Coach with Voice

### What Users Expect (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Text chat with context awareness (knows history, injuries, cycle phase, goals) | Dr. Muscle AI Chat, Fitbit Coach, and Zing AI have established this as baseline | HIGH | Gemini already proxied; prompt must inject user context (history summary, injuries, cycle, equipment, recent workouts) |
| Weekly check-in flow (structured questions: how are you feeling, what went well, what was hard) | SuperCoach, JuggernautAI readiness ratings establish this expectation | MEDIUM | Templated check-in prompt sequence; store responses; feed into next week's planning |
| Coach can explain "why" for recommendations | Users don't just want a plan; they want to understand it | LOW | Prompt engineering; Gemini handles explanatory responses well |
| Persistent conversation context within a session | Users expect follow-up questions to work ("tell me more about that") | MEDIUM | Message history in conversation window; truncate to last N messages for token budget |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Voice input (speech-to-text) + voice output (text-to-speech) | Apple Workout Buddy announced at WWDC 2025 sets expectation; Flaims does this on Apple Watch; voice makes it feel like a real coach | MEDIUM | AVSpeechSynthesizer (on-device TTS, free) + SFSpeechRecognizer (on-device STT, free). No third-party cost. iOS 17+ supports both |
| Coach references menstrual cycle data when relevant | "Based on your cycle, your energy may be lower this week — this is normal" | LOW | Prompt injection; unique to Sundee Fundee |
| Coach modifies next workout based on check-in response | Not just feedback — actionable adaptation to upcoming session | HIGH | Requires pipeline: check-in responses → Gemini prompt → updated workout parameters → apply to AI generation |
| Post-workout debrief mode | After logging: "How was that? Any pain? What felt strong?" — persistent learning loop | MEDIUM | Structured post-workout prompt + store key-value coaching notes in SwiftData |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Always-on background voice listening | Feels like a live coach | Microphone background permission; battery drain; privacy red flags; App Store scrutiny | Push notification to open check-in; voice only when user opens coach tab |
| Third-party TTS voices (ElevenLabs, etc.) | Higher quality voice | API cost per character; adds external dependency; latency | AVSpeechSynthesizer is free, low-latency, on-device, and has improved significantly in iOS 17+ |
| Video avatar coach | Visual engagement | Very high complexity and resource cost; no fitness app has cracked this at scale yet | Voice + text is sufficient; avatar adds no coaching value |
| Unlimited AI chat tokens | User freedom | Gemini API costs scale with usage; unlimited at $19.99/mo is unsustainable | Soft daily message limit (e.g., 20 messages/day) or monthly token budget |

---

## Feature 5: Readiness & Auto-Regulation

### What Users Expect (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Composite readiness score combining HRV, sleep, resting HR | Perform app, SensAI, Technogym Coach all do this; HealthKit data is already fetched in existing app | LOW | Infrastructure already exists: HealthKitReadinessRepository + ReadinessSurvey. This is primarily a score formula + display |
| Color-coded readiness zones (green/yellow/red) | WHOOP established this visual language; users universally understand it | LOW | Simple threshold-based categorization |
| Readiness-informed volume/intensity recommendation | Fitbod auto-scales; JuggernautAI adjusts based on daily feedback; users expect this | MEDIUM | Modify workout generation prompt with readiness context; or apply scaling factors to prescribed sets/reps/weight |
| Survey + biometric synthesis | Subjective feel + objective HRV should inform score together | LOW | ReadinessSurvey already exists; weighted average with HealthKit data |
| Score visible before starting workout | User must see readiness before committing to session | LOW | Surface score prominently on Dashboard or workout start screen |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Cycle-phase-aware readiness interpretation | Distinguish "low HRV due to overtraining" from "low HRV due to late luteal phase" — no competitor does this | MEDIUM | CycleAdaptationPolicy + HealthKit data merge; unique Sundee Fundee insight |
| Injury-aware auto-regulation | If readiness is low AND active injury logged, suggest modified or deload session automatically | MEDIUM | Cross-feature: InjuryAdaptationEngine + readiness score; already have both engines |
| Readiness trend visualization over cycle | Show 28-day readiness trend overlaid with cycle phases | MEDIUM | Line chart + phase annotations; informs long-term training rhythm |
| Explicit auto-regulation transparency ("I reduced your sets from 4 to 3 because your HRV is 18% below your 7-day average") | SensAI differentiates by explaining reasoning; users trust transparent systems more | LOW | Explanation string generated alongside the recommendation; Gemini or rule-based |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Always-on background HealthKit monitoring | Maximum freshness | Explicitly out of scope per PROJECT.md; battery + privacy impact | Fetch on app open or workout start — already established pattern |
| Replace the workout if readiness is very low | Users want guidance | Users should own the decision; auto-replacing feels paternalistic and can frustrate advanced lifters | Recommend modification + show reasoning; let user accept or override |
| Require wearable hardware (Apple Watch mandatory) | Better data quality | Excludes users without Watch; survey-only readiness must remain viable | HealthKit data optional enhancement; survey data sufficient for base score |

---

## Feature Dependencies

```
Predictive PR Forecasting
    └──requires──> MaxesFeature (e1RM history) [EXISTING]
    └──requires──> Exercise-to-muscle-group mapping [NEEDS BUILD]
    └──enhances──> Readiness & Auto-Regulation (peaking context)

Muscle Fatigue Heatmap
    └──requires──> Exercise-to-muscle-group mapping [NEEDS BUILD]
    └──requires──> WorkoutHistory (volume per session) [EXISTING]
    └──enhances──> Readiness & Auto-Regulation (fatigue context in score)

Bar Path & Form Analysis
    └──requires──> On-device Vision tracking (bar endpoint detection) [NEEDS BUILD]
    └──requires──> Gemini multimodal proxy (form coaching cues) [EXTENDS EXISTING]
    └──requires──> Monthly usage cap system [NEEDS BUILD]

Travel Mode & Multi-Gym Equipment Profiles
    └──requires──> EquipmentProfile SwiftData model [NEEDS BUILD]
    └──requires──> AI workout generation (already exists) [EXISTING]
    └──enhances──> Conversational AI Coach (coach knows current equipment)

Conversational AI Coach with Voice
    └──requires──> Gemini proxy (already exists) [EXISTING]
    └──requires──> User context serialization (history, injuries, cycle, equipment) [NEEDS BUILD]
    └──requires──> AVSpeechSynthesizer + SFSpeechRecognizer (on-device) [NEEDS BUILD]
    └──enhances──> Readiness & Auto-Regulation (check-in feeds readiness)

Readiness & Auto-Regulation
    └──requires──> HealthKitReadinessRepository [EXISTING]
    └──requires──> ReadinessSurvey [EXISTING]
    └──requires──> CycleAdaptationPolicy [EXISTING]
    └──requires──> InjuryAdaptationEngine [EXISTING]
    └──requires──> Readiness score formula + display [NEEDS BUILD]
    └──enhances──> AI workout generation (readiness context in prompt)

Elite Subscription Gate
    └──required by──> All five Elite features
    └──requires──> StoreKit 2 Elite product ($19.99) [NEEDS BUILD — entitlement checks]
```

### Dependency Notes

- **Exercise-to-muscle-group mapping is a shared dependency** for both PR Forecasting (volume load) and Muscle Fatigue Heatmap. This needs to be built once and reused. It is the highest-value infrastructure piece for multiple Elite features.
- **Monthly cap system** for Gemini multimodal calls is a cross-cutting concern needed by both Bar Path (video analysis) and AI Coach (chat volume). Build once as a shared `UsageCapRepository`.
- **Readiness & Auto-Regulation is intentionally last** because it is the lowest-complexity feature and its inputs (HealthKit, Survey, Cycle, Injury) are all pre-built. It acts as the connective tissue that makes other features more valuable.
- **Bar Path is the highest-risk feature** because Apple Vision does not provide a barbell-specific tracker — it must be built using object tracking primitives. This is the only feature that could realistically slip or require a scope reduction.

---

## MVP Definition

### Launch With (v1 Elite)

All five features ship together as the Elite tier gate. However, within each feature, these are the minimum viable slices:

- [ ] **Readiness Score display + auto-regulation** — Lowest complexity, highest perceived value, reuses all existing infrastructure. Validates the Elite tier concept with minimal risk.
- [ ] **Muscle fatigue heatmap** — Visually striking; Fitbod users know it; high perceived value for the UI investment. Requires muscle mapping infrastructure.
- [ ] **e1RM trend chart + PR forecasting trend line** — Extends existing MaxesFeature. Users can see direction; avoids overcommitting to precise date predictions.
- [ ] **Equipment profiles + Travel Mode workout adaptation** — Lowest-risk feature architecturally; SwiftData model + prompt injection. Clear utility.
- [ ] **AI Coach text chat with weekly check-in** — Core conversational experience. Voice is the differentiator but text is functional MVP.
- [ ] **Bar Path tracking (post-set, Big Three)** — Ship with on-device tracking + Gemini coaching cues. Monthly cap counter visible to user.

### Add After Validation (v1.x)

- [ ] **Voice input/output for AI Coach** — AVSpeechSynthesizer + SFSpeechRecognizer are on-device, but UX polish (interrupt handling, background audio session) takes iteration. Ship text first.
- [ ] **Bar path comparison over time (before/after view)** — Valuable but requires storing encoded path data; non-trivial SwiftData schema work. Add once tracking is validated.
- [ ] **Peaking readiness indicator** — Requires several weeks of data to be meaningful; cannot be validated at launch. Add after users have historical data.
- [ ] **Post-workout debrief mode in AI Coach** — Valuable persistent learning loop; requires more prompt engineering iteration than a launch feature allows.

### Future Consideration (v2+)

- [ ] **Body pose correction (full-body form analysis)** — Doubles scope of Vision work; wait for user validation of bar-path-only v1.
- [ ] **Competition attempt calculator** — Niche powerlifting feature; JuggernautAI and BarBend already own this. Validate demand first.
- [ ] **Auto-detect travel via location/calendar** — Privacy-sensitive; high complexity; wait for equipment profiles to prove their value first.
- [ ] **Apple Watch readiness integration** — Dedicated Watch app is a significant platform extension; defer until iOS product is stable.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Readiness score + auto-regulation | HIGH | LOW | P1 |
| Muscle fatigue heatmap | HIGH | MEDIUM | P1 |
| e1RM trend + PR forecasting | HIGH | MEDIUM | P1 |
| Equipment profiles + Travel Mode | MEDIUM | LOW | P1 |
| AI Coach text chat + weekly check-in | HIGH | HIGH | P1 |
| Bar path tracking (Big Three) | HIGH | HIGH | P1 |
| Voice input/output for AI Coach | MEDIUM | MEDIUM | P2 |
| Bar path comparison over time | MEDIUM | MEDIUM | P2 |
| Peaking readiness indicator | HIGH | HIGH | P2 |
| Post-workout debrief mode | MEDIUM | MEDIUM | P2 |
| Full-body pose correction | LOW | HIGH | P3 |
| Competition attempt calculator | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for Elite tier launch
- P2: Should have, add when possible (v1.x)
- P3: Nice to have, future consideration (v2+)

---

## Competitor Feature Analysis

| Feature | JuggernautAI ($35/mo) | Fitbod ($13/mo) | Dr. Muscle ($49/mo) | Hevy (free/Pro) | Sundee Fundee Elite ($19.99/mo) |
|---------|----------------------|-----------------|---------------------|-----------------|----------------------------------|
| e1RM trend chart | Yes (training history) | Yes | Yes (progress charts) | Yes (projected 1RM) | Yes + cycle annotations |
| Predictive PR date forecast | No — adjusts program but no forecast | No | No | No | Yes (trend-based, with confidence range) |
| Muscle fatigue heatmap | No | Yes (core feature) | No | Partial (muscle distribution chart) | Yes (MuscleMap SDK) |
| Bar path tracking | No | No | No | No | Yes (on-device Vision + Gemini cues) |
| AI form coaching | Basic weak-point flags | No | No | No | Yes (Gemini multimodal, monthly capped) |
| Equipment profiles | No | Yes (multiple gym profiles) | No — equipment filters | No | Yes (named profiles + quick-switch) |
| Travel Mode | No | Yes (generates to available equipment) | Partial (custom workout with equipment filter) | No | Yes (instant regen with active profile) |
| Conversational AI Coach | No | No | Yes (AI Chat — context-aware) | No | Yes (Gemini, context-injected) |
| Voice coach | No | No | No | No | Yes (AVSpeechSynthesizer + SFSpeechRecognizer) |
| Weekly check-in | Yes (readiness ratings per session) | No | No | No | Yes (structured + feeds next workout) |
| HRV/HealthKit readiness | No | No | No | No | Yes (HealthKit + survey composite) |
| Auto-regulation from readiness | Yes (program adjusts from daily feedback) | Yes (auto-scales from logged performance) | Yes (Recovery Mode) | No | Yes (volume/intensity scaling + transparent explanation) |
| Cycle-phase integration | No | No | No | No | Yes (unique to Sundee Fundee — all 5 features cycle-aware) |
| Injury cross-referencing | No | No | No | No | Yes (unique to Sundee Fundee — form + readiness + volume) |

**Key competitive insight:** Sundee Fundee Elite's genuine differentiators are the features no competitor offers at all — cycle-aware analytics, cycle-aware coaching cues, injury-cross-referenced form feedback, and bar path tracking with multimodal AI coaching. These are not marginal improvements; they are category-novel for a female-primary strength training app. The $19.99 price point sits below Dr. Muscle ($49/mo) while offering unique features that Dr. Muscle lacks entirely.

---

## Sources

- [JuggernautAI Review — PowerliftingTechnique.com](https://powerliftingtechnique.com/juggernaut-ai-review/)
- [JuggernautAI Pricing 2026 — Arvo](https://arvo.guru/vs/juggernaut-ai)
- [Fitbod Muscle Recovery Feature](https://fitbod.me/blog/muscle-recovery/)
- [Fitbod Personalized Workout Algorithms](https://fitbod.me/blog/how-fitbod-personalizes-your-workout-plan-using-smart-training-algorithms/)
- [Fitbod Travel Review — Hotel Gyms](https://www.hotelgyms.com/blog/review-of-fitbod-how-to-take-your-fitness-with-you)
- [Dr. Muscle: 27+ Differentiating Features](https://dr-muscle.com/what-makes-dr-muscle-different/)
- [Dr. Muscle Free Plan Announcement](https://dr-muscle.com/free-plan/)
- [Hevy Features — Performance Tracking](https://www.hevyapp.com/features/gym-performance/)
- [5 Best Apps for Analyzing Weightlifting Form — CueForm AI](https://cueform.ai/posts/5-best-apps-for-analyzing-weightlifting-form)
- [7 Best HRV Fitness Apps — Sensai](https://www.sensai.fit/blog/7-best-hrv-fitness-apps-oura-whoop-2025)
- [Apple Vision Framework — Developer Documentation](https://developer.apple.com/documentation/vision)
- [VNDetectHumanBodyPoseRequest — Apple Developer](https://developer.apple.com/documentation/vision/vndetecthumanbodyposerequest)
- [WWDC24: Swift Enhancements in Vision Framework](https://developer.apple.com/videos/play/wwdc2024/10163/)
- [MuscleMap SwiftUI SDK — GitHub](https://github.com/melihcolpan/MuscleMap)
- [MuscleMap — Swift Package Index](https://swiftpackageindex.com/melihcolpan/MuscleMap)
- [Metric VBT Bar Path Tracking](https://www.metric.coach/articles/the-complete-guide-to-bar-path-tracking-with-your-smartphone)
- [Apple Workout Buddy / WWDC 2025 — MacRumors](https://www.macrumors.com/2025/06/09/ai-powered-workout-buddy-coming-to-apple-watch/)
- [Flaims AI Voice Workout Coach for Apple Watch](https://www.flaims.fit/)
- [Chatbots in Fitness Apps — Digiqt](https://digiqt.com/blog/chatbots-in-fitness-apps/)
- [Gymverse Travel App Review — Hotel Gyms](https://www.hotelgyms.com/blog/gymverse-fitness-app-review)
- [e1RM Formulas Compared — Arvo](https://arvo.guru/resources/one-rep-max-formulas)

---
*Feature research for: Sundee Fundee — Elite Tier (v1.0)*
*Researched: 2026-03-14*
