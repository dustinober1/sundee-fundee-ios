/**
 * app/(app)/ai-workout/preview.tsx — AI Workout Preview Screen.
 *
 * Displays the generated workout with:
 *   - Summary header: name, estimated duration, exercise count
 *   - Offline badge (if generated offline)
 *   - Exercise list with sets/reps/weight and injury substitution labels
 *   - AdaptationChip showing what was factored in
 *
 * Two action buttons:
 *   - Start Workout: saves to history with source 'ai', navigates to workout-session
 *   - Regenerate: navigates back to config (DOES NOT save)
 *
 * CRITICAL: Workout is saved ONLY on "Start Workout" tap — not on preview load.
 *
 * Art Deco styling: cream exercise cards, navy text, orange Start button.
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import type { GeneratedWorkout, GeneratedExercise } from '@/src/domain/ai-workout/generated-workout';
import { totalEstimatedMinutes } from '@/src/domain/ai-workout/generated-workout';
import { getSharedWorkout, clearSharedWorkout } from './config';
import { AdaptationChip } from '@/src/components/ai-workout/AdaptationChip';
import type { CyclePhase } from '@/src/domain/types';
import type { InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '@/src/repositories/ReadinessRepo';
import * as colors from '@/src/theme/colors';

// ─── Exercise row ─────────────────────────────────────────────────────────────

interface ExerciseRowProps {
  exercise: GeneratedExercise;
  index: number;
}

function ExerciseRow({ exercise, index }: ExerciseRowProps): React.JSX.Element {
  const hasSubstitution = exercise.notes?.startsWith('Substituted for');

  return (
    <View style={styles.exerciseCard} testID={`exercise-row-${index}`}>
      <View style={styles.exerciseHeader}>
        <Text style={styles.exerciseNumber}>{index + 1}</Text>
        <Text style={styles.exerciseName}>{exercise.name}</Text>
        {exercise.bodyweightOnly ? (
          <View style={styles.bwBadge}>
            <Text style={styles.bwBadgeText}>BW</Text>
          </View>
        ) : null}
      </View>

      <View style={styles.exerciseMeta}>
        <Text style={styles.metaText}>
          {exercise.sets} sets × {exercise.reps}
        </Text>
        {exercise.weightLb != null && (
          <Text style={styles.metaText}> · {exercise.weightLb} lb</Text>
        )}
        {exercise.restMinutes != null && (
          <Text style={styles.metaTextMuted}> · {exercise.restMinutes} min rest</Text>
        )}
      </View>

      {hasSubstitution && exercise.notes ? (
        <Text style={styles.substitutionLabel}>{exercise.notes}</Text>
      ) : null}
    </View>
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function AIWorkoutPreviewScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isGuest } = useSession();
  const uid = user?.uid ?? '';

  const [workout, setWorkout] = useState<GeneratedWorkout | null>(null);
  const [isOffline, setIsOffline] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  // Adaptation context for AdaptationChip (passed via shared state)
  const [cyclePhase, setCyclePhase] = useState<CyclePhase | undefined>(undefined);
  const [injuries, setInjuries] = useState<InjuryProfileRecord[]>([]);
  const [readiness, setReadiness] = useState<ReadinessSurveyRecord | null>(null);

  useEffect(() => {
    // Read the generated workout from shared state (set by config screen)
    const shared = getSharedWorkout();
    if (shared) {
      setWorkout(shared.workout);
      setIsOffline(shared.isOffline);
      // Re-use adaptation context from the config context
      // The WorkoutGenerationContext has cyclePhase and injuries as strings — not full records.
      // We display the adaptation summary from the coaching summary instead via the chip.
    }
    // Do NOT clear shared state here — let Start Workout or Regenerate handle it
  }, []);

  // ── Start Workout ─────────────────────────────────────────────────────────
  const handleStartWorkout = useCallback(async (): Promise<void> => {
    if (!workout || isSaving) return;
    setIsSaving(true);

    try {
      // Save to history ONLY on Start Workout tap (not on preview load — per pitfall 7)
      const workoutRepo = getWorkoutRepo(isGuest);
      await workoutRepo.saveWorkout(uid, {
        id: workout.id,
        uid,
        completedAt: new Date().toISOString(),
        durationSeconds: totalEstimatedMinutes(workout.exercises) * 60,
        source: 'ai',
        workout,
        exerciseCount: workout.exercises.length,
      });

      // Clear shared state after save
      clearSharedWorkout();

      // Navigate to workout session with exercises preloaded
      router.push({
        pathname: '/workout-session',
        params: {
          aiWorkoutId: workout.id,
        },
      } as never);
    } catch (error) {
      console.error('[AIWorkout] Failed to save workout:', error);
      Alert.alert('Save Failed', 'Unable to save workout to history. Please try again.', [
        { text: 'OK' },
      ]);
    } finally {
      setIsSaving(false);
    }
  }, [workout, isSaving, uid, isGuest, router]);

  // ── Regenerate ────────────────────────────────────────────────────────────
  const handleRegenerate = useCallback((): void => {
    // Navigate back to config screen — do NOT save workout
    // Config screen will re-generate with same options
    clearSharedWorkout();
    router.back();
  }, [router]);

  // ── Empty state ───────────────────────────────────────────────────────────
  if (!workout) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyText}>No workout generated yet.</Text>
        <Pressable style={styles.backButton} onPress={() => router.back()}>
          <Text style={styles.backButtonText}>Go Back</Text>
        </Pressable>
      </View>
    );
  }

  const estimatedMinutes = totalEstimatedMinutes(workout.exercises);

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <View style={styles.screen}>
      <FlatList
        data={workout.exercises}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.scrollContent}
        ListHeaderComponent={
          <View>
            {/* Offline badge */}
            {isOffline && (
              <View style={styles.offlineBadge} testID="offline-badge">
                <Text style={styles.offlineBadgeText}>
                  Offline · Generated from your preferences
                </Text>
              </View>
            )}

            {/* Workout summary */}
            <View style={styles.summaryCard}>
              <Text style={styles.workoutTitle}>Your Workout</Text>
              <View style={styles.summaryRow}>
                <View style={styles.summaryItem}>
                  <Text style={styles.summaryValue}>{estimatedMinutes}</Text>
                  <Text style={styles.summaryLabel}>min</Text>
                </View>
                <View style={styles.summaryDivider} />
                <View style={styles.summaryItem}>
                  <Text style={styles.summaryValue}>{workout.exercises.length}</Text>
                  <Text style={styles.summaryLabel}>exercises</Text>
                </View>
              </View>
              {workout.coachingSummary ? (
                <Text style={styles.coachingSummary}>{workout.coachingSummary}</Text>
              ) : null}
            </View>

            {/* Adaptation chip */}
            <AdaptationChip
              cyclePhase={cyclePhase}
              injuries={injuries}
              readiness={readiness}
            />

            <Text style={styles.sectionLabel}>Exercises</Text>
          </View>
        }
        renderItem={({ item, index }) => (
          <ExerciseRow exercise={item} index={index} />
        )}
        ListFooterComponent={<View style={{ height: 120 }} />}
      />

      {/* Action buttons */}
      <View style={styles.footer}>
        <Pressable
          style={styles.regenerateButton}
          onPress={handleRegenerate}
          testID="regenerate-button"
        >
          <Text style={styles.regenerateButtonText}>Regenerate</Text>
        </Pressable>

        <Pressable
          style={[styles.startButton, isSaving && styles.startButtonDisabled]}
          onPress={() => void handleStartWorkout()}
          disabled={isSaving}
          testID="start-workout-button"
        >
          <Text style={styles.startButtonText}>
            {isSaving ? 'Saving…' : 'Start Workout'}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 20,
  },

  // Offline badge
  offlineBadge: {
    backgroundColor: colors.NAVY_MEDIUM,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
    marginBottom: 12,
    alignSelf: 'flex-start',
  },
  offlineBadgeText: {
    color: colors.CREAM,
    fontSize: 13,
    fontWeight: '600',
  },

  // Summary
  summaryCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 14,
    padding: 18,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  workoutTitle: {
    color: colors.NAVY,
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  summaryItem: {
    alignItems: 'center',
    flex: 1,
  },
  summaryValue: {
    color: colors.NAVY,
    fontSize: 28,
    fontWeight: '700',
  },
  summaryLabel: {
    color: colors.NAVY_MEDIUM,
    fontSize: 13,
    marginTop: 2,
  },
  summaryDivider: {
    width: 1,
    height: 40,
    backgroundColor: colors.GREY_LIGHT,
  },
  coachingSummary: {
    color: colors.NAVY_MEDIUM,
    fontSize: 13,
    lineHeight: 19,
    fontStyle: 'italic',
    marginTop: 4,
  },

  sectionLabel: {
    color: colors.NAVY,
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
    marginTop: 16,
    marginBottom: 10,
  },

  // Exercise card
  exerciseCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  exerciseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
    gap: 8,
  },
  exerciseNumber: {
    color: colors.ORANGE,
    fontSize: 14,
    fontWeight: '700',
    minWidth: 18,
  },
  exerciseName: {
    color: colors.NAVY,
    fontSize: 16,
    fontWeight: '600',
    flex: 1,
  },
  bwBadge: {
    backgroundColor: colors.NAVY_MEDIUM,
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  bwBadgeText: {
    color: colors.CREAM,
    fontSize: 10,
    fontWeight: '700',
  },
  exerciseMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginLeft: 26,
  },
  metaText: {
    color: colors.NAVY_MEDIUM,
    fontSize: 14,
  },
  metaTextMuted: {
    color: colors.GREY,
    fontSize: 13,
  },
  substitutionLabel: {
    color: colors.ORANGE_DARK,
    fontSize: 12,
    fontStyle: 'italic',
    marginTop: 4,
    marginLeft: 26,
  },

  // Footer
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: 20,
    paddingVertical: 16,
    paddingBottom: 32,
    backgroundColor: colors.CREAM,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
    flexDirection: 'row',
    gap: 12,
  },
  regenerateButton: {
    flex: 1,
    borderWidth: 2,
    borderColor: colors.NAVY,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  regenerateButtonText: {
    color: colors.NAVY,
    fontSize: 16,
    fontWeight: '600',
  },
  startButton: {
    flex: 2,
    backgroundColor: colors.ORANGE,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  startButtonDisabled: {
    backgroundColor: colors.GREY,
  },
  startButtonText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
  },

  // Empty state
  emptyState: {
    flex: 1,
    backgroundColor: colors.CREAM,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 40,
  },
  emptyText: {
    color: colors.NAVY,
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  backButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 10,
    paddingHorizontal: 24,
    paddingVertical: 12,
  },
  backButtonText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '600',
  },
});
