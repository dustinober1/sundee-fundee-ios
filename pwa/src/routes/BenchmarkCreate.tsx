/**
 * Create Custom Benchmark — form for name, category, description, scoringType.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getBenchmarkRepo } from '../repositories/BenchmarkRepo';
import type { BenchmarkDefinition, BenchmarkScoringType } from '../domain/types';
import { BENCHMARK_CATEGORY_ORDER } from '../domain/benchmarks/benchmark-catalog';
import styles from './BenchmarkCreate.module.css';

const SCORING_OPTIONS: { value: BenchmarkScoringType; label: string; desc: string }[] = [
  { value: 'time', label: 'For Time', desc: 'Lower is better' },
  { value: 'reps', label: 'Max Reps', desc: 'Higher is better' },
  { value: 'weight', label: 'Max Load', desc: 'Higher is better' },
  { value: 'roundsAndReps', label: 'AMRAP', desc: 'Rounds + reps' },
  { value: 'distance', label: 'Distance', desc: 'In meters' },
];

export function BenchmarkCreate() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const [name, setName] = useState('');
  const [category, setCategory] = useState(BENCHMARK_CATEGORY_ORDER[0]);
  const [description, setDescription] = useState('');
  const [scoringType, setScoringType] = useState<BenchmarkScoringType>('time');
  const [isSaving, setIsSaving] = useState(false);

  const canCreate = name.trim().length > 0;

  async function handleCreate() {
    if (!user || !canCreate) return;
    setIsSaving(true);
    const def: BenchmarkDefinition = {
      id: `custom-${user.uid}-${Date.now()}`,
      userID: user.uid,
      name: name.trim(),
      category,
      workoutDescription: description.trim(),
      scoringType,
      isPredefined: false,
      sortOrder: 0,
    };
    await getBenchmarkRepo(isGuest).saveCustomBenchmark(user.uid, def);
    navigate('/benchmarks');
  }

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/benchmarks')}>&larr; Benchmarks</button>
      <h1 className={styles.title}>Create Benchmark</h1>

      <label className={styles.label}>Name *</label>
      <input className={styles.input} type="text" placeholder="Benchmark name" value={name} onChange={(e) => setName(e.target.value)} autoFocus />

      <label className={styles.label}>Category</label>
      <div className={styles.chips}>
        {BENCHMARK_CATEGORY_ORDER.map((cat) => (
          <button key={cat} className={`${styles.chip} ${category === cat ? styles.chipActive : ''}`} onClick={() => setCategory(cat)}>{cat}</button>
        ))}
      </div>

      <label className={styles.label}>Description</label>
      <textarea className={styles.textarea} placeholder="Describe the workout..." value={description} onChange={(e) => setDescription(e.target.value)} rows={4} />

      <label className={styles.label}>Scoring Type</label>
      <div className={styles.scoringGrid}>
        {SCORING_OPTIONS.map((opt) => (
          <button key={opt.value} className={`${styles.scoringCard} ${scoringType === opt.value ? styles.scoringActive : ''}`} onClick={() => setScoringType(opt.value)}>
            <span className={styles.scoringLabel}>{opt.label}</span>
            <span className={styles.scoringDesc}>{opt.desc}</span>
          </button>
        ))}
      </div>

      <button className={styles.createBtn} onClick={handleCreate} disabled={!canCreate || isSaving}>
        {isSaving ? 'Creating...' : 'Create Benchmark'}
      </button>
    </div>
  );
}
