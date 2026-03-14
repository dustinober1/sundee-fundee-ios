# Architecture Research

**Domain:** Native iOS strength training app — elite tier feature integration
**Researched:** 2026-03-14
**Confidence:** HIGH (based on direct codebase inspection + verified API capabilities)

---

## Existing Architecture (Baseline)

Before describing new components, the current system must be understood because every new
feature plugs into it rather than beside it.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                                 │
│  Dashboard  Programs  WODs  History  Maxes  Benchmarks  Cycle  …    │
├─────────────────────────────────────────────────────────────────────┤
│             @Observable ViewModels (@MainActor)                      │
│   One ViewModel per feature screen. Dependency-injected.            │
├─────────────────────────────────────────────────────────────────────┤
│                   Repository Protocols (Sendable)                    │
│   WorkoutRepository  LiftRepository  ReadinessRepository  …         │
├─────────────────────────────────────────────────────────────────────┤
│        Domain Layer (pure Swift, zero framework deps, 100% tested)  │
│  InjuryAdaptationEngine  CycleAdaptationPolicy  BenchmarkCatalog    │
│  PainTrendAnalyzer  WeightCalculations  ReadinessMetrics  …         │
├──────────────────────┬──────────────────────────────────────────────┤
│   SwiftData Models   │   External Services                          │
│   22 @Model types    │   HealthKit  CloudKit  Gemini (via Worker)   │
│   V12 schema         │   StoreKit 2  AVFoundation                   │
└──────────────────────┴──────────────────────────────────────────────┘
```

**Key invariants that new features must respect:**

- Enum properties on `@Model` types stored as raw `String` — CloudKit requirement.
- Domain layer has zero framework imports. New Domain engines must stay pure Swift.
- Repositories are injected; ViewModels never construct concrete repos directly.
- `AppState` owns auth routing. New tabs/features check `currentUserID` from it.
- Schema versioning via XcodeGen `project.yml` + `AppSchemaV{N}.swift` — each new
  `@Model` type requires a new schema version and lightweight `MigrationStage`.
- Test coverage is 100% enforced. Every new Domain type and public method needs tests.

---

## New Component Map (All Five Features)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NEW: Elite Tier Component Layer                           │
├──────────────────┬──────────────────┬──────────────────┬────────────────────┤
│  Feature 1       │  Feature 2       │  Feature 3       │  Feature 4 + 5     │
│  PR Forecasting  │  Bar Path/Form   │  Travel Mode     │  AI Coach +        │
│  & Analytics     │  Analysis        │  & Equipment     │  Readiness Reg.    │
├──────────────────┴──────────────────┴──────────────────┴────────────────────┤
│                         New Domain Engines                                   │
│  PRForecastEngine   BarPathAnalyzer   TravelModeEngine   ReadinessAutoReg   │
│  MuscleFatigueMap   FormFeedback      EquipmentAdapter   CoachConversation  │
├──────────────────────────────────────────────────────────────────────────────┤
│                         New Repositories / Services                          │
│  GeminiFormService   GeminiChatService   EquipmentProfileRepo               │
│  FormCheckUsageRepo  ConversationRepo    FormCheckCapRepository              │
├──────────────────────────────────────────────────────────────────────────────┤
│                        New SwiftData Models (V13+)                           │
│  EquipmentProfile   ConversationMessage  FormCheckRecord  ReadinessScore    │
│  GymProfile                                                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                        New Framework Integrations                            │
│  Vision (bar path)   Speech (STT/TTS)   AVFoundation (video capture)        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Feature 1: Predictive PR Forecasting & Analytics

### New Components

**Domain:**
- `PRForecastEngine` — Pure Swift. Takes a `[OneRepMax]` time series per exercise,
  applies linear regression or exponential smoothing to project a target date for a
  goal weight. Returns a `PRForecast` value type with predicted date, confidence
  interval, and required weekly rate-of-gain.
- `MuscleFatigueDomainModel` — Pure Swift. Maps `[CompletedSet]` across a rolling
  7-day window to a per-muscle-group volume accumulation. Produces a `FatigueHeatmap`
  value type (dictionary of muscle group → fatigue percentage 0–100).
- `VolumeAccumulationAnalyzer` — Aggregates sets by muscle group, normalizes by
  known recovery windows, feeds `MuscleFatigueDomainModel`.

**Views/ViewModels:**
- `AnalyticsView` + `AnalyticsViewModel` — New tab or sheet. Displays PR trend
  charts (Swift Charts), muscle fatigue heatmap, and goal projection UI.
- `PRGoalSettingSheet` — Input for target weight + target date. ViewModel calls
  `PRForecastEngine` and surfaces back the projected date.

**No new repositories needed.** `PRForecastEngine` consumes data already available
via `LiftRepository.fetchOneRepMaxes(exercise:)` and
`WorkoutRepository.fetchSets(for:)`.

### Integration Points

| Existing Component | How It's Used |
|-------------------|---------------|
| `LiftRepository` | Read `OneRepMax` history for trend input |
| `WorkoutRepository` | Read `CompletedSet` history for muscle volume |
| `SubscriptionService` | Gate feature behind `.elite` tier |

### Data Flow

```
User opens Analytics tab
    ↓
AnalyticsViewModel.loadData()
    ↓
LiftRepository.fetchOneRepMaxes()  +  WorkoutRepository.fetchSets()
    ↓
PRForecastEngine.forecast(history:goal:)   →   PRForecast
MuscleFatigueDomainModel.compute(sets:)    →   FatigueHeatmap
    ↓
AnalyticsView renders Swift Charts + heatmap overlay
```

---

## Feature 2: Bar Path & Form Analysis

### New Components

**Framework Integrations:**
- `Vision` (`VNDetectHumanBodyPose3DRequest`, `VNDetectHumanBodyPoseRequest`) — On-device.
  iOS 17 supports 3D body pose (17 joints) on iPhone 12 Pro+. Requires no entitlement.
- `AVFoundation` (`AVCaptureSession`) — Live camera feed during set execution.
  Post-set analysis model: capture video, then process. Not real-time to avoid
  performance impact during lift.

**Domain:**
- `BarPathAnalyzer` — Pure Swift. Consumes a `[VNHumanBodyPoseObservation]` sequence
  (converted to plain `BarPathPoint` value types before entering Domain), computes
  bar path deviation from ideal vertical plane, symmetry metrics, and joint angles.
  Returns `BarPathReport` (deviation mm, symmetry %, per-joint angle history).
- `FormFeedbackMapper` — Maps `BarPathReport` metrics to plain-language coaching cues.
  On-device rule-based cues (fast, no cost). Feeds into Gemini for deeper analysis.

**Repository/Service:**
- `GeminiFormService` — New service (parallel to `GeminiWorkoutService`). Sends
  video frames (base64 JPEG, not full video — sampled at key moments) or the
  `BarPathReport` JSON to the Cloudflare Worker, which relays to Gemini multimodal.
  Returns `FormCoachingResponse` (list of cues with severity).
- `FormCheckUsageRepository` (protocol) + SwiftData implementation — Tracks monthly
  usage count per user. Schema: `FormCheckRecord` with `userID`, `exerciseName`,
  `checkDate`. ViewModel gates API call when count >= monthly cap.

**New SwiftData Model (V13):**
- `FormCheckRecord` — `userID: String`, `exerciseName: String`, `checkedAt: Date`,
  `feedbackSummary: String`. Lightweight record for cap tracking and history display.

**Views/ViewModels:**
- `BarPathCaptureView` — Camera overlay shown during set, uses `AVCaptureSession`.
  Minimal UI to avoid distraction. "Analyze" button triggers post-set processing.
- `FormAnalysisResultView` — Shows bar path visualization (line chart over video
  frame), on-device cues immediately, then Gemini cues async.
- `FormAnalysisViewModel` — Owns `AVCaptureSession`, Vision request pipeline,
  `GeminiFormService` call, usage cap check.

### Integration Points

| Existing Component | How It's Used |
|-------------------|---------------|
| `WorkoutExecutionView` | New "Record Form" button triggers capture flow as a sheet |
| `SubscriptionService` | Gate Gemini form check behind `.elite` |
| `GeminiWorkoutService` (pattern) | `GeminiFormService` follows same proxy URL pattern |
| Cloudflare Worker | Must add `/analyze-form` endpoint (or extend `/generate-workout`) |

### Data Flow

```
User taps "Record Form" during set
    ↓
BarPathCaptureView activates AVCaptureSession
    ↓
Set completes → Vision pipeline processes captured frames
    → VNDetectHumanBodyPoseRequest per frame
    → BarPathAnalyzer.compute(observations:) → BarPathReport
    → FormFeedbackMapper.cues(from:) → [on-device cues] (instant)
    ↓
FormAnalysisViewModel checks FormCheckUsageRepository cap
    ↓ (if under cap)
GeminiFormService.analyze(report: BarPathReport) → async Gemini cues
    → FormCheckRecord saved to SwiftData
    ↓
FormAnalysisResultView displays composite feedback
```

**Important constraint:** Gemini video API requires files > 20 MB via File API with
48-hour lifetime. For on-device processing, send the `BarPathReport` JSON + selected
keyframe images (base64 JPEG, well under 20 MB) rather than raw video. This avoids
File API complexity and keeps the Cloudflare Worker stateless.

---

## Feature 3: Travel Mode & Multi-Gym Equipment Profiles

### New Components

**New SwiftData Models (V13 or V14):**
- `GymProfile` — `id: String`, `userID: String`, `name: String`,
  `isTravelProfile: Bool`, `equipmentListJSON: String` (CloudKit-safe serialization
  of equipment array as JSON string).
- No separate model for individual equipment items — store as JSON string on
  `GymProfile` to avoid relationship complexity with CloudKit.

**Domain:**
- `TravelModeEngine` — Pure Swift. Extends the existing adaptation pattern. Takes a
  `GeneratedWorkout` or `Program` and a `[String]` (available equipment), replaces
  exercises that require unavailable equipment using a travel regression table.
  Returns adapted workout + list of substitutions made.
- `EquipmentAdapter` — Shared helper used by both `TravelModeEngine` and
  `InjuryAdaptationEngine` for exercise lookup. Consider extracting the regression
  table from `InjuryAdaptationEngine` into a shared `ExerciseRegressionCatalog`
  static type to avoid duplication.

**Repository:**
- `EquipmentProfileRepository` (protocol) + `SwiftDataEquipmentProfileRepository`
  — CRUD for `GymProfile`. Follows existing `BarbellRepository` pattern exactly.

**Views/ViewModels:**
- `GymProfileListView` + `GymProfileDetailView` — Manage saved gym profiles.
  "Travel Mode" toggle sets active profile.
- `TravelModeViewModel` — Activates travel profile, triggers `WorkoutGenerationContext`
  modification to pass available equipment. Existing AI workout gen already accepts
  `equipment: [String]` in `WorkoutGenerationContext` — this is a near-zero-change
  integration.

### Integration Points

| Existing Component | How It's Used |
|-------------------|---------------|
| `WorkoutGenerationContext.equipment` | Travel mode sets this field — existing field |
| `GeminiWorkoutService` | Unchanged — receives equipment list as before |
| `InjuryAdaptationEngine` | Pattern template for `TravelModeEngine` |
| `BarbellRepository` pattern | `EquipmentProfileRepository` mirrors this exactly |

### Data Flow

```
User enables Travel Mode → activates GymProfile (travel)
    ↓
AppState (or DashboardViewModel) reads active GymProfile
    ↓
WorkoutGenerationContext.equipment ← GymProfile.equipmentList
    ↓
GeminiWorkoutService.generate(context:) — no change needed
    ↓
For program sessions: TravelModeEngine.adapt(session:availableEquipment:)
```

**Why this builds first:** `WorkoutGenerationContext.equipment` already exists.
Travel mode is mostly a data model + UI change. Minimal new infra.

---

## Feature 4: Conversational AI Coach

### New Components

**New SwiftData Models (V14 or V15):**
- `ConversationMessage` — `id: String`, `userID: String`, `role: String` ("user"/"model"),
  `content: String`, `sentAt: Date`, `conversationID: String`.
- No separate `Conversation` model — group by `conversationID` in queries.

**Domain:**
- `CoachConversationContext` — Pure Swift value type. Builds the system prompt for
  the coach persona. Incorporates user's current cycle phase, readiness score,
  active injuries, and recent workout history into the system instruction. This is
  the personalization layer — the prompt builder, not a stateful object.
- `CoachMessageFormatter` — Formats raw Gemini responses into structured coach
  messages: strips markdown if needed, extracts action items.

**Repository/Service:**
- `ConversationRepository` (protocol) + `SwiftDataConversationRepository` — Saves
  and retrieves `ConversationMessage` records.
- `GeminiChatService` — New service. Uses Gemini's `contents` array with role
  alternation to maintain multi-turn context. Sends last N messages (rolling window,
  e.g., 20) to stay within context limits. Routes through existing Cloudflare Worker
  at a new endpoint (e.g., `/coach-chat`).

**Speech Integration:**
- `SpeechInputController` — Wraps `SFSpeechRecognizer` for STT. Manages
  authorization, recognition task lifecycle, publishes transcribed text.
  Note: iOS 26 introduces `SpeechAnalyzer` as a replacement, but `SFSpeechRecognizer`
  remains available on iOS 17 (our deployment target). Use `SFSpeechRecognizer`.
- `SpeechOutputController` — Wraps `AVSpeechSynthesizer` for TTS. Limitation:
  `AVSpeechSynthesizer` cannot stream token-by-token — must wait for full response.
  Mitigation: chunk response into sentences and synthesize sentence-by-sentence as
  they arrive (detect sentence boundaries via `.`, `!`, `?` markers in streamed text).
  **However:** Gemini via the current Cloudflare Worker does not stream. Either add
  streaming support to the Worker or accept the UX limitation (speak full response
  after it arrives). For v1.0, speak full response — simpler, still useful.

**Views/ViewModels:**
- `CoachChatView` — Chat bubble UI. Scrolling message list, text input, microphone
  button, speaker button on AI messages.
- `CoachChatViewModel` — Owns `GeminiChatService`, `ConversationRepository`,
  `SpeechInputController`, `SpeechOutputController`. Builds `CoachConversationContext`
  before each API call.

### Integration Points

| Existing Component | How It's Used |
|-------------------|---------------|
| `HealthKitReadinessRepository` | Feeds readiness score into coach system prompt |
| `CycleAdaptationPolicy` | Current phase read for coach context |
| `InjuryAdaptationEngine.normalizedBodyRegions()` | Active injuries in prompt |
| `WorkoutRepository` | Recent workout summary in prompt |
| `GeminiWorkoutService` pattern | `GeminiChatService` mirrors request structure |
| `SubscriptionService` | Gate behind `.elite` |

### Data Flow

```
User opens Coach tab → CoachChatViewModel.loadHistory()
    ↓
ConversationRepository.fetchMessages(conversationID:)
    ↓
User types or speaks (SpeechInputController → transcribed text)
    ↓
CoachChatViewModel builds CoachConversationContext (readiness + cycle + injuries)
    ↓
GeminiChatService.send(messages: [last N], systemPrompt: context)
    ↓
ConversationMessage saved → UI updates
    ↓ (optional)
SpeechOutputController.speak(response)
```

---

## Feature 5: Readiness & Auto-Regulation

### New Components

**Domain:**
- `ReadinessScoreEngine` — Pure Swift. Extends the existing `ReadinessMetrics.readinessScore`
  computed property (currently a simple average in `RepositoryProtocols.swift`). New
  engine applies weighted scoring: HRV weight > sleep weight > RHR weight, with
  per-user baseline normalization. Takes `ReadinessMetrics` + `ReadinessSurveyAnswers`
  (subjective inputs already implemented in `ReadinessSurvey.swift`) and returns a
  `CompositeReadinessScore` (0–10 `Double` + breakdown by component + trend vs. 7-day
  average).
- `AutoRegulationPolicy` — Pure Swift. Follows exact same pattern as
  `CycleAdaptationPolicy`. Takes `CompositeReadinessScore` + `ProgramExercise` array,
  returns adapted exercises with volume/intensity adjustments. Three tiers: score < 4
  (deload -20% volume), score 4–7 (no change), score > 7 (+5-10% intensity suggestion).
  This is a new policy that composes with `CycleAdaptationPolicy` in a pipeline.

**Policy Composition Pattern:**
```
ProgramExercise[]
    → CycleAdaptationPolicy.applyPhaseAdjustment()    (existing)
    → AutoRegulationPolicy.applyReadinessAdjustment() (new)
    → InjuryAdaptationEngine.adaptProgram()           (existing)
    → adapted ProgramExercise[]
```
The three policies run sequentially. The domain caller (ViewModel or existing
adaptation pipeline) chains them. Each policy is stateless and operates on value types.

**New SwiftData Model (V13+):**
- `ReadinessScore` — `id: String`, `userID: String`, `scoredAt: Date`,
  `compositeScore: Double`, `hrvScore: Double`, `sleepScore: Double`, `rhrScore: Double`,
  `surveyScore: Double`. Persists daily scores for 7-day trend calculation.

**Repository:**
- `ReadinessScoreRepository` (protocol) + `SwiftDataReadinessScoreRepository`
  — Saves and fetches `ReadinessScore` records. Minimal interface.

**Views/ViewModels:**
- `ReadinessDashboardCard` — Extends the existing `ReadinessCard.swift` in Dashboard.
  Shows composite score, component breakdown, and today's auto-regulation recommendation
  ("Deload today", "Train as planned", "Push the intensity").
- `AutoRegulationViewModel` — Owned by `DashboardViewModel` or injected into
  `WorkoutExecutionViewModel`. Computes regulated workout at session start.

### Integration Points

| Existing Component | How It's Used |
|-------------------|---------------|
| `HealthKitReadinessRepository` | Source of HRV, sleep, RHR metrics (unchanged) |
| `ReadinessSurvey.swift` (Domain) | Subjective survey answers feed into composite score |
| `ReadinessSurveyViewModel` | Triggers `ReadinessScoreEngine` after survey submit |
| `CycleAdaptationPolicy` | Policy chain — readiness policy runs after cycle policy |
| `DashboardView/ViewModel` | Readiness card renders composite score |
| `WorkoutExecutionViewModel` | Applies `AutoRegulationPolicy` at session start |

---

## Component Boundaries Table

| Component | New or Modified | Location | Dependencies |
|-----------|----------------|----------|--------------|
| `PRForecastEngine` | NEW | `Domain/Analytics/` | None (pure Swift) |
| `MuscleFatigueDomainModel` | NEW | `Domain/Analytics/` | None |
| `AnalyticsViewModel` | NEW | `Features/Analytics/` | `LiftRepository`, `WorkoutRepository` |
| `BarPathAnalyzer` | NEW | `Domain/FormAnalysis/` | None (pure Swift, uses value types) |
| `FormFeedbackMapper` | NEW | `Domain/FormAnalysis/` | None |
| `GeminiFormService` | NEW | `Repositories/Gemini/` | Cloudflare Worker |
| `FormCheckUsageRepository` | NEW | `Repositories/SwiftData/` | `FormCheckRecord` model |
| `FormAnalysisViewModel` | NEW | `Features/FormAnalysis/` | Vision, AVFoundation, `GeminiFormService` |
| `TravelModeEngine` | NEW | `Domain/TravelMode/` | Shares `ExerciseRegressionCatalog` |
| `ExerciseRegressionCatalog` | EXTRACTED | `Domain/` | Refactored from `InjuryAdaptationEngine` |
| `EquipmentProfileRepository` | NEW | `Repositories/SwiftData/` | `GymProfile` model |
| `GymProfile` | NEW SwiftData | `Models/` | CloudKit-safe (JSON string for list) |
| `CoachConversationContext` | NEW | `Domain/Coach/` | None (pure Swift prompt builder) |
| `GeminiChatService` | NEW | `Repositories/Gemini/` | Cloudflare Worker |
| `ConversationRepository` | NEW | `Repositories/SwiftData/` | `ConversationMessage` model |
| `SpeechInputController` | NEW | `Services/` | `Speech` framework |
| `SpeechOutputController` | NEW | `Services/` | `AVFoundation` |
| `CoachChatViewModel` | NEW | `Features/Coach/` | `GeminiChatService`, Speech controllers |
| `ReadinessScoreEngine` | NEW | `Domain/Readiness/` | None (pure Swift) |
| `AutoRegulationPolicy` | NEW | `Domain/Readiness/` | None (pure Swift) |
| `ReadinessScoreRepository` | NEW | `Repositories/SwiftData/` | `ReadinessScore` model |
| `SubscriptionTier` | MODIFIED | `Services/SubscriptionService.swift` | Add `.elite` case |
| `MainTabView.TabRoute` | MODIFIED | `Features/Shell/` | Add `.analytics`, `.coach` tabs |

---

## Recommended Project Structure (New Directories Only)

```
SundeeFundee/
├── Domain/
│   ├── Analytics/             ← NEW
│   │   ├── PRForecastEngine.swift
│   │   └── MuscleFatigueDomainModel.swift
│   ├── FormAnalysis/          ← NEW
│   │   ├── BarPathAnalyzer.swift
│   │   └── FormFeedbackMapper.swift
│   ├── TravelMode/            ← NEW
│   │   └── TravelModeEngine.swift
│   ├── Coach/                 ← NEW
│   │   └── CoachConversationContext.swift
│   ├── Readiness/             ← NEW (extends existing)
│   │   ├── ReadinessScoreEngine.swift
│   │   └── AutoRegulationPolicy.swift
│   └── ExerciseRegressionCatalog.swift   ← EXTRACTED from InjuryAdaptationEngine
├── Features/
│   ├── Analytics/             ← NEW tab
│   │   ├── AnalyticsView.swift
│   │   └── AnalyticsViewModel.swift
│   ├── FormAnalysis/          ← NEW (sheet from workout execution)
│   │   ├── BarPathCaptureView.swift
│   │   ├── FormAnalysisResultView.swift
│   │   └── FormAnalysisViewModel.swift
│   ├── TravelMode/            ← NEW (sheet or settings subsection)
│   │   ├── GymProfileListView.swift
│   │   └── GymProfileDetailView.swift
│   ├── Coach/                 ← NEW tab
│   │   ├── CoachChatView.swift
│   │   └── CoachChatViewModel.swift
│   └── Readiness/             ← EXTEND existing Dashboard readiness card
│       └── ReadinessDashboardCard.swift  (replaces ReadinessCard.swift)
├── Models/
│   ├── GymProfile.swift       ← NEW
│   ├── ConversationMessage.swift  ← NEW
│   ├── FormCheckRecord.swift  ← NEW
│   └── ReadinessScore.swift   ← NEW
├── Repositories/
│   ├── Gemini/
│   │   ├── GeminiFormService.swift   ← NEW
│   │   └── GeminiChatService.swift   ← NEW
│   └── SwiftData/
│       ├── SwiftDataEquipmentProfileRepository.swift  ← NEW
│       ├── SwiftDataConversationRepository.swift      ← NEW
│       └── SwiftDataReadinessScoreRepository.swift    ← NEW
└── Services/
    ├── SpeechInputController.swift   ← NEW
    └── SpeechOutputController.swift  ← NEW
```

---

## Architectural Patterns

### Pattern 1: Policy Pipeline (Existing, Extended)

**What:** Stateless policy objects transform value types in sequence. Each policy is
independently testable. Policies compose by chaining calls.

**When to use:** Any time workout content must be adapted to user state (cycle,
readiness, injuries, equipment).

**New application:** `AutoRegulationPolicy` slots into the existing
`CycleAdaptationPolicy` → `InjuryAdaptationEngine` pipeline. The caller chains:

```swift
// In WorkoutExecutionViewModel or DashboardViewModel
let cycleAdapted = cyclePolicy.applyPhaseAdjustment(exercise:phase:readinessTier:confidence:profile:)
let readinessAdapted = AutoRegulationPolicy.apply(cycleAdapted, score: compositeScore)
let injuryAdapted = InjuryAdaptationEngine.adaptProgram(readinessAdapted, activeInjuries:)
```

### Pattern 2: Vision → Domain Value Type Bridge

**What:** Vision framework observations are not pure Swift value types — they carry
framework dependencies. The bridge pattern converts them before they enter Domain.

**When to use:** Any on-device ML/Vision result that feeds into testable Domain logic.

```swift
// In FormAnalysisViewModel (framework layer)
let observations: [VNHumanBodyPoseObservation] = try await runVisionPipeline(on: frames)
let barPathPoints: [BarPathPoint] = observations.map { BarPathPoint(from: $0) }

// Domain layer — pure Swift, testable
let report = BarPathAnalyzer.analyze(barPathPoints)
```

`BarPathPoint` is a plain struct with `x`, `y`, `z`, `confidence` — no Vision import.

### Pattern 3: Rolling Context Window for Chat

**What:** Gemini (and all LLMs) have context limits. For multi-turn chat, send only
the last N messages plus the system prompt.

**When to use:** `GeminiChatService` — always. Prevents unbounded context growth.

```swift
// In GeminiChatService
let windowedMessages = allMessages.suffix(20)  // Last 20 turns
let body: [String: Any] = [
    "contents": windowedMessages.map { ["role": $0.role, "parts": [["text": $0.content]]] },
    "systemInstruction": ["parts": [["text": systemPrompt]]]
]
```

---

## Schema Migration Plan

Current schema: V12. Five new models need V13–V16 (one per model to minimize blast
radius of each migration).

| Version | New Model | Notes |
|---------|-----------|-------|
| V13 | `GymProfile` | Travel Mode — earliest feature, simple lightweight migration |
| V14 | `ReadinessScore` | Readiness — builds on existing HealthKit infra |
| V15 | `FormCheckRecord` | Form Analysis — gated behind cap enforcement |
| V16 | `ConversationMessage` | Coach — last feature, most complex new model |

All migrations are lightweight (new `@Model` class with default values). No custom
migration stages needed.

---

## Cloudflare Worker Extensions Required

The existing Worker at `workout-proxy.sundeefundee.workers.dev/generate-workout`
needs two new endpoints:

| Endpoint | Feature | Payload |
|----------|---------|---------|
| `/analyze-form` | Bar Path / Form Analysis | `{ report: BarPathReport, keyframes: [base64JPEG], exerciseName: String }` |
| `/coach-chat` | AI Coach | `{ messages: [ChatMessage], systemPrompt: String }` |

Both follow the same Gemini native format (`contents`, `systemInstruction`,
`generationConfig`). Adding endpoints is low-risk and does not touch existing `/generate-workout`.

---

## Suggested Build Order (Dependency-Driven)

```
Phase 1: Foundation
├── Add .elite to SubscriptionTier
├── Travel Mode (Feature 3)  ← simplest, uses existing infra, proves schema migration
└── Readiness Auto-Regulation (Feature 5)  ← extends existing HealthKit infra

Phase 2: Analytics
└── PR Forecasting & Analytics (Feature 1)  ← pure Domain + new tab, no new services

Phase 3: AI Extensions
├── Conversational AI Coach (Feature 4)  ← new Gemini endpoint + speech
└── Bar Path & Form Analysis (Feature 2)  ← Vision + AVFoundation + new Gemini endpoint
```

**Rationale for this order:**

1. **Travel Mode first** — Touches only `WorkoutGenerationContext.equipment` (already exists),
   new SwiftData model, new UI. No framework integrations. Proves schema migration
   pattern for V13 before more complex features need it.

2. **Readiness Auto-Regulation second** — `HealthKitReadinessRepository` already works.
   New Domain engines (`ReadinessScoreEngine`, `AutoRegulationPolicy`) are pure Swift.
   Proves the policy pipeline extension before Form Analysis needs it.

3. **PR Forecasting third** — Pure Domain work. New tab. Reads existing `LiftRepository`
   and `WorkoutRepository`. No new frameworks, no new services. High value, low risk.

4. **AI Coach fourth** — Requires new Cloudflare Worker endpoint, new speech controllers,
   new SwiftData models. Complex but self-contained. Does not block Form Analysis.

5. **Bar Path & Form Analysis last** — Most technically novel: Vision framework,
   `AVCaptureSession`, multimodal Gemini, usage caps. Should be last so the team has
   experience with the schema migration pattern and Gemini extension pattern.

---

## Anti-Patterns

### Anti-Pattern 1: Vision Types Leaking into Domain

**What people do:** Pass `VNHumanBodyPoseObservation` directly to `BarPathAnalyzer`.

**Why it's wrong:** Domain layer must have zero framework imports. Importing Vision
makes unit tests require a real device or simulator, breaking CI speed and 100%
coverage enforcement.

**Do this instead:** Convert Vision observations to `BarPathPoint` structs in the
ViewModel before calling any Domain method. Domain only sees plain value types.

### Anti-Pattern 2: Storing Enum Arrays Directly on @Model

**What people do:** Add a `[EquipmentType]` property to `GymProfile`.

**Why it's wrong:** CloudKit does not support Swift enum arrays on `@Model` types.
Sync silently fails for affected records.

**Do this instead:** Serialize equipment lists to `equipmentListJSON: String` using
`JSONEncoder`. Add a computed property that decodes on access.

### Anti-Pattern 3: Unbounded Conversation History in Gemini Request

**What people do:** Send all saved `ConversationMessage` records in every API call.

**Why it's wrong:** Context grows without bound, increasing latency and cost. Gemini
has a maximum context window.

**Do this instead:** Always use `.suffix(20)` on the message array before building
the Gemini request body. Persist full history locally, send only the window.

### Anti-Pattern 4: On-Device Video Encoding to Full MP4 for Gemini

**What people do:** Record a full AVAsset, encode to MP4, send to Gemini via File API.

**Why it's wrong:** Files > 20 MB require the Gemini File API with 48-hour TTL and
additional async upload round-trips. The Cloudflare Worker becomes stateful.
AVSpeechSynthesizer latency increases. Form analysis UX degrades.

**Do this instead:** Sample key frames from the captured video buffer, encode as JPEG,
send as base64 inline in the request. The `BarPathReport` JSON plus 3–5 keyframe
JPEGs will stay well under the 20 MB inline limit.

---

## Integration Points Summary

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Gemini via Cloudflare Worker | POST `/analyze-form`, `/coach-chat` | New endpoints; same auth pattern as `/generate-workout` |
| Apple Vision | `VNDetectHumanBodyPoseRequest` in ViewModel | Converted to value types before Domain |
| Apple Speech (SFSpeechRecognizer) | `SpeechInputController` service | iOS 17+ target; `SpeechAnalyzer` (iOS 26) not yet available at target |
| AVSpeechSynthesizer | `SpeechOutputController` service | Full response before speaking for v1.0; streaming deferred |
| HealthKit | `HealthKitReadinessRepository` (existing) | Extended by `ReadinessScoreEngine`; no new HealthKit queries needed for v1.0 |
| StoreKit 2 | `SubscriptionService.SubscriptionTier` | Add `.elite` case + product ID |
| CloudKit | Private DB sync via SwiftData | New models auto-sync; `GymProfile.equipmentListJSON` pattern preserves CloudKit compat |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| ViewModel → Domain | Direct method call, value types only | Never pass framework objects into Domain |
| ViewModel → Repository | Protocol injection | Use existing constructor injection pattern |
| Policy pipeline | Sequential function composition | `CyclePolicy → ReadinessPolicy → InjuryEngine` |
| Feature 2 → Feature 5 | None at runtime | Both inform workout adaptation independently |
| Feature 4 ↔ Feature 5 | Coach reads readiness score | `CoachConversationContext` reads `ReadinessScore` from repo |
| Feature 3 ↔ Feature 1 | None | Independent |

---

## Sources

- Direct codebase inspection: `SundeeFundee/` source tree (March 2026)
- [VNDetectHumanBodyPoseRequest — Apple Developer Documentation](https://developer.apple.com/documentation/vision/vndetecthumanbodyposerequest)
- [Vision framework overview — Apple Developer Documentation](https://developer.apple.com/documentation/vision)
- [Gemini Video Understanding API](https://ai.google.dev/gemini-api/docs/video-understanding)
- [SFSpeechRecognizer — Apple Developer Documentation](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [WWDC25 SpeechAnalyzer session](https://developer.apple.com/videos/play/wwdc2025/277/) — note: targets iOS 26, not our iOS 17 deployment target
- [SwiftData Schema Migrations practical guide](https://medium.com/@manikantasirumalla5/handling-swiftdata-schema-migrations-a-practical-guide-e58e05bd3071)
- [WWDC23 Customize on-device speech recognition](https://developer.apple.com/videos/play/wwdc2023/10101/)

---

*Architecture research for: Sundee Fundee — v1.0 Elite Tier*
*Researched: 2026-03-14*
