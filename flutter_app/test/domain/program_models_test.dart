import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/exercise_definitions.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

void main() {
  group('Program models', () {
    test('ExerciseValue decodes int', () {
      final ExerciseValue value = ExerciseValue.fromJson(5);
      expect(value.type, ExerciseValueType.fixed);
      expect(value.fixedValue, 5);
    });

    test('ExerciseValue decodes AMRAP', () {
      final ExerciseValue value = ExerciseValue.fromJson('AMRAP');
      expect(value.type, ExerciseValueType.amrap);
    });

    test('ExerciseValue decodes range', () {
      final ExerciseValue value = ExerciseValue.fromJson(<int>[6, 8]);
      expect(value.type, ExerciseValueType.range);
      expect(value.minValue, 6);
      expect(value.maxValue, 8);
    });

    test('ExerciseValue displayString matches expected', () {
      expect(ExerciseValue.fixed(5).displayString, '5');
      expect(ExerciseValue.amrap().displayString, 'AMRAP');
      expect(ExerciseValue.range(6, 8).displayString, '6-8');
    });

    test('ProgramV2 decodes full JSON structure', () {
      final String json = '''
      {
        "id": "test-program",
        "name": "Test Program",
        "category": "back-squat",
        "description": "A test program",
        "durationWeeks": 4,
        "sessionsPerWeek": 3,
        "difficulty": "beginner",
        "phases": [
          {
            "id": "phase-1",
            "name": "Phase One",
            "goal": "Build base",
            "weekRange": [1, 4]
          }
        ],
        "weeks": [
          {
            "week": 1,
            "phaseId": "phase-1",
            "sessions": [
              {
                "sessionId": "w1-a",
                "sessionName": "Session A",
                "sessionType": "support",
                "focus": "Strength",
                "exercises": [
                  {
                    "exercise": "Back Squat",
                    "sets": 3,
                    "reps": 5,
                    "percent1RM": 0.70,
                    "restMinutes": 3
                  }
                ]
              }
            ]
          }
        ]
      }
      ''';

      final ProgramV2 program = ProgramV2.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(program.id, 'test-program');
      expect(program.name, 'Test Program');
      expect(program.durationWeeks, 4);
      expect(program.phases.length, 1);
      expect(program.weeks.length, 1);
      expect(program.weeks.first.sessions.first.exercises.length, 1);
      expect(
        program.weeks.first.sessions.first.exercises.first.exercise,
        'Back Squat',
      );
      expect(
        program.weeks.first.sessions.first.exercises.first.sets.type,
        ExerciseValueType.fixed,
      );
    });

    test('ProgramV2 defaults cycle adjustment profile for legacy JSON', () {
      final ProgramV2 legacyProgram = ProgramV2.fromJson(
        <String, dynamic>{
          'id': 'legacy-program',
          'name': 'Legacy Program',
          'category': 'Strength',
          'description': 'legacy',
          'durationWeeks': 4,
          'sessionsPerWeek': 3,
          'difficulty': 'Intermediate',
          'phases': const <dynamic>[],
          'weeks': const <dynamic>[],
        },
      );

      expect(legacyProgram.cycleAdjustmentProfile, isNull);
    });

    test('ProgramV2 round-trips full cycle adjustment profile', () {
      final ProgramV2 program = ProgramV2(
        id: 'cycle-program',
        name: 'Cycle Program',
        category: 'Strength',
        description: 'desc',
        durationWeeks: 8,
        sessionsPerWeek: 3,
        difficulty: 'Intermediate',
        phases: const <ProgramPhase>[],
        weeks: const <ProgramWeek>[],
        cycleAdjustmentProfile: ProgramCycleAdjustmentProfile(
          fallbackPhase: 'follicular',
          lowConfidenceScale: 0.6,
          phaseSettings: <String, ProgramPhaseAdjustmentSettings>{
            'menstrual': const ProgramPhaseAdjustmentSettings(
              loadMultiplier: 0.9,
              setsMultiplier: 0.9,
              repsMultiplier: 0.9,
            ),
            'ovulation': const ProgramPhaseAdjustmentSettings(
              loadMultiplier: 1.1,
              setsMultiplier: 1.05,
              repsMultiplier: 0.95,
            ),
          },
        ),
      );

      final ProgramV2 decoded = ProgramV2.fromJson(program.toJson());
      final ProgramCycleAdjustmentProfile? profile =
          decoded.cycleAdjustmentProfile;

      expect(profile, isNotNull);
      expect(profile!.fallbackPhase, 'follicular');
      expect(profile.lowConfidenceScale, closeTo(0.6, 0.0001));
      expect(profile.phaseSettings['menstrual']!.loadMultiplier, 0.9);
      expect(profile.phaseSettings['ovulation']!.setsMultiplier, 1.05);
    });

    test('ProgramV2 handles partial cycle adjustment profile with defaults',
        () {
      final ProgramV2 program = ProgramV2.fromJson(
        <String, dynamic>{
          'id': 'partial-program',
          'name': 'Partial Program',
          'category': 'Strength',
          'description': 'partial',
          'durationWeeks': 4,
          'sessionsPerWeek': 3,
          'difficulty': 'Intermediate',
          'phases': const <dynamic>[],
          'weeks': const <dynamic>[],
          'cycleAdjustmentProfile': <String, dynamic>{
            'phaseSettings': <String, dynamic>{
              'luteal': <String, dynamic>{'loadMultiplier': 0.96},
            },
          },
        },
      );

      final ProgramCycleAdjustmentProfile profile =
          program.cycleAdjustmentProfile!;
      final ProgramPhaseAdjustmentSettings lutealSettings =
          profile.phaseSettings['luteal']!;

      expect(profile.fallbackPhase, 'follicular');
      expect(profile.lowConfidenceScale, closeTo(0.7, 0.0001));
      expect(lutealSettings.loadMultiplier, 0.96);
      expect(lutealSettings.setsMultiplier, 1.0);
      expect(lutealSettings.repsMultiplier, 1.0);
    });

    test('Exercise definitions lookup works', () {
      final ExerciseDefinition? squat = Exercises.findById('Back Squat');
      expect(squat, isNotNull);
      expect(squat?.name, 'Back Squat');
      expect(Exercises.findById('nonexistent'), isNull);

      for (final ExerciseDefinition exercise in Exercises.all) {
        expect(exercise.id, isNotEmpty);
        expect(exercise.name, isNotEmpty);
        expect(exercise.category, isNotEmpty);
        expect(exercise.muscleGroups, isNotEmpty);
      }
    });

    test('EnrolledProgramModel defaults completedWeeks for legacy records', () {
      final EnrolledProgramModel model = EnrolledProgramModel.fromJson(
        <String, dynamic>{
          'id': 'enrollment-1',
          'programId': 'program-1',
          'startDate': '2026-01-01T00:00:00.000Z',
          'currentWeek': 2,
          'currentDay': 3,
          'isActive': true,
        },
      );

      expect(model.completedWeeks, isEmpty);
    });

    test('EnrolledProgramModel serializes completedWeeks and lastSyncedAt', () {
      final DateTime lastSyncedAt = DateTime.utc(2026, 2, 23, 12, 0, 0);
      final EnrolledProgramModel model = EnrolledProgramModel(
        id: 'enrollment-2',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 4,
        currentDay: 1,
        completedWeeks: const <int>[1, 2, 3],
        lastSyncedAt: lastSyncedAt,
      );

      final Map<String, dynamic> json = model.toJson();
      expect(json['completedWeeks'], <int>[1, 2, 3]);
      expect(json['lastSyncedAt'], lastSyncedAt.toIso8601String());
    });
  });
}
