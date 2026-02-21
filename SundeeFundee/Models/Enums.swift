import Foundation

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

enum PrimaryGoal: String, Codable, CaseIterable {
    case strength
    case hypertrophy
    case explosiveness
}

enum CycleStatus: String, Codable, CaseIterable {
    case active
    case completed
    case paused
}

enum RecordType: String, Codable, CaseIterable {
    case weight
    case volume
}

enum FlowLevel: String, Codable, CaseIterable {
    case light
    case medium
    case heavy
}

enum SymptomCategory: String, Codable, CaseIterable {
    case physical
    case emotional
    case energy
}

enum CyclePhase: String, Codable, CaseIterable {
    case menstrual
    case follicular
    case ovulation
    case luteal
}

enum TimerStatus: String, Codable {
    case idle
    case running
    case paused
    case complete
}

enum NotificationType: String, Codable, CaseIterable {
    case sound
    case vibrate
    case both
    case none
}
