---
phase: 01
reviewed_at: 2026-04-16T00:00:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreInputs.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScore.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/HRVBaselineNormalizer.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/CyclePhaseScorer.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/PainScorer.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SleepDeduplicator.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/HealthClientProtocol.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift
  - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockHealthKitClient.swift
  - SundeeFundee/Sources/SundeeFundeeKit/Models/RecoveryScoreRecord.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryScoreCard.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/InputBarRow.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryBreakdownView.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryTrendChart.swift
  - SundeeFundeeApp/cloudkit-schema.json
severity_counts:
  critical: 2
  high: 4
  medium: 6
  low: 5
  total: 17
findings:
  critical: 2
  warning: 4
  info: 11
  total: 17
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-04-16
**Depth:** standard
**Files Reviewed:** 19 (17 Swift source + 1 CloudKit schema + 1 theme file)
**Status:** issues_found

## Summary

The Phase 01 recovery-score-foundation implementation is well-architected overall. Domain layer files are pure, properly typed, thread-safe, and follow established conventions. CloudKit schema follows naming rules (avoids `createdAt`/`startDate`/`endDate` reserved fields, uses `dateCreated` and `scoreDate`). Swift 6 strict concurrency is respected with `@MainActor` on the ViewModel and `actor` for `HealthKitClient`.

However, two **critical** issues block correctness: (1) `RecoveryScoreViewModel.loadScore` fetches `CompletedWorkoutRecord` from the `"Workout"` record type, but CloudKit-saved `Workout` records serialize with different field shapes (`exercises: [Exercise]` vs expected `exerciseNames: [String]`, missing `isComplete`). This will cause every recovery score to silently fall back to the "insufficient training history" default of 75 for the training-load dimension. (2) `HKUnit(from: "ms")` is used for HRV decoding — Apple's string-parsing unit API can crash at runtime on malformed strings and is the wrong canonical form; `HKUnit.secondUnit(with: .milli)` is used elsewhere (including the test factory).

Secondary concerns include multiple force-unwraps in `InputBarRow`, `TrainingLoadScorer`, and `HealthKitClient`, which violate the project's `force_unwrapping` SwiftLint rule and are crash-prone. Sub-score weights, sleep thresholds, HRV band thresholds, and pain score coefficients are hard-coded magic numbers without calibration justification — the research doc explicitly flagged HRV thresholds as a known low-confidence area.

None of the issues are security vulnerabilities. There is no `eval`/`exec`/hardcoded secrets/injection surface. All file I/O is bracketed by actor/await.

## Critical Issues

### CR-01: Workout record-type/type mismatch silently zeros training load input

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:110`
**Issue:** `loadScore` fetches `CompletedWorkoutRecord` from `recordType: "Workout"`, but the CloudKit `Workout` record type is written by `ActiveWorkoutSessionViewModel` / `WorkoutDetailView` using the `Workout` Swift struct, which encodes fields `id, date, name, exercises (as [Exercise] objects), notes, duration, completedAt`. `CompletedWorkoutRecord` requires non-optional `name, date, duration, exerciseNames ([String]), isComplete (Bool)`. Because `exerciseNames` and `isComplete` do not exist in persisted `Workout` records, JSON decoding of every record into `CompletedWorkoutRecord` will throw; both `CloudKitClient` and `LocalDataClient` skip-on-decode-failure (by design — see CLAUDE.md "Decode resilience"), so `workouts` resolves to an empty array. `WeeklyLoadAnalyzer.weeklySummaries(from: [], weekCount: 4)` returns few or no summaries, and `TrainingLoadScorer.score` then returns the "Insufficient training history — moderate default" score of 75 regardless of actual training volume. The training-load dimension becomes a constant 75 for all users — silently breaking a core recovery input.

**Fix:** Either (a) fetch `Workout` and map to `CompletedWorkoutRecord` using the existing `Workout.completedWorkoutRecord` extension, or (b) fetch `Workout` directly and adapt `WeeklyLoadAnalyzer` to accept `[Workout]`. Option (a) is less invasive:

```swift
// Training load: fetch workouts, compute weekly summaries
do {
    let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
    let completed = workouts.compactMap { $0.completedWorkoutRecord }
    weeklySummaries = WeeklyLoadAnalyzer.weeklySummaries(from: completed, weekCount: 4)
} catch {
    recoveryLogger.info("Training load fetch skipped: \(error.localizedDescription)")
}
```

This also requires a unit test that exercises a full fetch → decode → score pipeline with seeded Workout records — current tests likely mock `CompletedWorkoutRecord` directly and miss this integration break.

---

### CR-02: `HKUnit(from: "ms")` is crash-prone and inconsistent with canonical API

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:84`
**Issue:** `HKUnit(from: "ms")` uses Apple's string-initializer, which throws an Objective-C exception (not a Swift error) on unrecognized strings — there is no defensive fallback. The canonical form for heart-rate-variability SDNN is `HKUnit.secondUnit(with: .milli)`, already used correctly in `MockHealthKitClient.createMockHeartRateVariability` (line 621). Because Swift cannot catch Objective-C exceptions raised by `HKUnit`'s initializer without bridging, any parsing change in HealthKit would crash the app at first HRV read. The string `"ms"` is also ambiguous — HealthKit's unit parser distinguishes `ms` as milliseconds but historically has had edge cases with SI-prefixed units.

**Fix:**

```swift
hrvMs = latest.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
```

## Warnings (HIGH)

### WR-01: Multiple force unwraps violate `force_unwrapping` SwiftLint rule

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/InputBarRow.swift:41, 44, 57, 87`
**Issue:** `subScore!` force-unwrap appears four times. Although guarded by `isMissing = subScore == nil`, that local is computed from `subScore` at view-construction time — if the property is reassigned between checks and usage (e.g., under rapid state changes during animation), the check and unwrap can diverge. More importantly, `.swiftlint.yml` enables `force_unwrapping` as an opt-in rule, so this produces lint failures and violates project conventions.

**Fix:** Use `if let` or nil-coalesce:

```swift
if let score = subScore {
    Text("\(score)")
        .font(AppTheme.Typography.monoLarge)
        .foregroundColor(AppTheme.recoveryColor(for: score))
} else {
    Text("\u{2014}")
        .font(AppTheme.Typography.monoLarge)
        .foregroundColor(AppTheme.Text.secondary)
}
```

Apply the same pattern to the progress bar fill and accessibility label.

---

### WR-02: Force unwrap in `TrainingLoadScorer.score`

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift:26`
**Issue:** `let currentWeek = sorted.last!` force-unwraps after `summaries.count >= 2` guard. Safe today because `sorted.count == summaries.count >= 2`, but the guard check and the unwrap are separated by a `sorted` step; a future refactor that filters `sorted` could invalidate the invariant. Violates the `force_unwrapping` SwiftLint rule.

**Fix:**

```swift
guard summaries.count >= 2, let currentWeek = summaries.sorted(by: { $0.weekStartDate < $1.weekStartDate }).last else {
    return (75, "Insufficient training history — moderate default")
}
let sorted = summaries.sorted { $0.weekStartDate < $1.weekStartDate }
let priorWeeks = Array(sorted.dropLast())
```

---

### WR-03: Force unwrap in `HealthKitClient.fetchSamples`

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift:384`
**Issue:** `sortDescriptor != nil ? [sortDescriptor!] : nil` pattern force-unwraps despite there being a safe idiomatic form. Violates `force_unwrapping` lint rule.

**Fix:**

```swift
sortDescriptors: sortDescriptor.map { [$0] }
```

---

### WR-04: `ISO8601DateFormatter` created per-instance in record init default argument

**File:** `SundeeFundee/Sources/SundeeFundeeKit/Models/RecoveryScoreRecord.swift:53`
**Issue:** `dateCreated: String = ISO8601DateFormatter().string(from: Date())` evaluates a fresh `ISO8601DateFormatter()` every time the default is used. `ISO8601DateFormatter` is expensive to initialize (hundreds of microseconds). For a model that may be instantiated frequently (score history load = 30+ records), this is wasteful. More importantly, default argument expressions are evaluated at each call site — behavior is correct but opaque. The formatter is also created twice more inside `RecoveryScoreViewModel` (`loadHistory`, `persistScore`).

**Fix:** Use a shared static formatter, preferably an `ISO8601DateFormatter` constant on the type:

```swift
public struct RecoveryScoreRecord: Codable, Sendable, Identifiable {
    // Shared formatter for all date string encoding.
    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    public init(
        id: String = UUID().uuidString,
        scoreDate: String,
        // ...
        dateCreated: String? = nil
    ) {
        // ...
        self.dateCreated = dateCreated ?? Self.iso8601.string(from: Date())
    }
}
```

Note: `ISO8601DateFormatter` is thread-safe for formatting per Apple's documentation, so a static instance is safe.

## Info / Medium

### IN-01: HRV band thresholds and multipliers are uncalibrated magic numbers

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/HRVBaselineNormalizer.swift:22-28, 54-71`
**Issue:** Phase multipliers (`1.0/1.05/0.85/0.90`) and score bands (`20/40/60/80 ms`) are hard-coded without citation. Per research notes, HRV threshold calibration is explicitly listed as a known low-confidence blocker. Population HRV SDNN varies by 2× across age bands (young adults ~60ms median, 60+ ~30ms median). A fixed band labeling 40ms as score 30 will under-score older users across the board.

**Fix:** Add explicit documentation citing the source, and either (a) expose thresholds as injectable parameters for future user-specific calibration, or (b) add a personal baseline (7-day rolling median) subtractor before band scoring. Short-term: add a doc comment:

```swift
/// Thresholds approximate healthy-adult SDNN (2023 literature survey):
/// 80+ excellent, 60-80 good, 40-60 average, 20-40 poor. Calibration pending
/// (see Phase 02 — personal baseline tracking).
```

---

### IN-02: Sleep scoring threshold `7.0` in two places — magic number

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift:64, 122-129`
**Issue:** `7.0` appears both in the score-band switch and in the explanation comparison. If one is ever changed and the other forgotten, the explanation desyncs from the score.

**Fix:** Extract as a constant:

```swift
private enum SleepThreshold {
    static let recommended: Double = 7.0
}
```

Then use `sleep >= SleepThreshold.recommended` in both sites.

---

### IN-03: Recovery recommendation boundaries duplicated across modules

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift:100-104` and `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift:91-97`
**Issue:** Thresholds `70` (pushDay / green) and `40` (moderate / yellow) are duplicated. If one is changed without the other, the score color and recommendation label will desync (e.g., score 68 displayed on green background but labeled "Take It Easy").

**Fix:** Define as a single source of truth on `TrainingRecommendation`:

```swift
public enum TrainingRecommendation: String, Sendable, Equatable {
    case pushDay, moderate, restDay

    public static func from(score: Int) -> TrainingRecommendation {
        switch score {
        case 70...: return .pushDay
        case 40...: return .moderate
        default:    return .restDay
        }
    }
}
```

Then `AppTheme.recoveryColor(for:)` can switch on `TrainingRecommendation.from(score: score)`.

---

### IN-04: Pain score formula `100 - (clamped - 1) * 11` produces uneven distribution

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/PainScorer.swift:20`
**Issue:** Pain intensity 1→100, 2→89, 3→78, ..., 10→1. The documentation says "Intensity 10 → score 1" but the formula is `100 - 9 * 11 = 1`. Fine, but `max(0, ...)` is redundant since the min is 1. More importantly, `11` as a step multiplier is a magic number that is a workaround for 10 intensities mapping to 100 range non-uniformly; `(10 - intensity) * 100 / 9` would be more explicit. Also, intensity values are documented as 1-10, but clamped 1-10 — the lower clamp to 1 silently corrects invalid 0 or negative inputs instead of surfacing the bug.

**Fix:** Use clearer math and consider logging invalid inputs:

```swift
public static func score(intensity: Int) -> (score: Int, explanation: String) {
    guard (1...10).contains(intensity) else {
        // Invalid intensity — return neutral fallback
        return (50, "Pain intensity outside 1-10 range")
    }
    let score = Int(round(Double(10 - intensity) * 100.0 / 9.0))
    return (score, explanationForIntensity(intensity))
}
```

---

### IN-05: `SleepDeduplicator.subtractInterval` parameter order is inverted vs documentation

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SleepDeduplicator.swift:149-152`
**Issue:** Function signature is `subtractInterval(_ source: SleepInterval, from subtract: SleepInterval) -> [SleepInterval]` — reading the English "subtractInterval source from subtract" is counter-intuitive. The doc comment reads: "Subtracts one interval from another, returning the remaining portions. If `subtract` overlaps with `source`, the overlapping portion is removed." The normal English reading of `subtract(A, from: B)` returns `B - A`, but this call site computes `source - subtract` (subtract.start/end carves a hole out of source). The labels are reversed.

**Fix:** Rename to match call-site intent:

```swift
// Before: subtractInterval(interval, from: watch)
// After:
private static func trim(_ source: SleepInterval, removing: SleepInterval) -> [SleepInterval]
// or simpler:
private static func subtract(_ remove: SleepInterval, from source: SleepInterval) -> [SleepInterval]
```

Then the call site reads naturally: `let trimmed = subtract(watch, from: interval)`.

---

### IN-06: `RecoveryScoreViewModel.computePhaseBands` has off-by-one on dayOffset loop

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:195`
**Issue:** The loop `for dayOffset in 0...30` iterates 31 times across `thirtyDaysAgo...today`. This is probably intentional (inclusive both ends), but the final band's endDate is computed as `today + 1 day` which creates an asymmetric half-open interval (startDate inclusive, endDate exclusive). This is fine for `RectangleMark` in Charts, but could cause the last band to appear one day wider than expected. Additionally, when `currentPhase` stays the same for the full 31 days, only one band is appended in the final "Close final band" step — correct behavior, but not exercised by tests according to the summary.

**Fix:** No action required if intentional. Add a test case for the "single-phase, full window" scenario to lock in behavior. Also clarify intent with a comment:

```swift
// Iterate 31 days (inclusive of today) so we include today's phase in a band.
for dayOffset in 0...30 { ... }
```

---

### IN-07: `InputBarRow` animation captures view-initial width that stays stale on rotation

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/InputBarRow.swift:61-67`
**Issue:** `animatedWidth` is computed as `geo.size.width * score / 100.0` inside `.onAppear`. On orientation change (iPad, iPhone rotation) or dynamic-type change that resizes the row, `animatedWidth` will not update. The bar will render at the old width relative to the new parent.

**Fix:** Recompute on geometry change:

```swift
.onAppear {
    animate(width: geo.size.width)
}
.onChange(of: geo.size.width) { _, newWidth in
    animate(width: newWidth)
}

private func animate(width: CGFloat) {
    guard let score = subScore else { return }
    withAnimation(.easeOut(duration: 0.5).delay(animationDelay)) {
        animatedWidth = width * CGFloat(score) / 100.0
    }
}
```

---

### IN-08: `DashboardView.loadProgramInfo` `nextWorkout = "Day \(programs.count + 1)"` is misleading

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:641`
**Issue:** `nextWorkout = "Day \(programs.count + 1)"` uses the count of enrolled programs as a day index, which has no semantic meaning — enrolling in a second program sets `nextWorkout = "Day 3"`. This is a pre-existing issue marked `// Simplified` but now it's wired into the recovery-score dashboard layout and becomes more visible. It's misleading placeholder behavior.

**Fix:** Either (a) compute an actual next-workout day from program state, or (b) hide the line when real data isn't available. Minimum fix: change the comment to `// TODO(phase-02): compute real next-workout from ProgramSchedule` so the intent is explicit.

---

### IN-09: `@preconcurrency HealthClientProtocol` conformance on `HealthKitClient` masks potential violations

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift:24`
**Issue:** `public actor HealthKitClient: @preconcurrency HealthClientProtocol` bypasses Swift 6 strict-concurrency checking for protocol conformance. The `@preconcurrency` is probably unnecessary now that `HealthClientProtocol` is itself `Sendable` and all its async methods are already actor-safe. Leaving `@preconcurrency` hides any future concurrency violations introduced by changes to the protocol or actor.

**Fix:** Remove `@preconcurrency` and verify the build compiles under strict concurrency. If it compiles clean, remove it. If not, file a follow-up to tighten the conformance.

---

### IN-10: `MockHealthKitClient` uses `@unchecked Sendable` with DispatchQueue — could be an `actor`

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockHealthKitClient.swift:33`
**Issue:** `public final class MockHealthKitClient: HealthClientProtocol, @unchecked Sendable` + a serial `DispatchQueue` reimplements what Swift's `actor` already provides. `@unchecked Sendable` opts out of compiler verification. The production `HealthKitClient` is an actor — the mock should be too, for consistency and to reduce the risk of a test-only data race.

**Fix:** Convert to `public actor MockHealthKitClient: HealthClientProtocol` and remove the `queue` / all `queue.sync { ... }` wrappers. The public property setters (`isAvailable`, `authorizationGranted`, `shouldFailQueries`) would then be async but that's acceptable in tests. Alternative lower-cost fix: keep the class but add a doc comment explaining why `@unchecked` is safe (i.e., "all mutable state is guarded by `queue`").

---

### IN-11: CloudKit schema `Challenge` uses reserved `createdAt`/`startDate`/`endDate` as TIMESTAMP

**File:** `SundeeFundeeApp/cloudkit-schema.json:51-71`
**Issue:** Not a Phase-01 regression — the `Challenge` record type violates CLAUDE.md's rule ("Do NOT name model fields `createdAt`, `modifiedAt`, `startDate`, or `endDate`"). It's pre-existing, but the schema was touched in this phase (new `RecoveryScore` record type added at the bottom), so flagging for awareness. The phase-01 `RecoveryScore` record type correctly uses `scoreDate` and `dateCreated`.

**Fix:** No Phase-01 action needed. Out of scope for this review; noted for future phase cleanup.

## Low / Style Nits

### LN-01: `RecoveryScoreCalculator.calculate` has nested ternary that hurts readability

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift:100-104`
**Issue:** Nested ternary for recommendation derivation. Would read more clearly as a switch (see IN-03 fix).

---

### LN-02: `DashboardView.cyclePhaseBanner` has inconsistent indentation

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:155-156`
**Issue:** `NavigationLink(destination: CycleCalendarView()) {` on line 155 starts a block that is under-indented by one level (`ArtDecoCard {` at line 156 is at the same indent as the `NavigationLink`). Likely a copy-paste artifact from a refactor.

**Fix:** Re-indent the `ArtDecoCard` block one level deeper.

---

### LN-03: `Logger` category casing inconsistent

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:6` vs `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:4`
**Issue:** Logger category strings are `"RecoveryScore"` (PascalCase) and `"Dashboard"` (PascalCase). Consistent. But other categories in the codebase mix (`"AppleAuth"`, `"ScreenshotSeeder"` — PascalCase OK; but `"CloudKit"` is also PascalCase — all actually consistent). No change needed; keeping LN-03 as a confirmation.

**Fix:** None — confirmed consistent.

---

### LN-04: `@ViewBuilder` on `coachingInsightsCard` but not on `cyclePhaseBanner`

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:152, 380`
**Issue:** Both are conditional views returning `if let ... else` style content, but only `coachingInsightsCard` has `@ViewBuilder`. `cyclePhaseBanner` currently returns `some View` with an `if let phase` branch and no else — this relies on Swift's implicit empty view for the `nil` case, which works, but the inconsistency is noise.

**Fix:** Add `@ViewBuilder` to `cyclePhaseBanner` for consistency.

---

### LN-05: `RecoveryTrendChart.formatter` allocated per-instance (stored property)

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryTrendChart.swift:18`
**Issue:** `private let formatter = ISO8601DateFormatter()` stored on the view struct means every view re-construction (SwiftUI re-evaluates body frequently) re-allocates the formatter. SwiftUI view structs are cheap, but `ISO8601DateFormatter()` is not — several hundred microseconds per allocation.

**Fix:** Hoist to a static:

```swift
private static let formatter = ISO8601DateFormatter()
```

And reference as `Self.formatter` in `chartContent`.

---

_Reviewed: 2026-04-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
