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
    private var needsReload = false

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
        guard !isLoading else {
            needsReload = true
            return
        }
        isLoading = true

        do {
            let service = serviceProvider()
            today = try await service.recordOpen(at: now(), calendar: calendar)
            summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
            message = nil
        } catch {
            message = "Your daily momentum could not be updated. Your training plan is still available."
        }

        await completeOperation()
    }

    public func select(_ status: DailyPresenceStatus) async {
        let level: DailyParticipationLevel =
            status == .resting || status == .trained ? .acted : .checkedIn
        await promote(level: level, status: status)
    }

    public func recordCheckIn() async {
        await promote(level: .checkedIn, status: nil)
    }

    public func recordAction(_ status: DailyPresenceStatus?) async {
        await promote(level: .acted, status: status)
    }

    private func promote(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?
    ) async {
        guard !isLoading else { return }
        isLoading = true

        let service = serviceProvider()

        do {
            today = try await service.promoteToday(
                to: level,
                status: status,
                at: now(),
                calendar: calendar
            )
            HapticFeedback.light()

            do {
                summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
                message = nil
            } catch {
                message = "Your check-in was saved, but momentum couldn’t refresh yet."
            }
        } catch {
            message = "That check-in did not save. Please try again."
            HapticFeedback.warning()
        }

        await completeOperation()
    }

    private func completeOperation() async {
        isLoading = false
        guard needsReload else { return }
        needsReload = false
        await load()
    }
}
