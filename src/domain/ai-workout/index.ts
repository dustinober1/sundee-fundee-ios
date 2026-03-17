/**
 * AI Workout subdomain barrel
 * Re-exports all public API from ai-workout files.
 */

export type {
  ExerciseEquipmentType,
  GeneratedExercise,
  GeneratedWorkout,
  QuestionnaireAnswers,
} from './generated-workout';

export {
  getEquipmentType,
  totalEstimatedMinutes,
  extractMuscleGroups,
  stripHealthReferences,
  strippedForSharing,
} from './generated-workout';

export type {
  WorkoutGenerationContext,
  ExerciseMax,
  RecentWorkoutSummary,
  InjurySummary,
  BenchmarkSummary,
  PainActivitySummary,
} from './workout-generation-context';

export type { ExerciseTemplate } from './offline-workout-generator';

export {
  generateOfflineWorkout,
  selectTemplates,
  filterForEquipment,
  scaleForTime,
  applyWeights,
  applyEnergyLevel,
  applyInjurySubstitutions,
  applyCyclePhase,
  buildCoachingSummary,
  defaultPercentage,
} from './offline-workout-generator';
