# Readiness Foundation and Shadow Assessment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the testable Weeks 1–2 foundation for Sundee Fundee 2.0: personal-baseline readiness models, deterministic scoring and confidence, live context assembly, derived-record persistence, and cached shadow assessments that do not alter workouts or appear in production UI.

**Architecture:** Pure recovery-domain types and services calculate readiness from a framework-light `DailyTrainingContext`. Small data-layer providers translate HealthKit and existing records into that context, then `DailyReadinessService` persists the derived assessment and refreshes the shared cache. No workout consumer is connected in this slice; automatic adaptations remain disabled until the foundation gate passes.

**Tech Stack:** Swift 6 strict concurrency, Foundation, HealthKit, CloudKit-compatible `Codable`, `DataClientProtocol`, `SharedSnapshotStore`, XCTest and Swift Testing, XcodeGen, SwiftLint.

## Global Constraints

- iOS 18+, macOS 15+, watchOS 11+, Swift 6 strict concurrency.
- CloudKit and `LocalDataClient` are the only persistence backends; add no external dependencies.
- Domain files import Foundation only and contain no logging.
- HealthKit denial and missing data are non-blocking; unknown inputs never score as zero.
- Cycle phase has zero score weight and cannot lower readiness by itself.
- Use `AppTheme.*` for any future UI; this slice creates no product UI.
- Raw HealthKit samples remain in HealthKit; persist only derived readiness results.
- New CloudKit dates use ISO8601 strings and avoid `createdAt`, `modifiedAt`, `startDate`, and `endDate`.
- `DailyReadinessRecord` must have a queryable `___recordID` index in the checked-in schema.
- Do not add paywalls or paid feature gates.
- Do not build for upload, upload, distribute through TestFlight, or submit to App Review without explicit user authorization.
- Stage only the files named in each commit step; never use `git add .` or `git add -A`, never amend, and never force-push.
- The project-local `cloudkit-validate` skill referenced by `AGENTS.md` is currently absent from `.Codex/skills`; use the schema assertions in Task 10 and report the missing skill instead of inventing it.

## Program Decomposition

This plan covers only the first release gate from the approved design spec:

1. Readiness foundation and shadow assessment — this plan.
2. Daily readiness experience and subjective check-in — separate plan after this gate.
3. Bounded adaptive training — separate plan after the readiness experience gate.
4. Program, progress, and social intelligence — separate plan after adaptation invariants pass.
5. Offline queue activation and final release hardening — separate plan before 2.0 release.

## File Structure

### New production files

- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessModels.swift` — shared enums and value types for context and assessment.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessBaselineNormalizer.swift` — personal-baseline eligibility and metric normalization.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessAssessmentService.swift` — weighted scoring, confidence, state, and reason codes.
- `SundeeFundee/Sources/SundeeFundeeKit/Models/DailyReadinessRecord.swift` — CloudKit/local derived-record representation and mapping.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HealthReadinessProvider.swift` — HealthKit-to-domain physiological snapshot conversion.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HistoryReadinessProvider.swift` — existing-record-to-domain subjective, pain, and training snapshot conversion.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyTrainingContextBuilder.swift` — concurrent provider orchestration.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyReadinessService.swift` — shadow calculation, persistence, and cache orchestration.

### Modified production files

- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SharedSnapshotStore.swift` — cached readiness snapshot read/write/clear support.
- `SundeeFundeeApp/cloudkit-schema.json` — `DailyReadinessRecord` schema with queryable record ID.
- `scripts/next-release-gate.sh` — schema guards for the new record.

### Test and gate files

- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessModelsTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessBaselineNormalizerTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessAssessmentServiceTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessScenarioTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessRecordTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HealthReadinessProviderTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HistoryReadinessProviderTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyTrainingContextBuilderTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessServiceTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SharedSnapshotStoreTests.swift`
- `scripts/readiness-foundation-gate.sh`
- `docs/release/readiness-foundation-gate.md`

---

### Task 1: Define the readiness domain contract

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessModels.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessModelsTests.swift`

**Interfaces:**
- Consumes: Existing `CyclePhase` and `PainType` domain enums.
- Produces: `ReadinessState`, `ReadinessConfidence`, `ReadinessScoreGroup`, `ReadinessSignalID`, `ReadinessReasonCode`, `ReadinessMetricSnapshot`, `PhysiologicalReadinessSnapshot`, `SubjectiveReadinessSnapshot`, `TrainingReadinessSnapshot`, `PainReadinessSnapshot`, `DailyTrainingContext`, and `ReadinessAssessment`.

- [ ] **Step 1: Write the failing model-contract tests**

```swift
import XCTest
@testable import SundeeFundeeKit

final class ReadinessModelsTests: XCTestCase {
    func testStateBandsAreStable() {
        XCTAssertEqual(ReadinessState.from(score: 100), .ready)
        XCTAssertEqual(ReadinessState.from(score: 80), .ready)
        XCTAssertEqual(ReadinessState.from(score: 79), .maintain)
        XCTAssertEqual(ReadinessState.from(score: 60), .maintain)
        XCTAssertEqual(ReadinessState.from(score: 59), .recover)
        XCTAssertEqual(ReadinessState.from(score: 35), .recover)
        XCTAssertEqual(ReadinessState.from(score: 34), .rest)
        XCTAssertEqual(ReadinessState.from(score: 0), .rest)
    }

    func testStricterStateKeepsTheMoreCautiousValue() {
        XCTAssertEqual(ReadinessState.stricter(.ready, .recover), .recover)
        XCTAssertEqual(ReadinessState.stricter(.rest, .maintain), .rest)
    }

    func testContextCarriesCycleWithoutMakingItAScoreSignal() {
        let context = DailyTrainingContext(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000),
            timeZoneIdentifier: "America/New_York",
            physiological: .empty,
            subjective: .empty,
            training: .empty,
            pain: nil,
            cyclePhase: .luteal,
            cycleConfidence: 0.8
        )

        XCTAssertEqual(context.cyclePhase, .luteal)
        XCTAssertFalse(ReadinessSignalID.allCases.contains(.cyclePhase))
    }
}
```

- [ ] **Step 2: Run the model tests and confirm the contract is missing**

Run:

```bash
cd SundeeFundee
swift test --filter ReadinessModelsTests
```

Expected: FAIL with `cannot find 'ReadinessState' in scope`.

- [ ] **Step 3: Add the complete domain vocabulary**

```swift
import Foundation

public enum ReadinessState: String, Codable, Sendable, Equatable, CaseIterable {
    case ready
    case maintain
    case recover
    case rest

    public var rank: Int {
        switch self {
        case .ready: 3
        case .maintain: 2
        case .recover: 1
        case .rest: 0
        }
    }

    public static func from(score: Int) -> Self {
        switch min(100, max(0, score)) {
        case 80...100: .ready
        case 60..<80: .maintain
        case 35..<60: .recover
        default: .rest
        }
    }

    public static func stricter(_ lhs: Self, _ rhs: Self) -> Self {
        lhs.rank <= rhs.rank ? lhs : rhs
    }
}

public enum ReadinessConfidence: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
}

public enum ReadinessScoreGroup: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case physiological
    case subjective
    case training
    case symptomsAndPain

    public var weight: Double {
        switch self {
        case .physiological, .subjective: 0.30
        case .training: 0.25
        case .symptomsAndPain: 0.15
        }
    }
}

public enum ReadinessSignalID: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case sleep
    case hrv
    case restingHeartRate
    case energy
    case fatigue
    case stress
    case soreness
    case perceivedReadiness
    case trainingLoad
    case sessionRPE
    case rightForToday
    case cramps
    case pain
}

public enum ReadinessReasonCode: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case stillLearning
    case missingSignals
    case goodSleep
    case hrvAtOrAboveBaseline
    case restingHeartRateNormal
    case highEnergy
    case balancedTrainingLoad
    case sleepBelowBaseline
    case hrvBelowBaseline
    case restingHeartRateElevated
    case lowEnergy
    case highFatigue
    case highStress
    case highSoreness
    case highTrainingLoad
    case highPain
}

public struct ReadinessMetricSnapshot: Sendable, Equatable {
    public let currentValue: Double
    public let baselineValues: [Double]
    public let observedAt: Date

    public init(currentValue: Double, baselineValues: [Double], observedAt: Date) {
        self.currentValue = currentValue
        self.baselineValues = baselineValues
        self.observedAt = observedAt
    }
}

public struct PhysiologicalReadinessSnapshot: Sendable, Equatable {
    public let sleepHours: ReadinessMetricSnapshot?
    public let hrvMilliseconds: ReadinessMetricSnapshot?
    public let restingHeartRateBPM: ReadinessMetricSnapshot?

    public init(
        sleepHours: ReadinessMetricSnapshot? = nil,
        hrvMilliseconds: ReadinessMetricSnapshot? = nil,
        restingHeartRateBPM: ReadinessMetricSnapshot? = nil
    ) {
        self.sleepHours = sleepHours
        self.hrvMilliseconds = hrvMilliseconds
        self.restingHeartRateBPM = restingHeartRateBPM
    }

    public static let empty = Self()
}

public struct SubjectiveReadinessSnapshot: Sendable, Equatable {
    public let energy: Int?
    public let fatigue: Int?
    public let soreness: Int?
    public let stress: Int?
    public let perceivedReadiness: Int?
    public let cramps: Int?

    public init(
        energy: Int? = nil,
        fatigue: Int? = nil,
        soreness: Int? = nil,
        stress: Int? = nil,
        perceivedReadiness: Int? = nil,
        cramps: Int? = nil
    ) {
        self.energy = energy
        self.fatigue = fatigue
        self.soreness = soreness
        self.stress = stress
        self.perceivedReadiness = perceivedReadiness
        self.cramps = cramps
    }

    public static let empty = Self()
}

public struct TrainingReadinessSnapshot: Sendable, Equatable {
    public let weeklyLoadRatio: Double?
    public let averageSessionRPE: Double?
    public let rightForTodayRate: Double?
    public let completedWorkoutsInLast28Days: Int

    public init(
        weeklyLoadRatio: Double? = nil,
        averageSessionRPE: Double? = nil,
        rightForTodayRate: Double? = nil,
        completedWorkoutsInLast28Days: Int = 0
    ) {
        self.weeklyLoadRatio = weeklyLoadRatio
        self.averageSessionRPE = averageSessionRPE
        self.rightForTodayRate = rightForTodayRate
        self.completedWorkoutsInLast28Days = completedWorkoutsInLast28Days
    }

    public static let empty = Self()
}

public struct PainReadinessSnapshot: Sendable, Equatable {
    public let intensity: Int
    public let painType: PainType
    public let locationIDs: [String]
    public let observedAt: Date

    public init(intensity: Int, painType: PainType, locationIDs: [String], observedAt: Date) {
        self.intensity = intensity
        self.painType = painType
        self.locationIDs = locationIDs
        self.observedAt = observedAt
    }
}

public struct DailyTrainingContext: Sendable, Equatable {
    public let assessmentDate: Date
    public let timeZoneIdentifier: String
    public let physiological: PhysiologicalReadinessSnapshot
    public let subjective: SubjectiveReadinessSnapshot
    public let training: TrainingReadinessSnapshot
    public let pain: PainReadinessSnapshot?
    public let cyclePhase: CyclePhase?
    public let cycleConfidence: Double?

    public init(
        assessmentDate: Date,
        timeZoneIdentifier: String,
        physiological: PhysiologicalReadinessSnapshot,
        subjective: SubjectiveReadinessSnapshot,
        training: TrainingReadinessSnapshot,
        pain: PainReadinessSnapshot?,
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?
    ) {
        self.assessmentDate = assessmentDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.physiological = physiological
        self.subjective = subjective
        self.training = training
        self.pain = pain
        self.cyclePhase = cyclePhase
        self.cycleConfidence = cycleConfidence
    }
}

public struct ReadinessAssessment: Sendable, Equatable {
    public let assessmentDate: Date
    public let state: ReadinessState
    public let totalScore: Int
    public let confidence: ReadinessConfidence
    public let subScores: [ReadinessScoreGroup: Int]
    public let availableSignals: [ReadinessSignalID]
    public let missingSignals: [ReadinessSignalID]
    public let staleSignals: [ReadinessSignalID]
    public let positiveReasons: [ReadinessReasonCode]
    public let cautionReasons: [ReadinessReasonCode]
    public let modelVersion: String

    public init(
        assessmentDate: Date,
        state: ReadinessState,
        totalScore: Int,
        confidence: ReadinessConfidence,
        subScores: [ReadinessScoreGroup: Int],
        availableSignals: [ReadinessSignalID],
        missingSignals: [ReadinessSignalID],
        staleSignals: [ReadinessSignalID],
        positiveReasons: [ReadinessReasonCode],
        cautionReasons: [ReadinessReasonCode],
        modelVersion: String
    ) {
        self.assessmentDate = assessmentDate
        self.state = state
        self.totalScore = totalScore
        self.confidence = confidence
        self.subScores = subScores
        self.availableSignals = availableSignals
        self.missingSignals = missingSignals
        self.staleSignals = staleSignals
        self.positiveReasons = positiveReasons
        self.cautionReasons = cautionReasons
        self.modelVersion = modelVersion
    }
}
```

- [ ] **Step 4: Run the model tests**

Run: `cd SundeeFundee && swift test --filter ReadinessModelsTests`

Expected: PASS with 3 tests.

- [ ] **Step 5: Commit the domain contract**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessModels.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessModelsTests.swift
git commit -m "feat(readiness): define assessment domain contract"
```

---

### Task 2: Implement personal-baseline normalization

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessBaselineNormalizer.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessBaselineNormalizerTests.swift`

**Interfaces:**
- Consumes: `ReadinessMetricSnapshot` from Task 1.
- Produces: `ReadinessMetricDirection` and `ReadinessBaselineNormalizer.personalScore`, `sleepScore`, `median`, and `mean`.

- [ ] **Step 1: Write failing normalization tests**

```swift
import XCTest
@testable import SundeeFundeeKit

final class ReadinessBaselineNormalizerTests: XCTestCase {
    func testPersonalBaselineRequiresFourteenObservations() {
        let metric = ReadinessMetricSnapshot(currentValue: 50, baselineValues: Array(repeating: 50, count: 13), observedAt: Date())
        XCTAssertNil(ReadinessBaselineNormalizer.personalScore(metric, direction: .higherIsBetter))
    }

    func testBaselineMapsToSeventyFiveAndDirectionChangesDelta() {
        let history = Array(repeating: 50.0, count: 14)
        let atBaseline = ReadinessMetricSnapshot(currentValue: 50, baselineValues: history, observedAt: Date())
        let above = ReadinessMetricSnapshot(currentValue: 55, baselineValues: history, observedAt: Date())

        XCTAssertEqual(ReadinessBaselineNormalizer.personalScore(atBaseline, direction: .higherIsBetter), 75)
        XCTAssertGreaterThan(
            ReadinessBaselineNormalizer.personalScore(above, direction: .higherIsBetter)!,
            ReadinessBaselineNormalizer.personalScore(above, direction: .lowerIsBetter)!
        )
    }

    func testSleepHasAnAbsoluteFallbackWhileLearning() {
        XCTAssertEqual(ReadinessBaselineNormalizer.sleepScore(hours: 8.0, history: []), 90)
        XCTAssertEqual(ReadinessBaselineNormalizer.sleepScore(hours: 5.0, history: []), 40)
    }
}
```

- [ ] **Step 2: Verify the normalizer tests fail**

Run: `cd SundeeFundee && swift test --filter ReadinessBaselineNormalizerTests`

Expected: FAIL with `cannot find 'ReadinessBaselineNormalizer' in scope`.

- [ ] **Step 3: Implement the deterministic normalizer**

```swift
import Foundation

public enum ReadinessMetricDirection: Sendable, Equatable {
    case higherIsBetter
    case lowerIsBetter
}

public enum ReadinessBaselineNormalizer {
    public static let minimumPersonalObservations = 14

    public static func personalScore(
        _ metric: ReadinessMetricSnapshot,
        direction: ReadinessMetricDirection
    ) -> Int? {
        guard metric.baselineValues.count >= minimumPersonalObservations,
              let baseline = median(metric.baselineValues),
              baseline > 0 else { return nil }

        let delta = (metric.currentValue - baseline) / baseline
        let signedDelta = direction == .higherIsBetter ? delta : -delta
        return clamp(Int((75 + signedDelta * 250).rounded()))
    }

    public static func sleepScore(hours: Double, history: [Double]) -> Int {
        let metric = ReadinessMetricSnapshot(currentValue: hours, baselineValues: history, observedAt: Date())
        if let personal = personalScore(metric, direction: .higherIsBetter) {
            return personal
        }
        switch hours {
        case 9...: 100
        case 8..<9: 90
        case 7..<8: 75
        case 6..<7: 60
        case 5..<6: 40
        default: 20
        }
    }

    public static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]
    }

    public static func mean(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    public static func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
```

- [ ] **Step 4: Run both readiness test classes**

Run: `cd SundeeFundee && swift test --filter Readiness`

Expected: PASS for `ReadinessModelsTests` and `ReadinessBaselineNormalizerTests`.

- [ ] **Step 5: Commit the normalizer**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessBaselineNormalizer.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessBaselineNormalizerTests.swift
git commit -m "feat(readiness): normalize personal baselines"
```

---

### Task 3: Calculate score groups, confidence, state, and reasons

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessAssessmentService.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessAssessmentServiceTests.swift`

**Interfaces:**
- Consumes: `DailyTrainingContext` and `ReadinessBaselineNormalizer`.
- Produces: `ReadinessAssessmentService.assess(_:) -> ReadinessAssessment?` with model version `readiness-v1`.

- [ ] **Step 1: Write failing assessment tests**

```swift
import XCTest
@testable import SundeeFundeeKit

final class ReadinessAssessmentServiceTests: XCTestCase {
    func testAllMissingInputsReturnNil() {
        XCTAssertNil(ReadinessAssessmentService.assess(makeContext()))
    }

    func testCyclePhaseDoesNotChangeScore() throws {
        let base = makeContext(subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2, soreness: 2))
        let follicular = makeContext(subjective: base.subjective, cyclePhase: .follicular)
        let luteal = makeContext(subjective: base.subjective, cyclePhase: .luteal)

        XCTAssertEqual(try XCTUnwrap(ReadinessAssessmentService.assess(follicular)).totalScore,
                       try XCTUnwrap(ReadinessAssessmentService.assess(luteal)).totalScore)
    }

    func testHighPainCapsReadyScoreAtRecover() throws {
        let context = makeContext(
            subjective: SubjectiveReadinessSnapshot(energy: 10, fatigue: 0, soreness: 0, stress: 0, perceivedReadiness: 10),
            pain: PainReadinessSnapshot(intensity: 8, painType: .sharp, locationIDs: ["knee"], observedAt: Date())
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.state, .recover)
        XCTAssertTrue(result.cautionReasons.contains(.highPain))
    }

    private func makeContext(
        subjective: SubjectiveReadinessSnapshot = .empty,
        pain: PainReadinessSnapshot? = nil,
        cyclePhase: CyclePhase? = nil
    ) -> DailyTrainingContext {
        DailyTrainingContext(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000),
            timeZoneIdentifier: "America/New_York",
            physiological: .empty,
            subjective: subjective,
            training: .empty,
            pain: pain,
            cyclePhase: cyclePhase,
            cycleConfidence: cyclePhase == nil ? nil : 0.8
        )
    }
}
```

- [ ] **Step 2: Verify assessment tests fail**

Run: `cd SundeeFundee && swift test --filter ReadinessAssessmentServiceTests`

Expected: FAIL with `cannot find 'ReadinessAssessmentService' in scope`.

- [ ] **Step 3: Implement the assessment service**

Create an enum with the following public entry point and private scoring rules:

```swift
import Foundation

public enum ReadinessAssessmentService {
    public static let modelVersion = "readiness-v1"

    public static func assess(_ context: DailyTrainingContext) -> ReadinessAssessment? {
        let physiological = physiologicalScore(context.physiological)
        let subjective = subjectiveScore(context.subjective)
        let training = trainingScore(context.training)
        let symptomsAndPain = symptomsAndPainScore(context.subjective, pain: context.pain)

        let groups: [(ReadinessScoreGroup, Int?)] = [
            (.physiological, physiological),
            (.subjective, subjective),
            (.training, training),
            (.symptomsAndPain, symptomsAndPain)
        ]
        let present = groups.compactMap { group, score in score.map { (group, $0) } }
        guard !present.isEmpty else { return nil }

        let presentWeight = present.reduce(0.0) { $0 + $1.0.weight }
        let weighted = present.reduce(0.0) { $0 + Double($1.1) * $1.0.weight }
        let total = ReadinessBaselineNormalizer.clamp(Int((weighted / presentWeight).rounded()))
        let signalState = ReadinessState.from(score: total)
        let painCap: ReadinessState = (context.pain?.intensity ?? 0) >= 7 ? .recover : .ready
        let confidence = confidence(for: context)
        let confidenceAdjusted: ReadinessState = confidence == .low ? .maintain : signalState
        let state = ReadinessState.stricter(confidenceAdjusted, painCap)
        let signals = signalAvailability(context)
        let reasons = reasonCodes(context)

        return ReadinessAssessment(
            assessmentDate: context.assessmentDate,
            state: state,
            totalScore: total,
            confidence: confidence,
            subScores: Dictionary(uniqueKeysWithValues: present),
            availableSignals: signals.available,
            missingSignals: signals.missing,
            staleSignals: signals.stale,
            positiveReasons: reasons.positive,
            cautionReasons: reasons.caution,
            modelVersion: modelVersion
        )
    }

    private static func physiologicalScore(_ value: PhysiologicalReadinessSnapshot) -> Int? {
        var scores: [Int] = []
        if let sleep = value.sleepHours {
            scores.append(ReadinessBaselineNormalizer.sleepScore(hours: sleep.currentValue, history: sleep.baselineValues))
        }
        if let hrv = value.hrvMilliseconds,
           let score = ReadinessBaselineNormalizer.personalScore(hrv, direction: .higherIsBetter) {
            scores.append(score)
        }
        if let rhr = value.restingHeartRateBPM,
           let score = ReadinessBaselineNormalizer.personalScore(rhr, direction: .lowerIsBetter) {
            scores.append(score)
        }
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func subjectiveScore(_ value: SubjectiveReadinessSnapshot) -> Int? {
        let scores = [
            value.energy.map { $0 * 10 },
            value.fatigue.map { (10 - $0) * 10 },
            value.soreness.map { (10 - $0) * 10 },
            value.stress.map { (10 - $0) * 10 },
            value.perceivedReadiness.map { $0 * 10 }
        ].compactMap { $0 }.map(ReadinessBaselineNormalizer.clamp)
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func trainingScore(_ value: TrainingReadinessSnapshot) -> Int? {
        var scores: [Int] = []
        if let ratio = value.weeklyLoadRatio {
            let score = ratio <= 1.0 ? 80 : ratio < 1.5 ? Int((80 - (ratio - 1.0) * 100).rounded()) : 20
            scores.append(ReadinessBaselineNormalizer.clamp(score))
        }
        if let rpe = value.averageSessionRPE {
            scores.append(ReadinessBaselineNormalizer.clamp(Int((100 - max(0, rpe - 5) * 15).rounded())))
        }
        if let rate = value.rightForTodayRate {
            scores.append(ReadinessBaselineNormalizer.clamp(Int((rate * 100).rounded())))
        }
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func symptomsAndPainScore(
        _ subjective: SubjectiveReadinessSnapshot,
        pain: PainReadinessSnapshot?
    ) -> Int? {
        let scores = [
            subjective.cramps.map { (10 - $0) * 10 },
            pain.map { (10 - $0.intensity) * 10 }
        ].compactMap { $0 }.map(ReadinessBaselineNormalizer.clamp)
        return ReadinessBaselineNormalizer.mean(scores)
    }
}
```

In the same file, add private `confidence(for:)`, `signalAvailability(_:)`, and `reasonCodes(_:)` helpers with these exact rules:

```swift
private extension ReadinessAssessmentService {
    static func confidence(for context: DailyTrainingContext) -> ReadinessConfidence {
        let physiologicalCount = [context.physiological.sleepHours, context.physiological.hrvMilliseconds,
                                  context.physiological.restingHeartRateBPM].compactMap { $0 }.count
        let subjectiveCount = [context.subjective.energy, context.subjective.fatigue, context.subjective.soreness,
                               context.subjective.stress, context.subjective.perceivedReadiness].compactMap { $0 }.count
        let trainingCount = [context.training.weeklyLoadRatio, context.training.averageSessionRPE,
                             context.training.rightForTodayRate].compactMap { $0 }.count
        let symptomsCount = [context.subjective.cramps, context.pain?.intensity].compactMap { $0 }.count
        let coverage = 0.30 * Double(physiologicalCount) / 3.0
            + 0.30 * Double(subjectiveCount) / 5.0
            + 0.25 * Double(trainingCount) / 3.0
            + 0.15 * Double(symptomsCount) / 2.0
        let learning = [context.physiological.sleepHours, context.physiological.hrvMilliseconds,
                        context.physiological.restingHeartRateBPM]
            .compactMap { $0 }
            .contains { $0.baselineValues.count < ReadinessBaselineNormalizer.minimumPersonalObservations }

        if coverage >= 0.75 && physiologicalCount > 0 && subjectiveCount > 0 && !learning { return .high }
        if coverage >= 0.45 && physiologicalCount > 0 && subjectiveCount > 0 { return .medium }
        return .low
    }

    static func signalAvailability(_ context: DailyTrainingContext) -> (
        available: [ReadinessSignalID], missing: [ReadinessSignalID], stale: [ReadinessSignalID]
    ) {
        let pairs: [(ReadinessSignalID, Bool)] = [
            (.sleep, context.physiological.sleepHours != nil), (.hrv, context.physiological.hrvMilliseconds != nil),
            (.restingHeartRate, context.physiological.restingHeartRateBPM != nil),
            (.energy, context.subjective.energy != nil), (.fatigue, context.subjective.fatigue != nil),
            (.stress, context.subjective.stress != nil), (.soreness, context.subjective.soreness != nil),
            (.perceivedReadiness, context.subjective.perceivedReadiness != nil),
            (.trainingLoad, context.training.weeklyLoadRatio != nil), (.sessionRPE, context.training.averageSessionRPE != nil),
            (.rightForToday, context.training.rightForTodayRate != nil), (.cramps, context.subjective.cramps != nil),
            (.pain, context.pain != nil)
        ]
        let available = pairs.filter { $0.1 }.map { $0.0 }
        let missing = pairs.filter { !$0.1 }.map(\.0)
        let stale = physiologicalSignals(context).filter {
            context.assessmentDate.timeIntervalSince($0.1) > 48 * 60 * 60
        }.map(\.0)
        return (available.sorted { $0.rawValue < $1.rawValue },
                missing.sorted { $0.rawValue < $1.rawValue },
                stale.sorted { $0.rawValue < $1.rawValue })
    }

    static func physiologicalSignals(_ context: DailyTrainingContext) -> [(ReadinessSignalID, Date)] {
        [(.sleep, context.physiological.sleepHours?.observedAt),
         (.hrv, context.physiological.hrvMilliseconds?.observedAt),
         (.restingHeartRate, context.physiological.restingHeartRateBPM?.observedAt)]
            .compactMap { id, date in date.map { (id, $0) } }
    }

    static func reasonCodes(_ context: DailyTrainingContext) -> (
        positive: [ReadinessReasonCode], caution: [ReadinessReasonCode]
    ) {
        var positive: [ReadinessReasonCode] = []
        var caution: [ReadinessReasonCode] = []
        if let sleep = context.physiological.sleepHours {
            let score = ReadinessBaselineNormalizer.sleepScore(hours: sleep.currentValue, history: sleep.baselineValues)
            if score >= 75 { positive.append(.goodSleep) }
            if score < 60 { caution.append(.sleepBelowBaseline) }
        }
        if let hrv = context.physiological.hrvMilliseconds,
           let score = ReadinessBaselineNormalizer.personalScore(hrv, direction: .higherIsBetter) {
            if score >= 75 { positive.append(.hrvAtOrAboveBaseline) }
            if score < 60 { caution.append(.hrvBelowBaseline) }
        }
        if let rhr = context.physiological.restingHeartRateBPM,
           let score = ReadinessBaselineNormalizer.personalScore(rhr, direction: .lowerIsBetter) {
            if score >= 75 { positive.append(.restingHeartRateNormal) }
            if score < 60 { caution.append(.restingHeartRateElevated) }
        }
        if let energy = context.subjective.energy, energy <= 3 { caution.append(.lowEnergy) }
        if let energy = context.subjective.energy, energy >= 7 { positive.append(.highEnergy) }
        if let fatigue = context.subjective.fatigue, fatigue >= 7 { caution.append(.highFatigue) }
        if let stress = context.subjective.stress, stress >= 7 { caution.append(.highStress) }
        if let soreness = context.subjective.soreness, soreness >= 7 { caution.append(.highSoreness) }
        if let ratio = context.training.weeklyLoadRatio, (0.8...1.2).contains(ratio) {
            positive.append(.balancedTrainingLoad)
        }
        if let ratio = context.training.weeklyLoadRatio, ratio >= 1.3 { caution.append(.highTrainingLoad) }
        if let pain = context.pain, pain.intensity >= 7 { caution.append(.highPain) }
        let availability = signalAvailability(context)
        if !availability.missing.isEmpty { caution.append(.missingSignals) }
        if confidence(for: context) != .high { caution.append(.stillLearning) }
        return (Array(Set(positive)).sorted { $0.rawValue < $1.rawValue },
                Array(Set(caution)).sorted { $0.rawValue < $1.rawValue })
    }
}
```

- [ ] **Step 4: Run the assessment tests**

Run: `cd SundeeFundee && swift test --filter ReadinessAssessmentServiceTests`

Expected: PASS with 3 tests.

- [ ] **Step 5: Commit the assessment service**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessAssessmentService.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessAssessmentServiceTests.swift
git commit -m "feat(readiness): calculate explainable assessments"
```

---

### Task 4: Lock the safety and missing-data invariants

**Files:**
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessScenarioTests.swift`

**Interfaces:**
- Consumes: `ReadinessAssessmentService.assess(_:)`.
- Produces: A permanent regression suite for the approved score and confidence contract.

- [ ] **Step 1: Add the scenario matrix**

```swift
import XCTest
@testable import SundeeFundeeKit

final class ReadinessScenarioTests: XCTestCase {
    func testMissingHRVDoesNotReduceTheSameKnownInputs() throws {
        let known = makeContext(hrv: nil)
        let scoreWithoutHRV = try XCTUnwrap(ReadinessAssessmentService.assess(known)).totalScore
        let ineligibleHRV = makeContext(hrv: metric(55, history: Array(repeating: 50, count: 13)))
        let scoreWithIneligibleHRV = try XCTUnwrap(ReadinessAssessmentService.assess(ineligibleHRV)).totalScore
        XCTAssertEqual(scoreWithoutHRV, scoreWithIneligibleHRV)
    }

    func testCyclePhaseOnlyCannotCreateAnAssessment() {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: .empty, training: .empty, pain: nil,
            cyclePhase: .menstrual, cycleConfidence: 1
        )
        XCTAssertNil(ReadinessAssessmentService.assess(context))
    }

    func testLowConfidenceCapsAnOtherwiseReadyAssessmentAtMaintain() throws {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: SubjectiveReadinessSnapshot(energy: 10, fatigue: 0),
            training: .empty, pain: nil, cyclePhase: nil, cycleConfidence: nil
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.state, .maintain)
    }

    func testLowConfidenceCannotCreateScoreOnlyRest() throws {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: SubjectiveReadinessSnapshot(energy: 0, fatigue: 10),
            training: .empty, pain: nil, cyclePhase: nil, cycleConfidence: nil
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.state, .maintain)
    }

    func testScoreAndReasonsAreDeterministic() {
        let first = ReadinessAssessmentService.assess(makeContext(hrv: metric(55, history: Array(repeating: 50, count: 14))))
        let second = ReadinessAssessmentService.assess(makeContext(hrv: metric(55, history: Array(repeating: 50, count: 14))))
        XCTAssertEqual(first, second)
    }

    private func makeContext(hrv: ReadinessMetricSnapshot?) -> DailyTrainingContext {
        DailyTrainingContext(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: "UTC",
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: metric(8, history: Array(repeating: 7.5, count: 14)),
                hrvMilliseconds: hrv,
                restingHeartRateBPM: metric(58, history: Array(repeating: 60, count: 14))
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2, soreness: 2, stress: 2, perceivedReadiness: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1, averageSessionRPE: 7, rightForTodayRate: 0.9, completedWorkoutsInLast28Days: 8),
            pain: nil, cyclePhase: .luteal, cycleConfidence: 0.8
        )
    }

    private func metric(_ current: Double, history: [Double]) -> ReadinessMetricSnapshot {
        ReadinessMetricSnapshot(currentValue: current, baselineValues: history, observedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
}
```

- [ ] **Step 2: Run the scenario matrix**

Run: `cd SundeeFundee && swift test --filter ReadinessScenarioTests`

Expected: PASS with 5 tests. If a test fails, change the service rather than weakening the invariant.

- [ ] **Step 3: Run all readiness-domain tests together**

Run: `cd SundeeFundee && swift test --filter Readiness`

Expected: PASS with the model, normalizer, assessment, and scenario suites.

- [ ] **Step 4: Commit the invariant suite**

```bash
git add SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessScenarioTests.swift
git commit -m "test(readiness): lock scoring invariants"
```

---

### Task 5: Add the versioned derived record

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/Models/DailyReadinessRecord.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessRecordTests.swift`

**Interfaces:**
- Consumes: `ReadinessAssessment`.
- Produces: `DailyReadinessRecord.recordType`, `init(assessment:timeZone:createdAt:updatedAt:)`, and `assessment()`.

- [ ] **Step 1: Write failing round-trip and stable-ID tests**

```swift
import XCTest
@testable import SundeeFundeeKit

final class DailyReadinessRecordTests: XCTestCase {
    func testStableIDUsesLocalDayAndNotUserIdentity() {
        let zone = TimeZone(identifier: "America/New_York")!
        let record = DailyReadinessRecord(
            assessment: makeAssessment(), timeZone: zone,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        XCTAssertEqual(record.id, "readiness-2023-11-14")
        XCTAssertEqual(record.timeZoneIdentifier, "America/New_York")
    }

    func testJSONRoundTripPreservesAssessment() throws {
        let original = DailyReadinessRecord(assessment: makeAssessment(), timeZone: .gmt)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyReadinessRecord.self, from: encoder.encode(original))
        XCTAssertEqual(try decoded.assessment(), makeAssessment())
    }

    func testLocalClientReplacesTheSameLocalDay() async throws {
        let suiteName = "ReadinessRecordTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let client = LocalDataClient(userDefaults: defaults)
        try await client.save(
            DailyReadinessRecord(assessment: makeAssessment(score: 72), timeZone: .gmt),
            recordType: DailyReadinessRecord.recordType
        )
        try await client.save(
            DailyReadinessRecord(assessment: makeAssessment(score: 68), timeZone: .gmt),
            recordType: DailyReadinessRecord.recordType
        )

        let records: [DailyReadinessRecord] = try await client.fetchAll(
            recordType: DailyReadinessRecord.recordType
        )
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.totalScore, 68)
    }

    private func makeAssessment(score: Int = 72) -> ReadinessAssessment {
        ReadinessAssessment(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), state: .maintain,
            totalScore: score, confidence: .medium,
            subScores: [.physiological: 80, .subjective: 65],
            availableSignals: [.sleep, .energy], missingSignals: [.hrv], staleSignals: [],
            positiveReasons: [], cautionReasons: [.stillLearning], modelVersion: "readiness-v1"
        )
    }
}
```

- [ ] **Step 2: Verify record tests fail**

Run: `cd SundeeFundee && swift test --filter DailyReadinessRecordTests`

Expected: FAIL with `cannot find 'DailyReadinessRecord' in scope`.

- [ ] **Step 3: Implement the record and mapping**

```swift
import Foundation

public struct DailyReadinessRecord: Codable, Sendable, Identifiable, Equatable {
    public static let recordType = "DailyReadinessRecord"

    public let id: String
    public let dayKey: String
    public let timeZoneIdentifier: String
    public let assessmentDate: String
    public let dateCreated: String
    public let dateUpdated: String
    public let stateRaw: String
    public let totalScore: Int
    public let confidenceRaw: String
    public let modelVersion: String
    public let physiologicalScore: Int?
    public let subjectiveScore: Int?
    public let trainingScore: Int?
    public let symptomsPainScore: Int?
    public let availableSignalIDs: [String]
    public let missingSignalIDs: [String]
    public let staleSignalIDs: [String]
    public let positiveReasonIDs: [String]
    public let cautionReasonIDs: [String]

    public init(
        assessment: ReadinessAssessment,
        timeZone: TimeZone,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let dayKey = Self.dayKey(for: assessment.assessmentDate, timeZone: timeZone)
        let formatter = ISO8601DateFormatter()
        self.id = "readiness-\(dayKey)"
        self.dayKey = dayKey
        self.timeZoneIdentifier = timeZone.identifier
        self.assessmentDate = formatter.string(from: assessment.assessmentDate)
        self.dateCreated = formatter.string(from: createdAt)
        self.dateUpdated = formatter.string(from: updatedAt)
        self.stateRaw = assessment.state.rawValue
        self.totalScore = assessment.totalScore
        self.confidenceRaw = assessment.confidence.rawValue
        self.modelVersion = assessment.modelVersion
        self.physiologicalScore = assessment.subScores[.physiological]
        self.subjectiveScore = assessment.subScores[.subjective]
        self.trainingScore = assessment.subScores[.training]
        self.symptomsPainScore = assessment.subScores[.symptomsAndPain]
        self.availableSignalIDs = assessment.availableSignals.map(\.rawValue)
        self.missingSignalIDs = assessment.missingSignals.map(\.rawValue)
        self.staleSignalIDs = assessment.staleSignals.map(\.rawValue)
        self.positiveReasonIDs = assessment.positiveReasons.map(\.rawValue)
        self.cautionReasonIDs = assessment.cautionReasons.map(\.rawValue)
    }

    public func assessment() throws -> ReadinessAssessment {
        guard let date = ISO8601DateFormatter().date(from: assessmentDate),
              let state = ReadinessState(rawValue: stateRaw),
              let confidence = ReadinessConfidence(rawValue: confidenceRaw) else {
            throw DataError.invalidData(description: "DailyReadinessRecord contains invalid enum or date values")
        }
        let scores: [(ReadinessScoreGroup, Int?)] = [
            (.physiological, physiologicalScore), (.subjective, subjectiveScore),
            (.training, trainingScore), (.symptomsAndPain, symptomsPainScore)
        ]
        return ReadinessAssessment(
            assessmentDate: date, state: state, totalScore: totalScore, confidence: confidence,
            subScores: Dictionary(uniqueKeysWithValues: scores.compactMap { group, score in score.map { (group, $0) } }),
            availableSignals: availableSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            missingSignals: missingSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            staleSignals: staleSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            positiveReasons: positiveReasonIDs.compactMap(ReadinessReasonCode.init(rawValue:)),
            cautionReasons: cautionReasonIDs.compactMap(ReadinessReasonCode.init(rawValue:)),
            modelVersion: modelVersion
        )
    }

    private static func dayKey(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
```

- [ ] **Step 4: Verify LocalDataClient replacement semantics**

Run the three tests, including `testLocalClientReplacesTheSameLocalDay` from Step 1:

```bash
cd SundeeFundee
swift test --filter DailyReadinessRecordTests
```

Expected: PASS with 3 tests.

- [ ] **Step 5: Commit the record**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/Models/DailyReadinessRecord.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessRecordTests.swift
git commit -m "feat(readiness): persist versioned daily assessments"
```

---

### Task 6: Translate HealthKit samples into physiological snapshots

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HealthReadinessProvider.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HealthReadinessProviderTests.swift`

**Interfaces:**
- Consumes: `HealthClientProtocol`, `SleepDeduplicator`, and HealthKit samples.
- Produces: `HealthReadinessProviding.load(assessmentDate:calendar:) async -> PhysiologicalReadinessSnapshot`.

- [ ] **Step 1: Write failing provider tests using `MockHealthKitClient` factories**

```swift
import XCTest
@testable import SundeeFundeeKit

final class HealthReadinessProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFifteenDailyHRVSamplesProduceCurrentPlusFourteenBaselineDays() async throws {
        let client = MockHealthKitClient()
        let calendar = utcCalendar()
        let dates = (0..<15).map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        client.setMockHeartRateVariability(dates.compactMap {
            MockHealthKitClient.createMockHeartRateVariability(date: $0, milliseconds: 50)
        })
        let result = await HealthReadinessProvider(healthClient: client).load(assessmentDate: now, calendar: calendar)
        XCTAssertEqual(result.hrvMilliseconds?.currentValue, 50)
        XCTAssertEqual(result.hrvMilliseconds?.baselineValues.count, 14)
    }

    func testRestingHeartRateUsesBeatsPerMinute() async throws {
        let client = MockHealthKitClient()
        client.setMockRestingHeartRate([
            try XCTUnwrap(MockHealthKitClient.createMockRestingHeartRate(date: now, beatsPerMinute: 61))
        ])
        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertEqual(result.restingHeartRateBPM?.currentValue, 61)
    }

    func testOverlappingSleepSamplesAreCountedOnce() async throws {
        let client = MockHealthKitClient()
        let eightHoursAgo = now.addingTimeInterval(-8 * 3600)
        let sevenHoursAgo = now.addingTimeInterval(-7 * 3600)
        client.setMockSleepAnalysis([
            try XCTUnwrap(MockHealthKitClient.createMockSleepSample(startDate: eightHoursAgo, endDate: now)),
            try XCTUnwrap(MockHealthKitClient.createMockSleepSample(startDate: sevenHoursAgo, endDate: now))
        ])
        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertEqual(result.sleepHours?.currentValue, 8, accuracy: 0.001)
    }

    func testQueryFailureReturnsEmptySnapshot() async {
        let client = MockHealthKitClient()
        client.shouldFailQueries = true
        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertEqual(result, .empty)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
```

- [ ] **Step 2: Run the provider tests and confirm failure**

Run: `cd SundeeFundee && swift test --filter HealthReadinessProviderTests`

Expected: FAIL with `cannot find 'HealthReadinessProvider' in scope`.

- [ ] **Step 3: Implement the provider with concurrent HealthKit reads**

```swift
import Foundation
import HealthKit

public protocol HealthReadinessProviding: Sendable {
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot
}

public actor HealthReadinessProvider: HealthReadinessProviding {
    private let healthClient: HealthClientProtocol

    public init(healthClient: HealthClientProtocol = HealthClientFactory.shared.client) {
        self.healthClient = healthClient
    }

    public func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot {
        guard healthClient.isAvailable else { return .empty }
        let start = calendar.date(byAdding: .day, value: -29, to: assessmentDate) ?? assessmentDate
        async let hrv = try? healthClient.fetchHeartRateVariability(startDate: start, endDate: assessmentDate)
        async let rhr = try? healthClient.fetchRestingHeartRate(startDate: start, endDate: assessmentDate)
        async let sleep = try? healthClient.fetchSleepAnalysis(startDate: start, endDate: assessmentDate)
        let (hrvSamples, rhrSamples, sleepSamples) = await (hrv ?? [], rhr ?? [], sleep ?? [])
        return PhysiologicalReadinessSnapshot(
            sleepHours: sleepSnapshot(sleepSamples, calendar: calendar),
            hrvMilliseconds: quantitySnapshot(
                hrvSamples, unit: .secondUnit(with: .milli), calendar: calendar
            ),
            restingHeartRateBPM: quantitySnapshot(
                rhrSamples, unit: .count().unitDivided(by: .minute()), calendar: calendar
            )
        )
    }

    private func quantitySnapshot(
        _ samples: [HKQuantitySample], unit: HKUnit, calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let daily = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            .map { day, values in
                (day, ReadinessBaselineNormalizer.median(values.map { $0.quantity.doubleValue(for: unit) }) ?? 0)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.0 > $1.0 }
        guard let current = daily.first else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.dropFirst().prefix(28).map(\.1)),
            observedAt: current.0
        )
    }

    private func sleepSnapshot(
        _ samples: [HKCategorySample], calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let daily = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            .map { day, values -> (Date, Double) in
                let raw = values.map {
                    SleepDeduplicator.SleepSampleValue(
                        start: $0.startDate, end: $0.endDate,
                        value: $0.value, sourceName: $0.sourceRevision.source.name
                    )
                }
                let seconds = SleepDeduplicator.deduplicate(SleepDeduplicator.convertSamples(values: raw))
                return (day, seconds / 3600)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.0 > $1.0 }
        guard let current = daily.first else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.dropFirst().prefix(28).map(\.1)),
            observedAt: current.0
        )
    }
}
```

- [ ] **Step 4: Run the Health readiness tests**

Run: `cd SundeeFundee && swift test --filter HealthReadinessProviderTests`

Expected: PASS for HRV, resting heart rate, sleep deduplication, and failure fallback.

- [ ] **Step 5: Commit the provider**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HealthReadinessProvider.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HealthReadinessProviderTests.swift
git commit -m "feat(readiness): summarize HealthKit signals"
```

---

### Task 7: Translate existing records into subjective and training snapshots

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HistoryReadinessProvider.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HistoryReadinessProviderTests.swift`

**Interfaces:**
- Consumes: `DataClientProtocol`, `SymptomCheckInRecord`, `DailyPainLog`, `CompletedWorkoutRecord`, `Workout`, and `WorkoutCompletionCheckInRecord`.
- Produces: `HistoryReadinessSnapshot` and `HistoryReadinessProviding.load(assessmentDate:calendar:)`.

- [ ] **Step 1: Write failing history-provider tests**

```swift
import XCTest
@testable import SundeeFundeeKit

final class HistoryReadinessProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testNewestSameDaySymptomsAndPainWin() async throws {
        let client = MockCloudKitClient()
        try await client.save([
            SymptomCheckInRecord(symptomDate: now, cramps: 1, fatigue: 3, soreness: 2, energy: 7,
                                 dateCreated: now.addingTimeInterval(-60)),
            SymptomCheckInRecord(symptomDate: now, cramps: 2, fatigue: 6, soreness: 5, energy: 4,
                                 dateCreated: now)
        ], recordType: "SymptomCheckInRecord")
        try await client.save(
            DailyPainLog(id: "pain", locationIds: "knee", intensity: 7, painType: .sharp, date: now),
            recordType: "DailyPainLog"
        )

        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertEqual(result.subjective.energy, 4)
        XCTAssertEqual(result.subjective.fatigue, 6)
        XCTAssertEqual(result.pain?.intensity, 7)
        XCTAssertEqual(result.pain?.locationIDs, ["knee"])
    }

    func testLoadRatioAndFourNewestCompletionCheckInsAreAggregated() async throws {
        let client = MockCloudKitClient()
        let calendar = utcCalendar()
        let workouts = [1, 3, 8, 12, 18].enumerated().map { index, days in
            CompletedWorkoutRecord(
                id: "w\(index)", name: "Workout", date: calendar.date(byAdding: .day, value: -days, to: now)!,
                duration: 30, exerciseNames: ["Squat"], isComplete: true
            )
        }
        try await client.save(workouts, recordType: "CompletedWorkoutRecord")
        let checkIns = [
            WorkoutCompletionCheckInRecord(id: "c1", workoutID: "w1", sessionRPE: 6, soreness: 2, pain: 0,
                                           wasRightForToday: true, dateCreated: now),
            WorkoutCompletionCheckInRecord(id: "c2", workoutID: "w2", sessionRPE: 8, soreness: 3, pain: 0,
                                           wasRightForToday: true, dateCreated: now.addingTimeInterval(-1)),
            WorkoutCompletionCheckInRecord(id: "c3", workoutID: "w3", sessionRPE: nil, soreness: 2, pain: 0,
                                           wasRightForToday: false, dateCreated: now.addingTimeInterval(-2)),
            WorkoutCompletionCheckInRecord(id: "c4", workoutID: "w4", sessionRPE: 7, soreness: 1, pain: 0,
                                           wasRightForToday: true, dateCreated: now.addingTimeInterval(-3))
        ]
        try await client.save(checkIns, recordType: "WorkoutCompletionCheckIn")

        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: calendar
        )
        XCTAssertEqual(try XCTUnwrap(result.training.weeklyLoadRatio), 2, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.training.averageSessionRPE), 7, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.training.rightForTodayRate), 0.75, accuracy: 0.001)
        XCTAssertEqual(result.training.completedWorkoutsInLast28Days, 5)
    }

    func testNoSameDayPainReturnsNil() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            DailyPainLog(id: "old", locationIds: "back", intensity: 5, painType: .aching,
                         date: now.addingTimeInterval(-86_400)),
            recordType: "DailyPainLog"
        )
        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertNil(result.pain)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
```

- [ ] **Step 2: Confirm the tests fail**

Run: `cd SundeeFundee && swift test --filter HistoryReadinessProviderTests`

Expected: FAIL with `cannot find 'HistoryReadinessProvider' in scope`.

- [ ] **Step 3: Implement concurrent record loading and aggregation**

```swift
import Foundation

public struct HistoryReadinessSnapshot: Sendable, Equatable {
    public let subjective: SubjectiveReadinessSnapshot
    public let training: TrainingReadinessSnapshot
    public let pain: PainReadinessSnapshot?
}

public protocol HistoryReadinessProviding: Sendable {
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot
}

public actor HistoryReadinessProvider: HistoryReadinessProviding {
    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot {
        async let symptoms: [SymptomCheckInRecord] = fetch("SymptomCheckInRecord")
        async let painLogs: [DailyPainLog] = fetch("DailyPainLog")
        async let completedRecords: [CompletedWorkoutRecord] = fetch("CompletedWorkoutRecord")
        async let fullWorkouts: [Workout] = fetch("Workout")
        async let checkIns: [WorkoutCompletionCheckInRecord] = fetch("WorkoutCompletionCheckIn")
        let values = await (symptoms, painLogs, completedRecords, fullWorkouts, checkIns)
        let workouts = values.2.isEmpty ? values.3.compactMap(\.completedWorkoutRecord) : values.2
        let sameDaySymptoms = values.0
            .filter { calendar.isDate($0.symptomDate, inSameDayAs: assessmentDate) }
            .max { $0.dateCreated < $1.dateCreated }
        let sameDayPain = values.1
            .filter { calendar.isDate($0.date, inSameDayAs: assessmentDate) }
            .max { $0.date < $1.date }
        let recentCheckIns = values.4.sorted { $0.dateCreated > $1.dateCreated }.prefix(4)
        let rpes = recentCheckIns.compactMap(\.sessionRPE).map(Double.init)
        let rightRate = recentCheckIns.isEmpty ? nil
            : Double(recentCheckIns.filter(\.wasRightForToday).count) / Double(recentCheckIns.count)
        return HistoryReadinessSnapshot(
            subjective: SubjectiveReadinessSnapshot(
                energy: sameDaySymptoms?.energy, fatigue: sameDaySymptoms?.fatigue,
                soreness: sameDaySymptoms?.soreness, stress: nil,
                perceivedReadiness: nil, cramps: sameDaySymptoms?.cramps
            ),
            training: TrainingReadinessSnapshot(
                weeklyLoadRatio: loadRatio(workouts: workouts, assessmentDate: assessmentDate, calendar: calendar),
                averageSessionRPE: rpes.isEmpty ? nil : rpes.reduce(0, +) / Double(rpes.count),
                rightForTodayRate: rightRate,
                completedWorkoutsInLast28Days: workouts.filter {
                    $0.date >= calendar.date(byAdding: .day, value: -28, to: assessmentDate) ?? assessmentDate
                }.count
            ),
            pain: sameDayPain.map {
                PainReadinessSnapshot(
                    intensity: $0.intensity, painType: $0.painType,
                    locationIDs: $0.locationIds.split(separator: ",").map(String.init), observedAt: $0.date
                )
            }
        )
    }

    private func fetch<T: Decodable & Sendable>(_ recordType: String) async -> [T] {
        (try? await dataClient.fetchAll(recordType: recordType) as [T]) ?? []
    }

    private func loadRatio(
        workouts: [CompletedWorkoutRecord], assessmentDate: Date, calendar: Calendar
    ) -> Double? {
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: assessmentDate),
              let twentyEightDaysAgo = calendar.date(byAdding: .day, value: -28, to: assessmentDate) else { return nil }
        let current = workouts.filter { $0.date >= sevenDaysAgo && $0.date <= assessmentDate }.count
        let prior = workouts.filter { $0.date >= twentyEightDaysAgo && $0.date < sevenDaysAgo }.count
        let priorWeeklyAverage = Double(prior) / 3.0
        guard priorWeeklyAverage > 0 else { return nil }
        return Double(current) / priorWeeklyAverage
    }
}
```

- [ ] **Step 4: Run the history-provider tests**

Run: `cd SundeeFundee && swift test --filter HistoryReadinessProviderTests`

Expected: PASS for same-day selection, pain, load ratio, and completion feedback.

- [ ] **Step 5: Commit the provider**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/HistoryReadinessProvider.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/HistoryReadinessProviderTests.swift
git commit -m "feat(readiness): summarize training history"
```

---

### Task 8: Assemble the complete daily context concurrently

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyTrainingContextBuilder.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyTrainingContextBuilderTests.swift`

**Interfaces:**
- Consumes: `HealthReadinessProviding` and `HistoryReadinessProviding` from Tasks 6–7.
- Produces: `DailyTrainingContextBuilder.build(assessmentDate:timeZone:cyclePhase:cycleConfidence:)`.

- [ ] **Step 1: Write a failing orchestration test with recording stubs**

```swift
import XCTest
@testable import SundeeFundeeKit

final class DailyTrainingContextBuilderTests: XCTestCase {
    func testBuilderCallsBothProvidersAndCombinesTheirValues() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let health = StubHealthProvider(value: PhysiologicalReadinessSnapshot(
            sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: [], observedAt: date)
        ))
        let history = StubHistoryProvider(value: HistoryReadinessSnapshot(
            subjective: SubjectiveReadinessSnapshot(energy: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1),
            pain: nil
        ))
        let builder = DailyTrainingContextBuilder(healthProvider: health, historyProvider: history)
        let result = await builder.build(
            assessmentDate: date,
            timeZone: TimeZone(identifier: "America/New_York")!,
            cyclePhase: .luteal,
            cycleConfidence: 0.8
        )

        let healthCalls = await health.calls()
        let historyCalls = await history.calls()
        XCTAssertEqual(healthCalls, 1)
        XCTAssertEqual(historyCalls, 1)
        XCTAssertEqual(result.physiological.sleepHours?.currentValue, 8)
        XCTAssertEqual(result.subjective.energy, 8)
        XCTAssertEqual(result.training.weeklyLoadRatio, 1)
        XCTAssertEqual(result.cyclePhase, .luteal)
        XCTAssertEqual(result.cycleConfidence, 0.8)
        XCTAssertEqual(result.assessmentDate, date)
        XCTAssertEqual(result.timeZoneIdentifier, "America/New_York")
    }
}

private actor StubHealthProvider: HealthReadinessProviding {
    private let value: PhysiologicalReadinessSnapshot
    private var callCount = 0
    init(value: PhysiologicalReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot {
        callCount += 1
        return value
    }
    func calls() -> Int { callCount }
}

private actor StubHistoryProvider: HistoryReadinessProviding {
    private let value: HistoryReadinessSnapshot
    private var callCount = 0
    init(value: HistoryReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot {
        callCount += 1
        return value
    }
    func calls() -> Int { callCount }
}
```

- [ ] **Step 2: Confirm the orchestration test fails**

Run: `cd SundeeFundee && swift test --filter DailyTrainingContextBuilderTests`

Expected: FAIL with `cannot find 'DailyTrainingContextBuilder' in scope`.

- [ ] **Step 3: Implement the small orchestration actor**

```swift
import Foundation

public actor DailyTrainingContextBuilder {
    private let healthProvider: HealthReadinessProviding
    private let historyProvider: HistoryReadinessProviding

    public init(
        healthProvider: HealthReadinessProviding,
        historyProvider: HistoryReadinessProviding
    ) {
        self.healthProvider = healthProvider
        self.historyProvider = historyProvider
    }

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthProvider = HealthReadinessProvider(healthClient: healthClient)
        self.historyProvider = HistoryReadinessProvider(dataClient: dataClient)
    }

    public func build(
        assessmentDate: Date = Date(),
        timeZone: TimeZone = .current,
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?
    ) async -> DailyTrainingContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        async let health = healthProvider.load(assessmentDate: assessmentDate, calendar: calendar)
        async let history = historyProvider.load(assessmentDate: assessmentDate, calendar: calendar)
        let (physiological, recorded) = await (health, history)
        return DailyTrainingContext(
            assessmentDate: assessmentDate,
            timeZoneIdentifier: timeZone.identifier,
            physiological: physiological,
            subjective: recorded.subjective,
            training: recorded.training,
            pain: recorded.pain,
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence
        )
    }
}
```

- [ ] **Step 4: Run builder and provider tests together**

Run: `cd SundeeFundee && swift test --filter ReadinessProviderTests && swift test --filter DailyTrainingContextBuilderTests`

Expected: Provider and builder suites pass.

- [ ] **Step 5: Commit the builder**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyTrainingContextBuilder.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyTrainingContextBuilderTests.swift
git commit -m "feat(readiness): assemble daily training context"
```

---

### Task 9: Cache and persist shadow assessments

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyReadinessService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SharedSnapshotStore.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessServiceTests.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SharedSnapshotStoreTests.swift`

**Interfaces:**
- Consumes: `DailyTrainingContextBuilder`, `ReadinessAssessmentService`, `DailyReadinessRecord`, `DataClientProtocol`.
- Produces: `DailyReadinessSnapshot`, `ReadinessPersistenceState`, `DailyReadinessResult`, and `DailyReadinessService.calculateShadowAssessment(...)`.

- [ ] **Step 1: Write failing cache and service tests**

```swift
import CloudKit
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class DailyReadinessServiceTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private var defaults: UserDefaults!
    private var previousDefaults: UserDefaults?

    override func setUp() {
        super.setUp()
        previousDefaults = SharedSnapshotStore.defaults
        defaults = UserDefaults(suiteName: "DailyReadinessServiceTests.\(UUID().uuidString)") ?? .standard
        SharedSnapshotStore.defaults = defaults
        SharedSnapshotStore.clear()
    }

    override func tearDown() {
        SharedSnapshotStore.clear()
        SharedSnapshotStore.defaults = previousDefaults
        defaults = nil
        previousDefaults = nil
        super.tearDown()
    }

    func testSuccessfulAssessmentPersistsAndCaches() async throws {
        let client = MockCloudKitClient()
        let service = makeService(dataClient: client, subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2))
        let result = await service.calculateShadowAssessment(
            assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: .luteal, cycleConfidence: 0.8
        )
        XCTAssertEqual(result?.persistence, .saved)
        let saved: [DailyReadinessRecord] = try await client.fetchAll(recordType: DailyReadinessRecord.recordType)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(SharedSnapshotStore.readReadiness()?.totalScore, result?.assessment.totalScore)
    }

    func testSaveFailureReturnsCachedOnly() async {
        let service = makeService(dataClient: FailingSaveClient(), subjective: SubjectiveReadinessSnapshot(energy: 8))
        let result = await service.calculateShadowAssessment(
            assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: nil, cycleConfidence: nil
        )
        XCTAssertEqual(result?.persistence, .cachedOnly)
        XCTAssertNotNil(SharedSnapshotStore.readReadiness())
    }

    func testEmptyContextReturnsNilAndDoesNotCache() async {
        let service = makeService(dataClient: MockCloudKitClient(), subjective: .empty)
        let result = await service.calculateShadowAssessment(
            assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: nil, cycleConfidence: nil
        )
        XCTAssertNil(result)
        XCTAssertNil(SharedSnapshotStore.readReadiness())
    }

    private func makeService(
        dataClient: DataClientProtocol,
        subjective: SubjectiveReadinessSnapshot
    ) -> DailyReadinessService {
        let builder = DailyTrainingContextBuilder(
            healthProvider: FixedHealthProvider(value: .empty),
            historyProvider: FixedHistoryProvider(value: HistoryReadinessSnapshot(
                subjective: subjective, training: .empty, pain: nil
            ))
        )
        return DailyReadinessService(contextBuilder: builder, dataClient: dataClient)
    }
}

private actor FixedHealthProvider: HealthReadinessProviding {
    let value: PhysiologicalReadinessSnapshot
    init(value: PhysiologicalReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot { value }
}

private actor FixedHistoryProvider: HistoryReadinessProviding {
    let value: HistoryReadinessSnapshot
    init(value: HistoryReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot { value }
}

private actor FailingSaveClient: DataClientProtocol {
    func fetch<T>(recordType: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
    where T: Decodable & Sendable { [] }

    func save<T>(_ records: [T], recordType: String) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}
    func deleteAllData() async throws {}
    func saveFromJSON(_ jsonRecords: [Data], recordType: String) async throws {
        throw DataError.networkError(underlying: nil)
    }
}
```

- [ ] **Step 2: Confirm the new tests fail**

Run: `cd SundeeFundee && swift test --filter DailyReadinessServiceTests`

Expected: FAIL because the service and snapshot types do not exist.

- [ ] **Step 3: Add readiness support to `SharedSnapshotStore`**

```swift
public struct DailyReadinessSnapshot: Codable, Sendable, Equatable {
    public let stateRaw: String
    public let totalScore: Int
    public let confidenceRaw: String
    public let modelVersion: String
    public let assessmentDate: Date
    public let capturedAt: Date
}
```

Add key `daily_readiness_snapshot`, then add `writeReadiness(_:)`, `readReadiness()`, and remove the key from `clear()`. Use the same ISO8601 encoder and decoder already owned by `SharedSnapshotStore`.

```swift
private static let readinessKey = "dailyReadinessSnapshot.v1"

public static func writeReadiness(_ snapshot: DailyReadinessSnapshot) {
    guard let defaults else { return }
    do {
        defaults.set(try encoder().encode(snapshot), forKey: readinessKey)
    } catch {
        snapshotLogger.error("writeReadiness failed: \(error.localizedDescription)")
    }
}

public static func readReadiness() -> DailyReadinessSnapshot? {
    guard let defaults, let data = defaults.data(forKey: readinessKey) else { return nil }
    return try? decoder().decode(DailyReadinessSnapshot.self, from: data)
}

public static func clear() {
    defaults?.removeObject(forKey: cycleKey)
    defaults?.removeObject(forKey: sharkWeekBannerSuppressedKey)
    defaults?.removeObject(forKey: readinessKey)
}
```

Add these cases inside the existing serialized `SharedSnapshotStoreTests` suite:

```swift
@Test("Readiness snapshot round-trips through UserDefaults")
func readinessRoundTrip() async throws {
    await withTestSuite {
        let snapshot = DailyReadinessSnapshot(
            stateRaw: "maintain", totalScore: 72, confidenceRaw: "medium",
            modelVersion: "readiness-v1",
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000),
            capturedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        SharedSnapshotStore.writeReadiness(snapshot)
        #expect(SharedSnapshotStore.readReadiness() == snapshot)
    }
}

@Test("clear removes readiness snapshot")
func clearRemovesReadiness() async throws {
    await withTestSuite {
        SharedSnapshotStore.writeReadiness(
            DailyReadinessSnapshot(
                stateRaw: "maintain", totalScore: 72, confidenceRaw: "medium",
                modelVersion: "readiness-v1", assessmentDate: Date(), capturedAt: Date()
            )
        )
        SharedSnapshotStore.clear()
        #expect(SharedSnapshotStore.readReadiness() == nil)
    }
}
```

- [ ] **Step 4: Implement the shadow service**

```swift
import Foundation

public enum ReadinessPersistenceState: Sendable, Equatable {
    case saved
    case cachedOnly
}

public struct DailyReadinessResult: Sendable, Equatable {
    public let assessment: ReadinessAssessment
    public let persistence: ReadinessPersistenceState
}

public actor DailyReadinessService {
    private let contextBuilder: DailyTrainingContextBuilder
    private let dataClient: DataClientProtocol

    public init(contextBuilder: DailyTrainingContextBuilder, dataClient: DataClientProtocol) {
        self.contextBuilder = contextBuilder
        self.dataClient = dataClient
    }

    public func calculateShadowAssessment(
        assessmentDate: Date = Date(),
        timeZone: TimeZone = .current,
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?
    ) async -> DailyReadinessResult? {
        let context = await contextBuilder.build(
            assessmentDate: assessmentDate,
            timeZone: timeZone,
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence
        )
        guard let assessment = ReadinessAssessmentService.assess(context) else { return nil }
        let now = Date()
        let candidate = DailyReadinessRecord(
            assessment: assessment, timeZone: timeZone, createdAt: now, updatedAt: now
        )
        let existing: [DailyReadinessRecord] = (try? await dataClient.fetch(
            recordType: DailyReadinessRecord.recordType,
            predicate: NSPredicate(format: "dayKey == %@", candidate.dayKey),
            sortDescriptors: nil
        )) ?? []
        let originalCreatedAt = existing.first { $0.id == candidate.id }
            .flatMap { ISO8601DateFormatter().date(from: $0.dateCreated) } ?? now
        let record = DailyReadinessRecord(
            assessment: assessment, timeZone: timeZone,
            createdAt: originalCreatedAt, updatedAt: now
        )
        let snapshot = DailyReadinessSnapshot(
            stateRaw: assessment.state.rawValue,
            totalScore: assessment.totalScore,
            confidenceRaw: assessment.confidence.rawValue,
            modelVersion: assessment.modelVersion,
            assessmentDate: assessment.assessmentDate,
            capturedAt: now
        )
        SharedSnapshotStore.writeReadiness(snapshot)
        do {
            try await dataClient.save(record, recordType: DailyReadinessRecord.recordType)
            return DailyReadinessResult(assessment: assessment, persistence: .saved)
        } catch {
            return DailyReadinessResult(assessment: assessment, persistence: .cachedOnly)
        }
    }
}
```

- [ ] **Step 5: Run cache and service tests**

Run:

```bash
cd SundeeFundee
swift test --filter DailyReadinessServiceTests
swift test --filter SharedSnapshotStoreTests
```

Expected: service tests pass; the existing SharedSnapshotStore suite may remain disabled on the macOS SwiftPM host but must compile and pass in the iOS app test target.

- [ ] **Step 6: Commit cache and service together**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyReadinessService.swift SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SharedSnapshotStore.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyReadinessServiceTests.swift SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SharedSnapshotStoreTests.swift
git commit -m "feat(readiness): cache shadow assessments"
```

---

### Task 10: Add and guard the CloudKit schema

**Files:**
- Modify: `SundeeFundeeApp/cloudkit-schema.json`
- Modify: `scripts/next-release-gate.sh`

**Interfaces:**
- Consumes: `DailyReadinessRecord` fields from Task 5.
- Produces: Checked-in schema and automated queryable-index guard.

- [ ] **Step 1: Add a failing schema assertion before changing the schema**

Add to `scripts/next-release-gate.sh` immediately after the existing `TodayWorkoutPreference` checks:

```bash
if ! grep -q 'RECORD TYPE DailyReadinessRecord' "$SCHEMA"; then
    echo "CloudKit schema is missing DailyReadinessRecord."
    exit 1
fi

if ! awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'; then
    echo "CloudKit schema is missing queryable ___recordID for DailyReadinessRecord."
    exit 1
fi
```

- [ ] **Step 2: Run the assertion and confirm it fails**

Run: `bash scripts/next-release-gate.sh`

Expected: exits before builds with `CloudKit schema is missing DailyReadinessRecord.`

- [ ] **Step 3: Add the record type to `cloudkit-schema.json`**

```text
RECORD TYPE DailyReadinessRecord (
    "___createTime"       TIMESTAMP,
    "___createdBy"        REFERENCE,
    "___etag"             STRING,
    "___modTime"          TIMESTAMP,
    "___modifiedBy"       REFERENCE,
    "___recordID"         REFERENCE QUERYABLE,
    assessmentDate        STRING QUERYABLE SORTABLE,
    availableSignalIDs    LIST<STRING>,
    cautionReasonIDs      LIST<STRING>,
    confidenceRaw         STRING QUERYABLE SORTABLE,
    dateCreated           STRING QUERYABLE SORTABLE,
    dateUpdated           STRING QUERYABLE SORTABLE,
    dayKey                STRING QUERYABLE SORTABLE,
    id                    STRING,
    missingSignalIDs      LIST<STRING>,
    modelVersion          STRING QUERYABLE SORTABLE,
    physiologicalScore    INT64,
    positiveReasonIDs     LIST<STRING>,
    staleSignalIDs        LIST<STRING>,
    stateRaw              STRING QUERYABLE SORTABLE,
    subjectiveScore       INT64,
    symptomsPainScore     INT64,
    timeZoneIdentifier    STRING,
    totalScore            INT64 QUERYABLE SORTABLE,
    trainingScore         INT64,
    GRANT WRITE TO "_creator",
    GRANT CREATE TO "_icloud",
    GRANT READ TO "_world"
);
```

- [ ] **Step 4: Run focused schema checks without triggering the full gate**

Run:

```bash
grep -q 'RECORD TYPE DailyReadinessRecord' SundeeFundeeApp/cloudkit-schema.json
awk '/RECORD TYPE DailyReadinessRecord/,/\);/' SundeeFundeeApp/cloudkit-schema.json | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'
```

Expected: both commands exit 0.

- [ ] **Step 5: Commit the schema guard**

```bash
git add SundeeFundeeApp/cloudkit-schema.json scripts/next-release-gate.sh
git commit -m "build(cloudkit): add daily readiness schema"
```

Do not import or deploy the schema in this task. Development import and Production deployment require an explicitly reviewed gate in the readiness-experience and release-hardening plans.

---

### Task 11: Add the readiness foundation release gate

**Files:**
- Create: `scripts/readiness-foundation-gate.sh`
- Create: `docs/release/readiness-foundation-gate.md`

**Interfaces:**
- Consumes: All Tasks 1–10.
- Produces: One repeatable command and a review checklist for the Weeks 1–2 gate.

- [ ] **Step 1: Create the executable gate script**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$ROOT/SundeeFundeeApp/cloudkit-schema.json"

grep -q 'RECORD TYPE DailyReadinessRecord' "$SCHEMA"
awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" \
    | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'

cd "$ROOT/SundeeFundee"
swift test --filter Readiness
swift test --filter DailyTrainingContextBuilderTests
swift test --filter DailyReadinessServiceTests
swift test

cd "$ROOT/SundeeFundeeApp"
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

cd "$ROOT"
swiftlint --config .swiftlint.yml
```

Run `chmod +x scripts/readiness-foundation-gate.sh` after creating it.

- [ ] **Step 2: Create the human gate checklist**

The document must contain these checked-by-review requirements:

```markdown
# Readiness Foundation Gate

- [ ] All readiness domain, provider, record, cache, and service tests pass.
- [ ] Full Swift package tests pass.
- [ ] The app builds for iPhone 17 Pro Simulator.
- [ ] SwiftLint passes with the repository configuration.
- [ ] Missing HealthKit data does not reduce the score.
- [ ] Cycle phase alone cannot create or lower an assessment.
- [ ] Low-confidence output cannot exceed Maintain automation authority.
- [ ] High pain caps the state at Recover or stricter.
- [ ] Daily records replace by stable local-day ID.
- [ ] Raw HealthKit samples are absent from `DailyReadinessRecord`.
- [ ] No workout or production UI consumes shadow readiness yet.
- [ ] `DailyReadinessRecord` has a queryable `___recordID` in the checked-in schema.
- [ ] No schema import, TestFlight upload, or App Store submission was performed.
```

- [ ] **Step 3: Run the complete gate**

Run: `scripts/readiness-foundation-gate.sh`

Expected: all targeted tests, full tests, simulator build, and SwiftLint exit 0.

- [ ] **Step 4: Review that the slice remains shadow-only**

Run:

```bash
rg -n "DailyReadinessService|ReadinessAssessmentService" SundeeFundee/Sources/SundeeFundeeKit/UI SundeeFundeeApp/SundeeFundee
```

Expected: no matches. The service exists for controlled invocation and tests but is not wired into Today or workouts.

- [ ] **Step 5: Commit the foundation gate**

```bash
git add scripts/readiness-foundation-gate.sh docs/release/readiness-foundation-gate.md
git commit -m "test(release): add readiness foundation gate"
```

## Final Review Checklist

- [ ] Compare every implementation diff with `docs/superpowers/specs/2026-07-11-training-intelligence-20-design.md`.
- [ ] Confirm the only implemented program slice is readiness foundation and shadow calculation.
- [ ] Confirm score weights are 30% physiological, 30% subjective, 25% training, and 15% symptoms/pain.
- [ ] Confirm personal HealthKit baselines require 14 prior daily observations.
- [ ] Confirm confidence cannot be high without both physiological and subjective data.
- [ ] Confirm unknown data is excluded and lowers confidence instead of lowering score.
- [ ] Confirm phase never appears in `ReadinessSignalID` or numerical scoring.
- [ ] Confirm all new records use CloudKit-safe field names and ISO8601 date strings.
- [ ] Confirm existing user changes in `SundeeFundeeApp/project.yml`, the Xcode project, and Fastlane files remain untouched unless the user separately authorizes them.
- [ ] Confirm `git status --short` shows no unexpected staged or committed files.
