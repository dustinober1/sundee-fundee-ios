---
phase: 07-polish-and-pre-launch
plan: "02"
subsystem: data-export
tags: [csv, json, expo-file-system, expo-sharing, react-native-zip-archive, tdd]

# Dependency graph
requires:
  - phase: 03-data-layer-and-offline-architecture
    provides: Repository interfaces (WorkoutRepo, ExerciseMaxRepo, BenchmarkRepo, CycleRepo, InjuryRepo, ReadinessRepo) that export module queries
  - phase: 02-domain-layer-port
    provides: weight-unit-conversion.ts (lbToKg) used for unit-aware CSV values
provides:
  - Pure CSV formatter functions for all 7 user data types with unit-aware weight columns
  - Export orchestrator that collects all user data and shares as JSON or zipped CSVs
  - Cross-platform export: native share sheet on iOS/Android, browser download on web
affects: [07-polish-and-pre-launch, account-deletion-flow, data-portability]

# Tech tracking
tech-stack:
  added:
    - react-native-zip-archive (zip CSV bundle for mobile export)
  patterns:
    - RepoBundle dependency injection for testable export orchestration
    - Platform.OS branch for web vs mobile file sharing
    - Object.defineProperty(Platform, 'OS', ...) for Platform mock in jest-expo

key-files:
  created:
    - SundeeFundeeRN/src/export/csvFormatters.ts
    - SundeeFundeeRN/src/export/exportData.ts
    - SundeeFundeeRN/src/export/__tests__/csvFormatters.test.ts
    - SundeeFundeeRN/src/export/__tests__/exportData.test.ts
  modified:
    - SundeeFundeeRN/package.json (react-native-zip-archive added)

key-decisions:
  - "RepoBundle passed as parameter to collectAllUserData and exportUserData — enables clean unit tests with mocks without global state"
  - "ExerciseMax.weight stored in lbs per domain convention — maxesToCsv converts to user unit at export time"
  - "Pain logs fetched per-injury via Promise.all — no dedicated getAllPainLogs method on InjuryRepository"
  - "Web export triggers individual CSV file downloads (one per file) — no browser-native zip API; zip library is React Native only"
  - "expo-file-system/legacy imported (not new expo-file-system) — matches existing project pattern, provides writeAsStringAsync"
  - "globalThis.document stubbed in beforeEach for web tests — jest-expo uses React Native test env not jsdom"

patterns-established:
  - "CSV escaping: wrap commas/quotes in double-quotes, escape internal double-quotes by doubling"
  - "Unit-aware weight columns: header says Weight (lbs) or Weight (kg) to reflect conversion"
  - "All formatters return header-only string for empty arrays — safe to render even when user has no data"
  - "roundsAndReps encoding: score / 10000 = rounds, score % 10000 = reps — matches benchmark domain convention"

requirements-completed:
  - PLAT-06

# Metrics
duration: 5min
completed: "2026-03-15"
---

# Phase 7 Plan 02: Data Export Module Summary

**Seven unit-aware CSV formatters plus a cross-platform export orchestrator that zips CSVs or bundles a single JSON, sharing via native share sheet on mobile and browser download on web.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-15T19:45:29Z
- **Completed:** 2026-03-15T19:50:00Z
- **Tasks:** 1 (TDD: test → feat)
- **Files modified:** 6

## Accomplishments

- Seven pure CSV formatter functions covering all exportable data types (workouts, maxes, benchmarks, period logs, pain logs, injuries, readiness)
- Weight values converted to user's preferred unit at export time; column headers reflect the unit (Weight (lbs) / Weight (kg))
- Export orchestrator collects data from all six repositories, writes CSV files to cache directory, zips with react-native-zip-archive, and shares via expo-sharing
- JSON export writes a single pretty-printed file and shares it
- Web platform path uses Blob + URL.createObjectURL + synthetic anchor click — no native modules required on web
- 46 unit tests pass (32 CSV formatter tests + 14 orchestration tests)

## Task Commits

Each TDD phase committed atomically:

1. **RED — Failing tests** - `a91290d` (test)
2. **GREEN — Implementation + test fixes** - `0f8d0a5` (feat)

## Files Created/Modified

- `SundeeFundeeRN/src/export/csvFormatters.ts` — 7 pure formatter functions with CSV escaping and unit conversion
- `SundeeFundeeRN/src/export/exportData.ts` — collectAllUserData, buildCsvFiles, exportUserData orchestrator
- `SundeeFundeeRN/src/export/__tests__/csvFormatters.test.ts` — 32 tests covering all formatters, unit switching, empty arrays, CSV escaping
- `SundeeFundeeRN/src/export/__tests__/exportData.test.ts` — 14 tests covering repo queries, CSV file count, JSON write, zip, share, and web path
- `SundeeFundeeRN/package.json` — react-native-zip-archive added

## Decisions Made

- RepoBundle injected as parameter rather than importing repo factories directly — keeps export module testable without mocking module-level singletons
- Pain logs fetched per-injury using Promise.all on InjuryRepository.getPainLogs — no getAllPainLogs method available, this approach is O(injuries) Firestore reads at export time (acceptable for infrequent export operation)
- Web platform downloads one CSV file per formatter rather than a zip — browser has no native zip API and the library is mobile-only
- expo-file-system/legacy used for writeAsStringAsync compatibility with existing project patterns

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing react-native-zip-archive dependency**
- **Found during:** Task 1 (export implementation)
- **Issue:** Plan specifies react-native-zip-archive for CSV zip bundling; package not in package.json
- **Fix:** `npm install react-native-zip-archive --legacy-peer-deps`
- **Files modified:** package.json, package-lock.json
- **Verification:** Import succeeds, zip mock works in tests
- **Committed in:** 0f8d0a5 (feat commit)

**2. [Rule 1 - Bug] Fixed Platform.OS mock approach in tests**
- **Found during:** Task 1 (test GREEN phase)
- **Issue:** Direct property assignment `(Platform as any).OS = 'web'` fails because jest.mock factory returns read-only Platform object
- **Fix:** Used `Object.defineProperty(Platform, 'OS', {value, configurable: true})` per existing project decision in STATE.md
- **Files modified:** src/export/__tests__/exportData.test.ts
- **Verification:** All 14 exportData tests pass including web platform tests
- **Committed in:** 0f8d0a5 (feat commit)

**3. [Rule 1 - Bug] Replaced jest.spyOn(document) with globalThis stubs for web tests**
- **Found during:** Task 1 (test GREEN phase)
- **Issue:** jest-expo test environment has no jsdom — `document` is undefined; jest.spyOn(document, ...) throws ReferenceError
- **Fix:** Stub `globalThis.document`, `globalThis.URL`, and `globalThis.Blob` in beforeEach for the web platform describe block
- **Files modified:** src/export/__tests__/exportData.test.ts
- **Verification:** Web platform tests pass without jsdom dependency
- **Committed in:** 0f8d0a5 (feat commit)

---

**Total deviations:** 3 auto-fixed (1 blocking dependency, 2 test environment bugs)
**Impact on plan:** All fixes necessary for correctness in jest-expo environment. No scope creep.

## Issues Encountered

None beyond what is documented under Deviations.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Export module is self-contained and ready to be wired into Settings screen as an "Export My Data" button
- `exportUserData` accepts format + weightUnit + repos bundle — caller only needs to provide those from context
- Account deletion flow can link directly to `exportUserData` before deletion confirmation

## Self-Check: PASSED

- FOUND: SundeeFundeeRN/src/export/csvFormatters.ts
- FOUND: SundeeFundeeRN/src/export/exportData.ts
- FOUND: SundeeFundeeRN/src/export/__tests__/csvFormatters.test.ts
- FOUND: SundeeFundeeRN/src/export/__tests__/exportData.test.ts
- FOUND: .planning/phases/07-polish-and-pre-launch/07-02-SUMMARY.md
- FOUND commit: a91290d (test RED phase)
- FOUND commit: 0f8d0a5 (feat GREEN phase)

---
*Phase: 07-polish-and-pre-launch*
*Completed: 2026-03-15*
