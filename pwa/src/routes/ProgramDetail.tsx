/**
 * Program Detail — shows weekly breakdown, enrollment CTA, missing 1RM prompt.
 */
import { useCallback, useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getProgramRepo, type ProgramEnrollment } from '../repositories/ProgramRepo';
import type { Program, ProgramSession, ProgramExercise, ExerciseValue } from '../domain/types';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import styles from './ProgramDetail.module.css';

function formatExerciseValue(v: ExerciseValue | undefined): string {
  if (!v) return '';
  switch (v.kind) {
    case 'fixed': return String(v.value);
    case 'range': return `${v.lo}-${v.hi}`;
    case 'amrap': return 'AMRAP';
    case 'text': return v.value;
    default: return '';
  }
}

function isPercentageWeight(v: ExerciseValue | undefined): boolean {
  return !!v && v.kind === 'fixed' && v.value <= 1.0 && v.value > 0;
}

export function ProgramDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user, isGuest } = useSession();

  const [program, setProgram] = useState<Program | null>(null);
  const [enrollment, setEnrollment] = useState<ProgramEnrollment | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedSession, setExpandedSession] = useState<number | null>(null);
  const [missingExercises, setMissingExercises] = useState<string[]>([]);

  const load = useCallback(async () => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const repo = getProgramRepo(isGuest);
      const [prog, enroll, maxes] = await Promise.all([
        repo.getProgram(id),
        repo.getEnrollment(user.uid),
        getExerciseMaxRepo(isGuest).getAllMaxes(user.uid),
      ]);
      setProgram(prog);
      setEnrollment(enroll);

      // Find exercises with % weights but no logged max
      if (prog) {
        const maxedIds = new Set(maxes.map((m: ExerciseMax) => m.exerciseId));
        const missing = new Set<string>();
        for (const s of prog.sessions) {
          for (const e of s.exercises) {
            if (isPercentageWeight(e.weight) && !maxedIds.has(e.id)) {
              missing.add(e.name);
            }
          }
        }
        setMissingExercises(Array.from(missing));
      }
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, id]);

  useEffect(() => { load(); }, [load]);

  async function handleEnroll() {
    if (!user || !id) return;
    await getProgramRepo(isGuest).enrollUser(user.uid, id);
    navigate('/programs/session');
  }

  async function handleUnenroll() {
    if (!user) return;
    if (!confirm('Unenroll from this program?')) return;
    await getProgramRepo(isGuest).unenroll(user.uid);
    setEnrollment(null);
  }

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;
  if (!program) return <p className={styles.empty}>Program not found.</p>;

  const isEnrolledHere = enrollment?.programId === id;
  const isEnrolledElsewhere = enrollment && enrollment.programId !== id;

  return (
    <div className={styles.container}>
      {/* Header */}
      <div className={styles.header}>
        <button className={styles.back} onClick={() => navigate('/programs')}>&larr; Programs</button>
        <h1 className={styles.title}>{program.name}</h1>
        <p className={styles.meta}>{program.sessions.length} sessions</p>
      </div>

      {/* Missing 1RM warning */}
      {missingExercises.length > 0 && (
        <div className={styles.warning}>
          <strong>Missing maxes:</strong> {missingExercises.join(', ')}
          <p className={styles.warningHint}>Log 1RMs in the Maxes tab for accurate weight targets.</p>
        </div>
      )}

      {/* Enrollment CTA */}
      <div className={styles.cta}>
        {isEnrolledHere ? (
          <>
            <button className={styles.primaryBtn} onClick={() => navigate('/programs/session')}>
              Continue — Week {(enrollment?.currentWeek ?? 0) + 1}, Session {(enrollment?.currentSession ?? 0) + 1}
            </button>
            <button className={styles.dangerBtn} onClick={handleUnenroll}>Unenroll</button>
          </>
        ) : isEnrolledElsewhere ? (
          <div className={styles.warning}>You're enrolled in another program. Unenroll first to switch.</div>
        ) : (
          <button className={styles.primaryBtn} onClick={handleEnroll}>Start Program</button>
        )}
      </div>

      {/* Weekly breakdown */}
      <h2 className={styles.sectionTitle}>Sessions</h2>
      {program.sessions.map((session: ProgramSession, i: number) => (
        <div key={session.id} className={styles.sessionCard}>
          <button
            className={styles.sessionHeader}
            onClick={() => setExpandedSession(expandedSession === i ? null : i)}
          >
            <span className={styles.sessionBadge}>{i + 1}</span>
            <span className={styles.sessionName}>{session.name}</span>
            <span className={styles.chevron}>{expandedSession === i ? '−' : '+'}</span>
          </button>
          {expandedSession === i && (
            <div className={styles.exercises}>
              {session.exercises.map((ex: ProgramExercise) => (
                <div key={ex.id} className={styles.exerciseRow}>
                  <span className={styles.exName}>{ex.name}</span>
                  <span className={styles.exDetail}>
                    {ex.sets} × {formatExerciseValue(ex.reps)}
                    {ex.weight && (
                      isPercentageWeight(ex.weight) && ex.weight.kind === 'fixed'
                        ? ` @ ${Math.round(ex.weight.value * 100)}%`
                        : ` @ ${formatExerciseValue(ex.weight)} lbs`
                    )}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
