# CloudKit Benchmark Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the iOS app to fetch admin-published benchmarks from CloudKit Public DB, with bundled JSON fallback, so new benchmarks published from the WOD Dashboard appear in the app.

**Architecture:** Add an async `RemoteBenchmarkDefinitionRepository` protocol with Bundled and CloudKit implementations (mirroring the existing `ProgramRepository` pattern). The ViewModel merges three sources: hardcoded predefined (BenchmarkCatalog), remote (CloudKit/bundled JSON), and user-created (SwiftData). Note: `BenchmarkDefinition` is a SwiftData `@Model` (not a plain struct like `Program`), so the protocol omits `Sendable` and the bundled repo caches DTOs rather than `@Model` instances to avoid data races.

**Tech Stack:** Swift 6, SwiftUI, CloudKit, SwiftData

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift` | Protocol + BundledBenchmarkDefinitionRepository + CloudKitBenchmarkDefinitionRepository |
| Modify | `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` | Add `RemoteBenchmarkDefinitionRepository` protocol |
| Modify | `SundeeFundee/Domain/BenchmarkCatalog.swift` | Add "Sundee Fundee" to `categoryOrder` |
| Modify | `SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift` | Accept remote repo, merge remote benchmarks |
| Create | `SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift` | Tests for Bundled + CloudKit repos |
| Modify | `SundeeFundeTests/BenchmarksViewModelTests.swift` | Tests for remote benchmark merging |
| Modify | `SundeeFundeTests/BenchmarkModelTests.swift` | Test "Sundee Fundee" in categoryOrder |

---

### Task 1: Add RemoteBenchmarkDefinitionRepository Protocol

**Files:**
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift:79` (after BenchmarkDefinitionRepository)

- [ ] **Step 1: Add protocol to RepositoryProtocols.swift**

Insert after the `BenchmarkDefinitionRepository` block (after line 79):

```swift
// MARK: - RemoteBenchmarkDefinitionRepository

/// Async protocol for fetching admin-published benchmark definitions from CloudKit or bundled JSON.
/// Not Sendable because BenchmarkDefinition is a SwiftData @Model (not a plain struct).
protocol RemoteBenchmarkDefinitionRepository {
    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition]
}
```

- [ ] **Step 2: Build to verify no compile errors**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift
git commit -m "feat: add RemoteBenchmarkDefinitionRepository protocol"
```

---

### Task 2: Implement BundledBenchmarkDefinitionRepository

**Files:**
- Create: `SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift`
- Test: `SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift`

- [ ] **Step 1: Write the failing test**

Create `SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("BundledBenchmarkDefinitionRepository")
struct BundledBenchmarkDefinitionRepositoryTests {

    @Test func fetchesFromBundledJSON() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
        // benchmarks.json contains "Sundee Fundee" category entries
        #expect(defs.allSatisfy { $0.category == "Sundee Fundee" })
        #expect(defs.allSatisfy { $0.isPredefined == true })
        #expect(defs.allSatisfy { $0.userID == "" })
    }

    @Test func returnsEmptyForMissingBundle() async throws {
        let repo = BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent")
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.isEmpty)
    }

    @Test func cachesResults() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let first = try await repo.fetchBenchmarkDefinitions()
        let second = try await repo.fetchBenchmarkDefinitions()
        #expect(first.count == second.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BundledBenchmarkDefinitionRepositoryTests 2>&1 | tail -10`
Expected: FAIL (type not found)

- [ ] **Step 3: Implement BundledBenchmarkDefinitionRepository**

Create `SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift`:

```swift
import Foundation
import CloudKit

// MARK: - BenchmarkDefinitionDTO

/// Lightweight Codable struct for decoding benchmarks.json and CloudKit records.
/// Mapped to BenchmarkDefinition (SwiftData @Model) at the call site.
private struct BenchmarkDefinitionDTO: Codable {
    let id: String
    let name: String
    let category: String
    let workoutDescription: String
    let scoringTypeRaw: String
    let sortOrder: Int

    func toBenchmarkDefinition() -> BenchmarkDefinition {
        BenchmarkDefinition(
            id: id,
            userID: "",
            name: name,
            category: category,
            workoutDescription: workoutDescription,
            scoringType: BenchmarkScoringType(rawValue: scoringTypeRaw) ?? .time,
            isPredefined: true,
            sortOrder: sortOrder
        )
    }
}

// MARK: - BundledBenchmarkDefinitionRepository

/// Loads benchmark definitions from the bundled benchmarks.json file.
/// Caches the raw DTOs (not @Model instances) to avoid SwiftData data races.
final class BundledBenchmarkDefinitionRepository: RemoteBenchmarkDefinitionRepository {
    private let bundle: Bundle
    private let resourceName: String
    private var dtoCache: [BenchmarkDefinitionDTO]?

    init(bundle: Bundle = .main, resourceName: String = "benchmarks") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        if let dtoCache { return dtoCache.map { $0.toBenchmarkDefinition() } }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([BenchmarkDefinitionDTO].self, from: data)
        dtoCache = dtos
        return dtos.map { $0.toBenchmarkDefinition() }
    }
}
```

- [ ] **Step 4: Verify benchmarks.json is accessible from test bundle**

The test calls `BundledBenchmarkDefinitionRepository()` which defaults to `Bundle.main`. In the test host, `Bundle.main` is the app bundle (SundeeFundee.app), which already includes `benchmarks.json` via the `Resources/Benchmarks/` directory in `project.yml`. If the `fetchesFromBundledJSON` test returns empty, check that `benchmarks.json` is copied to the app bundle's resources.

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BundledBenchmarkDefinitionRepositoryTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift
git commit -m "feat: add BundledBenchmarkDefinitionRepository with tests"
```

---

### Task 3: Implement CloudKitBenchmarkDefinitionRepository

**Files:**
- Modify: `SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift`
- Modify: `SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift`

- [ ] **Step 1: Write the failing tests**

Append to `SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift`:

```swift
@Suite("CloudKitBenchmarkDefinitionRepository")
struct CloudKitBenchmarkDefinitionRepositoryTests {

    @Test func fetchesFromCloudKit() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudFetcher: {
                [BenchmarkDefinition(
                    id: "ck-1", userID: "", name: "CloudKit Bench",
                    category: "Sundee Fundee", workoutDescription: "Test",
                    scoringType: .time, isPredefined: true, sortOrder: 1
                )]
            }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "CloudKit Bench")
    }

    @Test func fallsBackWhenCloudKitFails() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(),
            cloudFetcher: { throw CKError(.networkUnavailable) }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        // Should get bundled benchmarks.json entries
        #expect(!defs.isEmpty)
    }

    @Test func fallsBackWhenCloudKitReturnsEmpty() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(),
            cloudFetcher: { [] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
    }

    @Test func decodesCloudKitRecords() async throws {
        let recordID = CKRecord.ID(recordName: "bench-1")
        let record = CKRecord(recordType: "BenchmarkDefinition", recordID: recordID)
        record["id"] = "bench-1" as CKRecordValue
        record["name"] = "Test WOD" as CKRecordValue
        record["category"] = "Sundee Fundee" as CKRecordValue
        record["workoutDescription"] = "Do stuff" as CKRecordValue
        record["scoringTypeRaw"] = "time" as CKRecordValue
        record["sortOrder"] = Int64(1) as CKRecordValue

        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudRecordFetcher: { _ in [(recordID, .success(record))] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "Test WOD")
        #expect(defs[0].scoringTypeRaw == "time")
        #expect(defs[0].isPredefined == true)
    }

    @Test func skipsInvalidCloudKitRecords() async throws {
        let goodID = CKRecord.ID(recordName: "bench-good")
        let good = CKRecord(recordType: "BenchmarkDefinition", recordID: goodID)
        good["id"] = "bench-good" as CKRecordValue
        good["name"] = "Good" as CKRecordValue
        good["category"] = "Sundee Fundee" as CKRecordValue
        good["workoutDescription"] = "OK" as CKRecordValue
        good["scoringTypeRaw"] = "reps" as CKRecordValue
        good["sortOrder"] = 1 as CKRecordValue

        let badID = CKRecord.ID(recordName: "bench-bad")
        let bad = CKRecord(recordType: "BenchmarkDefinition", recordID: badID)
        // Missing required fields

        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudRecordFetcher: { _ in [(goodID, .success(good)), (badID, .success(bad))] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "Good")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/CloudKitBenchmarkDefinitionRepositoryTests 2>&1 | tail -10`
Expected: FAIL (type not found)

- [ ] **Step 3: Implement CloudKitBenchmarkDefinitionRepository**

Append to `SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift`:

```swift
// MARK: - CloudKitBenchmarkDefinitionRepository

final class CloudKitBenchmarkDefinitionRepository: RemoteBenchmarkDefinitionRepository {
    typealias CloudRecordFetcher = @Sendable (CKQuery) async throws -> [(CKRecord.ID, Result<CKRecord, Error>)]

    private let cloudFetcher: () async throws -> [BenchmarkDefinition]
    private let fallback: RemoteBenchmarkDefinitionRepository

    init(
        containerID: String = "iCloud.com.sundeefundee.app",
        fallback: RemoteBenchmarkDefinitionRepository = BundledBenchmarkDefinitionRepository(),
        cloudQueryExecutor: CloudRecordFetcher? = nil
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            if let cloudQueryExecutor {
                return try await Self.fetchFromCloudKit(cloudQueryExecutor)
            }
            guard CloudKitWODRepository.hasCloudKitEntitlement else {
                throw CKError(.notAuthenticated)
            }
            return try await Self.fetchFromCloudKit { query in
                return try await CKContainer(identifier: containerID).publicCloudDatabase.records(matching: query).matchResults
            }
        }
    }

    init(
        fallback: RemoteBenchmarkDefinitionRepository,
        cloudRecordFetcher: @escaping CloudRecordFetcher
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            try await Self.fetchFromCloudKit(cloudRecordFetcher)
        }
    }

    init(
        fallback: RemoteBenchmarkDefinitionRepository,
        cloudFetcher: @escaping () async throws -> [BenchmarkDefinition]
    ) {
        self.fallback = fallback
        self.cloudFetcher = cloudFetcher
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        do {
            let defs = try await cloudFetcher()
            if defs.isEmpty {
                return try await fallback.fetchBenchmarkDefinitions()
            }
            return defs
        } catch {
            return try await fallback.fetchBenchmarkDefinitions()
        }
    }

    private static func fetchFromCloudKit(_ cloudRecordFetcher: CloudRecordFetcher) async throws -> [BenchmarkDefinition] {
        let query = CKQuery(recordType: "BenchmarkDefinition", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let matchResults = try await cloudRecordFetcher(query)
        return matchResults.compactMap { _, recordResult -> BenchmarkDefinition? in
            guard let record = try? recordResult.get(),
                  let id = record["id"] as? String,
                  let name = record["name"] as? String,
                  let category = record["category"] as? String,
                  let workoutDescription = record["workoutDescription"] as? String,
                  let scoringTypeRaw = record["scoringTypeRaw"] as? String,
                  let sortOrder = (record["sortOrder"] as? Int64).map(Int.init)
            else { return nil }
            return BenchmarkDefinition(
                id: id,
                userID: "",
                name: name,
                category: category,
                workoutDescription: workoutDescription,
                scoringType: BenchmarkScoringType(rawValue: scoringTypeRaw) ?? .time,
                isPredefined: true,
                sortOrder: sortOrder
            )
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/CloudKitBenchmarkDefinitionRepositoryTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Repositories/RemoteBenchmarkDefinitionRepository.swift SundeeFundeTests/RemoteBenchmarkDefinitionRepositoryTests.swift
git commit -m "feat: add CloudKitBenchmarkDefinitionRepository with fallback"
```

---

### Task 4: Add "Sundee Fundee" to BenchmarkCatalog.categoryOrder

**Files:**
- Modify: `SundeeFundee/Domain/BenchmarkCatalog.swift:81`
- Modify: `SundeeFundeTests/BenchmarkModelTests.swift`

- [ ] **Step 1: Write the failing test**

Add to `BenchmarkCatalogTests` in `SundeeFundeTests/BenchmarkModelTests.swift`:

```swift
@Test func categoryOrderIncludesSundeeFundee() {
    #expect(BenchmarkCatalog.categoryOrder.contains("Sundee Fundee"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BenchmarkCatalogTests/categoryOrderIncludesSundeeFundee 2>&1 | tail -10`
Expected: FAIL

- [ ] **Step 3: Add category constant and update categoryOrder**

In `SundeeFundee/Domain/BenchmarkCatalog.swift`:

Add after line 15 (`static let generalFitness = "General Fitness"`):
```swift
    static let sundeeFundee   = "Sundee Fundee"
```

Update line 81 (`categoryOrder`) to:
```swift
    static let categoryOrder: [String] = [sundeeFundee, crossfitWOD, strength, endurance, gymnastics, generalFitness]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BenchmarkCatalogTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Domain/BenchmarkCatalog.swift SundeeFundeTests/BenchmarkModelTests.swift
git commit -m "feat: add Sundee Fundee to BenchmarkCatalog.categoryOrder"
```

---

### Task 5: Wire Remote Repo into BenchmarksViewModel

**Files:**
- Modify: `SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift`
- Modify: `SundeeFundeTests/BenchmarksViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Add to `BenchmarksViewModelTests` in `SundeeFundeTests/BenchmarksViewModelTests.swift`:

```swift
@Test
@MainActor
func loadsRemoteBenchmarks() async throws {
    let container = try makeContainer()
    let remoteDefs = [
        BenchmarkDefinition(
            id: "sf-1", userID: "", name: "Eliz",
            category: "Sundee Fundee", workoutDescription: "5 rounds",
            scoringType: .time, isPredefined: true, sortOrder: 1
        )
    ]
    let vm = BenchmarksViewModel(remoteRepo: MockRemoteBenchmarkRepo(defs: remoteDefs))
    await vm.load(modelContext: container.mainContext, userID: "u1")
    let sfGroup = vm.categoryGroups.first { $0.category == "Sundee Fundee" }
    #expect(sfGroup != nil)
    #expect(sfGroup?.definitions.first?.name == "Eliz")
}

@Test
@MainActor
func remoteBenchmarkFailureStillLoadsOthers() async throws {
    let container = try makeContainer()
    let vm = BenchmarksViewModel(remoteRepo: MockRemoteBenchmarkRepo(shouldFail: true))
    await vm.load(modelContext: container.mainContext, userID: "u1")
    // Should still have predefined catalog entries
    #expect(!vm.categoryGroups.isEmpty)
    #expect(vm.categoryGroups.contains { $0.category == "Classic WODs" })
}
```

Add a helper mock at the bottom of the test file:

```swift
private final class MockRemoteBenchmarkRepo: RemoteBenchmarkDefinitionRepository {
    let defs: [BenchmarkDefinition]
    let shouldFail: Bool

    init(defs: [BenchmarkDefinition] = [], shouldFail: Bool = false) {
        self.defs = defs
        self.shouldFail = shouldFail
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        if shouldFail { throw NSError(domain: "test", code: 1) }
        return defs
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BenchmarksViewModelTests 2>&1 | tail -10`
Expected: FAIL (init parameter not found)

- [ ] **Step 3: Update BenchmarksViewModel to accept and use remote repo**

Modify `SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift`:

Add property (after `definitionRepoFactory` on line 23):
```swift
    private let remoteRepo: (any RemoteBenchmarkDefinitionRepository)?
```

Update init (lines 25-31) to:
```swift
    init(
        definitionRepoFactory: @escaping (ModelContext) -> any BenchmarkDefinitionRepository = {
            SwiftDataBenchmarkDefinitionRepository(context: $0)
        },
        remoteRepo: (any RemoteBenchmarkDefinitionRepository)? = CloudKitBenchmarkDefinitionRepository()
    ) {
        self.definitionRepoFactory = definitionRepoFactory
        self.remoteRepo = remoteRepo
    }
```

Update `load` method (lines 33-58) to fetch remote benchmarks and merge:
```swift
    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }

        let repo = definitionRepoFactory(modelContext)
        let userCreated = (try? repo.fetchUserCreated(userID: userID)) ?? []
        let remote = (try? await remoteRepo?.fetchBenchmarkDefinitions()) ?? []

        var grouped: [String: [BenchmarkDefinition]] = [:]
        for def in BenchmarkCatalog.predefined + remote + userCreated {
            grouped[def.category, default: []].append(def)
        }

        categoryGroups = BenchmarkCatalog.categoryOrder.compactMap { cat in
            guard let entries = grouped[cat], !entries.isEmpty else { return nil }
            return CategoryGroup(category: cat, definitions: entries.sorted { $0.sortOrder < $1.sortOrder })
        }
        let known = Set(BenchmarkCatalog.categoryOrder)
        for (cat, entries) in grouped where !known.contains(cat) {
            categoryGroups.append(CategoryGroup(category: cat, definitions: entries))
        }
    }
```

- [ ] **Step 4: Update existing tests to pass `remoteRepo: nil` to isolate from CloudKit**

In `BenchmarksViewModelTests`, update all four existing tests. Each one creates `BenchmarksViewModel()` — change to `BenchmarksViewModel(remoteRepo: nil)`:

```swift
// In loadsGroupsFromCatalog:
let vm = BenchmarksViewModel(remoteRepo: nil)

// In addCustomDefinitionAppearsInGroups:
let vm = BenchmarksViewModel(remoteRepo: nil)

// In deleteCustomDefinitionRemovesIt:
let vm = BenchmarksViewModel(remoteRepo: nil)

// In cannotDeletePredefinedDefinition:
let vm = BenchmarksViewModel(remoteRepo: nil)
```

This ensures existing tests don't depend on bundled JSON or CloudKit availability. Without this, the default `CloudKitBenchmarkDefinitionRepository()` would silently inject 5 bundled "Sundee Fundee" benchmarks into the results, making `cannotDeletePredefinedDefinition`'s count assertion fragile.

- [ ] **Step 5: Run all tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BenchmarksViewModelTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift SundeeFundeTests/BenchmarksViewModelTests.swift
git commit -m "feat: wire CloudKit benchmark repo into BenchmarksViewModel"
```

---

### Task 6: Run Full Test Suite and Verify Build

- [ ] **Step 1: Run full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 2: Fix any broken tests**

Tests to watch for:
- `BenchmarkModelTests` — `BenchmarkCatalogTests` asserts on categoryOrder; verify the new "Sundee Fundee" entry doesn't break sort-order or group assertions.
- `BenchmarksViewModelTests` — existing tests now get `remoteRepo: nil` so they should be isolated.
- `AppAuthCoverageTests` — no schema changes so should be unaffected.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve test regressions from benchmark CloudKit sync"
```
