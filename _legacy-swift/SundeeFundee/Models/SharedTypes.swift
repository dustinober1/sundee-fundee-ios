import Foundation

// MARK: - ExerciseValue

/// Represents the value for sets or reps on a program exercise.
/// Supports fixed counts, ranges, AMRAP, and freeform text.
enum ExerciseValue: Codable, Sendable, Hashable {
    case fixed(Int)
    case range(Int, Int)
    case amrap
    case text(String)

    var description: String {
        switch self {
        case .fixed(let n): return "\(n)"
        case .range(let lo, let hi): return "\(lo)–\(hi)"
        case .amrap: return "AMRAP"
        case .text(let s): return s
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type, value, low, high
    }

    init(from decoder: Decoder) throws {
        // Try single integer first
        if let container = try? decoder.singleValueContainer() {
            if let intValue = try? container.decode(Int.self) {
                self = .fixed(intValue)
                return
            }
            if let doubleValue = try? container.decode(Double.self) {
                self = .fixed(Int(doubleValue))
                return
            }
            if let strValue = try? container.decode(String.self) {
                let trimmed = strValue.trimmingCharacters(in: .whitespaces)
                if trimmed.uppercased() == "AMRAP" {
                    self = .amrap
                    return
                }
                let parts = trimmed.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                let ints = parts.compactMap { Int($0) }
                if ints.count == 2 {
                    self = .range(ints[0], ints[1])
                    return
                }
                if let n = Int(trimmed) {
                    self = .fixed(n)
                    return
                }
                self = .text(strValue)
                return
            }
        }
        // Try array of ints [lo, hi] → range
        if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var values: [Int] = []
            while !unkeyedContainer.isAtEnd {
                if let v = try? unkeyedContainer.decode(Int.self) {
                    values.append(v)
                } else {
                    break
                }
            }
            if values.count == 2 {
                self = .range(values[0], values[1])
                return
            }
        }
        // Structured decoding (keyed container)
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let type = try? container.decode(String.self, forKey: .type) {
            switch type {
            case "fixed":
                let value = try container.decode(Int.self, forKey: .value)
                self = .fixed(value)
            case "range":
                let lo = try container.decode(Int.self, forKey: .low)
                let hi = try container.decode(Int.self, forKey: .high)
                self = .range(lo, hi)
            case "amrap":
                self = .amrap
            default:
                let value = try container.decodeIfPresent(String.self, forKey: .value) ?? type
                self = .text(value)
            }
            return
        }
        // Fallback for empty objects or unknown
        self = .fixed(0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let n):
            try container.encode(n)
        case .range(let lo, let hi):
            try container.encode("\(lo)-\(hi)")
        case .amrap:
            try container.encode("AMRAP")
        case .text(let s):
            try container.encode(s)
        }
    }
}

// MARK: - ConditioningScoringType

/// Scoring type for conditioning benchmarks and PRs.
enum ConditioningScoringType: String, Codable, Sendable, CaseIterable {
    case reps
    case time
    case distance
    case roundsAndReps = "rounds_and_reps"
    case weight

    var displayName: String {
        switch self {
        case .reps: return "Reps"
        case .time: return "Time"
        case .distance: return "Distance"
        case .roundsAndReps: return "Rounds + Reps"
        case .weight: return "Weight"
        }
    }

    /// Returns true if newValue is better than existingValue for this scoring type.
    func isBetterThan(newValue: Double, existingValue: Double?) -> Bool {
        guard let existing = existingValue else { return true }
        switch self {
        case .time:
            return newValue < existing  // lower is better for time
        case .reps, .roundsAndReps, .weight, .distance:
            return newValue > existing  // higher is better
        }
    }

    func formatValue(_ value: Double) -> String {
        switch self {
        case .reps:
            let count = Int(value)
            return count == 1 ? "1 rep" : "\(count) reps"
        case .time:
            let totalSeconds = Int(value)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return seconds > 0 ? "\(minutes):\(String(format: "%02d", seconds))" : "\(minutes):00"
        case .distance:
            return String(format: "%.1f m", value)
        case .roundsAndReps:
            let rounds = Int(value) / 10000
            let reps = Int(value) % 10000
            return reps > 0 ? "\(rounds)+\(reps)" : "\(rounds) rounds"
        case .weight:
            return String(format: "%.1f kg", value)
        }
    }
}

// MARK: - PhaseSettings

struct PhaseSettings: Codable, Sendable, Hashable {
    let loadMultiplier: Double
    let setsMultiplier: Double
    let repsMultiplier: Double

    init(loadMultiplier: Double = 1.0, setsMultiplier: Double = 1.0, repsMultiplier: Double = 1.0) {
        self.loadMultiplier = loadMultiplier
        self.setsMultiplier = setsMultiplier
        self.repsMultiplier = repsMultiplier
    }
}

// MARK: - ProgramCycleAdjustmentProfile

/// Cycle adjustment profile for a program — maps menstrual cycle phases to load/volume multipliers.
struct ProgramCycleAdjustmentProfile: Codable, Sendable, Hashable {
    let fallbackPhase: String
    let lowConfidenceScale: Double
    let phaseSettings: [String: PhaseSettings]

    init(fallbackPhase: String = "follicular", lowConfidenceScale: Double = 0.7, phaseSettings: [String: PhaseSettings] = [:]) {
        self.fallbackPhase = fallbackPhase
        self.lowConfidenceScale = lowConfidenceScale
        self.phaseSettings = phaseSettings
    }
}

// MARK: - ConditioningExerciseCatalog

/// Catalog for conditioning exercises and their scoring types.
enum ConditioningExerciseCatalog {
    struct Entry: Sendable {
        let name: String
        let scoringType: ConditioningScoringType
    }

    static let all: [Entry] = [
        Entry(name: "Fran", scoringType: .time),
        Entry(name: "Grace", scoringType: .time),
        Entry(name: "Diane", scoringType: .time),
        Entry(name: "Helen", scoringType: .time),
        Entry(name: "Murph", scoringType: .time),
        Entry(name: "Cindy", scoringType: .roundsAndReps),
        Entry(name: "Fight Gone Bad", scoringType: .reps),
        Entry(name: "Max Pull-ups", scoringType: .reps),
        Entry(name: "Max Push-ups", scoringType: .reps),
        Entry(name: "Wall Ball", scoringType: .reps),
        Entry(name: "Burpee", scoringType: .reps),
        Entry(name: "Box Jump", scoringType: .reps),
        Entry(name: "Double Under", scoringType: .reps),
        Entry(name: "500m Row", scoringType: .time),
        Entry(name: "2000m Row", scoringType: .time),
        Entry(name: "1 Mile Run", scoringType: .time),
        Entry(name: "5K Run", scoringType: .time),
        Entry(name: "400m Run", scoringType: .time),
    ]

    private static let exercises: [String: ConditioningScoringType] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.name, $0.scoringType) })
    }()

    static func scoringType(for exercise: String) -> ConditioningScoringType? {
        exercises[exercise]
    }

    static func isConditioningExercise(_ name: String) -> Bool {
        exercises[name] != nil
    }
}

// MARK: - WeightliftingExerciseCatalog

/// Catalog of standard weightlifting exercises for max tracking.
struct WeightliftingExerciseCatalog {
    enum Category: String, Sendable, CaseIterable {
        case squat = "Squat"
        case hinge = "Hinge"
        case press = "Press"
        case pull = "Pull"
        case olympic = "Olympic"
        case accessory = "Accessory"
    }

    struct Entry: Identifiable, Sendable {
        let id: String
        let category: Category
    }

    static let defaultExerciseID = "Back Squat"

    static let sortedByCategory: [Entry] = [
        Entry(id: "Back Squat", category: .squat),
        Entry(id: "Front Squat", category: .squat),
        Entry(id: "Overhead Squat", category: .squat),
        Entry(id: "Goblet Squat", category: .squat),
        Entry(id: "Bench Press", category: .press),
        Entry(id: "Overhead Press", category: .press),
        Entry(id: "Push Press", category: .press),
        Entry(id: "Incline Bench Press", category: .press),
        Entry(id: "Deadlift", category: .hinge),
        Entry(id: "Sumo Deadlift", category: .hinge),
        Entry(id: "Romanian Deadlift", category: .hinge),
        Entry(id: "Barbell Row", category: .pull),
        Entry(id: "Pendlay Row", category: .pull),
        Entry(id: "Power Clean", category: .olympic),
        Entry(id: "Clean", category: .olympic),
        Entry(id: "Clean & Jerk", category: .olympic),
        Entry(id: "Clean and Jerk", category: .olympic),
        Entry(id: "Snatch", category: .olympic),
        Entry(id: "Power Snatch", category: .olympic),
        Entry(id: "Hang Clean", category: .olympic),
        Entry(id: "Hang Snatch", category: .olympic),
        Entry(id: "Split Jerk", category: .olympic),
        Entry(id: "Hip Thrust", category: .accessory),
        Entry(id: "Weighted Pull-up", category: .accessory),
        Entry(id: "Weighted Dip", category: .accessory),
    ]

    static let all: [Entry] = sortedByCategory

    static func isWeightliftingExercise(_ name: String) -> Bool {
        sortedByCategory.contains { name.hasPrefix($0.id) }
    }
}
