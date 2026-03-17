/**
 * LocalInjuryRepo — AsyncStorage implementation of InjuryRepository.
 *
 * Persists injury profiles and pain logs locally for guest (anonymous) users.
 * Injury profiles stored under '@sundee/injuries' as a JSON array.
 * Pain logs stored under '@sundee/pain_logs' as a JSON array.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { InjuryRepository, InjuryProfileRecord, PainLogRecord } from './InjuryRepo';

const INJURIES_KEY = '@sundee/injuries';
const PAIN_LOGS_KEY = '@sundee/pain_logs';

export class LocalInjuryRepo implements InjuryRepository {
  /**
   * Saves (upserts) an injury profile to AsyncStorage.
   * If a record with the same id exists, it is replaced.
   */
  async saveInjury(_uid: string, injury: InjuryProfileRecord): Promise<void> {
    const existing = await this.loadAllInjuries();
    const filtered = existing.filter((r) => r.id !== injury.id);
    filtered.push(injury);
    await AsyncStorage.setItem(INJURIES_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves all injury profiles.
   */
  async getInjuries(_uid: string): Promise<InjuryProfileRecord[]> {
    return this.loadAllInjuries();
  }

  /**
   * Deletes an injury profile by its id.
   */
  async deleteInjury(_uid: string, injuryId: string): Promise<void> {
    const existing = await this.loadAllInjuries();
    const filtered = existing.filter((r) => r.id !== injuryId);
    await AsyncStorage.setItem(INJURIES_KEY, JSON.stringify(filtered));
  }

  /**
   * Saves a pain log to AsyncStorage.
   * If a record with the same id exists, it is replaced.
   */
  async savePainLog(_uid: string, log: PainLogRecord): Promise<void> {
    const existing = await this.loadAllPainLogs();
    const filtered = existing.filter((r) => r.id !== log.id);
    filtered.push(log);
    await AsyncStorage.setItem(PAIN_LOGS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves all pain logs for a given injury, ordered by date descending.
   */
  async getPainLogs(_uid: string, injuryId: string): Promise<PainLogRecord[]> {
    const all = await this.loadAllPainLogs();
    return all
      .filter((r) => r.injuryId === injuryId)
      .sort((a, b) => b.date.localeCompare(a.date));
  }

  private async loadAllInjuries(): Promise<InjuryProfileRecord[]> {
    const raw = await AsyncStorage.getItem(INJURIES_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as InjuryProfileRecord[];
  }

  private async loadAllPainLogs(): Promise<PainLogRecord[]> {
    const raw = await AsyncStorage.getItem(PAIN_LOGS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as PainLogRecord[];
  }
}
