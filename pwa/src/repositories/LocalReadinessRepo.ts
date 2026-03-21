import type { ReadinessSurveyRecord, ReadinessRepository } from './ReadinessRepo';

const READINESS_KEY = '@sundee/readiness_surveys';

export class LocalReadinessRepo implements ReadinessRepository {
  async saveSurvey(_uid: string, record: ReadinessSurveyRecord): Promise<void> {
    const all = this.loadAll();
    const filtered = all.filter((r) => r.id !== record.id);
    filtered.push(record);
    localStorage.setItem(READINESS_KEY, JSON.stringify(filtered));
  }

  async getSurveyForDate(_uid: string, date: string): Promise<ReadinessSurveyRecord | null> {
    return this.loadAll().find((r) => r.date === date) ?? null;
  }

  async getRecentSurveys(_uid: string, limit = 7): Promise<ReadinessSurveyRecord[]> {
    return this.loadAll()
      .sort((a, b) => b.date.localeCompare(a.date))
      .slice(0, limit);
  }

  private loadAll(): ReadinessSurveyRecord[] {
    const raw = localStorage.getItem(READINESS_KEY);
    return raw ? (JSON.parse(raw) as ReadinessSurveyRecord[]) : [];
  }
}
