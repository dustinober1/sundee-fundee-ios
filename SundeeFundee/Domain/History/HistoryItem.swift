import Foundation

// MARK: - HistoryItemSource

enum HistoryItemSource: Hashable, Sendable {
    case aiWorkout
    case program(name: String)
}

// MARK: - HistoryItem

struct HistoryItem: Identifiable, Sendable {
    let id: String
    let title: String
    let source: HistoryItemSource
    let completedAt: Date
    let exerciseCount: Int
    let durationSeconds: Int

    /// Original ID for deletion (not prefixed).
    let originalID: String
    let isAIWorkout: Bool

    var sourceLabel: String {
        switch source {
        case .aiWorkout: return "AI Workout"
        case .program(let name): return name
        }
    }
}
