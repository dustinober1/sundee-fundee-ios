/* istanbul ignore file */
/**
 * Repositories barrel — re-exports all public types, interfaces, implementations,
 * factory functions, and the migration helper.
 *
 * Pure re-exports only; no executable logic in this file.
 */

// ─── UserRepository ──────────────────────────────────────────────────────────
export type { UserProfile, ExperienceLevel, PrimaryGoal, UserRepository } from './UserRepository';
export { FirestoreUserRepo } from './FirestoreUserRepo';
export { LocalUserRepo } from './LocalUserRepo';

// ─── OnboardingProfileRepo ───────────────────────────────────────────────────
export type { OnboardingProfile, OnboardingProfileRepository } from './OnboardingProfileRepo';
export { getOnboardingProfileRepo } from './OnboardingProfileRepo';
export { FirestoreOnboardingProfileRepo } from './FirestoreOnboardingProfileRepo';
export { LocalOnboardingProfileRepo } from './LocalOnboardingProfileRepo';

// ─── WorkoutRepo ──────────────────────────────────────────────────────────────
export type { WorkoutRecord, WorkoutRepository } from './WorkoutRepo';
export { getWorkoutRepo } from './WorkoutRepo';
export { FirestoreWorkoutRepo } from './FirestoreWorkoutRepo';
export { LocalWorkoutRepo } from './LocalWorkoutRepo';

// ─── SettingsRepo ─────────────────────────────────────────────────────────────
export type { AppSettings, SettingsRepository } from './SettingsRepo';
export { DEFAULT_SETTINGS, getSettingsRepo } from './SettingsRepo';
export { FirestoreSettingsRepo } from './FirestoreSettingsRepo';
export { LocalSettingsRepo } from './LocalSettingsRepo';

// ─── ReadinessRepo ────────────────────────────────────────────────────────────
export type { ReadinessSurveyRecord, ReadinessRepository } from './ReadinessRepo';
export { getReadinessRepo } from './ReadinessRepo';
export { FirestoreReadinessRepo } from './FirestoreReadinessRepo';
export { LocalReadinessRepo } from './LocalReadinessRepo';

// ─── ExerciseRepo ─────────────────────────────────────────────────────────────
export type { ExerciseRepository } from './ExerciseRepo';
export { getExerciseRepo } from './ExerciseRepo';
export { FirestoreExerciseRepo } from './FirestoreExerciseRepo';
export { LocalExerciseRepo } from './LocalExerciseRepo';

// ─── ExerciseMaxRepo ──────────────────────────────────────────────────────────
export type { ExerciseMaxRepository } from './ExerciseMaxRepo';
export { getExerciseMaxRepo } from './ExerciseMaxRepo';
export { FirestoreExerciseMaxRepo } from './FirestoreExerciseMaxRepo';
export { LocalExerciseMaxRepo } from './LocalExerciseMaxRepo';

// ─── Migration ────────────────────────────────────────────────────────────────
export { migrateGuestDataToFirestore } from './migration';
