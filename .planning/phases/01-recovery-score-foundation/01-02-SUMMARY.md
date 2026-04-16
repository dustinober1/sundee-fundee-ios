---
phase: 01-recovery-score-foundation
plan: 02
subsystem: healthkit
tags: [healthkit, sleep-analysis, deduplication, tdd, domain-layer]

# Dependency graph
requires:
  - phase: none
    provides: "Standalone — extends existing HealthClientProtocol and adds new domain module"
provides:
  - "HealthClientProtocol.fetchSleepAnalysis and fetchRecentSleepAnalysis"
  - "HealthKitClient sleep analysis query implementation"
  - "MockHealthKitClient sleep mock data support with createMockSleepSample factory"
  - "SleepDeduplicator pure domain function with Watch-priority interval subtraction"
  - "SleepDeduplicator.convertSamples bridge from HealthKit data to domain types"
  - "SleepStage, SleepSource, SleepInterval domain types"
affects: [01-03, 01-04, 01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Interval merge with source-priority subtraction: merge overlapping intervals per source, then subtract higher-priority (Watch) from lower-priority (Phone) to avoid double-counting"
    - "Bridge pattern: convertSamples decouples HealthKit HKCategorySample from pure domain SleepInterval"

key-files:
  created:
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SleepDeduplicator.swift
    - SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SleepDeduplicatorTests.swift
  modified:
    - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/HealthClientProtocol.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockHealthKitClient.swift

key-decisions:
  - "Watch-priority subtraction: instead of removing Phone intervals that overlap Watch, trim them so non-overlapping portions still count toward total sleep"
  - "convertSamples uses source name string matching (contains 'watch') to classify device source"

patterns-established:
  - "Sleep deduplication: filter sleep stages -> sort -> merge per source -> subtract Watch from Phone -> sum remaining"
  - "HealthKit fetch pattern for category types: mirror fetchMenstrualCycles with .sleepAnalysis type"

requirements-completed: [HK-01, HK-02, HK-03]

# Metrics
duration: 13min
completed: 2026-04-16
---

# Phase 1 Plan 02: Sleep Analysis Integration Summary

**HealthKit sleep fetch with Watch+Phone deduplication algorithm using interval subtraction, plus full mock support and 7 TDD tests**

## Performance

- **Duration:** 13 min
- **Started:** 2026-04-16T01:32:22Z
- **Completed:** 2026-04-16T01:45:33Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Extended HealthClientProtocol with fetchSleepAnalysis and fetchRecentSleepAnalysis convenience method
- Implemented SleepDeduplicator pure domain algorithm: filters non-sleep stages, merges overlapping intervals per source, subtracts Watch from Phone intervals, sums deduplicated total
- Added full MockHealthKitClient sleep support including createMockSleepSample factory for testing
- Full test suite green (86 tests, 0 failures)

## Task Commits

Each task was committed atomically:

1. **Task 1: Write SleepDeduplicator tests and stub, extend HealthClientProtocol** - `d05a6cd7` (test) -- TDD RED gate
2. **Task 2: Implement SleepDeduplicator, HealthKitClient sleep fetch, and MockHealthKitClient sleep support** - `8bc50bbb` (feat) -- TDD GREEN gate

_Note: TDD tasks have multiple commits (test -> feat)_

## Files Created/Modified
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/SleepDeduplicator.swift` - Pure domain sleep deduplication with SleepInterval, SleepSource, SleepStage types and convertSamples bridge
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SleepDeduplicatorTests.swift` - 7 test cases covering empty input, single source, identical overlap, partial overlap, stage filtering, mixed stages, non-overlapping segments
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/HealthClientProtocol.swift` - Added fetchSleepAnalysis protocol requirement and fetchRecentSleepAnalysis convenience
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift` - Added fetchSleepAnalysis implementation querying .sleepAnalysis, added to standardReadTypes
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockHealthKitClient.swift` - Added mockSleepAnalysis storage, fetchSleepAnalysis, set/add helpers, createMockSleepSample factory, sleep cleanup in reset()

## Decisions Made
- **Watch-priority interval subtraction**: Instead of removing Phone intervals that overlap with Watch intervals entirely, the algorithm trims Phone intervals to only keep the portions outside the Watch range. This ensures no sleep time is lost when both sources record overlapping data.
- **Source classification via string matching**: `convertSamples` classifies source as `.watch` if the source name contains "watch" (case-insensitive), otherwise `.phone`. This matches Apple's naming convention for Apple Watch sources.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed partial overlap deduplication producing incorrect total**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** Initial algorithm removed non-Watch intervals that overlapped with Watch intervals entirely, losing the non-overlapping portions. For Watch 11pm-5am and Phone 10pm-6am, result was 6h instead of 8h.
- **Fix:** Changed Step 5 from filter-remove to subtract-trim. Added `subtractInterval` helper that carves out the Watch portion from Phone intervals, preserving left and right remainders.
- **Files modified:** SleepDeduplicator.swift
- **Verification:** All 7 tests pass, including testWatchAndPhonePartialOverlap_ReturnsMergedDuration
- **Committed in:** 8bc50bbb (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Fix was necessary for correct deduplication behavior. No scope creep.

## TDD Gate Compliance

- [x] RED gate: `test(01-02)` commit exists (d05a6cd7) with 6 failing tests
- [x] GREEN gate: `feat(01-02)` commit exists (8bc50bbb) with all tests passing
- [ ] REFACTOR gate: No separate refactor commit needed; code was clean after implementation

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Sleep data pipeline complete: HealthKitClient can fetch sleep samples, SleepDeduplicator can merge and deduplicate them
- MockHealthKitClient fully supports sleep data for unit testing recovery score in Plans 03-05
- Plan 03 (Recovery Score ViewModel) can now use fetchSleepAnalysis + SleepDeduplicator as the sleep input to the recovery score

---
*Phase: 01-recovery-score-foundation*
*Completed: 2026-04-16*

## Self-Check: PASSED

All files verified present. All commits verified in git log. Full test suite green (86 tests, 0 failures).
