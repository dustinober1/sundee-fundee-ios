/**
 * app/(app)/(tabs)/index.tsx — Dashboard.
 *
 * Shows welcome message, Start Workout button (navigates to workout-session),
 * timed workout options (ForTime, AMRAP, EMOM), and a recent workout card.
 *
 * Phase 5 integrations:
 * - ReadinessSurveyCard at top (when no survey today) — ALL users
 * - CyclePhaseBanner — cycle-opted-in users only
 * - WODDashboardCard — today's WOD (expands inline, not workout-session)
 * - AI Workout entry point — navigates to ai-workout/config
 * - Programs, Benchmarks, Injuries quick-access cards
 *
 * Guest users see a contextual upgrade nudge per locked decision:
 * "Create Account option always visible in settings, plus contextual nudges elsewhere"
 */

import React, { useCallback, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { format } from 'date-fns';
import { useSession } from '@/src/auth/AuthContext';
import { getWorkoutRepo, type WorkoutRecord } from '@/src/repositories/WorkoutRepo';
import { getReadinessRepo } from '@/src/repositories/ReadinessRepo';
import { getWODRepo, type WODRecord } from '@/src/repositories/WODRepo';
import { getCycleRepo, recordToPeriodLog } from '@/src/repositories/CycleRepo';
import { calculateCycleStatus } from '@/src/domain/cycle/cycle-calculations';
import type { ReadinessResult } from '@/src/domain/readiness/readiness-survey';
import type { CycleStatusResult } from '@/src/domain/cycle/cycle-calculations';
import ReadinessSurveyCard from '@/src/components/readiness/ReadinessSurveyCard';
import ReadinessSurveyModal from '@/src/components/readiness/ReadinessSurveyModal';
import CyclePhaseBanner from '@/src/components/cycle/CyclePhaseBanner';
import { WODDashboardCard } from '@/src/components/wod/WODDashboardCard';
import { TrialBanner } from '@/src/components/paywall/TrialBanner';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import * as colors from '@/src/theme/colors';

/** Timed workout mode options presented on the dashboard. */
const TIMED_MODES: Array<{ mode: string; label: string; description: string }> = [
  { mode: 'forTime', label: 'For Time', description: 'Race the clock' },
  { mode: 'amrap', label: 'AMRAP', description: 'As Many Rounds As Possible' },
  { mode: 'emom', label: 'EMOM', description: 'Every Minute On the Minute' },
];

/** Format seconds into h:mm:ss or m:ss string. */
export function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) {
    return `${h}h ${m}m`;
  }
  return `${m}m ${String(s).padStart(2, '0')}s`;
}

/** Format a ReadinessResult as a compact badge string, e.g. "Readiness: 7.2/10". */
export function formatReadinessBadge(result: ReadinessResult): string {
  const rounded = Math.round(result.score * 10) / 10;
  return `Readiness: ${rounded}/10`;
}

export default function DashboardScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();
  const [lastWorkout, setLastWorkout] = useState<WorkoutRecord | null>(null);

  // Readiness survey state
  const [showReadinessCard, setShowReadinessCard] = useState(false);
  const [showSurveyModal, setShowSurveyModal] = useState(false);
  const [todayReadiness, setTodayReadiness] = useState<ReadinessResult | null>(null);

  // Cycle phase banner state
  const [cycleStatus, setCycleStatus] = useState<CycleStatusResult | null>(null);

  // WOD state
  const [todayWOD, setTodayWOD] = useState<WODRecord | null>(null);

  // Paywall state (for TrialBanner subscribe CTA)
  const [showPaywall, setShowPaywall] = useState(false);

  const displayName = isGuest
    ? 'Guest'
    : (user?.displayName ?? user?.email ?? 'Athlete');

  const loadLastWorkout = useCallback(async (): Promise<void> => {
    if (!user) return;
    try {
      const repo = getWorkoutRepo(isGuest);
      const history = await repo.getHistory(user.uid);
      if (history.length > 0) {
        const sorted = [...history].sort(
          (a, b) => b.startedAt.getTime() - a.startedAt.getTime()
        );
        setLastWorkout(sorted[0] ?? null);
      } else {
        setLastWorkout(null);
      }
    } catch {
      setLastWorkout(null);
    }
  }, [user, isGuest]);

  const checkTodayReadiness = useCallback(async (): Promise<void> => {
    if (!user) return;
    try {
      const todayDate = format(new Date(), 'yyyy-MM-dd');
      const repo = getReadinessRepo(isGuest);
      const existing = await repo.getSurveyForDate(user.uid, todayDate);
      if (existing != null) {
        setTodayReadiness(existing.result);
        setShowReadinessCard(false);
      } else {
        setShowReadinessCard(true);
      }
    } catch {
      // Non-critical — show card on error so user can still submit
      setShowReadinessCard(true);
    }
  }, [user, isGuest]);

  const loadCycleStatus = useCallback(async (): Promise<void> => {
    if (!user) return;
    try {
      const cycleRepo = getCycleRepo(isGuest);
      const [periodLogRecords, cycleSettings] = await Promise.all([
        cycleRepo.getPeriodLogs(user.uid),
        cycleRepo.getCycleSettings(user.uid),
      ]);
      if (cycleSettings?.cycleTrackingEnabled === true && periodLogRecords.length > 0) {
        const periodLogs = periodLogRecords.map(recordToPeriodLog);
        const status = calculateCycleStatus(periodLogs, cycleSettings);
        setCycleStatus(status);
      } else {
        setCycleStatus(null);
      }
    } catch {
      setCycleStatus(null);
    }
  }, [user, isGuest]);

  const loadTodayWOD = useCallback(async (): Promise<void> => {
    try {
      const todayDate = format(new Date(), 'yyyy-MM-dd');
      const wodRepo = getWODRepo();
      const wod = await wodRepo.getWODForDate(todayDate);
      setTodayWOD(wod);
    } catch {
      setTodayWOD(null);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      void loadLastWorkout();
      void checkTodayReadiness();
      void loadCycleStatus();
      void loadTodayWOD();
    }, [loadLastWorkout, checkTodayReadiness, loadCycleStatus, loadTodayWOD])
  );

  function handleStartWorkout(): void {
    router.push('/workout-session');
  }

  function handleStartTimedWorkout(mode: string): void {
    router.push({ pathname: '/workout-session', params: { timerMode: mode } });
  }

  function handleReadinessSurveyComplete(result: ReadinessResult): void {
    setShowSurveyModal(false);
    setShowReadinessCard(false);
    setTodayReadiness(result);
  }

  return (
    <ScrollView
      style={styles.scrollView}
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Welcome */}
      <View style={styles.welcomeSection}>
        <Text style={styles.greeting}>Welcome back,</Text>
        <Text style={styles.displayName}>{displayName}</Text>
        {!isGuest && user?.email != null && (
          <Text style={styles.email}>{user.email}</Text>
        )}
        {/* Readiness badge — shown when survey is complete for today */}
        {todayReadiness != null && (
          <View style={styles.readinessBadge} testID="readiness-badge">
            <Text style={styles.readinessBadgeText}>
              {formatReadinessBadge(todayReadiness)}
            </Text>
          </View>
        )}
      </View>

      {/* Trial Banner — shown on days 6-7 of free trial */}
      <TrialBanner onSubscribe={() => setShowPaywall(true)} />

      {/* Readiness survey card — shown when no survey completed today */}
      {showReadinessCard && todayReadiness == null && (
        <ReadinessSurveyCard
          onPress={() => setShowSurveyModal(true)}
          onDismiss={() => setShowReadinessCard(false)}
        />
      )}

      {/* Cycle phase banner — shown for cycle-opted-in users with logged data */}
      {cycleStatus !== null && (
        <CyclePhaseBanner
          cycleStatus={cycleStatus}
          onPress={() => router.push('/(app)/(tabs)/cycle')}
        />
      )}

      {/* WOD card — today's Workout of the Day */}
      <WODDashboardCard
        wod={todayWOD}
        onStart={() => {
          // Inline expand is handled inside WODDashboardCard
        }}
        onViewAll={() => router.push('/wods')}
      />

      {/* Primary Start Workout CTA */}
      <TouchableOpacity
        style={styles.startWorkoutButton}
        onPress={handleStartWorkout}
        activeOpacity={0.85}
        testID="start-workout-button"
      >
        <Text style={styles.startWorkoutText}>Start Workout</Text>
        <Text style={styles.startWorkoutSubtext}>Strength • Custom • Open</Text>
      </TouchableOpacity>

      {/* AI Workout entry point */}
      <TouchableOpacity
        style={styles.aiWorkoutButton}
        onPress={() => router.push('/ai-workout/config')}
        activeOpacity={0.85}
        testID="ai-workout-button"
      >
        <Text style={styles.aiWorkoutTitle}>Generate AI Workout</Text>
        <Text style={styles.aiWorkoutSubtext}>
          Personalized for your cycle, readiness, and injuries
        </Text>
      </TouchableOpacity>

      {/* Quick access cards: Programs, Benchmarks, Injuries */}
      <View style={styles.quickAccessSection}>
        <Text style={styles.sectionTitle}>Quick Access</Text>
        <View style={styles.quickAccessGrid}>
          <TouchableOpacity
            style={styles.quickAccessCard}
            onPress={() => router.push('/programs')}
            activeOpacity={0.8}
            testID="programs-card"
          >
            <Text style={styles.quickAccessIcon}>📋</Text>
            <Text style={styles.quickAccessLabel}>Programs</Text>
            <Text style={styles.quickAccessSub}>Structured training</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.quickAccessCard}
            onPress={() => router.push('/benchmarks')}
            activeOpacity={0.8}
            testID="benchmarks-card"
          >
            <Text style={styles.quickAccessIcon}>🏆</Text>
            <Text style={styles.quickAccessLabel}>Benchmarks</Text>
            <Text style={styles.quickAccessSub}>Track your PRs</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.quickAccessCard}
            onPress={() => router.push('/injuries')}
            activeOpacity={0.8}
            testID="injuries-card"
          >
            <Text style={styles.quickAccessIcon}>🩹</Text>
            <Text style={styles.quickAccessLabel}>Injuries</Text>
            <Text style={styles.quickAccessSub}>Manage & adapt</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Recent workout card */}
      {lastWorkout != null && (
        <View style={styles.recentCard}>
          <Text style={styles.recentLabel}>Last Workout</Text>
          <Text style={styles.recentTitle} numberOfLines={1}>
            {lastWorkout.name ?? 'Custom Workout'}
          </Text>
          <Text style={styles.recentMeta}>
            {lastWorkout.startedAt.toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
              year: 'numeric',
            })}
            {lastWorkout.durationSeconds != null &&
              `  ·  ${formatDuration(lastWorkout.durationSeconds)}`}
          </Text>
        </View>
      )}

      {/* Timed workout modes */}
      <View style={styles.timedSection}>
        <Text style={styles.sectionTitle}>Timed Workout</Text>
        <View style={styles.timedGrid}>
          {TIMED_MODES.map(({ mode, label, description }) => (
            <TouchableOpacity
              key={mode}
              style={styles.timedCard}
              onPress={() => handleStartTimedWorkout(mode)}
              activeOpacity={0.8}
              testID={`timed-mode-${mode}`}
            >
              <Text style={styles.timedLabel}>{label}</Text>
              <Text style={styles.timedDescription}>{description}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Guest upgrade nudge (per locked decision) */}
      {isGuest && (
        <View style={styles.upgradeNudge}>
          <Text style={styles.nudgeTitle}>Save Your Progress</Text>
          <Text style={styles.nudgeBody}>
            Create an account to sync your data across devices and never lose
            your training history.
          </Text>
          <TouchableOpacity
            style={styles.nudgeButton}
            onPress={() => router.push('/sign-in')}
            activeOpacity={0.8}
            testID="create-account-nudge"
          >
            <Text style={styles.nudgeButtonText}>Create Account</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Readiness survey modal */}
      <ReadinessSurveyModal
        visible={showSurveyModal}
        onComplete={handleReadinessSurveyComplete}
        onDismiss={() => setShowSurveyModal(false)}
      />

      {/* Paywall modal (opened by TrialBanner subscribe CTA) */}
      <PaywallModal
        visible={showPaywall}
        onDismiss={() => setShowPaywall(false)}
        onSubscribed={() => setShowPaywall(false)}
      />
    </ScrollView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  container: {
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 40,
    gap: 16,
  },
  welcomeSection: {
    marginBottom: 4,
  },
  greeting: {
    fontSize: 16,
    color: colors.NAVY_MEDIUM,
    marginBottom: 4,
  },
  displayName: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  email: {
    fontSize: 13,
    color: colors.GREY,
    marginTop: 2,
  },
  readinessBadge: {
    marginTop: 8,
    alignSelf: 'flex-start',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  readinessBadgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.3,
  },
  startWorkoutButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 14,
    paddingVertical: 22,
    paddingHorizontal: 24,
    alignItems: 'center',
    shadowColor: colors.ORANGE_DARK,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 6,
  },
  startWorkoutText: {
    fontSize: 20,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  startWorkoutSubtext: {
    fontSize: 13,
    color: colors.CREAM,
    opacity: 0.85,
    letterSpacing: 0.3,
  },
  aiWorkoutButton: {
    backgroundColor: colors.NAVY,
    borderRadius: 14,
    paddingVertical: 18,
    paddingHorizontal: 24,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: colors.ORANGE,
  },
  aiWorkoutTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  aiWorkoutSubtext: {
    fontSize: 12,
    color: colors.CREAM,
    opacity: 0.75,
    textAlign: 'center',
    letterSpacing: 0.2,
  },
  quickAccessSection: {},
  quickAccessGrid: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 10,
  },
  quickAccessCard: {
    flex: 1,
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    paddingVertical: 14,
    paddingHorizontal: 8,
    alignItems: 'center',
    gap: 4,
  },
  quickAccessIcon: {
    fontSize: 22,
    marginBottom: 2,
  },
  quickAccessLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.NAVY,
    textAlign: 'center',
  },
  quickAccessSub: {
    fontSize: 10,
    color: colors.GREY,
    textAlign: 'center',
    lineHeight: 13,
  },
  recentCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    paddingVertical: 14,
    paddingHorizontal: 16,
  },
  recentLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 4,
  },
  recentTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  recentMeta: {
    fontSize: 12,
    color: colors.GREY,
  },
  timedSection: {},
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  timedGrid: {
    flexDirection: 'row',
    gap: 10,
  },
  timedCard: {
    flex: 1,
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: colors.NAVY,
    paddingVertical: 14,
    paddingHorizontal: 10,
    alignItems: 'center',
  },
  timedLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 3,
    textAlign: 'center',
  },
  timedDescription: {
    fontSize: 10,
    color: colors.GREY,
    textAlign: 'center',
    lineHeight: 13,
  },
  upgradeNudge: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    padding: 20,
  },
  nudgeTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 8,
  },
  nudgeBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
    marginBottom: 16,
  },
  nudgeButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  nudgeButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
});
