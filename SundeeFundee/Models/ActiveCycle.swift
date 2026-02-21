import Foundation
import SwiftData

@Model
final class ActiveCycle {
    var id: String = UUID().uuidString
    var userId: String = ""
    var programId: String = ""
    var cycleName: String = ""
    var startDate: Date = Date.now
    var currentWeek: Int = 1
    var currentSessionId: String = ""
    var currentPhase: String?
    var statusRaw: String = CycleStatus.active.rawValue

    @Relationship(deleteRule: .cascade, inverse: \CompletedWorkout.activeCycle)
    var completedWorkouts: [CompletedWorkout]? = []

    var status: CycleStatus {
        get { CycleStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        programId: String,
        cycleName: String,
        startDate: Date = .now,
        currentWeek: Int = 1,
        currentSessionId: String,
        currentPhase: String? = nil,
        status: CycleStatus = .active
    ) {
        self.id = id
        self.userId = userId
        self.programId = programId
        self.cycleName = cycleName
        self.startDate = startDate
        self.currentWeek = currentWeek
        self.currentSessionId = currentSessionId
        self.currentPhase = currentPhase
        self.statusRaw = status.rawValue
        self.completedWorkouts = []
    }
}
