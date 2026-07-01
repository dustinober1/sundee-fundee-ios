import Foundation

public enum ProgressivePrompt: String, Sendable, Equatable {
    case healthKit
    case cycleSetup
    case photoSharing
    case reminders
}

public struct ProgressivePromptContext: Sendable, Equatable {
    public let completedWorkoutCount: Int
    public let openedCycle: Bool
    public let isAboutToSharePhoto: Bool
    public let declinedPromptIDs: [String]

    public init(
        completedWorkoutCount: Int,
        openedCycle: Bool,
        isAboutToSharePhoto: Bool,
        declinedPromptIDs: [String]
    ) {
        self.completedWorkoutCount = completedWorkoutCount
        self.openedCycle = openedCycle
        self.isAboutToSharePhoto = isAboutToSharePhoto
        self.declinedPromptIDs = declinedPromptIDs
    }
}

public enum ProgressivePromptPolicy {
    public static func nextPrompt(context: ProgressivePromptContext) -> ProgressivePrompt? {
        if context.openedCycle && !context.declinedPromptIDs.contains(ProgressivePrompt.cycleSetup.rawValue) {
            return .cycleSetup
        }
        if context.isAboutToSharePhoto && !context.declinedPromptIDs.contains(ProgressivePrompt.photoSharing.rawValue) {
            return .photoSharing
        }
        if context.completedWorkoutCount >= 1 && !context.declinedPromptIDs.contains(ProgressivePrompt.healthKit.rawValue) {
            return .healthKit
        }
        if context.completedWorkoutCount >= 2 && !context.declinedPromptIDs.contains(ProgressivePrompt.reminders.rawValue) {
            return .reminders
        }
        return nil
    }
}
