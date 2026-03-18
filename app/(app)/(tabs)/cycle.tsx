/**
 * app/(app)/(tabs)/cycle.tsx — Cycle Tracking Tab.
 *
 * Shows cycle phase, period logging calendar, and a 2-cycle forecast timeline.
 * Only visible to users who opted into cycle tracking (tab hidden via href: null otherwise).
 *
 * Sections:
 *   1. CyclePhaseBanner — current phase + recommendation
 *   2. CycleCalendar — period logging via two-tap interaction
 *   3. PhaseTimeline — 2-cycle forecast
 *
 * Period logging flow:
 *   - First tap: sets pendingStartDate (visual indicator on calendar)
 *   - Second tap on a later date: creates PeriodLog, saves to CycleRepo
 *   - Validates endDate > startDate
 *
 * Data loading via useFocusEffect so it refreshes on tab focus.
 */

import React, { useCallback, useState } from 'react';
import {
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useEntitlementContext } from '@/src/entitlements/EntitlementContext';
import {
  getCycleRepo,
  periodLogToRecord,
  recordToPeriodLog,
} from '@/src/repositories/CycleRepo';
import {
  calculateCycleStatus,
  type CycleStatusResult,
} from '@/src/domain/cycle/cycle-calculations';
import type { CycleSettings, PeriodLog } from '@/src/domain/types/index';
import CycleCalendar from '@/src/components/cycle/CycleCalendar';
import CyclePhaseBanner from '@/src/components/cycle/CyclePhaseBanner';
import PhaseTimeline, {
  buildTimelineBoundaries,
  type TimelineBoundary,
} from '@/src/components/cycle/PhaseTimeline';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import { PremiumBadge } from '@/src/components/paywall/PremiumBadge';
import { logEvent } from '@/src/firebase/analytics';
import * as colors from '@/src/theme/colors';
import { format } from 'date-fns';

/** Default cycle settings when user has not configured custom values. */
const DEFAULT_CYCLE_SETTINGS: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

/** Generate a UUID-like string for period log IDs. */
function generateId(): string {
  return `period_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

export default function CycleScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const { isPremium } = useEntitlementContext();

  const [periodLogs, setPeriodLogs] = useState<PeriodLog[]>([]);
  const [settings, setSettings] = useState<CycleSettings>(DEFAULT_CYCLE_SETTINGS);
  const [cycleStatus, setCycleStatus] = useState<CycleStatusResult | null>(null);
  const [timelineBoundaries, setTimelineBoundaries] = useState<TimelineBoundary[]>([]);
  const [pendingStart, setPendingStart] = useState<string | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(true);
  const [showPaywall, setShowPaywall] = useState(false);

  // ─── Load cycle data on focus ────────────────────────────────────────────

  const loadCycleData = useCallback(async (): Promise<void> => {
    if (!user) return;
    try {
      const repo = getCycleRepo(isGuest);
      const [records, savedSettings] = await Promise.all([
        repo.getPeriodLogs(user.uid),
        repo.getCycleSettings(user.uid),
      ]);

      const effectiveSettings = savedSettings ?? DEFAULT_CYCLE_SETTINGS;
      const logs = records.map(recordToPeriodLog);

      const status = calculateCycleStatus(logs, effectiveSettings) ?? null;

      // Build 2-cycle forecast from earliest known start or today
      const forecastStart = status?.phaseStartDate ?? new Date();
      const boundaries = buildTimelineBoundaries(
        forecastStart,
        effectiveSettings.averageCycleLengthDays,
        effectiveSettings.averagePeriodLengthDays,
        effectiveSettings.lutealPhaseLengthDays,
        2
      );

      setPeriodLogs(logs);
      setSettings(effectiveSettings);
      setCycleStatus(status);
      setTimelineBoundaries(boundaries);
    } catch {
      // Degrade gracefully — keep empty state
    } finally {
      setIsLoading(false);
    }
  }, [user, isGuest]);

  useFocusEffect(
    useCallback(() => {
      void loadCycleData();
    }, [loadCycleData])
  );

  // ─── Period logging via two-tap interaction ──────────────────────────────

  function handleDayPress(dateString: string): void {
    if (pendingStart == null) {
      // First tap — set pending start date
      setPendingStart(dateString);
    } else {
      // Second tap — validate and save
      if (dateString < pendingStart) {
        Alert.alert(
          'Invalid Date',
          'End date must be on or after the start date.',
          [{ text: 'OK' }]
        );
        setPendingStart(undefined);
        return;
      }

      if (dateString === pendingStart) {
        // Single-day period (same start and end)
        void savePeriodLog(pendingStart, pendingStart);
      } else {
        void savePeriodLog(pendingStart, dateString);
      }

      setPendingStart(undefined);
    }
  }

  async function savePeriodLog(startStr: string, endStr: string): Promise<void> {
    if (!user) return;
    try {
      const log: PeriodLog = {
        startDate: new Date(startStr),
        endDate: new Date(endStr),
      };
      const record = periodLogToRecord(user.uid, generateId(), log);
      await getCycleRepo(isGuest).savePeriodLog(user.uid, record);
      void logEvent('cycle_phase_updated');
      // Reload data to reflect new log
      await loadCycleData();
    } catch {
      Alert.alert('Error', 'Could not save period log. Please try again.');
    }
  }

  function handleCancelPending(): void {
    setPendingStart(undefined);
  }

  // ─── Render ──────────────────────────────────────────────────────────────

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  const isEmpty = periodLogs.length === 0;

  return (
    <ScrollView
      style={styles.scrollView}
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Phase Banner */}
      <CyclePhaseBanner cycleStatus={cycleStatus} />

      {/* Pending start instruction */}
      {pendingStart != null && (
        <View style={styles.pendingBanner}>
          <Text style={styles.pendingText}>
            Start date: {format(new Date(pendingStart), 'MMM d')} — now tap the end date
          </Text>
          <TouchableOpacity onPress={handleCancelPending} activeOpacity={0.7}>
            <Text style={styles.cancelText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Period Logging Calendar */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Period Calendar</Text>
        {pendingStart == null && (
          <Text style={styles.calendarHint}>Tap a date to log your period start</Text>
        )}
        <CycleCalendar
          periodLogs={periodLogs}
          onDayPress={handleDayPress}
          pendingStart={pendingStart}
        />
      </View>

      {/* Empty state */}
      {isEmpty && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyTitle}>Log your first period</Text>
          <Text style={styles.emptyBody}>
            Tap a start date above, then tap an end date to log a period. Cycle
            predictions will appear after your first log.
          </Text>
        </View>
      )}

      {/* 2-Cycle Forecast */}
      {!isEmpty && (
        <View style={styles.section}>
          <PhaseTimeline
            boundaries={timelineBoundaries}
            currentDate={new Date()}
          />
        </View>
      )}

      {/* Cycle Adaptation section — Premium only */}
      <TouchableOpacity
        style={styles.adaptationSection}
        onPress={() => {
          if (!isPremium) {
            setShowPaywall(true);
          }
        }}
        activeOpacity={isPremium ? 1 : 0.7}
        testID="cycle-adaptation-section"
      >
        <View style={styles.adaptationHeader}>
          <Text style={styles.sectionTitle}>Cycle Adaptation</Text>
          {!isPremium && <PremiumBadge />}
        </View>
        <Text style={styles.adaptationBody}>
          {isPremium
            ? 'Your workouts automatically adapt based on your current cycle phase — intensity, volume, and exercise selection are optimized for you.'
            : 'Unlock Premium to automatically adapt your workouts to your cycle phase.'}
        </Text>
      </TouchableOpacity>

      {/* Paywall for non-premium users */}
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
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  loadingText: {
    fontSize: 15,
    color: colors.GREY,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  calendarHint: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
    marginBottom: 10,
  },
  pendingBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    paddingVertical: 10,
    paddingHorizontal: 14,
    marginBottom: 16,
  },
  pendingText: {
    flex: 1,
    fontSize: 13,
    color: colors.NAVY,
    fontWeight: '500',
  },
  cancelText: {
    fontSize: 13,
    color: colors.ORANGE,
    fontWeight: '600',
    marginLeft: 12,
  },
  emptyState: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 20,
    alignItems: 'center',
    marginBottom: 24,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 8,
  },
  emptyBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 19,
    textAlign: 'center',
  },
  adaptationSection: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 16,
    marginBottom: 24,
  },
  adaptationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  adaptationBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 19,
  },
});
