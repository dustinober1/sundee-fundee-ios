# Plate Calculator Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add plate calculator to Actual Weight fields, per-exercise barbell type memory with smart defaults, and an Equipment settings section for managing barbell presets.

**Architecture:** Two new SwiftData models (`BarbellPreset`, `ExerciseBarMapping`) with a `BarbellRepository` protocol. New `BarbellDefaults` domain logic for smart exercise→bar mapping. UI changes in `SetRow` (trailing icon), `PlateCalculatorSheet` (bar picker), and `SettingsView` (Equipment section). Schema migration V10→V11.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing framework

---

### Task 1: BarbellPreset and ExerciseBarMapping SwiftData Models

**Files:**
- Create: `SundeeFundee/Models/BarbellPreset.swift`
- Create: `SundeeFundee/Models/ExerciseBarMapping.swift`

**Step 1: Create BarbellPreset model**

Create `SundeeFundee/Models/BarbellPreset.swift`:

```swift
import SwiftData
import Foundation

@Model
final class BarbellPreset {
    var id: String
    var userID: String
    var name: String
    var weightKg: Double
    var isBuiltIn: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        weightKg: Double,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.weightKg = weightKg
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}
```

**Step 2: Create ExerciseBarMapping model**

Create `SundeeFundee/Models/ExerciseBarMapping.swift`:

```swift
import SwiftData
import Foundation

@Model
final class ExerciseBarMapping {
    var id: String
    var userID: String
    var exerciseName: String
    var barbellPresetID: String

    init(
        id: String = UUID().uuidString,
        userID: String,
        exerciseName: String,
        barbellPresetID: String
    ) {
        self.id = id
        self.userID = userID
        self.exerciseName = exerciseName
        self.barbellPresetID = barbellPresetID
    }
}
```

**Step 3: Build to verify models compile**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 4: Commit**

```bash
git add SundeeFundee/Models/BarbellPreset.swift SundeeFundee/Models/ExerciseBarMapping.swift
git commit -m "feat: add BarbellPreset and ExerciseBarMapping SwiftData models"
```

---

### Task 2: Schema Migration V10 → V11

**Files:**
- Create: `SundeeFundee/App/AppSchemaV11.swift`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Modify: `SundeeFundee/App/AppModelContainer.swift`

**Step 1: Create AppSchemaV11**

Create `SundeeFundee/App/AppSchemaV11.swift`:

```swift
import SwiftData

/// Schema V11 — adds BarbellPreset and ExerciseBarMapping for per-exercise barbell configuration.
enum AppSchemaV11: VersionedSchema {
    static let versionIdentifier = Schema.Version(11, 0, 0)

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
            PainLog.self,
            ConditioningPR.self,
            GeneratedWorkoutRecord.self,
            SharedWorkoutTemplateRecord.self,
            BarbellPreset.self,
            ExerciseBarMapping.self,
        ]
    }
}
```

**Step 2: Update AppSchemaMigrationPlan**

In `SundeeFundee/App/AppSchemaMigrationPlan.swift`:

Add `AppSchemaV11.self` to the `schemas` array:
```swift
static var schemas: [any VersionedSchema.Type] {
    [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self, AppSchemaV9.self, AppSchemaV10.self, AppSchemaV11.self]
}
```

Add `migrateV10toV11` to the `stages` array:
```swift
static var stages: [MigrationStage] {
    [migrateV1toV6, migrateV6toV7, migrateV7toV8, migrateV8toV9, migrateV9toV10, migrateV10toV11]
}
```

Add the migration stage:
```swift
/// V10 → V11: Adds BarbellPreset and ExerciseBarMapping models for per-exercise barbell configuration.
static let migrateV10toV11 = MigrationStage.lightweight(
    fromVersion: AppSchemaV10.self,
    toVersion: AppSchemaV11.self
)
```

**Step 3: Update AppModelContainer**

In `SundeeFundee/App/AppModelContainer.swift`, change line 119:
```swift
private static let allModels: [any PersistentModel.Type] = AppSchemaV11.models
```

Also update `makeContainer(for:)` for the `.localPersistent` case to include the migration plan (line 94-96):
```swift
case .localPersistent:
    let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
```

**Step 4: Build to verify migration compiles**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 5: Commit**

```bash
git add SundeeFundee/App/AppSchemaV11.swift SundeeFundee/App/AppSchemaMigrationPlan.swift SundeeFundee/App/AppModelContainer.swift
git commit -m "feat: add schema V11 migration for BarbellPreset and ExerciseBarMapping"
```

---

### Task 3: BarbellDefaults Domain Logic

**Files:**
- Create: `SundeeFundee/Domain/Calculations/BarbellDefaults.swift`
- Test: `SundeeFundeTests/BarbellDefaultsTests.swift`

**Step 1: Write failing tests**

Create `SundeeFundeTests/BarbellDefaultsTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("BarbellDefaults")
struct BarbellDefaultsTests {

    // MARK: - Built-in presets

    @Test func builtInPresetsHasFourEntries() {
        let presets = BarbellDefaults.builtInPresets
        #expect(presets.count == 4)
    }

    @Test func standardPresetIs45Lb() {
        let standard = BarbellDefaults.builtInPresets.first { $0.name == "Standard" }
        #expect(standard != nil)
        let expectedKg = 45.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(standard!.weightKg - expectedKg) < 0.01)
    }

    @Test func womensPresetIs35Lb() {
        let womens = BarbellDefaults.builtInPresets.first { $0.name == "Women's" }
        #expect(womens != nil)
        let expectedKg = 35.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(womens!.weightKg - expectedKg) < 0.01)
    }

    @Test func trainingPresetIs33Lb() {
        let training = BarbellDefaults.builtInPresets.first { $0.name == "Training" }
        #expect(training != nil)
        let expectedKg = 33.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(training!.weightKg - expectedKg) < 0.01)
    }

    @Test func ezCurlPresetIs15Lb() {
        let ez = BarbellDefaults.builtInPresets.first { $0.name == "EZ Curl" }
        #expect(ez != nil)
        let expectedKg = 15.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(ez!.weightKg - expectedKg) < 0.01)
    }

    // MARK: - Suggested preset name

    @Test func curlExerciseSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Curl", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "EZ Bar Curl", gender: .female) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Preacher Curl", gender: .male) == "EZ Curl")
    }

    @Test func tricepExtensionSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Tricep Extension", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Overhead Tricep Extension", gender: .female) == "EZ Curl")
    }

    @Test func skullCrusherSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Skull Crusher", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Lying Skull Crushers", gender: .female) == "EZ Curl")
    }

    @Test func compoundLiftFemaleDefaultsToWomens() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Bench Press", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Deadlift", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Overhead Press", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Row", gender: .female) == "Women's")
    }

    @Test func compoundLiftMaleDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Bench Press", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Deadlift", gender: .male) == "Standard")
    }

    @Test func unknownExerciseDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Some Weird Exercise", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Cable Fly", gender: .female) == "Standard")
    }

    @Test func preferNotToSayDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .preferNotToSay) == "Standard")
    }

    @Test func caseInsensitiveMatching() {
        #expect(BarbellDefaults.suggestedPresetName(for: "barbell curl", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "BENCH PRESS", gender: .female) == "Women's")
    }

    // MARK: - EZ Curl takes priority over compound

    @Test func ezCurlPriorityOverCompound() {
        // "Curl" keyword should match EZ Curl even if "barbell" is in the name
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Curl", gender: .female) == "EZ Curl")
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BarbellDefaultsTests`
Expected: Compilation error — `BarbellDefaults` not found.

**Step 3: Implement BarbellDefaults**

Create `SundeeFundee/Domain/Calculations/BarbellDefaults.swift`:

```swift
import Foundation

enum BarbellDefaults {

    struct PresetDefinition {
        let name: String
        let weightKg: Double
        let sortOrder: Int
    }

    static let builtInPresets: [PresetDefinition] = [
        PresetDefinition(name: "Standard", weightKg: 45.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 0),
        PresetDefinition(name: "Women's", weightKg: 35.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 1),
        PresetDefinition(name: "Training", weightKg: 33.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 2),
        PresetDefinition(name: "EZ Curl", weightKg: 15.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 3),
    ]

    private static let ezCurlKeywords = ["curl", "tricep extension", "skull crush"]

    private static let compoundKeywords = ["squat", "bench press", "deadlift", "overhead press", "ohp", "barbell row", "bent over row", "front squat", "incline press"]

    static func suggestedPresetName(for exerciseName: String, gender: Gender?) -> String {
        let lower = exerciseName.lowercased()

        // EZ Curl bar exercises take priority
        if ezCurlKeywords.contains(where: { lower.contains($0) }) {
            return "EZ Curl"
        }

        // Compound lifts — women's bar for female
        if compoundKeywords.contains(where: { lower.contains($0) }) {
            return gender == .female ? "Women's" : "Standard"
        }

        // Default to standard
        return "Standard"
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BarbellDefaultsTests`
Expected: All PASS.

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/Calculations/BarbellDefaults.swift SundeeFundeTests/BarbellDefaultsTests.swift
git commit -m "feat: add BarbellDefaults domain logic with smart exercise-to-bar mapping"
```

---

### Task 4: BarbellRepository Protocol and SwiftData Implementation

**Files:**
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
- Create: `SundeeFundee/Repositories/SwiftData/SwiftDataBarbellRepository.swift`
- Test: `SundeeFundeTests/BarbellRepositoryCoverageTests.swift`

**Step 1: Write failing tests**

Create `SundeeFundeTests/BarbellRepositoryCoverageTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("BarbellRepository")
struct BarbellRepositoryTests {

    @Test func fetchPresetsReturnsEmpty() {
        let repo = MockBarbellRepository()
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.isEmpty)
    }

    @Test func saveAndFetchPreset() {
        let repo = MockBarbellRepository()
        let preset = BarbellPresetDTO(id: "p1", userID: "u1", name: "Standard", weightKg: 20.4, isBuiltIn: true, sortOrder: 0)
        try? repo.savePreset(preset)
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 1)
        #expect(presets.first?.name == "Standard")
    }

    @Test func deletePreset() {
        let repo = MockBarbellRepository()
        let preset = BarbellPresetDTO(id: "p1", userID: "u1", name: "Custom", weightKg: 10.0, isBuiltIn: false, sortOrder: 5)
        try? repo.savePreset(preset)
        try? repo.deletePreset(id: "p1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.isEmpty)
    }

    @Test func fetchMappingReturnsNilWhenEmpty() {
        let repo = MockBarbellRepository()
        let mapping = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(mapping == nil)
    }

    @Test func saveAndFetchMapping() {
        let repo = MockBarbellRepository()
        let mapping = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p1")
        try? repo.saveMapping(mapping)
        let fetched = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(fetched?.barbellPresetID == "p1")
    }

    @Test func saveMappingUpdatesExisting() {
        let repo = MockBarbellRepository()
        let m1 = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p1")
        try? repo.saveMapping(m1)
        let m2 = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p2")
        try? repo.saveMapping(m2)
        let fetched = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(fetched?.barbellPresetID == "p2")
    }

    @Test func seedBuiltInPresetsCreatesDefaults() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 4)
        #expect(presets.contains { $0.name == "Standard" })
        #expect(presets.contains { $0.name == "Women's" })
        #expect(presets.contains { $0.name == "Training" })
        #expect(presets.contains { $0.name == "EZ Curl" })
    }

    @Test func seedBuiltInPresetsIsIdempotent() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 4)
    }
}
```

**Step 2: Add BarbellRepository protocol to RepositoryProtocols.swift**

Add at the end of `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift` (before closing):

```swift
// MARK: - BarbellRepository

struct BarbellPresetDTO {
    let id: String
    let userID: String
    let name: String
    let weightKg: Double
    let isBuiltIn: Bool
    let sortOrder: Int
}

struct ExerciseBarMappingDTO {
    let id: String
    let userID: String
    let exerciseName: String
    let barbellPresetID: String
}

protocol BarbellRepository {
    func fetchPresets(userID: String) throws -> [BarbellPresetDTO]
    func savePreset(_ preset: BarbellPresetDTO) throws
    func deletePreset(id: String) throws
    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO?
    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws
    func seedBuiltInPresets(userID: String)
}
```

**Step 3: Create MockBarbellRepository for tests**

Add at the bottom of `SundeeFundeTests/BarbellRepositoryCoverageTests.swift` (below the test suite):

```swift
// MARK: - Mock

final class MockBarbellRepository: BarbellRepository {
    private var presets: [BarbellPresetDTO] = []
    private var mappings: [ExerciseBarMappingDTO] = []

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        presets.filter { $0.userID == userID }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func savePreset(_ preset: BarbellPresetDTO) throws {
        presets.removeAll { $0.id == preset.id }
        presets.append(preset)
    }

    func deletePreset(id: String) throws {
        presets.removeAll { $0.id == id }
    }

    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO? {
        mappings.first { $0.exerciseName == exerciseName && $0.userID == userID }
    }

    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws {
        mappings.removeAll { $0.exerciseName == mapping.exerciseName && $0.userID == mapping.userID }
        mappings.append(mapping)
    }

    func seedBuiltInPresets(userID: String) {
        let existing = (try? fetchPresets(userID: userID)) ?? []
        guard existing.isEmpty else { return }
        for def in BarbellDefaults.builtInPresets {
            try? savePreset(BarbellPresetDTO(
                id: UUID().uuidString,
                userID: userID,
                name: def.name,
                weightKg: def.weightKg,
                isBuiltIn: true,
                sortOrder: def.sortOrder
            ))
        }
    }
}
```

**Step 4: Create SwiftDataBarbellRepository**

Create `SundeeFundee/Repositories/SwiftData/SwiftDataBarbellRepository.swift`:

```swift
import SwiftData
import Foundation

final class SwiftDataBarbellRepository: BarbellRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor).map {
            BarbellPresetDTO(id: $0.id, userID: $0.userID, name: $0.name, weightKg: $0.weightKg, isBuiltIn: $0.isBuiltIn, sortOrder: $0.sortOrder)
        }
    }

    func savePreset(_ preset: BarbellPresetDTO) throws {
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.id == preset.id }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.name = preset.name
            existing.weightKg = preset.weightKg
            existing.isBuiltIn = preset.isBuiltIn
            existing.sortOrder = preset.sortOrder
        } else {
            context.insert(BarbellPreset(
                id: preset.id,
                userID: preset.userID,
                name: preset.name,
                weightKg: preset.weightKg,
                isBuiltIn: preset.isBuiltIn,
                sortOrder: preset.sortOrder
            ))
        }
        try context.save()
    }

    func deletePreset(id: String) throws {
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.id == id }
        )
        if let preset = try context.fetch(descriptor).first {
            context.delete(preset)
            try context.save()
        }
    }

    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO? {
        let descriptor = FetchDescriptor<ExerciseBarMapping>(
            predicate: #Predicate { $0.exerciseName == exerciseName && $0.userID == userID }
        )
        return try context.fetch(descriptor).first.map {
            ExerciseBarMappingDTO(id: $0.id, userID: $0.userID, exerciseName: $0.exerciseName, barbellPresetID: $0.barbellPresetID)
        }
    }

    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws {
        let exerciseName = mapping.exerciseName
        let userID = mapping.userID
        let descriptor = FetchDescriptor<ExerciseBarMapping>(
            predicate: #Predicate { $0.exerciseName == exerciseName && $0.userID == userID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.barbellPresetID = mapping.barbellPresetID
        } else {
            context.insert(ExerciseBarMapping(
                id: mapping.id,
                userID: mapping.userID,
                exerciseName: mapping.exerciseName,
                barbellPresetID: mapping.barbellPresetID
            ))
        }
        try context.save()
    }

    func seedBuiltInPresets(userID: String) {
        let existing = (try? fetchPresets(userID: userID)) ?? []
        guard existing.isEmpty else { return }
        for def in BarbellDefaults.builtInPresets {
            try? savePreset(BarbellPresetDTO(
                id: UUID().uuidString,
                userID: userID,
                name: def.name,
                weightKg: def.weightKg,
                isBuiltIn: true,
                sortOrder: def.sortOrder
            ))
        }
    }
}
```

**Step 5: Run tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/BarbellRepositoryTests`
Expected: All PASS.

**Step 6: Commit**

```bash
git add SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift SundeeFundee/Repositories/SwiftData/SwiftDataBarbellRepository.swift SundeeFundeTests/BarbellRepositoryCoverageTests.swift
git commit -m "feat: add BarbellRepository protocol with SwiftData implementation and tests"
```

---

### Task 5: Update WorkoutExecutionViewModel for Per-Exercise Plate Calculator

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift`
- Test: Add tests in `SundeeFundeTests/ViewModelCoverageTests.swift` or create new file

**Step 1: Write failing tests**

Add to test file (create `SundeeFundeTests/BarbellViewModelCoverageTests.swift`):

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("WorkoutExecutionViewModel.PlateCalcForActual")
@MainActor
struct WorkoutExecVMPlateCalcTests {

    @Test func openPlateCalcForActualSetsProperties() {
        let vm = makeVM()
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 100.0)
        #expect(vm.showPlateCalc == true)
        #expect(vm.plateCalcWeightKg == 100.0)
        #expect(vm.plateCalcExerciseName == "Squat")
    }

    @Test func openPlateCalcForActualLooksUpMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        try? repo.saveMapping(ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Curl", barbellPresetID: ezID))

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Curl", weightKg: 30.0)
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func openPlateCalcForActualCreatesDefaultMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")

        let vm = makeVM(barbellRepo: repo, userID: "u1", gender: .male)
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Barbell Curl", weightKg: 30.0)

        // Should auto-create mapping for EZ Curl
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func updateBarSelectionSavesMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let standardID = presets.first { $0.name == "Standard" }!.id
        let womensID = presets.first { $0.name == "Women's" }!.id

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.plateCalcExerciseName = "Squat"
        vm.updateBarSelection(presetID: womensID)

        let mapping = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(mapping?.barbellPresetID == womensID)
    }

    @Test func selectedBarbellWeightKgReturnsCorrectWeight() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.selectedPresetID = ezID

        let expectedKg = 15.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(vm.selectedBarbellWeightKg - expectedKg) < 0.01)
    }

    @Test func selectedBarbellWeightKgFallsBackToStandard() {
        let vm = makeVM()
        #expect(abs(vm.selectedBarbellWeightKg - PlateCalculation.standardBarKg) < 0.01)
    }

    // MARK: - Helpers

    private func makeVM(
        barbellRepo: BarbellRepository? = nil,
        userID: String = "u1",
        gender: Gender? = .male
    ) -> WorkoutExecutionViewModel {
        let exercises = [
            ProgramExercise(exercise: "Squat", variant: nil, sets: .fixed(3), reps: .fixed(5), percent1RM: nil, restMinutes: 2, notes: nil, bodyweightOnly: false),
            ProgramExercise(exercise: "Curl", variant: nil, sets: .fixed(3), reps: .fixed(10), percent1RM: nil, restMinutes: 1, notes: nil, bodyweightOnly: false),
        ]
        let session = ProgramSession(sessionID: "s1", sessionName: "Test", sessionType: "strength", focus: "Full Body", exercises: exercises)
        let enrollment = EnrolledProgram(id: "e1", userID: userID, programID: "p1")
        let program = Program(id: "p1", name: "Test", description: "", difficulty: "Intermediate", durationWeeks: 4, sessionsPerWeek: 3, weeks: [])
        return WorkoutExecutionViewModel(
            session: session,
            enrollment: enrollment,
            program: program,
            barbellRepo: barbellRepo,
            userID: userID,
            gender: gender
        )
    }
}
```

**Step 2: Update WorkoutExecutionViewModel**

In `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift`, add the following properties and methods:

Add new properties after `var errorMessage: String?` (line 36):

```swift
var plateCalcExerciseName: String = ""
var barbellPresets: [BarbellPresetDTO] = []
var selectedPresetID: String?

private var barbellRepo: BarbellRepository?
private var userID: String = ""
private var gender: Gender?
```

Update the program init (line 41-57) to accept new params:

```swift
init(
    session: ProgramSession,
    enrollment: EnrolledProgram,
    program: Program,
    oneRepMaxes: [String: Double] = [:],
    barbellWeightKg: Double = PlateCalculation.standardBarKg,
    weightUnit: WeightUnit = .pounds,
    barbellRepo: BarbellRepository? = nil,
    userID: String = "",
    gender: Gender? = nil
) {
    self.session = session
    self.enrollment = enrollment
    self.program = program
    self.generatedWorkout = nil
    self.oneRepMaxes = oneRepMaxes
    self.barbellWeightKg = barbellWeightKg
    self.weightUnit = weightUnit
    self.barbellRepo = barbellRepo
    self.userID = userID
    self.gender = gender
    initializeSets()
}
```

Update the AI init (line 59-71) similarly:

```swift
init(
    generatedWorkout: GeneratedWorkout,
    barbellWeightKg: Double = PlateCalculation.standardBarKg,
    weightUnit: WeightUnit = .pounds,
    barbellRepo: BarbellRepository? = nil,
    userID: String = "",
    gender: Gender? = nil
) {
    self.generatedWorkout = generatedWorkout
    self.session = Self.mapToSession(generatedWorkout)
    self.enrollment = nil
    self.program = nil
    self.barbellWeightKg = barbellWeightKg
    self.weightUnit = weightUnit
    self.barbellRepo = barbellRepo
    self.userID = userID
    self.gender = gender
    initializeAISets(from: generatedWorkout)
}
```

Add new methods after the existing `openPlateCalc(forWeight:)` method (after line 175):

```swift
func loadBarbellPresets() {
    guard let repo = barbellRepo else { return }
    barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
}

func openPlateCalcForActual(exerciseName: String, weightKg: Double) {
    plateCalcExerciseName = exerciseName
    plateCalcWeightKg = weightKg

    if let repo = barbellRepo {
        // Look up existing mapping
        if let mapping = try? repo.fetchMapping(exerciseName: exerciseName, userID: userID) {
            selectedPresetID = mapping.barbellPresetID
        } else {
            // Create default mapping using smart defaults
            let suggestedName = BarbellDefaults.suggestedPresetName(for: exerciseName, gender: gender)
            if let preset = barbellPresets.first(where: { $0.name == suggestedName }) {
                selectedPresetID = preset.id
                let mapping = ExerciseBarMappingDTO(
                    id: UUID().uuidString,
                    userID: userID,
                    exerciseName: exerciseName,
                    barbellPresetID: preset.id
                )
                try? repo.saveMapping(mapping)
            } else {
                selectedPresetID = barbellPresets.first?.id
            }
        }
    }

    showPlateCalc = true
}

func updateBarSelection(presetID: String) {
    selectedPresetID = presetID
    guard let repo = barbellRepo, !plateCalcExerciseName.isEmpty else { return }
    let mapping = ExerciseBarMappingDTO(
        id: UUID().uuidString,
        userID: userID,
        exerciseName: plateCalcExerciseName,
        barbellPresetID: presetID
    )
    try? repo.saveMapping(mapping)
}

var selectedBarbellWeightKg: Double {
    if let id = selectedPresetID, let preset = barbellPresets.first(where: { $0.id == id }) {
        return preset.weightKg
    }
    return barbellWeightKg
}
```

**Step 3: Run tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/WorkoutExecVMPlateCalcTests`
Expected: All PASS.

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift SundeeFundeTests/BarbellViewModelCoverageTests.swift
git commit -m "feat: add per-exercise barbell selection to WorkoutExecutionViewModel"
```

---

### Task 6: Update PlateCalculatorSheet with Bar Type Picker

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift` (PlateCalculatorSheet section)

**Step 1: Update PlateCalculatorSheet to accept presets and selection callback**

Replace the `PlateCalculatorSheet` struct (lines 505-613) with:

```swift
struct PlateCalculatorSheet: View {
    let weightKg: Double
    let barbellWeightKg: Double
    let weightUnit: WeightUnit
    var presets: [BarbellPresetDTO]
    var selectedPresetID: String?
    var onBarChange: ((String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    init(
        weightKg: Double,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds,
        presets: [BarbellPresetDTO] = [],
        selectedPresetID: String? = nil,
        onBarChange: ((String) -> Void)? = nil
    ) {
        self.weightKg = weightKg
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        self.presets = presets
        self.selectedPresetID = selectedPresetID
        self.onBarChange = onBarChange
    }

    private var effectiveBarbellKg: Double {
        if let id = selectedPresetID, let preset = presets.first(where: { $0.id == id }) {
            return preset.weightKg
        }
        return barbellWeightKg
    }

    private var plates: [(weight: Double, count: Int)] {
        PlateCalculation.platesPerSide(totalWeightKg: weightKg, barbellWeightKg: effectiveBarbellKg, weightUnit: weightUnit)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                if !presets.isEmpty, let selectedPresetID {
                    barPicker(selectedID: selectedPresetID)
                }

                Text(Self.description(
                    totalWeightKg: weightKg,
                    barbellWeightKg: effectiveBarbellKg,
                    plates: plates,
                    weightUnit: weightUnit
                ))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                    .multilineTextAlignment(.center)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))

                if Self.hasPlates(plates) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(plates, id: \.weight, content: plateRow(for:))
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                } else {
                    Text(Self.barOnlyText(barKg: effectiveBarbellKg, weightUnit: weightUnit))
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cream.ignoresSafeArea())
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func barPicker(selectedID: String) -> some View {
        Menu {
            ForEach(presets, id: \.id) { preset in
                Button {
                    onBarChange?(preset.id)
                } label: {
                    HStack {
                        Text(Self.presetLabel(preset: preset, weightUnit: weightUnit))
                        if preset.id == selectedID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "barbell")
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                if let selected = presets.first(where: { $0.id == selectedID }) {
                    Text(Self.presetLabel(preset: selected, weightUnit: weightUnit))
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    static func presetLabel(preset: BarbellPresetDTO, weightUnit: WeightUnit) -> String {
        let weight = WeightUnitConversion.format(kilograms: preset.weightKg, unit: weightUnit, maximumFractionDigits: 1)
        return "\(preset.name) (\(weight) \(weightUnit.symbol))"
    }

    private func plateRow(for plate: (weight: Double, count: Int)) -> some View {
        HStack {
            Text("\(plate.count)×")
                .foregroundStyle(AppTheme.Colors.accentOrange)
            Text("\(Self.formatPlateWeight(plate.weight)) \(weightUnit.symbol) plate")
                .foregroundStyle(AppTheme.Colors.navy)
            Spacer()
        }
        .font(AppTheme.Fonts.subheading)
    }

    static func hasPlates(_ plates: [(weight: Double, count: Int)]) -> Bool {
        !plates.isEmpty
    }

    static func formatPlateWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : WeightUnitConversion.formatValue(value, maximumFractionDigits: 2)
    }

    static func formatWeight(_ kg: Double, weightUnit: WeightUnit = .pounds) -> String {
        WeightUnitConversion.format(kilograms: kg, unit: weightUnit, maximumFractionDigits: 1)
    }

    static func barOnlyText(barKg: Double, weightUnit: WeightUnit = .pounds) -> String {
        "Bar only (\(formatWeight(barKg, weightUnit: weightUnit)) \(weightUnit.symbol))"
    }

    static func description(
        totalWeightKg: Double,
        barbellWeightKg: Double,
        plates: [(weight: Double, count: Int)],
        weightUnit: WeightUnit = .pounds
    ) -> String {
        if plates.isEmpty {
            return barOnlyText(barKg: barbellWeightKg, weightUnit: weightUnit)
        }
        let parts = plates.map { plate in
            "\(plate.count)×\(formatPlateWeight(plate.weight))\(weightUnit.symbol)"
        }
        return "\(formatWeight(totalWeightKg, weightUnit: weightUnit)) \(weightUnit.symbol) total • \(parts.joined(separator: " + ")) per side"
    }
}
```

**Step 2: Update the plateCalculatorSheet() function in WorkoutExecutionView**

Replace the `plateCalculatorSheet()` method (lines 59-65) with:

```swift
private func plateCalculatorSheet() -> some View {
    PlateCalculatorSheet(
        weightKg: viewModel.plateCalcWeightKg,
        barbellWeightKg: viewModel.selectedBarbellWeightKg,
        weightUnit: viewModel.weightUnit,
        presets: viewModel.barbellPresets,
        selectedPresetID: viewModel.selectedPresetID,
        onBarChange: { viewModel.updateBarSelection(presetID: $0) }
    )
}
```

**Step 3: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Workouts/WorkoutExecutionView.swift
git commit -m "feat: add bar type picker to PlateCalculatorSheet"
```

---

### Task 7: Add Plate Calculator Icon to SetRow Actual Weight Field

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift` (SetRow and ExerciseSetCard sections)

**Step 1: Update SetRow to accept an onPlateCalc callback**

Add a new parameter to `SetRow`:

```swift
struct SetRow: View {
    let setNumber: Int
    let state: SetExecutionState
    let onRepsChange: (Int) -> Void
    let onWeightChange: (Double) -> Void
    let weightUnit: WeightUnit
    let bodyweightOnly: Bool
    let onToggle: () -> Void
    let onPlateCalc: (() -> Void)?
```

Update the init:

```swift
init(
    setNumber: Int,
    state: SetExecutionState,
    onRepsChange: @escaping (Int) -> Void,
    onWeightChange: @escaping (Double) -> Void,
    weightUnit: WeightUnit = .pounds,
    bodyweightOnly: Bool = false,
    onToggle: @escaping () -> Void,
    onPlateCalc: (() -> Void)? = nil
) {
    self.setNumber = setNumber
    self.state = state
    self.onRepsChange = onRepsChange
    self.onWeightChange = onWeightChange
    self.weightUnit = weightUnit
    self.bodyweightOnly = bodyweightOnly
    self.onToggle = onToggle
    self.onPlateCalc = onPlateCalc
    _repsText = State(initialValue: "")
    _weightText = State(initialValue: "")
}
```

Replace the weight TextField (line 344-353) with an HStack containing the field + icon:

```swift
HStack(spacing: 2) {
    TextField("–", text: $weightText)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .onChange(of: weightText) { oldValue, newValue in
            Self.weightTextChangeHandler(onWeightChange: onWeightChange, weightUnit: weightUnit)(oldValue, newValue)
        }
    if let onPlateCalc {
        Button(action: onPlateCalc) {
            Image(systemName: "scalemass.fill")
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.accentOrange)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plate calculator")
    }
}
.frame(width: 80)
.padding(6)
.background(AppTheme.Colors.separator.opacity(0.3))
.clipShape(RoundedRectangle(cornerRadius: 6))
```

**Step 2: Update ExerciseSetCard.rowView to pass the onPlateCalc callback**

Replace the `rowView(for:)` method (lines 225-247):

```swift
private func rowView(for idx: Int) -> some View {
    SetRow(
        setNumber: idx + 1,
        state: sets[idx],
        onRepsChange: Self.repsChangeAction(
            viewModel: viewModel,
            exerciseName: exercise.exercise,
            setIndex: idx
        ),
        onWeightChange: Self.weightChangeAction(
            viewModel: viewModel,
            exerciseName: exercise.exercise,
            setIndex: idx
        ),
        weightUnit: viewModel.weightUnit,
        bodyweightOnly: exercise.bodyweightOnly,
        onToggle: Self.toggleAction(
            viewModel: viewModel,
            exerciseName: exercise.exercise,
            setIndex: idx
        ),
        onPlateCalc: exercise.bodyweightOnly ? nil : Self.actualWeightPlateCalcAction(
            viewModel: viewModel,
            exerciseName: exercise.exercise,
            setIndex: idx,
            sets: sets
        )
    )
}

static func actualWeightPlateCalcAction(
    viewModel: WorkoutExecutionViewModel,
    exerciseName: String,
    setIndex: Int,
    sets: [SetExecutionState]
) -> () -> Void {
    {
        let weightKg = sets[setIndex].actualWeightKg ?? sets[setIndex].prescribedWeightKg ?? 0
        viewModel.openPlateCalcForActual(exerciseName: exerciseName, weightKg: weightKg)
    }
}
```

**Step 3: Build and test**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Workouts/WorkoutExecutionView.swift
git commit -m "feat: add plate calculator icon to Actual Weight input fields"
```

---

### Task 8: Wire Up BarbellRepository in DashboardViewModel and Callers

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift`
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift`
- Modify: `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift`

**Step 1: Update DashboardViewModel to seed and provide barbell repo**

In `DashboardViewModel.swift`, add a property:

```swift
var gender: Gender?
```

Update `loadUserConfiguration` (line 66-72) to also store gender and seed presets:

```swift
private func loadUserConfiguration(modelContext: ModelContext) -> User? {
    let userRepo = SwiftDataUserRepository(context: modelContext)
    let currentUser = try? userRepo.fetchCurrentUser()
    barbellWeightKg = Self.barbellWeight(for: currentUser?.gender)
    weightUnit = currentUser?.weightUnit ?? .pounds
    gender = currentUser?.gender

    // Seed built-in barbell presets if needed
    let barbellRepo = SwiftDataBarbellRepository(context: modelContext)
    barbellRepo.seedBuiltInPresets(userID: currentUser?.id ?? "")

    return currentUser
}
```

**Step 2: Update DashboardView to pass barbellRepo and context to WorkoutExecutionViewModel**

In `DashboardView.swift`, update the `.navigationDestination(for: StartWorkoutDestination.self)` (lines 75-88):

```swift
.navigationDestination(for: StartWorkoutDestination.self) { dest in
    if let program = viewModel.activeProgram {
        WorkoutExecutionView(
            viewModel: WorkoutExecutionViewModel(
                session: dest.session,
                enrollment: dest.enrollment,
                program: program,
                oneRepMaxes: viewModel.oneRepMaxes,
                barbellWeightKg: viewModel.barbellWeightKg,
                weightUnit: viewModel.weightUnit,
                barbellRepo: SwiftDataBarbellRepository(context: modelContext),
                userID: appState.currentUserID ?? "",
                gender: viewModel.gender
            )
        )
    }
}
```

Update the `.navigationDestination(for: StartAIWorkoutDestination.self)` (lines 89-95):

```swift
.navigationDestination(for: StartAIWorkoutDestination.self) { _ in
    AIWorkoutFlowView(
        userID: appState.currentUserID ?? "",
        barbellWeightKg: viewModel.barbellWeightKg,
        weightUnit: viewModel.weightUnit,
        gender: viewModel.gender
    )
}
```

**Step 3: Update AIWorkoutFlowView**

In `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift`, add `gender` property and pass it through:

```swift
struct AIWorkoutFlowView: View {
    let userID: String
    let barbellWeightKg: Double
    let weightUnit: WeightUnit
    let gender: Gender?
    // ... existing code
```

When creating `WorkoutExecutionViewModel` in the navigation destination, add the barbell repo:

```swift
WorkoutExecutionView(
    viewModel: WorkoutExecutionViewModel(
        generatedWorkout: workout,
        barbellWeightKg: barbellWeightKg,
        weightUnit: weightUnit,
        barbellRepo: SwiftDataBarbellRepository(context: modelContext),
        userID: userID,
        gender: gender
    )
)
```

Note: `AIWorkoutFlowView` will need `@Environment(\.modelContext) private var modelContext` added if not already present.

**Step 4: Update WorkoutExecutionView to load barbell presets on appear**

In `WorkoutExecutionView`, add `.onAppear` to the body (or in the `.task` modifier):

After the `.sheet(isPresented:)` line, add:

```swift
.onAppear { viewModel.loadBarbellPresets() }
```

**Step 5: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 6: Commit**

```bash
git add SundeeFundee/Features/Dashboard/DashboardViewModel.swift SundeeFundee/Features/Dashboard/DashboardView.swift SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift SundeeFundee/Features/Workouts/WorkoutExecutionView.swift
git commit -m "feat: wire BarbellRepository through Dashboard and AI workout flows"
```

---

### Task 9: Equipment Settings Section with Barbell Presets Management

**Files:**
- Create: `SundeeFundee/Features/Settings/BarbellPresetsView.swift`
- Modify: `SundeeFundee/Features/Settings/SettingsView.swift`
- Modify: `SundeeFundee/Features/Settings/SettingsViewModel.swift`

**Step 1: Add barbell preset management to SettingsViewModel**

In `SundeeFundee/Features/Settings/SettingsViewModel.swift`, add properties after `var injuryProfiles`:

```swift
var barbellPresets: [BarbellPresetDTO] = []
```

In the `load` method, after loading injury profiles (after line 39), add:

```swift
let barbellRepo = SwiftDataBarbellRepository(context: modelContext)
barbellRepo.seedBuiltInPresets(userID: userID)
barbellPresets = (try? barbellRepo.fetchPresets(userID: userID)) ?? []
```

Add methods for CRUD:

```swift
func addCustomBarbell(name: String, weightKg: Double) {
    guard let ctx = modelContext else { return }
    let repo = SwiftDataBarbellRepository(context: ctx)
    let maxOrder = barbellPresets.map(\.sortOrder).max() ?? 0
    let preset = BarbellPresetDTO(
        id: UUID().uuidString,
        userID: userID,
        name: name,
        weightKg: weightKg,
        isBuiltIn: false,
        sortOrder: maxOrder + 1
    )
    try? repo.savePreset(preset)
    barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
}

func deleteCustomBarbell(id: String) {
    guard let ctx = modelContext else { return }
    let repo = SwiftDataBarbellRepository(context: ctx)
    try? repo.deletePreset(id: id)
    barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
}
```

**Step 2: Create BarbellPresetsView**

Create `SundeeFundee/Features/Settings/BarbellPresetsView.swift`:

```swift
import SwiftUI

struct BarbellPresetsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                ForEach(viewModel.barbellPresets, id: \.id) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(AppTheme.Colors.navy)
                            Text(Self.weightLabel(preset: preset, weightUnit: viewModel.weightUnit))
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                        Spacer()
                        if preset.isBuiltIn {
                            Text("Built-in")
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !preset.isBuiltIn {
                            Button(role: .destructive) {
                                viewModel.deleteCustomBarbell(id: preset.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Barbells")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddBarbellSheet(viewModel: viewModel)
        }
    }

    static func weightLabel(preset: BarbellPresetDTO, weightUnit: WeightUnit) -> String {
        let formatted = WeightUnitConversion.format(kilograms: preset.weightKg, unit: weightUnit, maximumFractionDigits: 1)
        return "\(formatted) \(weightUnit.symbol)"
    }
}

// MARK: - AddBarbellSheet

struct AddBarbellSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var weightValue: String = ""

    static func canSave(name: String, weightValue: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(weightValue) != nil && (Double(weightValue) ?? 0) > 0
    }

    static func saveAction(
        viewModel: SettingsViewModel,
        name: String,
        weightValue: String,
        weightUnit: WeightUnit,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            guard let value = Double(weightValue) else { return }
            let kg = WeightUnitConversion.kilograms(from: value, unit: weightUnit)
            viewModel.addCustomBarbell(name: name.trimmingCharacters(in: .whitespaces), weightKg: kg)
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Trap Bar, Safety Squat Bar", text: $name)
                }
                Section("Weight (\(viewModel.weightUnit.symbol))") {
                    TextField("Weight", text: $weightValue)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Barbell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        name: name,
                        weightValue: weightValue,
                        weightUnit: viewModel.weightUnit,
                        dismiss: dismiss.callAsFunction
                    ))
                    .disabled(!Self.canSave(name: name, weightValue: weightValue))
                }
            }
        }
    }
}
```

**Step 3: Add Equipment section to SettingsView**

In `SundeeFundee/Features/Settings/SettingsView.swift`, add a new section between "Training" (line 70) and "Premium" (line 73):

```swift
// Equipment
Section("Equipment") {
    NavigationLink("Barbells") {
        BarbellPresetsView(viewModel: viewModel)
    }
}
```

**Step 4: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Settings/BarbellPresetsView.swift SundeeFundee/Features/Settings/SettingsView.swift SundeeFundee/Features/Settings/SettingsViewModel.swift
git commit -m "feat: add Equipment settings section with barbell preset management"
```

---

### Task 10: Coverage Tests for New UI Static Methods

**Files:**
- Create: `SundeeFundeTests/BarbellUICoverageTests.swift`

**Step 1: Write coverage tests for all new static methods**

Create `SundeeFundeTests/BarbellUICoverageTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("PlateCalculatorSheet.presetLabel")
struct PlateCalcSheetCoverageTests {

    @Test func presetLabelFormatsCorrectly() {
        let preset = BarbellPresetDTO(id: "1", userID: "u", name: "Standard", weightKg: 45.0 / WeightUnitConversion.poundsPerKilogram, isBuiltIn: true, sortOrder: 0)
        let label = PlateCalculatorSheet.presetLabel(preset: preset, weightUnit: .pounds)
        #expect(label.contains("Standard"))
        #expect(label.contains("45"))
        #expect(label.contains("lb"))
    }

    @Test func presetLabelKg() {
        let preset = BarbellPresetDTO(id: "1", userID: "u", name: "Women's", weightKg: 15.0, isBuiltIn: true, sortOrder: 1)
        let label = PlateCalculatorSheet.presetLabel(preset: preset, weightUnit: .kilograms)
        #expect(label.contains("Women's"))
        #expect(label.contains("kg"))
    }
}

@Suite("BarbellPresetsView.weightLabel")
struct BarbellPresetsViewCoverageTests {

    @Test func weightLabelPounds() {
        let preset = BarbellPresetDTO(id: "1", userID: "u", name: "EZ Curl", weightKg: 15.0 / WeightUnitConversion.poundsPerKilogram, isBuiltIn: true, sortOrder: 3)
        let label = BarbellPresetsView.weightLabel(preset: preset, weightUnit: .pounds)
        #expect(label.contains("15"))
        #expect(label.contains("lb"))
    }

    @Test func weightLabelKg() {
        let preset = BarbellPresetDTO(id: "1", userID: "u", name: "Standard", weightKg: 20.0, isBuiltIn: true, sortOrder: 0)
        let label = BarbellPresetsView.weightLabel(preset: preset, weightUnit: .kilograms)
        #expect(label.contains("20"))
        #expect(label.contains("kg"))
    }
}

@Suite("AddBarbellSheet.canSave")
struct AddBarbellSheetCoverageTests {

    @Test func canSaveReturnsFalseForEmptyName() {
        #expect(!AddBarbellSheet.canSave(name: "", weightValue: "45"))
        #expect(!AddBarbellSheet.canSave(name: "  ", weightValue: "45"))
    }

    @Test func canSaveReturnsFalseForInvalidWeight() {
        #expect(!AddBarbellSheet.canSave(name: "Bar", weightValue: ""))
        #expect(!AddBarbellSheet.canSave(name: "Bar", weightValue: "abc"))
        #expect(!AddBarbellSheet.canSave(name: "Bar", weightValue: "0"))
        #expect(!AddBarbellSheet.canSave(name: "Bar", weightValue: "-5"))
    }

    @Test func canSaveReturnsTrueForValidInput() {
        #expect(AddBarbellSheet.canSave(name: "Trap Bar", weightValue: "55"))
        #expect(AddBarbellSheet.canSave(name: "SSB", weightValue: "65.5"))
    }
}

@Suite("ExerciseSetCard.actualWeightPlateCalcAction")
@MainActor
struct ExerciseSetCardActualWeightPlateCalcTests {

    @Test func actionUsesActualWeightWhenAvailable() {
        let vm = makeVM()
        vm.exerciseSets["Squat"]?[0].actualWeightKg = 100.0
        let sets = vm.exerciseSets["Squat"]!
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "Squat", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.plateCalcWeightKg == 100.0)
        #expect(vm.showPlateCalc == true)
    }

    @Test func actionFallsToPrescribedWeight() {
        let vm = makeVM()
        vm.exerciseSets["Squat"]?[0].actualWeightKg = nil
        vm.exerciseSets["Squat"]?[0].prescribedWeightKg = 80.0
        let sets = vm.exerciseSets["Squat"]!
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "Squat", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.plateCalcWeightKg == 80.0)
    }

    @Test func actionDefaultsToZero() {
        let vm = makeVM()
        vm.exerciseSets["Squat"]?[0].actualWeightKg = nil
        vm.exerciseSets["Squat"]?[0].prescribedWeightKg = nil
        let sets = vm.exerciseSets["Squat"]!
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "Squat", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.plateCalcWeightKg == 0)
    }

    private func makeVM() -> WorkoutExecutionViewModel {
        let exercises = [
            ProgramExercise(exercise: "Squat", variant: nil, sets: .fixed(3), reps: .fixed(5), percent1RM: nil, restMinutes: 2, notes: nil, bodyweightOnly: false),
        ]
        let session = ProgramSession(sessionID: "s1", sessionName: "Test", sessionType: "strength", focus: "Legs", exercises: exercises)
        let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1")
        let program = Program(id: "p1", name: "Test", description: "", difficulty: "Intermediate", durationWeeks: 4, sessionsPerWeek: 3, weeks: [])
        return WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
    }
}
```

**Step 2: Run all tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests`
Expected: All PASS.

**Step 3: Commit**

```bash
git add SundeeFundeTests/BarbellUICoverageTests.swift
git commit -m "test: add coverage tests for barbell UI static methods"
```

---

### Task 11: Run Full Test Suite and Fix Coverage Gaps

**Step 1: Run ALL tests**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests`

**Step 2: Fix any test failures**

Existing tests may break if they create `WorkoutExecutionViewModel` without the new optional params. Since `barbellRepo`, `userID`, and `gender` all have defaults, this should not happen. But verify and fix if needed.

Also check that `PlateCalculatorSheet` init calls in tests still compile — the new params have defaults so they should.

**Step 3: Check coverage**

If any new public methods lack coverage, add tests. Key areas to check:
- `SettingsViewModel.addCustomBarbell` and `deleteCustomBarbell`
- `WorkoutExecutionViewModel.loadBarbellPresets`
- `SwiftDataBarbellRepository` methods (tested via mock, but verify SwiftData impl compiles)

**Step 4: Regenerate Xcode project if needed**

If new files aren't being picked up:
```bash
xcodegen generate
```

**Step 5: Final commit**

```bash
git add -A
git commit -m "fix: resolve test failures and coverage gaps for plate calculator improvements"
```

---

### Task 12: Final Integration Build and Verification

**Step 1: Clean build**

Run: `xcodebuild clean build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

**Step 2: Run full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests`

**Step 3: Verify all tests pass and no regressions**

Expected: All tests PASS, build succeeds, zero warnings from new code.

**Step 4: Final commit if any cleanup was needed**

```bash
git add -A
git commit -m "chore: final cleanup for plate calculator improvements (issue #98)"
```
