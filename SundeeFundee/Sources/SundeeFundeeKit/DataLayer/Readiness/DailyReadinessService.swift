import Foundation

public enum ReadinessPersistenceState: Sendable, Equatable {
    case saved
    case cachedOnly
}

public struct DailyReadinessResult: Sendable, Equatable {
    public let assessment: ReadinessAssessment
    public let persistence: ReadinessPersistenceState

    public init(assessment: ReadinessAssessment, persistence: ReadinessPersistenceState) {
        self.assessment = assessment
        self.persistence = persistence
    }
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
        let context = await contextBuilder.build(assessmentDate: assessmentDate, timeZone: timeZone, cyclePhase: cyclePhase, cycleConfidence: cycleConfidence)
        guard let assessment = ReadinessAssessmentService.assess(context) else { return nil }
        let now = Date()
        let candidate = DailyReadinessRecord(assessment: assessment, timeZone: timeZone, createdAt: now, updatedAt: now)
        let existing: [DailyReadinessRecord] = (try? await dataClient.fetch(recordType: DailyReadinessRecord.recordType, predicate: NSPredicate(format: "dayKey == %@", candidate.dayKey), sortDescriptors: nil)) ?? []
        let originalCreatedAt = existing.first { $0.id == candidate.id }.flatMap { ISO8601DateFormatter().date(from: $0.dateCreated) } ?? now
        let record = DailyReadinessRecord(assessment: assessment, timeZone: timeZone, createdAt: originalCreatedAt, updatedAt: now)
        SharedSnapshotStore.writeReadiness(DailyReadinessSnapshot(stateRaw: assessment.state.rawValue, totalScore: assessment.totalScore, confidenceRaw: assessment.confidence.rawValue, modelVersion: assessment.modelVersion, assessmentDate: assessment.assessmentDate, capturedAt: now))
        do {
            try await dataClient.save(record, recordType: DailyReadinessRecord.recordType)
            return DailyReadinessResult(assessment: assessment, persistence: .saved)
        } catch {
            return DailyReadinessResult(assessment: assessment, persistence: .cachedOnly)
        }
    }
}
