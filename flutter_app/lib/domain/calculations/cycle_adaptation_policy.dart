import '../enums.dart';
import '../models/program_models.dart';

enum AdaptationReadinessTier { low, neutral, high }

enum AdaptationConfidence { low, medium, high }

class CycleAdaptationPolicy {
  const CycleAdaptationPolicy();

  static const Map<CyclePhase, ProgramPhaseAdjustmentSettings>
      _baselinePhaseSettings = <CyclePhase, ProgramPhaseAdjustmentSettings>{
    CyclePhase.menstrual: ProgramPhaseAdjustmentSettings(
      loadMultiplier: 0.9,
      setsMultiplier: 0.9,
      repsMultiplier: 0.9,
    ),
    CyclePhase.follicular: ProgramPhaseAdjustmentSettings(
      loadMultiplier: 1.0,
      setsMultiplier: 1.0,
      repsMultiplier: 1.0,
    ),
    CyclePhase.ovulation: ProgramPhaseAdjustmentSettings(
      loadMultiplier: 1.12,
      setsMultiplier: 1.05,
      repsMultiplier: 0.95,
    ),
    CyclePhase.luteal: ProgramPhaseAdjustmentSettings(
      loadMultiplier: 0.97,
      setsMultiplier: 0.95,
      repsMultiplier: 0.92,
    ),
  };

  static const Map<AdaptationReadinessTier, double> _readinessScales =
      <AdaptationReadinessTier, double>{
    AdaptationReadinessTier.low: 0.6,
    AdaptationReadinessTier.neutral: 1.0,
    AdaptationReadinessTier.high: 1.2,
  };

  static const Map<AdaptationConfidence, double> _confidenceScales =
      <AdaptationConfidence, double>{
    AdaptationConfidence.low: 0.55,
    AdaptationConfidence.medium: 0.8,
    AdaptationConfidence.high: 1.0,
  };

  AdaptationReadinessTier resolveReadinessTier({double? readinessScore}) {
    if (readinessScore == null) {
      return AdaptationReadinessTier.neutral;
    }
    if (readinessScore <= 3) {
      return AdaptationReadinessTier.low;
    }
    if (readinessScore >= 8) {
      return AdaptationReadinessTier.high;
    }
    return AdaptationReadinessTier.neutral;
  }

  double resolveConfidenceScale({
    required AdaptationConfidence confidence,
    ProgramCycleAdjustmentProfile? profile,
  }) {
    final double base = _confidenceScales[confidence] ?? 1.0;
    if (confidence != AdaptationConfidence.low) {
      return base;
    }

    final double profileScale = profile?.lowConfidenceScale ?? 0.7;
    return (base * profileScale).clamp(0.1, 1.0);
  }

  CyclePhase resolvePhase({
    required CyclePhase? currentPhase,
    required CyclePhase? lastKnownPhase,
    ProgramCycleAdjustmentProfile? profile,
  }) {
    if (currentPhase != null) {
      return currentPhase;
    }
    if (lastKnownPhase != null) {
      return lastKnownPhase;
    }
    final String fallback = profile?.fallbackPhase ?? 'follicular';
    return _phaseFromRaw(fallback) ?? CyclePhase.follicular;
  }

  AdaptationConfidence resolveConfidence({
    required CyclePhase? currentPhase,
    required CyclePhase? lastKnownPhase,
    required int periodLogCount,
    required DateTime? lastPeriodStart,
    DateTime? referenceDate,
  }) {
    if (periodLogCount == 0) {
      return AdaptationConfidence.low;
    }

    final DateTime now = referenceDate ?? DateTime.now();
    if (lastPeriodStart != null &&
        now.difference(lastPeriodStart).inDays > 45) {
      return AdaptationConfidence.low;
    }

    if (currentPhase != null && periodLogCount >= 3) {
      return AdaptationConfidence.high;
    }

    if (currentPhase != null) {
      return AdaptationConfidence.medium;
    }

    if (lastKnownPhase != null) {
      return AdaptationConfidence.low;
    }

    return AdaptationConfidence.low;
  }

  ProgramExercise applyPhaseAdjustment({
    required ProgramExercise exercise,
    required CyclePhase phase,
    required AdaptationReadinessTier readinessTier,
    required AdaptationConfidence confidence,
    required ProgramCycleAdjustmentProfile? profile,
  }) {
    final ProgramPhaseAdjustmentSettings targetSettings =
        _resolvePhaseSettings(phase: phase, profile: profile);
    final double readinessScale = _readinessScales[readinessTier] ?? 1.0;
    final double confidenceScale = resolveConfidenceScale(
      confidence: confidence,
      profile: profile,
    );

    final double loadMultiplier = _blendMultiplier(
      targetMultiplier: targetSettings.loadMultiplier,
      readinessScale: readinessScale,
      confidenceScale: confidenceScale,
    );
    final double setsMultiplier = _blendMultiplier(
      targetMultiplier: targetSettings.setsMultiplier,
      readinessScale: readinessScale,
      confidenceScale: confidenceScale,
    );
    final double repsMultiplier = _blendMultiplier(
      targetMultiplier: targetSettings.repsMultiplier,
      readinessScale: readinessScale,
      confidenceScale: confidenceScale,
    );

    return ProgramExercise(
      exercise: exercise.exercise,
      variant: exercise.variant,
      sets: _scaleExerciseValue(exercise.sets, setsMultiplier),
      reps: _scaleExerciseValue(exercise.reps, repsMultiplier),
      percent1Rm: exercise.percent1Rm == null
          ? null
          : _clampPercent1Rm(exercise.percent1Rm! * loadMultiplier),
      restMinutes: exercise.restMinutes,
      notes: exercise.notes,
    );
  }

  ProgramPhaseAdjustmentSettings _resolvePhaseSettings({
    required CyclePhase phase,
    required ProgramCycleAdjustmentProfile? profile,
  }) {
    final ProgramPhaseAdjustmentSettings? profileSetting =
        profile?.phaseSettings[phase.name];
    return profileSetting ?? _baselinePhaseSettings[phase]!;
  }

  double _blendMultiplier({
    required double targetMultiplier,
    required double readinessScale,
    required double confidenceScale,
  }) {
    final double direction = targetMultiplier - 1.0;
    final double weighted =
        1.0 + (direction * readinessScale * confidenceScale);
    return weighted.clamp(0.75, 1.25);
  }

  ExerciseValue _scaleExerciseValue(ExerciseValue value, double multiplier) {
    switch (value.type) {
      case ExerciseValueType.fixed:
        final int base = value.fixedValue ?? 1;
        final int adjusted = (base * multiplier).round().clamp(1, 20);
        return ExerciseValue.fixed(adjusted);
      case ExerciseValueType.range:
        final int baseMin = value.minValue ?? 1;
        final int baseMax = value.maxValue ?? baseMin;
        final int adjustedMin = (baseMin * multiplier).round().clamp(1, 20);
        final int adjustedMax = (baseMax * multiplier).round().clamp(1, 20);
        final int minValue =
            adjustedMin <= adjustedMax ? adjustedMin : adjustedMax;
        final int maxValue =
            adjustedMax >= adjustedMin ? adjustedMax : adjustedMin;
        return ExerciseValue.range(minValue, maxValue);
      case ExerciseValueType.amrap:
      case ExerciseValueType.text:
        return value;
    }
  }

  double _clampPercent1Rm(double value) {
    return value.clamp(0.4, 1.1);
  }

  CyclePhase? _phaseFromRaw(String raw) {
    for (final CyclePhase phase in CyclePhase.values) {
      if (phase.name == raw) {
        return phase;
      }
    }
    return null;
  }
}
