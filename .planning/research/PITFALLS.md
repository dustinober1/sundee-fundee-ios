# Pitfalls Research

**Domain:** Elite iOS fitness app — AI coaching, computer vision, biometric auto-regulation, voice UI
**Researched:** 2026-03-14
**Confidence:** HIGH (framework behavior from official docs + verified community sources); MEDIUM (API cost modeling and scaling thresholds from community patterns)

---

## Critical Pitfalls

### Pitfall 1: AVAudioSession Routing Destroys Voice Coach UX

**What goes wrong:**
When the user starts a video recording session for bar path analysis (`.playAndRecord` AVAudioSession category), the system silently routes all audio playback through the earpiece speaker at very low volume — as if in a phone call. The voice AI coach text-to-speech output becomes inaudible mid-workout. Simultaneously, SFSpeechRecognizer sets the audio session to recording mode on activation but does not restore it to playback on deactivation, leaving the session stuck in record mode. This means the coach's spoken reply cannot be heard after the user stops speaking.

**Why it happens:**
iOS treats the `.playAndRecord` category as a phone-call-like mode by default. Developers add AVSpeechSynthesizer TTS output without testing on device with the camera also active. The SFSpeechRecognizer lifecycle bug is a documented framework behavior, not a developer error, but it still requires an explicit workaround.

**How to avoid:**
- Configure the AVAudioSession explicitly: `.playAndRecord` with `.defaultToSpeaker` option set, ensuring playback routes to the main speaker.
- Set `setAllowHapticsAndSystemSoundsDuringRecording(true)` to prevent haptic interference during recording.
- Build a `VoiceSessionManager` that explicitly activates and deactivates the audio session around each speech recognition request, and restores the session category to `.playback` after `SFSpeechRecognizer` stops.
- Test the full audio chain on a physical device with AirPods connected, earpiece only, and speaker only — the simulator does not reproduce routing bugs.
- Add explicit AVAudioSession interruption observers (`AVAudioSessionInterruptionNotification`) in the voice coach to handle incoming calls resuming the session.

**Warning signs:**
- Voice coach works in simulator but is inaudible or distorted on device.
- TTS stops working after a recording session without app restart.
- Users report AI coach "going quiet" mid-workout.

**Phase to address:**
Conversational AI Coach with Voice phase — architect `VoiceSessionManager` before wiring up bar path recording. These two features share the audio session and must be designed together, not independently.

---

### Pitfall 2: Vision Framework Produces Zero Observations in Real Gym Conditions

**What goes wrong:**
`VNDetectHumanBodyPoseRequest` (or a custom object tracking request for barbell path) returns zero observations or wildly inaccurate joint positions when lighting is poor, the user wears dark clothes against a dark background (common in gyms), or the barbell is small in the frame. Developers test in bright kitchens and the feature appears to work — then it fails in production for a significant portion of users.

**Why it happens:**
The Vision framework's body pose model has documented degraded performance in low-contrast scenes. Barbell tracking specifically requires either custom Core ML models or creative use of color-based object tracking (`VNTrackObjectRequest`), since Vision has no native "barbell" detector. Relying on body pose landmarks to infer bar position breaks down when the bar is out of frame or occluded.

**How to avoid:**
- Do not use `VNDetectHumanBodyPoseRequest` alone to track barbell position. Use a two-stage approach: body pose for joint angles (lift evaluation) + `VNTrackObjectRequest` initialized with a user-tapped bounding box around the barbell for path tracking.
- Add a pre-recording checklist in the UI: "Make sure your full body and barbell are visible" with a live camera preview showing a confidence overlay before the set begins.
- Define a minimum confidence threshold for `VNRecognizedPoint` (use `.high` confidence filter; discard `.low`). If observations fall below threshold for more than 3 consecutive frames, surface a "poor tracking quality" warning rather than silently producing bad form analysis.
- Test on the oldest supported device (iOS 17 iPhone) and in low-light conditions with a test video corpus before shipping.

**Warning signs:**
- Vision requests return empty arrays on-device but work on the simulator.
- Confidence values are consistently below `.medium`.
- Bar path visualization shows erratic jumps that don't correspond to real motion.

**Phase to address:**
Bar Path and Form Analysis phase, specifically in the "on-device tracking" milestone. Prototype the tracking approach with a real barbell video before designing the UI layer.

---

### Pitfall 3: Gemini Multimodal Video Incurs Surprise Costs via the Existing Proxy

**What goes wrong:**
The existing Cloudflare Worker proxy handles text prompts that are predictably short. A single Gemini multimodal video call for form analysis sends a video file that can be 20–100MB. The File API workflow (required for files over 20MB) requires a separate upload step before the inference call. Without per-user monthly caps enforced at the proxy layer, a single power user uploading every set of every workout could generate unbounded API costs that exceed the $19.99/month subscription revenue.

Gemini samples video at 1 FPS and processes audio at 1 Kbps. A 2-minute lifting set at 1 FPS = ~120 frames = significant token consumption. At current pricing, even Flash/Flash-Lite costs can accumulate quickly across a user base.

**Why it happens:**
Developers treat video analysis as a direct extension of the existing text prompt flow. The proxy was not designed for large binary uploads or usage quotas. Usage caps are planned as a product decision but implemented as a client-side UI gate — which can be bypassed or miscounted if the cap is not enforced server-side.

**How to avoid:**
- Enforce the monthly form check quota at the Cloudflare Worker level, not in the iOS client. The worker must track per-user call counts (via Cloudflare KV or D1) and return a 429 with `X-Form-Checks-Remaining` header before dispatching to Gemini.
- Use aggressive video compression before upload: target 720p max, 15 FPS cap (Gemini only samples at 1 FPS anyway, so higher FPS is pure waste), H.264 compression via `AVAssetExportSession`.
- Use the Gemini File API pattern: upload video to Google's temporary file storage, get a `fileUri`, pass the URI (not the bytes) in the inference request. This decouples upload latency from inference latency.
- Implement the iOS client's form check counter as read-only UI state fetched from the proxy response headers — never as the authoritative gate.

**Warning signs:**
- Monthly Gemini API bill increases faster than subscriber growth.
- Proxy response times spike during peak hours (buffering large video uploads).
- Client-side counter and server-side counter diverge after app force-quits during upload.

**Phase to address:**
Bar Path and Form Analysis phase — the monthly cap enforcement must be built into the proxy before the iOS feature launches. Do not ship the iOS feature with only a client-side cap.

---

### Pitfall 4: HKSample Non-Sendability Breaks Swift 6 Strict Concurrency

**What goes wrong:**
`HKSample` and related HealthKit types do not conform to `Sendable`. In Swift 6's strict concurrency mode (which this codebase uses), passing HealthKit query results from a query callback across actor isolation boundaries produces compiler errors. The existing `HealthKitReadinessRepository` is marked `@unchecked Sendable` as a workaround, but as the readiness scoring logic grows more complex — consuming HRV time series, sleep stage arrays, and resting heart rate trends — more query results flow between contexts, and `@unchecked Sendable` propagates technical debt throughout the auto-regulation layer.

**Why it happens:**
Apple has not yet retroactively adopted `Sendable` on HealthKit's Objective-C-rooted model types. Developers working in Swift 6 must either extract primitive values (Double, Date, Int) immediately in the query callback before crossing isolation boundaries, or suppress the warning with `@unchecked Sendable`.

**How to avoid:**
- Extract only primitive values from HealthKit samples within the query result handler. Never pass `HKSample`, `HKQuantitySample`, or `HKCategorySample` objects beyond their call site. Return `ReadinessMetrics` (pure Swift struct, already Sendable) immediately.
- The existing `fetchLatestMetrics()` pattern in `HealthKitReadinessRepository` is already correct for the current simple case. The risk is in the auto-regulation scoring extension: build `ReadinessScore` as a pure Domain type that accepts primitives only, keeping HealthKit types contained in the repository layer.
- Do not add `@unchecked Sendable` to new types. Each new repository method should return a domain value type, not a HealthKit type.
- Add a compile-time test: `let _: Sendable = ReadinessScore(...)` as a static assertion in test coverage.

**Warning signs:**
- New `@unchecked Sendable` conformances appearing outside `Repositories/HealthKit/`.
- Domain types gaining `import HealthKit` at the top of the file.
- Build warnings suppressed with `nonisolated(unsafe)` on HealthKit-related state.

**Phase to address:**
Readiness and Auto-Regulation phase — define the `ReadinessScore` domain type and its pure-Swift API before expanding the repository. The domain type is the firewall that prevents HealthKit leakage.

---

### Pitfall 5: Conversation History Grows Until Gemini Context Costs Explode

**What goes wrong:**
The conversational AI coach maintains a chat history to give the coach contextual memory. Developers naively append every turn to the `contents` array sent to Gemini. After 10–20 check-in sessions, a single weekly check-in request includes months of conversation history, consuming large portions of the context window, increasing per-call token cost, and introducing latency. This is the same proxy that serves AI workout generation — conversation bloat degrades performance for all features sharing the endpoint.

**Why it happens:**
Gemini does not maintain server-side session state between API calls. Maintaining context requires re-sending history each time. There is no automatic pruning — the developer must decide what history to include and when to truncate.

**How to avoid:**
- Design the conversation storage layer with a fixed context window budget (e.g., 20,000 tokens max for history). Implement a "rolling window" strategy: always include the system prompt, the 3 most recent full turns, and a compressed summary of older sessions.
- Build a `ConversationSummarizer` in the Domain layer that collapses older history into a short paragraph ("User trained 4x last week, PRed squat, reported hip soreness") before appending to requests.
- Store the full conversation in SwiftData (for user access to history) but send only the trimmed context window to the proxy.
- Add a token estimation utility (character count / 4 is a rough proxy for tokens) that warns when a request approaches the budget before dispatch.

**Warning signs:**
- API response latency increases over time for the same user.
- First weekly check-in is fast; check-in #15 is slow.
- Users who've been on the app longer report "AI coach feels slower than when I first started."

**Phase to address:**
Conversational AI Coach phase — design the `ConversationStore` with trimming as a first-class concern before building the UI. Retrofitting context management after launch causes data migration complexity.

---

### Pitfall 6: AVSpeechSynthesizer Cannot Stream LLM Output Token-by-Token

**What goes wrong:**
The voice coach experience feels unnatural if the app waits for the complete Gemini response before speaking. Developers implement streaming Gemini responses to get token-by-token output, then try to feed partial text to `AVSpeechSynthesizer` for low-latency speech. This does not work: `AVSpeechSynthesizer` requires complete utterances and cannot process partial or streaming text. The result is either a silent pause while waiting for the full response, or choppy sentence-fragment speech from feeding utterances too early.

**Why it happens:**
LLM streaming and TTS streaming are both desirable features independently. The assumption is they compose naturally — they do not with iOS's native TTS API.

**How to avoid:**
- Implement sentence-boundary detection on the streaming token buffer: accumulate tokens and emit an `AVSpeechUtterance` when a sentence-terminating character (`.`, `?`, `!`) is followed by whitespace. This gives a first-speech latency equal to the time to generate the first sentence (~1–2 seconds), which is acceptable.
- Queue multiple utterances: `AVSpeechSynthesizer` supports a queue, so sentences 2, 3, 4 can be enqueued as they arrive, producing smooth continuous speech from sentence-chunked streaming.
- Note: iOS 26 introduces `SpeechAnalyzer` with improved on-device processing, but it targets speech-to-text, not text-to-speech. The sentence-chunking approach remains the correct pattern for TTS regardless of iOS version.
- Configure voice selection before each session and cache the result — voice lookup has measurable overhead if called per-utterance.

**Warning signs:**
- Voice coach goes silent for 3–8 seconds after user finishes speaking.
- Speech sounds like individual sentences with audible gaps between them (utterances queued at wrong granularity).
- Profiling shows `AVSpeechSynthesizer.speak()` called hundreds of times per response.

**Phase to address:**
Conversational AI Coach with Voice phase — prototype the streaming-to-TTS pipeline in isolation before connecting it to the Gemini proxy. This is a non-obvious integration that needs a standalone spike.

---

### Pitfall 7: Predictive PR Model Appears to Work but Has No Statistical Validity

**What goes wrong:**
e1RM trend forecasting is implemented by fitting a line through historical max attempts and extrapolating forward. The feature ships and looks polished — smooth curves, confidence bands — but the predictions are statistically meaningless for most users because:
1. The training data is sparse (most users have fewer than 10 max attempts per lift over months).
2. A linear trend ignores known strength periodization patterns (accumulation → peak → deload → adaptation cycle).
3. Confidence intervals are never shown, so users treat projections as commitments rather than estimates.

**Why it happens:**
Implementing curve fitting is easy (use Accelerate framework or a simple least-squares calculation in Domain). The hard part is communicating uncertainty honestly and handling the edge cases of sparse data gracefully.

**How to avoid:**
- Define a minimum data threshold: require at least 5 data points before showing a forecast line. Below threshold, show "Not enough data yet — keep logging maxes."
- Display confidence intervals on all projections. Use the residual standard error from the regression to compute ±N lb bands that widen as the forecast extends further into the future.
- Use the Epley or Brzycki formula family for the base e1RM calculation (already in the codebase for max tracking) rather than raw logged maxes, which reduces noise from day-to-day variation.
- Explicitly label the forecast as "estimated potential" not "will achieve." Copy matters here — users should understand they are seeing a model output, not a guarantee.
- The Accelerate framework (`cblas_`, `vDSP_`) handles regression calculations on-device with no dependencies, keeping this in the Domain layer with 100% testability.

**Warning signs:**
- Forecast lines extrapolate to physiologically impossible values (500 lb bench in 6 weeks from a 135 lb baseline).
- Users post to social media about "my PR prediction was completely wrong."
- Tests only verify that the curve renders, not that the underlying regression values are correct.

**Phase to address:**
Predictive PR Forecasting phase — define the statistical model and its validity constraints in the Domain layer with unit tests before building any visualization. The chart is easy; the math that must be right is in Domain.

---

### Pitfall 8: Test Coverage Cannot Reach 100% on Camera and Vision Code Without Architecture Planning

**What goes wrong:**
The project enforces 100% line coverage in CI. AVCaptureSession, Vision framework requests, and physical device sensors are fundamentally untestable in the XCTest simulator environment without dependency injection seams. Developers who write camera and Vision code directly in ViewModels or Feature views hit a wall: the CI pipeline fails because the uncoverable branches (camera not available, permission denied, Vision request failure) are impossible to exercise in the simulator.

**Why it happens:**
The Vision and AVFoundation APIs use hardware-backed implementations that are not available in XCTest. The project's 100% coverage rule is non-negotiable, so any code path that calls `AVCaptureDevice.default(...)` or `VNImageRequestHandler.perform(...)` directly is untestable.

**How to avoid:**
- Define protocol abstractions at the hardware boundary for every new framework:
  - `BarPathTrackerProtocol` wrapping Vision requests
  - `CameraSessionProtocol` wrapping AVCaptureSession
  - `SpeechRecognizerProtocol` wrapping SFSpeechRecognizer
  - `SpeechSynthesizerProtocol` wrapping AVSpeechSynthesizer
- Concrete implementations (e.g., `LiveBarPathTracker`) live in `Services/` and are excluded from coverage requirements via `// coverage:ignore` or a separate build target, following the same pattern that should apply to SwiftData context boilerplate.
- All business logic (tracking decisions, form coaching triggers, voice session state machine) lives in pure Domain types tested against mock implementations of the protocols.
- The CI coverage gate applies to `Domain/`, `Repositories/Protocols/`, and `Features/` ViewModels only. The `Services/` hardware adapters are marked excluded from coverage.

**Warning signs:**
- CI fails with "line X: AVCaptureDevice.default never executed in tests."
- ViewModel contains `import Vision` or `import AVFoundation` at the top.
- A `BarPathViewModel` is unit tested against a real `VNDetectHumanBodyPoseRequest` — this will pass locally but fail in CI.

**Phase to address:**
First implementation phase for both Bar Path Analysis and Conversational Voice — define the protocol seams before writing any implementation code. Every new hardware-touching feature needs its protocol defined first.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Storing full video frames in SwiftData for bar path replay | Simplest persistence approach | SwiftData/CloudKit will reject large binary blobs; CloudKit has a 1MB record limit | Never — store video in app sandbox as `.mp4`, store only file URL in SwiftData |
| Client-side-only form check quota counter | No Cloudflare worker changes needed | Counter resets on app reinstall; power users exploit it; impossible to audit | Never for quota enforcement |
| `@unchecked Sendable` on new HealthKit-wrapping types | Silences Swift 6 concurrency errors | Tech debt accumulates; breaks when types are used across new actors | Acceptable only in `Repositories/HealthKit/` for direct HKStore wrappers; never in Domain |
| Appending full conversation history to every Gemini request | Simplest way to maintain context | Token costs grow unbounded; latency degrades for long-term users | Never — implement rolling window from day one |
| Using `VNDetectHumanBodyPoseRequest` with `.low` confidence results | More observations returned | Bar path visualization shows phantom movement; coaching cues become incorrect | Never — filter to `.medium` or higher minimum |
| AVSpeechSynthesizer with full response text | Simplest TTS implementation | 3–8 second silence while waiting for full LLM response; bad UX | Acceptable for initial prototype/demo only; not for production ship |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Apple Vision + AVCaptureSession | Run `VNImageRequestHandler` on the main thread to access `@Observable` state | Run all Vision requests on a dedicated serial `DispatchQueue`; publish results back to `@MainActor` via `Task { await MainActor.run { ... } }` |
| SFSpeechRecognizer | Rely on system to restore AVAudioSession after recognition ends | Explicitly call `audioEngine.stop()`, `recognitionRequest.endAudio()`, and `audioSession.setActive(false)` in sequence in `stopRecording()` |
| Gemini multimodal video | Send video bytes inline in the request body through the proxy | Use the Gemini File API: upload video → get fileUri → send fileUri in inference request; update the Cloudflare Worker to proxy the upload separately |
| HealthKit on iOS Simulator | Assume authorization returns `.authorized` in tests | `HKHealthStore.isHealthDataAvailable()` returns `false` in Simulator; mock the repository using `ReadinessRepository` protocol |
| StoreKit 2 fourth tier | Use `Transaction.currentEntitlements` to check only the new elite product | Filter `.currentEntitlements` to the entire subscription group, then pick the highest active tier — multiple simultaneous entitlements are possible during upgrades/downgrades |
| SwiftData + video file URLs | Store `URL` directly as a SwiftData property with CloudKit enabled | Store the file path as `String` (URLs are not CloudKit-compatible); convert to `URL` in computed property; store the actual file in the local sandbox, not in SwiftData |
| Gemini conversation history | Store `ChatMessage` objects in SwiftData with a `Data`-encoded history blob | Use a dedicated `ConversationSession` SwiftData model with individual `ConversationTurn` child records for queryability and migration safety |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Vision requests on every captured frame | CPU/thermal throttling after 30 seconds of recording; battery drain complaint | Process every 3rd–5th frame for body pose; use `VNTrackObjectRequest` (cheaper) for frame-to-frame bar path; drop frames when processing queue depth > 2 | Immediately on older devices; ~30–60 seconds on A16+ |
| SwiftData `@Query` with history + new form analysis records in same fetch | History tab becomes sluggish as form analysis records accumulate | Add a `FormAnalysisRecord` model with a separate fetch predicate; never include it in the unified history `@Query` | ~50+ form analysis records |
| Loading full conversation history for UI display and for API context simultaneously | Redundant SwiftData fetch; stutter when opening coach tab | Separate the display model (all turns, for history view) from the API context model (trimmed window, for proxy calls); fetch them independently | ~20+ conversation sessions |
| Body heatmap recomputing muscle groups on every workout history change | Dashboard stutters when new workout is logged | Memoize heatmap computation with a `lastComputedAt` timestamp in the Domain; only recompute when newer workouts exist | ~100+ workouts in history |
| SFSpeechRecognizer holding audio engine open between sentences | Battery drain during long voice coach sessions | Implement push-to-talk or VAD (voice activity detection) stop trigger rather than leaving the audio engine open for the full session | Continuous — even 2 minutes of open mic drains battery |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing Gemini file upload tokens or temporary file URIs in SwiftData | Credentials in iCloud backup via CloudKit private DB sync | Store upload tokens only in-memory for the duration of the upload + inference call; never persist them |
| Logging conversation content to Observability/analytics without scrubbing | Health and fitness conversation data (injuries, cycle phase, form issues) is sensitive; App Store privacy label violations | Ensure `Observability/` layer never logs message content; log only event types (e.g., `coach_session_started`, `form_check_submitted`) |
| Requesting microphone permission during bar path video recording when audio is not needed | Unnecessary permission request; app review may question it | For bar path analysis, disable audio track in `AVCaptureSession` (`AVCaptureDevice.default(.builtInMicrophone)` not added as input); only request microphone for voice coach feature |
| Sending raw user conversation text through the proxy without sanitization | Prompt injection via user-typed coach questions; potential for model abuse | The Cloudflare Worker should validate request structure; the system prompt in the proxy is fixed and not user-modifiable |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing form analysis results while the user is still resting between sets | Overwhelming mid-workout; user ignores it | Deliver form analysis as a card in the rest timer view; present it when the rest timer starts, not when video processing finishes |
| Travel Mode requiring the user to manually select "Travel Mode" per workout | Users forget; get barbell workouts they can't do | Auto-suggest Travel Mode when the app detects a known travel gym equipment profile is active, or when GPS city differs from home city (if location permission granted) |
| Voice coach speaking during a set | Distracting; potentially dangerous (feedback loop on cues) | Gate TTS output on set completion; voice coach only speaks during rest periods or when explicitly summoned |
| PR forecast showing exact numbers without uncertainty bands | Users treat model output as a commitment; disappointment when not achieved | Always show forecast as a range (e.g., "315–335 lb in 8 weeks") not a point estimate |
| Readiness score auto-reducing workout volume without explanation | User feels the app "broke" their planned workout | Always show the readiness score with a one-sentence explanation ("HRV is 18% below your baseline — volume reduced by 20% today") before the workout starts |

---

## "Looks Done But Isn't" Checklist

- [ ] **Bar path tracking:** Feature works in demo video — verify it works with a real person, barbell, and gym lighting on the oldest supported device.
- [ ] **Form check quota:** Client shows "3 form checks remaining" — verify the Cloudflare Worker enforces the cap, not just the iOS UI.
- [ ] **Voice coach audio routing:** TTS works in simulator — verify on device with AirPods, earpiece, and speaker, and immediately after a bar path recording session.
- [ ] **Readiness auto-regulation:** Volume scaling applies to AI-generated workouts — verify it also applies to program workouts and travel mode workouts.
- [ ] **PR forecast:** Chart renders correctly — verify that the underlying Domain regression returns statistically valid results for sparse data (2 data points, 3 data points, data with a gap).
- [ ] **Conversation history:** Check-in #1 works — verify check-in #20 has acceptable latency and token count (instrument a test with 20 synthetic sessions).
- [ ] **StoreKit elite tier:** Elite features are gated in UI — verify that downgrade from Elite to Pro immediately revokes access in the same session (test in StoreKit sandbox environment).
- [ ] **Vision protocol seams:** All Vision code is tested — verify by running CI in a Simulator-only build; zero `.allow_untested` suppressions in Vision-related coverage files.
- [ ] **HealthKit nil handling:** Readiness score shows when all data is available — verify behavior when user has no Apple Watch (all HealthKit values nil), when permission is revoked mid-session, and when only some metrics are available.
- [ ] **Travel Mode equipment profile:** Workout adapts to "hotel gym" profile — verify the exercise substitution engine correctly handles the case where no barbell is available AND no dumbbells are available (bodyweight-only fallback).

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Client-side quota enforcement shipped to production | HIGH | Hotfix the Cloudflare Worker to add server-side enforcement; add a migration to reconcile existing over-quota users; communicate change to users transparently |
| AVAudioSession routing bug discovered post-launch | MEDIUM | Ship a focused audio session fix; the `VoiceSessionManager` refactor is isolated enough to patch without touching the full voice coach |
| Conversation history bloat causing latency regression | MEDIUM | Add context window trimming retroactively; existing `ConversationTurn` records in SwiftData are preserved, only the API call behavior changes |
| Vision tracking fails for large percentage of users (low-light gym) | HIGH | Implement the pre-recording quality check UI as an urgent update; add "poor tracking" graceful degradation path that still submits the video to Gemini for analysis even when on-device tracking confidence is low |
| PR forecast producing absurd extrapolations in production | MEDIUM | Add minimum data threshold and confidence interval rendering in a patch; the Domain layer changes are isolated and testable |
| 100% coverage CI failure due to uncovered Vision/AVFoundation code | MEDIUM | Define protocol seams retroactively and move untestable code to `Services/` with coverage exclusion; any existing direct Vision calls in ViewModels must be refactored out |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AVAudioSession routing (voice + video) | Conversational AI Coach — audio architecture spike | Device test: TTS audible immediately after recording session ends |
| Vision tracking in gym conditions | Bar Path Analysis — tracking prototype spike | Test video corpus including low-light, dark clothing, partially visible barbell |
| Gemini video cost controls | Bar Path Analysis — proxy quota enforcement | Cloudflare Worker returns 429 after N calls; iOS client reads `X-Form-Checks-Remaining` header |
| HKSample non-Sendability | Readiness Auto-Regulation — domain type definition | `ReadinessScore` struct has no HealthKit imports; compiles with Swift 6 strict concurrency with zero suppressions |
| Conversation history token bloat | Conversational AI Coach — ConversationStore design | Synthetic 20-session test: final request token count stays below 20,000 |
| AVSpeechSynthesizer streaming | Conversational AI Coach — voice pipeline spike | First spoken word delivered within 2 seconds of Gemini response start |
| PR model statistical validity | Predictive Analytics — Domain model | Unit tests: sparse data (2 points) returns nil/insufficient-data; extrapolation stays within physiological bounds |
| 100% coverage with Vision/AVFoundation | Bar Path Analysis AND Voice Coach — protocol definitions | CI passes with zero `@unchecked Sendable` on non-HealthKit types and zero coverage suppressions in ViewModels |
| StoreKit fourth tier entitlement | Elite subscription tier — StoreKit integration | Sandbox downgrade test: Elite features inaccessible immediately after downgrade confirmed |
| Travel Mode exercise substitution | Travel Mode phase — substitution engine | Unit test: null equipment set produces bodyweight-only workout with no crashes |

---

## Sources

- Apple Developer Documentation: [AVAudioSession](https://developer.apple.com/documentation/AVFAudio/AVAudioSession), [VNDetectHumanBodyPoseRequest](https://developer.apple.com/documentation/vision/vndetecthumanbodyposerequest), [HealthKit](https://developer.apple.com/documentation/healthkit)
- Gemini API official docs: [Video understanding](https://ai.google.dev/gemini-api/docs/video-understanding), [Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions)
- WWDC25: [Bring advanced speech-to-text to your app with SpeechAnalyzer](https://developer.apple.com/videos/play/wwdc2025/277/)
- Community: [Haptic feedback and AVAudioSession conflicts](https://medium.com/@mi9nxi/haptic-feedback-and-avaudiosession-conflicts-in-ios-troubleshooting-recording-issues-666fae35bfc6)
- Community: [Avoiding the Hidden Hazards: ML on iOS pitfalls](https://ksemianov.github.io/articles/ios-ml/)
- Community: [Real-time object detection with Vision + SwiftUI](https://medium.com/@authfy/real-time-object-detection-in-ios-using-vision-framework-and-swiftui-e77b1523b5fe)
- StoreKit: [iOS subscription upgrades, downgrades, and service levels](https://qonversion.io/blog/ios-subscription-upgrades-downgrades-and-service-levels/)
- Fatbobman: [Key considerations before using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/)
- Swift forums: [Swift 6 migration issues with HealthKit](https://developer.apple.com/forums/thread/763998)
- AVSpeechSynthesizer streaming limitation: [iOS Real-Time TTS: Streaming Text-to-Speech Tutorial](https://picovoice.ai/blog/ios-streaming-text-to-speech/)

---
*Pitfalls research for: Sundee Fundee v1.0 Elite Tier — iOS fitness app with AI coaching, computer vision, biometric integration, and voice UI*
*Researched: 2026-03-14*
