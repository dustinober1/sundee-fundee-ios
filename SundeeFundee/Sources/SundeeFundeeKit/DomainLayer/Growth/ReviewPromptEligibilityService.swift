import Foundation

public enum ReviewPromptTrigger: String, Codable, Sendable, CaseIterable {
    case thirdWorkoutCompleted
    case personalRecordLogged
    case benchmarkLogged
    case firstCoachPlanCompleted
    case painAwareSwapWorkoutCompleted
}

public struct ReviewPromptContext: Equatable, Sendable {
    public let completedWorkoutCount: Int
    public let actionSucceeded: Bool

    public init(completedWorkoutCount: Int = 0, actionSucceeded: Bool) {
        self.completedWorkoutCount = completedWorkoutCount
        self.actionSucceeded = actionSucceeded
    }
}

public struct ReviewPromptState: Codable, Equatable, Sendable {
    public var lastPromptedAppVersion: String?
    public var lastPromptedAt: Date?
    public var completedTriggerIDs: Set<String>

    public init(
        lastPromptedAppVersion: String? = nil,
        lastPromptedAt: Date? = nil,
        completedTriggerIDs: Set<String> = []
    ) {
        self.lastPromptedAppVersion = lastPromptedAppVersion
        self.lastPromptedAt = lastPromptedAt
        self.completedTriggerIDs = completedTriggerIDs
    }
}

public struct ReviewPromptEvaluation: Equatable, Sendable {
    public let shouldRequestReview: Bool
    public let state: ReviewPromptState

    public init(shouldRequestReview: Bool, state: ReviewPromptState) {
        self.shouldRequestReview = shouldRequestReview
        self.state = state
    }
}

public struct ReviewPromptEligibilityService: Sendable {
    private let cooldownDays: Int
    private let calendar: Calendar

    public init(cooldownDays: Int = 120, calendar: Calendar = .current) {
        self.cooldownDays = cooldownDays
        self.calendar = calendar
    }

    public func evaluate(
        trigger: ReviewPromptTrigger,
        triggerID: String,
        context: ReviewPromptContext,
        state: ReviewPromptState,
        appVersion: String,
        now: Date = Date()
    ) -> ReviewPromptEvaluation {
        guard context.actionSucceeded else {
            return ReviewPromptEvaluation(shouldRequestReview: false, state: state)
        }

        guard !state.completedTriggerIDs.contains(triggerID) else {
            return ReviewPromptEvaluation(shouldRequestReview: false, state: state)
        }

        guard state.lastPromptedAppVersion != appVersion else {
            return ReviewPromptEvaluation(shouldRequestReview: false, state: state)
        }

        if let lastPromptedAt = state.lastPromptedAt,
           let nextEligibleDate = calendar.date(byAdding: .day, value: cooldownDays, to: lastPromptedAt),
           now < nextEligibleDate {
            return ReviewPromptEvaluation(shouldRequestReview: false, state: state)
        }

        if trigger == .thirdWorkoutCompleted, context.completedWorkoutCount < 3 {
            return ReviewPromptEvaluation(shouldRequestReview: false, state: state)
        }

        var nextState = state
        nextState.lastPromptedAppVersion = appVersion
        nextState.lastPromptedAt = now
        nextState.completedTriggerIDs.insert(triggerID)

        return ReviewPromptEvaluation(shouldRequestReview: true, state: nextState)
    }
}

public final class ReviewPromptStateStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "sundee.reviewPrompt.state.v1"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> ReviewPromptState {
        guard let data = userDefaults.data(forKey: key),
              let state = try? JSONDecoder().decode(ReviewPromptState.self, from: data) else {
            return ReviewPromptState()
        }
        return state
    }

    public func save(_ state: ReviewPromptState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: key)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public enum ReviewPromptCoordinator {
    @discardableResult
    public static func recordSuccessfulAction(
        trigger: ReviewPromptTrigger,
        triggerID: String,
        completedWorkoutCount: Int = 0,
        appVersion: String? = nil,
        userDefaults: UserDefaults = .standard,
        now: Date = Date(),
        notificationCenter: NotificationCenter = .default
    ) -> Bool {
        let appVersion = appVersion ?? Self.currentAppVersion()
        let store = ReviewPromptStateStore(userDefaults: userDefaults)
        let state = store.load()
        let evaluation = ReviewPromptEligibilityService().evaluate(
            trigger: trigger,
            triggerID: triggerID,
            context: ReviewPromptContext(
                completedWorkoutCount: completedWorkoutCount,
                actionSucceeded: true
            ),
            state: state,
            appVersion: appVersion,
            now: now
        )

        guard evaluation.shouldRequestReview else {
            return false
        }

        store.save(evaluation.state)
        notificationCenter.post(name: .appReviewPromptRequested, object: nil)
        return true
    }

    private static func currentAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}
