---
name: data-layer
description: Deep dive into the persistence architecture — DataClientProtocol, CloudKit, LocalData, SyncQueue, ContentClient. Load when working on data persistence, offline sync, or client switching.
triggers:
  - "CloudKit"
  - "data client"
  - "persistence"
  - "offline"
  - "sync"
  - "SyncQueue"
  - "guest mode"
  - "LocalDataClient"
  - "ContentClient"
edges:
  - target: context/architecture.md
    condition: when understanding how data layer fits into the overall system
  - target: context/decisions.md
    condition: when understanding why the data layer is structured this way
  - target: patterns/add-view-feature.md
    condition: when a new feature needs to read/write data
last_updated: 2026-04-11
---

# Data Layer

## DataClientProtocol

The core persistence interface. All data access goes through this protocol:

```swift
public protocol DataClientProtocol: Sendable {
    func fetch<T: Decodable & Sendable>(recordType: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
    func save<T: Encodable & Sendable>(_ records: [T], recordType: String) async throws
    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws
    func deleteAllData() async throws
    func saveFromJSON(_ jsonRecords: [Data], recordType: String) async throws
}
```

Extension convenience methods: `fetchAll()`, `save(single:)`, `delete(single:)`.

Error type: `DataError` — `.recordNotFound`, `.networkError`, `.permissionDenied`, `.invalidData`.

## Implementations

| Client | Storage | Thread Model | Use Case |
|--------|---------|-------------|----------|
| `CloudKitClient` | iCloud private DB | `@unchecked Sendable` | Signed-in users |
| `LocalDataClient` | UserDefaults | `actor` | Guest mode |
| `MockCloudKitClient` | In-memory dict | `@unchecked Sendable` + serial DispatchQueue | Tests |

### CloudKitClient

- Container: `iCloud.com.sundeefundee.app`
- JSON↔CKRecord bridge: encodes Swift models to JSON, maps JSON keys to CKRecord fields
- Date strategy: ISO8601
- Handles missing queryable indexes gracefully (returns empty array, doesn't crash)
- Maps `CKError` → `DataError`

### LocalDataClient

- Keys: `"local_data_<RecordType>"` in UserDefaults
- Stores `[[String: Any]]` per record type as JSON
- Supports NSPredicate evaluation and NSSortDescriptor sorting on in-memory dictionaries
- `clearAll()` removes all `local_data_*` keys on sign-out

### DataClientFactory

Singleton with NSLock-based thread-safe read/write:
```swift
public final class DataClientFactory: @unchecked Sendable {
    public static let shared = DataClientFactory()
    private let lock = NSLock()
    private var _client: any DataClientProtocol = CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")
    public var client: any DataClientProtocol { get/set with lock }
}
```

**Switching points:**
- Guest sign-in: `DataClientFactory.shared.client = LocalDataClient()`
- Apple sign-in: keeps default `CloudKitClient`
- Sign-out: resets to `CloudKitClient`

## SyncQueue (Offline-First)

Actor wrapping any data client. Transparent to callers:

1. `save()` → tries `wrappedClient.save()` → success → done
2. If `DataError.networkError` → enqueue `PendingMutation` → return silently (UI sees success)
3. `NetworkMonitor` detects connectivity → `flushQueue()` replays pending mutations
4. Max 10 retry attempts per mutation. Persisted to UserDefaults (`"sync_queue_pending_mutations"`).

## ContentClientProtocol

Separate from DataClientProtocol — read-only content catalog:

```swift
public protocol ContentClientProtocol: Sendable {
    func fetchExercises() async throws -> [ContentExercise]
    func fetchPrograms() async throws -> [ContentProgram]
    func fetchBenchmarks() async throws -> [ContentBenchmark]
}
```

- `RemoteContentClient` — fetches from Teenybase backend, caches locally, falls back to bundled JSON
- `BundledContentProvider` — reads from bundled JSON files in the app package
- `MockContentClient` — in-memory for tests

## Gotchas

- **Never instantiate a specific client in a ViewModel** — always use `DataClientFactory.shared.client` as default parameter
- **Gate CloudKit writes** with `!authViewModel.isGuest` to avoid crashes in guest mode
- **Apple only provides name on first sign-in** — read `givenName` from Keychain/CloudKit, not from the ASAuthorizationCredential
- **CKRecord field queryable indexes** may not be deployed — CloudKitClient handles this gracefully but new queries on unindexed fields will return empty results
