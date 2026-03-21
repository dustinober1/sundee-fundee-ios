/**
 * Benchmarks catalog — predefined + custom benchmarks grouped by category.
 */
import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { getBenchmarkRepo } from '../repositories/BenchmarkRepo';
import type { BenchmarkDefinition } from '../domain/types';
import { BENCHMARK_CATALOG, BENCHMARK_CATEGORY_ORDER } from '../domain/benchmarks/benchmark-catalog';
import styles from './Benchmarks.module.css';

export function Benchmarks() {
  const { user, isGuest } = useSession();
  const navigate = useNavigate();
  const [customBenchmarks, setCustomBenchmarks] = useState<BenchmarkDefinition[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      const customs = await getBenchmarkRepo(isGuest).getCustomBenchmarks(user.uid);
      setCustomBenchmarks(customs);
    } catch { /* empty */ }
    setIsLoading(false);
  }, [user, isGuest]);

  useEffect(() => { load(); }, [load]);

  // Group predefined by category
  const grouped = new Map<string, BenchmarkDefinition[]>();
  for (const cat of BENCHMARK_CATEGORY_ORDER) {
    const items = BENCHMARK_CATALOG.filter((b) => b.category === cat);
    if (items.length > 0) grouped.set(cat, items);
  }

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Benchmarks</h1>

      {isLoading ? (
        <div className={styles.center}><div className={styles.spinner} /></div>
      ) : (
        <>
          {Array.from(grouped.entries()).map(([category, items]) => (
            <div key={category} className={styles.section}>
              <h3 className={styles.sectionTitle}>{category}</h3>
              {items.map((b) => (
                <Link
                  key={b.id}
                  to={`/benchmarks/${b.id}?name=${encodeURIComponent(b.name)}&scoring=${b.scoringType}&predefined=true`}
                  className={styles.row}
                >
                  <span className={styles.rowName}>{b.name}</span>
                  <span className={styles.rowBadge}>{b.scoringType}</span>
                </Link>
              ))}
            </div>
          ))}

          {customBenchmarks.length > 0 && (
            <div className={styles.section}>
              <h3 className={styles.sectionTitle}>Custom</h3>
              {customBenchmarks.map((b) => (
                <Link
                  key={b.id}
                  to={`/benchmarks/${b.id}?name=${encodeURIComponent(b.name)}&scoring=${b.scoringType}&predefined=false`}
                  className={styles.row}
                >
                  <span className={styles.rowName}>{b.name}</span>
                  <span className={styles.rowBadge}>{b.scoringType}</span>
                </Link>
              ))}
            </div>
          )}

          <button className={styles.fab} onClick={() => navigate('/benchmarks/create')}>+ Create Custom</button>
        </>
      )}
    </div>
  );
}
