# Custom Program Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow Plus/Premium users to create custom multi-week training programs via a hybrid guided builder: pick a template, customize basics, then drill into individual sessions and exercises.

**Architecture:** New `CustomProgramRecord` SwiftData model wrapping the existing `Program` Codable struct as JSON. `ProgramTemplateGenerator` produces the initial structure from 3 templates (Strength/Hypertrophy/Full Body). Four new views handle the creation flow (template picker, program editor, session editor, exercise editor). `ProgramListView` is extended to show custom programs alongside bundled ones.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing

---

## File Structure

```
New files:
  SundeeFundee/Models/CustomProgramRecord.swift            — SwiftData wrapper for custom programs
  SundeeFundee/App/AppSchemaV10.swift                      — Schema version adding CustomProgramRecord
  SundeeFundee/Repositories/SwiftData/SwiftDataCustomProgramRepository.swift
  SundeeFundee/Domain/ProgramTemplateGenerator.swift       — Pure Swift template generation
  SundeeFundee/Features/Programs/CreateProgramView.swift   — Template picker + basics form
  SundeeFundee/Features/Programs/CreateProgramViewModel.swift
  SundeeFundee/Features/Programs/ProgramEditorView.swift   — Week/session overview with save
  SundeeFundee/Features/Programs/SessionEditorView.swift   — Exercise list with add/reorder/delete
  SundeeFundee/Features/Programs/ExerciseEditorSheet.swift — Modal for editing exercise details

Modified files:
  SundeeFundee/App/AppModelContainer.swift:104             — allModels → AppSchemaV10
  SundeeFundee/App/AppSchemaMigrationPlan.swift            — Add V10 schema + migration stage
  SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift — Add CustomProgramRepository
  SundeeFundee/Features/Programs/ProgramListView.swift     — Add Create button + custom programs
  SundeeFundee/Features/Programs/ProgramListViewModel.swift — Load + delete custom programs
```

---

### Task 1: CustomProgramRecord Model and Schema V10

**Files:**
- Create: `SundeeFundee/Models/CustomProgramRecord.swift`
- Create: `SundeeFundee/App/AppSchemaV10.swift`
- Modify: `SundeeFundee/App/AppModelContainer.swift:104`
- Modify: `SundeeFundee/App/AppSchemaMigrationPlan.swift`
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift` (update schema count test if exists)

- [ ] **Step 1: Create CustomProgramRecord.swift**

```swift
import SwiftData
import Foundation

@Model
final class CustomProgramRecord {
    var id: String
    var userID: String
    var name: String
    var programJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        programJSON: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.programJSON = programJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toProgram() -> Program? {
        guard let data = programJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Program.self, from: data)
    }

    static func from(_ program: Program, userID: String) -> CustomProgramRecord? {
        guard let data = try? JSONEncoder().encode(program),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return CustomProgramRecord(
            id: program.id,
            userID: userID,
            name: program.name,
            programJSON: json
        )
    }
}
```

- [ ] **Step 2: Create AppSchemaV10.swift**

```swift
import SwiftData

/// Schema V10 — adds CustomProgramRecord for user-created programs.
enum AppSchemaV10: VersionedSchema {
    static let versionIdentifier = Schema.Version(10, 0, 0)

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
            CustomProgramRecord.self,
        ]
    }
}
```

- [ ] **Step 3: Update AppModelContainer.swift**

Change line 104 from:
```swift
private static let allModels: [any PersistentModel.Type] = AppSchemaV9.models
```
to:
```swift
private static let allModels: [any PersistentModel.Type] = AppSchemaV10.models
```

- [ ] **Step 4: Update AppSchemaMigrationPlan.swift**

Add `AppSchemaV10.self` to the `schemas` array and add a lightweight migration stage from V9 to V10. Find the `schemas` array and add V10:

```swift
[AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self, AppSchemaV9.self, AppSchemaV10.self]
```

Add a new migration stage at the end of the `stages` array:

```swift
MigrationStage.lightweight(fromVersion: AppSchemaV9.self, toVersion: AppSchemaV10.self),
```

- [ ] **Step 5: Add CustomProgramRepository protocol**

Append to `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift`:

```swift
// MARK: - CustomProgramRepository

protocol CustomProgramRepository {
    func save(_ record: CustomProgramRecord) throws
    func fetchAll(userID: String) throws -> [CustomProgramRecord]
    func fetch(id: String) throws -> CustomProgramRecord?
    func update(_ record: CustomProgramRecord) throws
    func delete(_ record: CustomProgramRecord) throws
}
```

- [ ] **Step 6: Update schema count tests if they exist**

Search `SundeeFundeTests/` for tests that assert schema count or stage count (e.g., `AppAuthCoverageTests.appSchemaAndContainerMetadataIsAccessible`). Update the expected schema count from the old value to old+1, and the stage count from old to old+1.

- [ ] **Step 7: Regenerate Xcode project and build**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate && xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add SundeeFundee/Models/CustomProgramRecord.swift SundeeFundee/App/AppSchemaV10.swift \
  SundeeFundee/App/AppModelContainer.swift SundeeFundee/App/AppSchemaMigrationPlan.swift \
  SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift SundeeFundeTests/
git commit -m "feat: add CustomProgramRecord model and schema V10"
```

---

### Task 2: CustomProgramRepository Implementation

**Files:**
- Create: `SundeeFundee/Repositories/SwiftData/SwiftDataCustomProgramRepository.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift` (append test suite)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/SubscriptionTests.swift`:

```swift
// MARK: - CustomProgramRecord Tests

@Suite("CustomProgramRecord")
struct CustomProgramRecordTests {

    @Test func roundTripProgramJSON() {
        let program = Program(
            id: "test-1", name: "Test Program", category: "custom",
            description: "A test", durationWeeks: 4, sessionsPerWeek: 3,
            difficulty: "intermediate", phases: [], weeks: [],
            cycleAdjustmentProfile: nil
        )
        let record = CustomProgramRecord.from(program, userID: "user-1")
        #expect(record != nil)
        #expect(record?.name == "Test Program")
        let decoded = record?.toProgram()
        #expect(decoded?.id == "test-1")
        #expect(decoded?.name == "Test Program")
        #expect(decoded?.category == "custom")
        #expect(decoded?.durationWeeks == 4)
    }

    @Test func fromNilForInvalidProgram() {
        // A valid program should always encode, but test the wrapper exists
        let record = CustomProgramRecord(userID: "u1", name: "Bad", programJSON: "not json")
        #expect(record.toProgram() == nil)
    }
}
```

- [ ] **Step 2: Implement SwiftDataCustomProgramRepository.swift**

```swift
import Foundation
import SwiftData

@MainActor
final class SwiftDataCustomProgramRepository: CustomProgramRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ record: CustomProgramRecord) throws {
        context.insert(record)
        try context.save()
    }

    func fetchAll(userID: String) throws -> [CustomProgramRecord] {
        let descriptor = FetchDescriptor<CustomProgramRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(id: String) throws -> CustomProgramRecord? {
        let descriptor = FetchDescriptor<CustomProgramRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    func update(_ record: CustomProgramRecord) throws {
        record.updatedAt = .now
        try context.save()
    }

    func delete(_ record: CustomProgramRecord) throws {
        context.delete(record)
        try context.save()
    }
}
```

- [ ] **Step 3: Regenerate Xcode project and run tests**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/CustomProgramRecordTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Repositories/SwiftData/SwiftDataCustomProgramRepository.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add SwiftDataCustomProgramRepository with tests"
```

---

### Task 3: ProgramTemplateGenerator

**Files:**
- Create: `SundeeFundee/Domain/ProgramTemplateGenerator.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift` (append test suite)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/SubscriptionTests.swift`:

```swift
// MARK: - ProgramTemplateGenerator Tests

@Suite("ProgramTemplateGenerator")
struct ProgramTemplateGeneratorTests {

    @Test func strengthTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "My Strength", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.name == "My Strength")
        #expect(program.category == "custom")
        #expect(program.durationWeeks == 4)
        #expect(program.sessionsPerWeek == 3)
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
            for session in week.sessions {
                #expect(!session.exercises.isEmpty)
            }
        }
    }

    @Test func hypertrophyTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .hypertrophy, name: "Hyper", durationWeeks: 6, sessionsPerWeek: 4
        )
        #expect(program.durationWeeks == 6)
        #expect(program.sessionsPerWeek == 4)
        #expect(program.weeks.count == 6)
        for week in program.weeks {
            #expect(week.sessions.count == 4)
        }
    }

    @Test func fullBodyTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .fullBody, name: "FB", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
        }
    }

    @Test func progressiveOverloadIncreasesPercent1RM() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
        )
        let week1FirstExercise = program.weeks[0].sessions[0].exercises[0]
        let week4FirstExercise = program.weeks[3].sessions[0].exercises[0]
        let w1Pct = week1FirstExercise.percent1RM ?? 0
        let w4Pct = week4FirstExercise.percent1RM ?? 0
        #expect(w4Pct > w1Pct, "Week 4 should have higher %1RM than week 1")
    }

    @Test func customDurationAndFrequency() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "Custom", durationWeeks: 8, sessionsPerWeek: 5
        )
        #expect(program.weeks.count == 8)
        for week in program.weeks {
            #expect(week.sessions.count == 5)
        }
    }

    @Test func allTemplatesProduceValidIDs() {
        for template in ProgramTemplate.allCases {
            let program = ProgramTemplateGenerator.generate(
                template: template, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
            )
            #expect(!program.id.isEmpty)
            #expect(program.id != "")
        }
    }

    @Test func templateDisplayInfo() {
        #expect(ProgramTemplate.strength.displayName == "Strength")
        #expect(ProgramTemplate.hypertrophy.displayName == "Hypertrophy")
        #expect(ProgramTemplate.fullBody.displayName == "Full Body")
        #expect(!ProgramTemplate.strength.icon.isEmpty)
        #expect(!ProgramTemplate.strength.subtitle.isEmpty)
        #expect(!ProgramTemplate.strength.descriptionText.isEmpty)
    }
}
```

- [ ] **Step 2: Implement ProgramTemplateGenerator.swift**

```swift
import Foundation

enum ProgramTemplate: String, CaseIterable, Sendable {
    case strength
    case hypertrophy
    case fullBody

    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .hypertrophy: "Hypertrophy"
        case .fullBody: "Full Body"
        }
    }

    var icon: String {
        switch self {
        case .strength: "figure.strengthtraining.traditional"
        case .hypertrophy: "figure.highintensity.intervaltraining"
        case .fullBody: "bolt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .strength: "Heavy compounds, low reps"
        case .hypertrophy: "Higher volume, muscle growth"
        case .fullBody: "Balanced, all muscle groups"
        }
    }

    var descriptionText: String {
        switch self {
        case .strength: "4 weeks · 3x/week"
        case .hypertrophy: "6 weeks · 4x/week"
        case .fullBody: "4 weeks · 3x/week"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .strength: 4
        case .hypertrophy: 6
        case .fullBody: 4
        }
    }

    var defaultFrequency: Int {
        switch self {
        case .strength: 3
        case .hypertrophy: 4
        case .fullBody: 3
        }
    }
}

enum ProgramTemplateGenerator {

    static func generate(
        template: ProgramTemplate,
        name: String,
        durationWeeks: Int,
        sessionsPerWeek: Int
    ) -> Program {
        let weeks = (1...durationWeeks).map { weekNum in
            let sessions = (1...sessionsPerWeek).map { dayNum in
                buildSession(template: template, week: weekNum, day: dayNum, sessionsPerWeek: sessionsPerWeek)
            }
            return ProgramWeek(week: weekNum, phaseID: nil, isTestWeek: nil, sessions: sessions)
        }

        return Program(
            id: UUID().uuidString,
            name: name,
            category: "custom",
            description: "\(template.displayName) program — \(durationWeeks) weeks, \(sessionsPerWeek)x/week",
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek,
            difficulty: "intermediate",
            phases: [],
            weeks: weeks,
            cycleAdjustmentProfile: nil
        )
    }

    // MARK: - Session Building

    private static func buildSession(
        template: ProgramTemplate,
        week: Int,
        day: Int,
        sessionsPerWeek: Int
    ) -> ProgramSession {
        let focus = sessionFocus(template: template, day: day, sessionsPerWeek: sessionsPerWeek)
        let exercises = sessionExercises(template: template, focus: focus, week: week)

        return ProgramSession(
            sessionID: "w\(week)d\(day)",
            sessionName: "Day \(day) — \(focus.capitalized) Focus",
            sessionType: "strength",
            focus: focus,
            exercises: exercises
        )
    }

    private static func sessionFocus(template: ProgramTemplate, day: Int, sessionsPerWeek: Int) -> String {
        switch template {
        case .strength:
            let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
            return focuses[(day - 1) % focuses.count]
        case .hypertrophy:
            let focuses = ["upper", "lower", "push", "pull", "upper"]
            return focuses[(day - 1) % focuses.count]
        case .fullBody:
            let focuses = ["full body a", "full body b", "full body c", "full body a", "full body b"]
            return focuses[(day - 1) % focuses.count]
        }
    }

    private static func sessionExercises(template: ProgramTemplate, focus: String, week: Int) -> [ProgramExercise] {
        let baseExercises = exercisePool(template: template, focus: focus)
        let progressionOffset = Double(week - 1) * 0.02 // +2% per week

        return baseExercises.map { (name, sets, reps, basePct, rest, bw) in
            ProgramExercise(
                exercise: name,
                variant: nil,
                sets: .fixed(sets),
                reps: .fixed(reps),
                percent1RM: bw ? nil : basePct + progressionOffset,
                restMinutes: rest,
                notes: nil,
                bodyweightOnly: bw
            )
        }
    }

    // MARK: - Exercise Pools

    // Returns: (name, sets, reps, basePct1RM, restMinutes, bodyweightOnly)
    private static func exercisePool(
        template: ProgramTemplate,
        focus: String
    ) -> [(String, Int, Int, Double, Double, Bool)] {
        switch template {
        case .strength:
            return strengthExercises(focus: focus)
        case .hypertrophy:
            return hypertrophyExercises(focus: focus)
        case .fullBody:
            return fullBodyExercises(focus: focus)
        }
    }

    private static func strengthExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "squat":
            return [
                ("Back Squat", 4, 5, 0.78, 3.0, false),
                ("Front Squat", 3, 5, 0.68, 2.5, false),
                ("Leg Press", 3, 8, 0.0, 2.0, false),
                ("Walking Lunge", 3, 10, 0.0, 1.5, false),
                ("Calf Raise", 3, 12, 0.0, 1.0, false),
            ]
        case "bench":
            return [
                ("Bench Press", 4, 5, 0.78, 3.0, false),
                ("Incline Dumbbell Press", 3, 8, 0.0, 2.0, false),
                ("Barbell Row", 4, 5, 0.72, 2.5, false),
                ("Dumbbell Lateral Raise", 3, 12, 0.0, 1.0, false),
                ("Tricep Pushdown", 3, 10, 0.0, 1.0, false),
            ]
        case "deadlift":
            return [
                ("Deadlift", 4, 5, 0.78, 3.0, false),
                ("Romanian Deadlift", 3, 8, 0.65, 2.0, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Hip Thrust", 3, 10, 0.0, 1.5, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        default:
            return [
                ("Overhead Press", 4, 5, 0.72, 3.0, false),
                ("Push Press", 3, 5, 0.68, 2.5, false),
                ("Lateral Raise", 3, 12, 0.0, 1.0, false),
                ("Face Pull", 3, 15, 0.0, 1.0, false),
                ("Dip", 3, 8, 0.0, 1.5, true),
            ]
        }
    }

    private static func hypertrophyExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "upper":
            return [
                ("Bench Press", 4, 10, 0.65, 2.0, false),
                ("Dumbbell Row", 4, 10, 0.0, 1.5, false),
                ("Overhead Press", 3, 10, 0.62, 1.5, false),
                ("Lat Pulldown", 3, 12, 0.0, 1.5, false),
                ("Bicep Curl", 3, 12, 0.0, 1.0, false),
                ("Tricep Extension", 3, 12, 0.0, 1.0, false),
            ]
        case "lower":
            return [
                ("Back Squat", 4, 10, 0.65, 2.0, false),
                ("Romanian Deadlift", 3, 10, 0.62, 2.0, false),
                ("Leg Press", 3, 12, 0.0, 1.5, false),
                ("Leg Curl", 3, 12, 0.0, 1.0, false),
                ("Calf Raise", 4, 15, 0.0, 1.0, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        case "push":
            return [
                ("Incline Bench Press", 4, 10, 0.62, 2.0, false),
                ("Dumbbell Fly", 3, 12, 0.0, 1.0, false),
                ("Overhead Press", 3, 10, 0.60, 1.5, false),
                ("Lateral Raise", 3, 15, 0.0, 1.0, false),
                ("Tricep Pushdown", 3, 12, 0.0, 1.0, false),
            ]
        default: // pull
            return [
                ("Barbell Row", 4, 10, 0.65, 2.0, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Face Pull", 3, 15, 0.0, 1.0, false),
                ("Hammer Curl", 3, 12, 0.0, 1.0, false),
                ("Shrug", 3, 12, 0.0, 1.0, false),
            ]
        }
    }

    private static func fullBodyExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "full body a":
            return [
                ("Back Squat", 3, 8, 0.70, 2.5, false),
                ("Bench Press", 3, 8, 0.70, 2.0, false),
                ("Barbell Row", 3, 8, 0.68, 2.0, false),
                ("Overhead Press", 3, 10, 0.62, 1.5, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        case "full body b":
            return [
                ("Deadlift", 3, 6, 0.75, 3.0, false),
                ("Incline Dumbbell Press", 3, 10, 0.0, 1.5, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Walking Lunge", 3, 10, 0.0, 1.5, false),
                ("Bicep Curl", 3, 12, 0.0, 1.0, false),
            ]
        default: // full body c
            return [
                ("Front Squat", 3, 8, 0.65, 2.5, false),
                ("Dumbbell Bench Press", 3, 10, 0.0, 1.5, false),
                ("Seated Row", 3, 10, 0.0, 1.5, false),
                ("Hip Thrust", 3, 10, 0.0, 1.5, false),
                ("Lateral Raise", 3, 12, 0.0, 1.0, false),
            ]
        }
    }
}
```

- [ ] **Step 3: Regenerate Xcode project and run tests**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/ProgramTemplateGeneratorTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Domain/ProgramTemplateGenerator.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add ProgramTemplateGenerator with 3 templates and tests"
```

---

### Task 4: CreateProgramView and ViewModel

**Files:**
- Create: `SundeeFundee/Features/Programs/CreateProgramViewModel.swift`
- Create: `SundeeFundee/Features/Programs/CreateProgramView.swift`
- Modify: `SundeeFundeTests/AIWorkoutViewModelTests.swift` (append test suite — or create new test file)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/AIWorkoutViewModelTests.swift`:

```swift
// MARK: - CreateProgramViewModel Tests

@Suite("CreateProgramViewModel")
@MainActor
struct CreateProgramViewModelTests {

    @Test func initialStateHasNoTemplate() {
        let vm = CreateProgramViewModel()
        #expect(vm.selectedTemplate == nil)
        #expect(vm.programName == "")
    }

    @Test func selectTemplatePopulatesDefaults() {
        let vm = CreateProgramViewModel()
        vm.selectTemplate(.strength)
        #expect(vm.selectedTemplate == .strength)
        #expect(vm.durationWeeks == 4)
        #expect(vm.sessionsPerWeek == 3)
    }

    @Test func selectHypertrophyDefaults() {
        let vm = CreateProgramViewModel()
        vm.selectTemplate(.hypertrophy)
        #expect(vm.durationWeeks == 6)
        #expect(vm.sessionsPerWeek == 4)
    }

    @Test func canGenerateRequiresNameAndTemplate() {
        let vm = CreateProgramViewModel()
        #expect(vm.canGenerate == false)
        vm.selectTemplate(.strength)
        #expect(vm.canGenerate == false)
        vm.programName = "My Program"
        #expect(vm.canGenerate == true)
    }

    @Test func canGenerateRejectsEmptyName() {
        let vm = CreateProgramViewModel()
        vm.selectTemplate(.strength)
        vm.programName = "   "
        #expect(vm.canGenerate == false)
    }

    @Test func generateCreatesValidProgram() {
        let vm = CreateProgramViewModel()
        vm.selectTemplate(.strength)
        vm.programName = "Test Block"
        vm.durationWeeks = 4
        vm.sessionsPerWeek = 3
        let program = vm.generateProgram()
        #expect(program != nil)
        #expect(program?.name == "Test Block")
        #expect(program?.category == "custom")
        #expect(program?.weeks.count == 4)
    }

    @Test func durationOptions() {
        #expect(CreateProgramViewModel.durationOptions == [3, 4, 6, 8])
    }

    @Test func frequencyOptions() {
        #expect(CreateProgramViewModel.frequencyOptions == [3, 4, 5])
    }
}
```

- [ ] **Step 2: Implement CreateProgramViewModel.swift**

```swift
import Foundation

@MainActor
@Observable
final class CreateProgramViewModel {
    var selectedTemplate: ProgramTemplate?
    var programName: String = ""
    var programDescription: String = ""
    var durationWeeks: Int = 4
    var sessionsPerWeek: Int = 3

    static let durationOptions = [3, 4, 6, 8]
    static let frequencyOptions = [3, 4, 5]

    var canGenerate: Bool {
        selectedTemplate != nil && !programName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func selectTemplate(_ template: ProgramTemplate) {
        selectedTemplate = template
        durationWeeks = template.defaultDuration
        sessionsPerWeek = template.defaultFrequency
    }

    func generateProgram() -> Program? {
        guard let template = selectedTemplate else { return nil }
        return ProgramTemplateGenerator.generate(
            template: template,
            name: programName.trimmingCharacters(in: .whitespaces),
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek
        )
    }
}
```

- [ ] **Step 3: Implement CreateProgramView.swift**

```swift
import SwiftUI

struct CreateProgramView: View {
    @State private var viewModel = CreateProgramViewModel()
    @State private var generatedProgram: Program?
    let userID: String
    var onProgramCreated: (Program) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    if viewModel.selectedTemplate == nil {
                        templatePicker
                    } else {
                        customizeSection
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle(viewModel.selectedTemplate == nil ? "New Program" : "Customize")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generatedProgram) { program in
            ProgramEditorView(program: program, userID: userID, onSave: onProgramCreated)
        }
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Choose a starting template")
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

            ForEach(ProgramTemplate.allCases, id: \.self) { template in
                Button {
                    viewModel.selectTemplate(template)
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.displayName)
                                .font(AppTheme.Fonts.subheading)
                            Text(template.descriptionText + " · " + template.subtitle)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .foregroundStyle(AppTheme.Colors.navy)
                    .cornerRadius(AppTheme.CornerRadius.card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Customize Section

    private var customizeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("PROGRAM NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                TextField("My Strength Block", text: $viewModel.programName)
                    .font(AppTheme.Fonts.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.button)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("DURATION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(CreateProgramViewModel.durationOptions, id: \.self) { weeks in
                        chipButton("\(weeks) wk", isSelected: viewModel.durationWeeks == weeks) {
                            viewModel.durationWeeks = weeks
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("SESSIONS PER WEEK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(CreateProgramViewModel.frequencyOptions, id: \.self) { freq in
                        chipButton("\(freq)", isSelected: viewModel.sessionsPerWeek == freq) {
                            viewModel.sessionsPerWeek = freq
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("DESCRIPTION (OPTIONAL)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                TextField("Focus on squat and deadlift PRs...", text: $viewModel.programDescription)
                    .font(AppTheme.Fonts.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.button)
            }

            Button {
                generatedProgram = viewModel.generateProgram()
            } label: {
                Text("Generate Program")
                    .font(AppTheme.Fonts.subheading)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.accentOrange)
            .disabled(!viewModel.canGenerate)
        }
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Fonts.body)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.navy)
                .cornerRadius(AppTheme.CornerRadius.button)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 4: Regenerate Xcode project, run tests, and build**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/CreateProgramViewModelTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/Programs/CreateProgramViewModel.swift \
  SundeeFundee/Features/Programs/CreateProgramView.swift \
  SundeeFundeTests/AIWorkoutViewModelTests.swift
git commit -m "feat: add CreateProgramView with template picker and customize form"
```

---

### Task 5: ProgramEditorView and SessionEditorView

**Files:**
- Create: `SundeeFundee/Features/Programs/ProgramEditorView.swift`
- Create: `SundeeFundee/Features/Programs/SessionEditorView.swift`
- Create: `SundeeFundee/Features/Programs/ExerciseEditorSheet.swift`

- [ ] **Step 1: Implement ProgramEditorView.swift**

```swift
import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var program: Program
    let userID: String
    var onSave: (Program) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    header

                    ForEach(Array(program.weeks.enumerated()), id: \.offset) { weekIndex, week in
                        weekSection(weekIndex: weekIndex, week: week)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Edit Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveProgram() }
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(program.name)
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
            Text("\(program.durationWeeks) weeks · \(program.sessionsPerWeek) sessions/week")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
        }
    }

    private func weekSection(weekIndex: Int, week: ProgramWeek) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WEEK \(week.week)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(week.sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                    NavigationLink {
                        SessionEditorView(
                            program: $program,
                            weekIndex: weekIndex,
                            sessionIndex: sessionIndex
                        )
                    } label: {
                        sessionRow(session: session)
                    }
                    .buttonStyle(.plain)

                    if sessionIndex < week.sessions.count - 1 {
                        Divider().padding(.leading, AppTheme.Spacing.md)
                    }
                }
            }
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.card)
        }
    }

    private func sessionRow(session: ProgramSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionName)
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text("\(session.exercises.count) exercises")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
        }
        .padding(AppTheme.Spacing.md)
    }

    private func saveProgram() {
        let repo = SwiftDataCustomProgramRepository(context: modelContext)
        if let record = CustomProgramRecord.from(program, userID: userID) {
            try? repo.save(record)
        }
        onSave(program)
        dismiss()
    }
}
```

- [ ] **Step 2: Implement SessionEditorView.swift**

```swift
import SwiftUI

struct SessionEditorView: View {
    @Binding var program: Program
    let weekIndex: Int
    let sessionIndex: Int
    @State private var editingExercise: EditableExercise?

    private var session: ProgramSession {
        program.weeks[weekIndex].sessions[sessionIndex]
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Week \(program.weeks[weekIndex].week)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

                    VStack(spacing: 0) {
                        ForEach(Array(session.exercises.enumerated()), id: \.offset) { exIndex, exercise in
                            Button {
                                editingExercise = EditableExercise(from: exercise, index: exIndex)
                            } label: {
                                exerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)

                            if exIndex < session.exercises.count - 1 {
                                Divider().padding(.leading, AppTheme.Spacing.md)
                            }
                        }
                    }
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.card)

                    Button {
                        addExercise()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Exercise", systemImage: "plus")
                                .font(AppTheme.Fonts.subheading)
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(AppTheme.Colors.separator)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle(session.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExercise) { editable in
            ExerciseEditorSheet(exercise: editable) { updated in
                applyExerciseEdit(updated)
            }
        }
    }

    private func exerciseRow(exercise: ProgramExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise)
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Self.exerciseSubtitle(exercise))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
        }
        .padding(AppTheme.Spacing.md)
    }

    static func exerciseSubtitle(_ exercise: ProgramExercise) -> String {
        var parts: [String] = ["\(exercise.sets) × \(exercise.reps)"]
        if let pct = exercise.percent1RM, pct > 0 {
            parts.append("@ \(Int(pct * 100))%")
        }
        if let rest = exercise.restMinutes {
            if rest == floor(rest) {
                parts.append("\(Int(rest)) min rest")
            } else {
                let seconds = Int(rest * 60)
                parts.append("\(seconds) sec rest")
            }
        }
        return parts.joined(separator: " · ")
    }

    private func addExercise() {
        let newExercise = ProgramExercise(
            exercise: "New Exercise",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(10),
            percent1RM: nil,
            restMinutes: 1.5,
            notes: nil,
            bodyweightOnly: false
        )
        var weeks = program.weeks
        var sessions = weeks[weekIndex].sessions
        var exercises = sessions[sessionIndex].exercises
        exercises.append(newExercise)

        let updatedSession = ProgramSession(
            sessionID: session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus: session.focus,
            exercises: exercises
        )
        sessions[sessionIndex] = updatedSession
        weeks[weekIndex] = ProgramWeek(
            week: weeks[weekIndex].week,
            phaseID: weeks[weekIndex].phaseID,
            isTestWeek: weeks[weekIndex].isTestWeek,
            sessions: sessions
        )
        program = Program(
            id: program.id, name: program.name, category: program.category,
            description: program.description, durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek, difficulty: program.difficulty,
            phases: program.phases, weeks: weeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }

    private func applyExerciseEdit(_ editable: EditableExercise) {
        let updated = editable.toProgramExercise()
        var weeks = program.weeks
        var sessions = weeks[weekIndex].sessions
        var exercises = sessions[sessionIndex].exercises
        exercises[editable.index] = updated

        let updatedSession = ProgramSession(
            sessionID: session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus: session.focus,
            exercises: exercises
        )
        sessions[sessionIndex] = updatedSession
        weeks[weekIndex] = ProgramWeek(
            week: weeks[weekIndex].week,
            phaseID: weeks[weekIndex].phaseID,
            isTestWeek: weeks[weekIndex].isTestWeek,
            sessions: sessions
        )
        program = Program(
            id: program.id, name: program.name, category: program.category,
            description: program.description, durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek, difficulty: program.difficulty,
            phases: program.phases, weeks: weeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }
}
```

- [ ] **Step 3: Implement ExerciseEditorSheet.swift**

```swift
import SwiftUI

struct EditableExercise: Identifiable {
    let id = UUID()
    let index: Int
    var name: String
    var sets: Int
    var reps: Int
    var percent1RM: Double?
    var restMinutes: Double
    var bodyweightOnly: Bool

    init(from exercise: ProgramExercise, index: Int) {
        self.index = index
        self.name = exercise.exercise
        self.sets = Self.extractInt(from: exercise.sets)
        self.reps = Self.extractInt(from: exercise.reps)
        self.percent1RM = exercise.percent1RM
        self.restMinutes = exercise.restMinutes ?? 1.5
        self.bodyweightOnly = exercise.bodyweightOnly ?? false
    }

    func toProgramExercise() -> ProgramExercise {
        ProgramExercise(
            exercise: name,
            variant: nil,
            sets: .fixed(sets),
            reps: reps == 0 ? .amrap : .fixed(reps),
            percent1RM: bodyweightOnly ? nil : percent1RM,
            restMinutes: restMinutes,
            notes: nil,
            bodyweightOnly: bodyweightOnly
        )
    }

    private static func extractInt(from value: ExerciseValue) -> Int {
        switch value {
        case .fixed(let n): return n
        case .range(let lo, _): return lo
        case .amrap: return 0
        case .text: return 0
        }
    }
}

struct ExerciseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var exercise: EditableExercise
    var onSave: (EditableExercise) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        fieldSection("EXERCISE NAME") {
                            TextField("Back Squat", text: $exercise.name)
                                .font(AppTheme.Fonts.body)
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.cardBackground)
                                .cornerRadius(AppTheme.CornerRadius.button)
                        }

                        HStack(spacing: AppTheme.Spacing.md) {
                            fieldSection("SETS") {
                                Stepper("\(exercise.sets)", value: $exercise.sets, in: 1...10)
                                    .font(AppTheme.Fonts.body)
                            }
                            fieldSection("REPS") {
                                Stepper(exercise.reps == 0 ? "AMRAP" : "\(exercise.reps)", value: $exercise.reps, in: 0...30)
                                    .font(AppTheme.Fonts.body)
                            }
                        }

                        fieldSection("REST (MINUTES)") {
                            Stepper(String(format: "%.1f", exercise.restMinutes), value: $exercise.restMinutes, in: 0.5...5.0, step: 0.5)
                                .font(AppTheme.Fonts.body)
                        }

                        Toggle("Bodyweight Only", isOn: $exercise.bodyweightOnly)
                            .font(AppTheme.Fonts.body)
                            .tint(AppTheme.Colors.accentOrange)

                        if !exercise.bodyweightOnly {
                            fieldSection("% OF 1RM (OPTIONAL)") {
                                Stepper(
                                    exercise.percent1RM.map { "\(Int($0 * 100))%" } ?? "None",
                                    value: Binding(
                                        get: { exercise.percent1RM ?? 0 },
                                        set: { exercise.percent1RM = $0 > 0 ? $0 : nil }
                                    ),
                                    in: 0...1.0,
                                    step: 0.05
                                )
                                .font(AppTheme.Fonts.body)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(exercise)
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                }
            }
        }
    }

    private func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .tracking(1)
            content()
        }
    }
}
```

- [ ] **Step 4: Regenerate Xcode project and build**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate && xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/Programs/ProgramEditorView.swift \
  SundeeFundee/Features/Programs/SessionEditorView.swift \
  SundeeFundee/Features/Programs/ExerciseEditorSheet.swift
git commit -m "feat: add ProgramEditorView, SessionEditorView, and ExerciseEditorSheet"
```

---

### Task 6: Wire Into ProgramListView

**Files:**
- Modify: `SundeeFundee/Features/Programs/ProgramListView.swift`
- Modify: `SundeeFundee/Features/Programs/ProgramListViewModel.swift`

- [ ] **Step 1: Update ProgramListViewModel to load custom programs**

Add custom program support to `ProgramListViewModel`. Read the file first, then add:

After the existing `programs` property, add:
```swift
var customPrograms: [Program] = []
```

In the `load` method, after loading programs from `programRepo` and setting `enrollmentRepo`, add:
```swift
if let ctx = modelContext {
    let customRepo = SwiftDataCustomProgramRepository(context: ctx)
    let records = (try? customRepo.fetchAll(userID: "")) ?? []
    customPrograms = records.compactMap { $0.toProgram() }
}
```

Add a computed property for all programs combined:
```swift
var allPrograms: [Program] {
    customPrograms + programs
}
```

Add a delete method:
```swift
func deleteCustomProgram(id: String, modelContext: ModelContext) {
    let repo = SwiftDataCustomProgramRepository(context: modelContext)
    if let record = try? repo.fetch(id: id) {
        try? repo.delete(record)
        customPrograms.removeAll { $0.id == id }
    }
}
```

Add a static helper for the custom badge:
```swift
static func isCustomProgram(_ program: Program) -> Bool {
    program.category == "custom"
}
```

- [ ] **Step 2: Update ProgramListView to show Create button and custom programs**

In `ProgramListView`, add a toolbar item for the Create button. Add `@Environment(AppState.self)` to get subscription tier.

In the `.loaded` case, replace `ForEach(viewModel.programs)` with `ForEach(viewModel.allPrograms)`.

Add a toolbar to the body:
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
            CreateProgramView(userID: "") // TODO: pass real userID from environment
                .requiresSubscription(.programBuilder)
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(AppTheme.Colors.accentOrange)
        }
    }
}
```

In `ProgramCardView`, add a "Custom" badge when `program.category == "custom"`:
After the `isEnrolled` badge check, add:
```swift
if program.category == "custom" {
    Text("Custom")
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(AppTheme.Colors.accentOrange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(AppTheme.Colors.accentOrange.opacity(0.1))
        .clipShape(Capsule())
}
```

- [ ] **Step 3: Build and run full test suite**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```
Expected: ALL TESTS PASS

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Features/Programs/ProgramListView.swift \
  SundeeFundee/Features/Programs/ProgramListViewModel.swift
git commit -m "feat: wire custom programs into ProgramListView with Create button"
```

---

### Task 7: Final Verification and TODO Update

**Files:**
- Modify: `docs/TODO.md`

- [ ] **Step 1: Run full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```
Expected: ALL TESTS PASS

- [ ] **Step 2: Build clean**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Update TODO.md**

In `docs/TODO.md`, change:
```markdown
- [ ] **Custom Program Builder** — Create multi-week training programs
```
to:
```markdown
- [x] **Custom Program Builder** — Hybrid guided builder with 3 templates (Strength/Hypertrophy/Full Body), CustomProgramRecord SwiftData model, session/exercise editing, Plus-gated.
```

- [ ] **Step 4: Commit**

```bash
git add docs/TODO.md
git commit -m "docs: mark Custom Program Builder as complete"
```
