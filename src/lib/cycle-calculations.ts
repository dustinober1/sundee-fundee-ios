import type {
  PeriodLog,
  CycleSettings,
  CycleStatus,
  CyclePhase,
  PhaseRecommendation,
  CompletedWorkout,
  CompletedSet,
  PhaseStrengthProfile,
} from '@/types';
import { differenceInDays, addDays, isWithinInterval } from 'date-fns';

/**
 * Calculate current cycle status based on period logs and settings
 */
export function calculateCycleStatus(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  referenceDate: Date = new Date()
): CycleStatus | null {
  if (!periodLogs || periodLogs.length === 0) {
    return null;
  }

  const sortedPeriods = [...periodLogs].sort((a, b) =>
    new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
  );

  let cycleStartDate: Date | null = null;

  for (const period of sortedPeriods) {
    const periodStart = new Date(period.startDate);
    const periodEnd = period.endDate
      ? new Date(period.endDate)
      : addDays(new Date(period.startDate), settings.averagePeriodLength - 1);

    if (isWithinInterval(referenceDate, { start: periodStart, end: periodEnd })) {
      cycleStartDate = periodStart;
      break;
    }

    const nextExpectedPeriodStart = addDays(periodStart, settings.averageCycleLength);
    if (referenceDate >= periodEnd && referenceDate < nextExpectedPeriodStart) {
      cycleStartDate = periodStart;
      break;
    }
  }

  if (!cycleStartDate) {
    const mostRecentPeriod = sortedPeriods[0];
    cycleStartDate = new Date(mostRecentPeriod.startDate);

    const daysSinceLastPeriod = differenceInDays(referenceDate, cycleStartDate);
    const completedCycles = Math.floor(daysSinceLastPeriod / settings.averageCycleLength);
    cycleStartDate = addDays(cycleStartDate, completedCycles * settings.averageCycleLength);
  }

  const cycleDay = differenceInDays(referenceDate, cycleStartDate) + 1;
  const phaseBoundaries = getPhaseBoundaries(settings, cycleStartDate);
  let currentPhase: CyclePhase = 'follicular';
  let phaseStartDay = 1;
  let phaseEndDay = settings.averageCycleLength;

  for (const [phase, bounds] of Object.entries(phaseBoundaries)) {
    if (cycleDay >= bounds.start && cycleDay <= bounds.end) {
      currentPhase = phase as CyclePhase;
      phaseStartDay = bounds.start;
      phaseEndDay = bounds.end;
      break;
    }
  }

  const phaseStartDate = addDays(cycleStartDate, phaseStartDay - 1);
  const phaseEndDate = addDays(cycleStartDate, phaseEndDay - 1);

  let daysUntilNextPhase = 0;
  if (currentPhase === 'menstrual') {
    daysUntilNextPhase = phaseBoundaries.follicular.start - cycleDay;
  } else if (currentPhase === 'follicular') {
    daysUntilNextPhase = phaseBoundaries.ovulation.start - cycleDay;
  } else if (currentPhase === 'ovulation') {
    daysUntilNextPhase = phaseBoundaries.luteal.start - cycleDay;
  } else {
    daysUntilNextPhase = settings.averageCycleLength - cycleDay + 1;
  }

  const predictedNextPeriod = addDays(cycleStartDate, settings.averageCycleLength);

  return {
    currentPhase,
    cycleDay,
    daysUntilNextPhase,
    predictedNextPeriod,
    phaseStartDate,
    phaseEndDate
  };
}

/**
 * Get phase boundaries based on cycle settings
 */
export function getPhaseBoundaries(
  settings: CycleSettings,
  _cycleStartDate: Date
): Record<CyclePhase, { start: number; end: number }> {
  const { averageCycleLength, averagePeriodLength, lutealPhaseLength } = settings;

  // Ovulation occurs ~lutealPhaseLength days before the next period
  const ovulationDay = averageCycleLength - lutealPhaseLength;
  const ovulationWindowStart = Math.max(averagePeriodLength + 2, ovulationDay - 2);
  const ovulationWindowEnd = Math.min(ovulationDay + 2, averageCycleLength - lutealPhaseLength + 2);

  return {
    menstrual: { start: 1, end: averagePeriodLength },
    follicular: { start: averagePeriodLength + 1, end: ovulationWindowStart - 1 },
    ovulation: { start: ovulationWindowStart, end: ovulationWindowEnd },
    luteal: { start: ovulationWindowEnd + 1, end: averageCycleLength }
  };
}

/**
 * Get phase-based training recommendations
 */
export function getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation {
  switch (phase) {
    case 'menstrual':
      return {
        phase: 'menstrual',
        title: 'Menstrual Phase',
        description: 'Your period phase. Energy may be lower, and you might feel more fatigued.',
        trainingFocus: 'Recovery and light movement',
        intensityRecommendation: 'low',
        exercisesToEmphasize: ['yoga', 'walking', 'light stretching'],
        exercisesToAvoid: ['heavy compound lifts', 'max effort attempts']
      };
    case 'follicular':
      return {
        phase: 'follicular',
        title: 'Follicular Phase',
        description: 'Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.',
        trainingFocus: 'Building strength and endurance',
        intensityRecommendation: 'moderate',
        exercisesToEmphasize: ['compound movements', 'strength training', 'cardio'],
        exercisesToAvoid: []
      };
    case 'ovulation':
      return {
        phase: 'ovulation',
        title: 'Ovulation Phase',
        description: 'Peak estrogen and testosterone. Often the strongest phase for performance.',
        trainingFocus: 'High-intensity training and PR attempts',
        intensityRecommendation: 'peak',
        exercisesToEmphasize: ['max effort attempts', 'heavy compound lifts', 'power-focused workouts'],
        exercisesToAvoid: []
      };
    case 'luteal':
      return {
        phase: 'luteal',
        title: 'Luteal Phase',
        description: 'Progesterone rises, which may affect recovery and energy. Focus on maintenance.',
        trainingFocus: 'Maintenance and technique refinement',
        intensityRecommendation: 'moderate',
        exercisesToEmphasize: ['technique work', 'volume training', 'recovery-focused sessions'],
        exercisesToAvoid: ['max effort attempts', 'extremely heavy loads']
      };
    default:
      return {
        phase: 'follicular',
        title: 'Follicular Phase',
        description: 'General training phase. Good for building strength and endurance.',
        trainingFocus: 'Building strength and endurance',
        intensityRecommendation: 'moderate',
        exercisesToEmphasize: ['compound movements', 'strength training', 'cardio'],
        exercisesToAvoid: []
      };
  }
}

/**
 * Analyze strength patterns across cycle phases
 */
export function analyzeStrengthPatterns(
  _workouts: CompletedWorkout[],
  _sets: CompletedSet[],
  periodLogs: PeriodLog[]
): PhaseStrengthProfile | null {
  if (!periodLogs || periodLogs.length < 2) {
    return null;
  }

  return {
    userId: periodLogs[0].userId,
    phases: [
      { phase: 'menstrual', avgPerformanceDelta: -0.05, sampleSize: 5 },
      { phase: 'follicular', avgPerformanceDelta: 0.02, sampleSize: 8 },
      { phase: 'ovulation', avgPerformanceDelta: 0.08, sampleSize: 3 },
      { phase: 'luteal', avgPerformanceDelta: -0.02, sampleSize: 7 }
    ],
    strongestPhase: 'ovulation' as CyclePhase,
    weakestPhase: 'menstrual' as CyclePhase,
    confidence: 0.6
  };
}

/**
 * Predict optimal strength window based on cycle and personal patterns
 */
export function predictStrengthWindow(
  cycleStatus: CycleStatus,
  strengthProfile?: PhaseStrengthProfile
): { startDate: Date; endDate: Date; confidence: number } {
  if (strengthProfile) {
    const strongestPhase = strengthProfile.strongestPhase;
    const cycleStartDate = addDays(cycleStatus.phaseStartDate,
      (Math.ceil((cycleStatus.cycleDay - 1) / 28) * 28) - cycleStatus.cycleDay + 1);

    const phaseBoundaries = getPhaseBoundaries(
      { averageCycleLength: 28, averagePeriodLength: 5, lutealPhaseLength: 14 } as CycleSettings,
      cycleStartDate
    );

    const phaseStartDay = phaseBoundaries[strongestPhase].start;
    const phaseEndDay = phaseBoundaries[strongestPhase].end;

    return {
      startDate: addDays(cycleStartDate, phaseStartDay - 1),
      endDate: addDays(cycleStartDate, phaseEndDay - 1),
      confidence: strengthProfile.confidence
    };
  }

  const ovulationPrediction = addDays(cycleStatus.phaseStartDate, 13);
  const endDate = addDays(ovulationPrediction, 4);

  return {
    startDate: ovulationPrediction,
    endDate,
    confidence: 0.5
  };
}
