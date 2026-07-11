# Sundee Fundee 2.0 Training Intelligence Design

**Date:** 2026-07-11
**Status:** Approved for implementation planning
**Target:** Major 2.0 platform release over approximately 14 weeks

## Goal

Make Sundee Fundee 2.0 a coherent training-intelligence suite that helps users make better daily workout decisions, train more consistently, and perceive substantially more value from the app.

The release succeeds through a product chain:

1. Better readiness and training decisions.
2. More consistent workout completion and return behavior.
3. Stronger usefulness feedback, reviews, and word of mouth.

## Current-State Grounding

The app is currently version 1.7.3. The June 2026 20-item quality and personalization program is complete and verified, including dark mode, accessibility, Coach Plan feedback, workout trust badges, context-aware quick workouts, same-day preferences, post-workout check-ins, progressive onboarding, progress guidance, widget deep links, and release gates.

The codebase already contains useful pieces for 2.0:

- HealthKit access for sleep, HRV, resting heart rate, workouts, active energy, and menstrual-cycle samples.
- Cycle, symptom, pain, workout-history, training-load, program, preference, and workout-feedback models.
- Deterministic coach, pain-substitution, program-adaptation, deload, active-recovery, and explanation services.
- `WorkoutAdaptationDecisionRecord`, `SymptomCheckInRecord`, `DailyPainLog`, `WorkoutCompletionCheckInRecord`, and `TodayWorkoutPreferenceRecord` persistence.
- Share cards, challenge invites, and buddy check-ins.
- A dormant `SyncQueue` that is not yet wired into `DataClientFactory`.

The former numeric Recovery Score was deliberately removed in June 2026. Version 2.0 must not restore that legacy design or its fixed cycle-phase penalties. It introduces a new readiness model with personal baselines, confidence, signal provenance, explicit safety constraints, and a distinct record type.

## Approved Product Decisions

- Build a major platform release rather than a narrowly focused feature release.
- Optimize better decisions, retention, and perceived value together.
- Lead with a plain-language readiness state and make a personalized 0–100 score available underneath.
- Use the maximum practical signal set: HealthKit, cycle context, symptoms, pain, subjective check-ins, recent workload, program state, and workout outcomes.
- Apply bounded workout adaptations automatically, then explain them and allow restoration of the original workout.
- Support a hybrid training model: preserve structured programs when active and generate intelligent standalone workouts otherwise.
- Treat social features as a privacy-safe supporting layer rather than a social network.
- Use one unified intelligence core so Today, workouts, programs, and progress cannot produce conflicting guidance.

## Product Scope

### 1. Readiness Intelligence

The primary daily state is one of:

- **Ready:** follow the planned training dose.
- **Maintain:** train productively with minor fatigue management.
- **Recover:** use a materially reduced or recovery-oriented dose.
- **Rest:** remove loaded training and offer optional gentle recovery guidance.

The Today surface leads with the state, confidence, and next action. The detailed view includes the 0–100 score, signal freshness, available and missing inputs, positive and caution drivers, and the reason for the recommendation.

Cycle phase is contextual information, not an automatic readiness penalty. Actual symptoms and personal response patterns may influence the assessment. Phase alone must not lower the score or state.

### 2. Adaptive Workouts

The system may adjust:

- working-set volume;
- prescribed intensity;
- exercise selection;
- rest intervals;
- warm-up dose;
- active-recovery programming.

Every adaptation must preserve the session's purpose where safe, remain within the state-specific bounds, include structured reasons, present a concise before-and-after summary, and retain enough information to restore the original workout.

### 3. Program Intelligence

An active structured program remains the long-term source of progression. The intelligence layer may adapt today's session, reshuffle missed sessions, distinguish planned deloads from reactive recovery recommendations, and support return-to-training ramps. It must not silently rewrite the program's progression model.

When no program is active, the same context and decision packet drive the best standalone Coach Plan.

### 4. Progress Intelligence

Progress connects readiness, adaptations, adherence, effort, and performance. Monthly reviews and trend views surface useful associations and next actions without claiming medical causation.

The product emphasizes actionable answers such as “what should I do next?” over adding charts for their own sake.

### 5. Privacy-Safe Social Support

Social sharing covers achievements, program milestones, monthly reviews, and optional buddy check-ins. Sensitive HealthKit inputs, pain data, cycle data, and readiness drivers remain private unless a user explicitly chooses a safe derived statement to share.

Version 2.0 does not add public profiles, a social feed, direct messaging, or a friend graph.

## Unified Architecture

### Signal Layer

The daily context may contain:

- sleep duration and freshness;
- HRV relative to a personal rolling baseline;
- resting heart rate relative to a personal rolling baseline;
- subjective energy, fatigue, soreness, stress, and perceived readiness;
- pain intensity, type, and affected body regions;
- cycle phase and phase confidence;
- current symptoms;
- recent training load, effort, completion, and missed sessions;
- active program position and scheduled session;
- available time, equipment, goals, and learned preferences.

Each input carries availability, source, observation date, freshness, and normalization status. Missing values remain unknown rather than receiving a poor default.

### `DailyTrainingContextBuilder`

This I/O-facing component gathers independent data concurrently from `HealthClientProtocol`, `DataClientProtocol`, local cache, and existing domain services. It produces a framework-light `DailyTrainingContext` value for the pure domain layer.

The builder owns source resolution and freshness. It does not score readiness or mutate workouts.

### `ReadinessAssessmentService`

This pure service consumes `DailyTrainingContext` and produces:

- readiness state;
- detailed score from 0 through 100;
- confidence level;
- available, missing, and stale signal summaries;
- normalized sub-scores;
- structured positive and caution reason codes;
- scoring-model version.

The initial model version uses four transparent score groups:

- physiological recovery: 30% from available sleep, HRV, and resting-heart-rate signals;
- subjective readiness: 30% from energy, fatigue, stress, soreness, and perceived readiness;
- training load and response: 25% from recent load, effort, completion feedback, and missed sessions;
- symptoms and pain: 15% from current symptoms and explicit pain reporting.

Cycle phase has no direct score weight. It changes explanations and may help interpret personal trends, but only reported symptoms or observed individual response contribute numerically.

Missing groups are excluded from the weighted mean rather than scored as zero. Confidence reflects coverage: high confidence requires at least 75% of weighted inputs plus both a physiological and subjective signal; medium confidence covers 45–74%; low confidence covers less than 45% or lacks either signal family.

Population-wide thresholds are initial calibration aids only. A HealthKit signal switches to a personal baseline after at least 14 valid daily observations within the previous 28 days. Training-load and response baselines require at least four completed workouts. Until those minimums are met, the UI labels the assessment as still learning and confidence cannot exceed medium.

### `TrainingDecisionService`

This pure service combines the assessment with the planned or generated workout. It produces a `TrainingDecisionPacket` containing:

- the original prescription;
- the adapted prescription;
- readiness state, score, and confidence;
- volume, intensity, exercise, rest, and warm-up changes;
- safety cautions and structured reasons;
- whether active recovery or rest is recommended;
- restoration data for the original session.

Deterministic services remain the only authority for safety, pain substitutions, progression, deloads, and session adaptation. On-device generated copy may explain a completed decision packet but may not change it.

### `TrainingInsightService`

This pure aggregation service combines historical assessments, workout outcomes, adaptations, and adherence into readiness-to-performance trends and monthly-review insights. It reports associations and next actions, not diagnoses or causal conclusions.

## Data Model and Persistence

### `DailyReadinessRecord`

Create a new record type rather than reusing the deleted `RecoveryScoreRecord`. It stores the derived assessment, not raw health samples.

Required fields include:

- stable `id` in the form `readiness-<local-day-key>`, scoped to the current private or local data store so guest migration does not change the identifier;
- `dayKey` and `timeZoneIdentifier` captured when that day's assessment is first created;
- `assessmentDate` encoded as an ISO8601 string;
- `dateCreated` encoded as an ISO8601 string;
- `dateUpdated` encoded as an ISO8601 string;
- `stateRaw`;
- integer `totalScore`;
- `confidenceRaw`;
- scoring `modelVersion`;
- available, missing, and stale input identifiers;
- sub-score values;
- positive and caution reason identifiers;
- source-freshness metadata sufficient to explain the assessment.

The name avoids CloudKit-reserved fields. The new record type requires a queryable record-identifier index in Development and Production.

### Subjective Check-In

Extend `SymptomCheckInRecord` with backward-compatible optional fields for stress and perceived readiness. Continue using its existing fatigue, soreness, energy, and cramps fields. Create a `DailyPainLog` only when the user reports localized pain. This avoids a parallel all-purpose check-in record while supporting the maximum-signal daily flow.

New optional fields must decode safely when absent from older records. CloudKit schema changes and round-trip coverage are part of the implementation plan.

### Existing Records

Reuse the following records as sources rather than duplicating their information:

- `DailyPainLog`;
- `SymptomCheckInRecord`;
- `WorkoutCompletionCheckInRecord`;
- `TodayWorkoutPreferenceRecord`;
- `WorkoutAdaptationDecisionRecord`;
- workout, program, cycle, and user-settings records.

### Storage Rules

- Raw HealthKit samples remain in HealthKit and are never copied into CloudKit.
- Only derived daily assessments and existing user-entered records are persisted.
- Guest users use `LocalDataClient`; signed-in users use CloudKit with the same domain behavior.
- A stable local-day identifier prevents duplicate daily assessments. Travel across a date boundary may create a new local-day record, which is intentional.
- New input arriving later in the day recomputes and replaces that day's assessment.
- Historical records retain their original score and model version. Trend UI marks model-version boundaries instead of silently recalculating history.

## Readiness and Adaptation Policy

The numerical bands are summaries. Deterministic pain and safety cautions may cap the resulting state regardless of score.

| State | Score | Allowed automatic behavior |
|---|---:|---|
| Ready | 80–100 | Follow planned dose. Readiness never adds work beyond ordinary progression rules. |
| Maintain | 60–79 | Preserve session purpose; reduce volume by at most 20% or prescribed intensity by at most 10% relative to the original prescription. |
| Recover | 35–59 | Reduce volume by 30–50% and prescribed intensity by 10–20% relative to the original prescription; use safer substitutions, extend rest, or offer active recovery. |
| Rest | 0–34 | Remove loaded training and offer optional gentle recovery guidance without medical language. |

Additional rules:

- Low confidence limits automatic behavior to Maintain bounds, cannot create a score-only Rest state, and prompts for a manual check-in. Explicit pain-safety rules may still impose a stricter cap.
- Cycle phase alone cannot reduce readiness.
- High pain invokes existing pain-aware substitution and return-to-lifting policies regardless of score.
- A single difficult day may adapt one session but cannot trigger a program-wide deload.
- Reactive deloads require caution evidence on at least three of the previous seven days across at least two independent signal families. Explicit pain-safety conditions may act sooner.
- Planned program deloads remain distinct from reactive recovery recommendations.
- Every change must have reason codes and an undo path.
- Readiness cannot increase training beyond the active program's progression policy in 2.0.

## Primary User Journey

1. Today immediately renders the cached assessment, including its age.
2. Fresh HealthKit, check-in, cycle, pain, load, and program inputs refresh concurrently.
3. The user sees a plain-language state, confidence, top drivers, and best next action.
4. The detailed score and full breakdown remain one level deeper.
5. If a workout is planned, the app shows the adapted session and concise reasons.
6. The user starts the adapted workout or restores the original.
7. Completion offers an optional sub-15-second effort, pain, soreness, and “right for today” check-in.
8. The result becomes a future baseline and progress input. One-off edits stay temporary; repeated patterns may become learned preferences.

## Reliability and Error Handling

### Permission and Signal Failures

- HealthKit denial or unavailability falls back to manual check-ins, cycle context, pain, symptoms, and training history.
- Missing or stale signals lower confidence and remain visible in the explanation.
- Unknown values never become negative scores.
- Permission prompts occur at the point of value and never block training.

### Offline Behavior

- Cache the most recent context snapshot and readiness assessment locally.
- Render the cached assessment immediately with a freshness label.
- Save new check-ins and assessments locally first when connectivity is unavailable.
- Activate the existing `SyncQueue` first for readiness assessment and check-in mutations.
- Expand queue coverage beyond the 2.0 path only after focused reliability tests pass.

### Data and Decision Failures

- Preserve existing resilient record decoding and diagnostics counting.
- A malformed individual record is skipped while the assessment continues with lower confidence.
- If no valid decision packet can be produced, preserve the original workout and show available cautions rather than guessing.
- User-facing errors provide an action and never expose raw `localizedDescription` text.
- A sync failure does not discard the locally calculated plan or check-in.

## Privacy and Trust Contract

- No raw HealthKit samples are persisted outside HealthKit.
- No raw health, cycle, pain, or generated-copy content enters growth analytics or social payloads.
- Readiness is framed as training guidance, not a medical assessment.
- Users can inspect contributing inputs, confidence, and model version.
- Users can restore every automatically adapted session.
- Sensitive sharing defaults to off and requires an explicit choice.
- Account deletion and export must include the new derived records and new optional check-in fields.

## Verification Strategy

### Domain and Invariant Tests

Cover scoring, personal baselines, freshness, confidence, reason codes, readiness bands, deload detection, adaptation limits, and model versions.

Permanent invariants include:

- missing data cannot lower readiness by itself;
- cycle phase alone cannot lower readiness;
- readiness cannot exceed normal program progression;
- adaptations cannot cross their state-specific bounds;
- every mutation has a reason and restoration path.

### Scenario Fixtures

Include no HealthKit access, sparse history, irregular cycles, high soreness, elevated pain, poor sleep, missed workouts, planned deloads, reactive deloads, guest mode, offline mode, and return after time away.

### Persistence and Integration Tests

Verify LocalDataClient and CloudKit-compatible round trips, ISO8601 dates, stable identifiers, duplicate prevention, optional-field decoding, sync retry, conflict resolution, queue restoration after relaunch, and isolation from legacy recovery records.

Run the project-local `cloudkit-validate` skill against all changed record models before schema deployment.

### View-Model and UI Tests

Verify cached-first loading, refresh, recomputation, confidence changes, preview, restore-original behavior, actionable errors, dark and light mode, large Dynamic Type, VoiceOver explanations, HealthKit denial, offline state, and adapted-workout comparisons.

### End-to-End Flow

The release gate must cover:

`morning assessment → explanation → adapted program session → workout completion → optional feedback → updated progress insight`

Context reads run concurrently, calculations stay off the main thread, and Today renders cached content before refresh completes.

## Delivery Roadmap

### Weeks 1–2: Foundation and Shadow Assessment

Build the context, assessment, confidence, reason-code, persistence, cache, and scenario-test foundations. Run the assessment against fixtures and internal data without changing workouts.

**Gate:** invariants and scenario suites pass; no user-visible adaptation is enabled.

### Weeks 3–5: Daily Readiness Experience

Build the Today state and score, full breakdown, maximum-signal check-in, HealthKit integration, missing-data states, local cache, history, and refreshed readiness widget.

**Gate:** guest, denied, sparse, offline, stale, and high-confidence flows are verified.

### Weeks 6–9: Bounded Adaptive Training

Build decision packets, program-aware session changes, deload and active-recovery policy, preview, reasons, restore-original behavior, and completion feedback.

**Gate:** every adaptation remains within bounds, has structured reasons, and is reversible.

### Weeks 10–12: Program, Progress, and Social Intelligence

Build missed-session reshuffling, planned-versus-reactive deload behavior, readiness-to-performance insights, monthly-review improvements, milestones, and privacy-safe share variants.

**Gate:** long-term program intent remains intact across daily adaptations.

### Weeks 13–14: Reliability and Release Hardening

Complete focused SyncQueue activation, CloudKit deployment, migration checks, accessibility, performance, privacy audit, simulator journeys, release notes, rollback documentation, and the final release gate.

**Gate:** the full release gate passes. Building for upload, uploading, TestFlight distribution, or App Store submission still requires explicit user authorization.

## Success Measures

### Better Decisions

- At least 75% of completed adapted sessions are rated “right for today.”
- No known adaptation exceeds its deterministic bounds.
- Restore-original rates and negative feedback are reviewed by readiness state and confidence level during an explicitly authorized beta.

### Better Retention

- Target a 10% relative lift in second-week workout completion compared with the 1.7 baseline.
- Target a 10% relative lift in four-week returning trainers compared with the 1.7 baseline.
- Use App Store analytics and privacy-safe existing growth events; do not introduce sensitive analytics payloads.

### Stronger Perceived Value

- At least 70% positive usefulness feedback for readiness explanations and Coach Plans during an explicitly authorized beta.
- Maintain or improve store rating and qualitative sentiment after release.
- Track which product explanations users find useful without recording the underlying health or cycle content.

## Scope Decomposition

This is a coordinated release program, not a single implementation batch. Implementation planning must preserve the five roadmap gates and divide work into independently testable vertical slices. The first executable slice is the readiness foundation and shadow assessment. Later slices may not bypass an earlier gate to expose automatic workout behavior sooner.

## Out of Scope

- Paywalls, subscriptions, or paid feature gates.
- Medical diagnosis or claims that readiness replaces professional advice.
- AI-generated safety, progression, deload, pain, or adaptation decisions.
- External package dependencies or non-CloudKit backends.
- Public profiles, public activity feeds, direct messaging, or a friend graph.
- Automatic training increases beyond existing progression policy.
- A wholesale redesign of the four-tab information architecture.
- App Store upload or submission without explicit authorization.

## Release Acceptance Criteria

- Today presents a clear readiness state, detailed score, confidence, freshness, drivers, and next action.
- The experience remains useful with HealthKit denied, no cycle tracking, sparse history, guest mode, and offline mode.
- Missing data never becomes a negative readiness input.
- Cycle phase alone never lowers readiness.
- Every automatic adaptation stays within approved bounds, is explained, and can be reversed.
- Active programs preserve their long-term progression intent.
- Planned deloads and reactive recovery recommendations remain distinguishable.
- Progress insights avoid causal or medical claims.
- Social outputs exclude sensitive inputs by default.
- New records satisfy CloudKit naming, date, index, and backward-decoding requirements.
- Domain, persistence, view-model, UI, accessibility, privacy, performance, and end-to-end release gates pass.

## Principal Risks and Mitigations

| Risk | Mitigation |
|---|---|
| False precision from a 0–100 score | Lead with state and confidence; expose provenance; use personal baselines; treat score as detail rather than the primary instruction. |
| Conflicting advice across surfaces | Require every consumer to use the same `TrainingDecisionPacket`. |
| Cycle stereotypes reduce trust | Prohibit phase-only penalties; use symptoms and personal patterns. |
| Sparse or denied HealthKit data | Use explicit missingness, confidence, manual inputs, and graceful fallback. |
| Automatic changes feel controlling | Explain changes, preserve session intent, and provide one-step restoration. |
| Program progression becomes unstable | Cap readiness behavior and prohibit increases beyond program progression policy. |
| Offline writes are lost | Cache locally and activate `SyncQueue` for the focused readiness path. |
| Scoring changes invalidate history | Persist model version and mark boundaries rather than rewriting old assessments. |
| Sensitive data leaks through sharing or analytics | Store only derived assessments, audit payloads, and default sensitive sharing off. |
| Fourteen-week scope becomes unmanageable | Enforce vertical slices and phase gates; do not expose adaptation before the foundation passes. |
