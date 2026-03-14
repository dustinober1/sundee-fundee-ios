# Project Research Summary

**Project:** Sundee Fundee — Elite Tier (v1.0)
**Domain:** Native iOS strength training app — AI coaching, computer vision, biometric auto-regulation, voice UI
**Researched:** 2026-03-14
**Confidence:** HIGH (stack + architecture verified against official Apple docs and codebase; features verified against competitor analysis; pitfalls verified against framework documentation)

## Executive Summary

Sundee Fundee Elite is a five-feature tier unlock for a native iOS strength training app already in production. The existing app delivers AI workout generation, HealthKit biometric reads, SwiftData + CloudKit persistence, StoreKit 2 subscriptions, and a full cycle-adaptation + injury-modification engine — a significant foundation that most of the Elite features plug directly into rather than building alongside. The recommended approach is additive: extend the existing policy pipeline (CycleAdaptationPolicy → InjuryAdaptationEngine) with new Domain engines, add two new Gemini proxy endpoints, introduce four new SwiftData models via lightweight schema migrations, and gate all five features behind a new `.elite` StoreKit 2 subscription tier.

The five Elite features in priority order by risk-adjusted value are: (1) Readiness score + auto-regulation — lowest complexity, highest perceived value, reuses all existing HealthKit and survey infrastructure; (2) Muscle fatigue heatmap + PR forecasting analytics — visually striking, requires one shared infrastructure piece (exercise-to-muscle-group mapping); (3) Travel Mode + equipment profiles — purely a SwiftData model plus prompt injection into an already-wired equipment field; (4) Conversational AI Coach with text chat and weekly check-in — new Gemini endpoint plus context serialization; and (5) Bar path + form analysis — the only technically novel feature requiring Vision framework, AVCaptureSession, and multimodal Gemini calls. All five features gain a category-novel advantage from cycle-phase and injury cross-referencing that no competitor currently provides.

The principal risks are concentrated in two areas: the bar path feature (Vision tracking quality in real gym conditions, Gemini video cost controls, and AVFoundation + speech audio session conflicts) and the AI coach feature (conversation history token bloat and TTS streaming latency). Both are well-understood problems with documented mitigations. The mitigation strategy is architectural discipline upfront: define protocol seams before writing Vision/AVFoundation code (to preserve 100% CI coverage), enforce Gemini usage quotas at the Cloudflare Worker level not the iOS client, and design the conversation context window with a rolling-window trim from day one.

---

## Key Findings

### Recommended Stack

The entire Elite tier can be built without adding any third-party frameworks except one Swift Package Manager dependency. All new capabilities — bar path tracking, speech I/O, PR charting — use Apple system frameworks already available on the iOS 17.0+ deployment target. MuscleMap 1.6.0 (SPM) is the sole new dependency and is the only production-quality SwiftUI-native muscle heatmap library with zero external dependencies.

The Cloudflare Worker proxy needs two new routes (`/analyze-form` and `/coach-chat`) using the existing Gemini native format. The model upgrade from `gemini-3.1-flash-lite-preview` to `gemini-2.5-flash` applies only to form analysis and coach chat routes; workout generation keeps the lite model for cost control.

**Core technologies (new additions only):**
- Swift Charts (system, iOS 17+): e1RM trend lines and PR forecasting visualization — native SwiftUI, zero dependencies, `chartXSelection` and `RuleMark` sufficient for all analytics UI
- Vision — VNDetectTrajectoriesRequest (system, iOS 14+): bar path tracking from camera frames — on-device, no inference cost, parabolic trajectory detection built-in
- Vision — VNDetectHumanBodyPoseRequest (system, iOS 14+): 2D joint angles for form analysis — covers all devices; 3D variant (LiDAR-only) reserved as enhancement
- AVFoundation — AVCaptureSession (system): camera frame capture for Vision pipeline — required to stream CMSampleBuffers to VNImageRequestHandler
- Speech — SFSpeechRecognizer (system, iOS 17+): voice input for AI coach — on-device recognition available, no cost, wrappable via AsyncThrowingStream
- AVFoundation — AVSpeechSynthesizer (system, iOS 17+): TTS for AI coach responses — 150+ voices, Personal Voice support, zero cost, works offline
- MuscleMap 1.6.0 (SPM): muscle fatigue heatmap visualization — only native SwiftUI muscle map library, iOS 17+, actively maintained

### Expected Features

**Must have (table stakes — all P1 for Elite launch):**
- e1RM trend chart per lift with historical PR markers — every competing app provides this
- Muscle fatigue heatmap (via MuscleMap) — Fitbod's signature feature; users now expect it
- Composite readiness score (HRV + sleep + RHR + survey) with color-coded zones — WHOOP established this visual language
- Readiness-informed volume/intensity scaling — Fitbod and JuggernautAI auto-scale; users expect it
- Named equipment profiles with quick-switch (1–2 taps) — Fitbod does this
- Equipment-adaptive AI workout generation with Travel Mode toggle — Fitbod and Gymverse do this
- AI Coach text chat with full user context (injuries, cycle, history, equipment) — Dr. Muscle AI Chat sets this expectation
- Weekly check-in flow (structured questions feeding next week's workout) — JuggernautAI establishes this
- Bar path tracking post-set for Squat/Bench/Deadlift with on-device path overlay — Iron Path, BarSense, Metric VBT set this expectation
- Gemini multimodal form coaching cues with monthly cap counter visible to user

**Should have (differentiators — P2, v1.x):**
- Voice input + output for AI Coach (AVSpeechSynthesizer + SFSpeechRecognizer) — ship text first; voice requires audio UX iteration
- Predictive PR date forecast with confidence range (not point estimate) — no competitor does forward projection
- Cycle-aware strength trend annotation on e1RM charts — unique to Sundee Fundee
- Cycle-phase-aware readiness interpretation — distinguishes training fatigue from luteal-phase HRV drop
- Peaking readiness indicator — requires weeks of data before meaningful; add after users have history
- Post-workout debrief mode in AI Coach — persistent learning loop; requires prompt iteration
- Bar path comparison over time (before/after same lift) — requires stored path data schema

**Defer (v2+):**
- Full-body pose correction — doubles Vision scope; wait for bar-path-only validation
- Competition attempt calculator — niche powerlifting; JuggernautAI owns this
- Auto-detect travel via GPS/Calendar — privacy-sensitive, high complexity
- Apple Watch readiness integration — dedicated Watch app is a platform extension; wait for iOS stability

### Architecture Approach

Every new Elite feature integrates into the existing four-layer architecture (SwiftUI → @Observable ViewModel → Repository Protocols → Domain) without changing its structure. New Domain engines (PRForecastEngine, MuscleFatigueDomainModel, BarPathAnalyzer, ReadinessScoreEngine, AutoRegulationPolicy) are pure Swift with zero framework imports, maintaining 100% testability. The key architectural extension is a three-policy pipeline: `CycleAdaptationPolicy` → `AutoRegulationPolicy` (new) → `InjuryAdaptationEngine`, each operating on value types sequentially. Framework-specific code (Vision, AVFoundation, Speech) is isolated in `Services/` behind protocol abstractions to preserve CI coverage. Four new SwiftData models (GymProfile, ReadinessScore, FormCheckRecord, ConversationMessage) require schema migrations V13–V16, all lightweight.

**Major new components:**
1. `PRForecastEngine` + `MuscleFatigueDomainModel` (Domain/Analytics/) — pure Swift analytics engines; consume existing LiftRepository and WorkoutRepository
2. `AutoRegulationPolicy` + `ReadinessScoreEngine` (Domain/Readiness/) — extend policy pipeline; plug between CycleAdaptationPolicy and InjuryAdaptationEngine
3. `BarPathAnalyzer` + `FormFeedbackMapper` (Domain/FormAnalysis/) — accept `BarPathPoint` value types only, never Vision framework types
4. `GeminiFormService` + `GeminiChatService` (Repositories/Gemini/) — new proxy endpoints; mirror existing GeminiWorkoutService pattern
5. `SpeechInputController` + `SpeechOutputController` (Services/) — hardware adapters behind protocols; excluded from CI coverage requirement
6. `CoachConversationContext` (Domain/Coach/) — pure Swift prompt builder injecting cycle, readiness, injuries, history
7. `TravelModeEngine` (Domain/TravelMode/) — plugs into existing WorkoutGenerationContext.equipment field; near-zero integration change
8. `ExerciseRegressionCatalog` (Domain/) — extracted from InjuryAdaptationEngine and shared with TravelModeEngine

### Critical Pitfalls

1. **AVAudioSession routing destroys voice coach audio when camera is also active** — configure `.playAndRecord` with `.defaultToSpeaker` option; build a `VoiceSessionManager` that explicitly restores session category after SFSpeechRecognizer stops; test on physical device with AirPods, earpiece, and speaker. Bar path recording and voice coach share the audio session and must be designed together.

2. **Vision tracking produces zero observations in real gym conditions** — do not use body pose landmarks to infer barbell position; use a two-stage approach (VNDetectHumanBodyPoseRequest for joints + VNTrackObjectRequest initialized from a user-tapped bounding box for bar path); show a live confidence overlay pre-recording and surface "poor tracking quality" warnings rather than silent failure; test with real barbell video in low-light.

3. **Gemini video costs explode without server-side quota enforcement** — enforce monthly form check cap at the Cloudflare Worker level (Cloudflare KV/D1), not the iOS client; return `X-Form-Checks-Remaining` in response headers; use 720p/15fps H.264 compression before upload; send 3–5 JPEG keyframes inline rather than full video to stay under 20MB inline limit.

4. **Conversation history causes unbounded Gemini token cost growth** — implement rolling context window (last 20 turns) from day one; build `ConversationSummarizer` to collapse older sessions into a short paragraph; store full history in SwiftData for user access but send only the trimmed window to the proxy; check-in #15 must perform comparably to check-in #1.

5. **100% CI coverage enforcement breaks with direct Vision/AVFoundation code in ViewModels** — define protocol seams at every hardware boundary (`BarPathTrackerProtocol`, `CameraSessionProtocol`, `SpeechRecognizerProtocol`, `SpeechSynthesizerProtocol`) before writing implementation; concrete hardware adapters in `Services/` are marked excluded from coverage; ViewModels only import protocols, never Vision or AVFoundation directly.

6. **PR forecast appears valid but is statistically meaningless for sparse data** — require minimum 5 data points before showing a forecast line; display confidence intervals as bands (not point estimates); label as "estimated potential" not a guarantee; use Brzycki/Epley formula for base e1RM rather than raw logged maxes.

7. **HKSample non-Sendability breaks Swift 6 strict concurrency** — extract only primitive values (Double, Date) from HealthKit samples within the query callback; return `ReadinessMetrics` (pure Swift, Sendable) immediately; never add `@unchecked Sendable` to Domain types.

---

## Implications for Roadmap

Based on the dependency graph, architecture build order, and pitfall prevention requirements, five phases are recommended.

### Phase 1: Elite Foundation + Travel Mode + Readiness Auto-Regulation

**Rationale:** Travel Mode touches only an existing field (`WorkoutGenerationContext.equipment`), proves the schema migration pattern (V13), and has zero framework risk — it is the safest first delivery. Readiness Auto-Regulation extends already-working HealthKit and survey infrastructure via pure Domain work, validates the policy pipeline extension (AutoRegulationPolicy), and is the highest value-to-effort ratio feature in the set. Adding `.elite` to StoreKit 2 and gating logic is the prerequisite for all other Elite features. Doing both here establishes the Elite tier as real and usable after Phase 1.

**Delivers:** Elite subscription tier (StoreKit 2 .elite product), GymProfile SwiftData model (schema V13), equipment profiles UI + Travel Mode toggle, workout regeneration via active profile, ReadinessScoreEngine + AutoRegulationPolicy (Domain), ReadinessScore SwiftData model (schema V14), composite readiness score display, auto-regulation applied to AI-generated and program workouts.

**Features addressed:** Travel Mode (full P1 scope), Readiness score + auto-regulation (full P1 scope).

**Pitfalls avoided:** HealthKit non-Sendability (define ReadinessScore domain type as firewall before expanding HealthKit reads); Travel Mode substitution engine unit tests (bodyweight-only fallback, null equipment set); StoreKit sandbox downgrade test.

**Research flag:** Standard patterns — well-documented territory. No deep research needed.

---

### Phase 2: Predictive PR Forecasting + Analytics Tab

**Rationale:** This phase is pure Domain engineering and a new SwiftUI tab. It reads from existing repositories (LiftRepository, WorkoutRepository) and requires no new frameworks, no new Gemini endpoints, and no new hardware integrations. Building it in Phase 2 lets the team establish the `exercise-to-muscle-group mapping` infrastructure, which is a shared dependency required by both analytics (volume load per muscle) and muscle fatigue heatmap. Delivering this phase produces a visually compelling tab that validates the Elite tier for early testers before the riskier features ship.

**Delivers:** Exercise-to-muscle-group mapping (shared Domain infrastructure), PRForecastEngine (linear regression with confidence intervals), MuscleFatigueDomainModel + VolumeAccumulationAnalyzer, AnalyticsView + AnalyticsViewModel, Swift Charts integration (e1RM trend + LineMark + RuleMark), MuscleMap SPM package integration, cycle-aware chart annotations.

**Features addressed:** PR forecasting and analytics (full P1 scope), muscle fatigue heatmap (full P1 scope).

**Pitfalls avoided:** PR model statistical validity — minimum 5-point threshold, confidence bands, and physiological bounds enforced in Domain with unit tests before any chart renders.

**Research flag:** Standard patterns — Swift Charts and MuscleMap are well-documented. Statistical regression in Domain is straightforward.

---

### Phase 3: Conversational AI Coach (Text + Voice Architecture)

**Rationale:** The AI Coach requires the most new infrastructure: a new Gemini endpoint, new SwiftData models, new speech controllers, and the conversation context window design. Placing it before Bar Path avoids a dependency inversion — the audio session architecture established here (VoiceSessionManager) must be in place before bar path recording is added, because both features share AVAudioSession. Building the coach first means the audio pitfall is resolved before the more complex Vision feature arrives. The Cloudflare Worker's `/coach-chat` endpoint is also simpler than `/analyze-form` and serves as a lower-risk introduction to Worker extensions.

**Delivers:** `/coach-chat` Cloudflare Worker endpoint (Gemini 2.5 Flash), GeminiChatService, ConversationMessage SwiftData model (schema V15), ConversationRepository, CoachConversationContext (prompt builder with cycle + readiness + injury + history injection), rolling 20-turn context window with ConversationSummarizer, weekly check-in flow, CoachChatView + CoachChatViewModel, VoiceSessionManager (audio session orchestration), SpeechInputController (SFSpeechRecognizer behind protocol), SpeechOutputController (AVSpeechSynthesizer with sentence-boundary chunking behind protocol).

**Features addressed:** AI Coach text chat + weekly check-in (full P1 scope), voice input/output (P2 — ship text first, voice in this phase given infrastructure is built together).

**Pitfalls avoided:** Conversation history token bloat (rolling window designed from day one); AVSpeechSynthesizer TTS streaming (sentence-boundary chunking with utterance queue); audio session routing (VoiceSessionManager built before bar path recording); protocol seams for speech (SpeechRecognizerProtocol + SpeechSynthesizerProtocol defined before implementation).

**Research flag:** Needs a focused spike on the streaming Gemini → sentence-chunked TTS pipeline in isolation before wiring to the full coach flow. Audio session management on physical device must be prototyped and verified before Phase 4 begins.

---

### Phase 4: Bar Path + Form Analysis

**Rationale:** This is the highest-risk, highest-complexity feature and deliberately comes last. By Phase 4 the team has established schema migration patterns (V13–V15), Cloudflare Worker extension patterns (/coach-chat), protocol seam patterns for hardware abstraction (speech controllers), and Swift 6 concurrency patterns (HealthKit Sendability). All of that experience applies directly to Bar Path. This feature introduces the last new framework combination (AVCaptureSession + Vision) and the most expensive Gemini call type (multimodal video). The audio session architecture from Phase 3 is already in place.

**Delivers:** BarPathCaptureView + AVCaptureSession (CameraSessionProtocol), VNDetectTrajectoriesRequest + VNTrackObjectRequest pipeline (BarPathTrackerProtocol), BarPathAnalyzer + FormFeedbackMapper (Domain, pure Swift), FormCheckRecord SwiftData model (schema V16), FormCheckUsageRepository, `/analyze-form` Cloudflare Worker endpoint with server-side per-user monthly quota (Cloudflare KV), GeminiFormService (720p keyframe JPEG inline, 3–5 frames, under 20MB), FormAnalysisResultView (on-device cues + async Gemini cues), usage counter UI reading from proxy response headers.

**Features addressed:** Bar path tracking (full P1 scope for Big Three lifts), Gemini multimodal form coaching (full P1 scope with monthly cap).

**Pitfalls avoided:** Vision gym-condition failures (two-stage tracking: body pose + VNTrackObjectRequest; pre-recording confidence overlay; minimum .medium confidence threshold); Gemini video cost explosion (server-side quota enforcement at Worker, keyframe JPEG not full video); CI coverage with Vision/AVFoundation (CameraSessionProtocol + BarPathTrackerProtocol defined first; concrete hardware adapters excluded from coverage); audio session conflict (VoiceSessionManager from Phase 3 already handles routing).

**Research flag:** Needs a tracking prototype spike before UI design — validate that VNTrackObjectRequest initialized from user-tapped barbell bounding box produces usable tracking quality on real gym video in low-light. This spike should produce a Go/No-Go decision on approach before Phase 4 planning begins.

---

### Phase Ordering Rationale

- Travel Mode first because it proves the schema migration pattern at lowest risk (no new frameworks, no new services).
- Readiness in Phase 1 because all infrastructure exists; only Domain logic is new; validates Elite tier value proposition immediately.
- Analytics in Phase 2 because it is the highest value-to-effort ratio feature after Phase 1 and establishes the shared exercise-to-muscle-group mapping needed by multiple features.
- AI Coach before Bar Path because the audio session architecture designed for voice coach is a prerequisite for the bar path recording feature; shipping them in the wrong order forces a refactor.
- Bar Path last because it is the only feature that could realistically slip or require scope reduction; placing it last protects the overall schedule.

### Research Flags

Phases needing deeper research during planning:
- **Phase 3 (AI Coach):** Spike needed on streaming Gemini → sentence-chunked AVSpeechSynthesizer pipeline; also validate Cloudflare Worker streaming support (or confirm full-response-before-speak is acceptable latency for v1.0).
- **Phase 4 (Bar Path):** Tracking prototype spike required before planning begins; validate VNTrackObjectRequest quality on real gym video. If quality is insufficient, scope fallback to Gemini-only frame analysis (no on-device path overlay) must be decided before Phase 4 roadmap is locked.

Phases with standard patterns (can skip research-phase):
- **Phase 1 (Travel Mode + Readiness):** Well-documented SwiftData + Domain patterns; existing codebase provides direct templates.
- **Phase 2 (Analytics):** Swift Charts and linear regression in Domain are well-documented; MuscleMap SDK has clear integration guide.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All Apple framework APIs verified via official docs; Gemini model IDs confirmed; MuscleMap version confirmed via Swift Package Index; only one SPM dependency needed |
| Features | MEDIUM | Competitor features verified via multiple sources as of early 2026; technical capability claims verified against Apple docs; pricing current as of March 2026; user behavior assumptions are inference |
| Architecture | HIGH | Based on direct codebase inspection (V12 schema, existing patterns) + verified Apple API capabilities; integration points mapped to actual existing code |
| Pitfalls | HIGH (framework behavior) / MEDIUM (cost modeling) | Framework pitfalls from official docs + community sources; API cost thresholds from community patterns, not first-party billing data |

**Overall confidence:** HIGH — the stack is entirely Apple system frameworks + one known SPM package; the architecture extends a well-understood existing codebase; the pitfalls are well-documented framework behaviors with clear mitigations.

### Gaps to Address

- **Gemini video cost per call at scale:** Cost modeling for form analysis calls is estimated from March 2026 Gemini pricing; actual per-call cost at production volume (720p keyframe JPEGs × monthly cap × subscriber count) should be validated with a billing simulation before Phase 4 launch pricing is finalized.
- **VNTrackObjectRequest quality on real gym video:** On-device bar tracking with user-tapped bounding box is the recommended approach but has not been prototyped in the actual app environment. This is the single highest-uncertainty technical assumption in the plan. The Phase 4 spike is non-optional.
- **AVAudioSession routing on all device/audio configurations:** The pitfall is documented but the exact `VoiceSessionManager` state machine needs empirical verification on physical devices before Phase 3 ships. Simulator results are not reliable for audio routing.
- **Cloudflare KV/D1 rate limiting for per-user quota enforcement:** The Worker quota architecture assumes Cloudflare KV or D1 is available and sufficient for per-user monthly counters. This should be confirmed during Cloudflare Worker planning in Phase 4 — D1 is the more robust choice for queryable usage records.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: VNDetectTrajectoriesRequest, VNDetectHumanBodyPoseRequest, Swift Charts, SFSpeechRecognizer, AVSpeechSynthesizer, AVCaptureSession, AVAudioSession, HealthKit — all framework APIs verified
- Gemini API official docs: video understanding, models list, interactions API — model IDs and pricing confirmed
- WWDC sessions: Swift Charts WWDC23/24, SpeechAnalyzer WWDC25 (confirms iOS 26 target, not applicable at iOS 17), Personal Voice WWDC23
- Direct codebase inspection: SundeeFundee/ source tree, V12 schema, existing services and domain engines

### Secondary (MEDIUM confidence)
- JuggernautAI, Fitbod, Dr. Muscle, Hevy competitor analysis via PowerliftingTechnique.com, Arvo, hotelgyms.com, hevyapp.com, dr-muscle.com
- Community: AVAudioSession routing bug (Medium), Vision ML on iOS pitfalls (ksemianov.github.io), SwiftData migrations (fatbobman.com)
- MuscleMap 1.6.0 — GitHub + Swift Package Index (actively maintained, iOS 17+, zero deps confirmed)

### Tertiary (LOW confidence)
- Gemini API cost scaling thresholds — community patterns, not first-party billing projections at production volume
- Cloudflare KV/D1 write throughput at quota-enforcement scale — assumed adequate; needs confirmation

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
