import SwiftData
import Foundation

@Model
final class BarbellPreset {
    var id: String
    var userID: String
    var name: String
    var weightKg: Double
    var isBuiltIn: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        weightKg: Double,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.weightKg = weightKg
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}
