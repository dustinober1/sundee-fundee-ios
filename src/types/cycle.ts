// Core cycle tracking
export interface PeriodLog {
  id: string;
  userId: string;
  startDate: Date;
  endDate?: Date;
  flowLevel?: 'light' | 'medium' | 'heavy';
  notes?: string;
  createdAt: Date;
}

export interface SymptomLog {
  id: string;
  userId: string;
  date: Date;
  symptomId: string;
  severity: 1 | 2 | 3 | 4 | 5;
  notes?: string;
}

export interface BBTLog {
  id: string;
  userId: string;
  date: Date;
  temperature: number;
  time: string;
  notes?: string;
}

// Configuration
export interface SymptomDefinition {
  id: string;
  name: string;
  category: 'physical' | 'emotional' | 'energy';
  isDefault: boolean;
  userId?: string;
}

export interface CycleSettings {
  id: string;
  userId: string;
  averageCycleLength: number;
  averagePeriodLength: number;
  lutealPhaseLength: number;
  enabledSymptomIds: string[];
  notificationsEnabled: boolean;
}

// Computed (not stored, calculated on-demand)
export type CyclePhase =
  | 'menstrual'
  | 'follicular'
  | 'ovulation'
  | 'luteal';

export interface CycleStatus {
  currentPhase: CyclePhase;
  cycleDay: number;
  daysUntilNextPhase: number;
  predictedNextPeriod: Date;
  phaseStartDate: Date;
  phaseEndDate: Date;
}

export interface PhaseRecommendation {
  phase: CyclePhase;
  title: string;
  description: string;
  trainingFocus: string;
  intensityRecommendation: 'low' | 'moderate' | 'high' | 'peak';
  exercisesToEmphasize: string[];
  exercisesToAvoid: string[];
}

export interface PhaseStrengthProfile {
  userId: string;
  phases: {
    phase: CyclePhase;
    avgPerformanceDelta: number;
    sampleSize: number;
  }[];
  strongestPhase: CyclePhase;
  weakestPhase: CyclePhase;
  confidence: number;
}
