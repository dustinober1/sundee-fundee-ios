/**
 * Injuries list — active injuries sorted by recovery phase, with delete.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getInjuryRepo, type InjuryProfileRecord } from '../repositories/InjuryRepo';
import type { RecoveryPhase } from '../domain/types';
import styles from './Injuries.module.css';

const PHASE_LABELS: Record<RecoveryPhase, string> = {
  acute: 'Acute', rehab: 'Rehab', lightLoad: 'Light Load', returnToPlay: 'Return to Play', resolved: 'Resolved',
};

const PHASE_COLORS: Record<RecoveryPhase, string> = {
  acute: '#EF5350', rehab: '#F2731A', lightLoad: '#E6A817', returnToPlay: '#1A3B66', resolved: '#999',
};

function locationLabel(loc: string): string {
  return loc.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase()).trim();
}

export function Injuries() {
  const { user, isGuest } = useSession();
  const navigate = useNavigate();
  const [injuries, setInjuries] = useState<InjuryProfileRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const all = await getInjuryRepo(isGuest).getInjuries(user.uid);
      all.sort((a, b) => {
        if (a.recoveryPhase === 'resolved' && b.recoveryPhase !== 'resolved') return 1;
        if (a.recoveryPhase !== 'resolved' && b.recoveryPhase === 'resolved') return -1;
        return b.injuryDate.localeCompare(a.injuryDate);
      });
      setInjuries(all);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { load(); }, [load]);

  async function handleDelete(injuryId: string) {
    if (!user || !confirm('Delete this injury?')) return;
    setInjuries((prev) => prev.filter((i) => i.id !== injuryId));
    try { await getInjuryRepo(isGuest).deleteInjury(user.uid, injuryId); } catch { load(); }
  }

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Injuries</h1>

      {injuries.length === 0 ? (
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>+</div>
          <h3>No active injuries</h3>
          <p className={styles.emptyHint}>Track injuries to get modified exercise recommendations.</p>
          <button className={styles.addBtn} onClick={() => navigate('/injuries/body-map')}>Add Injury</button>
        </div>
      ) : (
        <>
          {injuries.map((inj) => (
            <div key={inj.id} className={styles.row}>
              <Link to={`/injuries/${inj.id}`} className={styles.rowLink}>
                <div>
                  <span className={styles.rowLoc}>{locationLabel(inj.bodyLocation)}</span>
                  <span className={styles.rowDate}>{new Date(inj.injuryDate).toLocaleDateString()}</span>
                </div>
                <span className={styles.phaseBadge} style={{ background: PHASE_COLORS[inj.recoveryPhase] }}>
                  {PHASE_LABELS[inj.recoveryPhase]}
                </span>
              </Link>
              <button className={styles.deleteBtn} onClick={() => handleDelete(inj.id)}>Delete</button>
            </div>
          ))}
          <button className={styles.fab} onClick={() => navigate('/injuries/body-map')}>+ Add Injury</button>
        </>
      )}
    </div>
  );
}
