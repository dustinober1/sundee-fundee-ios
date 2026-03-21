/**
 * AI Workout Preview — shows generated workout exercises before starting.
 */
import { useNavigate } from 'react-router';
import { getSharedWorkout, clearSharedWorkout } from './AIWorkoutConfig';
import { formatWeight } from '../utils/formatWeight';
import { useSession } from '../auth/AuthContext';
import { getWorkoutRepo } from '../repositories/WorkoutRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import { useEffect, useState } from 'react';
import type { WeightUnit } from '../domain/types';
import type { GeneratedWorkout } from '../domain/ai-workout/generated-workout';
import { totalEstimatedMinutes } from '../domain/ai-workout/generated-workout';
import styles from './AIWorkoutPreview.module.css';

export function AIWorkoutPreview() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);
  const workout = getSharedWorkout();

  useEffect(() => {
    if (!user) return;
    getSettingsRepo(isGuest).getSettings(user.uid).then((s) => {
      if (s?.weightUnit) setWeightUnit(s.weightUnit);
    });
  }, [user, isGuest]);

  if (!workout) {
    return (
      <div className={styles.container}>
        <p className={styles.empty}>No workout generated. Go back and generate one.</p>
        <button className={styles.primaryBtn} onClick={() => navigate('/ai-workout/config')}>Go Back</button>
      </div>
    );
  }

  const duration = totalEstimatedMinutes(workout.exercises);

  async function handleStart() {
    if (!user || !workout) return;
    // Save AI workout record
    await getWorkoutRepo(isGuest).saveWorkout(user.uid, {
      id: workout.id,
      uid: user.uid,
      completedAt: new Date().toISOString(),
      durationSeconds: 0,
      source: 'ai',
      workout,
      workoutName: `AI ${workout.questionnaire.focus.replace(/_/g, ' ')} Workout`,
      exerciseCount: workout.exercises.length,
    });
    clearSharedWorkout();
    navigate('/workout-session');
  }

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/ai-workout/config')}>&larr; Back to Config</button>

      <h1 className={styles.title}>Your Workout</h1>

      {/* Summary card */}
      <div className={styles.summaryCard}>
        <div className={styles.summaryStats}>
          <div className={styles.stat}>
            <span className={styles.statValue}>~{duration}</span>
            <span className={styles.statLabel}>minutes</span>
          </div>
          <div className={styles.stat}>
            <span className={styles.statValue}>{workout.exercises.length}</span>
            <span className={styles.statLabel}>exercises</span>
          </div>
        </div>
        {workout.coachingSummary && (
          <p className={styles.coaching}>{workout.coachingSummary}</p>
        )}
      </div>

      {/* Exercise list */}
      <div className={styles.exercises}>
        {workout.exercises.map((ex) => (
          <div key={ex.id} className={styles.exRow}>
            <div className={styles.exInfo}>
              <span className={styles.exName}>{ex.name}</span>
              <span className={styles.exDetail}>
                {ex.sets} × {ex.reps}
                {ex.weightLb ? ` · ${formatWeight(ex.weightLb, weightUnit)}` : ex.bodyweightOnly ? ' · Bodyweight' : ''}
                {ex.restMinutes ? ` · ${ex.restMinutes}min rest` : ''}
              </span>
            </div>
            {ex.notes && <p className={styles.exNotes}>{ex.notes}</p>}
          </div>
        ))}
      </div>

      <button className={styles.primaryBtn} onClick={handleStart}>Start Workout</button>
    </div>
  );
}
