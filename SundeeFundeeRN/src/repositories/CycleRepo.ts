/**
 * CycleRepository interface and factory function.
 *
 * Defines the contract for menstrual cycle data persistence.
 * Implementations:
 *   - FirestoreCycleRepo: authenticated users (subcollections under /users/{uid})
 *   - LocalCycleRepo: guest users (@sundee/period_logs, @sundee/cycle_settings keys)
 */
import type { PeriodLog, CycleSettings } from '../domain/types/index';
import { FirestoreCycleRepo } from './FirestoreCycleRepo';
import { LocalCycleRepo } from './LocalCycleRepo';

/**
 * Persistence record wrapping domain PeriodLog.
 * Adds an `id` field (UUID) for Firestore document IDs.
 * Dates stored as ISO strings for cross-platform compatibility.
 */
export interface PeriodLogRecord {
  /** UUID document ID */
  id: string;
  uid: string;
  /** ISO date string for period start */
  startDate: string;
  /** ISO date string for period end, if known */
  endDate?: string;
}

export interface CycleRepository {
  savePeriodLog(uid: string, record: PeriodLogRecord): Promise<void>;
  getPeriodLogs(uid: string): Promise<PeriodLogRecord[]>;
  deletePeriodLog(uid: string, logId: string): Promise<void>;
  saveCycleSettings(uid: string, settings: CycleSettings): Promise<void>;
  getCycleSettings(uid: string): Promise<CycleSettings | null>;
}

/**
 * Returns the appropriate CycleRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getCycleRepo(isGuest: boolean): CycleRepository {
  return isGuest
    ? new LocalCycleRepo()
    : new FirestoreCycleRepo();
}

/**
 * Convert a domain PeriodLog to a PeriodLogRecord for persistence.
 */
export function periodLogToRecord(uid: string, id: string, log: PeriodLog): PeriodLogRecord {
  return {
    id,
    uid,
    startDate: log.startDate.toISOString(),
    endDate: log.endDate?.toISOString(),
  };
}

/**
 * Convert a PeriodLogRecord back to domain PeriodLog.
 */
export function recordToPeriodLog(record: PeriodLogRecord): PeriodLog {
  return {
    startDate: new Date(record.startDate),
    endDate: record.endDate ? new Date(record.endDate) : undefined,
  };
}
