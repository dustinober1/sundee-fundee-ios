/**
 * Benchmark Detail — record results, view history, see PR.
 */
import { useCallback, useEffect, useState } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getBenchmarkRepo, type BenchmarkResultRecord } from '../repositories/BenchmarkRepo';
import type { BenchmarkScoringType } from '../domain/types';
import { encodeRoundsAndReps, decodeRoundsAndReps } from '../domain/benchmarks/benchmark-catalog';
import { LineChart, type ChartDataPoint } from '../components/LineChart';
import styles from './BenchmarkDetail.module.css';

function formatScore(score: number, scoringType: BenchmarkScoringType): string {
  switch (scoringType) {
    case 'time': {
      const m = Math.floor(score / 60);
      const s = Math.round(score % 60);
      return `${m}:${s.toString().padStart(2, '0')}`;
    }
    case 'reps': return `${score} reps`;
    case 'weight': return `${score} lbs`;
    case 'distance': return `${score}m`;
    case 'roundsAndReps': {
      const { rounds, reps } = decodeRoundsAndReps(score);
      return `${rounds} rds + ${reps} reps`;
    }
    default: return String(score);
  }
}

function isScoreImproved(newScore: number, oldScore: number, scoringType: BenchmarkScoringType): boolean {
  if (scoringType === 'time' || scoringType === 'distance') return newScore < oldScore;
  return newScore > oldScore;
}

export function BenchmarkDetail() {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user, isGuest } = useSession();

  const name = searchParams.get('name') ?? 'Benchmark';
  const scoringType = (searchParams.get('scoring') ?? 'reps') as BenchmarkScoringType;

  const [results, setResults] = useState<BenchmarkResultRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showPR, setShowPR] = useState(false);

  // Input state
  const [timeMin, setTimeMin] = useState('');
  const [timeSec, setTimeSec] = useState('');
  const [repsInput, setRepsInput] = useState('');
  const [weightInput, setWeightInput] = useState('');
  const [roundsInput, setRoundsInput] = useState('');
  const [rrRepsInput, setRrRepsInput] = useState('');
  const [notes, setNotes] = useState('');

  const load = useCallback(async () => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const res = await getBenchmarkRepo(isGuest).getResults(user.uid, id);
      setResults(res.sort((a, b) => b.date.localeCompare(a.date)));
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest, id]);

  useEffect(() => { load(); }, [load]);

  function buildScore(): number {
    switch (scoringType) {
      case 'time': return (parseInt(timeMin) || 0) * 60 + (parseInt(timeSec) || 0);
      case 'reps': return parseInt(repsInput) || 0;
      case 'weight': return parseFloat(weightInput) || 0;
      case 'distance': return parseFloat(repsInput) || 0;
      case 'roundsAndReps': return encodeRoundsAndReps(parseInt(roundsInput) || 0, parseInt(rrRepsInput) || 0);
      default: return 0;
    }
  }

  const canSave = buildScore() > 0;

  async function handleSave() {
    if (!user || !id || !canSave) return;
    const score = buildScore();
    const record: BenchmarkResultRecord = {
      id: crypto.randomUUID(),
      uid: user.uid,
      benchmarkId: id,
      benchmarkName: name,
      scoringType,
      score,
      date: new Date().toISOString().slice(0, 10),
      notes: notes.trim() || undefined,
    };
    await getBenchmarkRepo(isGuest).saveResult(user.uid, record);

    // Check PR
    const best = results.length > 0
      ? results.reduce((b, r) => isScoreImproved(r.score, b, scoringType) ? r.score : b, results[0].score)
      : null;
    if (best === null || isScoreImproved(score, best, scoringType)) {
      setShowPR(true);
      setTimeout(() => setShowPR(false), 3000);
    }

    // Reset inputs & reload
    setTimeMin(''); setTimeSec(''); setRepsInput(''); setWeightInput(''); setRoundsInput(''); setRrRepsInput(''); setNotes('');
    load();
  }

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/benchmarks')}>&larr; Benchmarks</button>
      <h1 className={styles.title}>{name}</h1>
      <span className={styles.scoringBadge}>{scoringType.replace(/([A-Z])/g, ' $1').trim()}</span>

      {showPR && <div className={styles.prBanner}>New PR!</div>}

      {/* Record result */}
      <div className={styles.card}>
        <h3 className={styles.cardTitle}>Record Result</h3>
        {scoringType === 'time' && (
          <div className={styles.inputRow}>
            <input className={styles.input} type="number" inputMode="numeric" placeholder="MM" value={timeMin} onChange={(e) => setTimeMin(e.target.value)} />
            <span>:</span>
            <input className={styles.input} type="number" inputMode="numeric" placeholder="SS" value={timeSec} onChange={(e) => setTimeSec(e.target.value)} />
          </div>
        )}
        {(scoringType === 'reps' || scoringType === 'distance') && (
          <input className={styles.inputFull} type="number" inputMode="numeric" placeholder={scoringType === 'reps' ? 'Reps' : 'Meters'} value={repsInput} onChange={(e) => setRepsInput(e.target.value)} />
        )}
        {scoringType === 'weight' && (
          <input className={styles.inputFull} type="number" inputMode="decimal" placeholder="Weight (lbs)" value={weightInput} onChange={(e) => setWeightInput(e.target.value)} />
        )}
        {scoringType === 'roundsAndReps' && (
          <div className={styles.inputRow}>
            <input className={styles.input} type="number" inputMode="numeric" placeholder="Rounds" value={roundsInput} onChange={(e) => setRoundsInput(e.target.value)} />
            <span>+</span>
            <input className={styles.input} type="number" inputMode="numeric" placeholder="Reps" value={rrRepsInput} onChange={(e) => setRrRepsInput(e.target.value)} />
          </div>
        )}
        <textarea className={styles.textarea} placeholder="Notes (optional)" value={notes} onChange={(e) => setNotes(e.target.value)} rows={2} />
        <button className={styles.saveBtn} onClick={handleSave} disabled={!canSave}>Save Result</button>
      </div>

      {/* Progress chart */}
      {results.length >= 2 && (() => {
        const isLower = scoringType === 'time' || scoringType === 'distance';
        const chartData: ChartDataPoint[] = [...results]
          .sort((a, b) => a.date.localeCompare(b.date))
          .map((r) => ({ date: r.date, value: r.score }));
        return (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', padding: 'var(--space-md)', marginBottom: 'var(--space-md)' }}>
            <h3 className={styles.sectionTitle} style={{ marginTop: 0 }}>Progress</h3>
            <LineChart data={chartData} lowerIsBetter={isLower} formatValue={(v) => formatScore(Math.abs(v), scoringType)} />
          </div>
        );
      })()}

      {/* History */}
      <h3 className={styles.sectionTitle}>History</h3>
      {isLoading ? (
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : results.length === 0 ? (
        <p className={styles.empty}>No results yet. Record your first attempt!</p>
      ) : (
        <div className={styles.history}>
          {results.map((r) => (
            <div key={r.id} className={styles.historyRow}>
              <div>
                <span className={styles.historyDate}>{r.date}</span>
                {r.notes && <span className={styles.historyNotes}>{r.notes}</span>}
              </div>
              <span className={styles.historyScore}>{formatScore(r.score, scoringType)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
