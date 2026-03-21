/**
 * Cycle Tracking screen — period logging, phase display, timeline forecast.
 */
import { useCallback, useEffect, useState } from 'react';
import { useSession } from '../auth/AuthContext';
import { getCycleRepo, recordToPeriodLog, periodLogToRecord } from '../repositories/CycleRepo';
import type { PeriodLog, CycleSettings, CyclePhase } from '../domain/types';
import { calculateCycleStatus, type CycleStatusResult } from '../domain/cycle/cycle-calculations';
import styles from './Cycle.module.css';

const PHASE_LABELS: Record<CyclePhase, string> = {
  menstrual: 'Menstrual',
  follicular: 'Follicular',
  ovulation: 'Ovulation',
  luteal: 'Luteal',
};

const PHASE_COLORS: Record<CyclePhase, string> = {
  menstrual: '#EF5350',
  follicular: '#66BB6A',
  ovulation: '#42A5F5',
  luteal: '#AB47BC',
};

const PHASE_RECS: Record<CyclePhase, string> = {
  menstrual: 'Focus on recovery and lighter weights. Your body is restoring — listen to it.',
  follicular: 'Energy is rising! Great time to push intensity and try heavier loads.',
  ovulation: 'Peak strength window — go for PRs and high-intensity work.',
  luteal: 'Endurance is strong but recovery slows. Moderate volume, steady effort.',
};

export function Cycle() {
  const { user, isGuest } = useSession();
  const [logs, setLogs] = useState<PeriodLog[]>([]);
  const [settings, setSettings] = useState<CycleSettings | null>(null);
  const [status, setStatus] = useState<CycleStatusResult | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [pendingStart, setPendingStart] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const repo = getCycleRepo(isGuest);
      const [periodLogRecords, cycleSettings] = await Promise.all([
        repo.getPeriodLogs(user.uid),
        repo.getCycleSettings(user.uid),
      ]);
      const periodLogs = periodLogRecords.map(recordToPeriodLog);
      setLogs(periodLogs);
      setSettings(cycleSettings);
      if (periodLogs.length > 0 && cycleSettings) {
        setStatus(calculateCycleStatus(periodLogs, cycleSettings, new Date()) ?? null);
      }
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { load(); }, [load]);

  async function handleDateTap(dateStr: string) {
    if (!user) return;
    if (!pendingStart) {
      setPendingStart(dateStr);
      return;
    }
    // Second tap — save period log
    const start = new Date(pendingStart);
    const end = new Date(dateStr);
    if (end < start) {
      setPendingStart(dateStr);
      return;
    }
    const logId = crypto.randomUUID();
    const record = periodLogToRecord(user.uid, logId, { startDate: start, endDate: end });
    await getCycleRepo(isGuest).savePeriodLog(user.uid, record);
    setPendingStart(null);
    load();
  }

  // Build simple calendar grid for current month
  const today = new Date();
  const year = today.getFullYear();
  const month = today.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDow = new Date(year, month, 1).getDay();
  const calendarDays: (number | null)[] = [];
  for (let i = 0; i < firstDow; i++) calendarDays.push(null);
  for (let d = 1; d <= daysInMonth; d++) calendarDays.push(d);

  // Period days set
  const periodDays = new Set<string>();
  for (const log of logs) {
    const s = new Date(log.startDate);
    const e = log.endDate ? new Date(log.endDate) : s;
    for (let d = new Date(s); d <= e; d.setDate(d.getDate() + 1)) {
      periodDays.add(d.toISOString().slice(0, 10));
    }
  }

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Cycle Tracking</h1>

      {/* Phase banner */}
      {status && (
        <div className={styles.phaseBanner} style={{ borderLeftColor: PHASE_COLORS[status.currentPhase] }}>
          <div className={styles.phaseHeader}>
            <span className={styles.phaseDot} style={{ background: PHASE_COLORS[status.currentPhase] }} />
            <span className={styles.phaseName}>{PHASE_LABELS[status.currentPhase]}</span>
            <span className={styles.phaseDay}>Day {status.cycleDay}</span>
          </div>
          <p className={styles.phaseRec}>{PHASE_RECS[status.currentPhase]}</p>
          {status.daysUntilNextPhase > 0 && (
            <p className={styles.phaseNext}>{status.daysUntilNextPhase} days until next phase</p>
          )}
        </div>
      )}

      {/* Calendar */}
      <div className={styles.calendar}>
        <h3 className={styles.calMonth}>
          {today.toLocaleString('default', { month: 'long', year: 'numeric' })}
        </h3>
        <div className={styles.calDow}>
          {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d, i) => (
            <span key={i} className={styles.calDowLabel}>{d}</span>
          ))}
        </div>
        <div className={styles.calGrid}>
          {calendarDays.map((day, i) => {
            if (day === null) return <span key={i} />;
            const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const isPeriod = periodDays.has(dateStr);
            const isPending = pendingStart === dateStr;
            const isToday = day === today.getDate();
            return (
              <button
                key={i}
                className={`${styles.calDay} ${isPeriod ? styles.calDayPeriod : ''} ${isPending ? styles.calDayPending : ''} ${isToday ? styles.calDayToday : ''}`}
                onClick={() => handleDateTap(dateStr)}
              >
                {day}
              </button>
            );
          })}
        </div>
        {pendingStart && (
          <p className={styles.calHint}>Tap another date to set the period end date</p>
        )}
      </div>

      {/* Period log history */}
      {logs.length > 0 && (
        <div className={styles.logSection}>
          <h3 className={styles.logTitle}>Period History</h3>
          {logs.slice(0, 6).map((log, i) => {
            const start = new Date(log.startDate);
            const end = log.endDate ? new Date(log.endDate) : start;
            const days = Math.round((end.getTime() - start.getTime()) / 86400000) + 1;
            return (
              <div key={i} className={styles.logRow}>
                <span>{start.toLocaleDateString()}</span>
                <span className={styles.logDuration}>{days} days</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
