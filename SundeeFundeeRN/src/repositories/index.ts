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
export type { WorkoutRecord, WorkoutRepository, CompletedExercise, CompletedSet } from './WorkoutRepo';
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

// ─── CycleRepo ────────────────────────────────────────────────────────────────
export type { PeriodLogRecord, CycleRepository } from './CycleRepo';
export { getCycleRepo, periodLogToRecord, recordToPeriodLog } from './CycleRepo';
export { FirestoreCycleRepo } from './FirestoreCycleRepo';
export { LocalCycleRepo } from './LocalCycleRepo';

// ─── InjuryRepo ───────────────────────────────────────────────────────────────
export type { InjuryProfileRecord, PainLogRecord, InjuryRepository } from './InjuryRepo';
export { getInjuryRepo, injuryProfileToRecord, recordToInjuryProfile, painLogToRecord, recordToPainLog } from './InjuryRepo';
export { FirestoreInjuryRepo } from './FirestoreInjuryRepo';
export { LocalInjuryRepo } from './LocalInjuryRepo';

// ─── ProgramRepo ──────────────────────────────────────────────────────────────
export type { ProgramWeek, FirestoreProgramDocument, ProgramEnrollment, ProgramRepository } from './ProgramRepo';
export { getProgramRepo, firestoreProgramToProgram } from './ProgramRepo';
export { FirestoreProgramRepo } from './FirestoreProgramRepo';
export { LocalProgramRepo } from './LocalProgramRepo';

// ─── BenchmarkRepo ────────────────────────────────────────────────────────────
export type { BenchmarkResultRecord, BenchmarkRepository } from './BenchmarkRepo';
export { getBenchmarkRepo } from './BenchmarkRepo';
export { FirestoreBenchmarkRepo } from './FirestoreBenchmarkRepo';
export { LocalBenchmarkRepo } from './LocalBenchmarkRepo';

// ─── WODRepo ──────────────────────────────────────────────────────────────────
export type { WODRecord, WODRepository } from './WODRepo';
export { getWODRepo } from './WODRepo';
export { FirestoreWODRepo } from './FirestoreWODRepo';

// ─── Migration ────────────────────────────────────────────────────────────────
export { migrateGuestDataToFirestore } from './migration';
