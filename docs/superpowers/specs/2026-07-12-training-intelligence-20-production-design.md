# Sundee Fundee 2.0 Production Design

**Date:** 2026-07-12  
**Status:** Approved design; implementation not started  
**Target:** iOS 18+, Swift 6, CloudKit-only backend, all features free

## Goal

Prepare Sundee Fundee for a full 2.0 production release with three user-visible capabilities delivered in parallel:

1. A readiness-first daily training surface built on the existing shadow assessment foundation.
2. Conservative deload detection with active-recovery programming.
3. Privacy-first social sharing of selected training outcomes.

The release must remain useful in guest mode, degrade gracefully when HealthKit is denied, preserve existing workout history, and avoid exposing raw health or sensitive cycle data through analytics or sharing.

## Product decisions

- Target release version is `2.0.0`.
- The three capabilities become directly visible in production UI; no feature flag is required for launch.
- Workstreams proceed in parallel behind typed contracts, then converge through a single integration and release gate.
- Readiness is explainable: score/state, confidence, signal availability, stale status, and concise reasons are visible where useful.
- HealthKit is optional. Missing permission lowers confidence and changes copy, but never blocks workout creation.
- Deload recommendations are conservative and non-diagnostic. They may reduce volume, suggest active recovery, or preserve the normal session; they never rewrite completed history.
- Sharing is opt-in and metadata-only by default. Raw HealthKit values, cycle details, pain details, private notes, and raw prompts are excluded unless a future explicit product decision adds a narrowly scoped safe variant.
- No paywalls, purchase gates, or paid access are introduced.
- No archive-for-upload, TestFlight distribution, App Store upload, or App Review submission occurs without explicit authorization in a later step.

## Architecture and boundaries

### Readiness UI

Consume `DailyReadinessService` and `DailyReadinessSnapshot` from the existing readiness foundation. Add a view model and app-shell surface that can render loading, current assessment, unavailable data, stale data, HealthKit denial, and actionable save errors. The UI must not calculate scores or read HealthKit directly.

### Deload programming

Add a pure domain service that maps readiness state, confidence, training-load evidence, pain severity, recent session density, and deload history to a typed training adjustment. The output should distinguish normal training, reduced volume/intensity, and active recovery. Keep the decision deterministic and unit-testable. Workout generation consumes the adjustment through an adapter; completed workouts remain immutable.

### Social sharing

Extend the existing share-card system with 2.0-safe variants for readiness, recovery progress, deload completion, and selected workout outcomes. A privacy model controls which metadata is included. The renderer and system share sheet remain UI concerns; domain models provide only sanitized summaries.

### Data and CloudKit

Use versioned Codable models and existing client protocols. New CloudKit records must avoid reserved field names, encode dates as ISO8601 strings, decode booleans defensively, include queryable `recordName` indexes, and preserve local fallback behavior. Any schema migration/deployment is a separately verified release step.

### Integration boundary

Each workstream owns its domain, data, tests, and UI files. Integration happens through typed models and app-shell view models only. No stream may reach through another stream’s private implementation or introduce raw HealthKit/cycle/pain values into analytics or share payloads.

## User flow

1. The Today surface presents the daily readiness state and a short explanation.
2. The user can inspect signals or continue directly to a workout.
3. Workout entry applies the conservative adjustment when deload evidence is strong enough; otherwise it preserves the normal session.
4. After completion, the user may share a sanitized result card through the existing system share sheet.
5. Guests see the same core behavior with local persistence. Signed-in users sync supported derived records through CloudKit.

## Error and privacy behavior

- HealthKit denial: show an optional-permission explanation and continue with workout history/check-ins.
- No history: show a low-confidence state and avoid implying medical or performance certainty.
- Stale data: label the assessment and avoid silently presenting it as current.
- CloudKit failure: retain local behavior, queue supported mutations through existing data-client patterns, and show actionable copy without raw error descriptions.
- Share cancellation: do nothing destructive and preserve the user’s privacy preset.
- High pain: recommend recovery-oriented options and use non-diagnostic language.
- Analytics: record only safe event names, model versions, reason codes, fallback source, and surface names; never raw health, cycle, pain, prompts, or generated text.

## Testing and release gates

Each stream follows domain tests → persistence/data tests → view-model/UI tests. The integration gate must cover:

- Full Swift package test suite and simulator build.
- Readiness, deload, and sharing scenario tests, including insufficient history and HealthKit denial.
- Guest mode and signed-in local/CloudKit fallback.
- Accessibility labels, Dynamic Type, dark mode, and empty/loading/error states.
- Privacy-safe share output and cancellation.
- CloudKit schema validation, queryable record IDs, and migration/decode resilience.
- Simulator smoke journeys and fresh App Store screenshot capture.
- Metadata, release notes, privacy/review notes, version/build, and rollback documentation.

The final gate must explicitly record that no upload or submission occurred. Upload/submission requires a separate user authorization after all checks pass.

## Workstream decomposition

- **Readiness UI:** Today card, signal details, confidence/empty states, app-shell integration, UI tests.
- **Deload programming:** pure adjustment policy, active-recovery builder integration, workout-entry copy, domain and integration tests.
- **Social sharing:** sanitized 2.0 variants, privacy controls, renderer/share-sheet integration, screenshot and cancellation tests.
- **Integration/release:** shared navigation, persistence/schema, accessibility/privacy audit, metadata, version/build, simulator journeys, and final gate.

## Success criteria

The 2.0 build is ready for production preparation when all three workstreams are integrated, directly visible, covered by the release gate, and validated on the configured iPhone 17 Pro Simulator without regressions to guest mode, HealthKit denial handling, CloudKit/local fallback, or privacy guarantees.
