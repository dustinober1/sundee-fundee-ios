/**
 * exercise-detail.tsx — Exercise detail modal screen.
 *
 * Shows 1RM progress chart, rep-range PR table, and optional volume chart.
 * Navigated to from Maxes tab (ExerciseRow.onPress).
 *
 * Route params: exerciseId (string), exerciseName (string)
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';
import { getSettingsRepo, DEFAULT_SETTINGS } from '@/src/repositories/SettingsRepo';
import type { ExerciseMax } from '@/src/domain/pr-detection/pr-types';
import {
  prepare1RMChartData,
  prepareRepRangePRs,
  prepareVolumeChartData,
  type RepRangePR,
  type ChartDataPoint,
  type CompletedWorkoutRecord,
} from '@/src/domain/progress/progress-data';
import { ProgressChart } from '@/src/components/charts/ProgressChart';
import { RepRangePRTable } from '@/src/components/charts/RepRangePRTable';
import * as colors from '@/src/theme/colors';

// ─── ExerciseDetailScreen ─────────────────────────────────────────────────────

export default function ExerciseDetailScreen(): React.JSX.Element {
  const { exerciseId, exerciseName } = useLocalSearchParams<{
    exerciseId: string;
    exerciseName: string;
  }>();
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [maxes, setMaxes] = useState<ExerciseMax[]>([]);
  const [rmChartData, setRMChartData] = useState<ChartDataPoint[]>([]);
  const [volumeChartData, setVolumeChartData] = useState<ChartDataPoint[]>([]);
  const [repRangePRs, setRepRangePRs] = useState<RepRangePR[]>([]);
  const [best1RM, setBest1RM] = useState<{ weight: number; date: string } | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

  useEffect(() => {
    if (!user) return;
    void (async () => {
      try {
        const settings = await getSettingsRepo(isGuest).getSettings(user.uid);
        if (settings) setWeightUnit(settings.weightUnit);
      } catch (err) {
        console.error('[ExerciseDetail] Settings load failed:', err);
      }
    })();
  }, [user, isGuest]);

  useEffect(() => {
    if (!user || !exerciseId) return;

    async function load(): Promise<void> {
      if (!user || !exerciseId) return;
      try {
        const maxRepo = getExerciseMaxRepo(isGuest);
        const workoutRepo = getWorkoutRepo(isGuest);

        const [exerciseMaxes, workoutHistory] = await Promise.all([
          maxRepo.getMaxes(user.uid, exerciseId),
          workoutRepo.getHistory(user.uid, 50),
        ]);

        // Build chart data
        const rmData = prepare1RMChartData(exerciseMaxes, exerciseId);
        const prs = prepareRepRangePRs(exerciseMaxes, exerciseId);

        // Build volume chart from workout history
        const completedRecords: CompletedWorkoutRecord[] = workoutHistory
          .filter((r) => r.exercises !== undefined && r.exercises.length > 0)
          .map((r) => ({
            id: r.id,
            completedAt: r.completedAt,
            exercises: (r.exercises ?? []).map((ex) => ({
              id: ex.exerciseId,
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              sets: ex.sets.map((s) => ({
                id: `${ex.exerciseId}-${s.weight}-${s.reps}`,
                weight: s.weight,
                reps: s.reps,
                completed: true,
              })),
            })),
          }));

        const volData = prepareVolumeChartData(completedRecords, exerciseId);

        // Best 1RM across all rep ranges
        const allRM = prs.find((p) => p.repRange === 1);
        const bestRM =
          allRM?.weight !== null && allRM?.date !== null
            ? { weight: allRM.weight!, date: allRM.date! }
            : null;

        setMaxes(exerciseMaxes);
        setRMChartData(rmData);
        setVolumeChartData(volData);
        setRepRangePRs(prs);
        setBest1RM(bestRM);
      } catch (err) {
        console.error('[ExerciseDetail] Load failed:', err);
      } finally {
        setIsLoading(false);
      }
    }

    void load();
  }, [user, isGuest, exerciseId]);

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  const displayName = exerciseName ?? 'Exercise';

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.headerBack} onPress={() => router.back()}>
          <Text style={styles.headerBackText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle} numberOfLines={1}>
          {displayName}
        </Text>

        {/* Best 1RM badge */}
        {best1RM !== null && (
          <View style={styles.prBadgeContainer}>
            <Text style={styles.prBadgeLabel}>Current PR</Text>
            <Text style={styles.prBadgeValue}>{formatWeight(best1RM.weight, weightUnit)}</Text>
            <Text style={styles.prBadgeDate}>{formatDate(best1RM.date)}</Text>
          </View>
        )}
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Section 1: 1RM over time */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Estimated 1RM Over Time</Text>
          <ProgressChart
            data={rmChartData}
            yLabel={weightUnit === 'kg' ? 'kg (estimated)' : 'lbs (estimated)'}
          />
        </View>

        {/* Section 2: Rep Range PRs */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Rep Range PRs</Text>
          {repRangePRs.length > 0 ? (
            <RepRangePRTable prs={repRangePRs} weightUnit={weightUnit} />
          ) : (
            <Text style={styles.noDataText}>No PR data available yet.</Text>
          )}
        </View>

        {/* Section 3: Volume over time (optional — only if multiple data points) */}
        {volumeChartData.length > 1 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Volume Over Time</Text>
            <ProgressChart
              data={volumeChartData}
              yLabel={weightUnit === 'kg' ? 'total volume (kg)' : 'total volume (lbs)'}
            />
          </View>
        )}
      </ScrollView>
    </View>
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatDate(isoStr: string): string {
  const date = new Date(isoStr.includes('T') ? isoStr : isoStr + 'T12:00:00');
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  header: {
    backgroundColor: colors.NAVY,
    paddingTop: 56,
    paddingBottom: 16,
    paddingHorizontal: 16,
    gap: 4,
  },
  headerBack: {
    marginBottom: 4,
  },
  headerBackText: {
    color: colors.ORANGE,
    fontSize: 15,
    fontWeight: '600',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  prBadgeContainer: {
    marginTop: 12,
    backgroundColor: colors.ORANGE,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
    alignSelf: 'flex-start',
    gap: 2,
  },
  prBadgeLabel: {
    fontSize: 10,
    color: colors.CREAM,
    fontWeight: '700',
    letterSpacing: 0.8,
    textTransform: 'uppercase',
  },
  prBadgeValue: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.CREAM,
  },
  prBadgeDate: {
    fontSize: 11,
    color: 'rgba(244,240,223,0.8)',
    fontWeight: '500',
  },
  scrollContent: {
    padding: 16,
    gap: 20,
    paddingBottom: 32,
  },
  section: {
    gap: 10,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.3,
    textTransform: 'uppercase',
  },
  noDataText: {
    fontSize: 14,
    color: colors.GREY,
    textAlign: 'center',
    paddingVertical: 16,
  },
});
