/* istanbul ignore file */
/**
 * PR Detection subdomain barrel
 */

export type { ExerciseMax, PRCheckResult, TrackedRepRange } from './pr-types';
export { TRACKED_REP_RANGES } from './pr-types';
export { checkForPR, findClosestRepRange } from './check-pr';
