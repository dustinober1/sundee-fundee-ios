/**
 * Program Session — displays current session exercises with target weights, complete button.
 */
import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getProgramRepo, type ProgramEnrollment } from '../repositories/ProgramRepo';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import { getWorkoutRepo } from '../repositories/WorkoutRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import { formatWeight } from '../utils/formatWeight';
import type { Program, ProgramSession as PS, ProgramExercise, ExerciseValue, WeightUnit } from '../domain/types';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import { useInstallPrompt } from '../hooks/useInstallPrompt';
import { InstallBanner } from '../components/InstallBanner';
import styles from './ProgramSession.module.css';

function formatExVal(v: ExerciseValue): string {
  switch (v.kind) {
    case 'fixed': return String(v.value);
    case 'range': return `${v.lo}-${v.hi}`;
    case 'amrap': return 'AMRAP';
    case 'text': return v.value;
  }
}

function calculateTargetWeight(exercise: ProgramExercise, maxes: Map<string, number>, weightUnit: WeightUnit): string | null {
  if (!exercise.weight) return null;
  if (exercise.weight.kind === 'text') return exercise.weight.value;
  if (exercise.weight.kind !== 'fixed') return formatExVal(exercise.weight) + ' lbs';
  if (exercise.weight.value <= 1.0 && exercise.weight.value > 0) {
    const max1RM = maxes.get(exercise.id);
    if (max1RM) {
      const target = Math.round((max1RM * exercise.weight.value) / 5) * 5;
      return formatWeight(target, weightUnit);
    }
    return `${Math.round(exercise.weight.value * 100)}% 1RM`;
  }
  return formatWeight(exercise.weight.value, weightUnit);
}

export function ProgramSessionScreen() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const installPrompt = useInstallPrompt();
  const [pendingNavigation, setPendingNavigation] = useState<(() => void) | null>(null);
  const [program, setProgram] = useState<Program | null>(null);
  const [enrollment, setEnrollment] = useState<ProgramEnrollment | null>(null);
  const [session, setSession] = useState<PS | null>(null);
  const [maxesMap, setMaxesMap] = useState(new Map<string, number>());
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);
  const [isLoading, setIsLoading] = useState(true);
  const [isCompleting, setIsCompleting] = useState(false);

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const repo = getProgramRepo(isGuest);
      const enroll = await repo.getEnrollment(user.uid);
      if (!enroll) { navigate('/programs'); return; }
      setEnrollment(enroll);

      const [prog, maxes, settings] = await Promise.all([
        repo.getProgram(enroll.programId),
        getExerciseMaxRepo(isGuest).getAllMaxes(user.uid),
        getSettingsRepo(isGuest).getSettings(user.uid),
      ]);
      if (!prog) { navigate('/programs'); return; }
      setProgram(prog);
      setSession(prog.sessions[enroll.currentSession] ?? null);
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);

      const map = new Map<string, number>();
      for (const m of maxes) {
        const curr = map.get(m.exerciseId) ?? 0;
        if (m.estimated1RM > curr) map.set(m.exerciseId, m.estimated1RM);
      }
      setMaxesMap(map);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, navigate]);

  useEffect(() => { load(); }, [load]);

  async function handleComplete() {
    if (!user || !enrollment || !program || !session) return;
    setIsCompleting(true);
    try {
      const repo = getProgramRepo(isGuest);
      const totalSessions = program.sessions.length;
      let nextSession = enrollment.currentSession + 1;
      let nextWeek = enrollment.currentWeek;
      if (nextSession >= totalSessions) { nextSession = 0; nextWeek = 0; }

      await repo.updateEnrollmentProgress(user.uid, nextWeek, nextSession);
      await getWorkoutRepo(isGuest).saveWorkout(user.uid, {
        id: crypto.randomUUID(),
        uid: user.uid,
        completedAt: new Date().toISOString(),
        durationSeconds: 0,
        source: 'program',
        workoutName: session.name,
        exerciseCount: session.exercises.length,
      });
      if (installPrompt.showPrompt) {
        setPendingNavigation(() => () => navigate('/'));
      } else {
        navigate('/');
      }
    } catch { setIsCompleting(false); }
  }

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;
  if (!session || !enrollment || !program) return <div className={styles.container}><p>No active session.</p></div>;

  return (
    <div className={styles.container}>
      {/* Install banner — shown after session save when prompt is available */}
      {pendingNavigation !== null && installPrompt.showPrompt && (
        <InstallBanner
          isIOS={installPrompt.isIOS}
          onInstall={installPrompt.triggerAndroid}
          onDismiss={installPrompt.dismiss}
          onAfterDismiss={() => { if (pendingNavigation) pendingNavigation(); }}
        />
      )}

      <div className={styles.header}>
        <span className={styles.headerLabel}>{program.name}</span>
        <h1 className={styles.headerTitle}>{session.name}</h1>
        <span className={styles.headerMeta}>
          Week {enrollment.currentWeek + 1} &middot; Session {enrollment.currentSession + 1} of {program.sessions.length}
        </span>
      </div>

      <h3 className={styles.sectionTitle}>{session.exercises.length} Exercise{session.exercises.length !== 1 ? 's' : ''}</h3>

      {session.exercises.map((ex: ProgramExercise) => {
        const target = calculateTargetWeight(ex, maxesMap, weightUnit);
        return (
          <div key={ex.id} className={styles.exRow}>
            <div className={styles.exInfo}>
              <span className={styles.exName}>{ex.name}</span>
              <span className={styles.exDetail}>
                {ex.sets} × {formatExVal(ex.reps)}
                {ex.restSeconds ? ` · ${ex.restSeconds}s rest` : ''}
              </span>
            </div>
            {target && <span className={styles.weightBadge}>{target}</span>}
          </div>
        );
      })}

      <button className={styles.completeBtn} onClick={handleComplete} disabled={isCompleting}>
        {isCompleting ? 'Saving...' : 'Complete Session'}
      </button>
    </div>
  );
}
