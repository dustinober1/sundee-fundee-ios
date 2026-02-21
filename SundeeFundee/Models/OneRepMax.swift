import Foundation
import SwiftData

@Model
final class OneRepMax {
    var id: String = UUID().uuidString
    var userId: String = ""
    var exerciseId: String = ""
    var weight: Double = 0
    var date: Date = Date.now

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseId: String,
        weight: Double,
        date: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.weight = weight
        self.date = date
    }
}
