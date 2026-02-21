import Foundation
import SwiftData

@Model
final class OneRepMax {
    @Attribute(.unique) var id: String
    var userId: String
    var exerciseId: String
    var weight: Double
    var date: Date

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
