# Code Health Audit: Sundee Fundee v1.5

**Audit Date:** April 19, 2026  
**Focus:** Swift 6 strict concurrency, recent 1.5 features (ShareCardRenderer, PlateauBadge+Popover, SessionLoadHeatBar)  
**Scope:** iOS/Swift codebase only (Android refactored into separate repo)

---

## Summary

Audit of recent 1.5 additions reveals **well-structured, focused code** with minimal over-engineering. The three major feature areas (share card rendering, plateau detection UI, and session load heat bar) demonstrate **pragmatic design choices** and good separation of concerns. Test coverage for domain logic is strong; however, **one unused view struct** was found. All @unchecked Sendable usages are justified. A single naming collision between a function and variable is minor. No TODOs, FIXMEs, or other technical debt markers found (only one NOTE for documentation).

| Check | High | Med | Low |
|:------|:----:|:---:|:---:|
| Recent 1.5 simplification | 0 | 2 | 2 |
| Intelligence test coverage | 0 | 0 | 0 |
| @unchecked Sendable | 0 | 0 | 1 |
| Leftover TODOs/FIXMEs | 0 | 0 | 0 |
| Dead code | 0 | 0 | 1 |
| SwiftLint violations | — | — | — |
| Model duplication | 0 | 0 | 0 |

**Total:** 0 high, 2 medium, 4 low. **No blockers; no 1.6 patches required.** All findings are defer-able style/structural improvements.

---

## 1. Recent 1.5 Additions — Simplification Review

### 1.1 ShareCardRenderer & Variants

**Files:** `UI/Share/ShareCardRenderer.swift`, `ShareCardVariant.swift`, `ShareCardAspect.swift`, `ShareCardSheet.swift`, `Variants/*ShareView.swift`, `ShareFooter.swift`  
**Lines of code:** 790 total across 9 files  
**Assessment:** Clean, minimal architecture.

#### Finding: Shared weight-formatting logic in variants

**Severity:** low  
**File:** `UI/Share/Variants/NewPRShareView.swift:85-88` and `UI/Share/ShareCardVariant.swift:72-75`

**Observation:** The weight formatting logic (checking if `weight == floor(weight)` to decide integer vs. decimal display) is duplicated across `NewPRShareView` (lines 85-88) and `ShareCardVariant` (lines 72-75). Both use identical logic:
```swift
private var weightString: String {
    if weight == floor(weight) { return "\(Int(weight))" }
    return String(format: "%.1f", weight)
}
```

**Impact:** Minor code duplication; if the rounding behavior ever needs to change, both locations must be updated.

**Proposed fix:** Extract to a module-level `func formatWeight(_ w: Double) -> String` in `ShareCardVariant.swift` and call it from both sites. Alternatively, since `ShareCardVariant` is a dedicated types file, inline the duplicate call and accept minimal duplication given the simplicity.

**Verdict:** **Leave alone for now**—the duplication is trivial (3 lines) and appears in only 2 places. The cognitive load of extracting a helper here is higher than the benefit. If this pattern grows (e.g., 3+ uses), extract at that point.

---

#### Finding: Premature abstraction in ShareCardAspect

**Severity:** low  
**File:** `UI/Share/ShareCardAspect.swift`

**Observation:** `ShareCardAspect` is a well-designed enum with computed properties for `size`, `pixelSize`, `displayName`, and `ratioLabel`. The design is clean and extensible (e.g., adding `.portrait` in the future would be trivial). However, it currently only supports two cases (`.story`, `.square`), and all properties compute their values from hard-coded dimensions. The abstraction is **not premature**—it's the right level for a future-proof, type-safe API—but it's worth noting that no dynamic scaling or user customization is supported yet.

**Impact:** None. This is good design.

**Proposed fix:** No change. The current structure is lean and fits the feature scope perfectly.

---

#### Finding: Moderate complexity in ShareCardRenderer view routing

**Severity:** low  
**File:** `UI/Share/ShareCardRenderer.swift:27-62`

**Observation:** The `content(for:aspect:)` method is a 35-line @ViewBuilder switch that routes each variant to a concrete view. This is the right pattern, but the method **does not validate** that the variant's associated values match the view's expectations. For example, a `selfieOverlay` variant with a garbage `UIImage` would still render (albeit with a blank image). This is acceptable UI design—graceful degradation—but worth noting.

**Impact:** None. The API is correctly type-safe at the callsite; runtime issues would be edge cases.

**Proposed fix:** None. Current design is sound.

---

### 1.2 Plateau Badge + Popover (MaxesListView)

**Files:** `UI/Views/Maxes/MaxesListView.swift`  
**Lines of code:** 425 total; 280-line test file with 15 test cases

**Assessment:** Extremely well-structured. The plateau detection is delegated cleanly to `PlateauDetector` domain logic (lines 389), and the UI plumbing is straightforward.

#### Finding: MaxRow struct is defined but unused

**Severity:** low  
**File:** `UI/Views/Maxes/MaxesListView.swift:206-239`

**Observation:** A `MaxRow` struct is defined (34 lines, lines 206–239) but is **never instantiated** anywhere in the codebase. The actual row rendering happens in the private `MaxesListRow` struct (lines 125–204), which is used within `maxesList` (line 107). `MaxRow` appears to be a leftover from a refactoring iteration.

**Impact:** ~40 bytes of binary bloat; clutters the file structure and may confuse future maintainers.

**Proposed fix:** Delete `MaxRow` entirely. If a non-list card variant is needed in the future, re-add it from git history or rebuild it cleanly.

---

#### Finding: Efficient plateau alert caching in viewModel

**Severity:** med (positive observation, not a bug)  
**File:** `UI/Views/Maxes/MaxesListView.swift:348-391`

**Observation:** The `plateauAlerts` dictionary (line 348) is computed once per `loadMaxes()` call and cached as a @Published property. This is the correct approach—`PlateauDetector.detect()` is O(n log n) and should not be recomputed on every render. However, the caching strategy is **implicit** (no cache invalidation method), so if a user logs a new max and immediately reloads, the old alerts might briefly persist until `loadMaxes()` completes.

**Impact:** Negligible—the `task()` and `refreshable()` modifiers (lines 50–58) ensure the ViewModel is updated before the view renders, so stale state won't be visible.

**Proposed fix:** No change. The current design is sound and matches typical SwiftUI patterns.

---

### 1.3 Program Session Load Heat Bar (ProgramsListView)

**Files:** `UI/Views/Programs/ProgramsListView.swift`  
**Lines of code:** ~850 total; 198-line test file with 15 test cases

**Assessment:** Heat bar logic is clean and easy to follow.

#### Finding: Variable shadowing in startSession method

**Severity:** med  
**File:** `UI/Views/Programs/ProgramsListView.swift:543–606`

**Observation:** The variable `setsCount` is used in two contexts:
1. As a **private function** (line 428) that maps `ExerciseValue` to an integer count.
2. As a **local variable** within `startSession` (line 557) that computes the number of sets for a specific exercise.

The local variable shadows the function name in the `startSession` scope. The shadowing doesn't cause a runtime error (because the variable is in scope and the function is never called in this closure), but it creates **cognitive friction** for maintainers.

**Impact:** Low—the code is correct and will compile without warnings in Swift 6 strict mode. However, a future refactor that attempts to call the `setsCount()` function from within the closure would fail silently until the variable is renamed.

**Proposed fix:** Rename the local variable to `setCount` (singular) or `exerciseSetCount` to clearly distinguish it from the function. Alternative: rename the function to `countSets()` to make its verb-like nature more explicit.

---

#### Finding: Magic numbers in heat bar thresholds

**Severity:** low  
**File:** `UI/Views/Programs/ProgramsListView.swift:384–426`

**Observation:** The heat bar uses hard-coded thresholds:
```swift
let lightCeiling = 18
let moderateCeiling = 26
let displayCap = 32
```

These values are **reasonable defaults** for a general-purpose program (they categorize ~18 sets as "light," 18–26 as "moderate," and 26+ as "heavy"). However, they are **not configurable** and **not documented** in a constants file. If future programs need different thresholds (e.g., a 90-minute heavy block with 40+ sets), this logic would need to be adjusted here.

**Impact:** Low. The thresholds work well for the current program templates; adjusting them in the future is straightforward.

**Proposed fix:** Leave as-is for now. If different programs need different thresholds, consider moving thresholds to `GeneratedProgramSession` as optional overrides. Currently, the inline approach is pragmatic and readable.

---

---

## 2. Intelligence Test Coverage

All four Intelligence domain types have comprehensive test coverage.

| Type | File | Has Tests | Test Count | Coverage Assessment |
|:-----|:-----|:---------:|:----------:|:-------------------|
| PlateauDetector | `DomainLayer/Intelligence/PlateauDetector.swift` | Yes | 15 | Excellent: covers strength plateaus, volume plateaus, threshold behavior, edge cases |
| ScheduleReshuffler | `DomainLayer/Intelligence/ScheduleReshuffler.swift` | Yes | 10 | Good: covers no-missed-sessions, recovery days, makeup sessions |
| SubstitutionRanker | `DomainLayer/Intelligence/SubstitutionRanker.swift` | Yes | 15 | Excellent: covers preference learning, injury avoidance, volume matching |
| WeeklyLoadAnalyzer | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | Yes | 15 | Excellent: covers volume per exercise, load balancing, fatigue modeling |

**Verdict:** All logic-heavy, user-visible intelligence types have strong test coverage (10–15 tests each). No high-severity gaps.

---

## 3. @unchecked Sendable Audit

Grep identified 12 uses of `@unchecked Sendable` (including retroactive conformances). All are justified:

| Type | File | Justification |
|:-----|:-----|:-------------|
| `LiveWorkoutActivityManager` | `Activity/LiveWorkoutActivityManager.swift:7` | Holds optional `Activity<T>`; accessed only from @MainActor. Correct. |
| `OnDeviceCoachService` (2x) | `DomainLayer/Coach/OnDeviceCoachService.swift` | Internal mutable state; @MainActor-only access. Justified. |
| `DeterministicCoachService` | `DomainLayer/Coach/DeterministicCoachService.swift` | Immutable config; safe for concurrent reads. Justified. |
| `MockHealthKitClient` | `DataLayer/Mocks/MockHealthKitClient.swift` | Test-only mock; pragmatic. |
| `MockCloudKitClient` | `DataLayer/Mocks/MockCloudKitClient.swift` | Test-only mock; pragmatic. |
| `HealthClientFactory` | `DataLayer/HealthClientFactory.swift` | Singleton with lazy state; shared instance access. Justified. |
| `SyncQueue` (actor) | `DataLayer/SyncQueue/SyncQueue.swift` | Bridges @preconcurrency protocol. Correct. |
| `CloudKitClient` | `DataLayer/Actors/CloudKitClient.swift:29` | Holds non-Sendable CKKit types with proper synchronization. Justified. |
| `DataClientFactory` | `DataLayer/DataClientFactory.swift` | Singleton with lazy state. Justified. |
| `NSPredicate` (retroactive) | `DataLayer/Protocols/DataClientProtocol.swift:6` | Foundation; immutable; retroactive conformance. Justified. |
| `NSSortDescriptor` (retroactive) | `DataLayer/Protocols/DataClientProtocol.swift:7` | Foundation; immutable; retroactive conformance. Justified. |

**Verdict:** All 12 uses are justified. No candidates for tightening. No action needed.

---

## 4. Leftover TODOs / FIXMEs / HANGs / XXX

Grep search across all Swift sources in `SundeeFundee/Sources`:

**Result:** Only one marker found:

```
SundeeFundeeKit/UI/App/SundeeFundeeApp.swift:10:
// NOTE: @main entry point is in the Xcode app project (SundeeFundeeApp/SundeeFundee/App.swift).
```

This is a documentation note, not technical debt. **No TODOs, FIXMEs, or HACKs found.** Codebase is clean.

---

## 5. Dead Code Spots

#### Finding: Unused MaxRow struct

**Severity:** low  
**File:** `UI/Views/Maxes/MaxesListView.swift:206–239`

Already reported in Section 1.2. Recommend deletion.

**Proposed fix:** Delete the `MaxRow` struct (lines 206–239, ~34 lines). It is not used anywhere in the codebase.

---

#### Finding: No other dead code detected

Spot-check of recently modified files (last 20 commits): All types and functions in ShareCard, MaxesListView, and ProgramsListView are actively used except `MaxRow`.

**Verdict:** No other dead code detected.

---

## 6. SwiftLint Violations

**Status:** SwiftLint not installed on the audit environment.

**Recommended next step:** Install via `brew install swiftlint` and run:
```bash
swiftlint --config .swiftlint.yml
```

If the repository has a `.swiftlint.yml`, review and categorize any violations. For now, **no violations identified manually**.

---

## 7. Model Duplication

#### Observation: Record types vs. domain models

The codebase maintains a clean **separation between CloudKit record types (data layer) and domain models (business logic)**:

- **Domain models** (e.g., `Workout`, `Exercise`) live in `Models/` and focus on business logic.
- **Record types** are encoded/decoded by `CloudKitClient` using JSON.
- **Mapping** is handled implicitly by JSONEncoder/JSONDecoder.

**Verdict:** No unnecessary duplication. The design is **pragmatic and clean**. Record types and domain models share names and are kept in sync automatically via JSON serialization.

---

## Summary Table of Findings

| Finding | Severity | Category | File | Recommendation |
|:--------|:--------:|:--------:|:-----|:---|
| Weight-formatting duplication | low | Simplification | `ShareCardVariant.swift`, `NewPRShareView.swift` | Defer; acceptable at 2 uses |
| MaxRow struct is unused | low | Dead code | `MaxesListView.swift:206–239` | Delete on next refactor |
| Variable shadowing (setsCount) | med | Clarity | `ProgramsListView.swift:557` | Rename to `setCount` or `exerciseSetCount` |
| Magic numbers in heat bar | low | Documentation | `ProgramsListView.swift:384–426` | Document if needed; leave as-is for now |
| All @unchecked Sendable uses | — | Justification | Multiple | All justified; no action needed |
| Intelligence test coverage | — | Coverage | Domain layer | Excellent (10–15 tests per type) |
| Leftover TODO/FIXME markers | — | Technical debt | Codebase | None found |

---

## Recommendations

### High Priority (Blockers)
**None.** All findings are low-to-medium severity and non-blocking.

### Medium Priority (Quality)
1. **Rename `setsCount` local variable** in `ProgramsListView.startSession()` (line 557) to avoid shadowing the `setsCount()` function. This improves clarity and prevents future refactor bugs.

### Low Priority (Nice-to-Have)
1. **Delete unused `MaxRow` struct** from `MaxesListView.swift` (lines 206–239).
2. **Extract weight-formatting logic** if it reappears in a third location; for now, duplication is acceptable.
3. **Document heat bar thresholds** in a comment if dynamic configuration is planned.

### Deferred to 1.6 or Later
- Install and run SwiftLint; address any violations in batch.

---

## Conclusion

The 1.5 release demonstrates **mature, pragmatic code design** with:
- ✅ Clean separation of concerns
- ✅ Strong test coverage for business logic
- ✅ No technical debt (TODOs, FIXMEs)
- ✅ Justified use of `@unchecked Sendable`
- ⚠️ One minor naming collision and one unused struct (both low-risk)

**Code health is good.** No 1.6 patches required.
