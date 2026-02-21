import Foundation
import SwiftData

@Model
final class CompletedWorkout {
    var id: String = UUID().uuidString
    var userId: String = ""
    var activeCycleId: String = ""
    var programId: String = ""
    var week: Int = 1
    var day: Int = 1
    var sessionId: String = ""
    var completedAt: Date = Date.now
    var duration: Int = 0
    var notes: String?

    var activeCycle: ActiveCycle?

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.workout)
    var completedSets: [CompletedSet]? = []

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
