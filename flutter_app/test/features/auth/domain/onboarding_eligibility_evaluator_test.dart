import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/onboarding_eligibility_evaluator.dart';

UserModel _profile({
  required String name,
  required bool onboardingComplete,
  Gender gender = Gender.female,
  List<InjuryProfileModel> injuryProfiles = const <InjuryProfileModel>[],
}) {
  return UserModel(
    id: 'u1',
    name: name,
    experienceLevel: ExperienceLevel.beginner,
    primaryGoal: PrimaryGoal.strength,
    gender: gender,
    createdAt: DateTime.utc(2026, 2, 1),
    appleUserId: 'apple',
    onboardingComplete: onboardingComplete,
    injuryProfiles: injuryProfiles,
  );
}

void main() {
  group('OnboardingEligibilityEvaluator', () {
    const OnboardingEligibilityEvaluator evaluator =
        OnboardingEligibilityEvaluator();

    test('treats onboardingComplete true as complete even when name missing',
        () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: '', onboardingComplete: true),
        evidence: const LegacyOnboardingEvidence.none(),
      );

      expect(decision.decision, OnboardingDecision.complete);
      expect(decision.reason, OnboardingDecisionReason.onboardingFlagTrue);
      expect(decision.shouldAutoHeal, isFalse);
      expect(decision.showRecoveryNotice, isFalse);
    });

    test('auto-heals stale flag when required name is present', () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: 'Dustin', onboardingComplete: false),
        evidence: const LegacyOnboardingEvidence.none(),
      );

      expect(decision.decision, OnboardingDecision.complete);
      expect(decision.reason, OnboardingDecisionReason.requiredAnswersPresent);
      expect(decision.shouldAutoHeal, isTrue);
      expect(decision.showRecoveryNotice, isFalse);
    });

    test('requires resume when name missing and workout history exists', () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: '', onboardingComplete: false),
        evidence: const LegacyOnboardingEvidence(
          hasWorkoutHistory: true,
          hasMaxHistory: true,
        ),
      );

      expect(decision.decision, OnboardingDecision.resumeOnboarding);
      expect(
        decision.reason,
        OnboardingDecisionReason.missingRequiredWithWorkoutHistory,
      );
      expect(decision.shouldAutoHeal, isFalse);
    });

    test(
        'bypasses resume for max-only legacy history and emits recovery notice',
        () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: '', onboardingComplete: false),
        evidence: const LegacyOnboardingEvidence(
          hasWorkoutHistory: false,
          hasMaxHistory: true,
        ),
      );

      expect(decision.decision, OnboardingDecision.complete);
      expect(
        decision.reason,
        OnboardingDecisionReason.missingRequiredWithMaxOnlyHistory,
      );
      expect(decision.shouldAutoHeal, isTrue);
      expect(decision.showRecoveryNotice, isTrue);
    });

    test('requires resume when name missing and no legacy evidence exists', () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: '', onboardingComplete: false),
        evidence: const LegacyOnboardingEvidence.none(),
      );

      expect(decision.decision, OnboardingDecision.resumeOnboarding);
      expect(
          decision.reason, OnboardingDecisionReason.missingRequiredNoEvidence);
      expect(decision.shouldAutoHeal, isFalse);
      expect(decision.showRecoveryNotice, isFalse);
    });

    test('falls back to resume when legacy evidence probe fails', () {
      final OnboardingEligibility decision = evaluator.evaluate(
        profile: _profile(name: '', onboardingComplete: false),
        evidence: const LegacyOnboardingEvidence.probeFailed(),
      );

      expect(decision.decision, OnboardingDecision.resumeOnboarding);
      expect(decision.reason, OnboardingDecisionReason.legacyProbeFailed);
      expect(decision.shouldAutoHeal, isFalse);
    });
  });

  group('UserModel explicit onboarding answers', () {
    test('treats only male and female as explicitly answered gender values',
        () {
      expect(
        _profile(
          name: 'A',
          onboardingComplete: false,
          gender: Gender.female,
        ).hasExplicitOnboardingGenderAnswer,
        isTrue,
      );
      expect(
        _profile(
          name: 'B',
          onboardingComplete: false,
          gender: Gender.male,
        ).hasExplicitOnboardingGenderAnswer,
        isTrue,
      );
      expect(
        _profile(
          name: 'C',
          onboardingComplete: false,
          gender: Gender.preferNotToSay,
        ).hasExplicitOnboardingGenderAnswer,
        isFalse,
      );
    });
  });
}
