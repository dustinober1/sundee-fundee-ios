/**
 * InjuryRepository interface and factory function.
 *
 * Defines the contract for injury profile and pain log persistence.
 * Implementations:
 *   - FirestoreInjuryRepo: authenticated users (/users/{uid}/injuries/*)
 *   - LocalInjuryRepo: guest users (@sundee/injuries, @sundee/pain_logs keys)
 */
import type { InjuryProfile, PainLog, BodyLocation, RecoveryPhase } from '../domain/types/index';
import { FirestoreInjuryRepo } from './FirestoreInjuryRepo';
import { LocalInjuryRepo } from './LocalInjuryRepo';

/**
 * Persistence record for InjuryProfile.
 * Dates stored as ISO strings.
 */
export interface InjuryProfileRecord {
  id: string;
  uid: string;
  bodyLocation: BodyLocation;
  recoveryPhase: RecoveryPhase;
  /** ISO date string */
  injuryDate: string;
  notes?: string;
  location?: string;
}

/**
 * Persistence record for PainLog.
 * Adds an `id` field for Firestore document ID.
 * Date stored as ISO string.
 */
export interface PainLogRecord {
  /** UUID document ID */
  id: string;
  uid: string;
  injuryId: string;
  /** ISO date string */
  date: string;
  painLevel: number;
}

export interface InjuryRepository {
  saveInjury(uid: string, injury: InjuryProfileRecord): Promise<void>;
  getInjuries(uid: string): Promise<InjuryProfileRecord[]>;
  deleteInjury(uid: string, injuryId: string): Promise<void>;
  savePainLog(uid: string, log: PainLogRecord): Promise<void>;
  getPainLogs(uid: string, injuryId: string): Promise<PainLogRecord[]>;
}

/**
 * Returns the appropriate InjuryRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getInjuryRepo(isGuest: boolean): InjuryRepository {
  return isGuest
    ? new LocalInjuryRepo()
    : new FirestoreInjuryRepo();
}

/**
 * Convert a domain InjuryProfile to an InjuryProfileRecord for persistence.
 */
export function injuryProfileToRecord(uid: string, injury: InjuryProfile): InjuryProfileRecord {
  return {
    id: injury.id,
    uid,
    bodyLocation: injury.bodyLocation,
    recoveryPhase: injury.recoveryPhase,
    injuryDate: injury.injuryDate.toISOString(),
    notes: injury.notes,
    location: injury.location,
  };
}

/**
 * Convert an InjuryProfileRecord back to domain InjuryProfile.
 */
export function recordToInjuryProfile(record: InjuryProfileRecord): InjuryProfile {
  return {
    id: record.id,
    bodyLocation: record.bodyLocation,
    recoveryPhase: record.recoveryPhase,
    injuryDate: new Date(record.injuryDate),
    notes: record.notes,
    location: record.location,
  };
}

/**
 * Convert a domain PainLog to a PainLogRecord for persistence.
 */
export function painLogToRecord(uid: string, id: string, log: PainLog): PainLogRecord {
  return {
    id,
    uid,
    injuryId: log.injuryId,
    date: log.date.toISOString(),
    painLevel: log.painLevel,
  };
}

/**
 * Convert a PainLogRecord back to domain PainLog.
 */
export function recordToPainLog(record: PainLogRecord): PainLog {
  return {
    date: new Date(record.date),
    painLevel: record.painLevel,
    injuryId: record.injuryId,
  };
}
