# Phase 1: Recovery Score Foundation - Research

**Researched:** 2026-04-15
**Domain:** HealthKit sleep analysis, recovery score computation, SwiftUI Charts, CloudKit persistence
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Circular ring display on the dashboard — filled arc around the score number, color shifts green (70-100) / yellow (40-69) / red (0-39).
- **D-02:** Include "Push Day" / "Rest Day" label below the score number inside the ring card.
- **D-03:** Score card is the hero element at the top of the dashboard — first thing the user sees. Existing dashboard content shifts below it.
- **D-04:** Horizontal bar layout for the 5-input breakdown (HRV, sleep, training load, cycle phase, pain).
- **D-05:** Each bar includes a short explanation line (e.g., "Above your follicular baseline", "6.2h — below 7h target").
- **D-06:** 30-day recovery trend chart lives on the breakdown screen — scroll down from the bars to see it.
- **D-07:** Line chart with vertical cycle phase color bands behind the line. Uses SwiftUI Charts framework.
- **D-08:** Partial score with missing badge — compute from available inputs only; show "3/5 inputs" badge.
- **D-09:** Recovery score requires sign-in — guest users see a placeholder prompting sign-in.
- **D-10:** Per-phase HRV baseline normalization is mandatory.
- **D-11:** Score computes on app foreground only — no background HealthKit delivery.
- **D-12:** HRV threshold calibration ratios will be tuned via TestFlight feedback post-ship.

### Claude's Discretion

- Score weight distribution formula across the 5 inputs
- Sleep deduplication algorithm (HK-03 requirement)
- Exact color values for cycle phase bands (should use AppTheme tokens)
- Animation/transition style for the ring fill
- Internal data model field naming (following CloudKit schema rules)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HK-01 | App requests HealthKit sleep analysis authorization | Add `HKCategoryType.sleepAnalysis` to `standardReadTypes` in `HealthKitClient`; call `requestStandardAuthorization()` extended with sleep type |
| HK-02 | App reads sleep duration and quality from HealthKit (HKCategoryType.sleepAnalysis) | New `fetchSleepAnalysis(startDate:endDate:)` on `HealthClientProtocol` + `HealthKitClient`; returns `[HKCategorySample]` |
| HK-03 | Sleep samples from multiple sources deduplicated to avoid inflated duration | Pure domain function `SleepDeduplicator.deduplicate(_:)` using source priority + overlap detection |
| REC-01 | User sees a daily 0-100 recovery score on the dashboard, color-coded green/yellow/red | `RecoveryScoreCard` SwiftUI view in `DashboardView`; score from `RecoveryScoreViewModel` |
| REC-02 | Recovery score computed from up to 5 inputs: HRV, sleep, training volume (ACWR), cycle phase, pain logs | `RecoveryScoreCalculator` pure domain enum; `RecoveryScoreInputs` struct; `RecoveryScore` result struct |
| REC-03 | User can tap dashboard score card to see breakdown screen with each input's contribution | `RecoveryBreakdownView` pushed via `NavigationStack`; `InputBarRow` per sub-score |
| REC-04 | HRV baseline normalized per cycle phase so luteal-phase drops don't trigger false low scores | `HRVBaselineNormalizer` pure domain function; per-phase baseline table with progesterone adjustment |
| REC-05 | User can view recovery score trends over time correlated with cycle phase | `RecoveryTrendChart` using SwiftUI Charts with `RectangleMark` phase bands + `LineMark` scores |
| REC-06 | Recovery score degrades gracefully when HealthKit permissions denied or Apple Watch absent | `RecoveryScoreCalculator` accepts optional inputs; redistributes weights; ViewModel reports `inputCount` |
</phase_requirements>

---

## Summary

Phase 1 is a net-new feature addition to a well-structured existing codebase. The domain layer is strictly pure (zero framework imports), the data layer is protocol-based and actor-safe, and the UI layer uses established patterns (ArtDecoCard, SwiftUI Charts, @MainActor ViewModels). All five recovery score inputs either have existing data paths (HRV via `fetchHeartRateVariability`, training load via `WeeklyLoadAnalyzer`, cycle phase via `CyclePhaseCache`, pain via `DailyPainLog` CloudKit records) or need a new path added (sleep via `HKCategoryType.sleepAnalysis`).

The primary new work is: (1) a sleep fetch method and deduplication algorithm, (2) a pure-domain `RecoveryScoreCalculator` with per-phase HRV normalization, (3) a `RecoveryScoreRecord` CloudKit model with a new schema entry, (4) a `RecoveryScoreViewModel`, and (5) three new SwiftUI views. Every component has a direct analogue in the existing codebase. The biggest architectural decision left to Claude's discretion is the weight distribution formula across the five inputs — the research section below documents the recommended approach.

The CloudKit schema work requires a manual Dashboard step (add `recordName` QUERYABLE index for the new `RecoveryScore` record type) before Production deployment — this is a known project-wide rule documented in CLAUDE.md.

**Primary recommendation:** Build `RecoveryScoreCalculator` first as a pure domain function with full test coverage, then wire HealthKit sleep, then the ViewModel, then the three UI views in dependency order.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HRV fetch + normalization | DataLayer (HealthKitClient) | DomainLayer (calculator) | HealthKit is an external sensor API; normalization is pure math |
| Sleep fetch + deduplication | DataLayer (HealthKitClient) | DomainLayer (SleepDeduplicator) | Sample fetching is I/O; deduplication is pure logic |
| Training load computation | DomainLayer (WeeklyLoadAnalyzer) | DataLayer (CloudKit workouts) | Load analysis is already a pure domain enum — reuse directly |
| Cycle phase input | DataLayer (CyclePhaseCache) | DomainLayer (CycleCalculations) | Cache already wraps calculation; inject as parameter |
| Pain log input | DataLayer (CloudKit DailyPainLog) | DomainLayer (calculator) | Existing record type; fetch in ViewModel |
| Recovery score computation | DomainLayer (RecoveryScoreCalculator) | — | Pure math: inputs → 0-100 score. Zero framework deps |
| Score persistence | DataLayer (CloudKitClient) | — | Follows existing DataClientProtocol pattern |
| ViewModel orchestration | UILayer (@MainActor RecoveryScoreViewModel) | — | Coordinates all fetches; publishes state to views |
| Score card UI | UILayer (RecoveryScoreCard) | — | SwiftUI view, reads from ViewModel |
| Breakdown screen UI | UILayer (RecoveryBreakdownView) | — | NavigationStack push from dashboard |
| Trend chart UI | UILayer (RecoveryTrendChart) | — | SwiftUI Charts LineMark + RectangleMark phase bands |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| HealthKit | iOS 18 system | Sleep analysis, HRV, workouts | Project-required; already wired for HRV/workouts |
| SwiftUI Charts | iOS 16+ system | RecoveryTrendChart | Already used by VolumeChart, StrengthProgressionChart, FrequencyChart |
| CloudKit | iOS 18 system | RecoveryScore record persistence | Project-required; existing DataClientProtocol |
| Swift Testing + XCTest | Swift 6.3 / Xcode 26.4 | Unit tests for domain logic | Project-standard; existing test suite uses XCTest |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| os.log | System | Structured logging | All ViewModel and DataLayer operations per project convention |
| Foundation | System | Codable, Date, Calendar | Required for all models and date math |

No external package dependencies are added. `SundeeFundee/Package.swift` has `dependencies: []` — this is a project-hard constraint. [VERIFIED: Package.swift read in this session]

**Installation:** No installation required. All dependencies are Apple system frameworks.

---

## Architecture Patterns

### System Architecture Diagram

```
App Foreground (onAppear / .task)
        │
        ▼
RecoveryScoreViewModel (@MainActor)
  ├── Parallel fetch:
  │     ├── HealthKitClient.fetchSleepAnalysis(last24h)   ──→ [HKCategorySample]
  │     ├── HealthKitClient.fetchHeartRateVariability(last24h) → [HKQuantitySample]
  │     ├── DataClientFactory.client.fetchAll("DailyPainLog") → [DailyPainLog]
  │     ├── WeeklyLoadAnalyzer.weeklySummaries(workouts)   ──→ [WeeklySummary]
  │     └── CyclePhaseCache.currentPhase                   ──→ CyclePhase?
  │
  ▼
RecoveryScoreInputs (struct, all fields Optional)
        │
        ▼
RecoveryScoreCalculator.calculate(inputs:) ── pure domain function
  ├── SleepDeduplicator.deduplicate(samples:)
  ├── HRVBaselineNormalizer.normalize(hrv:phase:)
  ├── TrainingLoadScorer.score(weeklySummaries:)
  ├── CyclePhaseScorer.score(phase:)
  └── PainScorer.score(logs:)
        │
        ▼
RecoveryScore (struct: totalScore, inputScores, presentInputs, missingInputs)
        │
  ┌─────┴─────────────────┐
  ▼                       ▼
CloudKitClient            RecoveryScoreCard (DashboardView)
.save(RecoveryScoreRecord)  └── tap → RecoveryBreakdownView
                                  ├── InputBarRow × N
                                  └── RecoveryTrendChart
                                       ├── RectangleMark (phase bands)
                                       └── LineMark (daily scores)
```

### Recommended Project Structure

```
DomainLayer/Recovery/
├── RecoveryScoreCalculator.swift   # Pure enum, calculate(inputs:) → RecoveryScore
├── RecoveryScoreInputs.swift       # Struct, all Optional fields
├── RecoveryScore.swift             # Result struct (totalScore, subScores, etc.)
├── HRVBaselineNormalizer.swift     # Per-phase HRV normalization
├── SleepDeduplicator.swift         # Overlap-based deduplication for HK sleep samples
├── TrainingLoadScorer.swift        # ACWR-to-score conversion
├── CyclePhaseScorer.swift          # Phase → recovery multiplier
└── PainScorer.swift                # DailyPainLog → sub-score

DataLayer/
├── Protocols/HealthClientProtocol.swift  (extend: add fetchSleepAnalysis)
├── Actors/HealthKitClient.swift          (extend: implement fetchSleepAnalysis)
└── Mocks/MockHealthKitClient.swift       (extend: add mock sleep storage)

Models/
└── RecoveryScoreRecord.swift       # Codable+Sendable CloudKit record

UI/Views/Dashboard/
├── DashboardView.swift             (modify: insert RecoveryScoreCard as first element)
├── RecoveryScoreCard.swift         (new: hero ring card)
├── RecoveryBreakdownView.swift     (new: breakdown screen)
├── InputBarRow.swift               (new: single input bar component)
└── RecoveryTrendChart.swift        (new: 30-day trend chart)

UI/ViewModels/
└── RecoveryScoreViewModel.swift    (new: @MainActor, @Published state)

Tests/SundeeFundeeKitTests/DomainTests/
└── RecoveryScoreCalculatorTests.swift
Tests/SundeeFundeeKitTests/DataLayerTests/
└── SleepDeduplicatorTests.swift
```

### Pattern 1: Pure Domain Calculator

**What:** All recovery score math lives in `DomainLayer/Recovery/` as a pure `enum` with static functions. No framework imports. Accepts value types, returns value types.

**When to use:** All scoring sub-functions. This enables fast, framework-free unit tests.

**Example:**
```swift
// Source: Established project pattern (WeeklyLoadAnalyzer, CycleCalculations)
public enum RecoveryScoreCalculator {

    public static func calculate(inputs: RecoveryScoreInputs) -> RecoveryScore {
        var weightedSum: Double = 0
        var totalWeight: Double = 0

        if let hrvScore = scoreHRV(inputs.hrvMilliseconds, phase: inputs.cyclePhase) {
            weightedSum += hrvScore * InputWeight.hrv
            totalWeight += InputWeight.hrv
        }
        if let sleepScore = scoreSleep(inputs.sleepDurationHours) {
            weightedSum += sleepScore * InputWeight.sleep
            totalWeight += InputWeight.sleep
        }
        // ... remaining inputs
        guard totalWeight > 0 else {
            return RecoveryScore(total: 0, subScores: [:], presentInputCount: 0)
        }
        let total = (weightedSum / totalWeight).clamped(to: 0...100)
        return RecoveryScore(total: Int(total.rounded()), ...)
    }
}
```

### Pattern 2: HealthKit Sleep Analysis Fetch

**What:** Sleep samples use `HKCategoryType.sleepAnalysis` (not a quantity type). Values are `HKCategoryValueSleepAnalysis` enum cases.

**When to use:** HK-02 implementation in `HealthKitClient.fetchSleepAnalysis`.

**Key API facts:**
- Type identifier: `HKCategoryTypeIdentifier.sleepAnalysis` [VERIFIED: HealthKit framework, confirmed via project's existing menstrualFlow pattern which uses identical HKCategoryType API]
- Sample value cast: `Int(sample.value)` maps to `HKCategoryValueSleepAnalysis` cases: `.inBed` (0), `.asleep` (1 — legacy), `.awake` (2), `.asleepCore` (3), `.asleepDeep` (4), `.asleepREM` (5) [ASSUMED — specific integer mappings for iOS 16+ sleep stages; verify against HK headers]
- Duration: `sample.endDate.timeIntervalSince(sample.startDate)` in seconds
- Source: `sample.sourceRevision.source.name` — use to distinguish Watch vs iPhone

**Example pattern (mirrors existing fetchMenstrualCycles):**
```swift
// Source: Established project pattern (HealthKitClient.fetchMenstrualCycles)
public func fetchSleepAnalysis(
    startDate: Date,
    endDate: Date
) async throws -> [HKCategorySample] {
    guard isAvailable else { throw HealthError.notAvailable }
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthError.noData(type: "sleep analysis")
    }
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate, end: endDate, options: .strictStartDate
    )
    return try await fetchSamples(
        sampleType: sleepType,
        predicate: predicate,
        sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
        limit: HKObjectQueryNoLimit
    ) as? [HKCategorySample] ?? []
}
```

### Pattern 3: Sleep Deduplication (HK-03)

**What:** Apple Watch and iPhone both write sleep samples for the same night. Without deduplication, total duration is double-counted.

**When to use:** Always before computing sleep sub-score.

**Algorithm (Claude's Discretion):**
```
1. Filter to asleep stages only (exclude .inBed, .awake)
2. Sort by startDate ascending
3. Source priority: Watch samples preferred over iPhone samples
4. Merge overlapping intervals from same-priority sources
5. Where Watch and iPhone overlap for same interval, keep Watch
6. Sum merged intervals for total sleep duration
```

**Implementation approach:**
```swift
// Source: [ASSUMED] — standard interval merge algorithm
public enum SleepDeduplicator {
    public struct SleepInterval {
        let start: Date
        let end: Date
        let source: SleepSource   // .watch, .phone, .other
    }

    public static func deduplicate(_ samples: [HKCategorySample]) -> TimeInterval {
        // 1. Convert to intervals, filter to asleep stages
        // 2. Group by source, Watch > Phone priority
        // 3. Merge overlapping intervals within each source
        // 4. Remove Phone intervals that overlap with Watch intervals
        // 5. Sum all remaining intervals
    }
}
```

### Pattern 4: Per-Phase HRV Baseline Normalization (D-10, REC-04)

**What:** HRV is suppressed 10-20% in luteal phase by progesterone. A global baseline causes false low scores every luteal phase. Per-phase expected ranges normalize the score against cycle-phase expectations.

**Approach (Claude's Discretion for exact ratios, HIGH confidence for approach):**

| Cycle Phase | HRV Multiplier | Rationale |
|-------------|---------------|-----------|
| Follicular | 1.0 (baseline) | Post-menstrual estrogen rise: HRV near personal peak |
| Ovulation | 1.05 | Peak estrogen: slight HRV elevation |
| Luteal | 0.85 | Progesterone suppression: 10-20% drop is expected |
| Menstrual | 0.90 | Pain/inflammation: moderate suppression |

**Normalization formula:**
```swift
// Normalize: divide raw HRV by phase multiplier before scoring
// A luteal HRV of 42ms with baseline 50ms → 42/0.85 = 49.4ms (near-baseline)
let normalizedHRV = rawHRV / phaseMultiplier(for: cyclePhase)
```

**Then score against population reference ranges (ASSUMED — verify with TestFlight):**
```
≥ 80ms: 100 (excellent)
60-79ms: 80 (good)
40-59ms: 55 (moderate)
20-39ms: 25 (low)
< 20ms: 0 (very low)
```
[ASSUMED — these thresholds are population averages from training knowledge; should be validated via TestFlight per D-12]

### Pattern 5: Weight Distribution Formula (Claude's Discretion)

**Recommended weights (justification below):**

| Input | Weight | Rationale |
|-------|--------|-----------|
| HRV | 0.30 | Best validated physiological marker of autonomic recovery |
| Sleep | 0.25 | Directly predicts next-day performance and perceived exertion |
| Training Load | 0.25 | ACWR > 1.5 is primary injury/fatigue predictor |
| Cycle Phase | 0.15 | Contextual modifier — provides baseline expectation, not absolute fatigue |
| Pain | 0.05 | Binary signal: 0 pain = no penalty; high pain = override |

Missing inputs → remove their weight entirely, normalize remaining weights to sum to 1.0.

### Pattern 6: RecoveryScoreRecord CloudKit Model

**Field naming must avoid reserved CloudKit names** (per CLAUDE.md CloudKit schema rules):

```swift
// Source: [VERIFIED: CLAUDE.md CloudKit schema rules read in this session]
// Avoid: createdAt, modifiedAt, startDate, endDate — CloudKit system TIMESTAMP fields
public struct RecoveryScoreRecord: Codable, Sendable, Identifiable {
    public var id: String
    public let scoreDate: String        // ISO8601 string (not "date" to avoid ambiguity)
    public let totalScore: Int
    public let hrvSubScore: Int?
    public let sleepSubScore: Int?
    public let loadSubScore: Int?
    public let cyclePhaseSubScore: Int?
    public let painSubScore: Int?
    public let presentInputCount: Int
    public let cyclePhaseRaw: String?   // CyclePhase.rawValue
    public let dateCreated: String      // ISO8601, not "createdAt"
}
```

**CloudKit schema entry required:**
```
RECORD TYPE RecoveryScore (
    "___recordID"    REFERENCE QUERYABLE,
    scoreDate        STRING QUERYABLE SEARCHABLE SORTABLE,
    totalScore       INT64 QUERYABLE SORTABLE,
    hrvSubScore      INT64 QUERYABLE SORTABLE,
    sleepSubScore    INT64 QUERYABLE SORTABLE,
    loadSubScore     INT64 QUERYABLE SORTABLE,
    cyclePhaseSubScore INT64 QUERYABLE SORTABLE,
    painSubScore     INT64 QUERYABLE SORTABLE,
    presentInputCount INT64 QUERYABLE SORTABLE,
    cyclePhaseRaw    STRING QUERYABLE SORTABLE,
    dateCreated      STRING QUERYABLE SORTABLE,
    GRANT WRITE TO "_creator",
    GRANT CREATE TO "_icloud",
    GRANT READ TO "_world"
);
```

**Manual CloudKit Dashboard step required** after code merge: Add `recordName` QUERYABLE index for `RecoveryScore` record type in CloudKit Dashboard (Development → Indexes), then deploy to Production. Without this, `fetchAll` throws `DataError.schemaNotDeployed`. [VERIFIED: CLAUDE.md CloudKit schema rules]

### Pattern 7: RecoveryScoreViewModel Structure

Follows `DashboardViewModel` / `AnalyticsViewModel` patterns exactly:

```swift
// Source: [VERIFIED: DashboardView.swift read in this session]
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class RecoveryScoreViewModel: ObservableObject {
    @Published public private(set) var score: RecoveryScore?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var historicalScores: [RecoveryScoreRecord] = []

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    public func loadScore(cyclePhase: CyclePhase?) async { ... }
    public func loadHistory() async { ... }
}
```

### Anti-Patterns to Avoid

- **HRV without phase normalization:** Computing a global HRV score without cycle phase context causes false low scores every luteal phase. Always normalize before scoring.
- **Background HealthKit fetch for score:** D-11 explicitly locks this out. Background delivery fires before Watch sync completes, producing stale scores. Compute in foreground `.task` only.
- **CloudKit field named `date`, `createdAt`, `startDate`, or `endDate`:** These collide with CloudKit system TIMESTAMP fields. Use `scoreDate`, `dateCreated` instead.
- **Blocking the main thread on sleep deduplication:** Sleep deduplication involves date math on potentially hundreds of samples. Run it off `@MainActor` in the domain layer (pure sync is fine since it's O(n log n) with n ≤ 100 in practice).
- **Single HRV sample as today's score:** HRV varies hour-to-hour. Use the most recent nightly measurement (the Watch produces one overnight SDNN value) rather than averaging intraday readings.
- **Optional inputs crashing the score:** All five inputs must be Optional in `RecoveryScoreInputs`. The calculator must handle any combination of nil inputs, including all five being nil (return nil score, not 0 or crash).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sleep sample overlap detection | Custom interval tree | Standard interval merge (sorted array + sweep line) | O(n log n), deterministic, ≤100 samples in practice |
| HRV population reference ranges | Custom ML model | Hard-coded threshold table (tuned via TestFlight) | D-12 locked; ML adds complexity for negligible accuracy gain pre-launch |
| Chart date axis formatting | Custom date formatter in chart | `AxisMarks(values: .stride(by: .day))` + `dateTime.month()` | SwiftUI Charts built-in; consistent with existing VolumeChart |
| CloudKit fetch query | Custom predicate builder | `DataClientProtocol.fetchAll(recordType:)` + date filter in memory | Existing protocol already handles the common case; add predicate-based fetch only if query performance becomes a concern |
| Phase color lookup | Inline switch in chart | `AppTheme` extension or enum on `CyclePhase` | Centralizes colors; reusable for future features |

**Key insight:** The entire domain layer is pure Swift with no dependencies. Every scoring sub-function is a 5-20 line pure function. Resist the temptation to make this a "scoring engine" with protocols and registries — it's just math.

---

## Common Pitfalls

### Pitfall 1: Sleep Duration Inflation from Multi-Source Samples

**What goes wrong:** User has both Apple Watch and iPhone. Both write sleep analysis samples for the same night. `fetchSleepAnalysis` returns both sets. Summing durations without deduplication reports 14h sleep for an 8h night.

**Why it happens:** HealthKit does not deduplicate across sources. Both Watch and iPhone Health app write to the same HealthKit store.

**How to avoid:** `SleepDeduplicator.deduplicate(_:)` must be called before any duration calculation. Never sum `endDate - startDate` across raw samples without deduplication. [VERIFIED: CLAUDE.md HK-03 requirement; confirmed real-world behavior via project knowledge]

**Warning signs:** Sleep sub-score is always 100, even when user is exhausted. Sleep duration reports > 12 hours.

### Pitfall 2: HRV Reads as Low Every Luteal Phase

**What goes wrong:** Global HRV scoring (40ms = "moderate recovery") scores luteal-phase 42ms the same as follicular-phase 42ms. But follicular baseline might be 55ms, making 42ms genuinely low. Luteal baseline might be 45ms, making 42ms near-baseline.

**Why it happens:** Progesterone suppresses HRV 10-20% in the luteal phase. Without phase normalization, the score reflects absolute HRV, not relative-to-phase HRV.

**How to avoid:** Always call `HRVBaselineNormalizer.normalize(hrv:phase:)` before passing to the scoring threshold table. D-10 locks this in. [VERIFIED: CONTEXT.md D-10, STATE.md decision log]

**Warning signs:** Score drops to yellow/red every luteal phase for users with consistent training.

### Pitfall 3: CloudKit Schema Not Deployed in Production

**What goes wrong:** `RecoveryScore` record type exists in Development but not Production. `fetchAll` silently returns empty, then score history is blank.

**Why it happens:** CloudKit requires manual deployment from Development to Production via Dashboard. The app code itself doesn't create the schema.

**How to avoid:** Include a Wave 0 task to create the `RecoveryScore` record type in CloudKit Dashboard (Development), add `recordName` QUERYABLE index, then deploy to Production before the feature ships. [VERIFIED: CLAUDE.md CloudKit schema rules; cloudkit-schema.json read in this session]

**Warning signs:** `DataError.schemaNotDeployed` in device logs; score history always empty in production but works in development.

### Pitfall 4: RecoveryScoreViewModel Not Refreshing After Score Loads

**What goes wrong:** `RecoveryScoreCard` shows a loading spinner but never populates because `loadScore` is called before `CyclePhaseCache` has loaded the current phase.

**Why it happens:** `DashboardView.task` calls both `viewModel.loadData(cyclePhaseCache:)` and `recoveryScoreViewModel.loadScore(cyclePhase:)` in parallel, but cycle phase needs a moment to load from HealthKit/CloudKit.

**How to avoid:** Pass `cyclePhaseCache.currentPhase` (which may be nil) directly into `loadScore`. The calculator handles nil cycle phase by using a default scoring approach (no phase normalization, moderate defaults). Do not wait for cycle phase to load before computing the score — compute with what's available, then recompute if phase loads later. [VERIFIED: CyclePhaseCache.swift read in this session — refreshIfNeeded is async]

**Warning signs:** Score card spinner never resolves on first launch.

### Pitfall 5: Nil Score vs Zero Score Confusion

**What goes wrong:** `RecoveryScore.total` is `Int` (not `Int?`), so a score of 0 is indistinguishable from "no data". The ring displays 0 as "Rest Day" when the real meaning is "score unavailable".

**Why it happens:** Implicit optional-to-int conversion collapses nil into 0.

**How to avoid:** `RecoveryScore` should be an Optional return from the calculator (returns nil when all inputs are absent). The ViewModel holds `@Published var score: RecoveryScore?`. The view renders the loading/empty state when `score == nil`, and the ring when `score != nil`.

**Warning signs:** New users (no HealthKit data yet) see "0 — Rest Day" instead of the empty state with onboarding copy.

### Pitfall 6: SwiftUI Charts RectangleMark Phase Bands Require Date Ranges

**What goes wrong:** Cycle phase bands on the trend chart require start/end dates per phase segment. Using only the current cycle phase produces a single band, not the 30-day history.

**Why it happens:** `RecoveryTrendChart` needs per-day phase assignments for all 30 days, not just today's phase.

**How to avoid:** The ViewModel must pre-compute an array of `(dateRange: ClosedRange<Date>, phase: CyclePhase)` from the period logs + cycle settings, covering the 30-day window. Pass this array to `RecoveryTrendChart`. [VERIFIED: CycleCalculations.swift read — `calculateCycleStatus` accepts a `referenceDate` parameter, enabling per-day phase computation]

**Warning signs:** Chart shows no phase bands, or only a single band at today's position.

---

## Code Examples

### HKCategoryType.sleepAnalysis Authorization

```swift
// Source: [VERIFIED: HealthKitClient.swift standardReadTypes pattern read in session]
// Add to HealthKitClient.standardReadTypes:
if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
    types.insert(sleepType)
}
```

### Existing Chart Pattern (VolumeChart)

```swift
// Source: [VERIFIED: VolumeChart.swift read in this session]
Chart(data) { point in
    BarMark(x: .value("Week", point.weekStartDate), y: .value("Volume", point.totalVolume))
        .foregroundStyle(AppTheme.Background.navy.gradient)
}
.chartXAxis {
    AxisMarks(values: .stride(by: .month)) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
            .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
        AxisValueLabel(format: .dateTime.month(.abbreviated))
            .font(AppTheme.Typography.labelSmall)
    }
}
.frame(height: 200)
```

### Phase Band in RecoveryTrendChart (RectangleMark)

```swift
// Source: [ASSUMED] — RectangleMark is the correct SwiftUI Charts primitive for vertical bands
// Verify against Swift Charts docs before implementation
Chart {
    ForEach(phaseBands) { band in
        RectangleMark(
            xStart: .value("Phase Start", band.startDate),
            xEnd: .value("Phase End", band.endDate),
            yStart: .value("Min", 0),
            yEnd: .value("Max", 100)
        )
        .foregroundStyle(band.phase.chartBandColor)
        .opacity(band.phase.chartBandOpacity)
    }
    ForEach(scores) { record in
        LineMark(x: .value("Date", record.scoreDate), y: .value("Score", record.totalScore))
            .foregroundStyle(AppTheme.Text.primary)
            .lineStyle(StrokeStyle(lineWidth: 2))
        PointMark(x: .value("Date", record.scoreDate), y: .value("Score", record.totalScore))
            .foregroundStyle(record.zoneColor)
    }
}
```

### AppTheme.Recovery New Namespace

```swift
// Source: [VERIFIED: 01-UI-SPEC.md read in this session]
// Add to AppTheme.swift:
public enum Recovery {
    public static let green = Color(red: 0.22, green: 0.70, blue: 0.29)   // #38B249
    public static let yellow = Color(red: 0.92, green: 0.76, blue: 0.18)  // #EBC12E
    // Red zone reuses AppTheme.Accent.orange (#f27319)
}

public static func recoveryColor(for score: Int) -> Color {
    switch score {
    case 70...100: return AppTheme.Recovery.green
    case 40...69:  return AppTheme.Recovery.yellow
    default:       return AppTheme.Accent.orange
    }
}
```

### Arc Ring Animation Pattern

```swift
// Source: [VERIFIED: 01-UI-SPEC.md animation spec read in this session]
Circle()
    .trim(from: 0, to: animatedProgress)
    .stroke(ringColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .onAppear {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedProgress = Double(score.total) / 100.0
        }
    }
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HKSleepAnalysis `.asleep` only | iOS 16+ stage types: `.asleepCore`, `.asleepDeep`, `.asleepREM` | iOS 16 (2022) | Must handle both legacy `.asleep` and stage-specific values when filtering |
| HKSampleQuery (callback) | `withCheckedThrowingContinuation` wrapping | Swift async (2021) | Project already uses this pattern consistently; no changes needed |
| Charts (third-party) | SwiftUI Charts (iOS 16+) | WWDC 2022 | Project already uses SwiftUI Charts; consistent pattern |

**Deprecated/outdated:**
- `.asleep` (value 1): Still present for backwards compatibility, but iOS 16+ devices report stage-specific values. Sleep deduplication and duration summation must include all stage values (1, 3, 4, 5) — do not filter only for `.asleep`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | HRV phase multipliers: Follicular=1.0, Ovulation=1.05, Luteal=0.85, Menstrual=0.90 | Architecture Patterns: Pattern 4 | Scores may be off; specific ratios tuned via TestFlight per D-12 — medium risk |
| A2 | HRV scoring thresholds: ≥80ms=100, 60-79=80, 40-59=55, 20-39=25, <20=0 | Architecture Patterns: Pattern 4 | Thresholds may not fit user population; TestFlight will reveal this |
| A3 | Input weight distribution: HRV=0.30, Sleep=0.25, Load=0.25, Phase=0.15, Pain=0.05 | Architecture Patterns: Pattern 5 | Scores may feel wrong; user feedback will surface this |
| A4 | `HKCategoryValueSleepAnalysis` integer mappings for iOS 16+ stage types (.asleepCore=3, .asleepDeep=4, .asleepREM=5) | Architecture Patterns: Pattern 2 | Sleep deduplication might include wrong samples; verify against HealthKit headers during Wave 0 |
| A5 | `RectangleMark` is the correct SwiftUI Charts primitive for vertical background bands | Code Examples: Phase Band | Chart may not compile; verify against Charts docs or Swift Charts WWDC session |

**Verified claims (not in Assumptions Log):**
- HRV fetch API (`heartRateVariabilitySDNN`) — verified via HealthKitClient.swift
- Sleep auth pattern (identical to menstrualFlow) — verified via HealthKitClient.swift
- CloudKit field naming rules (avoid createdAt/startDate/endDate) — verified via CLAUDE.md
- AppTheme spacing/typography tokens — verified via AppTheme.swift
- Existing test infrastructure (XCTest, `@testable import SundeeFundeeKit`) — verified via test files
- `DashboardView` VStack structure and existing EnvironmentObjects — verified via DashboardView.swift
- `CyclePhaseCache.currentPhase` is `Optional<CyclePhase>` — verified via CyclePhaseCache.swift
- `WeeklyLoadAnalyzer.weeklySummaries(from:weekCount:)` signature — verified via WeeklyLoadAnalyzer.swift
- `DailyPainLog` CloudKit record type exists with `intensity` INT64 field — verified via cloudkit-schema.json
- `calculateCycleStatus(periodLogs:settings:referenceDate:)` accepts a `referenceDate` parameter — verified via CycleCalculations.swift

---

## Open Questions

1. **What DailyPainLog intensity scale maps to what recovery penalty?**
   - What we know: `DailyPainLog.intensity` is `INT64` (0-10 by convention, unverified)
   - What's unclear: Is 0 = no pain or 0 = unknown? Is scale 0-5 or 0-10?
   - Recommendation: Read `DailyPainLog` model source and/or `PainTrackingViewModel` to confirm scale before writing `PainScorer`. If scale is 0-10: linear map `max(0, 100 - intensity * 10)`.

2. **Does the app already store historical `RecoveryScoreRecord`s for the trend chart, or does it compute them lazily?**
   - What we know: Nothing is stored yet — this is new.
   - What's unclear: Should we back-fill scores on first launch (using existing HRV/sleep history), or only start recording from installation of the new build?
   - Recommendation: Back-fill scores on first launch for the last 30 days using available HealthKit history. This makes the trend chart immediately useful. Store each back-filled score with its `scoreDate`. Mark back-filled records if future features need to distinguish them.

3. **Does `CyclePhaseCache` need to expose per-day phase history (not just today)?**
   - What we know: `CyclePhaseCache` only exposes `currentPhase` for today.
   - What's unclear: The trend chart needs 30 days of phase bands, requiring per-day phase computation.
   - Recommendation: The `RecoveryScoreViewModel` should compute phase bands itself using `calculateCycleStatus(periodLogs:settings:referenceDate:)` with each past date as `referenceDate`. Do not modify `CyclePhaseCache` for this use case.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode 16+ (Swift 6 support) | Build | ✓ | Xcode 26.4 / Swift 6.3 | — |
| iOS Simulator | Testing | ✓ | iOS 18 (inferred from project target) | — |
| HealthKit (sleep analysis) | HK-01, HK-02, HK-03 | ✓ (framework) | iOS 18 system | Score without sleep sub-score (D-08 graceful degradation) |
| SwiftUI Charts | REC-05 trend chart | ✓ | iOS 16+ system | — |
| CloudKit | Score persistence | ✓ | iOS 18 system | Guest mode uses LocalDataClient |

**Missing dependencies with no fallback:** None.

**Note:** HealthKit sleep data requires a physical device with Apple Watch for meaningful test data. Simulator cannot write realistic sleep samples. Plan to test sleep deduplication with `MockHealthKitClient` in unit tests, and validate end-to-end on device during TestFlight.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (Swift 6.3 / Xcode 26.4) |
| Config file | `SundeeFundee/Package.swift` (Swift Package test target) |
| Quick run command | `cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter 'SundeeFundeeKitTests'` |
| Full suite command | `cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HK-01 | `requestStandardAuthorization` includes sleep type | unit | `swift test --filter 'SundeeFundeeKitTests.HealthKitClientTests'` | ✅ (extend existing) |
| HK-02 | `fetchSleepAnalysis` returns category samples for date range | unit | `swift test --filter 'SundeeFundeeKitTests.HealthKitClientTests'` | ✅ (extend existing) |
| HK-03 | `SleepDeduplicator` removes overlapping Watch+Phone samples | unit | `swift test --filter 'SundeeFundeeKitTests.SleepDeduplicatorTests'` | ❌ Wave 0 |
| REC-01 | RecoveryScoreCard renders score from ViewModel | manual-only | N/A — UI rendering | — |
| REC-02 | `RecoveryScoreCalculator.calculate` produces correct score from known inputs | unit | `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests'` | ❌ Wave 0 |
| REC-02 | Score is nil (not 0) when all inputs are nil | unit | `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests'` | ❌ Wave 0 |
| REC-03 | Breakdown screen shows correct sub-scores for each input | manual-only | N/A — UI layout | — |
| REC-04 | `HRVBaselineNormalizer` produces higher normalized score for luteal-phase HRV than global scoring would | unit | `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests'` | ❌ Wave 0 |
| REC-05 | `RecoveryTrendChart` renders with phase bands (smoke) | manual-only | N/A — chart rendering | — |
| REC-06 | Calculator with 2/5 inputs present returns partial score (not nil, not 0) | unit | `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests'` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests'`
- **Per wave merge:** `cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `Tests/SundeeFundeeKitTests/DomainTests/RecoveryScoreCalculatorTests.swift` — covers REC-02, REC-04, REC-06
- [ ] `Tests/SundeeFundeeKitTests/DataLayerTests/SleepDeduplicatorTests.swift` — covers HK-03

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Recovery score requires sign-in (D-09); auth enforced by `authViewModel.isGuest` check — existing pattern |
| V3 Session Management | no | No new session surface area |
| V4 Access Control | no | CloudKit private database; user can only read their own records |
| V5 Input Validation | yes | `RecoveryScoreInputs` — clamp HRV, sleep hours, sub-scores to valid ranges before persistence |
| V6 Cryptography | no | No new cryptographic operations |

### Known Threat Patterns for HealthKit + CloudKit

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Score injection (malformed CloudKit record) | Tampering | Resilient decode (skip corrupt records) — existing DataLayer pattern |
| HRV spoofing via injected HealthKit samples | Tampering | Out of scope — app trusts HealthKit as authoritative; no mitigation needed |
| Guest accessing score history | Elevation of Privilege | `authViewModel.isGuest` guard in ViewModel (D-09) |
| Crash on all-nil inputs to calculator | Denial of Service | Calculator must return `nil` (not crash) when all inputs absent — test REC-06 |

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: project codebase] — `HealthKitClient.swift`, `MockHealthKitClient.swift`, `CyclePhaseCache.swift`, `DashboardView.swift`, `AppTheme.swift`, `VolumeChart.swift`, `WeeklyLoadAnalyzer.swift`, `CycleCalculations.swift`, `cloudkit-schema.json` — all read directly in this session
- [VERIFIED: CLAUDE.md] — CloudKit schema rules, Swift 6 strict concurrency, Art Deco theme requirements, testing patterns
- [VERIFIED: 01-CONTEXT.md, 01-UI-SPEC.md] — locked decisions, UI component specifications, color tokens

### Secondary (MEDIUM confidence)

- [CITED: Apple HealthKit documentation pattern] — `HKCategoryTypeIdentifier.sleepAnalysis` query mirrors `HKCategoryTypeIdentifier.menstrualFlow` pattern already implemented in project

### Tertiary (LOW confidence)

- [ASSUMED] — HRV phase multiplier ratios (Luteal=0.85, etc.) — training knowledge; D-12 plans TestFlight validation
- [ASSUMED] — HRV scoring threshold table (ms → 0-100 mapping) — training knowledge; D-12 plans TestFlight validation
- [ASSUMED] — `HKCategoryValueSleepAnalysis` integer values for iOS 16+ stage types — verify against HealthKit headers
- [ASSUMED] — `RectangleMark` for chart phase bands — verify against Swift Charts API

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all Apple system frameworks, no external deps, verified in codebase
- Architecture: HIGH — all patterns have direct analogues in existing code; verified by reading source
- Pitfalls: HIGH — CloudKit rules, HRV normalization, sleep deduplication are well-documented in project; sleep stage values are ASSUMED
- HRV thresholds: LOW — population average thresholds from training knowledge, flagged for TestFlight validation

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (stable Apple frameworks; no fast-moving dependencies)
