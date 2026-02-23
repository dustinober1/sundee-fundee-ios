import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/calculations/cycle_adaptation_policy.dart';
import '../../../domain/calculations/cycle_calculations.dart';
import '../../../domain/calculations/cycle_program_generator.dart';
import '../../../domain/calculations/injury_adaptation_engine.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/cycle_models.dart';
import '../../../domain/models/injury_profile_model.dart';
import '../../../domain/models/program_models.dart';
import '../../../domain/models/user_model.dart';
import '../../auth/providers.dart';
import '../../cycle/providers.dart';
import '../data/program_repository.dart';

class ProgramAdaptationContext {
  const ProgramAdaptationContext({
    required this.isAdapted,
    required this.phase,
    required this.confidence,
    required this.showAdjustmentDetails,
    required this.autoApplyDuringWorkout,
  });

  final bool isAdapted;
  final CyclePhase? phase;
  final AdaptationConfidence confidence;
  final bool showAdjustmentDetails;
  final bool autoApplyDuringWorkout;
}

final Provider<AsyncValue<ProgramV2?>> adaptedActiveProgramProvider =
    Provider<AsyncValue<ProgramV2?>>((Ref ref) {
  const CycleAdaptationPolicy policy = CycleAdaptationPolicy();

  final AsyncValue<ProgramV2?> baseProgramAsync =
      ref.watch(activeProgramProvider);
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);
  final AsyncValue<CycleAdaptationPreferencesModel?> preferencesAsync =
      ref.watch(cycleAdaptationPreferencesProvider);

  // Force reactive recomputation on cycle stream changes, including same-day edits.
  final CycleStatusResult? cycleStatus = ref.watch(cycleStatusProvider);
  final CyclePhase? lastKnownPhase = ref.watch(cycleLastKnownPhaseProvider);
  final AdaptationConfidence confidence = ref.watch(
    cycleAdaptationConfidenceProvider,
  );
  ref.watch(periodLogsProvider);

  final UserModel? profile = profileAsync.asData?.value;
  final String userId = profile?.id ?? '';
  final CycleAdaptationPreferencesModel preferences =
      preferencesAsync.asData?.value ??
          defaultCycleAdaptationPreferences(userId);

  return baseProgramAsync.whenData((ProgramV2? baseProgram) {
    return buildAdaptedProgramView(
      baseProgram: baseProgram,
      profile: profile,
      preferences: preferences,
      currentPhase: cycleStatus?.currentPhase,
      lastKnownPhase: lastKnownPhase,
      confidence: confidence,
      policy: policy,
    );
  });
});

final Provider<ProgramAdaptationContext> programAdaptationContextProvider =
    Provider<ProgramAdaptationContext>((Ref ref) {
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);
  final AsyncValue<CycleAdaptationPreferencesModel?> preferencesAsync =
      ref.watch(cycleAdaptationPreferencesProvider);
  final CycleStatusResult? cycleStatus = ref.watch(cycleStatusProvider);
  final AdaptationConfidence confidence = ref.watch(
    cycleAdaptationConfidenceProvider,
  );

  final UserModel? profile = profileAsync.asData?.value;
  final CycleAdaptationPreferencesModel preferences =
      preferencesAsync.asData?.value ??
          defaultCycleAdaptationPreferences(profile?.id ?? '');
  final bool isAdapted = _shouldApplyAdaptation(
    profile: profile,
    preferences: preferences,
  );

  return ProgramAdaptationContext(
    isAdapted: isAdapted,
    phase: cycleStatus?.currentPhase,
    confidence: confidence,
    showAdjustmentDetails: preferences.showAdjustmentDetails,
    autoApplyDuringWorkout: preferences.autoApplyDuringWorkout,
  );
});

final Provider<bool> cycleAdjustmentDetailsVisibleProvider = Provider<bool>((
  Ref ref,
) {
  return ref.watch(programAdaptationContextProvider).showAdjustmentDetails;
});

bool _shouldApplyAdaptation({
  required UserModel? profile,
  required CycleAdaptationPreferencesModel preferences,
}) {
  if (profile == null) {
    return false;
  }
  if (profile.gender != Gender.female) {
    return false;
  }
  if (!profile.cycleTrackingEnabled) {
    return false;
  }
  if (!preferences.enabled) {
    return false;
  }
  return true;
}

ProgramV2? buildAdaptedProgramView({
  required ProgramV2? baseProgram,
  required UserModel? profile,
  required CycleAdaptationPreferencesModel preferences,
  required CyclePhase? currentPhase,
  required CyclePhase? lastKnownPhase,
  required AdaptationConfidence confidence,
  CycleAdaptationPolicy policy = const CycleAdaptationPolicy(),
}) {
  if (baseProgram == null) {
    return null;
  }
  if (!_shouldApplyAdaptation(profile: profile, preferences: preferences)) {
    return baseProgram;
  }

  final AdaptationReadinessTier readinessTier = policy.resolveReadinessTier(
    readinessScore: preferences.readinessScore,
  );

  return CycleProgramGenerator.adaptProgram(
    baseProgram: baseProgram,
    currentPhase: currentPhase,
    lastKnownPhase: lastKnownPhase,
    readinessTier: readinessTier,
    confidence: confidence,
  );
}

// ---------------------------------------------------------------------------
// Injury adaptation providers
// ---------------------------------------------------------------------------

/// Stacks injury adaptation on top of cycle adaptation.
///
/// Watches [adaptedActiveProgramProvider] (cycle-adapted) and applies
/// [InjuryAdaptationEngine.adaptProgram] when there are active injuries.
/// Returns the cycle-adapted program unchanged when no injuries are present
/// (zero-cost fast-path via [InjuryAdaptationEngine] same-reference return).
final Provider<AsyncValue<ProgramV2?>> injuryAdaptedActiveProgramProvider =
    Provider<AsyncValue<ProgramV2?>>((Ref ref) {
  final AsyncValue<ProgramV2?> cycleAdaptedAsync =
      ref.watch(adaptedActiveProgramProvider);
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);

  final List<InjuryProfileModel> activeInjuries =
      profileAsync.asData?.value?.activeInjuries ?? const [];

  return cycleAdaptedAsync.whenData((ProgramV2? program) {
    if (program == null || activeInjuries.isEmpty) return program;
    return InjuryAdaptationEngine.adaptProgram(
      baseProgram: program,
      activeInjuries: activeInjuries,
    );
  });
});

/// UI-facing context for injury adaptation state.
class InjuryAdaptationContext {
  const InjuryAdaptationContext({
    required this.hasActiveInjuries,
    required this.activeInjuries,
    required this.disclaimerAcknowledgedForAll,
  });

  final bool hasActiveInjuries;
  final List<InjuryProfileModel> activeInjuries;
  final bool disclaimerAcknowledgedForAll;
}

final Provider<InjuryAdaptationContext> injuryAdaptationContextProvider =
    Provider<InjuryAdaptationContext>((Ref ref) {
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);
  final UserModel? profile = profileAsync.asData?.value;
  final List<InjuryProfileModel> activeInjuries =
      profile?.activeInjuries ?? const [];

  return InjuryAdaptationContext(
    hasActiveInjuries: activeInjuries.isNotEmpty,
    activeInjuries: activeInjuries,
    disclaimerAcknowledgedForAll:
        profile?.hasAcknowledgedDisclaimerForAllActive(activeInjuries) ?? false,
  );
});
