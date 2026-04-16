# Phase 1: Recovery Score Foundation - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a daily 0-100 recovery score on the dashboard, backed by up to 5 inputs (HRV, sleep, training load, cycle phase, pain logs). Users always know whether today is a push day or a rest day. Includes the dashboard score card, a tap-through breakdown screen with per-input detail, and a 30-day trend chart with cycle phase bands.

</domain>

<decisions>
## Implementation Decisions

### Score Card Design
- **D-01:** Circular ring display on the dashboard — filled arc around the score number, color shifts green (70-100) / yellow (40-69) / red (0-39). Similar to Apple Activity Rings aesthetic.
- **D-02:** Include "Push Day" / "Rest Day" label below the score number inside the ring card — directly answers the app's core value proposition.
- **D-03:** Score card is the hero element at the top of the dashboard — first thing the user sees. Existing dashboard content shifts below it.

### Breakdown Screen
- **D-04:** Horizontal bar layout for the 5-input breakdown (HRV, sleep, training load, cycle phase, pain). Each bar shows a 0-100 sub-score with independent green/yellow/red coloring.
- **D-05:** Each bar includes a short explanation line below it (e.g., "Above your follicular baseline", "6.2h — below 7h target"). Not just label + number.
- **D-06:** 30-day recovery trend chart lives on the breakdown screen — scroll down from the bars to see it. One tap from dashboard gets everything.

### Trend Chart
- **D-07:** Line chart with vertical cycle phase color bands behind the line. Smooth line for daily scores, vertical colored bands mark menstrual/follicular/ovulation/luteal phases. Uses SwiftUI Charts framework (consistent with existing VolumeChart, StrengthProgressionChart).

### Graceful Degradation
- **D-08:** Partial score with missing badge — when HealthKit permissions denied or Apple Watch absent, compute score from available inputs only (redistribute weights). Show the score ring normally but add a "3/5 inputs" badge. Breakdown screen shows grayed-out bars for missing inputs with a prompt to enable.
- **D-09:** Recovery score requires sign-in — guest users do not see the recovery score. Show a placeholder prompting sign-in. This means all score history persists to CloudKit only.

### Pre-decided (from project/research)
- **D-10:** Per-phase HRV baseline normalization is mandatory — luteal-phase HRV drops must not trigger false low recovery scores. Progesterone suppresses HRV 10-20% in luteal phase.
- **D-11:** Score computes on app foreground only — no background HealthKit delivery (unreliable due to watchdog throttling; Watch sync may not have completed).
- **D-12:** HRV threshold calibration ratios will be tuned via TestFlight feedback post-ship — specific numbers are medium-confidence; the per-phase approach is high-confidence.

### Claude's Discretion
- Score weight distribution formula across the 5 inputs
- Sleep deduplication algorithm (HK-03 requirement)
- Exact color values for cycle phase bands (should use AppTheme tokens)
- Animation/transition style for the ring fill
- Internal data model field naming (following CloudKit schema rules)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — REC-01 through REC-06 (recovery score), HK-01 through HK-03 (HealthKit sleep)

### Existing Code
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/HealthClientProtocol.swift` — Existing protocol with `fetchHeartRateVariability()`, `fetchRestingHeartRate()`, `fetchActiveEnergy()`. Sleep reads need to be added here.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift` — Actor-based HealthKit implementation to extend with sleep queries
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` — Training load trends (ACWR, frequency, volume) — input to recovery score
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Cycle/CycleCalculations.swift` — Cycle phase calculation (pure domain function)
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/CyclePhaseCache.swift` — Observable cycle phase state (@EnvironmentObject)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` — Existing dashboard where score card will be added
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift` — Art Deco design tokens (colors, spacing, typography)
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift` — CloudKit persistence (score history storage)

### Schema
- `SundeeFundeeApp/cloudkit-schema.json` — Existing CloudKit record types (new RecoveryScore record type will be needed)

### Codebase Analysis
- `.planning/codebase/ARCHITECTURE.md` — Layered architecture, data flow patterns
- `.planning/codebase/INTEGRATIONS.md` — HealthKit integration details

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HealthClientProtocol` + `HealthKitClient` actor: HRV and heart rate reads already wired; extend with sleep analysis
- `WeeklyLoadAnalyzer`: Provides `WeeklySummary` with workout count, duration, muscle groups — ACWR-like training load input
- `PlateauDetector`: Plateau flags can feed into recovery score indirectly (via Phase 2 deload)
- `CyclePhaseCache`: Observable cycle phase — direct input to recovery score
- `PainTrackingViewModel`: Pain/injury data — direct input to recovery score
- SwiftUI Charts: `VolumeChart`, `StrengthProgressionChart`, `FrequencyChart`, `CycleCorrelationChart` — patterns for building the trend chart
- `AppTheme`: Design tokens (cream #f4f0df, navy #0d1a40, orange #f27319, gold #d4a520)
- `MockHealthKitClient`: Testing double for HealthKit — extend with mock sleep data

### Established Patterns
- Pure domain functions in `DomainLayer/` (no framework imports) — recovery score calculator goes here
- Actor-based data clients for thread safety — score persistence follows this pattern
- `@MainActor` ViewModels with `@Published` properties and async `loadData()` — new `RecoveryScoreViewModel`
- `DataClientProtocol` generic fetch/save — new `RecoveryScoreRecord` model
- `@EnvironmentObject` for shared state — `CyclePhaseCache` pattern could extend to `RecoveryScoreCache`
- Resilient decode (skip corrupt records) — apply to recovery score records

### Integration Points
- `DashboardView` — add score card as first element
- `MainTabView` — no new tab needed; breakdown is a navigation push from dashboard
- `HealthKitClient.requestStandardAuthorization()` — extend with sleep analysis types
- `DataClientFactory.shared.client` — score storage via existing CloudKit/Local switching
- CloudKit Dashboard — new `RecoveryScore` record type with `recordName` queryable index

</code_context>

<specifics>
## Specific Ideas

- Ring visual inspired by Apple Activity Rings — familiar to Apple Watch users
- "Push Day" / "Rest Day" is the single most important label — answers the core value question at a glance
- Explanation lines on breakdown bars should reference cycle-phase-relative baselines (e.g., "Above your follicular baseline") to educate users about their body's patterns

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-recovery-score-foundation*
*Context gathered: 2026-04-15*
