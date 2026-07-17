# Training Intelligence 2.0 privacy, accessibility, and performance audit

Date: 2026-07-17

## Scope and evidence

The integrated readiness, deload, analytics, dashboard, and share surfaces were reviewed against the Task 8 brief. Focused tests covered sanitized share payloads, share privacy defaults, guest mode, HealthKit denial, stale/no-history readiness, and analytics persistence. The full package suite and an iOS Simulator build were also run. Framework-specific counts and command output are retained in the release-gate log so this audit does not become stale as coverage grows.

## Privacy findings and remediation

- Share cards accept `ShareSanitizedSummary` for readiness/deload outcomes. Its validating initializer and decoder reject HealthKit, cycle, menstrual, pain, symptom, sleep/HRV, private-note, prompt, and generated-copy terms. Sanitized variants omit caller context from links and share analytics.
- `GrowthAnalyticsService` now applies a structural metadata firewall: only the allowlisted `GrowthEventName` values are persisted; unknown names are rejected. Sources and property keys are allowlisted, and each retained key has a constrained semantic value grammar (surface/route/enums, booleans, or opaque identifier tokens). The cycle-specific `ShareSurface.cycleInsight` source and surface metadata are explicitly excluded, while share event names remain available for aggregate funnel analysis. Arbitrary titles, private notes, health/cycle/pain text, prompts, generated copy, and free-form exercise names are never encoded. Safe presentation metadata remains available for funnel analysis.
- `DailyReadinessRecord` persists derived scores, state, confidence, and signal/reason identifiers only. It does not persist HealthKit samples, cycle dates, pain locations, or private notes. Raw HealthKit samples remain inside the readiness provider; manual logs remain behind the data client.
- Guest mode uses local storage and the readiness view model skips HealthKit copy. HealthKit unavailable/denied, CloudKit failure, stale snapshots, and no-assessment states have actionable or empty-state UI paths covered by tests.

## Accessibility and appearance review

- Dashboard readiness, share preview, privacy disclosure, QR badge, and outcome cards expose VoiceOver labels/values/hints. The privacy disclosure explicitly says health, cycle, pain, and private notes remain on-device.
- Existing theme tests verify semantic colors adapt in dark appearance. Reviewed 2.0 surfaces use `AppTheme` tokens; no new hard-coded semantic colors were introduced.
- Existing Dynamic Type coverage and semantic icon sizing remain intact. One intentionally fixed-size serif score in the PR card is constrained by the share-card aspect and is not a dashboard control.

## Performance and actor isolation

- Readiness health inputs load concurrently (`async let`) in an actor-backed provider; readiness persistence is actor-isolated and dashboard view models are main-actor-bound.
- Cycle phase work is throttled by `CyclePhaseCache`; share rendering runs from the sheet task and does not synchronously block dashboard state updates.
- Focused and full test runs completed without failures; Simulator build completed successfully.

## Verification commands

- `swift test --filter 'SundeeFundeeKitTests.(SharePrivacyTests|ShareSanitizedSummaryTests|ShareSanitizedSummaryShareTests|DailyReadinessViewModelTests|ReadinessScenarioTests|GrowthAnalyticsServiceTests)'` — completed successfully.
- `swift test` — XCTest and Swift Testing suites completed successfully; framework-specific counts are retained in the release-gate log.
- `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build CODE_SIGNING_ALLOWED=NO` — `BUILD SUCCEEDED`.
