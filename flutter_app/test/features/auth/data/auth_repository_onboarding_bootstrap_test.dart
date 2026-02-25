import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/onboarding_eligibility_evaluator.dart';

UserModel _profile({
  required String name,
  required bool onboardingComplete,
  List<InjuryProfileModel> injuryProfiles = const <InjuryProfileModel>[],
}) {
  return UserModel(
    id: 'u1',
    name: name,
    experienceLevel: ExperienceLevel.beginner,
    primaryGoal: PrimaryGoal.strength,
    gender: Gender.female,
    createdAt: DateTime.utc(2026, 2, 1),
    appleUserId: 'apple',
    onboardingComplete: onboardingComplete,
    injuryProfiles: injuryProfiles,
  );
}

AuthRepository _buildRepository({
  required Future<LegacyOnboardingEvidence> Function(String userId)
      legacyEvidenceLoader,
  required Future<void> Function(String userId) autoHealWriter,
  Duration timeout = const Duration(milliseconds: 30),
}) {
  return AuthRepository(
    guestModeStore: GuestModeStore(),
    firebaseEnabled: false,
    onboardingEligibilityEvaluator: const OnboardingEligibilityEvaluator(),
    legacyEvidenceLoader: legacyEvidenceLoader,
    onboardingAutoHealWriter: autoHealWriter,
    legacyEvidenceTimeout: timeout,
  );
}

void main() {
  group('AuthRepository onboarding bootstrap decisions', () {
    test(
        'complete profile with stale flag bypasses resume and schedules auto-heal',
        () async {
      final List<String> healedUsers = <String>[];
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async =>
            const LegacyOnboardingEvidence.none(),
        autoHealWriter: (String userId) async => healedUsers.add(userId),
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: 'Dustin', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.authenticated);
      expect(session.shouldShowRecoveryNotice, isFalse);
      expect(healedUsers, <String>['u1']);
    });

    test('missing-name profile with workout history requires resume onboarding',
        () async {
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async => const LegacyOnboardingEvidence(
          hasWorkoutHistory: true,
          hasMaxHistory: true,
        ),
        autoHealWriter: (_) async {},
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: '', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.resumeOnboarding);
      expect(session.shouldShowRecoveryNotice, isFalse);
    });

    test(
        'missing-name profile with max-only history bypasses resume and marks recovery notice',
        () async {
      final List<String> healedUsers = <String>[];
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async => const LegacyOnboardingEvidence(
          hasWorkoutHistory: false,
          hasMaxHistory: true,
        ),
        autoHealWriter: (String userId) async => healedUsers.add(userId),
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: '', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.authenticated);
      expect(session.shouldShowRecoveryNotice, isTrue);
      expect(healedUsers, <String>['u1']);
    });

    test(
        'missing-name profile with no legacy evidence requires resume onboarding',
        () async {
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async =>
            const LegacyOnboardingEvidence.none(),
        autoHealWriter: (_) async {},
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: '', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.resumeOnboarding);
      expect(session.shouldShowRecoveryNotice, isFalse);
    });

    test('legacy evidence timeout defaults to resume onboarding', () async {
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const LegacyOnboardingEvidence.none();
        },
        autoHealWriter: (_) async {},
        timeout: const Duration(milliseconds: 5),
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: '', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.resumeOnboarding);
      expect(session.shouldShowRecoveryNotice, isFalse);
    });

    test('legacy evidence errors default to resume onboarding', () async {
      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async => throw StateError('boom'),
        autoHealWriter: (_) async {},
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(name: '', onboardingComplete: false),
      );

      expect(session.status, AuthStatus.resumeOnboarding);
      expect(session.shouldShowRecoveryNotice, isFalse);
    });

    test('injury gating runs only after onboarding completeness is satisfied',
        () async {
      final InjuryProfileModel incompleteInjury = InjuryProfileModel(
        id: 'inj-1',
        location: 'Shoulder',
        movementLimitations: '',
        recoveryGoal: 'Return to overhead movement',
        status: InjuryStatus.active,
        createdAt: DateTime.utc(2026, 2, 1),
        updatedAt: DateTime.utc(2026, 2, 1),
      );

      final repository = _buildRepository(
        legacyEvidenceLoader: (_) async =>
            const LegacyOnboardingEvidence.none(),
        autoHealWriter: (_) async {},
      );

      final AuthSession session = await repository.resolveAuthSessionForProfile(
        userId: 'u1',
        profile: _profile(
          name: 'Dustin',
          onboardingComplete: false,
          injuryProfiles: <InjuryProfileModel>[incompleteInjury],
        ),
      );

      expect(session.status, AuthStatus.needsInjuryProfile);
    });
  });
}
