import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/data/back_squat_program.dart';
import 'package:sundee_fundee_flutter/domain/models/exercise_definitions.dart';

void main() {
  group('Back Squat Program', () {
    test('backSquatProgram is correctly defined', () {
      expect(backSquatProgram.id, 'back-squat-8-week-peak');
      expect(backSquatProgram.durationWeeks, 8);
      expect(backSquatProgram.weeks.length, 8);
    });

    test('All exercises in backSquatProgram exist in Exercises.all', () {
      final Set<String> exerciseIds = <String>{};
      for (var week in backSquatProgram.weeks) {
        for (var session in week.sessions) {
          for (var exercise in session.exercises) {
            exerciseIds.add(exercise.exercise);
          }
        }
      }

      for (var id in exerciseIds) {
        final ExerciseDefinition? definition = Exercises.findById(id);
        expect(definition, isNotNull, reason: 'Exercise $id not found in definitions');
      }
    });

    test('Week 8 Session C is the 1RM test', () {
      final week8 = backSquatProgram.weeks.firstWhere((w) => w.week == 8);
      final sessionC = week8.sessions.firstWhere((s) => s.sessionId == 'bs-w8-c');
      
      expect(sessionC.sessionName, contains('Session C'));
      expect(sessionC.exercises.first.exercise, 'back-squat');
      expect(sessionC.exercises.first.reps.fixedValue, 1);
    });
  });
}
