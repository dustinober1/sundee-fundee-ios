import Foundation

/// Structured body region for injury location mapping.
enum BodyLocation {

    enum Region: String, CaseIterable, Codable {
        case head
        case neck
        case leftShoulder
        case rightShoulder
        case chest
        case upperBack
        case lowerBack
        case leftElbow
        case rightElbow
        case leftWrist
        case rightWrist
        case leftHip
        case rightHip
        case leftKnee
        case rightKnee
        case leftAnkle
        case rightAnkle

        var displayName: String {
            switch self {
            case .head:           return "Head"
            case .neck:           return "Neck"
            case .leftShoulder:   return "Left Shoulder"
            case .rightShoulder:  return "Right Shoulder"
            case .chest:          return "Chest"
            case .upperBack:      return "Upper Back"
            case .lowerBack:      return "Lower Back"
            case .leftElbow:      return "Left Elbow"
            case .rightElbow:     return "Right Elbow"
            case .leftWrist:      return "Left Wrist"
            case .rightWrist:     return "Right Wrist"
            case .leftHip:        return "Left Hip"
            case .rightHip:       return "Right Hip"
            case .leftKnee:       return "Left Knee"
            case .rightKnee:      return "Right Knee"
            case .leftAnkle:      return "Left Ankle"
            case .rightAnkle:     return "Right Ankle"
            }
        }

        /// Maps to the engine's contraindication key.
        var engineKey: String {
            switch self {
            case .head, .neck:                       return "back"
            case .leftShoulder, .rightShoulder:      return "shoulder"
            case .chest:                             return "shoulder"
            case .upperBack:                         return "back"
            case .lowerBack:                         return "back"
            case .leftElbow, .rightElbow:            return "wrist"
            case .leftWrist, .rightWrist:            return "wrist"
            case .leftHip, .rightHip:                return "hip"
            case .leftKnee, .rightKnee:              return "knee"
            case .leftAnkle, .rightAnkle:            return "ankle"
            }
        }
    }

    /// Parses comma-separated raw string into regions.
    static func parseRegions(_ raw: String) -> [Region] {
        raw.split(separator: ",")
            .compactMap { Region(rawValue: String($0).trimmingCharacters(in: .whitespaces)) }
    }

    /// Encodes regions to comma-separated raw string.
    static func encodeRegions(_ regions: [Region]) -> String {
        regions.map(\.rawValue).joined(separator: ",")
    }
}
