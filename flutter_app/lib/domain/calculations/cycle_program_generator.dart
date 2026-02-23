import '../enums.dart';
import '../models/cycle_models.dart';
import '../models/program_models.dart';
import 'cycle_adaptation_policy.dart';
import 'cycle_calculations.dart';

class CycleProgramGenerator {
  static const CycleAdaptationPolicy _policy = CycleAdaptationPolicy();

  static final ProgramExercise _heavySessionTemplate = ProgramExercise(
    exercise: 'Back Squat',
    variant: null,
    sets: ExerciseValue.fixed(4),
    reps: ExerciseValue.fixed(5),
    percent1Rm: 0.8,
    restMinutes: 3.0,
    notes: 'Cycle-aware heavy day template.',
  );

  /// Builds a deterministic heavy-day prescription from the policy table.
  static List<ProgramExercise> generateSundayWorkout(CyclePhase phase) {
    return <ProgramExercise>[
      _policy.applyPhaseAdjustment(
        exercise: _heavySessionTemplate,
        phase: phase,
        readinessTier: AdaptationReadinessTier.neutral,
        confidence: AdaptationConfidence.high,
        profile: null,
      ),
    ];
  }

  /// Adapts all target sessions in a program for the current phase context.
  static ProgramV2 adaptProgram({
    required ProgramV2 baseProgram,
    required CyclePhase? currentPhase,
    required CyclePhase? lastKnownPhase,
    required AdaptationReadinessTier readinessTier,
    required AdaptationConfidence confidence,
  }) {
    final CyclePhase resolvedPhase = _policy.resolvePhase(
      currentPhase: currentPhase,
      lastKnownPhase: lastKnownPhase,
      profile: baseProgram.cycleAdjustmentProfile,
    );

    final List<ProgramWeek> adaptedWeeks = baseProgram.weeks
        .map(
          (ProgramWeek week) => _adaptWeek(
            week: week,
            phase: resolvedPhase,
            readinessTier: readinessTier,
            confidence: confidence,
            profile: baseProgram.cycleAdjustmentProfile,
          ),
        )
        .toList();

    return _copyProgram(baseProgram: baseProgram, adaptedWeeks: adaptedWeeks);
  }

  /// Main function to build a cycle-aware program from logged cycle data.
  static ProgramV2 generateWomensProgram(
    ProgramV2 baseProgram,
    CycleSettingsModel settings,
    List<PeriodLogModel> periodLogs,
    DateTime programStartDate,
  ) {
    final List<PeriodLogModel> sortedLogs =
        List<PeriodLogModel>.from(periodLogs)
          ..sort((PeriodLogModel a, PeriodLogModel b) {
            return b.startDate.compareTo(a.startDate);
          });
    final DateTime? lastPeriodStart =
        sortedLogs.isEmpty ? null : sortedLogs.first.startDate;

    CyclePhase? lastKnownPhase;
    final List<ProgramWeek> adaptedWeeks = <ProgramWeek>[];

    for (int weekNum = 1; weekNum <= baseProgram.durationWeeks; weekNum += 1) {
      final DateTime sundayDate =
          programStartDate.add(Duration(days: ((weekNum - 1) * 7) + 6));

      final CycleStatusResult? status = CycleCalculations.calculateCycleStatus(
        periodLogs: periodLogs,
        settings: settings,
        referenceDate: sundayDate,
      );
      final CyclePhase? currentPhase = status?.currentPhase;
      if (currentPhase != null) {
        lastKnownPhase = currentPhase;
      }

      final AdaptationConfidence confidence = _policy.resolveConfidence(
        currentPhase: currentPhase,
        lastKnownPhase: lastKnownPhase,
        periodLogCount: periodLogs.length,
        lastPeriodStart: lastPeriodStart,
        referenceDate: sundayDate,
      );
      final CyclePhase resolvedPhase = _policy.resolvePhase(
        currentPhase: currentPhase,
        lastKnownPhase: lastKnownPhase,
        profile: baseProgram.cycleAdjustmentProfile,
      );

      final ProgramWeek baseWeek = baseProgram.weeks.firstWhere(
        (ProgramWeek week) => week.week == weekNum,
        orElse: () => baseProgram.weeks.last,
      );

      adaptedWeeks.add(
        _adaptWeek(
          week: baseWeek,
          phase: resolvedPhase,
          readinessTier: AdaptationReadinessTier.neutral,
          confidence: confidence,
          profile: baseProgram.cycleAdjustmentProfile,
        ),
      );
    }

    return _copyProgram(baseProgram: baseProgram, adaptedWeeks: adaptedWeeks);
  }

  static ProgramWeek _adaptWeek({
    required ProgramWeek week,
    required CyclePhase phase,
    required AdaptationReadinessTier readinessTier,
    required AdaptationConfidence confidence,
    required ProgramCycleAdjustmentProfile? profile,
  }) {
    final List<ProgramSession> adaptedSessions = week.sessions.map((
      ProgramSession session,
    ) {
      if (!_isAdaptableSession(session)) {
        return session;
      }

      final List<ProgramExercise> adaptedExercises = session.exercises.map(
        (ProgramExercise exercise) {
          return _policy.applyPhaseAdjustment(
            exercise: exercise,
            phase: phase,
            readinessTier: readinessTier,
            confidence: confidence,
            profile: profile,
          );
        },
      ).toList();

      return ProgramSession(
        sessionId: session.sessionId,
        sessionName: session.sessionName,
        sessionType: session.sessionType,
        focus: session.focus,
        exercises: adaptedExercises,
      );
    }).toList();

    return ProgramWeek(
      week: week.week,
      phaseId: week.phaseId,
      isTestWeek: week.isTestWeek,
      sessions: adaptedSessions,
    );
  }

  static bool _isAdaptableSession(ProgramSession session) {
    final String focus = session.focus.toLowerCase();
    final String name = session.sessionName.toLowerCase();
    return focus.contains('sundee-fundee') ||
        focus.contains('heavymainlift') ||
        name.contains('sundee-fundee');
  }

  static ProgramV2 _copyProgram({
    required ProgramV2 baseProgram,
    required List<ProgramWeek> adaptedWeeks,
  }) {
    return ProgramV2(
      id: baseProgram.id,
      name: baseProgram.name,
      category: baseProgram.category,
      description: baseProgram.description,
      durationWeeks: baseProgram.durationWeeks,
      sessionsPerWeek: baseProgram.sessionsPerWeek,
      difficulty: baseProgram.difficulty,
      phases: baseProgram.phases,
      weeks: adaptedWeeks,
      cycleAdjustmentProfile: baseProgram.cycleAdjustmentProfile,
    );
  }
}
