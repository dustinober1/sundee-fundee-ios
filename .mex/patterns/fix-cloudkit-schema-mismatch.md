# Fix CloudKit Schema Mismatch

Use when CloudKit logs show missing record types, unqueryable fields, or app/code schema drift.

## Steps

1. Read `context/data-layer.md` and inspect `CloudKitClient` error handling.
2. Search for all `recordType:` usages for the failing types.
3. Check that every fetched record type is either:
- persisted somewhere in app code, or
- intentionally optional with a local fallback.
4. Fix mismatched record type strings so save and fetch paths agree.
5. If the app stores canonical data in one record type but reads a derived type, prefer deriving locally instead of requiring a second CloudKit schema type.
6. Build with `xcodebuild` and verify edited files compile.

## Common Fixes

- Change save/fetch code to use the same record type string.
- Fall back from legacy or derived record types to canonical persisted types.
- Keep CloudKit access behind `DataClientProtocol`.

## Gotchas

- `NSPredicate(value: true)` can still fail if the CloudKit schema is undeployed or missing indexes.
- Returning `[]` from `CloudKitClient` on queryable errors prevents crashes, but repeated logs usually mean a schema deployment or code/schema alignment problem remains.
