/**
 * Programs catalog — lists available programs with focus-area filtering.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getProgramRepo } from '../repositories/ProgramRepo';
import type { Program, ProgramSession, WorkoutFocus } from '../domain/types';
import { useEntitlementContext } from '../entitlements/EntitlementContext';
import styles from './Programs.module.css';

type FilterOption = 'all' | 'strength' | 'hypertrophy' | 'power';

const FOCUS_MAP: Record<Exclude<FilterOption, 'all'>, WorkoutFocus[]> = {
  strength: ['strength'],
  hypertrophy: ['upper_body', 'lower_body', 'full_body', 'push', 'pull'],
  power: ['olympic_lifts', 'conditioning'],
};

function programMatchesFilter(program: Program, filter: FilterOption): boolean {
  if (filter === 'all') return true;
  const targets = FOCUS_MAP[filter];
  return program.sessions.some((s: ProgramSession) => s.focusArea && targets.includes(s.focusArea));
}

function deriveFocusAreas(program: Program): string[] {
  const areas = new Set<string>();
  for (const s of program.sessions) {
    if (s.focusArea) areas.add(s.focusArea.replace(/_/g, ' '));
  }
  return Array.from(areas).slice(0, 3);
}

const FILTERS: { value: FilterOption; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'strength', label: 'Strength' },
  { value: 'hypertrophy', label: 'Hypertrophy' },
  { value: 'power', label: 'Power' },
];

export function Programs() {
  const { user, isGuest } = useSession();
  const { isPremium } = useEntitlementContext();
  const [programs, setPrograms] = useState<Program[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<FilterOption>('all');

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const repo = getProgramRepo(isGuest);
      setPrograms(await repo.getPrograms());
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { load(); }, [load]);

  const filtered = programs.filter((p) => programMatchesFilter(p, filter));

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Programs</h1>

      <div className={styles.filters}>
        {FILTERS.map((f) => (
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
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : filtered.length === 0 ? (
        <p className={styles.empty}>No programs match this filter.</p>
      ) : (
        <div className={styles.list}>
          {filtered.map((p) => (
            <Link key={p.id} to={`/programs/${p.id}`} className={styles.card}>
              <div className={styles.cardAccent} />
              <div className={styles.cardBody}>
                <div className={styles.cardHeader}>
                  <span className={styles.cardName}>{p.name}</span>
                  {!isPremium && <span className={styles.premiumBadge}>Premium</span>}
                </div>
                <span className={styles.cardSessions}>{p.sessions.length} sessions</span>
                <div className={styles.focusTags}>
                  {deriveFocusAreas(p).map((area) => (
                    <span key={area} className={styles.focusTag}>{area}</span>
                  ))}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
