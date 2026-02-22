import '../enums.dart';
import '../models/cycle_models.dart';

class CycleStatusResult {
  const CycleStatusResult({
    required this.currentPhase,
    required this.cycleDay,
    required this.daysUntilNextPhase,
    required this.predictedNextPeriod,
    required this.phaseStartDate,
    required this.phaseEndDate,
  });

  final CyclePhase currentPhase;
  final int cycleDay;
  final int daysUntilNextPhase;
  final DateTime predictedNextPeriod;
  final DateTime phaseStartDate;
  final DateTime phaseEndDate;
}

class PhaseBoundary {
  const PhaseBoundary({required this.start, required this.end});

  final int start;
  final int end;
}

class PhaseRecommendation {
  const PhaseRecommendation({
    required this.phase,
    required this.title,
    required this.description,
    required this.trainingFocus,
    required this.intensityRecommendation,
    required this.exercisesToEmphasize,
    required this.exercisesToAvoid,
  });

  final CyclePhase phase;
  final String title;
  final String description;
  final String trainingFocus;
  final String intensityRecommendation;
  final List<String> exercisesToEmphasize;
  final List<String> exercisesToAvoid;
}

class PhasePerformance {
  const PhasePerformance({
    required this.phase,
    required this.avgPerformanceDelta,
    required this.sampleSize,
  });

  final CyclePhase phase;
  final double avgPerformanceDelta;
  final int sampleSize;
}

class PhaseStrengthProfile {
  const PhaseStrengthProfile({
    required this.userId,
    required this.phases,
    required this.strongestPhase,
    required this.weakestPhase,
    required this.confidence,
  });

  final String userId;
  final List<PhasePerformance> phases;
  final CyclePhase strongestPhase;
  final CyclePhase weakestPhase;
  final double confidence;
}

class StrengthWindow {
  const StrengthWindow({
    required this.startDate,
    required this.endDate,
    required this.confidence,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double confidence;
}

class CycleCalculations {
  const CycleCalculations._();

  static CycleStatusResult? calculateCycleStatus({
    required List<PeriodLogModel> periodLogs,
    required CycleSettingsModel settings,
    DateTime? referenceDate,
  }) {
    if (periodLogs.isEmpty) {
      return null;
    }

    final DateTime effectiveReference = _startOfDay(
      referenceDate ?? DateTime.now(),
    );
    final List<PeriodLogModel> sortedPeriods =
        List<PeriodLogModel>.from(periodLogs)
          ..sort((PeriodLogModel a, PeriodLogModel b) {
            return b.startDate.compareTo(a.startDate);
          });

    DateTime? cycleStartDate;

    for (final PeriodLogModel period in sortedPeriods) {
      final DateTime periodStart = _startOfDay(period.startDate);
      final DateTime periodEnd = period.endDate != null
          ? _startOfDay(period.endDate!)
          : _addDays(periodStart, settings.averagePeriodLength - 1);

      if (_isWithin(effectiveReference, periodStart, periodEnd)) {
        cycleStartDate = periodStart;
        break;
      }

      final DateTime nextExpected = _addDays(
        periodStart,
        settings.averageCycleLength,
      );
      if (effectiveReference.isAfter(periodEnd) &&
          effectiveReference.isBefore(nextExpected)) {
        cycleStartDate = periodStart;
        break;
      }
    }

    if (cycleStartDate == null) {
      final PeriodLogModel mostRecent = sortedPeriods.first;
      var start = _startOfDay(mostRecent.startDate);
      final int daysSince = _daysBetween(start, effectiveReference);
      final int completedCycles = daysSince ~/ settings.averageCycleLength;
      start = _addDays(start, completedCycles * settings.averageCycleLength);
      cycleStartDate = start;
    }

    final int cycleDay = _daysBetween(cycleStartDate, effectiveReference) + 1;
    final Map<CyclePhase, PhaseBoundary> boundaries = getPhaseBoundaries(
      settings: settings,
    );

    CyclePhase currentPhase = CyclePhase.follicular;
    int phaseStartDay = 1;
    int phaseEndDay = settings.averageCycleLength;

    for (final CyclePhase phase in CyclePhase.values) {
      final PhaseBoundary? bounds = boundaries[phase];
      if (bounds == null) {
        continue;
      }

      if (cycleDay >= bounds.start && cycleDay <= bounds.end) {
        currentPhase = phase;
        phaseStartDay = bounds.start;
        phaseEndDay = bounds.end;
        break;
      }
    }

    final int daysUntilNextPhase;
    switch (currentPhase) {
      case CyclePhase.menstrual:
        daysUntilNextPhase =
            (boundaries[CyclePhase.follicular]?.start ?? 6) - cycleDay;
      case CyclePhase.follicular:
        daysUntilNextPhase =
            (boundaries[CyclePhase.ovulation]?.start ?? 13) - cycleDay;
      case CyclePhase.ovulation:
        daysUntilNextPhase =
            (boundaries[CyclePhase.luteal]?.start ?? 16) - cycleDay;
      case CyclePhase.luteal:
        daysUntilNextPhase = settings.averageCycleLength - cycleDay + 1;
    }

    final DateTime phaseStart = _addDays(cycleStartDate, phaseStartDay - 1);
    final DateTime phaseEnd = _addDays(cycleStartDate, phaseEndDay - 1);
    final DateTime predictedNext = _addDays(
      cycleStartDate,
      settings.averageCycleLength,
    );

    return CycleStatusResult(
      currentPhase: currentPhase,
      cycleDay: cycleDay,
      daysUntilNextPhase: daysUntilNextPhase,
      predictedNextPeriod: predictedNext,
      phaseStartDate: phaseStart,
      phaseEndDate: phaseEnd,
    );
  }

  static Map<CyclePhase, PhaseBoundary> getPhaseBoundaries({
    required CycleSettingsModel settings,
  }) {
    final int cycleLength = settings.averageCycleLength;
    final int periodLength = settings.averagePeriodLength;
    final int lutealLength = settings.lutealPhaseLength;

    final int ovulationDay = cycleLength - lutealLength;
    final int ovulationStart = _max(periodLength + 2, ovulationDay - 2);
    final int ovulationEnd = _min(
      ovulationDay + 2,
      cycleLength - lutealLength + 2,
    );

    return <CyclePhase, PhaseBoundary>{
      CyclePhase.menstrual: PhaseBoundary(start: 1, end: periodLength),
      CyclePhase.follicular: PhaseBoundary(
        start: periodLength + 1,
        end: ovulationStart - 1,
      ),
      CyclePhase.ovulation: PhaseBoundary(
        start: ovulationStart,
        end: ovulationEnd,
      ),
      CyclePhase.luteal: PhaseBoundary(
        start: ovulationEnd + 1,
        end: cycleLength,
      ),
    };
  }

  static PhaseRecommendation getPhaseRecommendation({
    required CyclePhase phase,
  }) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const PhaseRecommendation(
          phase: CyclePhase.menstrual,
          title: 'Menstrual Phase',
          description:
              'Your period phase. Energy may be lower, and you might feel more fatigued.',
          trainingFocus: 'Recovery and light movement',
          intensityRecommendation: 'low',
          exercisesToEmphasize: <String>['yoga', 'walking', 'light stretching'],
          exercisesToAvoid: <String>[
            'heavy compound lifts',
            'max effort attempts',
          ],
        );
      case CyclePhase.follicular:
        return const PhaseRecommendation(
          phase: CyclePhase.follicular,
          title: 'Follicular Phase',
          description:
              'Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.',
          trainingFocus: 'Building strength and endurance',
          intensityRecommendation: 'moderate',
          exercisesToEmphasize: <String>[
            'compound movements',
            'strength training',
            'cardio',
          ],
          exercisesToAvoid: <String>[],
        );
      case CyclePhase.ovulation:
        return const PhaseRecommendation(
          phase: CyclePhase.ovulation,
          title: 'Ovulation Phase',
          description:
              'Peak estrogen and testosterone. Often the strongest phase for performance.',
          trainingFocus: 'High-intensity training and PR attempts',
          intensityRecommendation: 'peak',
          exercisesToEmphasize: <String>[
            'max effort attempts',
            'heavy compound lifts',
            'power-focused workouts',
          ],
          exercisesToAvoid: <String>[],
        );
      case CyclePhase.luteal:
        return const PhaseRecommendation(
          phase: CyclePhase.luteal,
          title: 'Luteal Phase',
          description:
              'Progesterone rises, which may affect recovery and energy. Focus on maintenance.',
          trainingFocus: 'Maintenance and technique refinement',
          intensityRecommendation: 'moderate',
          exercisesToEmphasize: <String>[
            'technique work',
            'volume training',
            'recovery-focused sessions',
          ],
          exercisesToAvoid: <String>[
            'max effort attempts',
            'extremely heavy loads',
          ],
        );
    }
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _addDays(DateTime date, int days) {
    return _startOfDay(date).add(Duration(days: days));
  }

  static int _daysBetween(DateTime from, DateTime to) {
    return _startOfDay(to).difference(_startOfDay(from)).inDays;
  }

  static bool _isWithin(DateTime target, DateTime start, DateTime end) {
    return !target.isBefore(start) && !target.isAfter(end);
  }

  static int _max(int a, int b) => a > b ? a : b;

  static int _min(int a, int b) => a < b ? a : b;
}
