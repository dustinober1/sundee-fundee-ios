import type { CycleSettings } from '../domain/types/index';
import type { PeriodLogRecord, CycleRepository } from './CycleRepo';

const PERIOD_LOGS_KEY = '@sundee/period_logs';
const CYCLE_SETTINGS_KEY = '@sundee/cycle_settings';

export class LocalCycleRepo implements CycleRepository {
  async savePeriodLog(_uid: string, record: PeriodLogRecord): Promise<void> {
    const all = this.loadLogs();
    const filtered = all.filter((r) => r.id !== record.id);
    filtered.push(record);
    localStorage.setItem(PERIOD_LOGS_KEY, JSON.stringify(filtered));
  }

  async getPeriodLogs(_uid: string): Promise<PeriodLogRecord[]> {
    return this.loadLogs();
  }

  async deletePeriodLog(_uid: string, logId: string): Promise<void> {
    const filtered = this.loadLogs().filter((r) => r.id !== logId);
    localStorage.setItem(PERIOD_LOGS_KEY, JSON.stringify(filtered));
  }

  async saveCycleSettings(_uid: string, settings: CycleSettings): Promise<void> {
    localStorage.setItem(CYCLE_SETTINGS_KEY, JSON.stringify(settings));
  }

  async getCycleSettings(_uid: string): Promise<CycleSettings | null> {
    const raw = localStorage.getItem(CYCLE_SETTINGS_KEY);
    return raw ? (JSON.parse(raw) as CycleSettings) : null;
  }

  private loadLogs(): PeriodLogRecord[] {
    const raw = localStorage.getItem(PERIOD_LOGS_KEY);
    return raw ? (JSON.parse(raw) as PeriodLogRecord[]) : [];
  }
}
