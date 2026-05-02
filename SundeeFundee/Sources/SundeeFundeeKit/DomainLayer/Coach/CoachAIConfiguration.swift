import Foundation

public actor CoachAIConfiguration {
    public static let shared = CoachAIConfiguration()

    private var consecutiveValidationFailures = 0
    private var disabledUntilAppRestart = false

    public init() {}

    public func recordAcceptedCopy() {
        consecutiveValidationFailures = 0
    }

    public func recordRejectedCopy() {
        consecutiveValidationFailures += 1
        if consecutiveValidationFailures >= 2 {
            disabledUntilAppRestart = true
        }
    }

    public func shouldUseOnDeviceCopy() -> Bool {
        !disabledUntilAppRestart
    }
}
