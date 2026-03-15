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
 * - Pre-workout injury substitution card (if injuries modify exercises)
 * - Adaptation context loaded on mount: cycle phase multiplier + readiness blend
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
import { router, useFocusEffect } from 'expo-router';
import { format } from 'date-fns';
import { onExerciseSelected } from '@/src/hooks/useExerciseSelection';
import * as Notifications from 'expo-notifications';
import DraggableFlatList, { type RenderItemParams } from 'react-native-draggable-flatlist';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { ExerciseCard } from '@/src/components/workout/ExerciseCard';
import { RestTimerBar } from '@/src/components/workout/RestTimerBar';
import { PRToast } from '@/src/components/workout/PRToast';
import { AdaptationIndicator } from '@/src/components/workout/AdaptationIndicator';
import { InjurySubstitutionCard, type SubstitutionPair } from '@/src/components/injury/InjurySubstitutionCard';
import { useWorkoutSession } from '@/src/hooks/useWorkoutSession';
import { useRestTimer } from '@/src/hooks/useRestTimer';
import { usePRDetection } from '@/src/hooks/usePRDetection';
import { useSession } from '@/src/auth/AuthContext';
import type { ActiveExercise } from '@/src/domain/workout-session/session-types';
import { getSettingsRepo, DEFAULT_SETTINGS } from '@/src/repositories/SettingsRepo';
import type { WeightUnit } from '@/src/domain/types';
import type { PRCheckResult } from '@/src/domain/pr-detection/pr-types';
import { getCycleRepo, recordToPeriodLog } from '@/src/repositories/CycleRepo';
import { getInjuryRepo, recordToInjuryProfile } from '@/src/repositories/InjuryRepo';
import { getReadinessRepo } from '@/src/repositories/ReadinessRepo';
import { getOnboardingProfileRepo } from '@/src/repositories/OnboardingProfileRepo';
import { calculateCycleStatus } from '@/src/domain/cycle/cycle-calculations';
import { blendMultiplier, resolveReadinessTier, resolveConfidenceScale } from '@/src/domain/cycle/cycle-adaptation-policy';
import type { InjuryProfile } from '@/src/domain/types/index';
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

  // Adaptation context state
  const [adaptationMultiplier, setAdaptationMultiplier] = useState(1.0);
  const [adaptationReason, setAdaptationReason] = useState('');
  const [injurySubstitutions, setInjurySubstitutions] = useState<SubstitutionPair[]>([]);
  const [injuryForCard, setInjuryForCard] = useState<InjuryProfile | null>(null);
  const [injuryCardDismissed, setInjuryCardDismissed] = useState(false);

  // Current PR toast to show (first in queue)
  const [currentPR, setCurrentPR] = useState<
    (PRCheckResult & { exerciseName: string }) | null
  >(null);

  // Weight unit preference
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

  // Elapsed timer
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const elapsedIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Track if user has initiated a workout (vs crash recovery)
  const hasStartedRef = useRef(false);

  // ── Load adaptation context on focus ────────────────────────────────────
  const loadAdaptationContext = useCallback(async (): Promise<void> => {
    if (!user) return;

    try {
      const today = format(new Date(), 'yyyy-MM-dd');

      // 1. Load readiness score for today
      let readinessScore: number | undefined;
      try {
        const readinessRepo = getReadinessRepo(isGuest);
        const survey = await readinessRepo.getSurveyForDate(user.uid, today);
        readinessScore = survey?.result.score;
      } catch {
        // Non-critical — continue without readiness
      }

      // 2. Load cycle phase multiplier (skip if not tracking)
      let phaseLoadMultiplier = 1.0;
      let phaseLabel = '';
      try {
        const profileRepo = getOnboardingProfileRepo(isGuest);
        const profile = await profileRepo.getProfile(user.uid);
        const cycleRepo = getCycleRepo(isGuest);
        const [periodLogRecords, cycleSettings] = await Promise.all([
          cycleRepo.getPeriodLogs(user.uid),
          cycleRepo.getCycleSettings(user.uid),
        ]);
        if (profile?.cycleOptIn === true && periodLogRecords.length > 0) {
          const periodLogs = periodLogRecords.map(recordToPeriodLog);
          const cycleStatus = calculateCycleStatus(periodLogs, cycleSettings);
          if (cycleStatus !== null) {
            const phase = cycleStatus.currentPhase;
            // Use load baseline from BASELINE_PHASE_SETTINGS via blendMultiplier
            const PHASE_LOAD: Record<string, number> = {
              menstrual: 0.90,
              follicular: 1.00,
              ovulation: 1.12,
              luteal: 0.97,
            };
            const loadTarget = PHASE_LOAD[phase] ?? 1.0;
            const readinessTier = resolveReadinessTier(readinessScore);
            const confidenceScale = resolveConfidenceScale('high');
            const readinessScale = readinessTier === 'low' ? 0.6 : readinessTier === 'high' ? 1.2 : 1.0;
            phaseLoadMultiplier = blendMultiplier(loadTarget, readinessScale, confidenceScale);
            phaseLabel = phase.charAt(0).toUpperCase() + phase.slice(1);
          }
        }
      } catch {
        // Non-critical — continue without cycle adaptation
      }

      // 3. Load injuries and build substitution list
      let substitutions: SubstitutionPair[] = [];
      let primaryInjury: InjuryProfile | null = null;
      try {
        const injuryRepo = getInjuryRepo(isGuest);
        const injuryRecords = await injuryRepo.getInjuries(user.uid);
        const activeInjuries = injuryRecords
          .map(recordToInjuryProfile)
          .filter((inj) => inj.recoveryPhase !== 'resolved');
        if (activeInjuries.length > 0) {
          primaryInjury = activeInjuries[0] ?? null;
          // Build substitution pairs from the adaptation engine's regression table
          // using a sample of common strength exercises (mirrors Plan 05-05 pattern)
          const { adaptProgramWithMetadata } = await import('@/src/domain/injury/injury-adaptation-engine');
          const sampleProgram = {
            id: 'session',
            name: 'Session',
            description: '',
            sessions: [{
              id: 's1',
              name: 'Session',
              exercises: [
                { id: 'e1', name: 'Back Squat', sets: 3, reps: { kind: 'fixed' as const, value: 5 }, muscleGroup: 'quads' },
                { id: 'e2', name: 'Conventional Deadlift (No Straps)', sets: 3, reps: { kind: 'fixed' as const, value: 5 }, muscleGroup: 'back' },
                { id: 'e3', name: 'Bench Press', sets: 3, reps: { kind: 'fixed' as const, value: 5 }, muscleGroup: 'chest' },
                { id: 'e4', name: 'Overhead Press', sets: 3, reps: { kind: 'fixed' as const, value: 5 }, muscleGroup: 'shoulders' },
                { id: 'e5', name: 'Romanian Deadlift (No Straps)', sets: 3, reps: { kind: 'fixed' as const, value: 8 }, muscleGroup: 'hamstrings' },
              ],
            }],
          };
          const result = adaptProgramWithMetadata(sampleProgram, activeInjuries);
          substitutions = Object.entries(result.adaptedExercises).map(([replacement, original]) => ({
            original,
            replacement,
          }));
        }
      } catch {
        // Non-critical — continue without injury substitutions
      }

      // 4. Build reason text and update state
      const reasonParts: string[] = [];
      if (phaseLabel) reasonParts.push(`${phaseLabel} phase`);
      if (readinessScore !== undefined) reasonParts.push(`readiness ${Math.round(readinessScore)}/10`);
      const reasonText = reasonParts.length > 0 ? reasonParts.join(' + ') : '';

      setAdaptationMultiplier(phaseLoadMultiplier);
      setAdaptationReason(reasonText);
      setInjurySubstitutions(substitutions);
      setInjuryForCard(primaryInjury);
    } catch {
      // Fail gracefully — workout loads without adaptation context
    }
  }, [user, isGuest]);

  useFocusEffect(
    useCallback(() => {
      void loadAdaptationContext();
    }, [loadAdaptationContext])
  );

  // ── Load weight unit preference on mount ────────────────────────────────
  useEffect(() => {
    if (!user) return;
    void (async () => {
      try {
        const repo = getSettingsRepo(isGuest);
        const stored = await repo.getSettings(user.uid);
        if (stored?.weightUnit) {
          setWeightUnit(stored.weightUnit);
        }
      } catch {
        // Keep default on error
      }
    })();
  }, [user, isGuest]);

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

  // ── Pick up selected exercise from exercise-picker via event bridge ──────
  useEffect(() => {
    const unsubscribe = onExerciseSelected((exercise) => {
      dispatchAddExercise({
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
      });

      // Load previous values for ghost-text
      void getPreviousValues(exercise.id).then((values) => {
        setPreviousValuesMap((prev) => ({ ...prev, [exercise.id]: values }));
      });
    });
    return unsubscribe;
  }, [dispatchAddExercise, getPreviousValues]);

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
      weightUnit={weightUnit}
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

        {/* Pre-workout injury substitution card */}
        {!injuryCardDismissed &&
          injuryForCard !== null &&
          injurySubstitutions.length > 0 && (
            <View style={styles.injuryCardContainer}>
              <InjurySubstitutionCard
                injury={injuryForCard}
                substitutions={injurySubstitutions}
              />
              <TouchableOpacity
                style={styles.dismissButton}
                onPress={() => setInjuryCardDismissed(true)}
                accessibilityRole="button"
                accessibilityLabel="Dismiss injury substitution card"
              >
                <Text style={styles.dismissButtonText}>Got it, start workout</Text>
              </TouchableOpacity>
            </View>
          )}

        {/* Adaptation indicator banner — shown when multiplier differs from 1.0 */}
        {adaptationMultiplier !== 1.0 && (
          <View style={styles.adaptationBanner} testID="adaptation-banner">
            <AdaptationIndicator
              multiplier={adaptationMultiplier}
              reason={adaptationReason}
            />
            <Text style={styles.adaptationLabel}>
              Load adjusted for today
            </Text>
          </View>
        )}

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
  injuryCardContainer: {
    marginHorizontal: 16,
    marginTop: 12,
    gap: 10,
  },
  dismissButton: {
    backgroundColor: NAVY,
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: 'center',
  },
  dismissButtonText: {
    fontSize: 13,
    fontWeight: '600',
    color: CREAM,
    letterSpacing: 0.3,
  },
  adaptationBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: CREAM_LIGHT,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
  },
  adaptationLabel: {
    fontSize: 11,
    color: GREY,
    fontWeight: '400',
  },
});
