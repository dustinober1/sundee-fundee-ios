import Foundation
import SwiftUI

public protocol DailyPresenceServicing: Sendable {
    func recordOpen(at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
    func promoteToday(
        to: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord
    func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary
}

extension DailyPresenceService: DailyPresenceServicing {}

@MainActor
public final class TodayEngagementViewModel: ObservableObject {
    @Published public private(set) var today: DailyPresenceRecord?
    @Published public private(set) var summary: ConsistencyMomentumSummary?
    @Published public private(set) var isLoading = false
    @Published public private(set) var message: String?

    private let serviceProvider: @Sendable () -> any DailyPresenceServicing
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        service: (any DailyPresenceServicing)? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        if let service {
            serviceProvider = { service }
        } else {
            let localStore = PresenceLocalStore()
            serviceProvider = {
                DailyPresenceService(
                    localStore: localStore,
                    dataClient: DataClientFactory.shared.client
                )
            }
        }
        self.calendar = calendar
        self.now = now
    }

    init(
        serviceProvider: @escaping @Sendable () -> any DailyPresenceServicing,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.serviceProvider = serviceProvider
        self.calendar = calendar
        self.now = now
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let service = serviceProvider()
            today = try await service.recordOpen(at: now(), calendar: calendar)
            summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
            message = nil
        } catch {
            message = "Your daily momentum could not be updated. Your training plan is still available."
        }
    }

    public func select(_ status: DailyPresenceStatus) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let service = serviceProvider()
        let level: DailyParticipationLevel =
            status == .resting || status == .trained ? .acted : .checkedIn

        do {
            today = try await service.promoteToday(
                to: level,
                status: status,
                at: now(),
                calendar: calendar
            )
            summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
            message = nil
            HapticFeedback.light()
        } catch {
            message = "That check-in did not save. Please try again."
            HapticFeedback.warning()
        }
    }
}
