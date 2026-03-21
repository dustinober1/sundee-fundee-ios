/**
 * Workout Detail — view-only screen for completed workout from History.
 */
import { useCallback, useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getWorkoutRepo, type WorkoutRecord, type CompletedExercise } from '../repositories/WorkoutRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import { formatWeight } from '../utils/formatWeight';
import type { WeightUnit } from '../domain/types';
import styles from './WorkoutDetail.module.css';

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  return m < 60 ? `${m}m` : `${Math.floor(m / 60)}h ${m % 60}m`;
}

function sourceBadge(source: string): string {
  switch (source) {
    case 'ai': return 'AI';
    case 'program': return 'Program';
    default: return 'Custom';
  }
}

export function WorkoutDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const [record, setRecord] = useState<WorkoutRecord | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

  const load = useCallback(async () => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const [workout, settings] = await Promise.all([
        getWorkoutRepo(isGuest).getWorkout(user.uid, id),
        getSettingsRepo(isGuest).getSettings(user.uid),
      ]);
      setRecord(workout);
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, id]);

  useEffect(() => { load(); }, [load]);

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;
  if (!record) return <div className={styles.container}><p className={styles.empty}>Workout not found.</p></div>;

  const date = new Date(record.completedAt);

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <button className={styles.back} onClick={() => navigate('/history')}>&larr; History</button>
        <h1 className={styles.title}>{record.workoutName ?? 'Workout'}</h1>
      </div>

      {/* Meta card */}
      <div className={styles.meta}>
        <div className={styles.metaRow}>
          <span>{date.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}</span>
          <span className={styles.badge}>{sourceBadge(record.source)}</span>
        </div>
        <div className={styles.metaStats}>
          <span>{formatDuration(record.durationSeconds)}</span>
          <span>{record.exerciseCount ?? record.exercises?.length ?? 0} exercises</span>
          {record.totalVolume != null && record.totalVolume > 0 && (
            <span>{formatWeight(record.totalVolume, weightUnit)} vol</span>
          )}
        </div>
      </div>

      {/* Exercises */}
      {record.exercises && record.exercises.length > 0 && (
        <div className={styles.exercises}>
          {record.exercises.map((ex: CompletedExercise, i: number) => (
            <div key={i} className={styles.exCard}>
              <div className={styles.exHeader}>
                <span className={styles.exName}>{ex.exerciseName}</span>
                <span className={styles.exMuscle}>{ex.muscleGroup}</span>
              </div>
              <div className={styles.setTable}>
                <div className={styles.setHeaderRow}>
                  <span>Set</span><span>Weight</span><span>Reps</span><span></span>
                </div>
                {ex.sets.map((set, j) => (
                  <div key={j} className={styles.setDataRow}>
                    <span>{j + 1}</span>
                    <span>{formatWeight(set.weight, weightUnit)}</span>
                    <span>{set.reps}</span>
                    <span>{set.isPersonalRecord ? <span className={styles.prBadge}>PR</span> : ''}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* AI workout exercises */}
      {record.workout?.exercises && record.workout.exercises.length > 0 && (
        <div className={styles.exercises}>
          {record.workout.exercises.map((ex: any, i: number) => (
            <div key={i} className={styles.exCard}>
              <span className={styles.exName}>{ex.name}</span>
              <div className={styles.aiDetail}>
                <span>{ex.sets} × {ex.reps}</span>
                {ex.weightLb ? <span>{formatWeight(ex.weightLb, weightUnit)}</span> : <span>Bodyweight</span>}
              </div>
              {ex.notes && <p className={styles.exNotes}>{ex.notes}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
