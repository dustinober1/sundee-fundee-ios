import Foundation
import SwiftData

@Model
final class PersonalRecord {
    @Attribute(.unique) var id: String
    var userId: String
    var exerciseId: String
    var recordTypeRaw: String
    var value: Double
    var workoutId: String?
    var date: Date

    var recordType: RecordType {
        get { RecordType(rawValue: recordTypeRaw) ?? .weight }
        set { recordTypeRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseId: String,
        recordType: RecordType,
        value: Double,
        workoutId: String? = nil,
        date: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.recordTypeRaw = recordType.rawValue
        self.value = value
        self.workoutId = workoutId
        self.date = date
    }
}
