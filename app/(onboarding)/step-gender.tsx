/**
 * step-gender.tsx — Onboarding Step 4: Select gender.
 *
 * 3 option cards: Female, Male, Prefer Not to Say (maps to 'other').
 * Male users skip step-cycle and call completeOnboarding directly from this step.
 * Female/other users navigate to step-cycle.
 * Back navigates to step-goal.
 */
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useOnboarding } from '@/src/onboarding/OnboardingContext';
import { getNextStep, getTotalSteps, getPreviousStep } from '@/src/onboarding/useOnboardingFlow';
import type { Gender } from '@/src/domain/types';
import {
  CREAM,
  NAVY,
  ORANGE,
  CREAM_LIGHT,
  GREY_LIGHT,
  GREY,
  ORANGE_LIGHT,
  ORANGE_DARK,
} from '@/src/theme/colors';

const STEP_NAME = 'step-gender';
const STEP_NUMBER = 4;

interface Option {
  value: Gender;
  label: string;
}

const OPTIONS: Option[] = [
  { value: 'female', label: 'Female' },
  { value: 'male', label: 'Male' },
  { value: 'other', label: 'Prefer Not to Say' },
];

export default function StepGender(): React.JSX.Element {
  const { draft, setGender, completeOnboarding } = useOnboarding();
  const { user, isGuest } = useSession();
  const totalSteps = getTotalSteps(draft.gender);
  const canProceed = draft.gender !== null;

  function handleSelect(value: Gender): void {
    setGender(value);
  }

  async function handleNext(): Promise<void> {
    if (!canProceed || draft.gender === null) return;

    const nextStep = getNextStep(STEP_NAME, draft);

    if (nextStep === null) {
      // Male user: skip cycle step, save atomically and navigate to app
      const uid = user?.uid ?? '';
      try {
        await completeOnboarding(uid, isGuest);
        router.replace('/(app)/(tabs)' as never);
      } catch (error) {
        console.error('[StepGender] Failed to complete onboarding:', error);
        Alert.alert(
          'Error',
          'Failed to save your profile. Please try again.',
          [{ text: 'OK' }]
        );
      }
    } else {
      router.push(`/(onboarding)/${nextStep}` as never);
    }
  }

  function handleBack(): void {
    const prev = getPreviousStep(STEP_NAME);
    if (prev) {
      router.push(`/(onboarding)/${prev}` as never);
    }
  }

  // Recalculate totalSteps based on current selection so the bar updates live
  const displayTotalSteps = getTotalSteps(draft.gender);

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Progress bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressTrack}>
          <View
            style={[
              styles.progressFill,
              { width: `${(STEP_NUMBER / displayTotalSteps) * 100}%` },
            ]}
          />
        </View>
        <Text style={styles.progressText}>
          Step {STEP_NUMBER} of {displayTotalSteps}
        </Text>
      </View>

      {/* Content */}
      <View style={styles.content}>
        <Text style={styles.title}>How do you identify?</Text>
        <Text style={styles.subtitle}>
          This helps us personalize your training, including cycle-aware adaptations for users with menstrual cycles.
        </Text>

        {OPTIONS.map((option) => {
          const selected = draft.gender === option.value;
          return (
            <TouchableOpacity
              key={option.value}
              style={[styles.card, selected && styles.cardSelected]}
              onPress={() => handleSelect(option.value)}
              accessibilityRole="radio"
              accessibilityState={{ selected }}
              accessibilityLabel={option.label}
            >
              <Text style={[styles.cardLabel, selected && styles.cardLabelSelected]}>
                {option.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Navigation */}
      <View style={styles.navRow}>
        <TouchableOpacity
          style={[styles.nextButton, !canProceed && styles.nextButtonDisabled]}
          onPress={handleNext}
          disabled={!canProceed}
          accessibilityRole="button"
          accessibilityLabel={draft.gender === 'male' ? 'Complete' : 'Next'}
          accessibilityState={{ disabled: !canProceed }}
        >
          <Text style={[styles.nextButtonText, !canProceed && styles.nextButtonTextDisabled]}>
            {draft.gender === 'male' ? 'Complete' : 'Next'}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.backButton}
          onPress={handleBack}
          accessibilityRole="button"
          accessibilityLabel="Back"
        >
          <Text style={styles.backButtonText}>Back</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 40,
    backgroundColor: CREAM,
  },
  progressContainer: {
    marginBottom: 48,
  },
  progressTrack: {
    height: 4,
    backgroundColor: GREY_LIGHT,
    borderRadius: 2,
    overflow: 'hidden',
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: ORANGE,
    borderRadius: 2,
  },
  progressText: {
    fontSize: 13,
    color: GREY,
    textAlign: 'right',
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: NAVY,
    marginBottom: 12,
    letterSpacing: 0.3,
  },
  subtitle: {
    fontSize: 16,
    color: NAVY,
    opacity: 0.7,
    marginBottom: 32,
    lineHeight: 24,
  },
  card: {
    backgroundColor: CREAM_LIGHT,
    borderWidth: 2,
    borderColor: GREY_LIGHT,
    borderRadius: 12,
    padding: 20,
    marginBottom: 12,
  },
  cardSelected: {
    backgroundColor: ORANGE_LIGHT,
    borderColor: ORANGE,
  },
  cardLabel: {
    fontSize: 18,
    fontWeight: '700',
    color: NAVY,
  },
  cardLabelSelected: {
    color: ORANGE_DARK,
  },
  navRow: {
    marginTop: 32,
  },
  nextButton: {
    backgroundColor: ORANGE,
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 12,
  },
  nextButtonDisabled: {
    backgroundColor: GREY_LIGHT,
  },
  nextButtonText: {
    color: CREAM,
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  nextButtonTextDisabled: {
    color: GREY,
  },
  backButton: {
    paddingVertical: 12,
    alignItems: 'center',
  },
  backButtonText: {
    color: ORANGE_DARK,
    fontSize: 16,
    fontWeight: '600',
  },
});
