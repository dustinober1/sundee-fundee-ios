import Foundation

// MARK: - Exercise Value (Discriminated Union)

/// A discriminated union for sets/reps values in program templates.
/// Matches the TypeScript ExerciseValue type.
public enum ExerciseValue: Equatable, Codable, Sendable {
    case fixed(value: Int)
    case amrap
    case range(low: Int, high: Int)
    case text(value: String)

    public var description: String {
        switch self {
        case .fixed(let value): return "\(value)"
        case .amrap: return "AMRAP"
        case .range(let low, let high): return "\(low)\u{2013}\(high)"
        case .text(let value): return value
        }
    }
}
