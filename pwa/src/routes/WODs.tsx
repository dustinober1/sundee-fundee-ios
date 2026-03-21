/**
 * WODs Archive — list of recent Workouts of the Day, expandable cards.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router';
import { getWODRepo, type WODRecord } from '../repositories/WODRepo';
import styles from './WODs.module.css';

function isToday(dateStr: string): boolean {
  return dateStr === new Date().toISOString().slice(0, 10);
}

export function WODs() {
  const [wods, setWods] = useState<WODRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [expanded, setExpanded] = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      const records = await getWODRepo().getRecentWODs(30);
      records.sort((a, b) => {
        const aToday = isToday(a.date) ? 0 : 1;
        const bToday = isToday(b.date) ? 0 : 1;
        if (aToday !== bToday) return aToday - bToday;
        return b.date.localeCompare(a.date);
      });
      setWods(records);
    } catch { /* empty */ }
    setIsLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>WOD Archive</h1>

      {isLoading ? (
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : wods.length === 0 ? (
        <p className={styles.empty}>No WODs available yet.</p>
      ) : (
        wods.map((wod) => {
          const isExp = expanded === wod.id;
          const today = isToday(wod.date);
          return (
            <div key={wod.id} className={styles.card} onClick={() => setExpanded(isExp ? null : wod.id)}>
              <div className={styles.cardHeader}>
                <div>
                  {today && <span className={styles.todayBadge}>TODAY</span>}
                  <span className={styles.cardDate}>{wod.date}</span>
                </div>
                {wod.scoringType && <span className={styles.scoringBadge}>{wod.scoringType}</span>}
              </div>
              <h3 className={styles.cardName}>{wod.name}</h3>
              <p className={`${styles.cardDesc} ${isExp ? '' : styles.cardDescClamped}`}>{wod.description}</p>
              {isExp && (
                <>
                  {wod.exercises.length > 0 && (
                    <ul className={styles.exList}>
                      {wod.exercises.map((ex, i) => <li key={i}>{ex}</li>)}
                    </ul>
                  )}
                  {wod.scoringType && (
                    <Link
                      to={`/benchmarks/wod-${wod.id}?name=${encodeURIComponent(wod.name)}&scoring=${wod.scoringType}&predefined=false`}
                      className={styles.recordBtn}
                      onClick={(e) => e.stopPropagation()}
                    >
                      Record Result
                    </Link>
                  )}
                </>
              )}
              <span className={styles.expandHint}>{isExp ? 'Tap to collapse' : 'Tap to expand'}</span>
            </div>
          );
        })
      )}
    </div>
  );
}
