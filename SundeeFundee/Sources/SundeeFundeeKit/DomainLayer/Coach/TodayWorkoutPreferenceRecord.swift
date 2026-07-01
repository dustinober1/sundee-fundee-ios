import Foundation

public struct TodayWorkoutPreferenceRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let dateKey: String
    public var preferredMinutes: Int?
    public var reduceVolumeSelected: Bool
    public var removedExerciseNamesJSON: String?
    public let dateCreated: Date

    public init(
        id: String,
        dateKey: String,
        preferredMinutes: Int? = nil,
        reduceVolumeSelected: Bool = false,
        removedExerciseNamesJSON: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.preferredMinutes = preferredMinutes
        self.reduceVolumeSelected = reduceVolumeSelected
        self.removedExerciseNamesJSON = removedExerciseNamesJSON
        self.dateCreated = dateCreated
    }
}
