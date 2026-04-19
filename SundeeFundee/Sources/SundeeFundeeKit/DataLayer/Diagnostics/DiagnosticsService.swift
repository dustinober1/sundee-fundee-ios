import Foundation

// MARK: - DiagnosticsService

/// Tracks silent failures in the data layer — currently CloudKit/Local record
/// decode failures — so they can be surfaced in Settings instead of only
/// appearing in os.log where the user never sees them.
///
/// Lives on the MainActor because its `@Published` output binds directly to
/// SwiftUI. Data-layer actors call in via `MainActor.run { ... }`.
@MainActor
public final class DiagnosticsService: ObservableObject {

    // MARK: - Shared

    public static let shared = DiagnosticsService()

    // MARK: - DecodeFailure

    public struct DecodeFailure: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let recordType: String
        public let recordID: String
        public let errorDescription: String
        public let date: Date

        public init(
            id: UUID = UUID(),
            recordType: String,
            recordID: String,
            errorDescription: String,
            date: Date = Date()
        ) {
            self.id = id
            self.recordType = recordType
            self.recordID = recordID
            self.errorDescription = errorDescription
            self.date = date
        }
    }

    // MARK: - Published

    /// Total number of decode failures observed this session (not trimmed).
    @Published public private(set) var decodeFailureCount: Int = 0

    /// Most recent failures, capped to the last 50 in FIFO order.
    @Published public private(set) var recentDecodeFailures: [DecodeFailure] = []

    /// Cap on the circular buffer.
    private let bufferLimit = 50

    // MARK: - Init

    public init() {}

    // MARK: - Recording

    /// Records a decode failure. Increments the lifetime count and appends
    /// to the recent buffer, trimming the oldest entries when the cap is hit.
    public func recordDecodeFailure(recordType: String, recordID: String, error: Error) {
        decodeFailureCount += 1
        let failure = DecodeFailure(
            recordType: recordType,
            recordID: recordID,
            errorDescription: error.localizedDescription
        )
        recentDecodeFailures.append(failure)
        if recentDecodeFailures.count > bufferLimit {
            recentDecodeFailures.removeFirst(recentDecodeFailures.count - bufferLimit)
        }
    }

    /// Clears the count and buffer — exposed for tests and for a future
    /// "acknowledge" UI action.
    public func reset() {
        decodeFailureCount = 0
        recentDecodeFailures = []
    }
}
