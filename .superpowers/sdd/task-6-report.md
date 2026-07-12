# Task 6 report — persistence and CloudKit schema

## Results

- Added `DailyReadinessRecord.currentSchemaVersion` and persisted `schemaVersion`.
- Added explicit Codable decoding that defaults missing versions to v1, rejects newer unsupported versions, and naturally ignores unknown fields.
- Preserved stable `readiness-YYYY-MM-DD` local-day IDs, ISO-8601 string dates, optional integer score fields, and no boolean persistence fields.
- Added `schemaVersion INT64 QUERYABLE SORTABLE` to the existing `DailyReadinessRecord` CloudKit schema. The existing queryable `___recordID` remains present; no schema import/deploy was performed.
- Extended `next-release-gate.sh` to guard the version field and existing queryable record ID.
- Added regression tests covering legacy/versioned decoding, unknown fields, same-day local replacement, date/boolean CloudKit safety, local fallback behavior, and service persistence/failure caching.

## Verification

- `cd SundeeFundee && swift test --filter DailyReadinessRecordTests` — passed (5 tests).
- `cd SundeeFundee && swift test --filter DailyReadinessServiceTests` — passed (3 tests).
- `cd SundeeFundee && swift test` — passed (814 XCTest tests; Swift Testing suites passed).
- `bash -n scripts/next-release-gate.sh` — passed.

The full release gate was not run because it requires installed SwiftLint, an iOS simulator/Xcode build, and external release dependencies beyond this task.
