import '../models/program_models.dart';
import '../models/cycle_models.dart';
import '../enums.dart';
import 'cycle_calculations.dart';

class CycleProgramGenerator {
  /// Generates the specific heavy Sunday workout based on the calculated phase.
  static List<ProgramExercise> generateSundayWorkout(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.ovulation:
        // Peak Strength -> MAX ATTEMPT
        return [
          ProgramExercise(
            exercise: 'high-bar-back-squat',
            variant: null,
            sets: ExerciseValue.fixed(1),
            reps: ExerciseValue.fixed(1),
            percent1Rm: 0.95, // 90-95% (Heavy Single)
            restMinutes: 4.0, // 3-5 minutes
            notes: "PEAK STRENGTH. Estrogen/Testosterone are peaking. Hit a heavy, clean single.",
          ),
        ];

      case CyclePhase.follicular:
        // High Energy -> VOLUME
        return [
          ProgramExercise(
            exercise: 'high-bar-back-squat',
            variant: null,
            sets: ExerciseValue.fixed(4),
            reps: ExerciseValue.fixed(5),
            percent1Rm: 0.80, // 75-80%
            restMinutes: 2.5, // 2-3 minutes
            notes: "High energy phase. Push the volume.",
          ),
        ];

      case CyclePhase.luteal:
        // High Temp / CNS Fatigue -> HEAVY BUT LOW REP
        return [
          ProgramExercise(
            exercise: 'high-bar-back-squat',
            variant: null,
            sets: ExerciseValue.fixed(3),
            reps: ExerciseValue.range(2, 3), // 2-3 reps Let's use 2 here, or a range if available.
            percent1Rm: 0.85,
            restMinutes: 3.5, // 3+ minutes
            notes: "Endurance is lower, but strength is maintained. Keep reps low to manage CNS fatigue.",
          ),
        ];

      case CyclePhase.menstrual:
        // Low Energy -> DELOAD
        return [
          ProgramExercise(
            exercise: 'high-bar-back-squat',
            variant: null,
            sets: ExerciseValue.fixed(4),
            reps: ExerciseValue.fixed(4),
            percent1Rm: 0.70,
            restMinutes: 1.5, // 90 seconds
            notes: "Auto-regulate today. Focus on speed and perfect depth.",
          ),
        ];
    }
  }

  /// Main function to build a 12-week program adapted for a user's cycle.
  /// It takes the base program and modifies the 'Sundee-Fundee' day according to the user's cycle status.
  static ProgramV2 generateWomensProgram(
    ProgramV2 baseProgram,
    CycleSettingsModel settings,
    List<PeriodLogModel> periodLogs,
    DateTime programStartDate, // e.g., the Monday they start
  ) {
    if (periodLogs.isEmpty) {
      // If we don't have enough data to predict cycles, just return the base program
      return baseProgram;
    }

    final List<ProgramWeek> adaptedWeeks = [];

    for (int weekNum = 1; weekNum <= baseProgram.durationWeeks; weekNum++) {
      // Find the Sunday of this week (assuming program starts on a Monday, Sunday is Day 6)
      // Since DateTime weekdays are: Monday=1 ... Sunday=7
      // If programStartDate is a Monday (1), Sunday is programStartDate + 6 days.
      // We will just calculate target Sunday as:
      final DateTime sundayDate = programStartDate.add(Duration(days: ((weekNum - 1) * 7) + 6));

      // What phase will they be in on that Sunday?
      final CycleStatusResult? status = CycleCalculations.calculateCycleStatus(
        periodLogs: periodLogs,
        settings: settings,
        referenceDate: sundayDate,
      );

      final CyclePhase currentPhase = status?.currentPhase ?? CyclePhase.menstrual;

      // Find the week in the base program
      final ProgramWeek baseWeek = baseProgram.weeks.firstWhere(
        (w) => w.week == weekNum,
        orElse: () => baseProgram.weeks.last,
      );

      final List<ProgramSession> adaptedSessions = [];

      for (var session in baseWeek.sessions) {
        if (session.focus == 'HeavyMainLift' || session.sessionName == 'Sundee-Fundee') {
          // Adapt the Sunday workout!
          final ProgramSession adaptedSession = ProgramSession(
            sessionId: session.sessionId,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus: session.focus,
            exercises: generateSundayWorkout(currentPhase),
          );
          adaptedSessions.add(adaptedSession);
        } else {
          // Keep the accessory days as is (or adapt volume if requested in the future)
          adaptedSessions.add(session);
        }
      }

      adaptedWeeks.add(
        ProgramWeek(
          week: baseWeek.week,
          phaseId: baseWeek.phaseId,
          isTestWeek: baseWeek.isTestWeek,
          sessions: adaptedSessions,
        ),
      );
    }

    return ProgramV2(
      id: '${baseProgram.id}-adapted',
      name: '${baseProgram.name} (Cycle-Adapted)',
      category: baseProgram.category,
      description: baseProgram.description,
      durationWeeks: baseProgram.durationWeeks,
      sessionsPerWeek: baseProgram.sessionsPerWeek,
      difficulty: baseProgram.difficulty,
      phases: baseProgram.phases,
      weeks: adaptedWeeks,
    );
  }
}
