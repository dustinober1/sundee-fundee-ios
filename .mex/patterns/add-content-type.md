---
name: add-content-type
description: Adding a new content type to the ContentClient pipeline (bundled JSON + remote Teenybase + caching). Use when extending the content catalog.
triggers:
  - "content type"
  - "ContentClient"
  - "Teenybase"
  - "remote content"
  - "bundled content"
  - "exercises"
  - "programs"
  - "benchmarks"
edges:
  - target: context/data-layer.md
    condition: when understanding the ContentClientProtocol architecture
  - target: context/architecture.md
    condition: when understanding how content flows from backend to UI
  - target: patterns/add-view-feature.md
    condition: when the content type needs a new UI screen
last_updated: 2026-04-11
---

# Add Content Type

## Context

Load `context/data-layer.md` for ContentClientProtocol details.

The content pipeline has three layers:
1. **BundledContentProvider** — JSON files shipped in the app bundle (fallback)
2. **RemoteContentClient** — fetches from Teenybase backend, caches locally
3. **ContentClientProtocol** — abstraction consumed by ViewModels

Key files:
- Protocol: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/ContentClientProtocol.swift`
- Remote client: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/RemoteContentClient.swift`
- Bundled provider: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContentProvider.swift`
- Mock: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockContentClient.swift`
- Backend migrations: `SundeeFundeeApp/backend/migrations/`

## Steps

1. **Define the content model** (e.g., `ContentNewType`) — conform to `Codable`, `Sendable`, `Identifiable`, `Equatable`

2. **Add to ContentClientProtocol**:
   ```swift
   func fetchNewTypes() async throws -> [ContentNewType]
   ```

3. **Add bundled JSON** — create the JSON file in the app bundle, add to `BundledContentProvider`

4. **Add backend migration** — create SQL migration in `SundeeFundeeApp/backend/migrations/` following existing pattern (e.g., `0006_create_table_new_types.sql`)

5. **Implement in RemoteContentClient** — add fetch + cache + fallback logic matching the pattern for exercises/programs/benchmarks

6. **Implement in MockContentClient** — return hardcoded test data

7. **Wire to ViewModel** — inject `ContentClientProtocol` and call the new fetch method

8. **Write tests** — test RemoteContentClient merge/fallback behavior, test MockContentClient

## Gotchas

- **Fallback is critical** — `RemoteContentClient` must always fall back to `BundledContentProvider` if the network request fails. Users must never see empty content.
- **Cache invalidation** — RemoteContentClient caches locally. New content types need cache key management.
- **Backend naming** — Wrangler name must be lowercase for compatibility (see commit `46cc240d`)
- **Migration numbering** — migrations are numbered sequentially (`0000_`, `0001_`, etc.). Check existing migrations before choosing the next number.

## Verify

- [ ] Content model conforms to `Codable`, `Sendable`, `Identifiable`, `Equatable`
- [ ] Protocol method added to `ContentClientProtocol`
- [ ] BundledContentProvider has fallback JSON data
- [ ] RemoteContentClient implements fetch + cache + fallback
- [ ] MockContentClient implements the new method
- [ ] Backend migration follows sequential numbering
- [ ] Tests cover both remote success and fallback scenarios
- [ ] `swift test` passes

## Debug

If content appears empty in the app:
1. Check `BundledContentProvider` — is the JSON file included in the bundle?
2. Check `RemoteContentClient` cache — is the cache key correct?
3. Check backend — run `npx wrangler dev` locally and test the endpoint
4. Check fallback — does `RemoteContentClient` correctly fall back to bundled data on network error?

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" if what's working/not built has changed
- [ ] Update any `.mex/context/` files that are now out of date
- [ ] If this is a new task type without a pattern, create one in `.mex/patterns/` and add to `INDEX.md`
