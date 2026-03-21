/**
 * Injury Detail — phase display, pain logging (1-10), phase transition suggestion.
 */
import { useCallback, useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getInjuryRepo, type InjuryProfileRecord, type PainLogRecord } from '../repositories/InjuryRepo';
import type { RecoveryPhase } from '../domain/types';
import styles from './InjuryDetail.module.css';

const PHASE_LABELS: Record<RecoveryPhase, string> = {
  acute: 'Acute', rehab: 'Rehab', lightLoad: 'Light Load', returnToPlay: 'Return to Play', resolved: 'Resolved',
};
const PHASE_COLORS: Record<RecoveryPhase, string> = {
  acute: '#EF5350', rehab: '#F2731A', lightLoad: '#E6A817', returnToPlay: '#1A3B66', resolved: '#999',
};

function locationLabel(loc: string): string {
  return loc.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase()).trim();
}

export function InjuryDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const [injury, setInjury] = useState<InjuryProfileRecord | null>(null);
  const [painLogs, setPainLogs] = useState<PainLogRecord[]>([]);
  const [selectedPain, setSelectedPain] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const [injuries, logs] = await Promise.all([
        getInjuryRepo(isGuest).getInjuries(user.uid),
        getInjuryRepo(isGuest).getPainLogs(user.uid, id),
      ]);
      setInjury(injuries.find((i) => i.id === id) ?? null);
      setPainLogs(logs.sort((a, b) => b.date.localeCompare(a.date)));
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, id]);

  useEffect(() => { load(); }, [load]);

  async function handleLogPain() {
    if (!user || !id || selectedPain === null) return;
    const record: PainLogRecord = {
      id: crypto.randomUUID(), uid: user.uid, injuryId: id,
      date: new Date().toISOString(), painLevel: selectedPain,
    };
    await getInjuryRepo(isGuest).savePainLog(user.uid, record);
    setSelectedPain(null);
    load();
  }

  async function handlePhaseUpdate(phase: RecoveryPhase) {
    if (!user || !injury) return;
    const updated = { ...injury, recoveryPhase: phase };
    await getInjuryRepo(isGuest).saveInjury(user.uid, updated);
    setInjury(updated);
  }

  if (isLoading) return <div className={styles.center}><div className={styles.spinner} /></div>;
  if (!injury) return <div className={styles.container}><p>Injury not found.</p></div>;

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/injuries')}>&larr; Injuries</button>

      {/* Injury info */}
      <div className={styles.card}>
        <div className={styles.cardHeader}>
          <h2 className={styles.locTitle}>{locationLabel(injury.bodyLocation)}</h2>
          <span className={styles.phaseBadge} style={{ background: PHASE_COLORS[injury.recoveryPhase] }}>
            {PHASE_LABELS[injury.recoveryPhase]}
          </span>
        </div>
        <p className={styles.injDate}>Injured: {new Date(injury.injuryDate).toLocaleDateString()}</p>
        {injury.notes && <p className={styles.notes}>{injury.notes}</p>}
      </div>

      {/* Phase update */}
      {injury.recoveryPhase !== 'resolved' && (
        <div className={styles.card}>
          <h3 className={styles.cardTitle}>Update Phase</h3>
          <div className={styles.phaseChips}>
            {(['acute', 'rehab', 'lightLoad', 'returnToPlay', 'resolved'] as RecoveryPhase[]).map((phase) => (
              <button
                key={phase}
                className={`${styles.phaseChip} ${injury.recoveryPhase === phase ? styles.phaseChipActive : ''}`}
                style={injury.recoveryPhase === phase ? { background: PHASE_COLORS[phase], color: 'white' } : {}}
                onClick={() => handlePhaseUpdate(phase)}
              >
                {PHASE_LABELS[phase]}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Pain logging */}
      <div className={styles.card}>
        <h3 className={styles.cardTitle}>How's your {locationLabel(injury.bodyLocation).toLowerCase()} feeling?</h3>
        <div className={styles.painScale}>
          {Array.from({ length: 10 }, (_, i) => i + 1).map((n) => (
            <button
              key={n}
              className={`${styles.painBtn} ${selectedPain === n ? styles.painBtnActive : ''}`}
              onClick={() => setSelectedPain(n)}
            >
              {n}
            </button>
          ))}
        </div>
        {selectedPain && <p className={styles.painLabel}>Pain level: {selectedPain}/10</p>}
        {painLogs.length > 0 && (
          <p className={styles.lastLogged}>Last logged: {new Date(painLogs[0].date).toLocaleDateString()} — {painLogs[0].painLevel}/10</p>
        )}
        <button className={styles.logBtn} onClick={handleLogPain} disabled={selectedPain === null}>Log Pain</button>
      </div>

      {/* Pain history */}
      {painLogs.length > 0 && (
        <div className={styles.card}>
          <h3 className={styles.cardTitle}>Pain History</h3>
          {painLogs.slice(0, 10).map((log) => (
            <div key={log.id} className={styles.histRow}>
              <span>{new Date(log.date).toLocaleDateString()}</span>
              <span className={styles.histValue}>{log.painLevel}/10</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
