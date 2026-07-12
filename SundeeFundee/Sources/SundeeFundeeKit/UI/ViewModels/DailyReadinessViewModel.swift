import Foundation
import SwiftUI

public protocol DailyReadinessLoading: Sendable {
    func load(assessmentDate: Date, calendar: Calendar, cyclePhase: CyclePhase?, cycleConfidence: Double?) async throws -> DailyReadinessResult?
}

private struct ServiceReadinessLoader: DailyReadinessLoading {
    let service: DailyReadinessService
    func load(assessmentDate: Date, calendar: Calendar, cyclePhase: CyclePhase?, cycleConfidence: Double?) async throws -> DailyReadinessResult? {
        await service.calculateShadowAssessment(assessmentDate: assessmentDate, timeZone: calendar.timeZone, cyclePhase: cyclePhase, cycleConfidence: cycleConfidence)
    }
}

public struct DailyReadinessUISnapshot: Sendable, Equatable {
    public let state: ReadinessState
    public let totalScore: Int
    public let confidence: ReadinessConfidence
    public let assessmentDate: Date
    public let positiveReasons: [ReadinessReasonCode]
    public let cautionReasons: [ReadinessReasonCode]

    public init(assessment: ReadinessAssessment) {
        state = assessment.state; totalScore = assessment.totalScore; confidence = assessment.confidence
        assessmentDate = assessment.assessmentDate; positiveReasons = assessment.positiveReasons; cautionReasons = assessment.cautionReasons
    }
}

public enum DailyReadinessViewState: Equatable { case loading, content, empty, error }

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class DailyReadinessViewModel: ObservableObject {
    @Published public private(set) var state: DailyReadinessViewState = .loading
    @Published public private(set) var snapshot: DailyReadinessUISnapshot?
    @Published public private(set) var isStale = false
    @Published public private(set) var isGuest: Bool
    @Published public private(set) var guidance = ""
    @Published public private(set) var canRetry = false

    private let loader: any DailyReadinessLoading
    private let calendar: Calendar
    private let cyclePhase: CyclePhase?
    private let cycleConfidence: Double?

    public init(
        service: DailyReadinessService = DailyReadinessService(contextBuilder: DailyTrainingContextBuilder(), dataClient: DataClientFactory.shared.client),
        calendar: Calendar = .current,
        cyclePhase: CyclePhase? = nil,
        cycleConfidence: Double? = nil,
        isGuest: Bool = false
    ) {
        self.loader = ServiceReadinessLoader(service: service); self.calendar = calendar
        self.cyclePhase = cyclePhase; self.cycleConfidence = cycleConfidence; self.isGuest = isGuest
    }

    public init(loader: any DailyReadinessLoading, calendar: Calendar = .current, cyclePhase: CyclePhase? = nil, cycleConfidence: Double? = nil, isGuest: Bool = false) {
        self.loader = loader; self.calendar = calendar; self.cyclePhase = cyclePhase; self.cycleConfidence = cycleConfidence; self.isGuest = isGuest
    }

    public func updateGuestState(_ isGuest: Bool) { self.isGuest = isGuest }

    public func load() async {
        state = .loading; canRetry = false
        do {
            guard let result = try await loader.load(assessmentDate: Date(), calendar: calendar, cyclePhase: cyclePhase, cycleConfidence: cycleConfidence) else {
                state = .empty; snapshot = nil; guidance = isGuest ? "Readiness will be calculated from data saved on this device." : "Complete a check-in or allow Health data to see today's readiness."; return
            }
            snapshot = DailyReadinessUISnapshot(assessment: result.assessment)
            isStale = !calendar.isDateInToday(result.assessment.assessmentDate)
            guidance = makeGuidance(snapshot: snapshot!)
            state = .content
        } catch {
            state = .error; canRetry = true; guidance = "We couldn't calculate readiness. Check your connection and try again."
        }
    }

    public func retry() async { await load() }

    private func makeGuidance(snapshot: DailyReadinessUISnapshot) -> String {
        if isGuest { return "Your readiness is calculated privately from data saved on this device." }
        if snapshot.confidence == .low { return "Health data is limited. Allow Health access for a more confident score." }
        if isStale { return "This score is from an earlier day. Refresh to get today's guidance." }
        switch snapshot.state { case .ready: return "You have a strong signal for training today."; case .maintain: return "A steady session fits today's signals."; case .recover: return "Consider reducing intensity and prioritizing recovery."; case .rest: return "Rest or choose gentle movement today." }
    }
}
