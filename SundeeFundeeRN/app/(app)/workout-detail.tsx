/**
 * workout-detail.tsx — Full workout detail modal screen.
 *
 * Displays all exercises and sets for a completed workout.
 * Navigated to from the History tab (HistoryCard.onPress).
 *
 * Route params: workoutId (string)
 *
 * Layout:
 *   Header: workout name, date, duration, source badge
 *   Custom/Program: exercise name, muscle group badge, set table (set #, weight, reps, PR badge)
 *   AI workouts: exercise name, sets x reps scheme, prescribed weight
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
import {
  getWorkoutRepo,
  type WorkoutRecord,
  type CompletedExercise,
} from '@/src/repositories/WorkoutRepo';
import type { GeneratedExercise } from '@/src/domain/ai-workout/generated-workout';
import { formatDuration } from '@/src/components/history/HistoryCard';
import * as colors from '@/src/theme/colors';

// ─── Date formatting ──────────────────────────────────────────────────────────

function formatDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ─── Source badge ─────────────────────────────────────────────────────────────

function SourceBadge({ source }: { source: WorkoutRecord['source'] }): React.JSX.Element {
  const colorMap: Record<WorkoutRecord['source'], string> = {
    ai: '#2563EB',
    program: '#16A34A',
    custom: colors.ORANGE,
  };
  const labelMap: Record<WorkoutRecord['source'], string> = {
    ai: 'AI Workout',
    program: 'Program',
    custom: 'Custom',
  };

  return (
    <View style={[styles.badge, { backgroundColor: colorMap[source] }]}>
      <Text style={styles.badgeText}>{labelMap[source]}</Text>
    </View>
  );
}

// ─── WorkoutDetailScreen ──────────────────────────────────────────────────────

export default function WorkoutDetailScreen(): React.JSX.Element {
  const { workoutId } = useLocalSearchParams<{ workoutId: string }>();
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [record, setRecord] = useState<WorkoutRecord | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user || !workoutId) return;

    async function load(): Promise<void> {
      if (!user || !workoutId) return;
      try {
        const repo = getWorkoutRepo(isGuest);
        const data = await repo.getWorkout(user.uid, workoutId);
        if (data) {
          setRecord(data);
        } else {
          setError('Workout not found.');
        }
      } catch (err) {
        console.error('[WorkoutDetail] Load failed:', err);
        setError('Failed to load workout details.');
      } finally {
        setIsLoading(false);
      }
    }

    void load();
  }, [user, isGuest, workoutId]);

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  if (error || !record) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>{error ?? 'Workout not found.'}</Text>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Text style={styles.backButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const displayName =
    record.workoutName ?? (record.source === 'ai' ? 'AI Workout' : 'Custom Workout');
  const customExercises: CompletedExercise[] = record.exercises ?? [];
  const aiExercises: GeneratedExercise[] = record.workout?.exercises ?? [];

  const exerciseCount =
    record.exerciseCount ??
    (customExercises.length > 0 ? customExercises.length : aiExercises.length);

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
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Workout meta info */}
        <View style={styles.metaCard}>
          <View style={styles.metaRow}>
            <Text style={styles.metaDate}>{formatDate(record.completedAt)}</Text>
            <SourceBadge source={record.source} />
          </View>
          <View style={styles.metaStats}>
            <MetaStat label="Duration" value={formatDuration(record.durationSeconds)} />
            {exerciseCount > 0 && (
              <MetaStat label="Exercises" value={String(exerciseCount)} />
            )}
            {record.totalVolume !== undefined && (
              <MetaStat label="Volume" value={`${record.totalVolume} lbs`} />
            )}
          </View>
        </View>

        {/* Custom / Program exercises (logged sets with actual weight+reps) */}
        {customExercises.length > 0 &&
          customExercises.map((exercise, exIdx) => (
            <CompletedExerciseSection
              key={`${exercise.exerciseId}-${exIdx}`}
              exercise={exercise}
            />
          ))}

        {/* AI workout exercises (prescribed, no logged sets) */}
        {customExercises.length === 0 && aiExercises.length > 0 &&
          aiExercises.map((exercise, exIdx) => (
            <AIExerciseSection key={`${exercise.id}-${exIdx}`} exercise={exercise} />
          ))}

        {/* Nothing available */}
        {customExercises.length === 0 && aiExercises.length === 0 && (
          <View style={styles.noExercises}>
            <Text style={styles.noExercisesText}>
              No exercise details available for this workout.
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

// ─── CompletedExerciseSection (custom/program workouts) ──────────────────────

function CompletedExerciseSection({
  exercise,
}: {
  exercise: CompletedExercise;
}): React.JSX.Element {
  return (
    <View style={styles.exerciseCard}>
      <View style={styles.exerciseHeader}>
        <Text style={styles.exerciseName}>{exercise.exerciseName}</Text>
        {exercise.muscleGroup ? (
          <View style={styles.muscleGroupBadge}>
            <Text style={styles.muscleGroupText}>{exercise.muscleGroup}</Text>
          </View>
        ) : null}
      </View>

      {exercise.sets.length > 0 && (
        <View style={styles.setsTable}>
          <View style={styles.setRowHeader}>
            <Text style={[styles.setCell, styles.setCellHeader, styles.setNumCell]}>Set</Text>
            <Text style={[styles.setCell, styles.setCellHeader, styles.setWeightCell]}>
              Weight
            </Text>
            <Text style={[styles.setCell, styles.setCellHeader, styles.setRepsCell]}>Reps</Text>
            <Text style={[styles.setCell, styles.setCellHeader, styles.setPRCell]}></Text>
          </View>

          {exercise.sets.map((set, idx) => (
            <View key={idx} style={[styles.setRow, idx % 2 === 1 && styles.setRowAlt]}>
              <Text style={[styles.setCell, styles.setNumCell]}>{idx + 1}</Text>
              <Text style={[styles.setCell, styles.setWeightCell]}>
                {set.weight > 0 ? `${set.weight} lbs` : '—'}
              </Text>
              <Text style={[styles.setCell, styles.setRepsCell]}>
                {set.reps > 0 ? String(set.reps) : '—'}
              </Text>
              <View style={[styles.setCell, styles.setPRCell]}>
                {set.isPersonalRecord && (
                  <View style={styles.prBadge}>
                    <Text style={styles.prBadgeText}>PR</Text>
                  </View>
                )}
              </View>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

// ─── AIExerciseSection (AI-generated workout prescriptions) ──────────────────

function AIExerciseSection({ exercise }: { exercise: GeneratedExercise }): React.JSX.Element {
  const prescription = `${exercise.sets} × ${exercise.reps}`;
  const weightText =
    exercise.weightLb !== null && exercise.weightLb > 0
      ? `${exercise.weightLb} lbs`
      : exercise.bodyweightOnly
        ? 'Bodyweight'
        : null;

  return (
    <View style={styles.exerciseCard}>
      <View style={styles.exerciseHeader}>
        <Text style={styles.exerciseName}>{exercise.name}</Text>
        <Text style={styles.prescriptionText}>{prescription}</Text>
      </View>

      {(weightText !== null || exercise.notes !== null) && (
        <View style={styles.exerciseMeta}>
          {weightText !== null && (
            <Text style={styles.exerciseMetaText}>Weight: {weightText}</Text>
          )}
          {exercise.notes !== null && (
            <Text style={styles.exerciseMetaText}>{exercise.notes}</Text>
          )}
        </View>
      )}
    </View>
  );
}

// ─── MetaStat helper ──────────────────────────────────────────────────────────

function MetaStat({ label, value }: { label: string; value: string }): React.JSX.Element {
  return (
    <View style={styles.metaStatItem}>
      <Text style={styles.metaStatValue}>{value}</Text>
      <Text style={styles.metaStatLabel}>{label}</Text>
    </View>
  );
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
    padding: 24,
    gap: 16,
  },
  errorText: {
    fontSize: 16,
    color: colors.RED,
    textAlign: 'center',
  },
  backButton: {
    backgroundColor: colors.ORANGE,
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 20,
  },
  backButtonText: {
    color: colors.CREAM,
    fontWeight: '700',
    fontSize: 15,
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
  scrollContent: {
    padding: 16,
    gap: 12,
  },
  metaCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E4D6',
    gap: 12,
    marginBottom: 4,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  metaDate: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    fontWeight: '500',
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 12,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  metaStats: {
    flexDirection: 'row',
    gap: 20,
  },
  metaStatItem: {
    alignItems: 'center',
    gap: 2,
  },
  metaStatValue: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.NAVY,
  },
  metaStatLabel: {
    fontSize: 11,
    color: colors.NAVY_MEDIUM,
    fontWeight: '500',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  noExercises: {
    paddingVertical: 24,
    alignItems: 'center',
  },
  noExercisesText: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
  },
  exerciseCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E8E4D6',
    marginBottom: 4,
    gap: 10,
  },
  exerciseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
  },
  exerciseName: {
    flex: 1,
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  muscleGroupBadge: {
    backgroundColor: colors.ORANGE_LIGHT,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
  },
  muscleGroupText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.3,
  },
  prescriptionText: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.ORANGE,
  },
  exerciseMeta: {
    gap: 2,
  },
  exerciseMetaText: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
  setsTable: {
    borderRadius: 8,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E0DCD0',
  },
  setRowHeader: {
    flexDirection: 'row',
    backgroundColor: colors.NAVY,
    paddingVertical: 6,
    paddingHorizontal: 10,
  },
  setRow: {
    flexDirection: 'row',
    paddingVertical: 8,
    paddingHorizontal: 10,
    backgroundColor: colors.CREAM,
    alignItems: 'center',
  },
  setRowAlt: {
    backgroundColor: colors.CREAM_LIGHT,
  },
  setCell: {
    fontSize: 13,
    color: colors.NAVY,
    fontWeight: '500',
  },
  setCellHeader: {
    color: colors.CREAM,
    fontWeight: '700',
    fontSize: 11,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  setNumCell: {
    width: 36,
  },
  setWeightCell: {
    flex: 1,
  },
  setRepsCell: {
    width: 50,
    textAlign: 'center',
  },
  setPRCell: {
    width: 40,
    alignItems: 'flex-end',
  },
  prBadge: {
    backgroundColor: colors.ORANGE,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
  },
  prBadgeText: {
    color: colors.CREAM,
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
});
