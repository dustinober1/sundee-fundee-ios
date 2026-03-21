/**
 * Workout Session — core workout logging screen with exercise cards,
 * set tracking, rest timer, PR detection, and elapsed time.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getWorkoutRepo, type WorkoutRecord, type CompletedExercise, type CompletedSet } from '../repositories/WorkoutRepo';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import { createSession, addExercise, completeSet, addSet, removeExercise, reorderExercises } from '../domain/workout-session/session-actions';
import type { WorkoutSession as WS, ActiveExercise, LoggedSet } from '../domain/workout-session/session-types';
import { formatWeightNumeric, parseWeightInput } from '../utils/formatWeight';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import type { WeightUnit } from '../domain/types';
import { scheduleNotification, requestNotificationPermission } from '../notifications/web-push';
import { useInstallPrompt } from '../hooks/useInstallPrompt';
import { InstallBanner } from '../components/InstallBanner';
import styles from './WorkoutSession.module.css';

const ACTIVE_WORKOUT_KEY = '@sundee/active-workout';

function formatElapsed(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

function formatRestTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

export function WorkoutSessionScreen() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const installPrompt = useInstallPrompt();
  const [pendingNavigation, setPendingNavigation] = useState<(() => void) | null>(null);
  const [session, setSession] = useState<WS | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);
  const [restActive, setRestActive] = useState(false);
  const [restRemaining, setRestRemaining] = useState(0);
  const [restTotal, setRestTotal] = useState(90);
  const [prToast, setPrToast] = useState<string | null>(null);
  const [showExercisePicker, setShowExercisePicker] = useState(false);
  const [exerciseSearch, setExerciseSearch] = useState('');
  const startTimeRef = useRef(Date.now());
  const restIntervalRef = useRef<ReturnType<typeof setInterval>>(undefined);
  const [draggedId, setDraggedId] = useState<string | null>(null);

  // Drag-and-drop reorder
  function handleDragStart(id: string) { setDraggedId(id); }
  function handleDragOver(e: React.DragEvent, targetId: string) {
    e.preventDefault();
    if (!session || !draggedId || draggedId === targetId) return;
    const ids = session.exercises.map((ex) => ex.id);
    const fromIdx = ids.indexOf(draggedId);
    const toIdx = ids.indexOf(targetId);
    if (fromIdx === -1 || toIdx === -1) return;
    ids.splice(fromIdx, 1);
    ids.splice(toIdx, 0, draggedId);
    setSession(reorderExercises(session, ids));
  }
  function handleDragEnd() { setDraggedId(null); }

  // Load settings + crash recovery
  useEffect(() => {
    (async () => {
      if (!user) return;
      const settings = await getSettingsRepo(isGuest).getSettings(user.uid);
      if (settings?.weightUnit) setWeightUnit(settings.weightUnit);

      // Check crash recovery
      try {
        const saved = localStorage.getItem(ACTIVE_WORKOUT_KEY);
        if (saved) {
          const restored = JSON.parse(saved) as WS;
          setSession(restored);
          startTimeRef.current = new Date(restored.startedAt).getTime();
          return;
        }
      } catch { /* empty */ }

      // Start fresh session
      const fresh = createSession();
      setSession(fresh);
      startTimeRef.current = Date.now();
      localStorage.setItem(ACTIVE_WORKOUT_KEY, JSON.stringify(fresh));

      // Request notification permission for rest timer alerts
      requestNotificationPermission();
    })();
  }, [user, isGuest]);

  // Elapsed timer
  useEffect(() => {
    const id = setInterval(() => setElapsed(Date.now() - startTimeRef.current), 1000);
    return () => clearInterval(id);
  }, []);

  // Persist session on change
  useEffect(() => {
    if (session) localStorage.setItem(ACTIVE_WORKOUT_KEY, JSON.stringify(session));
  }, [session]);

  // Rest timer
  const restNotifRef = useRef<ReturnType<typeof setTimeout>>(undefined);
  function startRest(duration: number) {
    setRestTotal(duration);
    setRestRemaining(duration);
    setRestActive(true);
    if (restIntervalRef.current) clearInterval(restIntervalRef.current);
    if (restNotifRef.current) clearTimeout(restNotifRef.current);
    restIntervalRef.current = setInterval(() => {
      setRestRemaining((prev) => {
        if (prev <= 1) {
          clearInterval(restIntervalRef.current!);
          setRestActive(false);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    // Schedule push notification when rest completes
    restNotifRef.current = scheduleNotification(
      duration * 1000,
      'Rest Complete',
      { body: 'Time for your next set!', tag: 'rest-timer' },
    );
  }

  // Add exercise
  function handleAddExercise(exerciseId: string, exerciseName: string, muscleGroup: string) {
    if (!session) return;
    setSession(addExercise(session, { exerciseId, exerciseName, muscleGroup }));
    setShowExercisePicker(false);
    setExerciseSearch('');
  }

  // Complete set
  async function handleCompleteSet(activeExerciseId: string, setId: string, weight: number, reps: number) {
    if (!session || !user) return;
    const storedWeight = parseWeightInput(String(weight), weightUnit);
    const updated = completeSet(session, activeExerciseId, setId, { weight: storedWeight, reps });
    setSession(updated);
    startRest(90);

    // PR check
    try {
      const ex = session.exercises.find((e) => e.id === activeExerciseId);
      if (!ex) return;
      const maxes = await getExerciseMaxRepo(isGuest).getMaxes(user.uid, ex.exerciseId);
      const estimated1RM = storedWeight * (1 + reps / 30); // Epley
      const currentBest = maxes.reduce((best: number, m: ExerciseMax) => Math.max(best, m.estimated1RM), 0);
      if (estimated1RM > currentBest && estimated1RM > 0) {
        setPrToast(`New PR! ${ex.exerciseName}`);
        setTimeout(() => setPrToast(null), 3000);
      }
    } catch { /* empty */ }
  }

  // Finish workout
  async function handleFinish() {
    if (!session || !user) return;
    const durationSeconds = Math.floor((Date.now() - startTimeRef.current) / 1000);
    const exercises: CompletedExercise[] = session.exercises
      .filter((ex) => ex.sets.some((s) => s.completed))
      .map((ex) => ({
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        muscleGroup: ex.muscleGroup,
        sets: ex.sets.filter((s) => s.completed).map((s): CompletedSet => ({
          weight: s.weight,
          reps: s.reps,
          isPersonalRecord: s.isPersonalRecord ?? false,
        })),
      }));

    const totalVolume = exercises.reduce(
      (sum, ex) => sum + ex.sets.reduce((s, set) => s + set.weight * set.reps, 0), 0
    );

    const record: Omit<WorkoutRecord, 'id'> = {
      uid: user.uid,
      completedAt: new Date().toISOString(),
      durationSeconds,
      source: 'custom',
      exercises,
      exerciseCount: exercises.length,
      totalVolume,
    };

    await getWorkoutRepo(isGuest).saveWorkout(user.uid, record as WorkoutRecord);
    localStorage.removeItem(ACTIVE_WORKOUT_KEY);
    if (installPrompt.showPrompt) {
      setPendingNavigation(() => () => navigate('/'));
    } else {
      navigate('/');
    }
  }

  if (!session) return <div className={styles.center}><div className={styles.spinner} /></div>;

  return (
    <div className={styles.container}>
      {/* Install banner — shown after workout save when prompt is available */}
      {pendingNavigation !== null && installPrompt.showPrompt && (
        <InstallBanner
          isIOS={installPrompt.isIOS}
          onInstall={installPrompt.triggerAndroid}
          onDismiss={installPrompt.dismiss}
          onAfterDismiss={() => { if (pendingNavigation) pendingNavigation(); }}
        />
      )}
      {/* PR Toast */}
      {prToast && <div className={styles.prToast}>{prToast}</div>}

      {/* Header */}
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Workout</h1>
          <span className={styles.elapsed}>{formatElapsed(elapsed)}</span>
        </div>
        <button className={styles.finishBtn} onClick={handleFinish}>Finish</button>
      </div>

      {/* Exercise list */}
      {session.exercises.length === 0 ? (
        <div className={styles.emptyState}>
          <p>No exercises yet.</p>
          <p className={styles.hint}>Tap the button below to add your first exercise.</p>
        </div>
      ) : (
        session.exercises.map((ex) => (
          <ExerciseCard
            key={ex.id}
            exercise={ex}
            weightUnit={weightUnit}
            onCompleteSet={(setId, weight, reps) => handleCompleteSet(ex.id, setId, weight, reps)}
            onAddSet={() => session && setSession(addSet(session, ex.id))}
            onRemove={() => session && setSession(removeExercise(session, ex.id))}
            isDragging={draggedId === ex.id}
            onDragStart={() => handleDragStart(ex.id)}
            onDragOver={(e) => handleDragOver(e, ex.id)}
            onDragEnd={handleDragEnd}
          />
        ))
      )}

      {/* Add exercise FAB */}
      <button className={styles.fab} onClick={() => setShowExercisePicker(true)}>+ Add Exercise</button>

      {/* Rest timer bar */}
      {restActive && (
        <div className={styles.restBar}>
          <div className={styles.restProgress} style={{ width: `${((restTotal - restRemaining) / restTotal) * 100}%` }} />
          <div className={styles.restContent}>
            <span className={styles.restLabel}>REST</span>
            <span className={styles.restTime}>{formatRestTime(restRemaining)}</span>
            <button className={styles.restSkip} onClick={() => { setRestActive(false); clearInterval(restIntervalRef.current!); }}>Skip</button>
          </div>
        </div>
      )}

      {/* Exercise picker modal */}
      {showExercisePicker && (
        <ExercisePickerModal
          search={exerciseSearch}
          onSearchChange={setExerciseSearch}
          onSelect={handleAddExercise}
          onClose={() => { setShowExercisePicker(false); setExerciseSearch(''); }}
        />
      )}
    </div>
  );
}

// ─── Exercise Card ──────────────────────────────────────────────────────────

function ExerciseCard({ exercise, weightUnit, onCompleteSet, onAddSet, onRemove, isDragging, onDragStart, onDragOver, onDragEnd }: {
  exercise: ActiveExercise;
  weightUnit: WeightUnit;
  onCompleteSet: (setId: string, weight: number, reps: number) => void;
  onAddSet: () => void;
  onRemove: () => void;
  isDragging?: boolean;
  onDragStart?: () => void;
  onDragOver?: (e: React.DragEvent) => void;
  onDragEnd?: () => void;
}) {
  const completedCount = exercise.sets.filter((s) => s.completed).length;

  return (
    <div
      className={`${styles.exerciseCard} ${isDragging ? styles.exerciseCardDragging : ''}`}
      draggable
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDragEnd={onDragEnd}
    >
      <div className={styles.exHeader}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className={styles.dragHandle} title="Drag to reorder">&#8942;&#8942;</span>
          <div>
            <span className={styles.exName}>{exercise.exerciseName}</span>
            <span className={styles.exMuscle}>{exercise.muscleGroup}</span>
          </div>
        </div>
        <div className={styles.exHeaderRight}>
          <span className={styles.exProgress}>{completedCount}/{exercise.sets.length}</span>
          <button className={styles.exRemove} onClick={onRemove}>&times;</button>
        </div>
      </div>

      <div className={styles.setHeaders}>
        <span className={styles.setColNum}>Set</span>
        <span className={styles.setColWeight}>Weight</span>
        <span className={styles.setColReps}>Reps</span>
        <span className={styles.setColAction} />
      </div>

      {exercise.sets.map((set, i) => (
        <SetRow
          key={set.id}
          set={set}
          index={i + 1}
          weightUnit={weightUnit}
          onComplete={(weight, reps) => onCompleteSet(set.id, weight, reps)}
        />
      ))}

      <button className={styles.addSetBtn} onClick={onAddSet}>+ Add Set</button>
    </div>
  );
}

// ─── Set Row ────────────────────────────────────────────────────────────────

function SetRow({ set, index, weightUnit, onComplete }: {
  set: LoggedSet;
  index: number;
  weightUnit: WeightUnit;
  onComplete: (weight: number, reps: number) => void;
}) {
  const [weight, setWeight] = useState(set.completed ? String(formatWeightNumeric(set.weight, weightUnit)) : '');
  const [reps, setReps] = useState(set.completed ? String(set.reps) : '');

  const canComplete = !set.completed && parseFloat(weight) > 0 && parseInt(reps) > 0;

  return (
    <div className={`${styles.setRow} ${set.completed ? styles.setRowCompleted : ''}`}>
      <span className={styles.setColNum}>{index}</span>
      <div className={styles.setColWeight}>
        <input
          className={styles.setInput}
          type="number"
          inputMode="decimal"
          placeholder="0"
          value={weight}
          onChange={(e) => setWeight(e.target.value)}
          disabled={set.completed}
        />
        <span className={styles.setUnit}>{weightUnit === 'kg' ? 'kg' : 'lbs'}</span>
      </div>
      <div className={styles.setColReps}>
        <input
          className={styles.setInput}
          type="number"
          inputMode="numeric"
          placeholder="0"
          value={reps}
          onChange={(e) => setReps(e.target.value)}
          disabled={set.completed}
        />
      </div>
      <span className={styles.setColAction}>
        {set.completed ? (
          <span className={styles.checkDone}>&#10003;</span>
        ) : set.isPersonalRecord ? (
          <span className={styles.prBadge}>PR</span>
        ) : (
          <button
            className={styles.checkBtn}
            disabled={!canComplete}
            onClick={() => onComplete(parseFloat(weight), parseInt(reps))}
          >
            &#9675;
          </button>
        )}
      </span>
    </div>
  );
}

// ─── Exercise Picker Modal ──────────────────────────────────────────────────

const COMMON_EXERCISES = [
  { id: 'squat', name: 'Barbell Back Squat', muscle: 'Legs' },
  { id: 'bench-press', name: 'Barbell Bench Press', muscle: 'Chest' },
  { id: 'deadlift', name: 'Deadlift', muscle: 'Back' },
  { id: 'ohp', name: 'Overhead Press', muscle: 'Shoulders' },
  { id: 'barbell-row', name: 'Barbell Row', muscle: 'Back' },
  { id: 'pull-up', name: 'Pull Up', muscle: 'Back' },
  { id: 'dip', name: 'Dip', muscle: 'Chest' },
  { id: 'front-squat', name: 'Front Squat', muscle: 'Legs' },
  { id: 'romanian-deadlift', name: 'Romanian Deadlift', muscle: 'Legs' },
  { id: 'incline-bench', name: 'Incline Bench Press', muscle: 'Chest' },
  { id: 'lat-pulldown', name: 'Lat Pulldown', muscle: 'Back' },
  { id: 'leg-press', name: 'Leg Press', muscle: 'Legs' },
  { id: 'lateral-raise', name: 'Lateral Raise', muscle: 'Shoulders' },
  { id: 'bicep-curl', name: 'Bicep Curl', muscle: 'Arms' },
  { id: 'tricep-pushdown', name: 'Tricep Pushdown', muscle: 'Arms' },
  { id: 'leg-curl', name: 'Leg Curl', muscle: 'Legs' },
  { id: 'calf-raise', name: 'Calf Raise', muscle: 'Legs' },
  { id: 'face-pull', name: 'Face Pull', muscle: 'Shoulders' },
  { id: 'hip-thrust', name: 'Hip Thrust', muscle: 'Legs' },
  { id: 'cable-fly', name: 'Cable Fly', muscle: 'Chest' },
];

function ExercisePickerModal({ search, onSearchChange, onSelect, onClose }: {
  search: string;
  onSearchChange: (v: string) => void;
  onSelect: (id: string, name: string, muscle: string) => void;
  onClose: () => void;
}) {
  const filtered = search
    ? COMMON_EXERCISES.filter((e) => e.name.toLowerCase().includes(search.toLowerCase()))
    : COMMON_EXERCISES;

  return (
    <div className={styles.modalOverlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.modalHeader}>
          <h2 className={styles.modalTitle}>Add Exercise</h2>
          <button className={styles.modalClose} onClick={onClose}>&times;</button>
        </div>
        <input
          className={styles.modalSearch}
          type="text"
          placeholder="Search exercises..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          autoFocus
        />
        {/* Custom exercise option */}
        {search.trim() && !filtered.some((e) => e.name.toLowerCase() === search.toLowerCase()) && (
          <button
            className={styles.modalItem}
            onClick={() => onSelect(search.toLowerCase().replace(/\s+/g, '-'), search.trim(), 'Other')}
          >
            <span className={styles.modalItemName}>+ Create "{search.trim()}"</span>
          </button>
        )}
        <div className={styles.modalList}>
          {filtered.map((e) => (
            <button key={e.id} className={styles.modalItem} onClick={() => onSelect(e.id, e.name, e.muscle)}>
              <span className={styles.modalItemName}>{e.name}</span>
              <span className={styles.modalItemMuscle}>{e.muscle}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
