import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_program_generator.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

ProgramV2 _baseProgram() {
  return ProgramV2(
    id: 'program-1',
    name: 'Base Program',
    category: 'Strength',
    description: 'desc',
    durationWeeks: 2,
    sessionsPerWeek: 2,
    difficulty: 'Intermediate',
    phases: const <ProgramPhase>[],
    weeks: <ProgramWeek>[
      ProgramWeek(
        week: 1,
        phaseId: null,
        isTestWeek: false,
        sessions: <ProgramSession>[
          ProgramSession(
            sessionId: 'w1-heavy',
            sessionName: 'Sunday Heavy',
            sessionType: 'Lift',
            focus: 'Sundee-Fundee - Volume',
            exercises: <ProgramExercise>[
              ProgramExercise(
                exercise: 'Back Squat',
                variant: null,
                sets: ExerciseValue.fixed(4),
                reps: ExerciseValue.fixed(5),
                percent1Rm: 0.80,
                restMinutes: 3,
                notes: null,
              ),
            ],
          ),
          ProgramSession(
            sessionId: 'w1-accessory',
            sessionName: 'Accessory Session',
            sessionType: 'Lift',
            focus: 'Accessories',
            exercises: <ProgramExercise>[
              ProgramExercise(
                exercise: 'Walking Lunges',
                variant: null,
                sets: ExerciseValue.fixed(3),
                reps: ExerciseValue.fixed(10),
                percent1Rm: null,
                restMinutes: 2,
                notes: null,
              ),
            ],
          ),
        ],
      ),
      ProgramWeek(
        week: 2,
        phaseId: null,
        isTestWeek: false,
        sessions: const <ProgramSession>[],
      ),
    ],
  );
}

void main() {
  group('CycleProgramGenerator', () {
    test('phase matrix returns deterministic heavy-day prescriptions', () {
      final List<ProgramExercise> menstrual =
          CycleProgramGenerator.generateSundayWorkout(CyclePhase.menstrual);
      final List<ProgramExercise> follicular =
          CycleProgramGenerator.generateSundayWorkout(CyclePhase.follicular);
      final List<ProgramExercise> ovulation =
          CycleProgramGenerator.generateSundayWorkout(CyclePhase.ovulation);
      final List<ProgramExercise> luteal =
          CycleProgramGenerator.generateSundayWorkout(CyclePhase.luteal);

      expect(menstrual, hasLength(1));
      expect(follicular, hasLength(1));
      expect(ovulation, hasLength(1));
      expect(luteal, hasLength(1));
      expect(ovulation.first.percent1Rm,
          greaterThan(follicular.first.percent1Rm!));
      expect(
          menstrual.first.percent1Rm, lessThan(follicular.first.percent1Rm!));
    });

    test(
        'adaptProgram preserves week/session identity and only changes target sessions',
        () {
      final ProgramV2 base = _baseProgram();
      final ProgramV2 adapted = CycleProgramGenerator.adaptProgram(
        baseProgram: base,
        currentPhase: CyclePhase.ovulation,
        lastKnownPhase: CyclePhase.follicular,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
      );

      expect(adapted.id, base.id);
      expect(adapted.name, base.name);
      expect(adapted.weeks.length, base.weeks.length);
      expect(adapted.weeks.first.sessions.first.sessionId, 'w1-heavy');
      expect(adapted.weeks.first.sessions.last.sessionId, 'w1-accessory');

      final ProgramExercise adaptedHeavy =
          adapted.weeks.first.sessions.first.exercises.first;
      final ProgramExercise baseHeavy =
          base.weeks.first.sessions.first.exercises.first;

      expect(adaptedHeavy.percent1Rm, greaterThan(baseHeavy.percent1Rm!));

      final ProgramExercise adaptedAccessory =
          adapted.weeks.first.sessions.last.exercises.first;
      final ProgramExercise baseAccessory =
          base.weeks.first.sessions.last.exercises.first;
      expect(adaptedAccessory.sets.displayString,
          baseAccessory.sets.displayString);
      expect(adaptedAccessory.reps.displayString,
          baseAccessory.reps.displayString);
    });

    test(
        'adaptProgram falls back to last known phase when current phase is missing',
        () {
      final ProgramV2 base = _baseProgram();

      final ProgramV2 fromFallback = CycleProgramGenerator.adaptProgram(
        baseProgram: base,
        currentPhase: null,
        lastKnownPhase: CyclePhase.luteal,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
      );
      final ProgramV2 fromLuteal = CycleProgramGenerator.adaptProgram(
        baseProgram: base,
        currentPhase: CyclePhase.luteal,
        lastKnownPhase: null,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
      );

      final double fallbackLoad =
          fromFallback.weeks.first.sessions.first.exercises.first.percent1Rm!;
      final double lutealLoad =
          fromLuteal.weeks.first.sessions.first.exercises.first.percent1Rm!;

      expect(fallbackLoad, closeTo(lutealLoad, 0.0001));
    });

    test('low confidence reduces adaptation magnitude', () {
      final ProgramV2 base = _baseProgram();
      final ProgramV2 highConfidence = CycleProgramGenerator.adaptProgram(
        baseProgram: base,
        currentPhase: CyclePhase.ovulation,
        lastKnownPhase: null,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
      );
      final ProgramV2 lowConfidence = CycleProgramGenerator.adaptProgram(
        baseProgram: base,
        currentPhase: CyclePhase.ovulation,
        lastKnownPhase: null,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.low,
      );

      final double baseLoad =
          base.weeks.first.sessions.first.exercises.first.percent1Rm!;
      final double highLoad =
          highConfidence.weeks.first.sessions.first.exercises.first.percent1Rm!;
      final double lowLoad =
          lowConfidence.weeks.first.sessions.first.exercises.first.percent1Rm!;

      expect((lowLoad - baseLoad).abs(), lessThan((highLoad - baseLoad).abs()));
    });
  });
}
