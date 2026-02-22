import Foundation
import SwiftData

@Model
final class LiftMax {
    var id: String = UUID().uuidString
    var userId: String = ""
    var exerciseId: String = ""
    var repCount: Int = 1
    var weight: Double = 0
    var withStraps: Bool = false
    var updatedAt: Date = Date.now

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseId: String,
        repCount: Int,
        weight: Double,
        withStraps: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.repCount = repCount
        self.weight = weight
        self.withStraps = withStraps
        self.updatedAt = updatedAt
    }
}
