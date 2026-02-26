import SwiftData
import Foundation

enum CycleStatus: String, Codable {
    case active, completed, canceled
}

@Model
final class ActiveCycle {
    var id: String
    var userID: String
    var programID: String
    var cycleName: String
    var startDate: Date
    var currentWeek: Int
    var currentSessionID: String
    var currentPhase: String?
    var statusRaw: String

    init(
        id: String,
        userID: String,
        programID: String,
        cycleName: String,
        startDate: Date,
        currentWeek: Int = 1,
        currentSessionID: String,
        currentPhase: String? = nil,
        status: CycleStatus = .active
    ) {
        self.id = id
        self.userID = userID
        self.programID = programID
        self.cycleName = cycleName
        self.startDate = startDate
        self.currentWeek = currentWeek
        self.currentSessionID = currentSessionID
        self.currentPhase = currentPhase
        self.statusRaw = status.rawValue
    }

    var status: CycleStatus {
        get { CycleStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
}
