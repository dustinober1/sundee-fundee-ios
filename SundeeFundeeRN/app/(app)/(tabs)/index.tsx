/**
 * app/(app)/(tabs)/index.tsx — Dashboard.
 *
 * Shows welcome message, Start Workout button (navigates to workout-session),
 * timed workout options (ForTime, AMRAP, EMOM), and a recent workout card.
 *
 * Also shows the daily readiness survey prompt at the top when no survey has
 * been completed today. Available to ALL users per locked decision (not gated
 * on cycle tracking). Satisfies CYCL-02 via readiness survey mapping.
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
import type { ReadinessResult } from '@/src/domain/readiness/readiness-survey';
import ReadinessSurveyCard from '@/src/components/readiness/ReadinessSurveyCard';
import ReadinessSurveyModal from '@/src/components/readiness/ReadinessSurveyModal';
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

  useFocusEffect(
    useCallback(() => {
      void loadLastWorkout();
      void checkTodayReadiness();
    }, [loadLastWorkout, checkTodayReadiness])
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

      {/* Readiness survey card — shown when no survey completed today */}
      {showReadinessCard && todayReadiness == null && (
        <ReadinessSurveyCard
          onPress={() => setShowSurveyModal(true)}
          onDismiss={() => setShowReadinessCard(false)}
        />
      )}

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
  },
  welcomeSection: {
    marginBottom: 28,
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
    marginBottom: 16,
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
  recentCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    paddingVertical: 14,
    paddingHorizontal: 16,
    marginBottom: 24,
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
  timedSection: {
    marginBottom: 24,
  },
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
