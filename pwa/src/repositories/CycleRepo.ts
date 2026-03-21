import type { PeriodLog, CycleSettings } from '../domain/types/index';
import { FirestoreCycleRepo } from './FirestoreCycleRepo';
import { LocalCycleRepo } from './LocalCycleRepo';

export interface PeriodLogRecord {
  id: string;
  uid: string;
  startDate: string;
  endDate?: string;
}

export interface CycleRepository {
  savePeriodLog(uid: string, record: PeriodLogRecord): Promise<void>;
  getPeriodLogs(uid: string): Promise<PeriodLogRecord[]>;
  deletePeriodLog(uid: string, logId: string): Promise<void>;
  saveCycleSettings(uid: string, settings: CycleSettings): Promise<void>;
  getCycleSettings(uid: string): Promise<CycleSettings | null>;
}

export function getCycleRepo(isGuest: boolean): CycleRepository {
  return isGuest ? new LocalCycleRepo() : new FirestoreCycleRepo();
}

export function periodLogToRecord(uid: string, id: string, log: PeriodLog): PeriodLogRecord {
  return {
    id,
    uid,
    startDate: log.startDate.toISOString(),
    endDate: log.endDate?.toISOString(),
  };
}

export function recordToPeriodLog(record: PeriodLogRecord): PeriodLog {
  return {
    startDate: new Date(record.startDate),
    endDate: record.endDate ? new Date(record.endDate) : undefined,
  };
}
