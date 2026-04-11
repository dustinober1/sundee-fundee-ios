# Remote Content Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable remote management of programs, benchmarks, and exercises through a Teenybase backend + web admin dashboard, so content can be updated without App Store resubmission.

**Architecture:** Add three new tables to the existing Teenybase backend (exercises, programs, benchmarks). The app fetches published content on launch, overlays it on bundled defaults, and caches locally for offline use. A simple admin dashboard served by the Cloudflare Worker provides CRUD operations with draft/published workflow.

**Tech Stack:** Teenybase (Cloudflare Workers + D1), Swift 6 (strict concurrency), SwiftUI, vanilla HTML/JS for admin

---

## File Map

### Backend (Create/Modify)
| File | Action | Purpose |
|---|---|---|
| `backend/teenybase.ts` | Modify | Add exercises, programs, benchmarks tables |
| `backend/src-backend/worker.ts` | Modify | Add `/admin` route for serving admin HTML |
| `backend/src-backend/admin.html` | Create | Admin dashboard SPA |

### iOS — Data Layer (Create)
| File | Action | Purpose |
|---|---|---|
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/ContentClientProtocol.swift` | Create | Protocol for content fetching |
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/RemoteContentClient.swift` | Create | Fetches from Teenybase, caches, falls back to bundled |
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContent/BundledBenchmarks.swift` | Create | Extracts BenchmarkCatalog.allBenchmarks into a conforming provider |
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContent/BundledPrograms.swift` | Create | Extracts ProgramTemplate generation into a conforming provider |
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContent/BundledExercises.swift` | Create | Extracts ExerciseCatalog into a conforming provider |

### iOS — ViewModels (Modify)
| File | Action | Purpose |
|---|---|---|
| `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift` | Modify | Use ContentClientProtocol instead of BenchmarkCatalog |
| `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` | Modify | Use ContentClientProtocol in ProgramsListViewModel |

### Tests (Create)
| File | Action | Purpose |
|---|---|---|
| `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/RemoteContentClientTests.swift` | Create | Tests for fetch, cache, merge, fallback |

---

## Task 1: Add Content Tables to Teenybase Schema

**Files:**
- Modify: `SundeeFundeeApp/backend/teenybase.ts`

- [ ] **Step 1: Add three new table definitions to teenybase.ts**

Add these tables before the `export default` block at the end of the file:

```typescript
const exercisesTable: TableData = {
    name: "exercises",
    autoSetUid: true,
    fields: [
        ...baseFields,
        {name: "name", type: "text", sqlType: "text", notNull: true},
        {name: "category", type: "text", sqlType: "text", notNull: true},
        {name: "bodyweight", type: "bool", sqlType: "boolean", notNull: true, default: sqlValue(false)},
        {name: "equipment", type: "text", sqlType: "text"},
        {name: "movementTags", type: "text", sqlType: "text"},
        {name: "status", type: "text", sqlType: "text", notNull: true, default: sqlValue("draft")},
        {name: "sortOrder", type: "number", sqlType: "integer", notNull: true, default: sqlValue(0)},
    ],
    indexes: [
        {fields: "status"},
        {fields: "category"},
    ],
    extensions: [],
    triggers: [createdTrigger],
}

const programsTable: TableData = {
    name: "programs",
    autoSetUid: true,
    fields: [
        ...baseFields,
        {name: "name", type: "text", sqlType: "text", notNull: true},
        {name: "templateKey", type: "text", sqlType: "text"},
        {name: "category", type: "text", sqlType: "text", notNull: true},
        {name: "description", type: "text", sqlType: "text", notNull: true},
        {name: "durationWeeks", type: "number", sqlType: "integer", notNull: true},
        {name: "sessionsPerWeek", type: "number", sqlType: "integer", notNull: true},
        {name: "difficulty", type: "text", sqlType: "text", notNull: true},
        {name: "phases", type: "json", sqlType: "json"},
        {name: "status", type: "text", sqlType: "text", notNull: true, default: sqlValue("draft")},
        {name: "version", type: "number", sqlType: "integer", notNull: true, default: sqlValue(1)},
        {name: "sortOrder", type: "number", sqlType: "integer", notNull: true, default: sqlValue(0)},
    ],
    indexes: [
        {fields: "status"},
        {fields: "category"},
    ],
    extensions: [],
    triggers: [createdTrigger],
}

const benchmarksTable: TableData = {
    name: "benchmarks",
    autoSetUid: true,
    fields: [
        ...baseFields,
        {name: "name", type: "text", sqlType: "text", notNull: true},
        {name: "category", type: "text", sqlType: "text", notNull: true},
        {name: "workoutDescription", type: "text", sqlType: "text", notNull: true},
        {name: "scoringType", type: "text", sqlType: "text", notNull: true},
        {name: "intensity", type: "number", sqlType: "integer"},
        {name: "movementTags", type: "text", sqlType: "text"},
        {name: "equipment", type: "text", sqlType: "text"},
        {name: "timeDomain", type: "text", sqlType: "text"},
        {name: "coachNotes", type: "text", sqlType: "text"},
        {name: "status", type: "text", sqlType: "text", notNull: true, default: sqlValue("draft")},
        {name: "sortOrder", type: "number", sqlType: "integer", notNull: true, default: sqlValue(0)},
    ],
    indexes: [
        {fields: "status"},
        {fields: "category"},
    ],
    extensions: [],
    triggers: [createdTrigger],
}
```

Then update the export to include the new tables:

```typescript
export default {
    tables: [userTable, notesTable, kvStoreTable, exercisesTable, programsTable, benchmarksTable],
    appName: "Sundee Fundee",
    appUrl: "https://sundeefundee.com",
    jwtSecret: "$JWT_SECRET_MAIN",
    // ... rest unchanged
}
```

Also update `appName` from `"Sample app"` to `"Sundee Fundee"` and `appUrl` from `"https://sample.example.com"` to `"https://sundeefundee.com"`.

- [ ] **Step 2: Generate and apply migrations**

Run:
```bash
cd SundeeFundeeApp/backend && npm run generate:backend && npm run migrate:backend -- -y
```
Expected: Migration files created and applied. Three new tables appear in D1.

- [ ] **Step 3: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundeeApp/backend/teenybase.ts && git commit -m "feat(backend): add exercises, programs, benchmarks tables to Teenybase schema"
```

---

## Task 2: Add Admin Dashboard Route to Worker

**Files:**
- Modify: `SundeeFundeeApp/backend/src-backend/worker.ts`
- Create: `SundeeFundeeApp/backend/src-backend/admin.html`

- [ ] **Step 1: Add `/admin` route to worker.ts**

Replace the current `worker.ts` with:

```typescript
import { $Database, $Env, OpenApiExtension, PocketUIExtension, teenyHono } from 'teenybase/worker';
import config from '../migrations/config.json';
import { DatabaseSettings } from "teenybase";

export interface Env {
  Bindings: $Env['Bindings'] & {
    PRIMARY_DB: D1Database;
    PRIMARY_R2?: R2Bucket;
  },
  Variables: $Env['Variables']
}

const app = teenyHono<Env>(async (c)=> {
  const db = new $Database(c, config as unknown as DatabaseSettings, c.env.PRIMARY_DB, c.env.PRIMARY_R2)
  db.extensions.push(new OpenApiExtension(db, true))
  db.extensions.push(new PocketUIExtension(db))

  return db
}, undefined, {
  logger: false,
  cors: true,
})

app.get('/', (c)=>{
  return c.json({message: 'Hello Hono'})
})

app.get('/admin', async (c) => {
  const html = await import('./admin.html').then(m => m.default ?? m)
  return c.html(html)
})

export default app
```

- [ ] **Step 2: Create admin.html**

Create `SundeeFundeeApp/backend/src-backend/admin.html` with a minimal but functional admin dashboard. This is a single HTML file with embedded CSS and JS that:

1. Asks for the admin token (stored in localStorage)
2. Shows three tabs: Exercises, Programs, Benchmarks
3. Each tab lists items from the Teenybase API with status badges (draft/published)
4. Has a form modal for creating/editing items
5. Has a toggle to switch status between draft/published
6. Has a delete button for each item

The admin makes direct fetch calls to the Teenybase REST API using the admin token. The HTML file is large but self-contained — see the full implementation in the file created at `SundeeFundeeApp/backend/src-backend/admin.html`.

Key API calls the admin makes:
```javascript
const BASE = '';  // Same origin as worker
const TOKEN = localStorage.getItem('admin_token');

// List items
fetch(`${BASE}/api/v1/table/benchmarks/list`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` },
  body: JSON.stringify({ limit: 100 })
})

// Create item
fetch(`${BASE}/api/v1/table/benchmarks/insert`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` },
  body: JSON.stringify({ values: { name: '...', category: '...', ... }, returning: '*' })
})

// Update item
fetch(`${BASE}/api/v1/table/benchmarks/edit/ITEM_ID?returning=*`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` },
  body: JSON.stringify({ name: 'new name', status: 'published' })
})

// Delete item
fetch(`${BASE}/api/v1/table/benchmarks/delete`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` },
  body: JSON.stringify({ where: "id='ITEM_ID'" })
})
```

- [ ] **Step 3: Test admin loads locally**

Run:
```bash
cd SundeeFundeeApp/backend && npm run dev
```
Expected: Navigate to `http://localhost:8787/admin` and see the admin dashboard with a token prompt.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundeeApp/backend/src-backend/worker.ts SundeeFundeeApp/backend/src-backend/admin.html && git commit -m "feat(backend): add admin dashboard for content management"
```

---

## Task 3: Create ContentClientProtocol

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/ContentClientProtocol.swift`

- [ ] **Step 1: Write the test**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/ContentClientProtocolTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundeeKit

@available(iOS 18.0, *)
struct ContentClientProtocolTests {

    @Test("MockContentClient returns bundled benchmarks")
    func testBundledBenchmarks() async throws {
        let client = MockContentClient()
        let benchmarks = try await client.fetchBenchmarks()
        #expect(!benchmarks.isEmpty)
        #expect(benchmarks.allSatisfy { $0.source == .bundled })
    }

    @Test("MockContentClient returns bundled programs")
    func testBundledPrograms() async throws {
        let client = MockContentClient()
        let programs = try await client.fetchPrograms()
        #expect(!programs.isEmpty)
        #expect(programs.allSatisfy { $0.source == .bundled })
    }

    @Test("MockContentClient returns bundled exercises")
    func testBundledExercises() async throws {
        let client = MockContentClient()
        let exercises = try await client.fetchExercises()
        #expect(!exercises.isEmpty)
        #expect(exercises.allSatisfy { $0.source == .bundled })
    }

    @Test("ContentSource enum has bundled and remote cases")
    func testContentSourceCases() {
        #expect(ContentSource.bundled != ContentSource.remote)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter ContentClientProtocolTests 2>&1 | tail -5
```
Expected: FAIL — `ContentSource` and `MockContentClient` not found.

- [ ] **Step 3: Create ContentClientProtocol.swift**

```swift
import Foundation

// MARK: - Content Source

/// Origin of a content item
public enum ContentSource: String, Codable, Sendable, Equatable {
    case bundled
    case remote
}

// MARK: - Remote Content Models

/// A content exercise definition (remote-compatible)
public struct ContentExercise: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let bodyweight: Bool
    public let equipment: [String]?
    public let movementTags: [String]?
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        bodyweight: Bool = false,
        equipment: [String]? = nil,
        movementTags: [String]? = nil,
        sortOrder: Int = 0,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bodyweight = bodyweight
        self.equipment = equipment
        self.movementTags = movementTags
        self.sortOrder = sortOrder
        self.source = source
    }
}

/// A content program definition (remote-compatible)
public struct ContentProgram: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
    public let difficulty: String
    public let phases: String? // JSON string of phase definitions
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        description: String,
        durationWeeks: Int,
        sessionsPerWeek: Int,
        difficulty: String,
        phases: String? = nil,
        sortOrder: Int = 0,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.durationWeeks = durationWeeks
        self.sessionsPerWeek = sessionsPerWeek
        self.difficulty = difficulty
        self.phases = phases
        self.sortOrder = sortOrder
        self.source = source
    }
}

/// A content benchmark definition (remote-compatible)
public struct ContentBenchmark: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let workoutDescription: String
    public let scoringType: String
    public let intensity: Int?
    public let movementTags: [String]?
    public let equipment: [String]?
    public let timeDomain: String?
    public let coachNotes: String?
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        workoutDescription: String,
        scoringType: String,
        intensity: Int? = nil,
        movementTags: [String]? = nil,
        equipment: [String]? = nil,
        timeDomain: String? = nil,
        coachNotes: String? = nil,
        sortOrder: Int = 0,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.workoutDescription = workoutDescription
        self.scoringType = scoringType
        self.intensity = intensity
        self.movementTags = movementTags
        self.equipment = equipment
        self.timeDomain = timeDomain
        self.coachNotes = coachNotes
        self.sortOrder = sortOrder
        self.source = source
    }
}

// MARK: - Content Client Protocol

/// Protocol for fetching content (programs, benchmarks, exercises)
public protocol ContentClientProtocol: Sendable {
    func fetchExercises() async throws -> [ContentExercise]
    func fetchPrograms() async throws -> [ContentProgram]
    func fetchBenchmarks() async throws -> [ContentBenchmark]
}
```

Also create a `MockContentClient` in the same file for testing:

```swift
/// Mock content client for testing (returns bundled content)
public struct MockContentClient: ContentClientProtocol {
    public init() {}

    public func fetchExercises() async throws -> [ContentExercise] {
        return BundledContentProvider.exercises
    }

    public func fetchPrograms() async throws -> [ContentProgram] {
        return BundledContentProvider.programs
    }

    public func fetchBenchmarks() async throws -> [ContentBenchmark] {
        return BundledContentProvider.benchmarks
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter ContentClientProtocolTests 2>&1 | tail -5
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/ContentClientProtocol.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/ContentClientProtocolTests.swift && git commit -m "feat(data): add ContentClientProtocol with content models and mock client"
```

---

## Task 4: Create BundledContentProvider

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContent/BundledContentProvider.swift`

This extracts current hardcoded content into the new content model format so it can serve as the fallback.

- [ ] **Step 1: Write the test**

Add to `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/ContentClientProtocolTests.swift`:

```swift
@available(iOS 18.0, *)
struct BundledContentProviderTests {

    @Test("Bundled benchmarks match BenchmarkCatalog count")
    func testBundledBenchmarkCount() {
        let bundled = BundledContentProvider.benchmarks
        #expect(bundled.count == BenchmarkCatalog.allBenchmarks.count)
    }

    @Test("Bundled benchmarks preserve IDs")
    func testBundledBenchmarkIDs() {
        let bundled = BundledContentProvider.benchmarks
        let catalogIDs = Set(BenchmarkCatalog.allBenchmarks.map(\.id))
        let bundledIDs = Set(bundled.map(\.id))
        #expect(bundledIDs == catalogIDs)
    }

    @Test("Bundled programs match template count")
    func testBundledProgramCount() {
        let bundled = BundledContentProvider.programs
        #expect(bundled.count == ProgramTemplate.allCases.count)
    }

    @Test("Bundled exercises include weightlifting entries")
    func testBundledExercisesNotEmpty() {
        let bundled = BundledContentProvider.exercises
        #expect(bundled.count > 50) // 59 weightlifting + 31 conditioning
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter BundledContentProviderTests 2>&1 | tail -5
```
Expected: FAIL — `BundledContentProvider` not found.

- [ ] **Step 3: Create BundledContentProvider.swift**

```swift
import Foundation

/// Provides bundled (hardcoded) content as ContentXxx model instances.
/// Used as the fallback when remote content is unavailable.
public struct BundledContentProvider: Sendable {

    /// All bundled benchmarks, converted from BenchmarkCatalog
    public static let benchmarks: [ContentBenchmark] = BenchmarkCatalog.allBenchmarks.map { def in
        ContentBenchmark(
            id: def.id,
            name: def.name,
            category: def.category,
            workoutDescription: def.workoutDescription,
            scoringType: def.scoringType.rawValue,
            intensity: def.intensity?.rawValue,
            movementTags: def.movementTags,
            equipment: def.equipment,
            timeDomain: def.timeDomain,
            coachNotes: def.coachNotes,
            sortOrder: def.sortOrder,
            source: .bundled
        )
    }

    /// All bundled programs, generated from ProgramTemplate
    public static let programs: [ContentProgram] = ProgramTemplate.allCases.map { template in
        let defaults = templateDefaults[template]!
        let program = generateProgram(template: template, name: templateName(template))
        return ContentProgram(
            id: program.id,
            name: program.name,
            category: program.category,
            description: program.description,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek,
            difficulty: program.difficulty,
            phases: nil, // Programs are generated on-demand, not stored as JSON phases
            sortOrder: ProgramTemplate.allCases.firstIndex(of: template)!,
            source: .bundled
        )
    }

    /// All bundled exercises, combined from ExerciseCatalog
    public static let exercises: [ContentExercise] = {
        let wl = weightliftingExercises.map { entry in
            ContentExercise(
                id: entry.id,
                name: entry.id,
                category: entry.category.rawValue,
                bodyweight: false,
                equipment: nil,
                movementTags: nil,
                sortOrder: 0,
                source: .bundled
            )
        }
        let cond = conditioningExercises.map { entry in
            ContentExercise(
                id: entry.id,
                name: entry.id,
                category: "Conditioning",
                bodyweight: false,
                equipment: nil,
                movementTags: nil,
                sortOrder: 0,
                source: .bundled
            )
        }
        return wl + cond
    }()

    private static func templateName(_ template: ProgramTemplate) -> String {
        switch template {
        case .strength:    return "Strength Basics"
        case .hypertrophy: return "Hypertrophy Phase"
        case .fullBody:    return "Full Body"
        case .linear:      return "Linear Progression"
        case .dup:         return "Daily Undulating"
        case .block:       return "Block Periodization"
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter BundledContentProviderTests 2>&1 | tail -5
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/BundledContent/BundledContentProvider.swift && git commit -m "feat(data): add BundledContentProvider for fallback content"
```

---

## Task 5: Create RemoteContentClient

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/RemoteContentClient.swift`

- [ ] **Step 1: Write the test**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/RemoteContentClientTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundeeKit

@available(iOS 18.0, *)
struct RemoteContentClientTests {

    @Test("RemoteContentClient falls back to bundled when fetch fails")
    func testFallbackOnFetchFailure() async throws {
        let client = RemoteContentClient(
            baseURL: "http://localhost:1", // Invalid port, will fail
            token: "test-token",
            cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("test-content-\(UUID().uuidString)")
        )
        let benchmarks = try await client.fetchBenchmarks()
        #expect(!benchmarks.isEmpty)
        // All should be bundled since remote fetch fails
        #expect(benchmarks.allSatisfy { $0.source == .bundled })
    }

    @Test("RemoteContentClient returns cached content on second call")
    func testCaching() async throws {
        let cacheDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-content-cache-\(UUID().uuidString)")
        let client = RemoteContentClient(
            baseURL: "http://localhost:1",
            token: "test-token",
            cacheDirectory: cacheDir
        )

        // First call populates cache (falls back to bundled)
        let first = try await client.fetchBenchmarks()
        #expect(!first.isEmpty)

        // Second call should also work (from cache)
        let second = try await client.fetchBenchmarks()
        #expect(!second.isEmpty)

        // Cleanup
        try? FileManager.default.removeItem(at: cacheDir)
    }

    @Test("Remote content overlays bundled content by ID")
    func testRemoteOverlay() async throws {
        let bundled = BundledContentProvider.benchmarks
        let remoteBenchmark = ContentBenchmark(
            id: bundled[0].id, // Same ID as a bundled item
            name: "Updated Name",
            category: bundled[0].category,
            workoutDescription: "Updated description",
            scoringType: "time",
            sortOrder: 0,
            source: .remote
        )

        let merged = RemoteContentClient.merge(
            bundled: bundled,
            remote: [remoteBenchmark]
        )

        #expect(merged.count == bundled.count) // Same count
        let updated = merged.first { $0.id == bundled[0].id }
        #expect(updated?.name == "Updated Name")
        #expect(updated?.source == .remote)
    }

    @Test("Remote content adds new items alongside bundled")
    func testRemoteAddsNewItems() async throws {
        let bundled = BundledContentProvider.benchmarks
        let newBenchmark = ContentBenchmark(
            id: "remote-new-1",
            name: "Brand New Benchmark",
            category: "General Fitness",
            workoutDescription: "A new benchmark",
            scoringType: "reps",
            sortOrder: 99,
            source: .remote
        )

        let merged = RemoteContentClient.merge(
            bundled: bundled,
            remote: [newBenchmark]
        )

        #expect(merged.count == bundled.count + 1)
        #expect(merged.contains { $0.id == "remote-new-1" })
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter RemoteContentClientTests 2>&1 | tail -5
```
Expected: FAIL — `RemoteContentClient` not found.

- [ ] **Step 3: Create RemoteContentClient.swift**

```swift
import Foundation

/// Fetches content from Teenybase, caches locally, and falls back to bundled defaults.
public actor RemoteContentClient: ContentClientProtocol {

    private let baseURL: String
    private let token: String
    private let cacheDirectory: URL

    private var cachedExercises: [ContentExercise]?
    private var cachedPrograms: [ContentProgram]?
    private var cachedBenchmarks: [ContentBenchmark]?

    public init(
        baseURL: String,
        token: String,
        cacheDirectory: URL
    ) {
        self.baseURL = baseURL
        self.token = token
        self.cacheDirectory = cacheDirectory
    }

    // MARK: - Public API

    public func fetchExercises() async throws -> [ContentExercise] {
        if let cached = cachedExercises { return cached }
        let result = try await fetchWithFallback(
            table: "exercises",
            cachedFile: "exercises.json",
            bundled: BundledContentProvider.exercises,
            cacheKey: \.id
        ) { data in
            try JSONDecoder().decode([RemoteExercise].self, from: data).map { $0.toContentExercise() }
        }
        cachedExercises = result
        return result
    }

    public func fetchPrograms() async throws -> [ContentProgram] {
        if let cached = cachedPrograms { return cached }
        let result = try await fetchWithFallback(
            table: "programs",
            cachedFile: "programs.json",
            bundled: BundledContentProvider.programs,
            cacheKey: \.id
        ) { data in
            try JSONDecoder().decode([RemoteProgram].self, from: data).map { $0.toContentProgram() }
        }
        cachedPrograms = result
        return result
    }

    public func fetchBenchmarks() async throws -> [ContentBenchmark] {
        if let cached = cachedBenchmarks { return cached }
        let result = try await fetchWithFallback(
            table: "benchmarks",
            cachedFile: "benchmarks.json",
            bundled: BundledContentProvider.benchmarks,
            cacheKey: \.id
        ) { data in
            try JSONDecoder().decode([RemoteBenchmark].self, from: data).map { $0.toContentBenchmark() }
        }
        cachedBenchmarks = result
        return result
    }

    // MARK: - Merge

    /// Merge remote items over bundled items. Remote items with matching IDs replace bundled;
    /// new remote IDs are appended.
    public static func merge<T: Identifiable & Equatable>(
        bundled: [T],
        remote: [T]
    ) -> [T] {
        var result = bundled
        let bundledIDs = Set(bundled.map { $0.id as! String })

        for item in remote {
            if bundledIDs.contains(item.id as! String) {
                // Replace bundled item at same position
                if let index = result.firstIndex(where: { $0.id as! String == item.id as! String }) {
                    result[index] = item
                }
            } else {
                result.append(item)
            }
        }

        return result
    }

    // MARK: - Private

    private func fetchWithFallback<T: Identifiable>(
        table: String,
        cachedFile: String,
        bundled: [T],
        cacheKey: KeyPath<T, String>,
        decode: (Data) throws -> [T]
    ) async throws -> [T] {
        // Try remote fetch
        do {
            let remoteItems = try await fetchFromAPI(table: table, decode: decode)
            let merged = Self.merge(bundled: bundled, remote: remoteItems)
            // Cache the result
            try? saveToCache(merged, file: cachedFile)
            return merged
        } catch {
            // Try loading from file cache
            if let cached = loadFromCache(file: cachedFile, decode: decode) {
                return cached
            }
            // Fall back to bundled
            return bundled
        }
    }

    private func fetchFromAPI<T>(
        table: String,
        decode: (Data) throws -> [T]
    ) async throws -> [T] {
        guard let url = URL(string: "\(baseURL)/api/v1/table/\(table)/list") else {
            throw ContentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["where": "status='published'", "limit": 200])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ContentError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        // Teenybase wraps results in { data: [...] }
        struct APIResponse<T: Decodable>: Decodable {
            let data: [T]?
        }

        let wrapper = try JSONDecoder().decode(APIResponse<T>.self, from: data)
        return wrapper.data ?? []
    }

    private func saveToCache<T: Encodable>(_ items: [T], file: String) throws {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(items)
        try data.write(to: cacheDirectory.appendingPathComponent(file))
    }

    private func loadFromCache<T>(file: String, decode: (Data) throws -> [T]) -> [T]? {
        let url = cacheDirectory.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }
}

// MARK: - Error Types

public enum ContentError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError(let msg): return "Decoding error: \(msg)"
        }
    }
}

// MARK: - Remote Decoding Types

/// Decodable wrapper for remote exercise from Teenybase
struct RemoteExercise: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let bodyweight: Bool?
    let equipment: String?
    let movementTags: String?
    let sortOrder: Int?

    func toContentExercise() -> ContentExercise {
        ContentExercise(
            id: id ?? UUID().uuidString,
            name: name ?? "Unknown",
            category: category ?? "Unknown",
            bodyweight: bodyweight ?? false,
            equipment: equipment.flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) },
            movementTags: movementTags.flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) },
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }
}

/// Decodable wrapper for remote program from Teenybase
struct RemoteProgram: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let description: String?
    let durationWeeks: Int?
    let sessionsPerWeek: Int?
    let difficulty: String?
    let phases: String?
    let sortOrder: Int?

    func toContentProgram() -> ContentProgram {
        ContentProgram(
            id: id ?? UUID().uuidString,
            name: name ?? "Unknown",
            category: category ?? "custom",
            description: description ?? "",
            durationWeeks: durationWeeks ?? 4,
            sessionsPerWeek: sessionsPerWeek ?? 3,
            difficulty: difficulty ?? "intermediate",
            phases: phases,
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }
}

/// Decodable wrapper for remote benchmark from Teenybase
struct RemoteBenchmark: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let workoutDescription: String?
    let scoringType: String?
    let intensity: Int?
    let movementTags: String?
    let equipment: String?
    let timeDomain: String?
    let coachNotes: String?
    let sortOrder: Int?

    func toContentBenchmark() -> ContentBenchmark {
        ContentBenchmark(
            id: id ?? UUID().uuidString,
            name: name ?? "Unknown",
            category: category ?? "General Fitness",
            workoutDescription: workoutDescription ?? "",
            scoringType: scoringType ?? "reps",
            intensity: intensity,
            movementTags: movementTags.flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) },
            equipment: equipment.flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) },
            timeDomain: timeDomain,
            coachNotes: coachNotes,
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter RemoteContentClientTests 2>&1 | tail -10
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/RemoteContentClient.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/RemoteContentClientTests.swift && git commit -m "feat(data): add RemoteContentClient with fetch, cache, and fallback"
```

---

## Task 6: Wire ViewModels to ContentClientProtocol

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift`

- [ ] **Step 1: Update BenchmarksListViewModel**

In `BenchmarksViewModel.swift`, add a `ContentClientProtocol` dependency to `BenchmarksListViewModel` and replace the `updateBenchmarksForCategory` method:

Add property:
```swift
private let contentClient: ContentClientProtocol
```

Update init:
```swift
public init(
    dataClient: DataClientProtocol = DataClientFactory.shared.client,
    healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
    contentClient: ContentClientProtocol? = nil
) {
    self.dataClient = dataClient
    self.healthClient = healthClient
    self.contentClient = contentClient ?? RemoteContentClient(
        baseURL: ContentConfig.baseURL,
        token: ContentConfig.adminToken,
        cacheDirectory: ContentConfig.cacheDirectory
    )
}
```

Replace `updateBenchmarksForCategory`:
```swift
private func updateBenchmarksForCategory() {
    Task {
        do {
            let allContent = try await contentClient.fetchBenchmarks()
            benchmarks = allContent
                .filter { $0.category == selectedCategory }
                .sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            // Fallback to bundled catalog
            benchmarks = BenchmarkCatalog.benchmarks(in: selectedCategory).map { def in
                ContentBenchmark(
                    id: def.id, name: def.name, category: def.category,
                    workoutDescription: def.workoutDescription,
                    scoringType: def.scoringType.rawValue,
                    intensity: def.intensity?.rawValue,
                    movementTags: def.movementTags, equipment: def.equipment,
                    timeDomain: def.timeDomain, coachNotes: def.coachNotes,
                    sortOrder: def.sortOrder, source: .bundled
                )
            }
        }
    }
}
```

Update `getBestResult` and `formatScore` to work with `ContentBenchmark` instead of `BenchmarkDefinition`:

```swift
public func getBestResult(for benchmarkId: String) -> BenchmarkResult? {
    guard let results = userResults[benchmarkId] else { return nil }
    let scoringType = benchmarks.first { $0.id == benchmarkId }?.scoringType ?? "reps"
    if scoringType == "time" {
        return results.min(by: { $0.score < $1.score })
    } else {
        return results.max(by: { $0.score < $1.score })
    }
}
```

- [ ] **Step 2: Update ProgramsListViewModel**

In `ProgramsListView.swift`, update `ProgramsListViewModel` to use `ContentClientProtocol`:

Add property:
```swift
private let contentClient: ContentClientProtocol
```

Update init:
```swift
init(
    dataClient: DataClientProtocol = DataClientFactory.shared.client,
    contentClient: ContentClientProtocol? = nil
) {
    self.dataClient = dataClient
    self.contentClient = contentClient ?? RemoteContentClient(
        baseURL: ContentConfig.baseURL,
        token: ContentConfig.adminToken,
        cacheDirectory: ContentConfig.cacheDirectory
    )
}
```

Replace `loadPrograms` body:
```swift
func loadPrograms() async {
    isLoading = true

    // Load enrolled programs from CloudKit
    var enrolledIds: Set<String> = []
    do {
        let enrolled = try await dataClient.fetchAll(
            recordType: "EnrolledProgramRecord"
        ) as [EnrolledProgramRecord]
        enrolledIds = Set(enrolled.filter(\.isActive).map(\.id))
    } catch {
        errorMessage = "Failed to load programs: \(error.localizedDescription)"
    }

    // Fetch programs from content client (remote + bundled)
    do {
        let contentPrograms = try await contentClient.fetchPrograms()
        programs = contentPrograms.map { prog in
            ProgramListItem(
                id: prog.id,
                name: prog.name,
                category: prog.category,
                description: prog.description,
                durationWeeks: prog.durationWeeks,
                sessionsPerWeek: prog.sessionsPerWeek,
                difficulty: prog.difficulty,
                isEnrolled: enrolledIds.contains(prog.id)
            )
        }
    } catch {
        // Fallback to bundled templates
        programs = ProgramTemplate.allCases.map { template in
            let program = generateProgram(template: template, name: templateDisplayName(template))
            return ProgramListItem(
                id: program.id,
                name: program.name,
                category: program.category,
                description: program.description,
                durationWeeks: program.durationWeeks,
                sessionsPerWeek: program.sessionsPerWeek,
                difficulty: program.difficulty,
                isEnrolled: enrolledIds.contains(program.id)
            )
        }
    }

    isLoading = false
}
```

- [ ] **Step 3: Create ContentConfig**

Create `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/ContentConfig.swift`:

```swift
import Foundation

/// Configuration for remote content fetching
public struct ContentConfig: Sendable {
    public static var baseURL: String {
        // TODO: Replace with production URL when deployed
        return "http://localhost:8787"
    }

    public static var adminToken: String {
        return "password_for_accessing_the_backend_as_admin"
    }

    public static var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ContentCache")
    }
}
```

- [ ] **Step 4: Build to verify compilation**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Run all tests**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test 2>&1 | tail -10
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift SundeeFundee/Sources/SundeeFundeeKit/DataLayer/ContentConfig.swift && git commit -m "feat(ui): wire ViewModels to ContentClientProtocol for remote content"
```

---

## Task 7: Seed Backend with Current Content

**Files:**
- None (API calls only)

- [ ] **Step 1: Seed exercises via admin dashboard**

Start the backend:
```bash
cd SundeeFundeeApp/backend && npm run dev
```

Open `http://localhost:8787/admin`, enter admin token (`password_for_accessing_the_backend_as_admin`), then use the admin to add a few benchmark entries manually to verify the round-trip works.

Alternatively, seed via curl:
```bash
TOKEN="password_for_accessing_the_backend_as_admin"
DB_URL="http://localhost:8787"

# Seed one benchmark as a test
curl -s -X POST "$DB_URL/api/v1/table/benchmarks/insert" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"values": {
    "name": "Test Benchmark",
    "category": "General Fitness",
    "workoutDescription": "20 AMRAP: 5 pull-ups, 10 push-ups, 15 air squats",
    "scoringType": "roundsAndReps",
    "intensity": 3,
    "status": "published",
    "sortOrder": 100
  }, "returning": "*"}'
```

Expected: 200 OK with the created record.

- [ ] **Step 2: Verify app fetches the seeded content**

Run the app in simulator, navigate to Benchmarks, select "General Fitness" category. The "Test Benchmark" should appear.

- [ ] **Step 3: Commit any config changes**

If `ContentConfig.swift` needed URL updates, commit those.

```bash
cd /Users/dustinober/Projects/sundee-fundee && git add -A && git commit -m "feat(config): configure content API URL for local development"
```

---

## Task 8: Verify End-to-End Flow

**Files:**
- None (manual verification)

- [ ] **Step 1: Test the full flow**

1. Start backend: `cd SundeeFundeeApp/backend && npm run dev`
2. Open admin at `http://localhost:8787/admin`
3. Add a new benchmark with status "draft" — verify it does NOT appear in the app
4. Change the benchmark to "published" — verify it DOES appear after app refresh
5. Turn off backend — verify the app still shows all bundled content

- [ ] **Step 2: Run full test suite**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test 2>&1 | tail -10
```
Expected: All tests PASS.

- [ ] **Step 3: Run Xcode build**

Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED
