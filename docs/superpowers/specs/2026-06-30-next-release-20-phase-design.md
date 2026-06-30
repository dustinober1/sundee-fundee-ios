# Next Release 20-Item Phase Design

## Goal

Implement the 20 recommendations from the static repo review as one coordinated release program, split into phases that can be built, tested, and committed incrementally without rushing the whole scope into one risky batch.

## Context

The source review was static and slightly stale relative to the current tree. Recent commits already completed or partially completed several items:

- Benchmark list/detail fetches already use parallel loading.
- Share-card rendering already uses an asynchronous detached task with main-actor SwiftUI rendering.
- Haptics exist in workout set completion, PR/workout completion, challenges, sharing, settings, and symptom check-in flows.
- Widget freshness copy and support-tip release wiring already landed.
- Several loading and error-message fixes already landed.

This plan still includes all 20 review items. For already-completed work, the plan should include verification and regression coverage rather than duplicate implementation.

## Phase Structure

### Phase 0: Inventory and Truth Pass

Build a source-of-truth release matrix for all 20 recommendations. Each item is marked as `not started`, `partial`, `implemented-needs-verification`, or `done`, with links to files, tests, and manual QA notes.

This phase prevents stale review notes from becoming busywork. It also gives later phases a checklist that can be updated as each task is completed.

Primary artifacts:

- A release matrix document under `docs/superpowers/specs/` or `docs/superpowers/plans/`.
- A focused grep/audit list for hardcoded colors, raw user-facing errors, unlabeled loading states, fixed icon/text sizes, and known performance paths.

### Phase 1: Release Quality Foundation

Covers recommendations #1-6.

The release should first feel more readable, accessible, and native across the existing core flows. The implementation focus is dark mode, contrast, accessibility smoke checks, loading/error/empty-state polish, haptics verification, performance verification, and share-card smoothness.

Design decisions:

- Dark mode should be solved at the token layer first, then applied to outliers. `AppTheme.*` remains the only source of app colors.
- Static brand colors may remain only where the surface is deliberately branded and contrast-safe, such as share cards or app icons. Interactive app UI should use adaptive tokens.
- Semantic colors should be adaptive and named by meaning, not raw hue.
- Destructive and warning button states should use theme tokens, not `Color.red` or `Color.orange`.
- Accessibility QA is a release gate, not a best-effort note. It must cover light mode, dark mode, high contrast if available, larger Dynamic Type, VoiceOver labels on icon-only actions, and tap target sanity.
- Existing async performance changes are verified with tests/build/manual notes; only gaps are implemented.

Expected user-visible outcome:

- The app is legible in dark mode.
- Loading, empty, and error states feel intentional.
- Important completion/share/milestone moments have native feedback.
- Share-card creation does not visibly freeze the app.

### Phase 2: Training Trust and Personalization

Covers recommendations #8-12.

This phase improves the product loop around Coach Plan and the gym workflow. The app already has deterministic coach decisions, reason codes, caution codes, quick workouts, pain/cycle/energy context, editable workout drafts, and preference-learning domain pieces. The release should make those capabilities feel more trustworthy and personal.

Design decisions:

- Coach copy feedback should be lightweight: thumbs up/down or a similar one-tap usefulness signal. It should track safe metadata only, such as prompt/copy version, deterministic reason codes, fallback source, and surface name. It must not log raw prompts, generated text, cycle details, pain details, or health records.
- "Why this workout?" should present deterministic reasons as clear user-facing trust badges: energy, equipment, recovery, cycle confidence, pain caution, weekly load, and deload/active-recovery signals.
- "Best Next 20 Min" should stop using hardcoded defaults when reliable context exists. It should pull from user settings/equipment, recent check-in, pain logs, cycle phase/confidence, and recent training history with graceful fallback.
- Quick edits should become short-lived learned preferences first, such as "today only" duration/equipment/volume intent. Persistent preferences should be added only where existing `PreferenceLearner` or settings models make it low-risk.
- Post-workout check-in should be brief and optional. It should collect enough signal to improve future plans without turning completion into a survey wall.

Expected user-visible outcome:

- Coach Plan feels explainable, not opaque.
- The quick workout button feels context-aware.
- Edits and post-workout feedback influence near-term recommendations.

### Phase 3: Activation and Progressive Trust

Covers recommendations #7, #14, and #15.

This phase connects onboarding, first workout success, privacy trust, and analytics into a clearer activation loop.

Design decisions:

- The activation funnel should use existing growth events where possible: onboarding started/completed, first workout started/completed, AI/coach plan generated/started, share events, reminders, cycle adjustments, and second session within seven days.
- The first implementation can be an internal domain/service and debug/settings surface rather than a polished external dashboard if that keeps scope safe.
- Onboarding remains short. HealthKit, cycle setup, camera/photo sharing, and reminders should be prompted progressively at the moment they are useful.
- Privacy/data-control messaging should be surfaced in onboarding and Settings using the existing CloudKit/local guest model and Data Trust Center patterns.
- HealthKit denial must remain graceful. Users should never hit a dead-end because a progressive prompt is declined.

Expected user-visible outcome:

- New users get to a successful first workout faster.
- Sensitive permissions are requested with context.
- Users can understand where their health, cycle, pain, and workout data lives.

### Phase 4: Progress, Widgets, and Discoverability

Covers recommendations #13 and #17.

This phase makes hidden value easier to discover without bloating the minimal four-tab surface.

Design decisions:

- Progress destinations can remain conditionally emphasized, but the screen should show value previews or empty guidance instead of hiding entire concepts.
- Empty/locked copy should be action-oriented and precise, such as completing workouts, logging a max, doing a check-in, or sharing a buddy update.
- Widget freshness work is already partially landed. The remaining scope is deep-link accuracy from stale/no-data states into the correct app action.
- Widget copy must stay short and privacy-safe.

Expected user-visible outcome:

- Progress feels useful before the user has lots of data.
- Widgets tell users when data is stale and take them to the right next action.

### Phase 5: Release Readiness and Maintenance

Covers recommendations #16 and #18-20.

This phase makes the release branch clean, review-safe, and repeatable.

Design decisions:

- Support-tip App Review safety is verification-first because the implementation already exists. The gate must rehearse purchase, pending, cancel, unavailable, and unverified transaction paths with the StoreKit config.
- Developer docs should match the real app: SwiftUI, CloudKit, HealthKit, Apple Sign-In, widgets, StoreKit support tip, and current package/app structure.
- Code-health cleanup should stay small and focused: remove stale dead code, fix naming shadows, and run lint/build/tests. Avoid opportunistic refactors.
- The final release gate should match real risk: Swift tests, app build, targeted UI screenshots, StoreKit support-tip flow, dark-mode screenshots, accessibility text-size smoke tests, and Coach Plan fallback with Foundation Models unavailable.
- The plan must explicitly avoid App Store submission unless the user asks for it.

Expected user-visible outcome:

- The release is easier to validate and maintain.
- App Review-sensitive support-tip behavior is rehearsed without submitting.
- Future contributors and agents see accurate docs.

## Cross-Phase Architecture

### Theme and Accessibility

Theme work belongs in `UI/Theme/AppTheme.swift` and small call-site replacements. New colors should be adaptive tokens under existing namespaces, such as `Background`, `Text`, `Accent`, `Semantic`, or `Recovery`. Views should not introduce new raw `Color.red`, `Color.orange`, `Color.green`, or similar app UI colors.

Dynamic Type and icon sizing should prefer semantic SwiftUI fonts. Fixed font sizes are acceptable only for intentionally branded share cards or verified fixed-format surfaces.

### Data and Privacy

New tracking or feedback should use existing domain/data patterns and avoid raw health details. Feedback records should be metadata-only and CloudKit-compatible. If new CloudKit record types are needed, the implementation plan must include schema/index notes and local fallback behavior.

### Coach and Training Logic

Deterministic services remain the source of truth. AI/on-device copy can describe decisions but must not decide workout safety, progression, deload, pain substitutions, or cycle adaptations.

### Verification

Each phase should end with a focused verification command set. The final release gate should run the full package tests and app build, then add targeted UI/manual verification notes where automation is not practical.

## Success Criteria

- All 20 review recommendations are represented in the release matrix and either implemented or explicitly verified as already complete.
- No core app UI depends on hardcoded raw colors where `AppTheme` tokens should be used.
- Dark mode and large text are readable across Today, Train, Cycle, Progress, Settings, share flows, and active workout flows.
- Coach Plan explanations and quick workouts use available user context with safe fallbacks.
- Activation, progressive prompts, and privacy surfaces improve first-workout trust without adding paywalls or blocking guest mode.
- Widgets deep-link to useful next actions from stale/no-data states.
- Support tip remains optional, Settings-only, repeatable, and not tied to feature access.
- Docs and release gates match the current product and architecture.

## Out of Scope

- App Store submission or upload.
- Paywalls, paid feature gates, subscriptions, or restore UI for the consumable support tip.
- New external dependencies.
- Backend services outside CloudKit/local storage.
- Major visual redesign of the four-tab minimal surface.
- Replacing deterministic coach/program logic with AI-generated decisions.

