/**
 * Dashboard — home screen with welcome, quick actions, and today's WOD.
 */
import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { useEntitlementContext } from '../entitlements/EntitlementContext';
import { getWODRepo, type WODRecord } from '../repositories/WODRepo';
import { getOnboardingProfileRepo, type OnboardingProfile } from '../repositories/OnboardingProfileRepo';
import { SkeletonCard } from '../components/SkeletonCard';
import styles from './Dashboard.module.css';

export function Dashboard() {
  const { user, isGuest } = useSession();
  const { isPremium } = useEntitlementContext();
  const [profile, setProfile] = useState<OnboardingProfile | null>(null);
  const [todayWOD, setTodayWOD] = useState<WODRecord | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    const profileFetch = user
      ? getOnboardingProfileRepo(isGuest).getProfile(user.uid).then(setProfile).catch(() => {})
      : Promise.resolve();
    const wodFetch = getWODRepo().getWODForDate(today).then(setTodayWOD).catch(() => {});
    Promise.all([profileFetch, wodFetch]).finally(() => setIsLoading(false));
  }, [user, isGuest]);

  const displayName = profile?.name || user?.displayName || 'Athlete';

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <h1 className={styles.greeting}>Hey, {displayName}</h1>
        {isPremium && <span className={styles.badge}>Premium</span>}
      </header>

      {/* Quick action: Start Workout */}
      <Link to="/workout" className={styles.startBtn}>
        Start Workout
      </Link>

      {isLoading ? (
        <SkeletonCard count={3} height={80} />
      ) : (
        <>
          {/* Quick links grid */}
          <div className={styles.grid}>
            <Link to="/programs" className={styles.card}>
              <span className={styles.cardIcon}>📋</span>
              <span className={styles.cardLabel}>Programs</span>
            </Link>
            <Link to="/benchmarks" className={styles.card}>
              <span className={styles.cardIcon}>🏆</span>
              <span className={styles.cardLabel}>Benchmarks</span>
            </Link>
            <Link to="/ai-workout" className={styles.card}>
              <span className={styles.cardIcon}>🤖</span>
              <span className={styles.cardLabel}>AI Workout</span>
            </Link>
            <Link to="/injuries" className={styles.card}>
              <span className={styles.cardIcon}>🩹</span>
              <span className={styles.cardLabel}>Injuries</span>
            </Link>
          </div>

          {/* Today's WOD */}
          {todayWOD && (
            <Link to="/wods" className={styles.wodCard}>
              <div className={styles.wodHeader}>
                <span className={styles.wodLabel}>WOD</span>
                <span className={styles.wodDate}>{todayWOD.date}</span>
              </div>
              <h3 className={styles.wodName}>{todayWOD.name}</h3>
              <p className={styles.wodDesc}>{todayWOD.description}</p>
            </Link>
          )}
        </>
      )}
    </div>
  );
}
