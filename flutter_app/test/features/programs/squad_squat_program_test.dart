import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/programs/data/squad_squat_program.dart';
import 'package:sundee_fundee_flutter/domain/models/exercise_definitions.dart';

void main() {
  group('Squad Squat Program', () {
    test('squadSquatProgram is correctly defined', () {
      expect(squadSquatProgram.id, 'squad-squat-12-week-peak');
      expect(squadSquatProgram.durationWeeks, 12);
      expect(squadSquatProgram.weeks.length, 12);
    });

    test('All exercises in squadSquatProgram exist in Exercises.all', () {
      final Set<String> exerciseIds = <String>{};
      for (var week in squadSquatProgram.weeks) {
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

    test('Week 12 Session C is the 1RM test', () {
      final week12 = squadSquatProgram.weeks.firstWhere((w) => w.week == 12);
      final sessionC = week12.sessions.firstWhere((s) => s.sessionId == 'ss-w12-c');
      
      expect(sessionC.sessionName, contains('Session C'));
      expect(sessionC.exercises.first.exercise, 'Back Squat');
      expect(sessionC.exercises.first.reps.fixedValue, 1);
    });
  });
}
