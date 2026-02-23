import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/features/workouts/presentation/workout_execution_providers.dart';

ProgramV2 _buildProgram({required int sessionsPerWeek}) {
  final List<ProgramSession> sessions = List<ProgramSession>.generate(
    sessionsPerWeek,
    (int index) => ProgramSession(
      sessionId: 's-${index + 1}',
      sessionName: 'Session ${index + 1}',
      sessionType: 'Lift',
      focus: 'Strength',
      exercises: <ProgramExercise>[
        ProgramExercise(
          exercise: 'Back Squat',
          variant: null,
          sets: ExerciseValue.fixed(3),
          reps: ExerciseValue.fixed(5),
          percent1Rm: 0.75,
          restMinutes: 3,
          notes: null,
        ),
      ],
    ),
  );

  return ProgramV2(
    id: 'program-1',
    name: 'Program',
    category: 'Squat',
    description: 'desc',
    durationWeeks: 12,
    sessionsPerWeek: sessionsPerWeek,
    difficulty: 'Intermediate',
    phases: <ProgramPhase>[],
    weeks: <ProgramWeek>[
      ProgramWeek(
        week: 1,
        phaseId: null,
        isTestWeek: false,
        sessions: sessions,
      ),
    ],
  );
}

void main() {
  group('recommendNextEnrollmentProgress', () {
    test('advances day within the same week for non-final session', () {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: 'enrollment-1',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 1,
        currentDay: 1,
      );
      final ProgramV2 program = _buildProgram(sessionsPerWeek: 3);

      final EnrollmentProgress recommendation = recommendNextEnrollmentProgress(
        enrollment: enrollment,
        program: program,
      );

      expect(recommendation.week, 1);
      expect(recommendation.day, 2);
    });

    test('does not auto-advance week when final day is completed', () {
      final EnrolledProgramModel enrollment = EnrolledProgramModel(
        id: 'enrollment-1',
        programId: 'program-1',
        startDate: DateTime.utc(2026, 1, 1),
        currentWeek: 1,
        currentDay: 3,
      );
      final ProgramV2 program = _buildProgram(sessionsPerWeek: 3);

      final EnrollmentProgress recommendation = recommendNextEnrollmentProgress(
        enrollment: enrollment,
        program: program,
      );

      expect(recommendation.week, 1);
      expect(recommendation.day, 3);
    });
  });
}
