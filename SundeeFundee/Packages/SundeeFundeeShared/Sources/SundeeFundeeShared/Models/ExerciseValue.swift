import Foundation

public enum ExerciseValue: Codable, CustomStringConvertible, Sendable {
    case fixed(Int)
    case amrap
    case range(Int, Int)
    case text(String)

    public var description: String {
        switch self {
        case .fixed(let n): return "\(n)"
        case .amrap: return "AMRAP"
        case .range(let lo, let hi): return "\(lo)–\(hi)"
        case .text(let t): return t
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let n = try? container.decode(Int.self) { self = .fixed(n); return }
        if let d = try? container.decode(Double.self) { self = .fixed(Int(d)); return }
        if let s = try? container.decode(String.self) {
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased() == "AMRAP" { self = .amrap; return }
            if trimmed.contains("-") {
                let parts = trimmed.split(separator: "-")
                if parts.count == 2,
                   let lo = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                   let hi = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    self = .range(lo, hi); return
                }
            }
            if let n = Int(trimmed) { self = .fixed(n); return }
            self = .text(s); return
        }
        if let arr = try? container.decode([Int].self), arr.count == 2 {
            self = .range(arr[0], arr[1]); return
        }
        self = .fixed(0)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let n): try container.encode(n)
        case .amrap: try container.encode("AMRAP")
        case .range(let lo, let hi): try container.encode([lo, hi])
        case .text(let t): try container.encode(t)
        }
    }
}
