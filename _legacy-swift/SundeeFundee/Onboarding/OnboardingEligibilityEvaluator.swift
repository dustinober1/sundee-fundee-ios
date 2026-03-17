import Foundation
import SwiftData

/// Determines whether the current user needs to go through onboarding.
///
/// Mirrors the logic from the Flutter `OnboardingEligibilityEvaluator`.
enum OnboardingEligibilityEvaluator {

    enum Result {
        case complete
        case needsOnboarding
        case resumeOnboarding
    }

    static func evaluate(user: User?) -> Result {
        guard let user else { return .needsOnboarding }
        if user.onboardingComplete && user.hasRequiredOnboardingAnswers { return .complete }
        if user.hasRequiredOnboardingAnswers { return .resumeOnboarding }
        return .needsOnboarding
    }
}
