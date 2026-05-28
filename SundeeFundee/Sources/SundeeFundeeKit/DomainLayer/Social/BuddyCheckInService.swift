import Foundation

// MARK: - BuddyCheckInSummary

/// Weekly summary of buddy check-ins for a single thread.
public struct BuddyCheckInSummary: Sendable, Equatable {
    public let threadID: String
    public let totalCheckIns: Int
    public let completedCheckIns: Int
    public let weekStartDate: Date

    public init(
        threadID: String,
        totalCheckIns: Int,
        completedCheckIns: Int,
        weekStartDate: Date
    ) {
        self.threadID = threadID
        self.totalCheckIns = totalCheckIns
        self.completedCheckIns = completedCheckIns
        self.weekStartDate = weekStartDate
    }
}

// MARK: - BuddyCheckInService

/// Actor-based service for persisting buddy check-ins and computing summaries.
///
/// Saves through `DataClientProtocol` and computes weekly summaries by fetching
/// and filtering records. Pure domain service with zero framework deps beyond
/// Foundation.
public actor BuddyCheckInService {
    private let dataClient: DataClientProtocol
    private static let recordType = "BuddyCheckInRecord"

    public init(dataClient: DataClientProtocol) {
        self.dataClient = dataClient
    }

    // MARK: - Save

    /// Saves a check-in record through the data client.
    public func save(_ record: BuddyCheckInRecord) async throws {
        try await dataClient.save(record, recordType: Self.recordType)
    }

    // MARK: - Weekly Summary

    /// Computes a weekly summary of check-ins for the given thread.
    ///
    /// - Parameters:
    ///   - threadID: The buddy thread to summarize.
    ///   - weekStartDate: The start of the week (inclusive).
    /// - Returns: A summary with total and completed counts.
    public func weeklySummary(
        threadID: String,
        weekStartDate: Date
    ) async -> BuddyCheckInSummary {
        guard let records: [BuddyCheckInRecord] = try? await dataClient.fetchAll(
            recordType: Self.recordType
        ) else {
            return BuddyCheckInSummary(
                threadID: threadID,
                totalCheckIns: 0,
                completedCheckIns: 0,
                weekStartDate: weekStartDate
            )
        }

        let calendar = Calendar(identifier: .gregorian)
        let weekEndDate = calendar.date(
            byAdding: DateComponents(day: 7),
            to: weekStartDate
        ) ?? weekStartDate

        let filtered = records.filter { record in
            guard record.threadID == threadID else { return false }
            return record.checkInDate >= weekStartDate && record.checkInDate < weekEndDate
        }

        let completedCount = filtered.filter { $0.status == .completed }.count

        return BuddyCheckInSummary(
            threadID: threadID,
            totalCheckIns: filtered.count,
            completedCheckIns: completedCount,
            weekStartDate: weekStartDate
        )
    }
}
