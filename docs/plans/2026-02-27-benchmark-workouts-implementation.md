# Benchmark Workouts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the freeform `Benchmark` model with a catalog-driven benchmark system supporting predefined named workouts (CrossFit WODs, strength, endurance, gymnastics) and user-created custom benchmarks, with scoring adapted per workout type (time, reps, weight).

**Architecture:** Two new SwiftData models — `BenchmarkDefinition` (what the workout is) and `BenchmarkResult` (how the user did) — replace the existing `Benchmark` model. A hardcoded `BenchmarkCatalog` (like `WeightliftingExerciseCatalog`) ships predefined workouts. A `BenchmarkScoringType` enum drives adaptive UI for logging results. Schema advances to V2 with a lightweight destructive migration for the old `Benchmark` model.

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Testing (`@Suite`, `@Test`), Swift Charts

**Design doc:** `docs/plans/2026-02-27-benchmark-workouts-design.md`

---

## Existing Code to Understand First

Before starting, read these files (don't modify yet):
- `SundeeFundee/Models/Benchmark.swift` — the model being replaced
- `SundeeFundee/Domain/WeightliftingExerciseCatalog.swift` — pattern to follow for the catalog
- `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` — where to add new protocols
- `SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkRepository.swift` — pattern to follow
- `SundeeFundee/App/AppSchemaV1.swift` — schema to version up from
- `SundeeFundee/App/AppSchemaMigrationPlan.swift` — migration plan to update
- `SundeeFundee/Features/Benchmarks/BenchmarksView.swift` — UI to replace
- `SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift` — VM to replace
- `SundeeFundeTests/RepositoryCoverageTests.swift` — test patterns to follow

---

## Task 1: Add `BenchmarkScoringType` enum and `BenchmarkDefinition` model

**Files:**
- Create: `SundeeFundee/Models/BenchmarkDefinition.swift`
- Modify: `SundeeFundee/Models/Benchmark.swift` (delete content — replace entire file)

**Step 1: Write the failing test**

Add a new file `SundeeFundeTests/BenchmarkModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDefinition Model")
struct BenchmarkDefinitionTests {

    @Test func scoringTypeRoundTrips() {
        for type in BenchmarkScoringType.allCases {
            #expect(BenchmarkScoringType(rawValue: type.rawValue) == type)
        }
    }

    @Test func definitionInit() {
        let def = BenchmarkDefinition(
            userID: "",
            name: "Fran",
            category: "CrossFit WOD",
            workoutDescription: "21-15-9: Thrusters + Pull-ups",
            scoringType: .time,
            isPredefined: true,
            sortOrder: 0
        )
        #expect(def.name == "Fran")
        #expect(def.scoringType == BenchmarkScoringType.time.rawValue)
        #expect(def.isPredefined == true)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDefinitionTests 2>&1 | tail -20
```
Expected: compile error — `BenchmarkScoringType` and `BenchmarkDefinition` not found.

**Step 3: Create `SundeeFundee/Models/BenchmarkDefinition.swift`**

```swift
import SwiftData
import Foundation

/// Scoring category for a benchmark workout.
/// Determines how the result is displayed and which input field is shown when logging.
enum BenchmarkScoringType: String, Codable, CaseIterable {
    /// Lower is better — stored as total seconds (Double).
    case time
    /// Higher is better — stored as whole number cast to Double.
    case reps
    /// Higher is better — stored as kilograms (Double).
    case weight
    /// Fixed distance, logged as time in seconds — lower is better.
    case distance
}

/// A named benchmark workout definition — either predefined (ships with the app)
/// or user-created (stored in SwiftData with a non-empty userID).
@Model
final class BenchmarkDefinition {
    var id: String
    /// Empty string for predefined catalog entries; user's ID for custom definitions.
    var userID: String
    var name: String
    var category: String
    var workoutDescription: String
    /// Raw value of `BenchmarkScoringType`.
    var scoringType: String
    var isPredefined: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        category: String,
        workoutDescription: String,
        scoringType: BenchmarkScoringType,
        isPredefined: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.category = category
        self.workoutDescription = workoutDescription
        self.scoringType = scoringType.rawValue
        self.isPredefined = isPredefined
        self.sortOrder = sortOrder
    }

    var resolvedScoringType: BenchmarkScoringType {
        BenchmarkScoringType(rawValue: scoringType) ?? .time
    }
}
```

**Step 4: Replace `SundeeFundee/Models/Benchmark.swift` entirely with:**

```swift
import SwiftData
import Foundation

/// A logged result for a named benchmark workout.
///
/// `scoreValue` interpretation depends on `BenchmarkDefinition.resolvedScoringType`:
/// - `.time` / `.distance` → total seconds (lower is better)
/// - `.weight` → kilograms (higher is better)
/// - `.reps` → count cast as Double (higher is better)
@Model
final class BenchmarkResult {
    var id: String
    var userID: String
    /// ID of the `BenchmarkDefinition` this result belongs to.
    var definitionID: String
    var scoreValue: Double
    var notes: String
    var performedAt: Date

    init(
        id: String = UUID().uuidString,
        userID: String,
        definitionID: String,
        scoreValue: Double,
        notes: String = "",
        performedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.definitionID = definitionID
        self.scoreValue = scoreValue
        self.notes = notes
        self.performedAt = performedAt
    }
}
```

**Step 5: Run test to verify it passes**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDefinitionTests 2>&1 | tail -20
```
Expected: PASS

**Step 6: Commit**

```bash
git add SundeeFundee/Models/BenchmarkDefinition.swift SundeeFundee/Models/Benchmark.swift SundeeFundeTests/BenchmarkModelTests.swift
git commit -m "feat: add BenchmarkDefinition, BenchmarkResult, and BenchmarkScoringType models"
```

---

## Task 2: Add `BenchmarkCatalog`

**Files:**
- Create: `SundeeFundee/Domain/BenchmarkCatalog.swift`

**Step 1: Write the failing test**

Add to `SundeeFundeTests/BenchmarkModelTests.swift`:

```swift
@Suite("BenchmarkCatalog")
struct BenchmarkCatalogTests {

    @Test func catalogIsNotEmpty() {
        #expect(!BenchmarkCatalog.predefined.isEmpty)
    }

    @Test func allEntriesHaveUniqueNames() {
        let names = BenchmarkCatalog.predefined.map(\.name)
        #expect(names.count == Set(names).count)
    }

    @Test func allScoringTypesAreValid() {
        for entry in BenchmarkCatalog.predefined {
            #expect(BenchmarkScoringType(rawValue: entry.scoringType) != nil)
        }
    }

    @Test func categoriesGroupedCorrectly() {
        let grouped = BenchmarkCatalog.groupedByCategory
        #expect(!grouped.isEmpty)
        for (_, entries) in grouped {
            #expect(!entries.isEmpty)
        }
    }

    @Test func franIsPresent() {
        let fran = BenchmarkCatalog.predefined.first { $0.name == "Fran" }
        #expect(fran != nil)
        #expect(fran?.scoringType == BenchmarkScoringType.time.rawValue)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkCatalogTests 2>&1 | tail -20
```
Expected: compile error — `BenchmarkCatalog` not found.

**Step 3: Create `SundeeFundee/Domain/BenchmarkCatalog.swift`**

```swift
import Foundation

/// Hardcoded catalog of predefined benchmark workouts shipped with the app.
///
/// Predefined entries have `userID = ""` and `isPredefined = true`.
/// User-created definitions are stored in SwiftData and merged at runtime.
enum BenchmarkCatalog {

    // MARK: - Category Constants

    static let crossfitWOD   = "CrossFit WOD"
    static let strength      = "Strength"
    static let endurance     = "Endurance"
    static let gymnastics    = "Gymnastics"
    static let generalFitness = "General Fitness"

    // MARK: - Predefined Definitions

    static let predefined: [BenchmarkDefinition] = {
        var entries: [BenchmarkDefinition] = []
        var order = 0

        func add(_ name: String, _ category: String, _ description: String, _ scoring: BenchmarkScoringType) {
            entries.append(BenchmarkDefinition(
                id: "predefined-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
                userID: "",
                name: name,
                category: category,
                workoutDescription: description,
                scoringType: scoring,
                isPredefined: true,
                sortOrder: order
            ))
            order += 1
        }

        // CrossFit WODs — Time
        add("Fran",   crossfitWOD, "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups", .time)
        add("Helen",  crossfitWOD, "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups", .time)
        add("Grace",  crossfitWOD, "For time: 30 Clean & Jerks (135/95 lb)", .time)
        add("Karen",  crossfitWOD, "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)", .time)
        add("DT",     crossfitWOD, "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)", .time)
        add("Murph",  crossfitWOD, "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.", .time)
        add("Annie",  crossfitWOD, "50-40-30-20-10 reps for time: Double-Unders, Sit-ups", .time)

        // CrossFit WODs — Reps/Rounds
        add("Cindy",          crossfitWOD, "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.", .reps)
        add("Fight Gone Bad", crossfitWOD, "3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20\"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.", .reps)

        // Strength — Weight (1RM)
        add("1RM Back Squat",      strength, "Find your 1-rep max back squat. Record the barbell weight only (not including bar unless noted).", .weight)
        add("1RM Deadlift",        strength, "Find your 1-rep max conventional deadlift.", .weight)
        add("1RM Bench Press",     strength, "Find your 1-rep max flat barbell bench press.", .weight)
        add("1RM Overhead Press",  strength, "Find your 1-rep max strict barbell overhead press.", .weight)
        add("1RM Clean & Jerk",    strength, "Find your 1-rep max clean & jerk.", .weight)
        add("1RM Snatch",          strength, "Find your 1-rep max snatch.", .weight)

        // Endurance — Time
        add("1-Mile Run",           endurance, "Run 1 mile (1.6 km) as fast as possible.", .distance)
        add("5K Run",               endurance, "Run 5 kilometers (3.1 miles) as fast as possible.", .distance)
        add("1.5-Mile Run",         endurance, "Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).", .distance)
        add("2K Row",               endurance, "Row 2000 meters on an ergometer as fast as possible.", .distance)

        // Gymnastics — Reps
        add("Max Pull-ups",            gymnastics, "Maximum strict pull-ups in one unbroken set.", .reps)
        add("Max Push-ups (2 min)",    gymnastics, "Maximum push-ups completed in 2 minutes.", .reps)
        add("Max Handstand Push-ups",  gymnastics, "Maximum strict handstand push-ups in one unbroken set.", .reps)
        add("Max Muscle-ups",          gymnastics, "Maximum ring or bar muscle-ups in one unbroken set.", .reps)

        // General Fitness
        add("100 Push-ups for Time", generalFitness, "Complete 100 push-ups as fast as possible. Rest as needed.", .time)
        add("100 Sit-ups for Time",  generalFitness, "Complete 100 sit-ups as fast as possible. Rest as needed.", .time)
        add("L-Sit Hold",            generalFitness, "Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.", .time)

        return entries
    }()

    // MARK: - Helpers

    /// All category names in display order.
    static let categoryOrder: [String] = [crossfitWOD, strength, endurance, gymnastics, generalFitness]

    /// Predefined entries grouped by category, in display order.
    static var groupedByCategory: [(category: String, entries: [BenchmarkDefinition])] {
        categoryOrder.compactMap { cat in
            let entries = predefined.filter { $0.category == cat }
            guard !entries.isEmpty else { return nil }
            return (category: cat, entries: entries)
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkCatalogTests 2>&1 | tail -20
```
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/BenchmarkCatalog.swift SundeeFundeTests/BenchmarkModelTests.swift
git commit -m "feat: add BenchmarkCatalog with 24 predefined workouts"
```

---

## Task 3: Repository protocols and SwiftData implementations

**Files:**
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
- Create: `SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkDefinitionRepository.swift`
- Create: `SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkResultRepository.swift`
- Delete: `SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkRepository.swift`

**Step 1: Write the failing test**

Add a new file `SundeeFundeTests/BenchmarkRepositoryTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarkDefinition Repository")
struct BenchmarkDefinitionRepositoryTests {

    @MainActor
    private func makeRepo() throws -> (SwiftDataBenchmarkDefinitionRepository, ModelContext) {
        let schema = Schema(AppSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo = SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)
        return (repo, container.mainContext)
    }

    @Test @MainActor
    func saveAndFetch() throws {
        let (repo, _) = try makeRepo()
        let def = BenchmarkDefinition(userID: "u1", name: "My WOD", category: "General Fitness",
                                      workoutDescription: "Run + burpees", scoringType: .time,
                                      isPredefined: false, sortOrder: 0)
        try repo.save(def)
        let fetched = try repo.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "My WOD")
    }

    @Test @MainActor
    func fetchUserCreated() throws {
        let (repo, _) = try makeRepo()
        let custom = BenchmarkDefinition(userID: "u1", name: "Custom", category: "General Fitness",
                                         workoutDescription: "desc", scoringType: .reps,
                                         isPredefined: false, sortOrder: 0)
        try repo.save(custom)
        let results = try repo.fetchUserCreated(userID: "u1")
        #expect(results.count == 1)
    }

    @Test @MainActor
    func delete() throws {
        let (repo, _) = try makeRepo()
        let def = BenchmarkDefinition(userID: "u1", name: "Delete Me", category: "Strength",
                                       workoutDescription: "1RM squat", scoringType: .weight,
                                       isPredefined: false, sortOrder: 0)
        try repo.save(def)
        try repo.delete(def)
        let fetched = try repo.fetchAll()
        #expect(fetched.isEmpty)
    }
}

@Suite("BenchmarkResult Repository")
struct BenchmarkResultRepositoryTests {

    @MainActor
    private func makeRepo() throws -> (SwiftDataBenchmarkResultRepository, ModelContext) {
        let schema = Schema(AppSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo = SwiftDataBenchmarkResultRepository(context: container.mainContext)
        return (repo, container.mainContext)
    }

    @Test @MainActor
    func saveAndFetchForDefinition() throws {
        let (repo, _) = try makeRepo()
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 210.0,
                                     notes: "PR!", performedAt: .now)
        try repo.save(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.count == 1)
        #expect(fetched[0].scoreValue == 210.0)
    }

    @Test @MainActor
    func delete() throws {
        let (repo, _) = try makeRepo()
        let result = BenchmarkResult(userID: "u1", definitionID: "def-1", scoreValue: 180.0)
        try repo.save(result)
        try repo.delete(result)
        let fetched = try repo.fetchResults(forDefinitionID: "def-1")
        #expect(fetched.isEmpty)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDefinitionRepositoryTests 2>&1 | tail -20
```
Expected: compile error — `AppSchemaV2`, `SwiftDataBenchmarkDefinitionRepository`, `SwiftDataBenchmarkResultRepository` not found.

**Step 3: Replace `BenchmarkRepository` protocol in `RepositoryProtocols.swift`**

Find the `// MARK: - BenchmarkRepository` block and replace with:

```swift
// MARK: - BenchmarkDefinitionRepository

protocol BenchmarkDefinitionRepository {
    func save(_ definition: BenchmarkDefinition) throws
    func fetchAll() throws -> [BenchmarkDefinition]
    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition]
    func delete(_ definition: BenchmarkDefinition) throws
}

// MARK: - BenchmarkResultRepository

protocol BenchmarkResultRepository {
    func save(_ result: BenchmarkResult) throws
    func fetchResults(forDefinitionID definitionID: String) throws -> [BenchmarkResult]
    func delete(_ result: BenchmarkResult) throws
}
```

**Step 4: Create `SwiftDataBenchmarkDefinitionRepository.swift`**

```swift
import Foundation
import SwiftData

final class SwiftDataBenchmarkDefinitionRepository: BenchmarkDefinitionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ definition: BenchmarkDefinition) throws {
        context.insert(definition)
        try context.save()
    }

    func fetchAll() throws -> [BenchmarkDefinition] {
        let descriptor = FetchDescriptor<BenchmarkDefinition>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition] {
        let descriptor = FetchDescriptor<BenchmarkDefinition>(
            predicate: #Predicate { $0.isPredefined == false && $0.userID == userID },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ definition: BenchmarkDefinition) throws {
        context.delete(definition)
        try context.save()
    }
}
```

**Step 5: Create `SwiftDataBenchmarkResultRepository.swift`**

```swift
import Foundation
import SwiftData

final class SwiftDataBenchmarkResultRepository: BenchmarkResultRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ result: BenchmarkResult) throws {
        context.insert(result)
        try context.save()
    }

    func fetchResults(forDefinitionID definitionID: String) throws -> [BenchmarkResult] {
        let descriptor = FetchDescriptor<BenchmarkResult>(
            predicate: #Predicate { $0.definitionID == definitionID },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ result: BenchmarkResult) throws {
        context.delete(result)
        try context.save()
    }
}
```

**Step 6: Delete the old file**

```bash
rm SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkRepository.swift
```

**Step 7: Run test to verify it passes**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDefinitionRepositoryTests -only-testing:SundeeFundeTests/BenchmarkResultRepositoryTests 2>&1 | tail -20
```
Expected: PASS

**Step 8: Commit**

```bash
git add SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift \
        SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkDefinitionRepository.swift \
        SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkResultRepository.swift \
        SundeeFundeTests/BenchmarkRepositoryTests.swift
git rm SundeeFundee/Repositories/SwiftData/SwiftDataBenchmarkRepository.swift
git commit -m "feat: add BenchmarkDefinition and BenchmarkResult repositories, remove old BenchmarkRepository"
```

---

## Task 4: Schema V2 and migration

**Files:**
- Create: `SundeeFundee/App/AppSchemaV2.swift`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Modify: `SundeeFundee/App/AppModelContainer.swift`

**Step 1: Read `AppModelContainer.swift` first**

```bash
cat SundeeFundee/App/AppModelContainer.swift
```

**Step 2: Create `AppSchemaV2.swift`**

```swift
import SwiftData

/// Schema V2 — replaces the freeform `Benchmark` model with the catalog-driven
/// `BenchmarkDefinition` and `BenchmarkResult` models.
///
/// Version history:
///   V1 — initial schema (Benchmark model, freeform benchmarks)
///   V2 — adds BenchmarkDefinition + BenchmarkResult, removes Benchmark
enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            User.self,
            ActiveCycle.self,
            CompletedWorkout.self,
            CompletedSet.self,
            OneRepMax.self,
            PersonalRecord.self,
            LiftMax.self,
            PeriodLog.self,
            SymptomLog.self,
            CycleSettings.self,
            CycleAdaptationPreferences.self,
            InjuryProfile.self,
            EnrolledProgram.self,
            EnrollmentEvent.self,
            BenchmarkDefinition.self,
            BenchmarkResult.self,
        ]
    }
}
```

**Step 3: Update `AppSchemaMigrationPlan.swift`**

Replace the entire file:

```swift
import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// V1 → V2: Remove Benchmark, add BenchmarkDefinition and BenchmarkResult.
    /// No data is migrated — freeform benchmark history is discarded.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self
    )
}
```

**Step 4: Update `AppModelContainer.swift`**

Find where `AppSchemaV1` is referenced in `AppModelContainer.swift` and update it to use `AppSchemaV2` and `AppSchemaMigrationPlan`. The exact change depends on what you read in Step 1 — look for a line like:
```swift
let schema = Schema(AppSchemaV1.models)
```
and update to:
```swift
let schema = Schema(AppSchemaV2.models)
```
Also ensure `ModelContainer` is initialized with `migrationPlan: AppSchemaMigrationPlan.self` if it isn't already.

**Step 5: Build to verify no compile errors**

```bash
xcodebuild build -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 6: Commit**

```bash
git add SundeeFundee/App/AppSchemaV2.swift \
        SundeeFundee/App/AppSchemaMigrationPlan.swift \
        SundeeFundee/App/AppModelContainer.swift
git commit -m "feat: advance schema to V2 — BenchmarkDefinition + BenchmarkResult replace Benchmark"
```

---

## Task 5: `BenchmarksViewModel` — rewrite

**Files:**
- Modify: `SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift`

**Step 1: Write the failing test**

Add `SundeeFundeTests/BenchmarksViewModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Suite("BenchmarksViewModel")
@MainActor
struct BenchmarksViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    @Test
    func loadsGroupsFromCatalog() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        #expect(!vm.categoryGroups.isEmpty)
        let names = vm.categoryGroups.map(\.category)
        #expect(names.contains("CrossFit WOD"))
        #expect(names.contains("Strength"))
    }

    @Test
    func addCustomDefinitionAppearsInGroups() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        vm.addCustomDefinition(name: "My Workout", category: "General Fitness",
                               description: "Run 1 mile", scoringType: .time)
        #expect(vm.categoryGroups.contains { $0.category == "General Fitness" })
        let generalGroup = vm.categoryGroups.first { $0.category == "General Fitness" }
        #expect(generalGroup?.definitions.contains { $0.name == "My Workout" } == true)
    }

    @Test
    func deleteCustomDefinitionRemovesIt() async throws {
        let ctx = try makeContext()
        let vm = BenchmarksViewModel()
        await vm.load(modelContext: ctx, userID: "u1")
        vm.addCustomDefinition(name: "Temp WOD", category: "General Fitness",
                               description: "Burpees", scoringType: .reps)
        let group = vm.categoryGroups.first { $0.category == "General Fitness" }
        let def = group?.definitions.first { $0.name == "Temp WOD" }
        #expect(def != nil)
        vm.deleteCustomDefinition(def!)
        let updated = vm.categoryGroups.first { $0.category == "General Fitness" }
        #expect(updated?.definitions.contains { $0.name == "Temp WOD" } != true)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarksViewModelTests 2>&1 | tail -20
```
Expected: compile error — `categoryGroups`, `addCustomDefinition`, `deleteCustomDefinition` not found.

**Step 3: Rewrite `BenchmarksViewModel.swift`**

```swift
import Foundation
import SwiftData

/// View model for the Benchmarks screen.
///
/// Merges predefined catalog entries with user-created definitions stored in SwiftData,
/// groups them by category, and provides actions for logging results and managing custom definitions.
@MainActor
@Observable
final class BenchmarksViewModel {

    struct CategoryGroup: Identifiable {
        var id: String { category }
        let category: String
        var definitions: [BenchmarkDefinition]
    }

    var categoryGroups: [CategoryGroup] = []
    var isLoading = false

    private var modelContext: ModelContext?
    private var userID: String = ""
    private let definitionRepoFactory: (ModelContext) -> any BenchmarkDefinitionRepository

    init(
        definitionRepoFactory: @escaping (ModelContext) -> any BenchmarkDefinitionRepository = {
            SwiftDataBenchmarkDefinitionRepository(context: $0)
        }
    ) {
        self.definitionRepoFactory = definitionRepoFactory
    }

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }

        let repo = definitionRepoFactory(modelContext)
        let userCreated = (try? repo.fetchUserCreated(userID: userID)) ?? []

        // Merge predefined + user-created, grouped by category
        var grouped: [String: [BenchmarkDefinition]] = [:]
        for def in BenchmarkCatalog.predefined + userCreated {
            grouped[def.category, default: []].append(def)
        }

        categoryGroups = BenchmarkCatalog.categoryOrder.compactMap { cat in
            guard let entries = grouped[cat], !entries.isEmpty else { return nil }
            return CategoryGroup(category: cat, definitions: entries.sorted { $0.sortOrder < $1.sortOrder })
        }
        // Append any user-created categories not in the predefined order
        let known = Set(BenchmarkCatalog.categoryOrder)
        for (cat, entries) in grouped where !known.contains(cat) {
            categoryGroups.append(CategoryGroup(category: cat, definitions: entries))
        }
    }

    func addCustomDefinition(name: String, category: String, description: String, scoringType: BenchmarkScoringType) {
        guard let ctx = modelContext else { return }
        let def = BenchmarkDefinition(
            userID: userID,
            name: name,
            category: category,
            workoutDescription: description,
            scoringType: scoringType,
            isPredefined: false,
            sortOrder: Int.max
        )
        let repo = definitionRepoFactory(ctx)
        try? repo.save(def)

        if let idx = categoryGroups.firstIndex(where: { $0.category == category }) {
            categoryGroups[idx].definitions.append(def)
        } else {
            categoryGroups.append(CategoryGroup(category: category, definitions: [def]))
        }
    }

    func deleteCustomDefinition(_ definition: BenchmarkDefinition) {
        guard !definition.isPredefined, let ctx = modelContext else { return }
        let repo = definitionRepoFactory(ctx)
        try? repo.delete(definition)

        for idx in categoryGroups.indices {
            categoryGroups[idx].definitions.removeAll { $0.id == definition.id }
        }
        categoryGroups.removeAll { $0.definitions.isEmpty }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarksViewModelTests 2>&1 | tail -20
```
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Benchmarks/BenchmarksViewModel.swift \
        SundeeFundeTests/BenchmarksViewModelTests.swift
git commit -m "feat: rewrite BenchmarksViewModel to use catalog + user-created definitions"
```

---

## Task 6: `BenchmarkDetailViewModel`

**Files:**
- Create: `SundeeFundee/Features/Benchmarks/BenchmarkDetailViewModel.swift`

**Step 1: Write the failing test**

Add to `SundeeFundeTests/BenchmarksViewModelTests.swift`:

```swift
@Suite("BenchmarkDetailViewModel")
@MainActor
struct BenchmarkDetailViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV2.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    private func makeFranDefinition() -> BenchmarkDefinition {
        BenchmarkDefinition(
            id: "fran", userID: "", name: "Fran",
            category: "CrossFit WOD",
            workoutDescription: "21-15-9: Thrusters + Pull-ups",
            scoringType: .time, isPredefined: true, sortOrder: 0
        )
    }

    @Test
    func loadsEmptyResults() async throws {
        let ctx = try makeContext()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: ctx, userID: "u1")
        #expect(vm.results.isEmpty)
        #expect(vm.bestResult == nil)
    }

    @Test
    func logResultAppearsInResults() async throws {
        let ctx = try makeContext()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: ctx, userID: "u1")
        vm.logResult(scoreValue: 210.0, notes: "First attempt")
        #expect(vm.results.count == 1)
        #expect(vm.results[0].scoreValue == 210.0)
    }

    @Test
    func bestResultForTimeScoringIsLowest() async throws {
        let ctx = try makeContext()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: ctx, userID: "u1")
        vm.logResult(scoreValue: 240.0, notes: "")
        vm.logResult(scoreValue: 195.0, notes: "PR")
        vm.logResult(scoreValue: 220.0, notes: "")
        #expect(vm.bestResult?.scoreValue == 195.0)
    }

    @Test
    func deleteResultRemovesIt() async throws {
        let ctx = try makeContext()
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        await vm.load(modelContext: ctx, userID: "u1")
        vm.logResult(scoreValue: 210.0, notes: "")
        let result = vm.results[0]
        vm.deleteResult(result)
        #expect(vm.results.isEmpty)
    }

    @Test
    func formattedScoreForTime() {
        let vm = BenchmarkDetailViewModel(definition: makeFranDefinition())
        // 3 minutes 30 seconds = 210 seconds
        #expect(vm.formatted(score: 210, for: .time) == "3:30")
        #expect(vm.formatted(score: 65, for: .time) == "1:05")
    }

    @Test
    func formattedScoreForWeight() {
        let franDef = BenchmarkDefinition(
            id: "squat", userID: "", name: "1RM Back Squat",
            category: "Strength", workoutDescription: "desc",
            scoringType: .weight, isPredefined: true, sortOrder: 0
        )
        let vm = BenchmarkDetailViewModel(definition: franDef)
        #expect(vm.formatted(score: 100, for: .weight) == "100.0 kg")
    }

    @Test
    func formattedScoreForReps() {
        let cindy = BenchmarkDefinition(
            id: "cindy", userID: "", name: "Cindy",
            category: "CrossFit WOD", workoutDescription: "desc",
            scoringType: .reps, isPredefined: true, sortOrder: 0
        )
        let vm = BenchmarkDetailViewModel(definition: cindy)
        #expect(vm.formatted(score: 20, for: .reps) == "20 rds")
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDetailViewModelTests 2>&1 | tail -20
```
Expected: compile error — `BenchmarkDetailViewModel` not found.

**Step 3: Create `BenchmarkDetailViewModel.swift`**

```swift
import Foundation
import SwiftData

/// View model for a single benchmark's detail screen.
///
/// Loads and displays all logged results for one `BenchmarkDefinition`,
/// computes the best result based on scoring type, and formats scores for display.
@MainActor
@Observable
final class BenchmarkDetailViewModel {
    let definition: BenchmarkDefinition
    var results: [BenchmarkResult] = []
    var isLoading = false

    private var modelContext: ModelContext?
    private var userID: String = ""
    private let resultRepoFactory: (ModelContext) -> any BenchmarkResultRepository

    init(
        definition: BenchmarkDefinition,
        resultRepoFactory: @escaping (ModelContext) -> any BenchmarkResultRepository = {
            SwiftDataBenchmarkResultRepository(context: $0)
        }
    ) {
        self.definition = definition
        self.resultRepoFactory = resultRepoFactory
    }

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }
        let repo = resultRepoFactory(modelContext)
        results = (try? repo.fetchResults(forDefinitionID: definition.id)) ?? []
    }

    /// The best result based on the definition's scoring type.
    var bestResult: BenchmarkResult? {
        switch definition.resolvedScoringType {
        case .time, .distance:
            return results.min(by: { $0.scoreValue < $1.scoreValue })
        case .weight, .reps:
            return results.max(by: { $0.scoreValue < $1.scoreValue })
        }
    }

    func logResult(scoreValue: Double, notes: String, performedAt: Date = .now) {
        guard let ctx = modelContext else { return }
        let result = BenchmarkResult(
            userID: userID,
            definitionID: definition.id,
            scoreValue: scoreValue,
            notes: notes,
            performedAt: performedAt
        )
        let repo = resultRepoFactory(ctx)
        try? repo.save(result)
        results.insert(result, at: 0)
    }

    func deleteResult(_ result: BenchmarkResult) {
        guard let ctx = modelContext else { return }
        let repo = resultRepoFactory(ctx)
        try? repo.delete(result)
        results.removeAll { $0.id == result.id }
    }

    /// Human-readable score string for a given value and scoring type.
    func formatted(score: Double, for type: BenchmarkScoringType) -> String {
        switch type {
        case .time, .distance:
            let total = Int(score)
            let minutes = total / 60
            let seconds = total % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .weight:
            return String(format: "%.1f kg", score)
        case .reps:
            return "\(Int(score)) rds"
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/BenchmarkDetailViewModelTests 2>&1 | tail -20
```
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Benchmarks/BenchmarkDetailViewModel.swift \
        SundeeFundeTests/BenchmarksViewModelTests.swift
git commit -m "feat: add BenchmarkDetailViewModel with result logging, best-result logic, and score formatting"
```

---

## Task 7: Rewrite `BenchmarksView` and add `BenchmarkDetailView`

**Files:**
- Modify: `SundeeFundee/Features/Benchmarks/BenchmarksView.swift`
- Create: `SundeeFundee/Features/Benchmarks/BenchmarkDetailView.swift`

**Step 1: Write the failing build check**

After rewriting, the app must build cleanly. No new unit tests needed here (view logic is covered by VM tests). Verify with:

```bash
xcodebuild build -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```

**Step 2: Rewrite `BenchmarksView.swift`**

```swift
import SwiftUI
import SwiftData

/// Main benchmarks screen — shows all definitions grouped by category.
struct BenchmarksView: View {
    @State private var viewModel = BenchmarksViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCustom = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.categoryGroups.isEmpty {
                    ContentUnavailableView(
                        "No Benchmarks",
                        systemImage: "checkmark.seal",
                        description: Text("Loading benchmark catalog…")
                    )
                } else {
                    List {
                        ForEach(viewModel.categoryGroups) { group in
                            Section(header: categoryHeader(group.category)) {
                                ForEach(group.definitions, id: \.id) { def in
                                    NavigationLink(destination: BenchmarkDetailView(definition: def)) {
                                        BenchmarkDefinitionRow(definition: def)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        if !def.isPredefined {
                                            Button(role: .destructive) {
                                                viewModel.deleteCustomDefinition(def)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Benchmarks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddCustom = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add custom benchmark")
            }
        }
        .sheet(isPresented: $showAddCustom) {
            AddCustomBenchmarkSheet(viewModel: viewModel)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }

    private func categoryHeader(_ category: String) -> some View {
        Text(category)
            .font(AppTheme.Fonts.subheading)
            .foregroundStyle(AppTheme.Colors.navy)
            .textCase(nil)
    }
}

// MARK: - BenchmarkDefinitionRow

struct BenchmarkDefinitionRow: View {
    let definition: BenchmarkDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(definition.name)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(scoringLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            Spacer()
            if !definition.isPredefined {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.accentOrange.opacity(0.7))
            }
        }
        .padding(.vertical, 2)
    }

    private var scoringLabel: String {
        switch definition.resolvedScoringType {
        case .time:     return "For time"
        case .reps:     return "Max reps / rounds"
        case .weight:   return "Max weight"
        case .distance: return "For time"
        }
    }
}

// MARK: - AddCustomBenchmarkSheet

struct AddCustomBenchmarkSheet: View {
    @Bindable var viewModel: BenchmarksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = BenchmarkCatalog.generalFitness
    @State private var description = ""
    @State private var scoringType = BenchmarkScoringType.time

    private let categories = BenchmarkCatalog.categoryOrder

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. 500m Row", text: $name)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Scoring") {
                    Picker("Scoring type", selection: $scoringType) {
                        Text("For time").tag(BenchmarkScoringType.time)
                        Text("Max reps / rounds").tag(BenchmarkScoringType.reps)
                        Text("Max weight").tag(BenchmarkScoringType.weight)
                        Text("Distance (time)").tag(BenchmarkScoringType.distance)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Description (optional)") {
                    TextField("Movements, reps scheme…", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Custom Benchmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCustomDefinition(
                            name: name.trimmingCharacters(in: .whitespaces),
                            category: category,
                            description: description,
                            scoringType: scoringType
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
```

**Step 3: Create `BenchmarkDetailView.swift`**

```swift
import SwiftUI
import SwiftData
import Charts

/// Detail screen for a single benchmark definition — shows history and allows logging new results.
struct BenchmarkDetailView: View {
    let definition: BenchmarkDefinition
    @State private var viewModel: BenchmarkDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showLogResult = false

    init(definition: BenchmarkDefinition) {
        self.definition = definition
        _viewModel = State(initialValue: BenchmarkDetailViewModel(definition: definition))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                // Description section
                Section {
                    Text(definition.workoutDescription)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy)
                        .padding(.vertical, 4)
                }

                // Best result
                if let best = viewModel.bestResult {
                    Section("Personal Best") {
                        HStack {
                            Text(viewModel.formatted(score: best.scoreValue, for: definition.resolvedScoringType))
                                .font(AppTheme.Fonts.heading)
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                            Spacer()
                            Text(best.performedAt, style: .date)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                    }
                }

                // Chart
                if viewModel.results.count > 1 {
                    Section("Progress") {
                        BenchmarkProgressChart(
                            results: viewModel.results,
                            scoringType: definition.resolvedScoringType,
                            viewModel: viewModel
                        )
                        .frame(height: 160)
                        .padding(.vertical, 4)
                    }
                }

                // History
                if !viewModel.results.isEmpty {
                    Section("History") {
                        ForEach(viewModel.results) { result in
                            BenchmarkResultRow(result: result, viewModel: viewModel, definition: definition)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteResult(result)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(definition.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showLogResult = true } label: {
                    Label("Log Result", systemImage: "plus")
                }
                .accessibilityLabel("Log result")
            }
        }
        .sheet(isPresented: $showLogResult) {
            LogBenchmarkResultSheet(viewModel: viewModel, definition: definition)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - BenchmarkResultRow

struct BenchmarkResultRow: View {
    let result: BenchmarkResult
    let viewModel: BenchmarkDetailViewModel
    let definition: BenchmarkDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.formatted(score: result.scoreValue, for: definition.resolvedScoringType))
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                if !result.notes.isEmpty {
                    Text(result.notes)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(result.performedAt, style: .date)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - BenchmarkProgressChart

struct BenchmarkProgressChart: View {
    let results: [BenchmarkResult]
    let scoringType: BenchmarkScoringType
    let viewModel: BenchmarkDetailViewModel

    var body: some View {
        let sorted = results.sorted { $0.performedAt < $1.performedAt }
        Chart {
            ForEach(sorted) { result in
                LineMark(
                    x: .value("Date", result.performedAt),
                    y: .value("Score", result.scoreValue)
                )
                .foregroundStyle(AppTheme.Colors.accentOrange)
                PointMark(
                    x: .value("Date", result.performedAt),
                    y: .value("Score", result.scoreValue)
                )
                .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(viewModel.formatted(score: v, for: scoringType))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - LogBenchmarkResultSheet

struct LogBenchmarkResultSheet: View {
    let viewModel: BenchmarkDetailViewModel
    let definition: BenchmarkDefinition
    @Environment(\.dismiss) private var dismiss

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var weightKg: String = ""
    @State private var repCount: Int = 1
    @State private var performedAt: Date = .now
    @State private var notes: String = ""

    private var scoringType: BenchmarkScoringType { definition.resolvedScoringType }

    private var canSave: Bool {
        switch scoringType {
        case .time, .distance: return minutes > 0 || seconds > 0
        case .weight:          return Double(weightKg) != nil
        case .reps:            return repCount > 0
        }
    }

    private var scoreValue: Double {
        switch scoringType {
        case .time, .distance: return Double(minutes * 60 + seconds)
        case .weight:          return Double(weightKg) ?? 0
        case .reps:            return Double(repCount)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Result") {
                    switch scoringType {
                    case .time, .distance:
                        HStack {
                            Stepper("Min: \(minutes)", value: $minutes, in: 0...999)
                            Stepper("Sec: \(seconds)", value: $seconds, in: 0...59)
                        }
                    case .weight:
                        TextField("Weight (kg)", text: $weightKg)
                            .keyboardType(.decimalPad)
                    case .reps:
                        Stepper("Reps / Rounds: \(repCount)", value: $repCount, in: 1...9999)
                    }
                }
                Section("Date") {
                    DatePicker("Date", selection: $performedAt, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Log Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logResult(scoreValue: scoreValue, notes: notes, performedAt: performedAt)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
```

**Step 4: Build to verify no compile errors**

```bash
xcodebuild build -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Benchmarks/BenchmarksView.swift \
        SundeeFundee/Features/Benchmarks/BenchmarkDetailView.swift
git commit -m "feat: rewrite BenchmarksView and add BenchmarkDetailView with chart, history, and LogBenchmarkResultSheet"
```

---

## Task 8: Fix any broken existing tests and run full suite

**Step 1: Run the full test suite**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40
```

**Step 2: Fix compile errors caused by old `Benchmark` references**

Search for any remaining references to the old `Benchmark` model or `BenchmarkRepository`:

```bash
grep -rn "Benchmark[^Definition|Result|Catalog|Scoring|sView|Detail]" SundeeFundee/ SundeeFundeTests/ --include="*.swift" | grep -v "BenchmarkDefinition\|BenchmarkResult\|BenchmarkCatalog\|BenchmarkScoring\|BenchmarksView\|BenchmarkDetail"
```

Update any found references:
- `Benchmark` → `BenchmarkResult`
- `BenchmarkRepository` → `BenchmarkResultRepository` or `BenchmarkDefinitionRepository`
- `AppSchemaV1.models` in test `makeContainer()` calls → `AppSchemaV2.models`

**Step 3: Run full suite again to confirm all pass**

```bash
xcodebuild test -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "Test Suite|passed|failed" | tail -20
```
Expected: All tests pass.

**Step 4: Commit**

```bash
git add -A
git commit -m "fix: update test fixtures and stale Benchmark references to use AppSchemaV2"
```

---

## Task 9: Update `DebugSeedData` (if it references old Benchmark)

**Step 1: Read `DebugSeedData.swift`**

```bash
cat SundeeFundee/App/DebugSeedData.swift
```

**Step 2: Update any `Benchmark(...)` initializers to use `BenchmarkResult(...)`**

If the file seeds benchmark data, update to create `BenchmarkResult` objects tied to a predefined definition ID (e.g., `"predefined-fran"`).

**Step 3: Build and run tests**

```bash
xcodebuild build -scheme SundeeFunde -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```

**Step 4: Commit if changes were needed**

```bash
git add SundeeFundee/App/DebugSeedData.swift
git commit -m "fix: update DebugSeedData to seed BenchmarkResult instead of Benchmark"
```

---

## Done

After all tasks, the app has:
- A 24-entry predefined benchmark catalog grouped by category
- User-created custom benchmarks stored in SwiftData
- Adaptive score logging UI (time picker, weight field, rep stepper)
- Per-benchmark history with personal best and a progress chart
- Clean schema V2 migration from V1
