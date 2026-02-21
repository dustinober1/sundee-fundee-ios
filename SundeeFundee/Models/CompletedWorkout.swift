import Foundation
import SwiftData

@Model
final class CompletedWorkout {
    @Attribute(.unique) var id: String
    var userId: String
    var activeCycleId: String
    var programId: String
    var week: Int
    var day: Int
    var sessionId: String
    var completedAt: Date
    var duration: Int
    var notes: String?

    var activeCycle: ActiveCycle?

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.workout)
    var completedSets: [CompletedSet]?

    init(
        id: String = UUID().uuidString,
        userId: String,
        activeCycleId: String,
        programId: String,
        week: Int,
        day: Int,
        sessionId: String,
        completedAt: Date = .now,
        duration: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.activeCycleId = activeCycleId
        self.programId = programId
        self.week = week
        self.day = day
        self.sessionId = sessionId
        self.completedAt = completedAt
        self.duration = duration
        self.notes = notes
        self.completedSets = []
    }
}
