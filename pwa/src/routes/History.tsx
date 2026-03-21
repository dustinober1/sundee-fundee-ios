/**
 * History screen — completed workouts grouped by date with source filtering.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getWorkoutRepo, type WorkoutRecord } from '../repositories/WorkoutRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import type { HistoryItem } from '../domain/history/history-item';
import type { HistorySourceFilter } from '../domain/history/history-filter';
import { filterHistoryBySource, groupHistoryByDate } from '../domain/history/history-filter';
import { formatWeight } from '../utils/formatWeight';
import type { WeightUnit } from '../domain/types';
import { SkeletonCard } from '../components/SkeletonCard';
import styles from './History.module.css';

function workoutRecordToHistoryItem(record: WorkoutRecord): HistoryItem {
  let source: HistoryItem['source'];
  switch (record.source) {
    case 'ai': source = { kind: 'aiWorkout' }; break;
    case 'program': source = { kind: 'program', name: record.workoutName ?? 'Program Workout' }; break;
    default: source = { kind: 'custom' }; break;
  }

  return {
    id: record.id,
    title: record.workoutName ?? (record.source === 'ai' ? 'AI Workout' : 'Custom Workout'),
    source,
    completedAt: new Date(record.completedAt),
    exerciseCount: record.exerciseCount ?? record.exercises?.length ?? record.workout?.exercises?.length ?? 0,
    durationSeconds: record.durationSeconds,
    originalID: record.id,
    isAIWorkout: record.source === 'ai',
    totalVolume: record.totalVolume,
    workoutName: record.workoutName,
  };
}

const SOURCE_FILTERS: { value: HistorySourceFilter; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'custom', label: 'Custom' },
  { value: 'program', label: 'Program' },
  { value: 'ai', label: 'AI' },
];

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  return m < 60 ? `${m}m` : `${Math.floor(m / 60)}h ${m % 60}m`;
}

export function History() {
  const { user, isGuest } = useSession();
  const [records, setRecords] = useState<WorkoutRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<HistorySourceFilter>('all');
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

  const loadHistory = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const repo = getWorkoutRepo(isGuest);
      const [history, settings] = await Promise.all([
        repo.getHistory(user.uid, 100),
        getSettingsRepo(isGuest).getSettings(user.uid),
      ]);
      setRecords(history);
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { loadHistory(); }, [loadHistory]);

  const items = records.map(workoutRecordToHistoryItem);
  const filtered = filterHistoryBySource(items, filter);
  const groups = groupHistoryByDate(filtered);

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>History</h1>

      {/* Source filter chips */}
      <div className={styles.filters}>
        {SOURCE_FILTERS.map((f) => (
          <button
            key={f.value}
            className={`${styles.chip} ${filter === f.value ? styles.chipActive : ''}`}
            onClick={() => setFilter(f.value)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {isLoading ? (
        <SkeletonCard count={4} height={72} />
      ) : groups.length === 0 ? (
        <p className={styles.empty}>No workouts yet. Start your first workout!</p>
      ) : (
        groups.map((group) => (
          <div key={group.label} className={styles.group}>
            <h3 className={styles.dateLabel}>{group.label}</h3>
            {group.items.map((item) => (
              <Link key={item.id} to={`/workout/${item.id}`} className={styles.card}>
                <div className={styles.cardTop}>
                  <span className={styles.cardTitle}>{item.title}</span>
                  <span className={styles.cardBadge}>
                    {item.source.kind === 'aiWorkout' ? 'AI' : item.source.kind === 'program' ? 'Program' : 'Custom'}
                  </span>
                </div>
                <div className={styles.cardMeta}>
                  <span>{item.exerciseCount} exercises</span>
                  <span>{formatDuration(item.durationSeconds)}</span>
                  {item.totalVolume != null && item.totalVolume > 0 && (
                    <span>{formatWeight(item.totalVolume, weightUnit)} vol</span>
                  )}
                </div>
              </Link>
            ))}
          </div>
        ))
      )}
    </div>
  );
}
