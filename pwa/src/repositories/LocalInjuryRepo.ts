import type { InjuryRepository, InjuryProfileRecord, PainLogRecord } from './InjuryRepo';

const INJURIES_KEY = '@sundee/injuries';
const PAIN_LOGS_KEY = '@sundee/pain_logs';

export class LocalInjuryRepo implements InjuryRepository {
  async saveInjury(_uid: string, injury: InjuryProfileRecord): Promise<void> {
    const all = this.loadInjuries();
    const filtered = all.filter((i) => i.id !== injury.id);
    filtered.push(injury);
    localStorage.setItem(INJURIES_KEY, JSON.stringify(filtered));
  }

  async getInjuries(_uid: string): Promise<InjuryProfileRecord[]> {
    return this.loadInjuries();
  }

  async deleteInjury(_uid: string, injuryId: string): Promise<void> {
    localStorage.setItem(INJURIES_KEY, JSON.stringify(this.loadInjuries().filter((i) => i.id !== injuryId)));
    localStorage.setItem(PAIN_LOGS_KEY, JSON.stringify(this.loadPainLogs().filter((l) => l.injuryId !== injuryId)));
  }

  async savePainLog(_uid: string, log: PainLogRecord): Promise<void> {
    const all = this.loadPainLogs();
    const filtered = all.filter((l) => l.id !== log.id);
    filtered.push(log);
    localStorage.setItem(PAIN_LOGS_KEY, JSON.stringify(filtered));
  }

  async getPainLogs(_uid: string, injuryId: string): Promise<PainLogRecord[]> {
    return this.loadPainLogs()
      .filter((l) => l.injuryId === injuryId)
      .sort((a, b) => b.date.localeCompare(a.date));
  }

  private loadInjuries(): InjuryProfileRecord[] {
    const raw = localStorage.getItem(INJURIES_KEY);
    return raw ? (JSON.parse(raw) as InjuryProfileRecord[]) : [];
  }

  private loadPainLogs(): PainLogRecord[] {
    const raw = localStorage.getItem(PAIN_LOGS_KEY);
    return raw ? (JSON.parse(raw) as PainLogRecord[]) : [];
  }
}
