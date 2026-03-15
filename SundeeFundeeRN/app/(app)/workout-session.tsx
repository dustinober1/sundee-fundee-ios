/**
 * workout-session.tsx — Active workout logging screen.
 *
 * Features:
 * - Header: "Workout" title, elapsed duration timer, "Finish" button
 * - Body: DraggableFlatList of ExerciseCard components
 * - Floating "Add Exercise" button navigates to exercise-picker modal
 * - RestTimerBar at bottom (visible when timer active)
 * - PRToast overlay
 * - On set completion: check PR, start rest timer
 * - On finish: save workout, navigate back
 * - Empty state: "Tap + to add your first exercise"
 * - On mount: checks for exercise selected from exercise-picker
 * - Notification permission requested on first workout start
 */

import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  ScrollView,
} from 'react-native';
import { router, useFocusEffect, useLocalSearchParams } from 'expo-router';
import * as Notifications from 'expo-notifications';
import DraggableFlatList, { type RenderItemParams } from 'react-native-draggable-flatlist';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { ExerciseCard } from '@/src/components/workout/ExerciseCard';
import { RestTimerBar } from '@/src/components/workout/RestTimerBar';
import { PRToast } from '@/src/components/workout/PRToast';
import { useWorkoutSession } from '@/src/hooks/useWorkoutSession';
import { useRestTimer } from '@/src/hooks/useRestTimer';
import { usePRDetection } from '@/src/hooks/usePRDetection';
import { useSession } from '@/src/auth/AuthContext';
import type { ActiveExercise } from '@/src/domain/workout-session/session-types';
import type { PRCheckResult } from '@/src/domain/pr-detection/pr-types';
import {
  CREAM,
  NAVY,
  NAVY_DARK,
  ORANGE,
  ORANGE_LIGHT,
  CREAM_LIGHT,
  GREY,
  GREY_LIGHT,
} from '@/src/theme/colors';

// ─── Default rest duration ────────────────────────────────────────────────────

const DEFAULT_REST_SECONDS = 90;

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function WorkoutSessionScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const params = useLocalSearchParams<{
    selectedExerciseId?: string;
    selectedExerciseName?: string;
    selectedMuscleGroup?: string;
  }>();

  const {
    session,
    isActive,
    startWorkout,
    finishWorkout,
    dispatchAddExercise,
    dispatchRemoveExercise,
    dispatchAddSet,
    dispatchCompleteSet,
    dispatchReorderExercises,
    getPreviousValues,
  } = useWorkoutSession(isGuest);

  const restTimer = useRestTimer(DEFAULT_REST_SECONDS);
  const prDetection = usePRDetection(isGuest);

  // Store previous values per exercise for ghost text
  const [previousValuesMap, setPreviousValuesMap] = useState<
    Record<string, { weight: number; reps: number }[]>
  >({});

  // Current PR toast to show (first in queue)
  const [currentPR, setCurrentPR] = useState<
    (PRCheckResult & { exerciseName: string }) | null
  >(null);

  // Elapsed timer
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const elapsedIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Track if user has initiated a workout (vs crash recovery)
  const hasStartedRef = useRef(false);

  // ── Start workout on mount (or restore from crash) ──────────────────────
  useEffect(() => {
    if (!isActive && !hasStartedRef.current) {
      startWorkout();
      hasStartedRef.current = true;
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Load maxes for PR detection on session start ─────────────────────────
  useEffect(() => {
    if (isActive && user) {
      void prDetection.loadMaxes(user.uid);
    }
  }, [isActive, user]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Request notification permissions ────────────────────────────────────
  useEffect(() => {
    async function requestNotifPermission(): Promise<void> {
      const { status } = await Notifications.getPermissionsAsync();
      if (status !== 'granted') {
        await Notifications.requestPermissionsAsync();
      }
    }
    void requestNotifPermission();
  }, []);

  // ── Elapsed timer ────────────────────────────────────────────────────────
  useEffect(() => {
    if (isActive) {
      elapsedIntervalRef.current = setInterval(() => {
        setElapsedSeconds((prev) => prev + 1);
      }, 1000);
    }
    return () => {
      if (elapsedIntervalRef.current) {
        clearInterval(elapsedIntervalRef.current);
      }
    };
  }, [isActive]);

  // ── Pick up selected exercise from exercise-picker ───────────────────────
  useFocusEffect(
    useCallback(() => {
      if (
        params.selectedExerciseId &&
        params.selectedExerciseName &&
        params.selectedMuscleGroup
      ) {
        const exerciseId = params.selectedExerciseId;
        const exerciseName = params.selectedExerciseName;
        const muscleGroup = params.selectedMuscleGroup;

        dispatchAddExercise({ exerciseId, exerciseName, muscleGroup });

        // Load previous values for this exercise
        void getPreviousValues(exerciseId).then((values) => {
          setPreviousValuesMap((prev) => ({ ...prev, [exerciseId]: values }));
        });

        // Clear params to prevent re-adding on subsequent focus
        router.setParams({
          selectedExerciseId: undefined,
          selectedExerciseName: undefined,
          selectedMuscleGroup: undefined,
        });
      }
    }, [params.selectedExerciseId, params.selectedExerciseName, params.selectedMuscleGroup, dispatchAddExercise, getPreviousValues]),
  );

  // ── PR toast queue management ────────────────────────────────────────────
  useEffect(() => {
    if (prDetection.recentPRs.length > 0 && !currentPR) {
      const pr = prDetection.recentPRs[0];
      // Find exercise name from session
      const exercise = session?.exercises.find((e) =>
        e.sets.some((s) => s.isPersonalRecord),
      );
      setCurrentPR({
        ...pr,
        exerciseName: exercise?.exerciseName ?? 'Exercise',
      });
    }
  }, [prDetection.recentPRs, currentPR, session]);

  const handleDismissPR = (): void => {
    setCurrentPR(null);
    prDetection.clearRecentPRs();
  };

  // ── Set completion handler ───────────────────────────────────────────────
  const handleCompleteSet = async (
    activeExerciseId: string,
    setId: string,
    weight: number,
    reps: number,
  ): Promise<void> => {
    // Find exercise details for PR check
    const exercise = session?.exercises.find((e) => e.id === activeExerciseId);
    if (!exercise) return;

    // Check for PR
    const prResult = await prDetection.checkAndRecordPR(
      user?.uid ?? '',
      exercise.exerciseId,
      exercise.exerciseName,
      weight,
      reps,
    );

    // Complete the set with PR flag
    dispatchCompleteSet(activeExerciseId, setId, {
      weight,
      reps,
      isPersonalRecord: prResult.isWeightPR || prResult.is1RMPR,
    });

    // Auto-start rest timer
    void restTimer.start(DEFAULT_REST_SECONDS);
  };

  // ── Finish workout ───────────────────────────────────────────────────────
  const handleFinish = (): void => {
    const completedSetsCount =
      session?.exercises.reduce((total, ex) => total + ex.sets.filter((s) => s.completed).length, 0) ?? 0;

    if (completedSetsCount === 0) {
      Alert.alert(
        'Empty Workout',
        'You have no completed sets. Are you sure you want to finish?',
        [
          { text: 'Keep Going', style: 'cancel' },
          { text: 'Discard', style: 'destructive', onPress: () => router.back() },
        ],
      );
      return;
    }

    Alert.alert('Finish Workout?', `${completedSetsCount} sets completed.`, [
      { text: 'Keep Going', style: 'cancel' },
      {
        text: 'Finish',
        onPress: async () => {
          restTimer.skip();
          await finishWorkout(user?.uid ?? '');
          router.back();
        },
      },
    ]);
  };

  // ── Elapsed time formatter ───────────────────────────────────────────────
  const formatElapsed = (secs: number): string => {
    const hrs = Math.floor(secs / 3600);
    const mins = Math.floor((secs % 3600) / 60);
    const s = secs % 60;
    if (hrs > 0) {
      return `${hrs}:${String(mins).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }
    return `${String(mins).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  // ── Navigate to exercise picker ──────────────────────────────────────────
  const handleAddExercise = (): void => {
    router.push('/(app)/exercise-picker');
  };

  // ── Render DraggableFlatList item ────────────────────────────────────────
  const renderExerciseItem = ({ item, drag, isActive: isDragging }: RenderItemParams<ActiveExercise>): React.JSX.Element => (
    <ExerciseCard
      exercise={item}
      previousValues={previousValuesMap[item.exerciseId] ?? []}
      onCompleteSet={(aeId, setId, weight, reps) =>
        void handleCompleteSet(aeId, setId, weight, reps)
      }
      onAddSet={dispatchAddSet}
      onRemoveExercise={dispatchRemoveExercise}
      drag={drag}
      isActive={isDragging}
    />
  );

  // ── Empty state ──────────────────────────────────────────────────────────
  const EmptyState = (): React.JSX.Element => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyIcon}>🏋️</Text>
      <Text style={styles.emptyTitle}>No exercises yet</Text>
      <Text style={styles.emptySubtitle}>Tap + to add your first exercise</Text>
      <TouchableOpacity
        style={styles.emptyAddButton}
        onPress={handleAddExercise}
        accessibilityRole="button"
        accessibilityLabel="Add first exercise"
      >
        <Text style={styles.emptyAddButtonText}>+ Add Exercise</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <GestureHandlerRootView style={styles.gestureRoot}>
      <SafeAreaView style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.headerTitle}>Workout</Text>
            <Text style={styles.headerDuration}>{formatElapsed(elapsedSeconds)}</Text>
          </View>
          <TouchableOpacity
            style={styles.finishButton}
            onPress={handleFinish}
            accessibilityRole="button"
            accessibilityLabel="Finish workout"
          >
            <Text style={styles.finishButtonText}>Finish</Text>
          </TouchableOpacity>
        </View>

        {/* Exercise list */}
        {session && session.exercises.length > 0 ? (
          <DraggableFlatList
            data={session.exercises}
            keyExtractor={(item) => item.id}
            renderItem={renderExerciseItem}
            onDragEnd={({ data }) => {
              dispatchReorderExercises(data.map((e) => e.id));
            }}
            contentContainerStyle={styles.listContent}
          />
        ) : (
          <ScrollView contentContainerStyle={styles.emptyContainer}>
            <EmptyState />
          </ScrollView>
        )}

        {/* Floating Add Exercise button */}
        {session && session.exercises.length > 0 && (
          <TouchableOpacity
            style={styles.fab}
            onPress={handleAddExercise}
            accessibilityRole="button"
            accessibilityLabel="Add exercise"
          >
            <Text style={styles.fabText}>+</Text>
          </TouchableOpacity>
        )}

        {/* Rest timer bar */}
        <RestTimerBar
          isActive={restTimer.isActive}
          remainingSeconds={restTimer.remainingSeconds}
          totalSeconds={DEFAULT_REST_SECONDS}
          onSkip={restTimer.skip}
        />

        {/* PR Toast overlay */}
        {currentPR && (
          <PRToast pr={currentPR} onDismiss={handleDismissPR} />
        )}
      </SafeAreaView>
    </GestureHandlerRootView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  gestureRoot: {
    flex: 1,
  },
  container: {
    flex: 1,
    backgroundColor: CREAM,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: NAVY,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 2,
    borderBottomColor: NAVY_DARK,
  },
  headerLeft: {
    gap: 2,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: 0.5,
  },
  headerDuration: {
    fontSize: 14,
    color: ORANGE,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  finishButton: {
    backgroundColor: ORANGE,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  finishButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: CREAM,
  },
  listContent: {
    paddingTop: 8,
    paddingBottom: 120, // space for rest timer bar + FAB
  },
  emptyContainer: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 40,
    gap: 12,
  },
  emptyIcon: {
    fontSize: 56,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: NAVY,
  },
  emptySubtitle: {
    fontSize: 15,
    color: GREY,
    textAlign: 'center',
  },
  emptyAddButton: {
    marginTop: 8,
    backgroundColor: ORANGE,
    paddingHorizontal: 28,
    paddingVertical: 14,
    borderRadius: 28,
  },
  emptyAddButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: CREAM,
  },
  fab: {
    position: 'absolute',
    bottom: 100, // above rest timer bar
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: ORANGE,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: NAVY,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
  },
  fabText: {
    fontSize: 28,
    color: CREAM,
    fontWeight: '300',
    lineHeight: 32,
  },
});
