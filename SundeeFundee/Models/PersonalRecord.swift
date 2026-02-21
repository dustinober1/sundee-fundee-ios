import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: String = UUID().uuidString
    var userId: String = ""
    var exerciseId: String = ""
    var recordTypeRaw: String = RecordType.weight.rawValue
    var value: Double = 0
    var workoutId: String?
    var date: Date = Date.now

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
