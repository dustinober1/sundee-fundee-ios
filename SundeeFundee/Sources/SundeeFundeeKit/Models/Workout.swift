import Foundation

public struct Workout: Equatable, Codable, Identifiable, Sendable {
    public let id: String
    public var date: Date
    public var name: String
    public var exercises: [Exercise]
    public var notes: String?
    public var duration: Int  // minutes
    public var completedAt: Date?

    public init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        exercises: [Exercise],
        notes: String? = nil,
        duration: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.duration = duration
        self.completedAt = completedAt
    }

    // MARK: - Backwards-compatible decoding
    //
    // Old CloudKit records may be missing `exercises` because the nested
    // array wasn't saved correctly (CloudKit [Any] cast issue). Default
    // to an empty array so the record is still usable for volume/stats.

    private enum CodingKeys: String, CodingKey {
        case id, date, name, exercises, notes, duration, completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        name = try container.decode(String.self, forKey: .name)
        exercises = (try? container.decode([Exercise].self, forKey: .exercises)) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        duration = (try? container.decode(Int.self, forKey: .duration)) ?? 0
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    public var totalVolume: Double {
        exercises.flatMap { exercise in
            exercise.targetSets.map { set in
                let reps = set.actualReps ?? set.reps
                let weight = (set.completedWeight ?? 0) > 0
                    ? set.completedWeight!
                    : (set.prescribedWeight > 0 ? set.prescribedWeight : 0)
                return Double(reps) * weight
            }
        }.reduce(0, +)
    }

    public var isComplete: Bool {
        completedAt != nil
    }
}
