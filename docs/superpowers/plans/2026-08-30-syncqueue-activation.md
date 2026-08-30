# SyncQueue Activation Implementation Plan

> Scoped sub-plan under `2026-08-30-app-improvement-roadmap.md` Release 2.2a. Covers only offline-write activation — the String Catalog / localization half of Release 2.2 is a separate, much larger effort and is not addressed here.

**Goal:** `SyncQueue` — a fully built, fully tested `DataClientProtocol` wrapper that queues writes on network failure and replays them on reconnect — is never constructed anywhere in the app. Wire it into `DataClientFactory` so CloudKit writes survive being offline, without introducing a cross-account data leak or touching `AuthViewModel`'s auth-critical, heavily-tested logic.

## Verified current state (2026-08-30)

- `SyncQueue`, `PendingMutation`, `SyncQueueStore`, `NetworkMonitor` (`DataLayer/SyncQueue/`) are complete and tested (`SyncQueueTests.swift`, `SyncQueueStuckTests.swift`). `SyncQueue` already conforms to `DataClientProtocol` and is designed as a drop-in wrapper per its own doc comment.
- `SyncQueueDiagnosticsService.shared.attach(_:)` (`DataLayer/Diagnostics/`) already polls a `SyncQueue?` every 5s and publishes `pendingCount`/`stuckCount`/`lastFlushError`. `DataTrustCenterView` already reads those published values. `attach(_:)` has zero callers today — this is the only missing wire.
- `DataClientFactory` (`DataLayer/DataClientFactory.swift`) holds `_client: any DataClientProtocol` behind an `NSLock`, exposed via a plain `client` get/set and via `activate(client:ownerID:)`. It does not know about `SyncQueue` today.
- `AuthViewModel` is the only caller of `activate(client:ownerID:)`, at exactly 3 logical points, all going through one of two factory closures also owned by `AuthViewModel`:
  - `destinationClientFactory: @Sendable () -> any DataClientProtocol`, default `{ CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app") }` — used by `restoreSession()` (line ~460) and `activateMigratedAccount(_:destination:displayName:)` (line ~690, `destination` supplied by its caller).
  - `localClientFactory: @Sendable () -> any DataClientProtocol`, default `{ LocalDataClient() }` — used by `continueAsGuest()` and every `keepGuestSession(source:ownerID:)` call site (guest migration abandon/retry paths). Never wraps a CloudKit client.
- The one non-auth caller, `ScreenshotSeeder.swift:25`, sets `DataClientFactory.shared.client = localClient` directly (the plain setter, not `activate`) and is unaffected by anything below.
- `SyncQueueStore.init(userDefaults: UserDefaults = .standard)` persists under a **fixed** key (`sync_queue_pending_mutations`) regardless of who constructs it — there is no per-account namespacing anywhere in the existing, already-shipped code.

## The risk this plan exists to avoid

`destinationClientFactory` is a zero-argument closure — it doesn't receive `ownerID`. If `DataClientFactory.activate()` wrapped whatever `CloudKitClient` it's handed in a `SyncQueue` backed by the *default* `SyncQueueStore(.standard)`, every account would share one pending-mutation store. Sequence: User A goes offline, saves a workout (queued) → User A signs out, User B signs in on the same device before reconnecting → User B's fresh `SyncQueue` reads the *same* UserDefaults key, sees User A's queued workout, and replays it into User B's CloudKit account on reconnect. That is a real cross-account data leak, not a hypothetical.

## Design decision

Do the wrapping **inside `DataClientFactory`**, not in `AuthViewModel`, and namespace the queue's storage by `ownerID`:

- `DataClientFactory` gains one pure, testable static function:
  ```swift
  static func wrapForSync(
      _ client: any DataClientProtocol,
      ownerID: String,
      monitor: NetworkMonitor
  ) -> any DataClientProtocol
  ```
  Wraps only when `client is CloudKitClient` (never `LocalDataClient` — a local client can't throw `DataError.networkError`, so queuing it is a correctness no-op, and skipping it keeps guest mode simple). Builds `SyncQueueStore(userDefaults: UserDefaults(suiteName: "com.sundeefundee.syncqueue.\(ownerID)") ?? .standard)` — an **arbitrary suite name, not a real App Group**, so no entitlement is needed; it just gives each `ownerID` (including the fixed `"guest_local"`, which never reaches this path anyway) its own on-device storage.
- This sidesteps the leak by construction — Account A and Account B never share a UserDefaults key — rather than by detecting an account switch and clearing state reactively, which would need `activate()` to become `async` (a signature change to a protocol two other call sites and an auth test suite depend on) to safely await a clear before exposing the new client.
- `DataClientFactory` holds one `NetworkMonitor` for its own lifetime (constructed once, reused across every `activate()` call) rather than spinning up a new `NWPathMonitor` per sign-in.
- `activate(client:ownerID:)` calls the wrapper before storing `_client`, then hops to `@MainActor` to call `SyncQueueDiagnosticsService.shared.attach(_:)` with the resulting queue (or `nil` when the activated client isn't a `SyncQueue` — e.g. guest mode — so the diagnostics UI correctly shows nothing to sync rather than stale state from a previous account).
- `AuthViewModel` is untouched. `destinationClientFactory` keeps returning a bare `CloudKitClient`; the wrapping is an implementation detail of `DataClientFactory.activate()`.
- The plain `client` setter is untouched — it carries no `ownerID`, is not used by any real sign-in path, and its only caller (`ScreenshotSeeder`) needs a deterministic local client, not a queue.

## Files

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/DataClientFactory.swift` — add `wrapForSync`, a stored `NetworkMonitor`, and the `attach`/`activate` wiring.
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DataClientFactoryTests.swift` — first test file for this type. Tests `wrapForSync` as a pure function (no singleton state touched, so no cross-test pollution risk): wraps a `CloudKitClient`, does not wrap a `LocalDataClient`, and two different `ownerID`s produce queues backed by different storage (verified by writing through one and confirming the other doesn't see it).

## Explicitly out of scope here

- No new UI. `DataTrustCenterView`'s sync section already renders `pendingCount`/`stuckCount`; this plan makes those numbers real instead of always zero.
- No change to `SyncQueue`/`SyncQueueStore`/`NetworkMonitor`/`PendingMutation` — they're correct as built.
- No change to `AuthViewModel`.
- The String Catalog / localization half of Release 2.2 — unrelated concern, separate plan.
- Manual on-device verification (airplane mode → save → reconnect → confirm replay) — needs a real simulator/device and is left for the checks the user is doing separately; this plan produces code and unit tests only.
