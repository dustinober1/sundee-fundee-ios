/**
 * LocalReadinessRepo — AsyncStorage implementation of ReadinessRepository.
 *
 * Persists readiness survey records locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/readiness_surveys' as a JSON array.
 * If a record with the same date already exists, it is replaced (upsert).
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { ReadinessSurveyRecord, ReadinessRepository } from './ReadinessRepo';

const READINESS_KEY = '@sundee/readiness_surveys';

export class LocalReadinessRepo implements ReadinessRepository {
  /**
   * Saves a readiness survey record to AsyncStorage.
   * If a record with the same date already exists, it is replaced.
   */
  async saveSurvey(_uid: string, record: ReadinessSurveyRecord): Promise<void> {
    const existing = await this.loadAll();
    const filtered = existing.filter((r) => r.date !== record.date);
    filtered.push(record);
    await AsyncStorage.setItem(READINESS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves a single survey by date.
   * Returns null if no survey exists for that date.
   */
  async getSurveyForDate(_uid: string, date: string): Promise<ReadinessSurveyRecord | null> {
    const all = await this.loadAll();
    return all.find((r) => r.date === date) ?? null;
  }

  /**
   * Retrieves recent readiness surveys sorted by date descending.
   * @param limit - Maximum number of records to return (default 30)
   */
  async getRecentSurveys(_uid: string, limit = 30): Promise<ReadinessSurveyRecord[]> {
    const all = await this.loadAll();
    const sorted = all.sort((a, b) => b.date.localeCompare(a.date));
    return sorted.slice(0, limit);
  }

  private async loadAll(): Promise<ReadinessSurveyRecord[]> {
    const raw = await AsyncStorage.getItem(READINESS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as ReadinessSurveyRecord[];
  }
}
