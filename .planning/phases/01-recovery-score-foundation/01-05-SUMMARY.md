---
phase: 01-recovery-score-foundation
plan: 05
subsystem: ui-dashboard
tags: [recovery-score, dashboard, breakdown, swift-charts, navigation, integration]

# Dependency graph
requires:
  - phase: 01-03
    provides: RecoveryScoreViewModel, RecoveryScoreRecord, phaseBands computation
  - phase: 01-04
    provides: RecoveryScoreCard, InputBarRow, AppTheme.Recovery tokens, CyclePhase chartBandColor/chartBandOpacity
  - phase: existing
    provides: DashboardView, AuthViewModel, CyclePhaseCache, AppTheme, ArtDecoCard
provides:
  - "DashboardView integration: RecoveryScoreCard as hero element with NavigationLink to breakdown"
  - "RecoveryBreakdownView: full-screen detail view with Today's Inputs section and 30-Day Trend section"
  - "RecoveryTrendChart: 30-day line chart with cycle phase background bands and zone gridlines"
  - "Complete recovery score feature wired end-to-end: dashboard -> card -> breakdown -> trend chart"
affects: [dashboard, recovery-flow]

# Tech tracking
tech-stack:
  added: []
patterns:
  - "Navigation hero pattern: NavigationLink wrapping hero ArtDecoCard with .buttonStyle(.plain)"
  - "Lazy history load pattern: breakdown view .task triggers viewModel.loadHistory()"
  - "Multi-layer chart pattern: background bands (RectangleMark) + gridlines (RuleMark) + data (LineMark + PointMark)"

key-files:
  created:
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryBreakdownView.swift
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryTrendChart.swift
  modified:
    - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift

key-decisions:
  - "Load recovery score in both .task and .refreshable so pull-to-refresh recomputes the score alongside other dashboard data"
  - "Hero card placement: directly after welcomeHeader (before cyclePhaseBanner) per D-03 -- recovery score is the primary training decision signal"
  - "Phase bands load lazily in breakdown .task (not dashboard) -- saves dashboard perf since historical query is unused until user drills in"

patterns-established:
  - "Recovery feature navigation: Dashboard NavigationLink -> RecoveryBreakdownView NavigationStack push"
  - "Chart assembly: background decoration layer -> reference lines -> data layer (stacked in Chart{} builder)"

requirements-completed: [REC-01, REC-03, REC-05]

# Metrics
duration: 3min
completed: 2026-04-16
---

# Phase 1 Plan 05: Dashboard Integration and Breakdown Screen Summary

**RecoveryScoreCard wired as dashboard hero with tap-through to a new RecoveryBreakdownView showing 5 input bars and a 30-day SwiftUI Charts trend chart with cycle phase background bands**

## Performance

- **Duration:** ~3 min (Task 1 implementation + build + tests)
- **Started:** 2026-04-16T23:21:35Z
- **Task 1 Completed:** 2026-04-16T23:24:54Z
- **Tasks Completed (auto):** 1 of 3
- **Tasks Pending (checkpoints):** 2 of 3 (both blocking, require human action)
- **Files modified:** 3 (1 modified + 2 created)

## Accomplishments (Task 1 only)

- `DashboardView` now owns a `@StateObject RecoveryScoreViewModel` and renders `RecoveryScoreCard` as the first element after the welcome header, wrapped in a `NavigationLink` that pushes to `RecoveryBreakdownView`.
- `.task` and `.refreshable` both invoke `recoveryScoreViewModel.loadScore(cyclePhase:isGuest:)`, so the score computes on foreground and on pull-to-refresh (D-11).
- `RecoveryBreakdownView` built with two sections: "Today's Inputs" (5 `InputBarRow` via `ForEach RecoveryInput.allCases` with staggered animation delays) and "30-Day Trend" (embedded `RecoveryTrendChart`). Triggers `viewModel.loadHistory()` lazily in `.task`.
- `RecoveryTrendChart` built with SwiftUI Charts: `RectangleMark` phase bands (colored by `CyclePhase.chartBandColor` / `chartBandOpacity`), `RuleMark` dashed gridlines at zone boundaries 40 and 70, `LineMark` for the score trend, `PointMark` with `AppTheme.recoveryColor(for:)` coloring. Empty state uses "Not enough data yet - check back after a few days." Accessibility label summarizes avg/min/max.
- All 86 tests pass; `swift build` succeeds; `xcodebuild -scheme SundeeFundee` for iPhone 17 Pro simulator produces a signed `.app` bundle.

## Task Commits

Each atomic auto task was committed individually:

1. **Task 1: Integrate RecoveryScoreCard into DashboardView and build RecoveryBreakdownView with trend chart** — `7a1d31be` (feat)

### Pending checkpoint tasks (not executed)

2. **Task 2: Visual verification of complete recovery score feature** — `checkpoint:human-verify`, blocking. Requires user to run app in iOS Simulator, sign in with Apple ID, and confirm 15 visual acceptance steps.
3. **Task 3: Add RecoveryScore recordName QUERYABLE index in CloudKit Dashboard** — `checkpoint:human-action`, blocking. Requires user to log into https://icloud.developer.apple.com/dashboard/ and add a QUERYABLE index on `recordName` for the `RecoveryScore` record type.

## Files Created/Modified

- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` — Added `@StateObject recoveryScoreViewModel`, inserted `NavigationLink(destination: RecoveryBreakdownView) { RecoveryScoreCard(...) }` between welcomeHeader and cyclePhaseBanner, added `loadScore` calls in `.task` and `.refreshable`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryBreakdownView.swift` — **Created**. ScrollView containing "Today's Inputs" section (`ForEach` over `RecoveryInput.allCases` with `InputBarRow`), gold-tinted divider, "30-Day Trend" section (embedded `RecoveryTrendChart`). Triggers `viewModel.loadHistory()` in `.task`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryTrendChart.swift` — **Created**. SwiftUI Chart with phase band `RectangleMark` layer, zone-boundary `RuleMark` gridlines, `LineMark` + `PointMark` data layer, `.chartYScale(domain: 0...100)`, week-stride X axis, 0/20/40/60/80/100 Y ticks, empty state, accessibility summary.

## Decisions Made

- **Pull-to-refresh recomputes recovery score.** `.refreshable` now also calls `recoveryScoreViewModel.loadScore`, matching user expectation that pulling down refreshes all dashboard data. Not explicitly in plan — plan only specified `.task` — but refreshable already existed for `viewModel.loadData`, so adding parity was a natural extension.
- **Divider background tint.** Used `AppTheme.Accent.gold.opacity(0.3)` per the UI-SPEC table for section dividers within the breakdown screen (consistent with the dashboard's existing divider usage).
- **Chart axis label font.** Used `AppTheme.Typography.monoLarge` for X and Y axis labels per UI-SPEC ("trend chart axis labels: Typography.monoLarge"). VolumeChart uses `labelSmall` — the recovery chart uses the explicitly specified monoLarge to match UI-SPEC.

## Deviations from Plan

None — Task 1 executed exactly as written in the plan. All code blocks copied faithfully from the `<action>` sections, including imports, struct signatures, availability annotations, and copy strings.

Tasks 2 and 3 were **not executed** — they are human-gated checkpoints that require a person in front of the simulator (Task 2) or logged into the CloudKit web dashboard (Task 3). Per the executor checkpoint protocol for `autonomous: false` plans, these checkpoints surface to the user rather than being auto-approved.

## Issues Encountered

- Worktree base was `26e6144c` (far behind). Performed the hard reset to `577dfaf1` per the orchestrator's `<worktree_branch_check>` block so the plan files and prior-plan source code were present. Reset succeeded on first attempt.
- One pre-existing warning in `ProgramsListView.swift:524` (`immutable value 'pct' was never used`) — **out of scope**. Not caused by this plan's changes. Logged to deferred items (no code change made).

## User Setup Required

**Blocking checkpoints remain.** The following human actions must be completed to finalize this plan:

### Checkpoint 1 — Visual verification (Task 2)

Run the app in iOS Simulator (build already succeeded for iPhone 17 Pro) and verify all 15 acceptance steps listed in the plan:

1. Build and run in iOS Simulator
2. Sign in (or continue as guest)
3. Verify: Guest mode shows "Sign in to unlock Recovery Score" placeholder card at top of dashboard
4. Sign in with Apple ID
5. Verify: Recovery score card is FIRST element after welcomeHeader on dashboard
6. Verify: Score ring shows 0-100 number with color-coded arc
7. Verify: "Push Day" / "Take It Easy" / "Rest Day" label appears below number
8. Verify: Partial data badge "X/5 inputs" shows when applicable
9. Tap the score card
10. Verify: Breakdown screen opens with "Recovery Breakdown" title
11. Verify: 5 input bars visible (missing inputs grayed out with "Enable..." text)
12. Verify: Each bar has icon, label, sub-score, progress bar, explanation
13. Scroll down on breakdown screen
14. Verify: 30-day trend chart section visible (empty state OK if no history)
15. Back button returns to dashboard

Type "approved" to continue or describe any visual/functional issues.

### Checkpoint 2 — CloudKit Dashboard index (Task 3)

Before shipping to TestFlight / Production, add the QUERYABLE index for `recordName` on the `RecoveryScore` record type:

1. Open https://icloud.developer.apple.com/dashboard/
2. Select container: `iCloud.com.sundeefundee.app`
3. Schema > Record Types > RecoveryScore (run app signed-in first if missing to auto-create it)
4. Schema > Indexes > Add index: Record Type = RecoveryScore, Field = recordName, Index Type = QUERYABLE
5. Save
6. (For TestFlight) Schema > Deploy to Production

Without this index, `fetchAll(recordType: "RecoveryScore")` throws `DataError.schemaNotDeployed` per CLAUDE.md CloudKit rules.

Type "done" after completing the CloudKit Dashboard steps.

## Next Phase Readiness

Once checkpoints 1 and 2 are cleared:

- Phase 1 is feature-complete: recovery score computes daily, persists to CloudKit, displays as dashboard hero, drills into breakdown + 30-day trend.
- Downstream phases (Phase 2 deload detection, Phase 3 social sharing) can consume `RecoveryScoreRecord` history and `phaseBands` via the ViewModel's existing public API.

## Known Stubs

None. All UI surfaces are wired to real data sources:

- `RecoveryScoreCard` reads `viewModel.score` (computed from HealthKit + CloudKit via `RecoveryScoreCalculator`)
- `InputBarRow` reads `viewModel.score?.subScores[input]` and `viewModel.score?.explanations[input]`
- `RecoveryTrendChart` reads `viewModel.historicalScores` (30-day CloudKit fetch) and `viewModel.phaseBands` (computed from `PeriodLogRecord` + `CycleSettings` via `computePhaseBands`)

All sources are live. Missing inputs surface as grayed-out states with "Enable..." prompts, not stubbed data.

## Threat Flags

None — this plan only wires existing components and adds a NavigationLink. No new network endpoints, no new auth paths, no new trust boundaries. The `T-01-12` mitigation (Guest guard) is preserved: the existing `RecoveryScoreCard` renders the guest placeholder whenever `authViewModel.isGuest == true`, and `loadScore` returns early for guest users.

## Self-Check: PASSED

**Files verified:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` — FOUND
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryBreakdownView.swift` — FOUND
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryTrendChart.swift` — FOUND

**Commits verified:**
- `7a1d31be` — feat(01-05): integrate RecoveryScoreCard into dashboard, build breakdown view and trend chart — FOUND

**Acceptance criteria (Task 1) all PASS:**
- DashboardView: `@StateObject ... RecoveryScoreViewModel()` ✓
- DashboardView: `NavigationLink(destination: RecoveryBreakdownView(...))` ✓
- DashboardView: `RecoveryScoreCard(` ✓
- DashboardView: `recoveryScoreViewModel.loadScore(` ✓ (2 occurrences: .task + .refreshable)
- RecoveryBreakdownView: `struct RecoveryBreakdownView: View` ✓
- RecoveryBreakdownView: `"Today's Inputs"` ✓
- RecoveryBreakdownView: `"30-Day Trend"` ✓
- RecoveryBreakdownView: `InputBarRow(` ✓
- RecoveryBreakdownView: `RecoveryTrendChart(` ✓
- RecoveryBreakdownView: `.navigationTitle("Recovery Breakdown")` ✓
- RecoveryTrendChart: `struct RecoveryTrendChart: View` ✓
- RecoveryTrendChart: `RectangleMark(` ✓
- RecoveryTrendChart: `LineMark(` ✓
- RecoveryTrendChart: `PointMark(` ✓
- RecoveryTrendChart: `chartBandColor` ✓
- RecoveryTrendChart: `"Not enough data yet"` ✓
- RecoveryTrendChart: `.accessibilityLabel(chartAccessibilityLabel)` ✓
- `swift test` — 86 tests pass
- `swift build` — succeeds
- `xcodebuild -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` — BUILD SUCCEEDED

**Checkpoints outstanding (not self-checkable):**
- Task 2 (human-verify) — requires human in front of Simulator
- Task 3 (human-action) — requires human logged into CloudKit Dashboard

---
*Phase: 01-recovery-score-foundation*
*Completed (partial — Task 1 only): 2026-04-16*
