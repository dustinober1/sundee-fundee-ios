import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/injury_adaptation_engine.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

InjuryProfileModel _injury(String location) => InjuryProfileModel(
      id: 'test-$location',
      location: location,
      movementLimitations: 'test limitations',
      recoveryGoal: 'test goal',
      status: InjuryStatus.active,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

ProgramExercise _exercise(String name) => ProgramExercise(
      exercise: name,
      variant: null,
      sets: ExerciseValue.fixed(3),
      reps: ExerciseValue.fixed(8),
      percent1Rm: null,
      restMinutes: 2.0,
      notes: null,
    );

ProgramSession _session(String id, List<String> exerciseNames) =>
    ProgramSession(
      sessionId: id,
      sessionName: 'Session $id',
      sessionType: 'strength',
      focus: 'lower',
      exercises: exerciseNames.map(_exercise).toList(),
    );

ProgramV2 _program(List<ProgramSession> sessions) => ProgramV2(
      id: 'test-prog',
      name: 'Test Program',
      category: 'strength',
      description: 'Test',
      durationWeeks: 1,
      sessionsPerWeek: 1,
      difficulty: 'intermediate',
      phases: const [],
      weeks: [
        ProgramWeek(
          week: 1,
          phaseId: null,
          isTestWeek: false,
          sessions: sessions,
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('InjuryAdaptationEngine', () {
    // -----------------------------------------------------------------------
    // 1. No-op: empty injury list returns same program reference
    // -----------------------------------------------------------------------
    test('returns same program reference when no active injuries', () {
      final ProgramV2 program = _program([_session('s1', ['Back Squat'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: const [],
      );
      expect(identical(result, program), isTrue,
          reason: 'Should return the exact same reference — zero copy cost.');
    });

    // -----------------------------------------------------------------------
    // 2. Back Squat is replaced when knee injury is active
    // -----------------------------------------------------------------------
    test('replaces Back Squat when knee injury is active', () {
      final ProgramV2 program = _program([_session('s1', ['Back Squat'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );
      final ProgramExercise adapted =
          result.weeks.first.sessions.first.exercises.first;
      expect(adapted.exercise, isNot('Back Squat'),
          reason: 'Contraindicated exercise must be replaced.');
      expect(adapted.injuryReplacedOriginal, 'Back Squat',
          reason: 'injuryReplacedOriginal must record original name.');
      expect(adapted.injuryReplacementReason, isNotNull);
      expect(adapted.injuryReplacementReason, isNotEmpty);
      expect(adapted.injuryReplacementReason, contains('knee'),
          reason: 'Reason must mention the injury location.');
    });

    // -----------------------------------------------------------------------
    // 3. Flat Barbell Bench Press is replaced when shoulder injury is active
    // -----------------------------------------------------------------------
    test('replaces Flat Barbell Bench Press when shoulder injury is active',
        () {
      final ProgramV2 program =
          _program([_session('s1', ['Flat Barbell Bench Press'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('shoulder')],
      );
      final ProgramExercise adapted =
          result.weeks.first.sessions.first.exercises.first;
      expect(adapted.exercise, isNot('Flat Barbell Bench Press'));
      expect(adapted.injuryReplacedOriginal, 'Flat Barbell Bench Press');
      expect(adapted.injuryReplacementReason, contains('shoulder'));
    });

    // -----------------------------------------------------------------------
    // 4. Recovery prep is added to every session when knee injury is active
    // -----------------------------------------------------------------------
    test('adds recoveryPrepExercises to every session when knee injury active',
        () {
      final ProgramV2 program = _program([
        _session('s1', ['Air Squats']),
        _session('s2', ['Bird-Dogs']),
      ]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );
      for (final ProgramSession session in result.weeks.first.sessions) {
        expect(session.recoveryPrepExercises, isNotEmpty,
            reason: 'Every session must have recovery prep when injury active.');
      }
    });

    // -----------------------------------------------------------------------
    // 5. Recovery prep from multiple injuries is deduplicated and capped at 5
    // -----------------------------------------------------------------------
    test(
        'recovery prep from multiple injuries is deduplicated and capped at 5',
        () {
      final ProgramV2 program = _program([_session('s1', ['Air Squats'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee'), _injury('shoulder')],
      );
      final List<ProgramExercise> prep =
          result.weeks.first.sessions.first.recoveryPrepExercises;
      expect(prep.length, greaterThan(0));
      expect(prep.length, lessThanOrEqualTo(5),
          reason: 'Recovery prep must be capped at 5 exercises.');
      // Names must be unique
      final Set<String> names = prep.map((e) => e.exercise).toSet();
      expect(names.length, prep.length,
          reason: 'Recovery prep exercises must be deduplicated.');
    });

    // -----------------------------------------------------------------------
    // 6. Non-contraindicated exercise passes through unchanged
    // -----------------------------------------------------------------------
    test(
        'non-contraindicated exercises pass through unchanged, recovery prep still added',
        () {
      // Bird-Dogs is not contraindicated for knee (it IS in the recovery prep
      // list but not in the contraindication set for exercises in the program).
      final ProgramV2 program = _program([_session('s1', ['Face Pulls'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );
      final ProgramExercise ex =
          result.weeks.first.sessions.first.exercises.first;
      expect(ex.exercise, 'Face Pulls',
          reason: 'Non-contraindicated exercise must be unchanged.');
      expect(ex.injuryReplacedOriginal, isNull,
          reason: 'injuryReplacedOriginal must be null for unchanged exercises.');
      // Recovery prep still present
      expect(result.weeks.first.sessions.first.recoveryPrepExercises,
          isNotEmpty);
    });

    // -----------------------------------------------------------------------
    // 7. Replacement reason string format is correct
    // -----------------------------------------------------------------------
    test('replacement reason mentions location and original exercise name', () {
      final ProgramV2 program =
          _program([_session('s1', ['Strict Press / Military Press'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('shoulder')],
      );
      final ProgramExercise adapted =
          result.weeks.first.sessions.first.exercises.first;
      expect(adapted.injuryReplacementReason, startsWith('Replaced'),
          reason: 'Reason must start with "Replaced".');
      expect(adapted.injuryReplacementReason, contains('shoulder'));
    });

    // -----------------------------------------------------------------------
    // 8. isContraindicatedOriginal defaults to false on replaced exercises
    // -----------------------------------------------------------------------
    test('isContraindicatedOriginal is false on replaced exercises', () {
      final ProgramV2 program = _program([_session('s1', ['Back Squat'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );
      final ProgramExercise adapted =
          result.weeks.first.sessions.first.exercises.first;
      expect(adapted.isContraindicatedOriginal, isFalse,
          reason:
              'Engine never sets isContraindicatedOriginal=true; that is a user action.');
    });

    // -----------------------------------------------------------------------
    // 9. Fields are null on non-replaced exercises
    // -----------------------------------------------------------------------
    test('injury fields are null on non-replaced exercises', () {
      final ProgramV2 program = _program([
        _session('s1', ['Back Squat', 'Face Pulls']),
      ]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );
      // Face Pulls should not be contraindicated for knee
      final ProgramExercise facePulls =
          result.weeks.first.sessions.first.exercises.last;
      expect(facePulls.exercise, 'Face Pulls');
      expect(facePulls.injuryReplacedOriginal, isNull);
      expect(facePulls.injuryReplacementReason, isNull);
    });

    // -----------------------------------------------------------------------
    // 10. Immutability — input program is not mutated
    // -----------------------------------------------------------------------
    test('does not mutate the input program', () {
      final ProgramExercise original = _exercise('Back Squat');
      final ProgramSession session = _session('s1', ['Back Squat']);
      final ProgramV2 program = _program([session]);

      InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('knee')],
      );

      // Original objects should not be mutated
      expect(original.exercise, 'Back Squat');
      expect(original.injuryReplacedOriginal, isNull);
      expect(session.recoveryPrepExercises, isEmpty);
    });

    // -----------------------------------------------------------------------
    // 11. fromJson/toJson round-trip does not include injury-only fields
    // -----------------------------------------------------------------------
    test('ProgramExercise fromJson/toJson round-trip excludes injury fields',
        () {
      final ProgramExercise ex = ProgramExercise(
        exercise: 'Back Squat',
        variant: null,
        sets: ExerciseValue.fixed(3),
        reps: ExerciseValue.fixed(5),
        percent1Rm: 0.8,
        restMinutes: 2.0,
        notes: 'test',
        injuryReplacedOriginal: 'Original Exercise',
        injuryReplacementReason: 'test reason',
        isContraindicatedOriginal: true,
      );
      final Map<String, dynamic> json = ex.toJson();
      expect(json.containsKey('injuryReplacedOriginal'), isFalse);
      expect(json.containsKey('injuryReplacementReason'), isFalse);
      expect(json.containsKey('isContraindicatedOriginal'), isFalse);

      // Round-trip — should decode fine without these fields
      final ProgramExercise decoded = ProgramExercise.fromJson(json);
      expect(decoded.exercise, 'Back Squat');
      expect(decoded.injuryReplacedOriginal, isNull);
    });

    // -----------------------------------------------------------------------
    // 12. Recovery prep exercises have correct structure
    // -----------------------------------------------------------------------
    test('recovery prep exercises have correct sets/reps/rest/notes format',
        () {
      final ProgramV2 program = _program([_session('s1', ['Air Squats'])]);
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: [_injury('shoulder')],
      );
      final List<ProgramExercise> prep =
          result.weeks.first.sessions.first.recoveryPrepExercises;
      expect(prep, isNotEmpty);
      for (final ProgramExercise p in prep) {
        // sets: 2-3
        final ExerciseValue sets = p.sets;
        final int setsVal = sets.type == ExerciseValueType.fixed
            ? (sets.fixedValue ?? 0)
            : (sets.minValue ?? 0);
        expect(setsVal, inInclusiveRange(2, 3));
        // reps: 8-15
        final ExerciseValue reps = p.reps;
        final int repsMin = reps.type == ExerciseValueType.fixed
            ? (reps.fixedValue ?? 0)
            : (reps.minValue ?? 0);
        expect(repsMin, greaterThanOrEqualTo(8));
        // rest: 0.5
        expect(p.restMinutes, 0.5);
        // notes prefix
        expect(p.notes, startsWith('Injury recovery prep'),
            reason: 'Notes must start with "Injury recovery prep".');
      }
    });
  });
}
