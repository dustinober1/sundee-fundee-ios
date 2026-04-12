# Fix: CloudKit Duplicate Record Error

## When to Use
When `CloudKitClient.save()` fails with `"record to insert already exists"` because a record with the same `recordID` already exists on the server.

## Root Cause
`CKRecord(recordType:recordID:)` always creates a **new** record. If a record with that ID already exists in CloudKit, the default `.ifServerRecordUnchanged` save policy treats it as a duplicate insert.

## Fix
`CloudKitClient.save()` now uses **fetch-or-update** (upsert) semantics:

1. Encode all records to `CKRecord` as before
2. Fetch existing records via `database.records(for:)` 
3. For any that exist: copy new field values onto the existing `CKRecord` (preserves server change tag)
4. Save all records in one `modifyRecords` call

The same logic is applied to both `save()` and `saveFromJSON()` (SyncQueue replay path).

## Key Methods
- `CloudKitClient.fetchExistingRecords(_:)` — best-effort fetch, returns `[:]` on failure
- `CloudKitClient.mergeWithExisting(_:existing:)` — merges fields if record exists, returns new record otherwise

## Gotchas
- `MockCloudKitClient` already handled upsert correctly (checks ID, updates in-place) — only `CloudKitClient` needed fixing
- `database.records(for:)` returns `[CKRecord.ID: Result<CKRecord, Error>]` directly (not a tuple like `records(matching:)`)
- The fetch step is best-effort: if it fails, falls back to insert-only (same behavior as before the fix)

## Tests
- `MockCloudKitClientUpsertTests` — 4 tests verifying mock upsert behavior
- `ProgramsListViewModelTests` — 3 tests verifying enrollment flow (save, re-enroll, multi-program)
