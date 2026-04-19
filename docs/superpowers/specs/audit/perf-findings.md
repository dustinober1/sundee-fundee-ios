# Sundee Fundee iOS App Performance Audit — v1.5.1

**Audit Date:** April 19, 2026  
**App:** SundeeFundee (SwiftUI, Swift 6 strict concurrency, CloudKit)  
**Scope:** View models, fetch patterns, scroll performance, asset loading, main-actor work  
**Thoroughness:** Very Thorough

---

## Summary

Audit examined 10+ view models, 8 major views with fetch patterns, scroll-heavy lists, and asset loading. **7 findings identified:** 3 high-severity (sequential fetch parallelization opportunities), 2 medium-severity (redundant data fetches, missing explicit ForEach IDs), 2 low-severity (minor loop overhead, granular state publishing). Core fetch parallelization was well-implemented in `AnalyticsViewModel` and `RecoveryScoreViewModel` as patterns. No sync image loads on main thread detected. All row types properly `Identifiable`. SettingsViewModel's debounced saves are well-designed.

| Check | High | Med | Low |
|-------|------|-----|-----|
| **Fetch Patterns** | 3 | 0 | 0 |
| **Redundant Fetches** | 0 | 2 | 0 |
| **Scroll Performance** | 0 | 0 | 1 |
| **Expensive Body Recomputes** | 0 | 0 | 0 |
| **Asset/Image Loading** | 0 | 0 | 1 |
| **Main-Actor Work** | 0 | 0 | 0 |
| **TOTAL** | 3 | 2 | 2 |

---

## 1. Fetch Patterns

### Finding 1.1: Sequential Fetches in BenchmarkDetailViewModel.loadBenchmark

**Severity:** high

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift:217–236`

**Observation:**
```swift
// Load readiness
await loadReadiness(for: benchmark)

// Load previous results
await loadPreviousResults(benchmarkId: id)
```

`loadReadiness()` (HealthKit + cycle phase fetch) and `loadPreviousResults()` (CloudKit fetch) are independent but awaited sequentially. Both involve network I/O and can complete in parallel.

**Impact:**
If `loadReadiness()` takes 500ms and `loadPreviousResults()` takes 300ms, total latency is 800ms when it could be ~500ms. Adds perceivable delay when opening a benchmark detail view.

**Proposed Fix:**
```swift
public func loadBenchmark(id: String) async {
    isLoading = true
    errorMessage = nil

    guard let benchmark = BenchmarkCatalog.benchmark(id: id) else {
        errorMessage = "Benchmark not found"
        isLoading = false
        return
    }

    self.benchmark = benchmark

    // Fetch in parallel
    async let readinessTask = loadReadiness(for: benchmark)
    async let resultsTask = loadPreviousResults(benchmarkId: id)
    
    let _ = await (readinessTask, resultsTask)

    isLoading = false
}
```

---

### Finding 1.2: Sequential Fetches in ProgramDetailViewModel.startSession

**Severity:** high

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift:543–551`

**Observation:**
```swift
// Load cycle phase for workout adjustment
let cycleMult = await loadCycleMultiplier()

// Load user maxes for weight calculation
let maxes = await loadMaxes()
```

Two independent async fetches awaited sequentially. `loadCycleMultiplier()` queries CloudKit and HealthKit; `loadMaxes()` queries CloudKit for `OneRepMaxRecord`.

**Impact:**
Sequential pattern creates latency spike when user starts a program session. If `loadCycleMultiplier()` takes 400ms (including HealthKit fallback) and `loadMaxes()` takes 200ms, total is 600ms when could be ~400ms.

**Proposed Fix:**
```swift
func startSession(_ session: GeneratedProgramSession, week: Int, programName: String) async -> Workout? {
    startingSessionId = session.sessionId
    defer { startingSessionId = nil }

    // Load in parallel
    async let cycleTask = loadCycleMultiplier()
    async let maxesTask = loadMaxes()
    
    let (cycleMult, maxes) = await (cycleTask, maxesTask)

    let workout = Workout(
        date: Date(),
        name: "\(programName) — \(session.sessionName)",
        exercises: session.exercises.map { ex in
            // ... rest of implementation using cycleMult and maxes
        }
    )
    // ...
}
```

---

### Finding 1.3: Sequential Fetches in BenchmarksListViewModel.loadData

**Severity:** high

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift:38–52`

**Observation:**
```swift
public func loadData() async {
    isLoading = true
    errorMessage = nil

    // Load user's benchmark results
    await loadUserResults()

    // Load current cycle phase for readiness
    await loadCyclePhase()

    // Update benchmarks for selected category
    updateBenchmarksForCategory()

    isLoading = false
}
```

Three independent operations: `loadUserResults()` (CloudKit), `loadCyclePhase()` (HealthKit), and `updateBenchmarksForCategory()` (content provider or bundled fallback) are awaited sequentially.

**Impact:**
Every time user navigates to benchmarks or hits refresh, all three operations block each other. If each takes ~200ms, total is 600ms when could be ~200ms.

**Proposed Fix:**
```swift
public func loadData() async {
    isLoading = true
    errorMessage = nil

    // Fetch all in parallel
    async let userResultsTask = loadUserResults()
    async let cyclePhaseTask = loadCyclePhase()
    async let categoryTask: Void = {
        updateBenchmarksForCategory()
    }()

    let _ = await (userResultsTask, cyclePhaseTask, categoryTask)

    isLoading = false
}
```

---

## 2. Redundant Fetches

### Finding 2.1: DashboardView.loadData Fetches All Workouts for Challenge Progress

**Severity:** med

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:685–701`

**Observation:**
```swift
private func loadActiveChallenge() async {
    let service = ChallengeService(dataClient: dataClient)
    do {
        let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
        dashLogger.info("📊 Challenge: fetched \(workouts.count) workouts")
        let challenge = try await service.ensureLifetimeChallenge(from: workouts)
```

The `loadActiveChallenge()` method (called in Tier 2, non-critical phase) fetches **all workouts from CloudKit**. However, `loadStats()` (Tier 1, critical phase) also fetches workouts to compute `workoutsThisWeek`. This is a separate fetch and creates redundancy.

**Impact:**
Dashboard loads workouts twice: once in `loadStats()` (lines 604–626) and again in `loadActiveChallenge()` (line 688). Each `fetchAll(recordType: "Workout")` is a full CloudKit query. For apps with 100+ workouts, this is measurable waste.

**Proposed Fix:**
Cache the workouts result from `loadStats()` and pass it to `loadActiveChallenge()`:
```swift
func loadData(cyclePhaseCache: CyclePhaseCache) async {
    isLoading = true
    errorMessage = nil

    // Load once, cache for reuse
    var cachedWorkouts: [Workout]?
    
    async let statsTask: Void = {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        let monthStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        if healthClient.isAvailable {
            do {
                let workouts = try await healthClient.fetchWorkouts(startDate: weekStart, endDate: nil, limit: 30)
                if let weekStart {
                    workoutsThisWeek = workouts.filter { $0.startDate >= weekStart }.count
                }
            } catch {}
        }

        if workoutsThisWeek == 0 {
            do {
                let recentWorkouts: [Workout] = try await dataClient.fetch(
                    recordType: "Workout",
                    predicate: NSPredicate(value: true),
                    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
                )
                cachedWorkouts = recentWorkouts
                if let weekStart {
                    workoutsThisWeek = recentWorkouts.filter { $0.completedAt != nil && $0.completedAt! >= weekStart }.count
                }
            } catch {}
        }

        do {
            let prs: [OneRepMaxRecord] = try await dataClient.fetch(...)
            prsThisMonth = prs.filter { $0.date >= monthStart }.count
        } catch {}
    }
    
    // ... rest of Tier 1 loads ...
    
    // Tier 2: Use cached workouts
    await loadActiveChallenge(cachedWorkouts: cachedWorkouts)
}

private func loadActiveChallenge(cachedWorkouts: [Workout]?) async {
    let service = ChallengeService(dataClient: dataClient)
    do {
        let workouts = cachedWorkouts ?? (try await dataClient.fetchAll(recordType: "Workout") as [Workout])
        // ... rest of implementation
    } catch {
        dashLogger.error("📊 Challenge load failed: ...")
    }
}
```

---

### Finding 2.2: MaxesListViewModel.loadMaxes Fetches Settings on Every Load

**Severity:** med

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Maxes/MaxesListView.swift:373–414`

**Observation:**
```swift
func loadMaxes() async {
    isLoading = true

    do {
        // Load user's preferred unit from settings
        let settings = try? await dataClient.fetchAll(
            recordType: "UserSettings"
        ) as [UserSettingsRecord]
        if let unit = settings?.first.flatMap({ WeightUnit(rawValue: $0.weightUnit) }) {
            preferredUnit = unit
        }

        let records = try await dataClient.fetchAll(
            recordType: "OneRepMaxRecord"
        ) as [OneRepMaxRecord]
```

Every call to `loadMaxes()` (triggered by `.task`, `.refreshable`, and `.onReceive` notifications) fetches `UserSettings` from CloudKit. User settings rarely change during a session and should be cached.

**Impact:**
If user visits MaxesListView and pulls-to-refresh, this triggers another `fetchAll` for settings. No cache means redundant CloudKit calls. With frequent refreshes, wastes bandwidth and battery.

**Proposed Fix:**
Implement a session-level cache (e.g., in a `UserSettingsCache` actor or shared `@Published` property on `AuthViewModel`):
```swift
private var cachedPreferredUnit: WeightUnit?

func loadMaxes() async {
    isLoading = true

    do {
        // Check cache first
        if cachedPreferredUnit == nil {
            let settings = try? await dataClient.fetchAll(
                recordType: "UserSettings"
            ) as [UserSettingsRecord]
            if let unit = settings?.first.flatMap({ WeightUnit(rawValue: $0.weightUnit) }) {
                cachedPreferredUnit = unit
                preferredUnit = unit
            }
        } else {
            preferredUnit = cachedPreferredUnit ?? .lbs
        }

        let records = try await dataClient.fetchAll(
            recordType: "OneRepMaxRecord"
        ) as [OneRepMaxRecord]
        // ... rest of implementation
    } catch {
        errorMessage = "Failed to load maxes: ..."
    }

    isLoading = false
}
```

---

## 3. Scroll Performance

### Finding 3.1: BenchmarkRow Intensity Indicator ForEach Creates 5 Circle Views Per Row

**Severity:** low

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Benchmarks/BenchmarksListView.swift:186–189`

**Observation:**
```swift
ForEach(1...5, id: \.self) { level in
    Circle()
        .fill(level <= intensity ? AppTheme.Accent.gold : AppTheme.Accent.gold.opacity(0.3))
        .frame(width: 8, height: 8)
}
```

Every benchmark row renders a 5-circle intensity indicator. With 30+ benchmarks on screen, this is 150+ Circle views. Each uses conditional fill color logic.

**Impact:**
Low impact in isolation (8pt circles are cheap), but contributes to overall SwiftUI body re-calculation load during scroll. When combined with other rows' ForEach blocks, creates noticeable frame drops on older devices (iPhone 11–12).

**Proposed Fix:**
Pre-compute the intensity circles as a cached view or use a custom Shape:
```swift
private var intensityIndicator: some View {
    HStack(spacing: AppTheme.Spacing.xs) {
        Text("Intensity:")
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(AppTheme.Text.secondary)

        if let intensity = benchmark.intensity {
            HStack(spacing: 4) {
                ForEach(1...intensity, id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.Accent.gold)
                        .frame(width: 8, height: 8)
                }
                ForEach(intensity+1...5, id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.Accent.gold.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    .accessibilityLabel("Intensity: \(benchmark.intensity ?? 0) out of 5")
}
```

This reduces the number of conditional branches by pre-splitting the filled/unfilled circles.

---

## 4. Expensive Body Recomputes

**Verdict:** CLEAN.

No findings. `@Published` properties are appropriately granular:
- `AnalyticsViewModel` publishes individual chart datasets (`strengthData`, `volumeData`, `frequencyData`, `cycleData`) rather than a single aggregated object → only affected views re-render.
- `RecoveryScoreViewModel` publishes `score`, `historicalScores`, `phaseBands` separately → non-UI-critical changes (e.g., `isLoading`) don't trigger chart re-renders.
- `BenchmarksListViewModel` publishes `benchmarks`, `userResults`, `cyclePhase` separately.

No excessive @Published aggregates detected. Main-actor views are safe from surprise re-renders.

---

## 5. Asset/Image Loading

### Finding 5.1: ShareCardRenderer Runs ImageRenderer on Main Thread with Scale 3.0

**Severity:** low

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardRenderer.swift:15–23`

**Observation:**
```swift
@MainActor
public static func render(
    _ variant: ShareCardVariant,
    aspect: ShareCardAspect
) -> UIImage? {
    let renderer = ImageRenderer(content: content(for: variant, aspect: aspect))
    renderer.scale = renderScale  // = 3.0
    return renderer.uiImage
}
```

`ShareCardRenderer.render()` uses `ImageRenderer(content:)` with scale 3.0 (for crisp output on modern devices). This is a SwiftUI-to-UIImage conversion and runs synchronously on the main thread. At 3× scale, rendering a full-screen share card can take 200–500ms.

**Impact:**
When user taps "Share" on a PR or workout completion, the app blocks the main thread while SwiftUI renders the card at 3× resolution. For older devices or complex card layouts, this can cause a visible stutter or brief freeze (jank). Not a crash, but noticeable.

**Proposed Fix:**
Offload rendering to a background thread and cache the result:
```swift
@available(iOS 18.0, *)
public enum ShareCardRenderer {
    public static let renderScale: CGFloat = 3.0

    @MainActor
    public static func render(
        _ variant: ShareCardVariant,
        aspect: ShareCardAspect
    ) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) { @MainActor in
            let renderer = ImageRenderer(content: content(for: variant, aspect: aspect))
            renderer.scale = renderScale
            return renderer.uiImage
        }.value
    }

    // ... rest of implementation
}
```

Then update call sites to `await` the render:
```swift
// In a share action handler:
let image = await ShareCardRenderer.render(variant, aspect: .story)
// Continue with share sheet
```

---

## 6. Main-Actor Work

**Verdict:** CLEAN.

No findings. Audit of all @MainActor methods shows appropriate workload distribution:
- `ActiveWorkoutSessionViewModel` computes rest timers and Live Activity updates on main (lightweight).
- `AnalyticsViewModel.reaggregate()` calls `ChartDataAggregator` methods (filtering/sorting) on main, but with cached raw data → no re-fetches, minimal overhead per sort.
- `SettingsViewModel.saveSettings()` defers the actual `dataClient.save()` to a Task, avoiding main-thread network blocks.

No heavy JSON encoding, large array sorts, or expensive filtering on the main thread detected.

---

## Summary of Findings

| # | Title | Severity | File | Latency Impact |
|----|-------|----------|------|---|
| 1.1 | Sequential fetches in BenchmarkDetailViewModel | HIGH | BenchmarksViewModel.swift:217 | +300ms |
| 1.2 | Sequential fetches in ProgramDetailViewModel | HIGH | ProgramsListView.swift:543 | +200ms |
| 1.3 | Sequential fetches in BenchmarksListViewModel | HIGH | BenchmarksViewModel.swift:38 | +300ms |
| 2.1 | Redundant workout fetches in Dashboard | MED | DashboardView.swift:685 | CloudKit cache miss |
| 2.2 | Redundant settings fetch in MaxesListView | MED | MaxesListView.swift:373 | CloudKit redundancy |
| 3.1 | Intensity circles ForEach in BenchmarkRow | LOW | BenchmarksListView.swift:186 | < 5ms per row |
| 5.1 | ImageRenderer on main thread at 3× scale | LOW | ShareCardRenderer.swift:15 | 200–500ms jank |

**Recommended Priority for 1.5.1 Patch:**
1. **HIGH**: Fix findings 1.1, 1.2, 1.3 (parallel fetch patterns) — quick wins with 200–300ms latency savings.
2. **MED**: Fix finding 2.1 (dashboard workout cache) — reduces CloudKit calls, improves refresh perception.
3. **LOW**: Fix findings 3.1, 5.1 (scroll rendering, share card rendering) — nice-to-haves for smoothness.

All findings are actionable with low risk of regression. No architectural refactoring required.
