import SwiftData
import Foundation
import SundeeFundeeShared

@Model
final class CustomProgramRecord {
    var id: String
    var userID: String
    var name: String
    var programJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        programJSON: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.programJSON = programJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toProgram() -> Program? {
        guard let data = programJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Program.self, from: data)
    }

    static func from(_ program: Program, userID: String) -> CustomProgramRecord? {
        guard let data = try? JSONEncoder().encode(program),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return CustomProgramRecord(
            id: program.id,
            userID: userID,
            name: program.name,
            programJSON: json
        )
    }
}
