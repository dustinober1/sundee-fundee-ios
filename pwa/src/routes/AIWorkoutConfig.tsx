/**
 * AI Workout Config — select time, focus, equipment, energy → generate workout.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { useEntitlementContext } from '../entitlements/EntitlementContext';
import { generateOfflineWorkout } from '../domain/ai-workout/offline-workout-generator';
import type { GeneratedWorkout } from '../domain/ai-workout/generated-workout';
import type { WorkoutGenerationContext } from '../domain/ai-workout/workout-generation-context';
import type { WorkoutFocus, EnergyLevel, EquipmentAccess } from '../domain/types';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import { getSettingsRepo, DEFAULT_SETTINGS } from '../repositories/SettingsRepo';
import { getOnboardingProfileRepo } from '../repositories/OnboardingProfileRepo';
import styles from './AIWorkoutConfig.module.css';

// Module-level shared state for passing workout to preview screen
let _sharedWorkout: GeneratedWorkout | null = null;
export function getSharedWorkout(): GeneratedWorkout | null { return _sharedWorkout; }
export function clearSharedWorkout(): void { _sharedWorkout = null; }

type TimeOption = 15 | 30 | 45 | 60;
type FocusOption = 'upper_body' | 'lower_body' | 'full_body' | 'push' | 'pull' | 'core';
type EquipmentOption = 'full_gym' | 'home_dumbbells' | 'hotel_gym' | 'bodyweight_only';
type EnergyOption = 'low' | 'medium' | 'high';

const TIME_OPTIONS: { value: TimeOption; label: string }[] = [
  { value: 15, label: '15 min' },
  { value: 30, label: '30 min' },
  { value: 45, label: '45 min' },
  { value: 60, label: '60 min' },
];

const FOCUS_OPTIONS: { value: FocusOption; label: string }[] = [
  { value: 'upper_body', label: 'Upper Body' },
  { value: 'lower_body', label: 'Lower Body' },
  { value: 'full_body', label: 'Full Body' },
  { value: 'push', label: 'Push' },
  { value: 'pull', label: 'Pull' },
  { value: 'core', label: 'Core' },
];

const EQUIPMENT_OPTIONS: { value: EquipmentOption; label: string }[] = [
  { value: 'full_gym', label: 'Full Gym' },
  { value: 'home_dumbbells', label: 'Home Dumbbells' },
  { value: 'hotel_gym', label: 'Hotel Gym' },
  { value: 'bodyweight_only', label: 'Bodyweight Only' },
];

const ENERGY_OPTIONS: { value: EnergyOption; label: string }[] = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
];

export function AIWorkoutConfig() {
  const navigate = useNavigate();
  const { user, isGuest } = useSession();
  const { isPremium } = useEntitlementContext();
  const [time, setTime] = useState<TimeOption>(30);
  const [focus, setFocus] = useState<FocusOption>('full_body');
  const [equipment, setEquipment] = useState<EquipmentOption>('full_gym');
  const [energy, setEnergy] = useState<EnergyOption>('medium');
  const [isGenerating, setIsGenerating] = useState(false);

  async function handleGenerate() {
    if (!user) return;
    if (!isPremium) {
      alert('AI Workout is a Premium feature. Upgrade in Settings to unlock.');
      return;
    }
    setIsGenerating(true);
    try {
      // Load user context for generation
      const [maxesRaw, settings, profile] = await Promise.all([
        getExerciseMaxRepo(isGuest).getAllMaxes(user.uid),
        getSettingsRepo(isGuest).getSettings(user.uid),
        getOnboardingProfileRepo(isGuest).getProfile(user.uid),
      ]);

      const maxes = maxesRaw.map((m) => ({ name: m.exerciseName, weightLb: m.weight }));

      const context: WorkoutGenerationContext = {
        userID: user.uid,
        timeMinutes: time,
        focus: focus as WorkoutFocus,
        energyLevel: energy as EnergyLevel,
        equipment: equipment as EquipmentAccess,
        maxes,
        recentWorkouts: [],
        cyclePhase: null,
        readinessTier: null,
        activeInjuries: [],
        experienceLevel: profile?.experienceLevel ?? 'intermediate',
        primaryGoal: profile?.primaryGoal ?? 'strength',
        gender: profile?.gender ?? 'other',
        weightUnit: settings?.weightUnit ?? DEFAULT_SETTINGS.weightUnit,
        desiredSkills: [],
        benchmarkSummaries: [],
        bodyWeightKg: null,
        recentPainActivity: [],
        workoutCompletionRate: null,
        travelModeEnabled: false,
      };

      // TODO: Try Cloud Function first when available, fall back to offline
      const workout = generateOfflineWorkout(context);
      _sharedWorkout = workout;
      navigate('/ai-workout/preview');
    } catch (err) {
      console.error('AI workout generation failed:', err);
      setIsGenerating(false);
    }
  }

  return (
    <div className={styles.container}>
      <button className={styles.back} onClick={() => navigate('/')}>&larr; Dashboard</button>
      <h1 className={styles.title}>AI Workout</h1>
      <p className={styles.subtitle}>Configure your personalized workout</p>

      <Section label="Duration">
        <div className={styles.chips}>
          {TIME_OPTIONS.map((o) => (
            <Chip key={o.value} label={o.label} active={time === o.value} onClick={() => setTime(o.value)} />
          ))}
        </div>
      </Section>

      <Section label="Focus">
        <div className={styles.chips}>
          {FOCUS_OPTIONS.map((o) => (
            <Chip key={o.value} label={o.label} active={focus === o.value} onClick={() => setFocus(o.value)} />
          ))}
        </div>
      </Section>

      <Section label="Equipment">
        <div className={styles.chips}>
          {EQUIPMENT_OPTIONS.map((o) => (
            <Chip key={o.value} label={o.label} active={equipment === o.value} onClick={() => setEquipment(o.value)} />
          ))}
        </div>
      </Section>

      <Section label="Energy Level">
        <div className={styles.chips}>
          {ENERGY_OPTIONS.map((o) => (
            <Chip key={o.value} label={o.label} active={energy === o.value} onClick={() => setEnergy(o.value)} />
          ))}
        </div>
      </Section>

      <button className={styles.generateBtn} onClick={handleGenerate} disabled={isGenerating}>
        {isGenerating ? 'Generating...' : 'Generate Workout'}
      </button>
    </div>
  );
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className={styles.section}>
      <h3 className={styles.sectionLabel}>{label}</h3>
      {children}
    </div>
  );
}

function Chip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button className={`${styles.chip} ${active ? styles.chipActive : ''}`} onClick={onClick}>
      {label}
    </button>
  );
}
