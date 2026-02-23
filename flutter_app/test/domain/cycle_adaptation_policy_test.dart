import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

void main() {
  group('CycleAdaptationPolicy', () {
    const CycleAdaptationPolicy policy = CycleAdaptationPolicy();

    test('resolveReadinessTier maps score buckets deterministically', () {
      expect(
        policy.resolveReadinessTier(readinessScore: 2),
        AdaptationReadinessTier.low,
      );
      expect(
        policy.resolveReadinessTier(readinessScore: 6),
        AdaptationReadinessTier.neutral,
      );
      expect(
        policy.resolveReadinessTier(readinessScore: 9),
        AdaptationReadinessTier.high,
      );
      expect(
        policy.resolveReadinessTier(readinessScore: null),
        AdaptationReadinessTier.neutral,
      );
    });

    test('resolveConfidenceScale decreases adjustment magnitude', () {
      final double high = policy.resolveConfidenceScale(
        confidence: AdaptationConfidence.high,
      );
      final double medium = policy.resolveConfidenceScale(
        confidence: AdaptationConfidence.medium,
      );
      final double low = policy.resolveConfidenceScale(
        confidence: AdaptationConfidence.low,
      );

      expect(high, greaterThan(medium));
      expect(medium, greaterThan(low));
    });

    test('resolvePhase falls back to last known then conservative phase', () {
      expect(
        policy.resolvePhase(
          currentPhase: CyclePhase.ovulation,
          lastKnownPhase: CyclePhase.menstrual,
        ),
        CyclePhase.ovulation,
      );

      expect(
        policy.resolvePhase(
          currentPhase: null,
          lastKnownPhase: CyclePhase.luteal,
        ),
        CyclePhase.luteal,
      );

      expect(
        policy.resolvePhase(
          currentPhase: null,
          lastKnownPhase: null,
        ),
        CyclePhase.follicular,
      );
    });

    test(
      'applyPhaseAdjustment keeps phase direction and uses readiness for magnitude',
      () {
        final ProgramExercise base = ProgramExercise(
          exercise: 'Back Squat',
          variant: null,
          sets: ExerciseValue.fixed(4),
          reps: ExerciseValue.fixed(5),
          percent1Rm: 0.8,
          restMinutes: 3,
          notes: null,
        );

        final ProgramExercise ovulationLowReadiness =
            policy.applyPhaseAdjustment(
          exercise: base,
          phase: CyclePhase.ovulation,
          readinessTier: AdaptationReadinessTier.low,
          confidence: AdaptationConfidence.high,
          profile: null,
        );
        final ProgramExercise ovulationHighReadiness =
            policy.applyPhaseAdjustment(
          exercise: base,
          phase: CyclePhase.ovulation,
          readinessTier: AdaptationReadinessTier.high,
          confidence: AdaptationConfidence.high,
          profile: null,
        );

        expect(ovulationLowReadiness.percent1Rm, greaterThan(base.percent1Rm!));
        expect(
          ovulationHighReadiness.percent1Rm,
          greaterThan(ovulationLowReadiness.percent1Rm!),
        );
      },
    );

    test('low confidence scales phase adjustments conservatively', () {
      final ProgramExercise base = ProgramExercise(
        exercise: 'Back Squat',
        variant: null,
        sets: ExerciseValue.fixed(4),
        reps: ExerciseValue.fixed(5),
        percent1Rm: 0.8,
        restMinutes: 3,
        notes: null,
      );

      final ProgramExercise highConfidence = policy.applyPhaseAdjustment(
        exercise: base,
        phase: CyclePhase.menstrual,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
        profile: null,
      );
      final ProgramExercise lowConfidence = policy.applyPhaseAdjustment(
        exercise: base,
        phase: CyclePhase.menstrual,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.low,
        profile: null,
      );

      final double highDelta =
          (highConfidence.percent1Rm! - base.percent1Rm!).abs();
      final double lowDelta =
          (lowConfidence.percent1Rm! - base.percent1Rm!).abs();

      expect(lowDelta, lessThan(highDelta));
    });
  });
}
