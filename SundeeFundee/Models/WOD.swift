import Foundation

// MARK: - WOD (Workout of the Day)

struct WOD: Codable, Identifiable, Hashable, Sendable {
    let id: String          // "wod-2026-03-01"
    let date: String        // "2026-03-01" (yyyy-MM-dd)
    let title: String       // "Sunday Starter"
    let description: String // Coach notes
    let exercises: [ProgramExercise]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: WOD, rhs: WOD) -> Bool { lhs.id == rhs.id }
}
