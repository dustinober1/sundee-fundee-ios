/**
 * Maxes screen — exercise list with best estimated 1RM, searchable.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import { formatWeight } from '../utils/formatWeight';
import type { WeightUnit } from '../domain/types';
import styles from './Maxes.module.css';

interface ExerciseSummary {
  exerciseId: string;
  exerciseName: string;
  best1RM: number;
  lastAchievedAt: string;
}

function buildExerciseSummaries(maxes: ExerciseMax[]): ExerciseSummary[] {
  const map = new Map<string, ExerciseSummary>();
  for (const max of maxes) {
    const existing = map.get(max.exerciseId);
    if (!existing) {
      map.set(max.exerciseId, {
        exerciseId: max.exerciseId,
        exerciseName: max.exerciseName,
        best1RM: max.estimated1RM,
        lastAchievedAt: max.achievedAt,
      });
    } else if (max.estimated1RM > existing.best1RM) {
      existing.best1RM = max.estimated1RM;
      existing.lastAchievedAt = max.achievedAt;
    }
  }
  return Array.from(map.values()).sort((a, b) => a.exerciseName.localeCompare(b.exerciseName));
}

export function Maxes() {
  const { user, isGuest } = useSession();
  const [summaries, setSummaries] = useState<ExerciseSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const [maxes, settings] = await Promise.all([
        getExerciseMaxRepo(isGuest).getAllMaxes(user.uid),
        getSettingsRepo(isGuest).getSettings(user.uid),
      ]);
      setSummaries(buildExerciseSummaries(maxes));
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { load(); }, [load]);

  const filtered = search
    ? summaries.filter((s) => s.exerciseName.toLowerCase().includes(search.toLowerCase()))
    : summaries;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Maxes</h1>

      <input
        className={styles.search}
        type="text"
        placeholder="Search exercises..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />

      {isLoading ? (
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : filtered.length === 0 ? (
        <p className={styles.empty}>
          {search ? 'No exercises match your search.' : 'No PRs recorded yet. Complete a workout to track your maxes!'}
        </p>
      ) : (
        <div className={styles.list}>
          {filtered.map((s) => (
            <Link key={s.exerciseId} to={`/exercises/${s.exerciseId}`} className={styles.card}>
              <span className={styles.name}>{s.exerciseName}</span>
              <span className={styles.max}>{formatWeight(s.best1RM, weightUnit)}</span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
