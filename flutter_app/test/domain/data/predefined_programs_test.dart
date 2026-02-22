import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/data/predefined_programs.dart';
import 'package:sundee_fundee_flutter/domain/models/exercise_definitions.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

void main() {
  group('PredefinedPrograms', () {
    final List<ProgramV2> programs = [
      PredefinedPrograms.baseline12Week,
      PredefinedPrograms.squat2Cycle,
      PredefinedPrograms.deadlift1Cycle,
      PredefinedPrograms.benchPress1Cycle,
      PredefinedPrograms.deadlift2Cycle,
    ];

    for (final program in programs) {
      test('Program ${program.id} has valid exercises', () {
        for (final week in program.weeks) {
          for (final session in week.sessions) {
            for (final exercise in session.exercises) {
              final definition = Exercises.findById(exercise.exercise);
              expect(
                definition,
                isNotNull,
                reason:
                    'Exercise "${exercise.exercise}" in program "${program.id}" (Week ${week.week}, Session ${session.sessionId}) not found in ExerciseDefinitions.',
              );
            }
          }
        }
      });
    }
  });
}
