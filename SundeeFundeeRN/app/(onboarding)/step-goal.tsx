/**
 * step-goal.tsx — Onboarding Step 3: Select primary goal.
 *
 * 5 option cards: Strength, Build Muscle, Endurance, Weight Loss, General Fitness.
 * Next disabled until selection made. Back navigates to step-experience.
 */
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useOnboarding } from '@/src/onboarding/OnboardingContext';
import { getNextStep, getTotalSteps, getPreviousStep } from '@/src/onboarding/useOnboardingFlow';
import type { PrimaryGoal } from '@/src/repositories/OnboardingProfileRepo';
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

const STEP_NAME = 'step-goal';
const STEP_NUMBER = 3;

interface Option {
  value: PrimaryGoal;
  label: string;
}

const OPTIONS: Option[] = [
  { value: 'strength', label: 'Strength' },
  { value: 'muscle', label: 'Build Muscle' },
  { value: 'endurance', label: 'Endurance' },
  { value: 'weightLoss', label: 'Weight Loss' },
  { value: 'general', label: 'General Fitness' },
];

export default function StepGoal(): React.JSX.Element {
  const { draft, setPrimaryGoal } = useOnboarding();
  const totalSteps = getTotalSteps(draft.gender);
  const canProceed = draft.primaryGoal !== null;

  function handleSelect(value: PrimaryGoal): void {
    setPrimaryGoal(value);
  }

  function handleNext(): void {
    if (!canProceed) return;
    const nextStep = getNextStep(STEP_NAME, draft);
    if (nextStep) {
      router.push(`/(onboarding)/${nextStep}` as never);
    }
  }

  function handleBack(): void {
    const prev = getPreviousStep(STEP_NAME);
    if (prev) {
      router.push(`/(onboarding)/${prev}` as never);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Progress bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressTrack}>
          <View
            style={[
              styles.progressFill,
              { width: `${(STEP_NUMBER / totalSteps) * 100}%` },
            ]}
          />
        </View>
        <Text style={styles.progressText}>
          Step {STEP_NUMBER} of {totalSteps}
        </Text>
      </View>

      {/* Content */}
      <View style={styles.content}>
        <Text style={styles.title}>What is your primary goal?</Text>
        <Text style={styles.subtitle}>
          Your training programs will be optimized for this objective.
        </Text>

        {OPTIONS.map((option) => {
          const selected = draft.primaryGoal === option.value;
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
          accessibilityLabel="Next"
          accessibilityState={{ disabled: !canProceed }}
        >
          <Text style={[styles.nextButtonText, !canProceed && styles.nextButtonTextDisabled]}>
            Next
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
