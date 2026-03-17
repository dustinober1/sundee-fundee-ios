/**
 * LocalCycleRepo — AsyncStorage implementation of CycleRepository.
 *
 * Persists period logs and cycle settings locally for guest (anonymous) users.
 * Period logs stored under '@sundee/period_logs' as a JSON array.
 * Cycle settings stored under '@sundee/cycle_settings' as a JSON object.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { CycleSettings } from '../domain/types/index';
import type { CycleRepository, PeriodLogRecord } from './CycleRepo';

const PERIOD_LOGS_KEY = '@sundee/period_logs';
const CYCLE_SETTINGS_KEY = '@sundee/cycle_settings';

export class LocalCycleRepo implements CycleRepository {
  /**
   * Saves a period log record to AsyncStorage.
   * If a record with the same id already exists, it is replaced (upsert).
   */
  async savePeriodLog(_uid: string, record: PeriodLogRecord): Promise<void> {
    const existing = await this.loadAllLogs();
    const filtered = existing.filter((r) => r.id !== record.id);
    filtered.push(record);
    await AsyncStorage.setItem(PERIOD_LOGS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves all period logs, ordered by startDate descending.
   */
  async getPeriodLogs(_uid: string): Promise<PeriodLogRecord[]> {
    const all = await this.loadAllLogs();
    return all.sort((a, b) => b.startDate.localeCompare(a.startDate));
  }

  /**
   * Deletes a period log by its id.
   */
  async deletePeriodLog(_uid: string, logId: string): Promise<void> {
    const existing = await this.loadAllLogs();
    const filtered = existing.filter((r) => r.id !== logId);
    await AsyncStorage.setItem(PERIOD_LOGS_KEY, JSON.stringify(filtered));
  }

  /**
   * Saves cycle settings to AsyncStorage.
   * Always overwrites the existing settings.
   */
  async saveCycleSettings(_uid: string, settings: CycleSettings): Promise<void> {
    await AsyncStorage.setItem(CYCLE_SETTINGS_KEY, JSON.stringify(settings));
  }

  /**
   * Retrieves cycle settings.
   * Returns null if no settings have been saved.
   */
  async getCycleSettings(_uid: string): Promise<CycleSettings | null> {
    const raw = await AsyncStorage.getItem(CYCLE_SETTINGS_KEY);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as CycleSettings;
  }

  private async loadAllLogs(): Promise<PeriodLogRecord[]> {
    const raw = await AsyncStorage.getItem(PERIOD_LOGS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as PeriodLogRecord[];
  }
}
