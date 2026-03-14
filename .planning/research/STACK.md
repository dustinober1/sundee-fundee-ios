# Stack Research

**Domain:** iOS Elite Fitness Features — Computer Vision, AI Coaching, Voice, Analytics
**Researched:** 2026-03-14
**Confidence:** HIGH (Apple framework APIs verified via official docs; Gemini model IDs confirmed via current API docs; third-party package version confirmed via Swift Package Index)

---

## Context: What Already Exists

These are validated and shipped — do NOT re-add or change them:

| Capability | Implementation |
|------------|----------------|
| AI workout generation | `GeminiWorkoutService` → Cloudflare Worker → `gemini-3.1-flash-lite-preview` |
| HealthKit data | `HealthKitReadinessRepository` (sleep, HRV, resting HR) |
| Persistence | SwiftData + CloudKit (private + public DB) |
| Subscriptions | StoreKit 2 (Free / Plus / Pro) |
| Body tracking | Apple Vision framework — imported but unused |
| Charting | None yet |

---

## New Stack Additions by Feature

### Feature 1: Predictive PR Forecasting & Analytics

#### Swift Charts (system framework — zero install)
| Property | Value |
|----------|-------|
| Framework | `Charts` (Apple, built into iOS 16+) |
| Version | iOS 17+ adds `chartXSelection`, `chartYSelection`; iOS 18 adds `LinePlot` vectorized plots |
| Purpose | e1RM trend lines, projected PR curves, workout volume bars |
| Why | Native SwiftUI integration, zero dependency, supports `RuleMark` for prediction overlays and `chartXSelection` for interactive scrubbing |

Use `LineMark` + `RuleMark` for historical e1RM trend with projected future curve. `chartXSelection` in iOS 17 handles interactive tooltip popover at selected date. No third-party charting library needed — Swift Charts has full capability for this use case.

#### No CoreML needed for e1RM forecasting
e1RM is a deterministic formula (Brzycki, Epley, or Lombardi), not an ML inference problem. Compute it in Domain/ as pure Swift math. Peaking predictions (planned peak week, volume taper) are likewise algorithmic. Avoid CoreML overhead for what is arithmetic.

---

### Feature 2: Bar Path & Form Analysis

#### Apple Vision — VNDetectTrajectoriesRequest
| Property | Value |
|----------|-------|
| Framework | `Vision` (Apple, already imported) |
| API | `VNDetectTrajectoriesRequest` |
| Available since | iOS 14 |
| Purpose | Track parabolic movement of barbell across video frames |
| Why | On-device, no network, no third-party dependency. Accepts `trajectoryLength` (min 5 points) and optional `objectMaximumNormalizedRadius` to filter noise. Returns `VNTrajectoryObservation` with detected path points. |

**Important constraint:** `VNDetectHumanBodyPose3DRequest` (3D skeletal pose) requires LiDAR — iPhone 12 Pro or later only. Do NOT use 3D pose as the primary form signal. Use `VNDetectTrajectoriesRequest` for bar path (all devices) and `VNDetectHumanBodyPoseRequest` (2D, all devices, iOS 14+) for joint angle checks. Reserve 3D pose as an enhancement for Pro-tier devices.

#### AVFoundation — AVCaptureSession + AVCaptureVideoDataOutput
| Property | Value |
|----------|-------|
| Framework | `AVFoundation` (Apple, system) |
| Purpose | Capture live camera frames as `CMSampleBuffer` for Vision processing |
| Why | `AVCaptureVideoDataOutput` feeds individual frames to `VNImageRequestHandler` without recording a file. Keeps processing real-time and avoids storage overhead for form analysis. |
| Threading | Run session on a dedicated `DispatchQueue` (not MainActor). Use `CaptureService` actor pattern to bridge to Swift concurrency. |

#### Gemini Multimodal — Form Coaching (via existing Cloudflare Worker)
| Property | Value |
|----------|-------|
| Model | `gemini-2.5-flash` (upgrade from `gemini-3.1-flash-lite-preview` for vision tasks) |
| Input | Base64-encoded JPEG frames (< 20MB inline) or short video clip via File API |
| Format | Existing `contents` / `systemInstruction` / `generationConfig` structure in `GeminiWorkoutService` pattern |
| Purpose | Post-set form coaching cues from sampled frames |
| Why | The Cloudflare Worker already proxies Gemini; extend with a new `/analyze-form` endpoint that accepts base64 image data. Gemini 2.5 Flash supports image and video inputs natively. Monthly cap enforced server-side in the Worker. |

Extend the existing Cloudflare Worker with a `/analyze-form` route. Send 3–5 representative JPEG frames sampled from the bar path recording. Return structured coaching text. Cap calls in the Worker by counting per-user-ID per calendar month.

---

### Feature 3: Travel Mode & Multi-Gym Equipment Profiles

#### No new frameworks needed
This feature is pure SwiftData modeling + existing Gemini workout generation. New `EquipmentProfile` and `GymProfile` SwiftData `@Model` types, a schema migration (V9), and a modified `WorkoutGenerationContext` that passes the active profile's equipment list.

| Work | Details |
|------|---------|
| SwiftData schema | Add `EquipmentProfile` (name, equipment list as `[String]`, isTravel `Bool`) and `GymProfile` (name, location, `EquipmentProfile`) models |
| Migration | V9 lightweight migration — new optional models, no existing model changes |
| CloudKit constraint | All new properties need default values or be optional for CloudKit sync compatibility |
| Workout adaptation | Inject `EquipmentProfile.equipment` into `GeminiPromptBuilder.userPrompt` — already has an `equipment` field in `WorkoutGenerationContext` |

---

### Feature 4: Conversational AI Coach with Voice

#### Speech Framework — SFSpeechRecognizer (Speech-to-Text)
| Property | Value |
|----------|-------|
| Framework | `Speech` (Apple, system) |
| API | `SFSpeechRecognizer` + `SFSpeechAudioBufferRecognitionRequest` + `AVAudioEngine` |
| On-device | Set `requiresOnDeviceRecognition = true` for offline support (iOS 13+) |
| Purpose | Transcribe user voice input during weekly check-in and mid-workout queries |
| Why | Zero cost, no third-party dependency, privacy-respecting. On-device mode available. `AsyncThrowingStream` wraps the audio tap for Swift concurrency compatibility. |

**Note on SpeechAnalyzer:** Apple announced `SpeechAnalyzer` at WWDC 2025 (iOS 26). Since this project targets iOS 17.0+, use `SFSpeechRecognizer`. Do not adopt `SpeechAnalyzer` until minimum deployment target moves to iOS 26.

#### AVFoundation — AVSpeechSynthesizer (Text-to-Speech)
| Property | Value |
|----------|-------|
| Framework | `AVFoundation` (Apple, system) |
| API | `AVSpeechSynthesizer` + `AVSpeechUtterance` |
| Purpose | Read AI coach responses aloud during workouts |
| Why | 150+ preinstalled voices, zero cost, supports Personal Voice (iOS 17+) for users who want a cloned voice. Adequate for coaching cues. |
| Limitation | Does not stream token-by-token. Wait for full Gemini response before enqueuing utterance — acceptable for coach check-in use case. For workout cues, pre-render short phrases. |

#### Gemini Conversation Context (via Cloudflare Worker)
| Property | Value |
|----------|-------|
| Model | `gemini-2.5-flash` |
| Purpose | Weekly check-in dialogue + mid-workout question answering |
| Conversation history | Send `contents` array with alternating `user`/`model` turns — Gemini native multi-turn format |
| Worker change | Add `/coach-chat` endpoint that maintains turn history per request (client sends full history each call) |
| Why stateless | Cloudflare Workers are stateless; client stores conversation history in a local `[ChatMessage]` array backed by SwiftData |

Conversation history is stored locally in a new `CoachConversation` SwiftData model (array of `CoachMessage` with role + content). On each turn, serialize history to JSON and include in the Worker request body.

---

### Feature 5: Readiness & Auto-Regulation

#### HealthKit — Extended Query Types (extends existing)
| Property | Value |
|----------|-------|
| Framework | `HealthKit` (already integrated) |
| New query types | `HKQuantityType(.vo2Max)`, `HKQuantityType(.activeEnergyBurned)`, optional workout recovery metrics |
| Purpose | Richer readiness scoring beyond HRV/sleep/RHR |
| Why | HealthKit already authorized for HRV/sleep/RHR in `HealthKitReadinessRepository`. Add VO2 max for fitness baseline; active energy for recovery debt estimate. |

No new frameworks — extend `HealthKitReadinessRepository.fetchLatestMetrics()` to return a richer `ReadinessMetrics` struct, and build the scoring algorithm in Domain/ as pure Swift.

---

## Recommended Stack

### Core Technologies (New Additions Only)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift Charts | iOS 17+ (system) | e1RM trends, volume history, PR projections | Native SwiftUI, zero dependencies, `chartXSelection` + `RuleMark` cover all analytics UI needs |
| Vision — VNDetectTrajectoriesRequest | iOS 14+ (system) | Bar path tracking from camera frames | On-device, no cost per inference, parabolic trajectory detection built-in |
| Vision — VNDetectHumanBodyPoseRequest | iOS 14+ (system) | 2D joint angle detection for form analysis | Covers all devices; 3D variant requires LiDAR so use as enhancement-only |
| AVFoundation — AVCaptureSession | iOS 17+ (system) | Camera frame capture for Vision pipeline | Only way to stream CMSampleBuffers to VNImageRequestHandler in real time |
| Speech — SFSpeechRecognizer | iOS 17+ (system) | Voice input for AI coach | On-device recognition available, no cost, Swift concurrency compatible via AsyncThrowingStream |
| AVFoundation — AVSpeechSynthesizer | iOS 17+ (system) | Text-to-speech for AI coach responses | 150+ voices, Personal Voice support, zero cost |
| MuscleMap | 1.6.0 (SPM) | Muscle fatigue heatmap visualization | Only native SwiftUI library with front/back muscle map SVG overlays, heat intensity mapping, iOS 17+, zero external dependencies |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MuscleMap | `from: "1.6.0"` | Interactive human body muscle map with heatmap intensity | Fatigue visualization in analytics and post-workout summary |

MuscleMap is the only addition requiring a Swift Package Manager dependency. Everything else is Apple system frameworks.

### Development Tools (No Changes)

Existing XcodeGen + Xcode Cloud pipeline is sufficient. No new build tooling needed.

---

## Installation

```swift
// In project.yml — packages section, add:
packages:
  MuscleMap:
    url: https://github.com/melihcolpan/MuscleMap.git
    from: "1.6.0"

// In the target that needs muscle visualization (Features/Analytics or Features/Dashboard):
dependencies:
  - package: MuscleMap
```

No npm/Homebrew changes required. All other frameworks are system frameworks already available on iOS 17+.

---

## Cloudflare Worker Changes

The existing Worker at `workout-proxy.sundeefundee.workers.dev` needs two new routes:

| Route | Purpose | Model | Notes |
|-------|---------|-------|-------|
| `/analyze-form` | Receive base64 JPEG frames, return coaching text | `gemini-2.5-flash` | Enforce monthly per-user cap server-side; validate user ID in request |
| `/coach-chat` | Receive conversation history array, return next coach turn | `gemini-2.5-flash` | Client sends full `contents` array each call; Worker is stateless |

**Upgrade model for vision/chat:** Switch from `gemini-3.1-flash-lite-preview` to `gemini-2.5-flash` for form analysis and coach chat. The lite model is sufficient for text-only workout generation but `gemini-2.5-flash` has better multimodal reasoning at still-reasonable cost ($0.075/1M input tokens as of March 2026).

Keep `gemini-3.1-flash-lite-preview` for the existing `/generate-workout` route — cost optimization for high-volume generation calls.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| VNDetectTrajectoriesRequest | Third-party CV library (e.g., OpenCV via C++ bridge) | No C++ FFI complexity needed; Apple's trajectory detection is purpose-built for this parabolic motion case; massive overhead for no gain |
| SFSpeechRecognizer | Whisper CoreML (on-device) | Whisper requires bundling a 150MB+ model; SFSpeechRecognizer on-device mode delivers comparable quality with zero size cost |
| AVSpeechSynthesizer | ElevenLabs / external TTS API | Adds per-call cost and network dependency; AVSpeechSynthesizer is free, instant, and works offline during workouts |
| Swift Charts | DGCharts / AAChartKit-Swift | Third-party chart libs are not native SwiftUI; Swift Charts integrates with SwiftUI state and accessibility natively; sufficient for fitness analytics |
| MuscleMap SPM package | Custom SVG muscle diagram | Custom implementation is 2–3 weeks of work for a solved problem; MuscleMap is iOS 17+, zero deps, actively maintained |
| Gemini 2.5 Flash (form/chat) | GPT-4o Vision via OpenAI | Would require a new proxy endpoint and API key; Gemini is already integrated; multimodal quality is equivalent at lower cost |
| Inline base64 JPEG frames | Full video upload to Gemini File API | File API adds async upload/polling complexity; 3–5 JPEG frames < 2MB total fit inline; sufficient for post-set form review |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| VNDetectHumanBodyPose3DRequest as primary form signal | Requires LiDAR (iPhone 12 Pro+); excludes ~40% of user base | VNDetectHumanBodyPoseRequest (2D, all devices) + VNDetectTrajectoriesRequest for bar path |
| CoreML custom regression model for e1RM | e1RM is a deterministic formula, not a learning problem; adding CoreML model bundling for arithmetic is architectural waste | Pure Swift math in Domain/ (Brzycki formula: `weight / (1.0278 - 0.0278 * reps)`) |
| SpeechAnalyzer (iOS 26 API) | Project targets iOS 17.0+; SpeechAnalyzer is iOS 26+ only | SFSpeechRecognizer with `requiresOnDeviceRecognition = true` |
| Firebase AI Logic SDK | Project already has Gemini via Cloudflare Worker proxy; adding Firebase SDK introduces a heavyweight dependency (~10MB) and second auth system for no benefit | Continue with direct URLSession calls to Cloudflare Worker |
| Real-time video streaming to Gemini | Out of scope per PROJECT.md; high cost per continuous stream | Sample 3–5 frames post-set, send inline base64 |
| Third-party speech recognition (Deepgram, AssemblyAI) | Per-minute billing; network dependency; offline unusable | SFSpeechRecognizer on-device mode |
| Always-on HealthKit background delivery | Out of scope per PROJECT.md; battery and privacy cost | Fetch on app open or workout start only |

---

## Version Compatibility

| Package / Framework | Compatible With | Notes |
|---------------------|-----------------|-------|
| Swift Charts | iOS 17+ / Swift 6 | `chartXSelection` requires iOS 17; `LinePlot` requires iOS 18 — use conditionally |
| VNDetectTrajectoriesRequest | iOS 14+ / Swift 6 | Sendable-safe; use `VNSequenceRequestHandler` for stateful video tracking |
| SFSpeechRecognizer | iOS 17+ / Swift 6 | `requiresOnDeviceRecognition` stable since iOS 13; wrap delegate callbacks in `AsyncThrowingStream` for actor isolation |
| AVSpeechSynthesizer | iOS 17+ / Swift 6 | Personal Voice authorization requires `Privacy - Personal Voice Usage Description` in Info.plist |
| AVCaptureSession | iOS 17+ / Swift 6 | Must run on non-MainActor queue; use `CaptureService` actor pattern; Swift 6 strict concurrency requires explicit `nonisolated(unsafe)` or actor-isolated session management |
| MuscleMap 1.6.0 | iOS 17+, Swift 5.9+, Swift 6 compatible | Zero external dependencies; XcodeGen `packages:` entry sufficient |
| Gemini 2.5 Flash | Current (March 2026) | Replaces `gemini-3.1-flash-lite-preview` for vision/chat routes only |

---

## Stack Patterns by Feature

**For bar path tracking (real-time):**
- `AVCaptureSession` feeds frames → `VNSequenceRequestHandler` with `VNDetectTrajectoriesRequest` → accumulate `VNTrajectoryObservation.detectedPoints` → render overlay `Path` in SwiftUI

**For form coaching (post-set async):**
- Sample 3–5 frames from recorded set → JPEG compress to < 400KB each → base64 encode → POST to `/analyze-form` Worker route → display coaching text in UI

**For voice coach interaction:**
- `AVAudioEngine` tap → `SFSpeechAudioBufferRecognitionRequest` → transcription string → POST to `/coach-chat` Worker → response text → `AVSpeechSynthesizer.speak()`

**For muscle fatigue heatmap:**
- Calculate per-muscle load from completed sets (Domain/ logic) → normalize to 0.0–1.0 intensity values → pass to `MuscleMap` SDK's heatmap API

**For analytics charts:**
- Query lift history from SwiftData → compute e1RM per session in Domain/ → pass `[(Date, Double)]` to `Chart { LineMark(...) }` with `RuleMark` for projected PR date

**If targeting iOS 18+ users (enhancement):**
- Use `LinePlot` with a mathematical projection function for smooth e1RM forecast curves

---

## Sources

- [VNDetectTrajectoriesRequest — Apple Developer Documentation](https://developer.apple.com/documentation/vision/vndetecttrajectoriesrequest) — trajectory detection API, iOS 14+
- [VNDetectHumanBodyPose3DRequest — Apple Developer Documentation](https://developer.apple.com/documentation/vision/vndetecthumanbodypose3drequest) — confirmed LiDAR requirement
- [Swift Charts — Apple Developer Documentation](https://developer.apple.com/documentation/Charts) — chartXSelection iOS 17, LinePlot iOS 18
- [Swift Charts: Vectorized and function plots — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10155/) — LinePlot API (iOS 18)
- [Explore pie charts and interactivity in Swift Charts — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10037/) — chartXSelection pattern
- [Gemini API Models](https://ai.google.dev/gemini-api/docs/models) — confirmed gemini-2.5-flash as current production model
- [Gemini Video Understanding](https://ai.google.dev/gemini-api/docs/video-understanding) — inline base64 < 20MB, 1fps default sampling
- [AVSpeechSynthesizer — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) — Personal Voice (iOS 17+)
- [Extend Speech Synthesis with personal and custom voices — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10033/) — Personal Voice authorization pattern
- [SFSpeechRecognizer — Apple Developer Documentation](https://developer.apple.com/documentation/speech/sfspeechrecognizer) — on-device recognition
- [Bring advanced speech-to-text to your app with SpeechAnalyzer — WWDC25](https://developer.apple.com/videos/play/wwdc2025/277/) — confirms SpeechAnalyzer is iOS 26 only
- [MuscleMap — GitHub](https://github.com/melihcolpan/MuscleMap) — version 1.6.0, iOS 17+, zero deps, SwiftUI native
- [Identifying Trajectories in Video — Apple Developer Documentation](https://developer.apple.com/documentation/vision/identifying-trajectories-in-video) — VNDetectTrajectoriesRequest usage guide

---

*Stack research for: Sundee Fundee v1.0 Elite Tier*
*Researched: 2026-03-14*
