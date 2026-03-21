import type { InjuryProfile, PainLog, BodyLocation, RecoveryPhase } from '../domain/types/index';
import { FirestoreInjuryRepo } from './FirestoreInjuryRepo';
import { LocalInjuryRepo } from './LocalInjuryRepo';

export interface InjuryProfileRecord {
  id: string;
  uid: string;
  bodyLocation: BodyLocation;
  recoveryPhase: RecoveryPhase;
  injuryDate: string;
  notes?: string;
  location?: string;
}

export interface PainLogRecord {
  id: string;
  uid: string;
  injuryId: string;
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

export function getInjuryRepo(isGuest: boolean): InjuryRepository {
  return isGuest ? new LocalInjuryRepo() : new FirestoreInjuryRepo();
}

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

export function painLogToRecord(uid: string, id: string, log: PainLog): PainLogRecord {
  return { id, uid, injuryId: log.injuryId, date: log.date.toISOString(), painLevel: log.painLevel };
}

export function recordToPainLog(record: PainLogRecord): PainLog {
  return { date: new Date(record.date), painLevel: record.painLevel, injuryId: record.injuryId };
}
