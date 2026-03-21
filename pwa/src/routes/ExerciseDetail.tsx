/**
 * Exercise Detail — 1RM history, rep-range PRs, volume trend.
 */
import { useCallback, useEffect, useState } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import { formatWeight, formatWeightNumeric } from '../utils/formatWeight';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { WeightUnit } from '../domain/types';
import { LineChart, type ChartDataPoint } from '../components/LineChart';
import styles from './ExerciseDetail.module.css';

export function ExerciseDetail() {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user, isGuest } = useSession();

  const exerciseName = searchParams.get('name') ?? id ?? 'Exercise';
  const [maxes, setMaxes] = useState<ExerciseMax[]>([]);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const [m, settings] = await Promise.all([
        getExerciseMaxRepo(isGuest).getMaxes(user.uid, id),
        getSettingsRepo(isGuest).getSettings(user.uid),
      ]);
      setMaxes(m.sort((a, b) => b.achievedAt.localeCompare(a.achievedAt)));
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, id]);

  useEffect(() => { load(); }, [load]);

  const best1RM = maxes.reduce((b, m) => Math.max(b, m.estimated1RM), 0);

  // Group by rep range
  const repRanges = new Map<number, ExerciseMax>();
  for (const m of maxes) {
    const curr = repRanges.get(m.repRange);
    if (!curr || m.estimated1RM > curr.estimated1RM) repRanges.set(m.repRange, m);
  }
  const sortedRanges = Array.from(repRanges.entries()).sort((a, b) => a[0] - b[0]);

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/maxes')}>&larr; Maxes</button>
      <h1 className={styles.title}>{exerciseName}</h1>

      {best1RM > 0 && (
        <div className={styles.prCard}>
          <span className={styles.prLabel}>CURRENT PR</span>
          <span className={styles.prValue}>{formatWeight(best1RM, weightUnit)}</span>
          <span className={styles.prDate}>est. 1RM</span>
        </div>
      )}

      {isLoading ? (
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : maxes.length === 0 ? (
        <p className={styles.empty}>No PR data yet. Complete a workout with this exercise to start tracking.</p>
      ) : (
        <>
          {/* 1RM Trend Chart */}
          {maxes.length >= 2 && (() => {
            const chartData: ChartDataPoint[] = [...maxes]
              .sort((a, b) => a.achievedAt.localeCompare(b.achievedAt))
              .map((m) => ({
                date: new Date(m.achievedAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),
                value: formatWeightNumeric(m.estimated1RM, weightUnit),
              }));
            return (
              <>
                <h3 className={styles.sectionTitle}>Estimated 1RM Over Time</h3>
                <div className={styles.chartWrap}>
                  <LineChart data={chartData} formatValue={(v) => formatWeight(v, weightUnit === 'kg' ? 'kg' : 'lb')} />
                </div>
              </>
            );
          })()}

          {/* Rep Range PRs */}
          <h3 className={styles.sectionTitle}>Rep Range PRs</h3>
          <div className={styles.table}>
            <div className={styles.tableHeader}>
              <span>Reps</span><span>Weight</span><span>Est. 1RM</span><span>Date</span>
            </div>
            {sortedRanges.map(([reps, m]) => (
              <div key={reps} className={styles.tableRow}>
                <span>{reps}</span>
                <span>{formatWeight(m.weight, weightUnit)}</span>
                <span className={styles.accent}>{formatWeight(m.estimated1RM, weightUnit)}</span>
                <span className={styles.muted}>{new Date(m.achievedAt).toLocaleDateString()}</span>
              </div>
            ))}
          </div>

          {/* 1RM History */}
          <h3 className={styles.sectionTitle}>1RM History</h3>
          {maxes.slice(0, 20).map((m, i) => (
            <div key={i} className={styles.histRow}>
              <span>{new Date(m.achievedAt).toLocaleDateString()}</span>
              <span>{m.repRange} reps @ {formatWeight(m.weight, weightUnit)}</span>
              <span className={styles.accent}>{formatWeight(m.estimated1RM, weightUnit)}</span>
            </div>
          ))}
        </>
      )}
    </div>
  );
}
