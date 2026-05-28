import Foundation

// MARK: - SyncStatusKind

/// Categorises the current sync state for display in Settings and workout completion.
public enum SyncStatusKind: String, Sendable, Equatable {
    case localOnly
    case synced
    case queued
    case needsAttention
}

// MARK: - SyncStatus

/// A user-facing snapshot of the current sync state with display-ready copy.
public struct SyncStatus: Sendable, Equatable {
    public let kind: SyncStatusKind
    public let title: String
    public let message: String
    public let systemImage: String
}

// MARK: - SyncStatusService

/// Pure, stateless service that maps guest mode and queue diagnostics
/// into a `SyncStatus` suitable for UI display.
public enum SyncStatusService {

    /// Returns the current sync status based on auth state and queue health.
    ///
    /// - Parameters:
    ///   - isGuest: Whether the user is in guest mode (local-only data).
    ///   - pendingMutationCount: Number of mutations waiting to flush.
    ///   - stuckMutationCount: Number of mutations that failed to sync.
    /// - Returns: A `SyncStatus` with kind, title, message, and SF Symbol name.
    public static func status(
        isGuest: Bool,
        pendingMutationCount: Int,
        stuckMutationCount: Int
    ) -> SyncStatus {
        if isGuest {
            return SyncStatus(
                kind: .localOnly,
                title: "Saved on this device",
                message: "Saved on this device. Sign in to sync to iCloud.",
                systemImage: "lock.shield"
            )
        }

        if stuckMutationCount > 0 {
            return SyncStatus(
                kind: .needsAttention,
                title: "Needs attention",
                message: "Some changes couldn't sync. Check your connection.",
                systemImage: "exclamationmark.icloud"
            )
        }

        if pendingMutationCount > 0 {
            let noun = pendingMutationCount == 1 ? "change" : "changes"
            return SyncStatus(
                kind: .queued,
                title: "Waiting to sync",
                message: "\(pendingMutationCount) \(noun) waiting to sync.",
                systemImage: "arrow.triangle.2.circlepath.icloud"
            )
        }

        return SyncStatus(
            kind: .synced,
            title: "Synced with iCloud",
            message: "All your data is synced with iCloud.",
            systemImage: "checkmark.icloud"
        )
    }
}
