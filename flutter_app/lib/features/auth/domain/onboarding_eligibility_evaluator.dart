import '../../../domain/models/user_model.dart';

enum OnboardingDecision {
  needsOnboarding,
  resumeOnboarding,
  complete,
}

enum OnboardingDecisionReason {
  profileMissing,
  onboardingFlagTrue,
  requiredAnswersPresent,
  missingRequiredWithWorkoutHistory,
  missingRequiredWithMaxOnlyHistory,
  missingRequiredNoEvidence,
  legacyProbeFailed,
}

class LegacyOnboardingEvidence {
  const LegacyOnboardingEvidence({
    required this.hasWorkoutHistory,
    required this.hasMaxHistory,
    this.probeFailed = false,
  });

  const LegacyOnboardingEvidence.none()
      : hasWorkoutHistory = false,
        hasMaxHistory = false,
        probeFailed = false;

  const LegacyOnboardingEvidence.probeFailed()
      : hasWorkoutHistory = false,
        hasMaxHistory = false,
        probeFailed = true;

  final bool hasWorkoutHistory;
  final bool hasMaxHistory;
  final bool probeFailed;

  bool get hasMaxOnlyHistory => !hasWorkoutHistory && hasMaxHistory;
}

class OnboardingEligibility {
  const OnboardingEligibility({
    required this.decision,
    required this.reason,
    this.shouldAutoHeal = false,
    this.showRecoveryNotice = false,
  });

  final OnboardingDecision decision;
  final OnboardingDecisionReason reason;
  final bool shouldAutoHeal;
  final bool showRecoveryNotice;
}

class OnboardingEligibilityEvaluator {
  const OnboardingEligibilityEvaluator();

  OnboardingEligibility evaluate({
    required UserModel profile,
    required LegacyOnboardingEvidence evidence,
  }) {
    if (profile.onboardingComplete) {
      return const OnboardingEligibility(
        decision: OnboardingDecision.complete,
        reason: OnboardingDecisionReason.onboardingFlagTrue,
      );
    }

    if (profile.hasRequiredOnboardingAnswers) {
      return const OnboardingEligibility(
        decision: OnboardingDecision.complete,
        reason: OnboardingDecisionReason.requiredAnswersPresent,
        shouldAutoHeal: true,
      );
    }

    if (evidence.probeFailed) {
      return const OnboardingEligibility(
        decision: OnboardingDecision.resumeOnboarding,
        reason: OnboardingDecisionReason.legacyProbeFailed,
      );
    }

    if (evidence.hasWorkoutHistory) {
      return const OnboardingEligibility(
        decision: OnboardingDecision.resumeOnboarding,
        reason: OnboardingDecisionReason.missingRequiredWithWorkoutHistory,
      );
    }

    if (evidence.hasMaxOnlyHistory) {
      return const OnboardingEligibility(
        decision: OnboardingDecision.complete,
        reason: OnboardingDecisionReason.missingRequiredWithMaxOnlyHistory,
        shouldAutoHeal: true,
        showRecoveryNotice: true,
      );
    }

    return const OnboardingEligibility(
      decision: OnboardingDecision.resumeOnboarding,
      reason: OnboardingDecisionReason.missingRequiredNoEvidence,
    );
  }
}
