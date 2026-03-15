/**
 * app/(app)/ai-workout/config.tsx — AI Workout Configuration Screen.
 *
 * Presents four quick-select card rows:
 *   1. Time — 15, 30, 45, 60 min
 *   2. Focus — Upper, Lower, Full Body, Push, Pull
 *   3. Equipment — Full Gym, Dumbbells, Bodyweight
 *   4. Energy — Low, Medium, High
 *
 * Auto-loads adaptation context on mount:
 *   - Cycle phase (if cycle tracking enabled)
 *   - Active injuries
 *   - Today's readiness score
 *
 * On "Generate Workout":
 *   1. Checks network connectivity
 *   2. Online → calls Firebase Cloud Function 'generateWorkout'
 *   3. Offline → calls generateOfflineWorkout()
 *   4. Navigates to preview screen with generated workout
 *
 * Art Deco styling: cream background, navy text, orange CTA.
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as Network from 'expo-network';
import { format } from 'date-fns';
import { useSession } from '@/src/auth/AuthContext';
import { getCycleRepo, recordToPeriodLog } from '@/src/repositories/CycleRepo';
import { getInjuryRepo, type InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import { getReadinessRepo, type ReadinessSurveyRecord } from '@/src/repositories/ReadinessRepo';
import { getOnboardingProfileRepo } from '@/src/repositories/OnboardingProfileRepo';
import { calculateCycleStatus } from '@/src/domain/cycle/cycle-calculations';
import type { CyclePhase, WorkoutFocus, EnergyLevel, EquipmentAccess } from '@/src/domain/types';
import { generateOfflineWorkout } from '@/src/domain/ai-workout/offline-workout-generator';
import type { WorkoutGenerationContext, InjurySummary } from '@/src/domain/ai-workout/workout-generation-context';
import { ConfigCards, type CardOption } from '@/src/components/ai-workout/ConfigCards';
import { AdaptationChip } from '@/src/components/ai-workout/AdaptationChip';
import * as colors from '@/src/theme/colors';

// ─── Option definitions ───────────────────────────────────────────────────────

const TIME_OPTIONS: CardOption[] = [
  { label: '15 min', value: '15', icon: '⚡' },
  { label: '30 min', value: '30', icon: '🕐' },
  { label: '45 min', value: '45', icon: '🕑' },
  { label: '60 min', value: '60', icon: '🕒' },
];

const FOCUS_OPTIONS: CardOption[] = [
  { label: 'Upper Body', value: 'upper_body', icon: '💪' },
  { label: 'Lower Body', value: 'lower_body', icon: '🦵' },
  { label: 'Full Body', value: 'full_body', icon: '🏋️' },
  { label: 'Push', value: 'push', icon: '⬆️' },
  { label: 'Pull', value: 'pull', icon: '⬇️' },
  { label: 'Core', value: 'core', icon: '🔄' },
];

const EQUIPMENT_OPTIONS: CardOption[] = [
  { label: 'Full Gym', value: 'full_gym', icon: '🏟️' },
  { label: 'Dumbbells', value: 'home_dumbbells', icon: '🪆' },
  { label: 'Bodyweight', value: 'bodyweight_only', icon: '🤸' },
  { label: 'Hotel Gym', value: 'hotel_gym', icon: '🏨' },
];

const ENERGY_OPTIONS: CardOption[] = [
  { label: 'Low', value: 'low', icon: '😴' },
  { label: 'Medium', value: 'medium', icon: '😊' },
  { label: 'High', value: 'high', icon: '🔥' },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Convert InjuryProfileRecord to InjurySummary for the workout generation context.
 */
export function injuryToSummary(injury: InjuryProfileRecord): InjurySummary {
  const location = injury.location ?? injury.bodyLocation;
  return {
    location,
    phase: injury.recoveryPhase,
    restrictions: [],
  };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function AIWorkoutConfigScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isGuest } = useSession();
  const uid = user?.uid ?? '';

  // ── Config state ──────────────────────────────────────────────────────────
  const [timeMinutes, setTimeMinutes] = useState<string>('30');
  const [focus, setFocus] = useState<WorkoutFocus>('full_body');
  const [equipment, setEquipment] = useState<EquipmentAccess>('full_gym');
  const [energyLevel, setEnergyLevel] = useState<EnergyLevel>('medium');

  // ── Adaptation context ────────────────────────────────────────────────────
  const [cyclePhase, setCyclePhase] = useState<CyclePhase | undefined>(undefined);
  const [injuries, setInjuries] = useState<InjuryProfileRecord[]>([]);
  const [readiness, setReadiness] = useState<ReadinessSurveyRecord | null>(null);

  // ── Generation state ──────────────────────────────────────────────────────
  const [isGenerating, setIsGenerating] = useState(false);
  const generatingRef = useRef(false);

  // ── Load adaptation context on mount ─────────────────────────────────────
  useEffect(() => {
    if (!uid) return;

    void loadAdaptationContext();
  }, [uid, isGuest]); // eslint-disable-line react-hooks/exhaustive-deps

  const loadAdaptationContext = useCallback(async (): Promise<void> => {
    try {
      // Load cycle phase — only if user opted into cycle tracking
      const profileRepo = getOnboardingProfileRepo(isGuest);
      const profile = await profileRepo.getProfile(uid);

      if (profile?.cycleOptIn === true) {
        const cycleRepo = getCycleRepo(isGuest);
        const [periodLogRecords, cycleSettings] = await Promise.all([
          cycleRepo.getPeriodLogs(uid),
          cycleRepo.getCycleSettings(uid),
        ]);

        if (cycleSettings && periodLogRecords.length > 0) {
          const periodLogs = periodLogRecords.map(recordToPeriodLog);
          const status = calculateCycleStatus(periodLogs, cycleSettings);
          if (status) {
            setCyclePhase(status.currentPhase);
          }
        }
      }
    } catch {
      // Cycle data unavailable — proceed without it
    }

    try {
      // Load injuries
      const injuryRepo = getInjuryRepo(isGuest);
      const injuryRecords = await injuryRepo.getInjuries(uid);
      const activeInjuries = injuryRecords.filter((i) => i.recoveryPhase !== 'resolved');
      setInjuries(activeInjuries);
    } catch {
      // Injury data unavailable — proceed without it
    }

    try {
      // Load today's readiness
      const readinessRepo = getReadinessRepo(isGuest);
      const today = format(new Date(), 'yyyy-MM-dd');
      const survey = await readinessRepo.getSurveyForDate(uid, today);
      setReadiness(survey);
    } catch {
      // Readiness data unavailable — proceed without it
    }
  }, [uid, isGuest]);

  // ── Generate workout ──────────────────────────────────────────────────────
  const handleGenerateWorkout = useCallback(async (): Promise<void> => {
    if (generatingRef.current) return;
    generatingRef.current = true;
    setIsGenerating(true);

    try {
      // 1. Check connectivity BEFORE calling Cloud Function (anti-pattern: checking after)
      const networkState = await Network.getNetworkStateAsync();
      const isOnline = networkState.isConnected === true && networkState.isInternetReachable !== false;

      // 2. Build generation context
      const activeInjuries = injuries.filter((i) => i.recoveryPhase !== 'resolved');
      const readinessTier = readiness
        ? (readiness.result.tier as string)
        : null;

      const context: WorkoutGenerationContext = {
        userID: uid,
        timeMinutes: parseInt(timeMinutes, 10),
        focus,
        energyLevel,
        equipment,
        maxes: [],
        recentWorkouts: [],
        cyclePhase: cyclePhase ?? null,
        readinessTier,
        activeInjuries: activeInjuries.map(injuryToSummary),
        experienceLevel: 'intermediate',
        primaryGoal: 'general_fitness',
        gender: 'female',
        weightUnit: 'lb',
        desiredSkills: [],
        benchmarkSummaries: [],
        bodyWeightKg: null,
        recentPainActivity: [],
        workoutCompletionRate: null,
        travelModeEnabled: false,
      };

      let generatedWorkout;
      let generatedOffline = false;

      if (isOnline) {
        try {
          // 3a. Call Firebase Cloud Function
          generatedWorkout = await callGenerateWorkoutFunction(context);
        } catch (fnError) {
          // Function failed — fall back to offline
          console.warn('[AIWorkout] Cloud Function failed, falling back to offline:', fnError);
          generatedWorkout = generateOfflineWorkout(context);
          generatedOffline = true;
          showOfflineFallbackToast();
        }
      } else {
        // 3b. Offline: use template-based generator
        generatedWorkout = generateOfflineWorkout(context);
        generatedOffline = true;
      }

      // 4. Navigate to preview screen
      // Pass generated workout via global shared state to avoid URL param size limits
      setSharedWorkout(generatedWorkout, generatedOffline, context);
      router.push('/ai-workout/preview' as never);
    } catch (error) {
      console.error('[AIWorkout] Generation failed:', error);
      Alert.alert(
        'Generation Failed',
        'Unable to generate workout. Please try again.',
        [{ text: 'OK' }],
      );
    } finally {
      generatingRef.current = false;
      setIsGenerating(false);
    }
  }, [uid, timeMinutes, focus, energyLevel, equipment, cyclePhase, injuries, readiness, router]);

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <View style={styles.screen}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.heading}>Build Your Workout</Text>
        <Text style={styles.subheading}>
          Your cycle, injuries, and readiness are automatically incorporated.
        </Text>

        <ConfigCards
          title="Time"
          options={TIME_OPTIONS}
          selected={timeMinutes}
          onSelect={(v) => setTimeMinutes(v)}
          testID="config-time"
        />

        <ConfigCards
          title="Focus"
          options={FOCUS_OPTIONS}
          selected={focus}
          onSelect={(v) => setFocus(v as WorkoutFocus)}
          testID="config-focus"
        />

        <ConfigCards
          title="Equipment"
          options={EQUIPMENT_OPTIONS}
          selected={equipment}
          onSelect={(v) => setEquipment(v as EquipmentAccess)}
          testID="config-equipment"
        />

        <ConfigCards
          title="Energy"
          options={ENERGY_OPTIONS}
          selected={energyLevel}
          onSelect={(v) => setEnergyLevel(v as EnergyLevel)}
          testID="config-energy"
        />

        <AdaptationChip
          cyclePhase={cyclePhase}
          injuries={injuries}
          readiness={readiness}
        />
      </ScrollView>

      {/* Generate button */}
      <View style={styles.footer}>
        <Pressable
          style={[styles.generateButton, isGenerating && styles.generateButtonDisabled]}
          onPress={() => void handleGenerateWorkout()}
          disabled={isGenerating}
          testID="generate-workout-button"
        >
          {isGenerating ? (
            <View style={styles.loadingRow}>
              <ActivityIndicator color={colors.CREAM} size="small" />
              <Text style={styles.generateButtonText}>Generating…</Text>
            </View>
          ) : (
            <Text style={styles.generateButtonText}>Generate Workout</Text>
          )}
        </Pressable>
      </View>
    </View>
  );
}

// ─── Cloud Function call ──────────────────────────────────────────────────────

async function callGenerateWorkoutFunction(
  context: WorkoutGenerationContext,
): Promise<ReturnType<typeof generateOfflineWorkout>> {
  const { callCloudFunction } = await import('@/src/services/callCloudFunction');
  return callCloudFunction<ReturnType<typeof generateOfflineWorkout>>(
    'generateWorkout',
    context as unknown as Record<string, unknown>,
  );
}

function showOfflineFallbackToast(): void {
  // Simple alert for offline fallback notification
  // A proper toast library can be integrated in a future pass
  Alert.alert(
    'Using Offline Mode',
    'Cloud generation unavailable. Generated a workout based on your preferences.',
    [{ text: 'OK' }],
  );
}

// ─── Shared state ─────────────────────────────────────────────────────────────
// Module-level shared state to pass generated workout to preview screen
// without URL param size limits or navigation serialization issues.

import type { GeneratedWorkout } from '@/src/domain/ai-workout/generated-workout';

interface SharedWorkoutState {
  workout: GeneratedWorkout;
  isOffline: boolean;
  context: WorkoutGenerationContext;
}

let _sharedWorkoutState: SharedWorkoutState | null = null;

export function setSharedWorkout(
  workout: GeneratedWorkout,
  isOffline: boolean,
  context: WorkoutGenerationContext,
): void {
  _sharedWorkoutState = { workout, isOffline, context };
}

export function getSharedWorkout(): SharedWorkoutState | null {
  return _sharedWorkoutState;
}

export function clearSharedWorkout(): void {
  _sharedWorkoutState = null;
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
    paddingBottom: 120,
  },
  heading: {
    color: colors.NAVY,
    fontSize: 26,
    fontWeight: '700',
    letterSpacing: -0.5,
    marginBottom: 6,
  },
  subheading: {
    color: colors.NAVY_MEDIUM,
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 24,
  },
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
  },
  generateButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  generateButtonDisabled: {
    backgroundColor: colors.GREY,
  },
  generateButtonText: {
    color: colors.CREAM,
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
});
