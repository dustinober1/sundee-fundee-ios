import Foundation

enum WODTemplateType: String, Sendable {
    case strength
    case amrap
    case emom
    case forTime
    case circuit

    static func from(_ rawValue: String) -> WODTemplateType {
        WODTemplateType(rawValue: rawValue) ?? .strength
    }

    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .amrap: "AMRAP"
        case .emom: "EMOM"
        case .forTime: "For Time"
        case .circuit: "Circuit"
        }
    }

    var requiresTimer: Bool {
        switch self {
        case .amrap, .emom, .forTime: true
        case .strength, .circuit: false
        }
    }
}
